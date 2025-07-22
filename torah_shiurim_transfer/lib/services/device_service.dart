import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:torah_shiurim_transfer/models/device_info.dart';
import 'package:torah_shiurim_transfer/services/log_service.dart';


typedef NativeWndProc = IntPtr Function(
    IntPtr hwnd, Uint32 uMsg, IntPtr wParam, IntPtr lParam);


typedef DartWndProc = int Function(
    int hwnd, int uMsg, int wParam, int lParam);

class DeviceService {
  final _controller = StreamController<List<ConnectedDeviceInfo>>.broadcast();
  final LogService _logService;

  static int _hwnd = 0;

  static Pointer<NativeFunction<NativeWndProc>> _originalWndProcPtr = nullptr;
  static void Function()? _refreshDevicesCallback;

  DeviceService(this._logService, int hwnd) {
    _logService.logInfo('DeviceService initialized for event-driven detection.');
    _hwnd = hwnd;
    _refreshDevicesCallback = _refreshDevices;
    _initializeWin32Listener();
    _refreshDevices();
  }

  Future<void> _initializeWin32Listener() async {
    try {
      if (_hwnd == 0) {
        _logService.logError(
          'Invalid window handle provided (0). Device change notifications will be disabled.',
          null,
          null,
        );
        return;
      }

      _logService.logInfo('Using window handle ($_hwnd). Subclassing for device change notifications.');


      final newWndProcPtr = Pointer.fromFunction<NativeWndProc>(
        _wndProc,
        0,
      );


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
            .cast<NativeFunction<NativeWndProc>>();
        _logService.logInfo('Successfully subclassed window procedure.');
      }
    } catch (e, st) {
      _logService.logError('Error during Win32 listener initialization.', e, st);
    }
  }


  static int _wndProc(int hwnd, int uMsg, int wParam, int lParam) {
    if (_originalWndProcPtr == nullptr) {
      return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }

    if (uMsg == WM_DEVICECHANGE) {
      const dbtDeviceArrival = 0x8000;
      const dbtDeviceRemoveComplete = 0x8004;

      if (wParam == dbtDeviceArrival || wParam == dbtDeviceRemoveComplete) {
        Future(() => _refreshDevicesCallback?.call());
      }
    }

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