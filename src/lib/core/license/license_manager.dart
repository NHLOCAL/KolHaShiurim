import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:canonical_json/canonical_json.dart' as cj;
import 'package:basic_utils/basic_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';
import 'package:kol_hashiurim/services/log_service.dart';
import 'package:win32/win32.dart';
import 'package:windows_system_info/windows_system_info.dart';

extension Uint8ArrayExtension on Array<Uint8> {
  List<int> toList(int length) {
    final list = <int>[];
    for (var i = 0; i < length; i++) {
      list.add(this[i]);
    }
    return list;
  }
}

RSAPublicKey parsePublicKeyFromPem(String pem) =>
    CryptoUtils.rsaPublicKeyFromPem(pem);

class LicenseManager {
  final RSAPublicKey publicKey;
  LicenseManager(this.publicKey);
  Future<File> get _licenseFile async {
    final dir = await getApplicationSupportDirectory();
    final appDir = Directory(p.join(dir.path, 'TorahShiurimTransfer'));
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return File(p.join(appDir.path, 'app.lic'));
  }

  Future<String?> _getWmicInfo(String query, LogService logService) async {
    try {
      final result = await Process.run('wmic', query.split(' '));
      if (result.exitCode == 0 && result.stdout is String) {
        final lines = result.stdout.toString().trim().split(
          RegExp(r'(\r\n|\r|\n)'),
        );
        if (lines.length > 1) {
          final value = lines[1].trim();
          if (value.isNotEmpty &&
              !value.toLowerCase().contains('to be filled by o.e.m.')) {
            await logService.logInfo('WMIC query "$query" success: $value');
            return value;
          }
        }
      }
      await logService.logWarning(
        'WMIC query "$query" failed or returned empty. Exit code: ${result.exitCode}, StdErr: ${result.stderr}',
      );
      return null;
    } catch (e, st) {
      await logService.logError('Exception running WMIC query "$query"', e, st);
      return null;
    }
  }

