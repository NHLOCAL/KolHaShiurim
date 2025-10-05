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
  Timer? _fallbackTimer;
  Timer? _eventDebounceTimer;
  Future<void>? _scanInProgress;
  Process? _eventWatcherProcess;
  StreamSubscription<String>? _eventWatcherStdoutSub;
  StreamSubscription<String>? _eventWatcherStderrSub;
  bool _eventWatcherStarting = false;
  bool _eventWatcherStopRequested = false;
  bool _pendingEventWatcherRestart = false;
  static const _pollingInterval = Duration(seconds: 5);
  static const _powershellDeviceQuery = r'''
$ErrorActionPreference = 'Stop'
@(
  Get-CimInstance Win32_LogicalDisk |
    Where-Object { $_.DriveType -eq 2 -and $_.VolumeSerialNumber } |
    Select-Object -Property DeviceID, VolumeSerialNumber
) | ConvertTo-Json -Compress
''';
  static const _powershellVolumeWatcherScript = r'''
$ErrorActionPreference = 'Stop'
$sourceId = 'KolHashiurimVolumeWatcher'
if (Get-EventSubscriber -SourceIdentifier $sourceId -ErrorAction SilentlyContinue) {
  Unregister-Event -SourceIdentifier $sourceId | Out-Null
}
Register-WmiEvent -Class Win32_VolumeChangeEvent -SourceIdentifier $sourceId | Out-Null
try {
  while ($true) {
    $evt = Wait-Event -SourceIdentifier $sourceId
    if ($null -ne $evt) {
      $newEvent = $evt.SourceEventArgs.NewEvent
      $drive = $newEvent.DriveName
      $type = $newEvent.EventType
      if ($drive) {
        Write-Output (@{ EventType = $type; Drive = $drive } | ConvertTo-Json -Compress)
      }
      Remove-Event -EventIdentifier $evt.EventIdentifier | Out-Null
    }
  }
} finally {
  Unregister-Event -SourceIdentifier $sourceId -ErrorAction SilentlyContinue | Out-Null
}
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
    if (!Platform.isWindows) {
      if (_fallbackTimer?.isActive ?? false) {
        _logService.logInfo('Fallback device polling already active.');
        return;
      }
      unawaited(_refreshDevices());
      _startFallbackTimer(reason: 'unsupported platform');
      return;
    }
    if (_eventWatcherProcess != null) {
      if (_eventWatcherStopRequested) {
        _pendingEventWatcherRestart = true;
        _logService.logInfo(
          'Device monitoring restart requested; waiting for current watcher to stop.',
        );
      } else {
        _logService.logInfo('Device monitoring already active.');
      }
      return;
    }
    if (_eventWatcherStarting) {
      _logService.logInfo('Device monitoring start already in progress.');
      return;
    }
    _pendingEventWatcherRestart = false;
    _logService.logInfo('Starting device monitoring using Win32 volume events.');
    _stopFallbackTimer();
    unawaited(_refreshDevices());
    unawaited(_startEventWatcher());
  }

  void stopPolling() {
    final hadFallback = _fallbackTimer != null;
    _stopFallbackTimer();
    _eventDebounceTimer?.cancel();
    _eventDebounceTimer = null;
    _pendingEventWatcherRestart = false;
    if (_eventWatcherProcess != null) {
      _eventWatcherStopRequested = true;
      _logService.logInfo('Stopping volume event watcher.');
      _eventWatcherProcess!.kill();
    } else if (_eventWatcherStarting) {
      _eventWatcherStopRequested = true;
      _logService.logInfo(
        'Volume event watcher start in progress; stop will take effect once ready.',
      );
    } else if (hadFallback) {
      _logService.logInfo('Fallback device polling stopped.');
    } else {
      _logService.logInfo('Device monitoring is not active.');
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

  Future<void> _startEventWatcher() async {
    if (!Platform.isWindows || _eventWatcherProcess != null || _eventWatcherStarting) {
      return;
    }
    _eventWatcherStarting = true;
    try {
      final process = await Process.start(
        'powershell.exe',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          _powershellVolumeWatcherScript,
        ],
        runInShell: true,
      );
      _eventWatcherProcess = process;
      _eventWatcherStopRequested = false;
      _stopFallbackTimer();
      _logService.logInfo('Volume event watcher started (PID ${process.pid}).');

      _eventWatcherStdoutSub = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        _handleVolumeWatcherLine,
        onError: (Object error, StackTrace stackTrace) {
          _logService.logError('Volume event watcher stdout error.', error, stackTrace);
        },
      );

      _eventWatcherStderrSub = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (String line) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            _logService.logWarning('Volume event watcher stderr: $trimmed');
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _logService.logError('Volume event watcher stderr stream error.', error, stackTrace);
        },
      );

      unawaited(process.exitCode.then(_handleWatcherExit));
    } on ProcessException catch (e, st) {
      _logService.logError('Failed to start volume event watcher process.', e, st);
      _startFallbackTimer(reason: 'failed to start volume event watcher');
    } catch (e, st) {
      _logService.logError('Unexpected error starting volume event watcher.', e, st);
      _startFallbackTimer(reason: 'volume event watcher error');
    } finally {
      _eventWatcherStarting = false;
    }
  }

  void _handleVolumeWatcherLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return;
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (e, st) {
      _logService.logWarning(
        'Ignoring malformed volume watcher output: $trimmed',
        e,
        st,
      );
      return;
    }
    if (decoded is! Map) {
      return;
    }
    final drive = decoded['Drive'];
    if (drive is! String || drive.isEmpty) {
      return;
    }
    final normalizedDrive = _normalizeMountPath(drive);
    final eventTypeValue = decoded['EventType'];
    final int? eventType = eventTypeValue is int
        ? eventTypeValue
        : int.tryParse(eventTypeValue?.toString() ?? '');
    if (eventType != null && eventType != 2 && eventType != 3) {
      _logService.logInfo(
        'Ignoring volume event type ${_describeVolumeEventType(eventType)} for $normalizedDrive.',
      );
      return;
    }
    final description = eventType != null
        ? _describeVolumeEventType(eventType)
        : 'unknown';
    _logService.logInfo(
      'Volume event ($description) detected for $normalizedDrive. Scheduling device refresh.',
    );
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _eventDebounceTimer?.cancel();
    _eventDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(_refreshDevices());
    });
  }

  void _startFallbackTimer({String? reason}) {
    if (_fallbackTimer?.isActive ?? false) {
      return;
    }
    final suffix = reason == null ? '' : ' ($reason)';
    _logService.logWarning(
      'Using fallback device polling every ${_pollingInterval.inSeconds} seconds$suffix.',
    );
    _fallbackTimer = Timer.periodic(_pollingInterval, (_) {
      unawaited(_refreshDevices());
    });
    unawaited(_refreshDevices());
  }

  void _stopFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  void _handleWatcherExit(int exitCode) {
    unawaited(_eventWatcherStdoutSub?.cancel());
    unawaited(_eventWatcherStderrSub?.cancel());
    _eventWatcherStdoutSub = null;
    _eventWatcherStderrSub = null;
    _eventWatcherProcess = null;

    final expectedStop = _eventWatcherStopRequested;
    final restartRequested = _pendingEventWatcherRestart;
    _eventWatcherStopRequested = false;
    _pendingEventWatcherRestart = false;

    if (restartRequested && Platform.isWindows) {
      _logService.logInfo(
        'Restarting volume event watcher after stop (previous exit code $exitCode).',
      );
      unawaited(_startEventWatcher());
      return;
    }

    if (expectedStop) {
      _logService.logInfo('Volume event watcher stopped (exit code $exitCode).');
      return;
    }

    if (Platform.isWindows) {
      _logService.logWarning(
        'Volume event watcher exited unexpectedly (code $exitCode). Attempting restart.',
      );
      unawaited(_startEventWatcher());
    } else {
      _startFallbackTimer(reason: 'event watcher unavailable');
    }
  }

  String _describeVolumeEventType(int type) {
    switch (type) {
      case 1:
        return 'configuration change';
      case 2:
        return 'arrival';
      case 3:
        return 'removal';
      case 4:
        return 'dock';
      default:
        return 'type $type';
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
    unawaited(_eventWatcherStdoutSub?.cancel());
    unawaited(_eventWatcherStderrSub?.cancel());
    _eventWatcherStdoutSub = null;
    _eventWatcherStderrSub = null;
    _eventDebounceTimer?.cancel();
    _eventDebounceTimer = null;
    if (!_controller.isClosed) {
      _controller.close();
    }
    _logService.logInfo('DeviceService disposed.');
  }
}
