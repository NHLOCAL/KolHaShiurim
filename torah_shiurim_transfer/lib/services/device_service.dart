import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:torah_shiurim_transfer/models/device_info.dart';
import 'package:torah_shiurim_transfer/services/log_service.dart';

class DeviceService {
  final _controller = StreamController<List<ConnectedDeviceInfo>>.broadcast();
  final LogService _logService;
  Timer? _pollingTimer;

  DeviceService(this._logService) {
    _logService.logInfo('DeviceService initialized.');
    _startPollingDrives();
  }

  Stream<List<ConnectedDeviceInfo>> watchConnectedDevices() =>
      _controller.stream.distinct((a, b) => _areEqual(a, b));

  void _startPollingDrives({Duration interval = const Duration(seconds: 5)}) {
    _refreshDevices();
    _pollingTimer = Timer.periodic(interval, (_) => _refreshDevices());
  }

  Future<void> _refreshDevices() async {
    _logService.logInfo('Refreshing connected volumes via Win32 API.');
    try {
      final devices = <ConnectedDeviceInfo>[];
      final mask = GetLogicalDrives();

      for (var i = 0; i < 26; i++) {
        if ((mask & (1 << i)) == 0) continue;
        final letter = String.fromCharCode(65 + i);
        final root = '$letter:\\';

        if (GetDriveType(root.toNativeUtf16()) != DRIVE_REMOVABLE) continue;

        final lpRootPathName = root.toNativeUtf16();
        final pVolumeNameBuffer    = calloc<Utf16>(MAX_PATH);
        final pSerialNumber        = calloc<Uint32>();
        final pMaxComponentLen     = calloc<Uint32>();
        final pFileSystemFlags     = calloc<Uint32>();
        final pFileSystemNameBuffer= calloc<Utf16>(MAX_PATH);

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
          final formatted  = '${serialHex.substring(0,4)}-${serialHex.substring(4)}';
          devices.add(ConnectedDeviceInfo(mountPath: root, serialNumber: formatted));
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
      throw FormatException('Use 8 hex digits, e.g. 1234ABCD.');
    }

    final formatted = '${s.substring(0,4)}-${s.substring(4)}';
    final result = await Process.run('volumeid.exe', [mount, formatted], runInShell: true);

    if (result.exitCode != 0) {
      _logService.logError('volumeid.exe failed: ${result.stderr}');
      throw Exception('Ensure volumeid.exe is in PATH and run as admin.');
    }

    await _refreshDevices();
    _logService.logUserActivity('Serial for $mount changed to $formatted.');
    return 'Serial changed to $formatted. Replug device to apply.';
  }

  void dispose() {
    _pollingTimer?.cancel();
    if (!_controller.isClosed) _controller.close();
    _logService.logInfo('DeviceService disposed.');
  }
}
