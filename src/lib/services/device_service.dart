import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:win32/win32.dart';
import 'package:kol_hashiurim/models/device_info.dart';
import 'package:kol_hashiurim/services/log_service.dart';

class DeviceService {
  final _controller = StreamController<List<ConnectedDeviceInfo>>.broadcast();
  final LogService _logService;
  Timer? _pollingTimer;
  Future<void>? _scanInProgress;
  static const _pollingInterval = Duration(seconds: 5);
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
    const suppressedErrors = SEM_FAILCRITICALERRORS | SEM_NOOPENFILEERRORBOX;
    final previousThreadErrorMode = calloc<Uint32>();
    int? previousProcessErrorMode;
    var threadErrorModeChanged = false;
    try {
      final setThreadResult = SetThreadErrorMode(
        suppressedErrors,
        previousThreadErrorMode,
      );
      if (setThreadResult != 0) {
        threadErrorModeChanged = true;
      } else {
        previousProcessErrorMode = SetErrorMode(suppressedErrors);
        if (previousProcessErrorMode == 0) {
          final error = GetLastError();
          if (error != NO_ERROR) {
            _logService.logWarning(
              'Failed to configure critical-error suppression. Win32 Error: $error',
            );
          }
        }
      }
      final devices = <ConnectedDeviceInfo>[];
      final mask = GetLogicalDrives();
      if (mask == 0) {
        final error = GetLastError();
        _logService.logError('GetLogicalDrives failed.', 'Win32 Error: $error');
        return devices;
      }
      for (var i = 0; i < 26; i++) {
        if ((mask & (1 << i)) == 0) continue;
        final letter = String.fromCharCode(65 + i);
        final root = '$letter:\\';
        // Allocate with calloc so we can safely free using calloc.free below.
        final rootPtr = root.toNativeUtf16(allocator: calloc);
        try {
          if (GetDriveType(rootPtr) != DRIVE_REMOVABLE) {
            continue;
          }
          final volNameBufNative = calloc<Uint16>(MAX_PATH);
          final fsNameBufNative = calloc<Uint16>(MAX_PATH);
          final pSerialNumber = calloc<Uint32>();
          final pMaxComponentLen = calloc<Uint32>();
          final pFileSystemFlags = calloc<Uint32>();
          try {
            final success = GetVolumeInformation(
              rootPtr,
              volNameBufNative.cast<Utf16>(),
              MAX_PATH,
              pSerialNumber,
              pMaxComponentLen,
              pFileSystemFlags,
              fsNameBufNative.cast<Utf16>(),
              MAX_PATH,
            );
            if (success != 0) {
              final serialHex = pSerialNumber.value
                  .toRadixString(16)
                  .toUpperCase()
                  .padLeft(8, '0');
              final formatted =
                  '${serialHex.substring(0, 4)}-${serialHex.substring(4)}';
              devices.add(
                ConnectedDeviceInfo(mountPath: root, serialNumber: formatted),
              );
            } else {
              final error = GetLastError();
              if (error == ERROR_NOT_READY) {
                _logService.logInfo(
                  'Drive $root is not ready (no media inserted). Skipping.',
                );
              } else if (error == ERROR_ACCESS_DENIED) {
                _logService.logWarning(
                  'Access denied while reading removable drive $root. The drive might be in use.',
                );
              } else {
                _logService.logInfo(
                  'Could not get volume information for removable drive $root. Win32 Error: $error',
                );
              }
            }
          } finally {
            calloc.free(volNameBufNative);
            calloc.free(fsNameBufNative);
            calloc.free(pSerialNumber);
            calloc.free(pMaxComponentLen);
            calloc.free(pFileSystemFlags);
          }
        } catch (e, st) {
          _logService.logError(
            "Error processing drive $root. This might be a bug or an unexpected system state.",
            e,
            st,
          );
        } finally {
          calloc.free(rootPtr);
        }
      }
      devices.sort((a, b) => a.mountPath.compareTo(b.mountPath));
      return devices;
    } catch (e, st) {
      _logService.logError('Error enumerating drives', e, st);
      return [];
    } finally {
      if (threadErrorModeChanged) {
        SetThreadErrorMode(previousThreadErrorMode.value, nullptr);
      } else if (previousProcessErrorMode != null) {
        SetErrorMode(previousProcessErrorMode);
      }
      calloc.free(previousThreadErrorMode);
      completer.complete();
      _scanInProgress = null;
    }
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
        _logService.logError('volumeid.exe failed: ${result.stderr}');
        throw Exception(
          'Failed to execute volumeid.exe. Error: ${result.stderr}',
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
