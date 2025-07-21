import 'dart:convert';
import 'dart:ffi';
import 'dart:io'; // ← make sure this is here
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';
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

  /// Combines CPU ID, disk serial & MAC, then SHA‑256 → Base64Url.
  Future<String> getHardwareFingerprint() async {
    // 1) CPU info
    final sysInfo = calloc<SYSTEM_INFO>();
    GetSystemInfo(sysInfo);
    final cpuId =
        '${sysInfo.ref.wProcessorArchitecture}-${sysInfo.ref.dwNumberOfProcessors}-${sysInfo.ref.dwProcessorType}';
    calloc.free(sysInfo);

    // 2) Disk serial
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

    // 3) MAC address via WindowsSystemInfo
    String macAddress = '';
    await WindowsSystemInfo.initWindowsInfo(
      requiredValues: [WindowsSystemInfoFeat.network],
    );
    final adapters = WindowsSystemInfo.network;
    for (final adapter in adapters) {
      final mac = adapter.mac; // ← use `.mac`
      if (mac.isNotEmpty) {
        macAddress = mac;
        break;
      }
    }

    // Combine and hash
    final concat = 'cpu:$cpuId;disk:$diskSerial;mac:$macAddress';
    final hash =
        SHA256Digest().process(Uint8List.fromList(utf8.encode(concat)));
    return base64Url.encode(hash);
  }

  Future<bool> verifyLicense(String licenseJson) async {
    try {
      final jsonMap = json.decode(licenseJson) as Map<String, dynamic>;
      final signature = base64.decode(jsonMap['signature'] as String);

      // Rebuild payload
      final payloadMap = {
        'fingerprint': jsonMap['fingerprint'],
        'issued_to': jsonMap['issued_to'],
        'issued_on': jsonMap['issued_on'],
        'valid_until': jsonMap['valid_until'],
        'features': jsonMap['features'],
      };
      final payload = utf8.encode(json.encode(payloadMap));

      // RSA‑SHA256 verify
      final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
      signer.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
      if (!signer.verifySignature(
          Uint8List.fromList(payload), RSASignature(signature))) {
        return false;
      }

      // Date checks
      final now = DateTime.now();
      if (now.isBefore(DateTime.parse(jsonMap['issued_on'])) ||
          now.isAfter(DateTime.parse(jsonMap['valid_until']))) {
        return false;
      }

      // Fingerprint match
      final localFp = await getHardwareFingerprint();
      return localFp == jsonMap['fingerprint'];
    } catch (_) {
      return false;
    }
  }

  Future<void> saveLicense(String licenseJson) async {
    final file = await _licenseFile;
    await file.writeAsString(licenseJson);
  }

  Future<bool> verifyAndSaveLicense(String licenseJson) async {
    final valid = await verifyLicense(licenseJson);
    if (valid) await saveLicense(licenseJson);
    return valid;
  }

  Future<bool> hasValidLicense() async {
    final file = await _licenseFile;
    if (!await file.exists()) return false;
    final jsonStr = await file.readAsString();
    return verifyLicense(jsonStr);
  }
}
