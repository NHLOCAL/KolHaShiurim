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
        final result = await Process.run('wmic', ['logicaldisk', 'where', 'drivetype=2', 'get', 'name,volumeserialnumber']);
        final output = result.stdout.toString();
        final lines = output.split('\n').skip(1);

        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final driveLetter = parts[0];
            final serial = parts.sublist(1).join();
            if (driveLetter.isNotEmpty && serial.isNotEmpty) {
               // The constructor for ConnectedDeviceInfo is now correctly found.
               devices.add(ConnectedDeviceInfo(mountPath: '$driveLetter\\', serialNumber: serial));
            }
          }
        }
      } catch (e) {
        print("Error getting drives on Windows: $e");
      }
    } else { // macOS / Linux
      final dir = Directory('/Volumes');
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is Directory) {
            // The constructor for ConnectedDeviceInfo is now correctly found.
            devices.add(ConnectedDeviceInfo(mountPath: entity.path, serialNumber: entity.path));
          }
        }
      }
    }
    return devices;
  }
}