  Future<String> getHardwareFingerprint(LogService logService) async {
    await logService.logInfo("--- Generating Hardware Fingerprint ---");
    final cpuId = await _getWmicInfo('cpu get processorid', logService);
    final baseboardSerial = await _getWmicInfo(
      'baseboard get serialnumber',
      logService,
    );
    final volName = calloc<Uint16>(MAX_PATH).cast<Utf16>();
    final fsName = calloc<Uint16>(MAX_PATH).cast<Utf16>();
    final serialPtr = calloc<DWORD>();
    String diskSerial = '';
    if (GetVolumeInformation(
          TEXT('C:\\'),
          volName,
          MAX_PATH,
          serialPtr,
          nullptr,
          nullptr,
          fsName,
          MAX_PATH,
        ) !=
        0) {
      diskSerial = serialPtr.value.toRadixString(16).toUpperCase();
      await logService.logInfo("Disk serial: $diskSerial");
    } else {
      await logService.logWarning("Failed to get disk serial.");
    }
    calloc.free(volName);
    calloc.free(fsName);
    calloc.free(serialPtr);
    String macsString = '';
    try {
      await WindowsSystemInfo.initWindowsInfo(
        requiredValues: [WindowsSystemInfoFeat.network],
      );
      final adapters = WindowsSystemInfo.network;
      final macs = adapters
          .map(
            (a) => a.mac.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '').toUpperCase(),
          )
          .where(
            (mac) =>
                mac.isNotEmpty &&
                mac != '000000000000' &&
                !mac.startsWith('02'),
          )
          .toSet()
          .toList();
      macs.sort();
      macsString = macs.join(',');
      await logService.logInfo("Sorted MACs: $macsString");
    } catch (e, st) {
      await logService.logError("Failed to get MAC addresses", e, st);
    }
    final components = <String>[];
    if (cpuId != null && cpuId.isNotEmpty) components.add('cpu:$cpuId');
    if (baseboardSerial != null && baseboardSerial.isNotEmpty) {
      components.add('board:$baseboardSerial');
    }
    components.add('disk:$diskSerial');
    components.add('macs:$macsString');
    if (cpuId == null && baseboardSerial == null) {
      final sysInfo = calloc<SYSTEM_INFO>();
      GetSystemInfo(sysInfo);
      final fallbackCpuId =
          '${sysInfo.ref.wProcessorArchitecture}-${sysInfo.ref.dwNumberOfProcessors}-${sysInfo.ref.dwProcessorType}';
      components.add('fb_cpu:$fallbackCpuId');
      calloc.free(sysInfo);
      await logService.logWarning("Using fallback CPU info: $fallbackCpuId");
    }
    final concat = components.join(';');
    await logService.logInfo("Final fingerprint string for hashing: $concat");
    final hash = SHA256Digest().process(
      Uint8List.fromList(utf8.encode(concat)),
    );
    final fingerprint = base64Url.encode(hash).replaceAll('=', '');
    await logService.logInfo("Generated Fingerprint: $fingerprint");
    await logService.logInfo("--- End Fingerprint Generation ---");
    return fingerprint;
  }

  Future<bool> verifyLicense(String licenseJson, LogService logService) async {
    await logService.logInfo("--- Starting License Verification ---");
    try {
      final jsonMap = json.decode(licenseJson) as Map<String, dynamic>;
      await logService.logInfo("Step 1: License JSON parsed successfully.");
      final sigB64 = jsonMap['signature'] as String;
      final signatureBytes = base64Url.decode(sigB64);
      await logService.logInfo(
        "Step 2: Signature decoded. Length: ${signatureBytes.length} bytes.",
      );
      final payloadMap = {
        'fingerprint': jsonMap['fingerprint'],
        'issued_to': jsonMap['issued_to'],
        'issued_on': jsonMap['issued_on'],
        'valid_until': jsonMap['valid_until'],
        'features': jsonMap['features'],
      };
      final payloadBytes = cj.canonicalJson.encode(payloadMap);
      final payloadString = utf8.decode(payloadBytes);
      await logService.logInfo("--- CRITICAL PAYLOAD CHECK ---");
      await logService.logInfo("Payload for verification:");
      await logService.logInfo(payloadString);
      await logService.logInfo("--- END CRITICAL PAYLOAD CHECK ---");
      final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');
      verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
      final payloadBytesUint8 = Uint8List.fromList(payloadBytes);
      final isValid = verifier.verifySignature(
        payloadBytesUint8,
        RSASignature(signatureBytes),
      );
      await logService.logInfo(
        "Step 3: Signature verification result: $isValid",
      );
      if (!isValid) {
        await logService.logWarning("Verification FAILED: Invalid signature.");
        return false;
      }
      final now = DateTime.now();
      final issuedOn = DateTime.parse(jsonMap['issued_on']);
      final validUntil = DateTime.parse(jsonMap['valid_until']);
      await logService.logInfo(
        "Step 4: Now=$now, IssuedOn=$issuedOn, ValidUntil=$validUntil",
      );
      if (now.isBefore(issuedOn) || now.isAfter(validUntil)) {
        await logService.logWarning("Verification FAILED: License not active.");
        return false;
      }
      final localFp = await getHardwareFingerprint(logService);
      final licenseJsonFp = jsonMap['fingerprint'] as String;
      final localFpCanonical = localFp.replaceAll('=', '');
      final licenseFpCanonical = licenseJsonFp.replaceAll('=', '');
      final fpMatch = localFpCanonical == licenseFpCanonical;
      await logService.logInfo(
        "Step 5: Fingerprints – Local (canonical): $localFpCanonical, License (canonical): $licenseFpCanonical",
      );
      if (!fpMatch) {
        await logService.logWarning(
          "Verification FAILED: Fingerprint mismatch.",
        );
        return false;
      }
      await logService.logInfo("--- License Verification SUCCESS ---");
      return true;
    } catch (e, st) {
      await logService.logError(
        "Unexpected error during license verification.",
        e,
        st,
      );
      return false;
    }
  }

  Future<void> saveLicense(String licenseJson) async {
    final file = await _licenseFile;
    await file.writeAsString(licenseJson);
  }

  Future<bool> verifyAndSaveLicense(
    String licenseJson,
    LogService logService,
  ) async {
    final valid = await verifyLicense(licenseJson, logService);
    if (valid) await saveLicense(licenseJson);
    return valid;
  }

  Future<bool> hasValidLicense(LogService logService) async {
    final file = await _licenseFile;
    if (!await file.exists()) return false;
    final content = await file.readAsString();
    return verifyLicense(content, logService);
  }
}
