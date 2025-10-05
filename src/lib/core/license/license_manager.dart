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
    final appDir = Directory(p.join(dir.path, 'KolHaShiurim'));
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return File(p.join(appDir.path, 'app.lic'));
  }

  Future<String?> _getPowerShellInfo(
    String command,
    LogService logService,
  ) async {
    try {
      final result = await Process.run('powershell.exe', ['-Command', command]);
      if (result.exitCode == 0 && result.stdout is String) {
        final value = result.stdout.toString().trim();
        if (value.isNotEmpty &&
            !value.toLowerCase().contains('to be filled by o.e.m.')) {
          await logService.logInfo(
            'PowerShell command "$command" success: $value',
          );
          return value;
        }
      }
      await logService.logWarning(
        'PowerShell command "$command" failed or returned empty. Exit code: ${result.exitCode}, StdErr: ${result.stderr}',
      );
      return null;
    } catch (e, st) {
      await logService.logError(
        'Exception running PowerShell command "$command"',
        e,
        st,
      );
      return null;
    }
  }

  Future<String> getHardwareFingerprint(LogService logService) async {
    await logService.logInfo("--- Generating Hardware Fingerprint ---");
    final cpuId = await _getPowerShellInfo(
      '(Get-CimInstance Win32_Processor).ProcessorId',
      logService,
    );
    final baseboardSerial = await _getPowerShellInfo(
      '(Get-CimInstance Win32_BaseBoard).SerialNumber',
      logService,
    );
    final systemUuid = await _getPowerShellInfo(
      '(Get-CimInstance Win32_ComputerSystemProduct).UUID',
      logService,
    );
    final diskSerial = await _getPowerShellInfo(
      r'(Get-CimInstance Win32_DiskDrive | Where-Object { $_.Index -eq 0 }).SerialNumber',
      logService,
    );
    final components = <String>[];
    if (cpuId != null && cpuId.isNotEmpty) components.add('cpu:$cpuId');
    if (systemUuid != null && systemUuid.isNotEmpty) {
      components.add('uuid:$systemUuid');
    }
    if (diskSerial != null && diskSerial.isNotEmpty) {
      components.add('disk:$diskSerial');
    }
    if (baseboardSerial != null && baseboardSerial.isNotEmpty) {
      components.add('board:$baseboardSerial');
    }
    if (cpuId == null && baseboardSerial == null && systemUuid == null) {
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
