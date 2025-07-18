import 'dart:async';
import 'dart:io';
// FIXED: Corrected the import path. This was the source of many errors.
import 'package:torah_shiurim_transfer/models/device_info.dart';

class DeviceService {
  Stream<List<ConnectedDeviceInfo>> watchConnectedDevices() {
    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => _getConnectedVolumes())
        .distinct((prev, next) => _areDeviceListsEqual(prev, next));
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
        // MODIFIED: Query all logical disks, not just removable ones.
        final result = await Process.run(
            'wmic', ['logicaldisk', 'get', 'name,volumeserialnumber']);
        final output = result.stdout.toString();
        // MODIFIED: Improved parsing to be more robust.
        final lines =
            output.split('\n').where((line) => line.trim().isNotEmpty).skip(1);

        for (final line in lines) {
          // Trim the line and then look for the position of the first space.
          final trimmedLine = line.trim();
          final spaceIndex = trimmedLine.indexOf(' ');

          if (spaceIndex != -1 && spaceIndex + 1 < trimmedLine.length) {
            // The drive letter is before the first space.
            final driveLetter = trimmedLine.substring(0, spaceIndex).trim();
            // The serial number is everything after the first space.
            final serial = trimmedLine.substring(spaceIndex + 1).trim();

            if (driveLetter.isNotEmpty && serial.isNotEmpty) {
              devices.add(ConnectedDeviceInfo(
                  mountPath: driveLetter, serialNumber: serial));
            }
          }
        }
      } catch (e) {
        print("Error getting drives on Windows: $e");
      }
    } else {
      // macOS / Linux
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
}
