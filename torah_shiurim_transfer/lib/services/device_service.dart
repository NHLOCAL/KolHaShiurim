import 'dart:async';
import 'dart:io';
import 'package:torah_shiurim_transfer/models/device_info.dart';

class DeviceService {
  Stream<List<ConnectedDeviceInfo>> watchConnectedDevices() {
    return Stream.periodic(const Duration(seconds: 3))
        .asyncMap((_) => _getConnectedVolumes())
        .asBroadcastStream();
  }

  Future<List<ConnectedDeviceInfo>> _getConnectedVolumes() async {
    final List<ConnectedDeviceInfo> devices = [];
    if (Platform.isWindows) {
      try {
        // ... (השאר ללא שינוי)
        final result = await Process.run('wmic', ['logicaldisk', 'get', 'name']);
        final output = result.stdout.toString();
        final drives = output.split('\n')
            .map((s) => s.trim())
            .where((s) => s.contains(':'))
            .map((s) => '$s\\');
        for (final drive in drives) {
          // ב-Windows, אין דרך פשוטה לקבל Serial Number מהאות של הכונן בלבד.
          // נשתמש בנתיב כ"מספר סידורי" ייחודי לצורך הזיהוי.
          devices.add(ConnectedDeviceInfo(mountPath: drive, serialNumber: drive));
        }
      } catch (e) {
        print("Error getting drives on Windows: $e");
      }
    } else { // macOS / Linux
      final dir = Directory('/Volumes');
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is Directory) {
            // ב-macOS, שם התיקייה ב-/Volumes הוא בדרך כלל שם הכונן ומשמש כמזהה טוב.
            devices.add(ConnectedDeviceInfo(mountPath: entity.path, serialNumber: entity.path));
          }
        }
      }
    }
    return devices;
  }
}