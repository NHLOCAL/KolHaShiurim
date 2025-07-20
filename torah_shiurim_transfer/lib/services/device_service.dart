import 'dart:async';
import 'dart:io';
import 'package:device_manager/device_manager.dart';
import 'package:torah_shiurim_transfer/models/device_info.dart';
import 'package:torah_shiurim_transfer/services/log_service.dart'; // NEW

class DeviceService {
  final StreamController<List<ConnectedDeviceInfo>> _controller =
      StreamController.broadcast();
  final LogService _logService; // NEW: Declare LogService

  DeviceService(this._logService) {
    // NEW: Constructor takes LogService
    _logService.logInfo('DeviceService initialized.'); // NEW
    if (Platform.isWindows) {
      _handleDeviceChange();
      DeviceManager().addListener(_handleDeviceChange);
      _logService.logInfo('DeviceManager listener added for Windows.'); // NEW
    } else {
      // NEW: Log for non-Windows platforms
      _logService.logInfo(
          'DeviceManager listener not supported on current platform: ${Platform.operatingSystem}'); // NEW
      // On non-Windows, we might still want to get initial devices.
      _handleDeviceChange();
    }
  }

  Stream<List<ConnectedDeviceInfo>> watchConnectedDevices() {
    return _controller.stream
        .distinct((prev, next) => _areDeviceListsEqual(prev, next));
  }

  void _handleDeviceChange() async {
    _logService.logInfo('Handling device change event.'); // NEW
    try {
      // NEW: Add try-catch for device detection
      final devices = await _getConnectedVolumes();
      _controller.add(devices);
      _logService.logInfo(
          'Updated connected devices list: ${devices.length} devices found.'); // NEW
    } catch (e, st) {
      // NEW: Catch and log error
      _logService.logError('Error handling device change', e, st); // NEW
    }
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
        _logService.logInfo(
            'Detected ${devices.length} volumes on Windows via WMIC.'); // NEW
      } catch (e, st) {
        // NEW: Catch and log error
        _logService.logError(
            "Error getting drives on Windows using WMIC", e, st); // NEW
      }
    } else {
      // macOS / Linux – אם נדרש
      final dir = Directory('/Volumes');
      if (await dir.exists()) {
        try {
          // NEW: Add try-catch for directory listing
          await for (final entity in dir.list()) {
            if (entity is Directory) {
              devices.add(ConnectedDeviceInfo(
                  mountPath: entity.path,
                  serialNumber:
                      entity.path)); // Simple path as serial for non-Windows
            }
          }
          _logService.logInfo(
              'Detected ${devices.length} volumes on non-Windows via /Volumes.'); // NEW
        } catch (e, st) {
          // NEW: Catch and log error
          _logService.logError(
              "Error getting drives on non-Windows from /Volumes",
              e,
              st); // NEW
        }
      } else {
        // NEW: Log if /Volumes does not exist
        _logService.logWarning(
            'Directory /Volumes does not exist on this non-Windows system.'); // NEW
      }
    }
    return devices;
  }

  Future<String> changeVolumeSerialNumber(
      String mountPath, String newSerial) async {
    _logService.logUserActivity(
        'Attempting to change serial number for $mountPath to $newSerial.'); // NEW
    if (!Platform.isWindows) {
      _logService.logError(
          'Attempted to change serial number on unsupported platform: ${Platform.operatingSystem}'); // NEW
      throw UnsupportedError(
          'Changing serial number is only supported on Windows.');
    }

    final sanitizedSerial = newSerial.replaceAll('-', '');
    if (!RegExp(r'^[0-9A-Fa-f]{8}$').hasMatch(sanitizedSerial)) {
      _logService
          .logError('Invalid serial number format provided: $newSerial'); // NEW
      throw const FormatException(
          'Invalid serial number format. Must be 8 hexadecimal characters (e.g., 1234-ABCD).');
    }
    final formattedSerialForTool =
        '${sanitizedSerial.substring(0, 4)}-${sanitizedSerial.substring(4)}';

    try {
      _logService.logInfo(
          'Executing volumeid.exe with arguments: $mountPath, $formattedSerialForTool'); // NEW
      final result = await Process.run(
          'volumeid.exe', [mountPath, formattedSerialForTool]);

      if (result.exitCode != 0) {
        final stdErr = result.stderr.toString();
        String errorMessage =
            'Failed to change serial number. Error: $stdErr\nMake sure the drive is not in use.';
        if (stdErr.toLowerCase().contains('administrator') ||
            stdErr.toLowerCase().contains('elevation')) {
          errorMessage =
              'Administrator privileges required. Please restart the application as an administrator.';
        }
        _logService.logError(
            'volumeid.exe failed (exit code ${result.exitCode}): $errorMessage. StdOut: ${result.stdout}',
            null,
            StackTrace.current); // NEW
        throw Exception(errorMessage);
      }

      _handleDeviceChange(); // Trigger a device re-scan
      final successMessage =
          'Serial change command sent successfully. Please replug the device for the change to take full effect. The new serial is $formattedSerialForTool.';
      _logService.logUserActivity(
          'Serial number for $mountPath successfully changed to $formattedSerialForTool.'); // NEW
      return successMessage;
    } on ProcessException catch (e, st) {
      // NEW: Catch and log process execution errors
      if (e.errorCode == 2) {
        _logService.logError('volumeid.exe tool not found.', e, st); // NEW
        throw Exception(
            '`volumeid.exe` tool not found. Please download it from Microsoft Sysinternals and place it in the application folder or a system PATH directory.');
      }
      _logService.logError('Error executing volumeid.exe', e, st); // NEW
      throw Exception('Error executing volumeid.exe: $e');
    } catch (e, st) {
      // NEW: Catch and log other errors
      _logService.logError(
          'Unknown error during serial number change.', e, st); // NEW
      rethrow;
    }
  }

  void dispose() {
    _logService.logInfo('DeviceService disposed.'); // NEW
    if (!_controller.isClosed) {
      _controller.close();
    }
    if (Platform.isWindows) {
      // NEW: Remove listener on dispose
      DeviceManager().removeListener(_handleDeviceChange); // NEW
    } // NEW
  }
}
