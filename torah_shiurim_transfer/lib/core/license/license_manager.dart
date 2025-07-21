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
import 'package:torah_shiurim_transfer/services/log_service.dart';
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

  Future<String> getHardwareFingerprint() async {
    final sysInfo = calloc<SYSTEM_INFO>();
    GetSystemInfo(sysInfo);
    final cpuId =
        '${sysInfo.ref.wProcessorArchitecture}-${sysInfo.ref.dwNumberOfProcessors}-${sysInfo.ref.dwProcessorType}';
    calloc.free(sysInfo);

    final volName = calloc<Uint16>(MAX_PATH).cast<Utf16>();
    final fsName = calloc<Uint16>(MAX_PATH).cast<Utf16>();
    final serialPtr = calloc<DWORD>();
    String diskSerial = '';
    if (GetVolumeInformation(TEXT('C:\\'), volName, MAX_PATH, serialPtr,
            nullptr, nullptr, fsName, MAX_PATH) !=
        0) {
      diskSerial = serialPtr.value.toRadixString(16).toUpperCase();
    }
    calloc.free(volName);
    calloc.free(fsName);
    calloc.free(serialPtr);

    String macAddress = '';
    await WindowsSystemInfo.initWindowsInfo(
      requiredValues: [WindowsSystemInfoFeat.network],
    );
    final adapters = WindowsSystemInfo.network;
    for (final adapter in adapters) {
      final mac = adapter.mac;
      if (mac.isNotEmpty) {
        macAddress = mac;
        break;
      }
    }

    final concat = 'cpu:$cpuId;disk:$diskSerial;mac:$macAddress';
    final hash =
        SHA256Digest().process(Uint8List.fromList(utf8.encode(concat)));
    // Explicitly remove padding for Base64Url canonical form.
    return base64Url.encode(hash).replaceAll('=', '');
  }

  Future<bool> verifyLicense(String licenseJson, LogService logService) async {
    await logService.logInfo("--- Starting License Verification ---");
    try {
      final jsonMap = json.decode(licenseJson) as Map<String, dynamic>;
      await logService.logInfo("Step 1: License JSON parsed successfully.");

      final sigB64 = jsonMap['signature'] as String;
      final signatureBytes = base64Url.decode(sigB64);
      await logService.logInfo(
          "Step 2: Signature decoded. Length: ${signatureBytes.length} bytes.");

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
          payloadBytesUint8, RSASignature(signatureBytes));
      await logService
          .logInfo("Step 3: Signature verification result: $isValid");

      if (!isValid) {
        await logService.logWarning("Verification FAILED: Invalid signature.");
        return false;
      }

      final now = DateTime.now();
      final issuedOn = DateTime.parse(jsonMap['issued_on']);
      final validUntil = DateTime.parse(jsonMap['valid_until']);
      await logService.logInfo(
          "Step 4: Now=$now, IssuedOn=$issuedOn, ValidUntil=$validUntil");
      if (now.isBefore(issuedOn) || now.isAfter(validUntil)) {
        await logService.logWarning("Verification FAILED: License not active.");
        return false;
      }

      final localFp = await getHardwareFingerprint();
      final licenseJsonFp = jsonMap['fingerprint'] as String;

      // Ensure both fingerprints are in canonical form (no padding) for comparison
      final localFpCanonical = localFp.replaceAll('=', '');
      final licenseFpCanonical = licenseJsonFp.replaceAll('=', '');

      final fpMatch = localFpCanonical == licenseFpCanonical;
      await logService.logInfo(
          "Step 5: Fingerprints – Local (canonical): $localFpCanonical, License (canonical): $licenseFpCanonical");
      if (!fpMatch) {
        await logService
            .logWarning("Verification FAILED: Fingerprint mismatch.");
        return false;
      }

      await logService.logInfo("--- License Verification SUCCESS ---");
      return true;
    } catch (e, st) {
      await logService.logError(
          "Unexpected error during license verification.", e, st);
      return false;
    }
  }

  Future<void> saveLicense(String licenseJson) async {
    final file = await _licenseFile;
    await file.writeAsString(licenseJson);
  }

  Future<bool> verifyAndSaveLicense(
      String licenseJson, LogService logService) async {
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
