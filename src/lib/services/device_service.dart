import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:kol_hashiurim/models/device_info.dart';
import 'package:kol_hashiurim/services/log_service.dart';

class DeviceService {
  final _controller = StreamController<List<ConnectedDeviceInfo>>.broadcast();
  final LogService _logService;
  Timer? _pollingTimer;
  Future<void>? _scanInProgress;
  static const _pollingInterval = Duration(seconds: 5);
  static const _powershellDeviceQuery = r'''
$ErrorActionPreference = 'Stop'
@(
  Get-CimInstance Win32_LogicalDisk |
    Where-Object { $_.DriveType -eq 2 -and $_.VolumeSerialNumber } |
    Select-Object -Property DeviceID, VolumeSerialNumber
) | ConvertTo-Json -Compress
''';
  DeviceService(this._logService) {
    _logService.logInfo('DeviceService initialized.');
  }
  Stream<List<ConnectedDeviceInfo>> watchConnectedDevices() =>
      _controller.stream.distinct((a, b) => _areEqual(a, b));
  Future<List<ConnectedDeviceInfo>> getConnectedDevices() async {
    return _getDevices();
  }

  void startPolling() {
    if (_pollingTimer?.isActive ?? false) {
      _logService.logInfo('Polling is already active.');
      return;
    }
    _logService.logInfo('Starting device polling.');
    _refreshDevices();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) => _refreshDevices());
  }

  void stopPolling() {
    if (_pollingTimer?.isActive ?? false) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
      _logService.logInfo('Device polling stopped.');
    }
  }

  Future<void> _refreshDevices() async {
    final devices = await _getDevices();
    if (!_controller.isClosed) {
      _controller.add(devices);
    }
  }

  Future<List<ConnectedDeviceInfo>> _getDevices() async {
    while (_scanInProgress != null) {
      await _scanInProgress;
    }
    final completer = Completer<void>();
    _scanInProgress = completer.future;
    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          _powershellDeviceQuery,
        ],
        runInShell: true,
      );
      if (result.exitCode != 0) {
        final errorOutput = _decodeProcessOutput(result.stderr);
        _logService.logError(
          'Failed to enumerate removable drives via PowerShell.',
          'ExitCode: ${result.exitCode}, StdErr: $errorOutput',
        );
        return <ConnectedDeviceInfo>[];
      }
      final output = _decodeProcessOutput(result.stdout).trim();
      if (output.isEmpty || output == '[]' || output == 'null') {
        return <ConnectedDeviceInfo>[];
      }
      dynamic decoded;
      try {
        decoded = jsonDecode(output);
      } on FormatException catch (e, st) {
        _logService.logError(
          'Failed to parse PowerShell drive enumeration output.',
          e,
          st,
        );
        return <ConnectedDeviceInfo>[];
      }
      final Iterable<dynamic> items = decoded is List ? decoded : [decoded];
      final devices = <ConnectedDeviceInfo>[];
      for (final item in items) {
        if (item is! Map) {
          continue;
        }
        final deviceId = item['DeviceID'] as String?;
        final volumeSerial = item['VolumeSerialNumber'] as String?;
        if (deviceId == null || deviceId.isEmpty) {
          continue;
        }
        if (volumeSerial == null || volumeSerial.isEmpty) {
          _logService.logInfo(
            'Skipping removable drive $deviceId because it has no volume serial number.',
          );
          continue;
        }
        final formattedSerial = _formatSerial(volumeSerial);
        if (formattedSerial == null) {
          _logService.logWarning(
            'Skipping removable drive $deviceId due to unexpected serial format: $volumeSerial',
          );
          continue;
        }
        devices.add(
          ConnectedDeviceInfo(
            mountPath: _normalizeMountPath(deviceId),
            serialNumber: formattedSerial,
          ),
        );
      }
      devices.sort((a, b) => a.mountPath.compareTo(b.mountPath));
      return devices;
    } catch (e, st) {
      _logService.logError('Error enumerating drives', e, st);
      return <ConnectedDeviceInfo>[];
    } finally {
      completer.complete();
      _scanInProgress = null;
    }
  }

  String _normalizeMountPath(String deviceId) {
    final normalized = deviceId.trim().replaceAll('/', '\\').toUpperCase();
    if (normalized.isEmpty) {
      return normalized;
    }
    return normalized.endsWith('\\') ? normalized : '$normalized\\';
  }

  String? _formatSerial(String serial) {
    final sanitized = serial.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    if (sanitized.length != 8) {
      return null;
    }
    return '${sanitized.substring(0, 4)}-${sanitized.substring(4)}';
  }

  String _decodeProcessOutput(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    if (value is List<int>) {
      try {
        return utf8.decode(value);
      } catch (_) {
        return String.fromCharCodes(value);
      }
    }
    return value.toString();
  }

  bool _areEqual(List<ConnectedDeviceInfo> a, List<ConnectedDeviceInfo> b) {
    if (a.length != b.length) return false;
    final sa = a.map((d) => d.serialNumber).toSet();
    final sb = b.map((d) => d.serialNumber).toSet();
    return sa.containsAll(sb) && sb.containsAll(sa);
  }

  Future<String> changeVolumeSerialNumber(String mount, String serial) async {
    _logService.logUserActivity('Changing serial for $mount to $serial.');
    final s = serial.replaceAll('-', '');
    if (!RegExp(r'^[0-9A-Fa-f]{8}$').hasMatch(s)) {
      _logService.logError('Invalid serial: $serial');
      throw const FormatException('Use 8 hex digits, e.g. 1234ABCD.');
    }
    final formatted = '${s.substring(0, 4)}-${s.substring(4)}';
    try {
      final tempDir = await getTemporaryDirectory();
      final volumeIdPath = p.join(tempDir.path, 'Volumeid.exe');
      final volumeIdFile = File(volumeIdPath);
      final byteData = await rootBundle.load('assets/bin/Volumeid.exe');
      await volumeIdFile.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
      final result = await Process.run(volumeIdPath, [
        mount,
        formatted,
      ], runInShell: true);
      await volumeIdFile.delete();
      if (result.exitCode != 0) {
        final errorOutput = _decodeProcessOutput(result.stderr);
        _logService.logError('volumeid.exe failed: $errorOutput');
        throw Exception(
          'Failed to execute volumeid.exe. Error: $errorOutput',
        );
      }
      await _refreshDevices();
      _logService.logUserActivity('Serial for $mount changed to $formatted.');
      return 'Serial changed to $formatted. Replug device to apply.';
    } catch (e, st) {
      _logService.logError('Error running volumeid.exe', e, st);
      throw Exception('Could not change serial number. See logs for details.');
    }
  }

  void dispose() {
    stopPolling();
    if (!_controller.isClosed) {
      _controller.close();
    }
    _logService.logInfo('DeviceService disposed.');
  }
}
