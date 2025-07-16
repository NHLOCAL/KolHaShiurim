import 'dart:async';
import 'dart:io';
import 'package.torah_shiurim_transfer/models/device_info.dart';

class DeviceService {
  Stream<List<ConnectedDeviceInfo>> watchConnectedDevices() {
    // Check more frequently for better responsiveness
    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => _getConnectedVolumes())
        // Use distinct to avoid emitting the same list of devices repeatedly
        .distinct((prev, next) => _areDeviceListsEqual(prev, next));
  }

  // Helper to compare lists of devices to avoid unnecessary stream events
  bool _areDeviceListsEqual(List<ConnectedDeviceInfo> a, List<ConnectedDeviceInfo> b) {
    if (a.length != b.length) return false;
    final aSerials = a.map((d) => d.serialNumber).toSet();
    final bSerials = b.map((d) => d.serialNumber).toSet();
    return aSerials.difference(bSerials).isEmpty && bSerials.difference(aSerials).isEmpty;
  }

  Future<List<ConnectedDeviceInfo>> _getConnectedVolumes() async {
    final List<ConnectedDeviceInfo> devices = [];
    if (Platform.isWindows) {
      try {
        // CHANGED: Using a more robust wmic command to get serial numbers for removable drives.
        // This command gets the drive letter (Name) and the volume serial number for physical, removable drives.
        final result = await Process.run('wmic', ['logicaldisk', 'where', 'drivetype=2', 'get', 'name,volumeserialnumber']);
        final output = result.stdout.toString();
        final lines = output.split('\n').skip(1); // Skip header line

        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final driveLetter = parts[0];
            final serial = parts.sublist(1).join(); // Serial might contain spaces
            if (driveLetter.isNotEmpty && serial.isNotEmpty) {
               devices.add(ConnectedDeviceInfo(mountPath: '$driveLetter\\', serialNumber: serial));
            }
          }
        }
      } catch (e) {
        // In a real app, use a proper logging framework
        print("Error getting drives on Windows: $e");
      }
    } else { // macOS / Linux (Simplified - uses path as serial)
      // NOTE: For a production app on macOS/Linux, you'd use command-line tools
      // like `diskutil` or `lsblk` and parse the output to get real serial numbers.
      // e.g., on Linux: `lsblk -o NAME,SERIAL`
      // e.g., on macOS: `diskutil info -all`
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