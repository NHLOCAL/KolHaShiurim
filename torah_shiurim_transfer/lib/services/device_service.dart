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

  static int _hwnd = 0;
  static int _originalWndProc = 0;
  static void Function()? _refreshDevicesCallback;

  DeviceService(this._logService) {
    _logService.logInfo('DeviceService initialized for event-driven detection.');
    _refreshDevicesCallback = _refreshDevices;
    _initializeWin32Listener(); // Set up the system event listener
    _refreshDevices(); // Perform an initial scan on startup
  }

  Future<void> _initializeWin32Listener() async {
    try {
      // The window is created by window_manager. We need to wait for it to be findable.
      // We'll try for a few seconds before giving up.
      for (var i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        final ptrTitle = 'העברת שיעורי תורה'.toNativeUtf16();
        _hwnd = FindWindow(nullptr, ptrTitle);
        calloc.free(ptrTitle);
        if (_hwnd != 0) break;
      }

      if (_hwnd == 0) {
        _logService.logError(
            'Could not find application window handle. Device change notifications will be disabled.',
            null,
            null);
        return;
      }

      _logService.logInfo(
          'Found window handle ($_hwnd). Subclassing for device change notifications.');

      final newWndProc = Pointer.fromFunction<WNDPROC>(_wndProc, 0);

      _originalWndProc =
          SetWindowLongPtr(_hwnd, GWLP_WNDPROC, newWndProc.address);
      if (_originalWndProc == 0) {
        final error = GetLastError();
        _logService.logError(
            'Failed to subclass window procedure. Error code: $error.',
            null,
            null);
      } else {
        _logService.logInfo('Successfully subclassed window procedure.');
      }
    } catch (e, st) {
      _logService.logError(
          'Error during Win32 listener initialization.', e, st);
    }
  }

  static int _wndProc(int hwnd, int uMsg, int wParam, int lParam) {
    if (uMsg == WM_DEVICECHANGE) {
      const dbtDeviceArrival = 0x8000;
      const dbtDeviceRemoveComplete = 0x8004;

      if (wParam == dbtDeviceArrival || wParam == dbtDeviceRemoveComplete) {
        // A device was added or removed. Schedule a refresh to avoid blocking the message loop.
        Future(() => _refreshDevicesCallback?.call());
      }
    }
    // Always call the original window procedure for other messages
    return CallWindowProc(_originalWndProc, hwnd, uMsg, wParam, lParam);
  }

  Stream<List<ConnectedDeviceInfo>> watchConnectedDevices() =>
      _controller.stream.distinct((a, b) => _areEqual(a, b));

  Future<void> _refreshDevices() async {
    _logService.logInfo('Refreshing connected volumes via Win32 API.');
    try {
      final devices = <ConnectedDeviceInfo>[];
      final mask = GetLogicalDrives();

      for (var i = 0; i < 26; i++) {
        if ((mask & (1 << i)) == 0) continue;
        final letter = String.fromCharCode(65 + i);
        final root = '$letter:\\';

        final rootPtr = root.toNativeUtf16();
        if (GetDriveType(rootPtr) != DRIVE_REMOVABLE) {
          calloc.free(rootPtr);
          continue;
        }

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
          final serialHex =
              pSerialNumber.value.toRadixString(16).toUpperCase().padLeft(8, '0');
          final formatted =
              '${serialHex.substring(0, 4)}-${serialHex.substring(4)}';
          devices.add(ConnectedDeviceInfo(
            mountPath: root,
            serialNumber: formatted,
          ));
        }

        calloc.free(rootPtr);
        calloc.free(volNameBufNative);
        calloc.free(fsNameBufNative);
        calloc.free(pSerialNumber);
        calloc.free(pMaxComponentLen);
        calloc.free(pFileSystemFlags);
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

    final formatted = '${s.substring(0, 4)}-${s.substring(4)}';
    final result = await Process.run(
      'volumeid.exe',
      [mount, formatted],
      runInShell: true,
    );

    if (result.exitCode != 0) {
      _logService.logError('volumeid.exe failed: ${result.stderr}');
      throw Exception('Ensure volumeid.exe is in PATH and run as admin.');
    }

    await _refreshDevices();
    _logService.logUserActivity('Serial for $mount changed to $formatted.');
    return 'Serial changed to $formatted. Replug device to apply.';
  }

  void dispose() {
    if (_originalWndProc != 0 && _hwnd != 0) {
      SetWindowLongPtr(_hwnd, GWLP_WNDPROC, _originalWndProc);
      _logService.logInfo('Restored original window procedure.');
    }
    if (!_controller.isClosed) _controller.close();
    _logService.logInfo('DeviceService disposed.');
  }
}