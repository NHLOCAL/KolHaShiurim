import 'dart:async';
import 'dart:io';
import 'package:device_manager/device_manager.dart';
import 'package:torah_shiurim_transfer/models/device_info.dart';

class DeviceService {
  final StreamController<List<ConnectedDeviceInfo>> _controller =
      StreamController.broadcast();

  DeviceService() {
    if (Platform.isWindows) {
      _handleDeviceChange();
      DeviceManager().addListener(_handleDeviceChange);
    }
  }

  Stream<List<ConnectedDeviceInfo>> watchConnectedDevices() {
    return _controller.stream
        .distinct((prev, next) => _areDeviceListsEqual(prev, next));
  }

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

  Future<String> changeVolumeSerialNumber(
      String mountPath, String newSerial) async {
    if (!Platform.isWindows) {
      throw UnsupportedError(
          'Changing serial number is only supported on Windows.');
    }

    final sanitizedSerial = newSerial.replaceAll('-', '');
    if (!RegExp(r'^[0-9A-Fa-f]{8}$').hasMatch(sanitizedSerial)) {
      throw const FormatException(
          'Invalid serial number format. Must be 8 hexadecimal characters (e.g., 1234-ABCD).');
    }
    final formattedSerialForTool =
        '${sanitizedSerial.substring(0, 4)}-${sanitizedSerial.substring(4)}';

    try {
      final result = await Process.run(
          'volumeid.exe', [mountPath, formattedSerialForTool]);

      if (result.exitCode != 0) {
        final stdErr = result.stderr.toString();
        if (stdErr.toLowerCase().contains('administrator') ||
            stdErr.toLowerCase().contains('elevation')) {
          throw Exception(
              'Administrator privileges required. Please restart the application as an administrator.');
        }
        throw Exception(
            'Failed to change serial number. Error: $stdErr\nMake sure the drive is not in use.');
      }

      _handleDeviceChange();
      return 'Serial change command sent successfully. Please replug the device for the change to take full effect. The new serial is $formattedSerialForTool.';
    } on ProcessException catch (e) {
      if (e.errorCode == 2) {
        throw Exception(
            '`volumeid.exe` tool not found. Please download it from Microsoft Sysinternals and place it in the application folder or a system PATH directory.');
      }
      throw Exception('Error executing volumeid.exe: $e');
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
