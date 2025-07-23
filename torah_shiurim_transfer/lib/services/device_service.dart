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
    try {
      final devices = <ConnectedDeviceInfo>[];
      final mask = GetLogicalDrives();

      for (var i = 0; i < 26; i++) {
        if ((mask & (1 << i)) == 0) continue;
        final letter = String.fromCharCode(65 + i);
        final root = '$letter:\\';

        // toNativeUtf16() כבר מחזיר Pointer<Utf16>
        final rootPtr = root.toNativeUtf16();
        if (GetDriveType(rootPtr) != DRIVE_REMOVABLE) {
          calloc.free(rootPtr);
          continue;
        }

        // הקצאה כ־Uint16 ואז המרה ל־Utf16
        final volNameBufNative = calloc<Uint16>(MAX_PATH);
        final volNameBuf = volNameBufNative.cast<Utf16>();
        final fsNameBufNative = calloc<Uint16>(MAX_PATH);
        final fsNameBuf = fsNameBufNative.cast<Utf16>();

        final pSerialNumber = calloc<Uint32>();
        final pMaxComponentLen = calloc<Uint32>();
        final pFileSystemFlags = calloc<Uint32>();

        final success = GetVolumeInformation(
          rootPtr,
          volNameBuf,
          MAX_PATH,
          pSerialNumber,
          pMaxComponentLen,
          pFileSystemFlags,
          fsNameBuf,
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
        }

        // שיחרור כל הזיכרון שהוקצה
        calloc.free(rootPtr);
        calloc.free(volNameBufNative);
        calloc.free(fsNameBufNative);
        calloc.free(pSerialNumber);
        calloc.free(pMaxComponentLen);
        calloc.free(pFileSystemFlags);
      }

      _controller.add(devices);
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
      throw const FormatException('Use 8 hex digits, e.g. 1234ABCD.');
    }

    final formatted = '${s.substring(0, 4)}-${s.substring(4)}';
    final result = await Process.run('volumeid.exe', [
      mount,
      formatted,
    ], runInShell: true);

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
