import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_manager/device_manager.dart';
import 'package:torah_shiurim_transfer/models/device_info.dart';
import 'package:torah_shiurim_transfer/services/log_service.dart';

class DeviceService {
  final StreamController<List<ConnectedDeviceInfo>> _controller =
      StreamController.broadcast();
  final LogService _logService;

  DeviceService(this._logService) {

    _logService.logInfo('DeviceService initialized.');
    if (Platform.isWindows) {
      _handleDeviceChange();
      DeviceManager().addListener(_handleDeviceChange);
      _logService.logInfo('DeviceManager listener added for Windows.');
    } else {

      _logService.logInfo(
          'DeviceManager listener not supported on current platform: ${Platform.operatingSystem}');

      _handleDeviceChange();
    }
  }

  Stream<List<ConnectedDeviceInfo>> watchConnectedDevices() {
    return _controller.stream
        .distinct((prev, next) => _areDeviceListsEqual(prev, next));
  }

  void _handleDeviceChange() async {
    _logService.logInfo('Handling device change event.');
    try {

      final devices = await _getConnectedVolumes();
      _controller.add(devices);
      _logService.logInfo(
          'Updated connected devices list: ${devices.length} devices found.');
    } catch (e, st) {

      _logService.logError('Error handling device change', e, st);
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
        final result = await Process.run('powershell.exe', [
          '-NoProfile',
          '-Command',
          "Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object DeviceID, VolumeSerialNumber | Where-Object { \$_.VolumeSerialNumber -ne \$null } | ConvertTo-Json"
        ]);

        if (result.exitCode != 0) {
          _logService.logError(
              "PowerShell command to get volumes failed with exit code ${result.exitCode}",
              result.stderr,
              StackTrace.current);
          return [];
        }

        final output = result.stdout.toString().trim();
        if (output.isEmpty) {
          _logService.logInfo('No volumes found from PowerShell.');
          return [];
        }

        final jsonResult = jsonDecode(output);
        
        final List<dynamic> driveList =
            jsonResult is List ? jsonResult : [jsonResult];

        for (final driveData in driveList) {
          if (driveData is Map<String, dynamic> &&
              driveData.containsKey('DeviceID') &&
              driveData.containsKey('VolumeSerialNumber')) {
            final drive = driveData['DeviceID'] as String;
            final serial = driveData['VolumeSerialNumber'] as String;
            if (drive.isNotEmpty && serial.isNotEmpty) {
              devices.add(
                  ConnectedDeviceInfo(mountPath: drive, serialNumber: serial));
            }
          }
        }
        _logService.logInfo(
            'Detected ${devices.length} volumes on Windows via PowerShell.');
      } catch (e, st) {
        _logService.logError(
            "Error getting drives on Windows using PowerShell", e, st);
      }
    } else {
      
      final dir = Directory('/Volumes');
      if (await dir.exists()) {
        try {

          await for (final entity in dir.list()) {
            if (entity is Directory) {
              devices.add(ConnectedDeviceInfo(
                  mountPath: entity.path,
                  serialNumber:
                      entity.path));
            }
          }
          _logService.logInfo(
              'Detected ${devices.length} volumes on non-Windows via /Volumes.');
        } catch (e, st) {

          _logService.logError(
              "Error getting drives on non-Windows from /Volumes",
              e,
              st);
        }
      } else {

        _logService.logWarning(
            'Directory /Volumes does not exist on this non-Windows system.');
      }
    }
    return devices;
  }

  Future<String> changeVolumeSerialNumber(
      String mountPath, String newSerial) async {
    _logService.logUserActivity(
        'Attempting to change serial number for $mountPath to $newSerial.');
    if (!Platform.isWindows) {
      _logService.logError(
          'Attempted to change serial number on unsupported platform: ${Platform.operatingSystem}');
      throw UnsupportedError(
          'Changing serial number is only supported on Windows.');
    }

    final sanitizedSerial = newSerial.replaceAll('-', '');
    if (!RegExp(r'^[0-9A-Fa-f]{8}$').hasMatch(sanitizedSerial)) {
      _logService
          .logError('Invalid serial number format provided: $newSerial');
      throw const FormatException(
          'Invalid serial number format. Must be 8 hexadecimal characters (e.g., 1234-ABCD).');
    }
    final formattedSerialForTool =
        '${sanitizedSerial.substring(0, 4)}-${sanitizedSerial.substring(4)}';

    try {
      _logService.logInfo(
          'Executing volumeid.exe with arguments: $mountPath, $formattedSerialForTool');
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
            StackTrace.current);
        throw Exception(errorMessage);
      }

      _handleDeviceChange();
      final successMessage =
          'Serial change command sent successfully. Please replug the device for the change to take full effect. The new serial is $formattedSerialForTool.';
      _logService.logUserActivity(
          'Serial number for $mountPath successfully changed to $formattedSerialForTool.');
      return successMessage;
    } on ProcessException catch (e, st) {

      if (e.errorCode == 2) {
        _logService.logError('volumeid.exe tool not found.', e, st);
        throw Exception(
            '`volumeid.exe` tool not found. Please download it from Microsoft Sysinternals and place it in the application folder or a system PATH directory.');
      }
      _logService.logError('Error executing volumeid.exe', e, st);
      throw Exception('Error executing volumeid.exe: $e');
    } catch (e, st) {

      _logService.logError(
          'Unknown error during serial number change.', e, st);
      rethrow;
    }
  }

  void dispose() {
    _logService.logInfo('DeviceService disposed.');
    if (!_controller.isClosed) {
      _controller.close();
    }
    if (Platform.isWindows) {

      DeviceManager().removeListener(_handleDeviceChange);
    }
  }
}