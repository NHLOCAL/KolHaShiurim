import 'dart:async';
import 'dart:io';
import 'package:device_manager/device_manager.dart'; // הוספת חבילת device_manager
import 'package:torah_shiurim_transfer/models/device_info.dart';

class DeviceService {
  final StreamController<List<ConnectedDeviceInfo>> _controller =
      StreamController.broadcast();

  DeviceService() {
    if (Platform.isWindows) {
      // מאזינים לאירועי חיבור/ניתוק התקנים
      DeviceManager().addListener(_handleDeviceChange);
    }
  }

  /// זרם ששולח רשימת התקנים רק כשיש שינוי.
  Stream<List<ConnectedDeviceInfo>> watchConnectedDevices() {
    return _controller.stream
        .distinct((prev, next) => _areDeviceListsEqual(prev, next));
  }

  /// מטפל באירוע חיבור או ניתוק התקן
  void _handleDeviceChange() async {
    final devices = await _getConnectedVolumes();
    _controller.add(devices);
  }

  bool _areDeviceListsEqual(
      List<ConnectedDeviceInfo> a, List<ConnectedDeviceInfo> b) {
    if (a.length != b.length) return false;
    final aSerials = a.map((d) => d.serialNumber).toSet();
    final bSerials = b.map((d) => d.serialNumber).toSet();
    return aSerials.difference(bSerials).isEmpty &&
        bSerials.difference(aSerials).isEmpty;
  }

  Future<List<ConnectedDeviceInfo>> _getConnectedVolumes() async {
    final List<ConnectedDeviceInfo> devices = [];
    if (Platform.isWindows) {
      try {
        // שואלים את כל הדיסקים הלוגיים
        final result = await Process.run(
            'wmic', ['logicaldisk', 'get', 'name,volumeserialnumber']);
        final output = result.stdout.toString();
        final lines =
            output.split('\n').where((line) => line.trim().isNotEmpty).skip(1);

        for (final line in lines) {
          final trimmed = line.trim();
          final parts = trimmed.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final drive = parts[0];
            final serial = parts.sublist(1).join();
            if (drive.isNotEmpty && serial.isNotEmpty) {
              devices.add(
                  ConnectedDeviceInfo(mountPath: drive, serialNumber: serial));
            }
          }
        }
      } catch (e) {
        print("Error getting drives on Windows: $e");
      }
    } else {
      // macOS / Linux – אם נדרש
      final dir = Directory('/Volumes');
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is Directory) {
            devices.add(ConnectedDeviceInfo(
                mountPath: entity.path, serialNumber: entity.path));
          }
        }
      }
    }
    return devices;
  }

  /// לבירור: יש לסגור את ה-StreamController בעת סגירת האפליקציה
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
