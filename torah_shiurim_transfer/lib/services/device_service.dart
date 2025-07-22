import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:torah_shiurim_transfer/models/device_info.dart';
import 'package:torah_shiurim_transfer/services/log_service.dart';

/// Native signature of the window procedure callback.
typedef NativeWndProc = IntPtr Function(
    IntPtr hwnd, Uint32 uMsg, IntPtr wParam, IntPtr lParam);

/// Dart signature of the window procedure callback.
typedef DartWndProc = int Function(
    int hwnd, int uMsg, int wParam, int lParam);

class DeviceService {
  final _controller = StreamController<List<ConnectedDeviceInfo>>.broadcast();
  final LogService _logService;

  static int _hwnd = 0;
  // כעת מאחסנים בפוינטר ולא באינטייגר בלבד
  static Pointer<NativeFunction<NativeWndProc>> _originalWndProcPtr = nullptr;
  static void Function()? _refreshDevicesCallback;

  DeviceService(this._logService) {
    _logService.logInfo('DeviceService initialized for event-driven detection.');
    _refreshDevicesCallback = _refreshDevices;
    _initializeWin32Listener(); // Set up the system event listener
    _refreshDevices(); // Perform an initial scan on startup
  }

  Future<void> _initializeWin32Listener() async {
    try {
      // מחכים עד שהחלון יופיע
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
          null,
        );
        return;
      }

      _logService.logInfo('Found window handle ($_hwnd). Subclassing for device change notifications.');

      // יוצרים פוינטר חדש ל־WNDPROC עם טיפוס NativeWndProc (ולא NativeFunction<WNDPROC>)
      final newWndProcPtr = Pointer.fromFunction<NativeWndProc>(
        _wndProc,
        0,
      ); // :contentReference[oaicite:0]{index=0}

      // שומרים את הכתובת הקודמת כמספר, ואז ממירים חזרה לפוינטר
      final oldProcAddress = SetWindowLongPtr(
        _hwnd,
        GWLP_WNDPROC,
        newWndProcPtr.address,
      );
      if (oldProcAddress == 0) {
        final error = GetLastError();
        _logService.logError(
          'Failed to subclass window procedure. Error code: $error.',
          null,
          null,
        );
      } else {
        _originalWndProcPtr = Pointer.fromAddress(oldProcAddress)
            .cast<NativeFunction<NativeWndProc>>(); // :contentReference[oaicite:1]{index=1}
        _logService.logInfo('Successfully subclassed window procedure.');
      }
    } catch (e, st) {
      _logService.logError('Error during Win32 listener initialization.', e, st);
    }
  }

  /// הפונקציה שתטפל בהודעות
  static int _wndProc(int hwnd, int uMsg, int wParam, int lParam) {
    if (uMsg == WM_DEVICECHANGE) {
      const dbtDeviceArrival = 0x8000;
      const dbtDeviceRemoveComplete = 0x8004;

      if (wParam == dbtDeviceArrival || wParam == dbtDeviceRemoveComplete) {
        Future(() => _refreshDevicesCallback?.call());
      }
    }
    // מחזירים לקריאה המקורית
    return CallWindowProc(
      _originalWndProcPtr,
      hwnd,
      uMsg,
      wParam,
      lParam,
    );
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
        final fsNameBufNative = calloc<Uint16>(MAX_PATH);
        final pSerialNumber = calloc<Uint32>();
        final pMaxComponentLen = calloc<Uint32>();
        final pFileSystemFlags = calloc<Uint32>();

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
    if (_originalWndProcPtr.address != 0 && _hwnd != 0) {
      SetWindowLongPtr(_hwnd, GWLP_WNDPROC, _originalWndProcPtr.address);
      _logService.logInfo('Restored original window procedure.');
    }
    if (!_controller.isClosed) _controller.close();
    _logService.logInfo('DeviceService disposed.');
  }
}
