import 'dart:async';
import 'dart:io';
import 'package:torah_shiurim_transfer/models/device_info.dart';

class DeviceService {
  // --- MOCK IMPLEMENTATION ---
  // In a real application, this service would use Platform Channels to
  // communicate with native code (WMI on Windows, IOKit on macOS)
  // to get the actual hardware serial number for each volume.
  // For this demo, we use the drive's mount path (e.g., 'E:\') as a unique ID.

  Stream<List<ConnectedDeviceInfo>> watchConnectedDevices() {
    // This stream polls the filesystem every 3 seconds to check for new drives.
    return Stream.periodic(const Duration(seconds: 3), (_) {
      return _getConnectedVolumes();
    }).asBroadcastStream();
  }

  Future<List<ConnectedDeviceInfo>> _getConnectedVolumes() async {
    final List<ConnectedDeviceInfo> devices = [];
    if (Platform.isWindows) {
      try {
        final result = await Process.run('wmic', ['logicaldisk', 'get', 'name']);
        final output = result.stdout.toString();
        final drives = output.split('\n')
            .map((s) => s.trim())
            .where((s) => s.contains(':'))
            .map((s) => '$s\\');
        
        for (final drive in drives) {
          // Using the drive letter itself as the "serial number" for this mock.
          devices.add(ConnectedDeviceInfo(mountPath: drive, serialNumber: drive));
        }
      } catch (e) {
        print("Error getting drives on Windows: $e");
      }
    } else { // macOS and Linux - a simpler check
      final dir = Directory('/Volumes'); // Common on macOS
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is Directory) {
            devices.add(ConnectedDeviceInfo(mountPath: entity.path, serialNumber: entity.path));
          }
        }
      }
    }
    return devices;
  }
}