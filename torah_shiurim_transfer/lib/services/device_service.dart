import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:torah_shiurim_transfer/models/device_info.dart';
import 'package:torah_shiurim_transfer/services/log_service.dart';

class DeviceService {
  final StreamController<List<ConnectedDeviceInfo>> _controller =
      StreamController<List<ConnectedDeviceInfo>>.broadcast();
  final LogService _logService;
  Timer? _pollingTimer;

  DeviceService(this._logService) {
    _logService.logInfo('DeviceService initialized.');
    _startPollingDrives();
  }

  Stream<List<ConnectedDeviceInfo>> watchConnectedDevices() {
    return _controller.stream.distinct(
      (prev, next) => _areDeviceListsEqual(prev, next),
    );
  }

  void _startPollingDrives({Duration interval = const Duration(seconds: 5)}) {
    _refreshDevices(); // Initial load
    _pollingTimer = Timer.periodic(interval, (_) {
      _refreshDevices();
    });
  }

  Future<void> _refreshDevices() async {
    _logService.logInfo('Refreshing connected volumes via Win32 API.');
    try {
      final devices = <ConnectedDeviceInfo>[];
      final driveBitmask = GetLogicalDrives();

      for (var i = 0; i < 26; i++) {
        if ((driveBitmask & (1 << i)) == 0) continue;
        final letter = String.fromCharCode(65 + i);
        final mountPath = '$letter:\\';

        final driveType = GetDriveType(mountPath.toNativeUtf16());
        if (driveType != DRIVE_REMOVABLE) continue;

        final lpRootPathName = mountPath.toNativeUtf16();
        final pVolumeNameBuffer = calloc<Uint16>(MAX_PATH);
        final pSerialNumber    = calloc<Uint32>();
        final pMaxComponentLen = calloc<Uint32>();
        final pFileSystemFlags = calloc<Uint32>();
        final pFileSystemNameBuffer = calloc<Uint16>(MAX_PATH);

        final success = GetVolumeInformation(
          lpRootPathName,
          pVolumeNameBuffer,
          MAX_PATH,
          pSerialNumber,
          pMaxComponentLen,
          pFileSystemFlags,
          pFileSystemNameBuffer,
          MAX_PATH,
        );

        if (success != 0) {
          final serialHex = pSerialNumber.value
              .toRadixString(16)
              .toUpperCase()
              .padLeft(8, '0');
          final formattedSerial =
              '${serialHex.substring(0, 4)}-${serialHex.substring(4)}';
          devices.add(
            ConnectedDeviceInfo(
              mountPath: mountPath,
              serialNumber: formattedSerial,
            ),
          );
        }

        free(lpRootPathName);
        free(pVolumeNameBuffer);
        free(pSerialNumber);
        free(pMaxComponentLen);
        free(pFileSystemFlags);
        free(pFileSystemNameBuffer);
      }

      _controller.add(devices);
      _logService.logInfo('Detected ${devices.length} removable volumes.');
    } catch (e, st) {
      _logService.logError('Error enumerating drives', e, st);
    }
  }

  bool _areDeviceListsEqual(
    List<ConnectedDeviceInfo> a,
    List<ConnectedDeviceInfo> b,
  ) {
    if (a.length != b.length) return false;
    final aSet = a.map((d) => d.serialNumber).toSet();
    final bSet = b.map((d) => d.serialNumber).toSet();
    return aSet.containsAll(bSet) && bSet.containsAll(aSet);
  }

  Future<String> changeVolumeSerialNumber(
    String mountPath,
    String newSerial,
  ) async {
    _logService.logUserActivity(
      'Changing serial for $mountPath to $newSerial.',
    );

    final sanitized = newSerial.replaceAll('-', '');
    // RegExp must be closed and anchored for exactly 8 hex digits
    if (!RegExp(r'^[0-9A-Fa-f]{8}$').hasMatch(sanitized)) {
      _logService.logError('Invalid serial format: $newSerial');
      throw FormatException(
        'Invalid serial format. Use 8 hex digits, e.g., 1234ABCD.',
      );
    }

    final formatted = '${sanitized.substring(0, 4)}-${sanitized.substring(4)}';

    final result = await Process.run(
      'volumeid.exe',
      [mountPath, formatted],
      runInShell: true,
    );

    if (result.exitCode != 0) {
      _logService.logError('volumeid.exe failed: ${result.stderr}');
      throw Exception(
        'Failed to change serial. Ensure volumeid.exe is in PATH and run as admin.',
      );
    }

    await _refreshDevices(); // Update stream after change
    _logService.logUserActivity(
      'Serial for $mountPath changed to $formatted.',
    );
    return 'Serial changed to $formatted. Replug device to apply.';
  }

  void dispose() {
    _pollingTimer?.cancel();
    if (!_controller.isClosed) {
      _controller.close();
    }
    _logService.logInfo('DeviceService disposed.');
  }
}
