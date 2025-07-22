import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:torah_shiurim_transfer/models/device_info.dart';
import 'package:torah_shiurim_transfer/services/log_service.dart';

/// חתימה נייטיבית של פונקציית החלון
typedef NativeWndProc = IntPtr Function(
    IntPtr hwnd, Uint32 uMsg, IntPtr wParam, IntPtr lParam);

class DeviceService {
  final _controller = StreamController<List<ConnectedDeviceInfo>>.broadcast();
  final LogService _logService;

  static int _hwnd = 0;
  static Pointer<NativeFunction<NativeWndProc>> _originalWndProcPtr = nullptr;

  // יוצר NativeCallable התומך בהחזרת ערך
  static late final NativeCallable<NativeWndProc> _wndProcCallable;
  static void Function()? _refreshDevicesCallback;

  DeviceService(this._logService) {
    _logService.logInfo('DeviceService initialized for event-driven detection.');
    _refreshDevicesCallback = _refreshDevices;
    _initializeWin32Listener();
    _refreshDevices();
  }

  Future<void> _initializeWin32Listener() async {
    // מציאת ה‑HWND של החלון
    for (var i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final titlePtr = 'העברת שיעורי תורה'.toNativeUtf16();
      _hwnd = FindWindow(nullptr, titlePtr);
      calloc.free(titlePtr);
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
    _logService.logInfo('Found window handle ($_hwnd). Subclassing WndProc.');

    // יוצר NativeCallable.isolateLocal עבור פונקציית ה‑WNDPROC :contentReference[oaicite:0]{index=0}
    _wndProcCallable = NativeCallable<NativeWndProc>.isolateLocal(
      _wndProc,
      exceptionalReturn: 0,
    );

    final newProcAddr = _wndProcCallable.nativeFunction.address;  // :contentReference[oaicite:1]{index=1}
    final oldProcAddr = SetWindowLongPtr(_hwnd, GWLP_WNDPROC, newProcAddr);
    if (oldProcAddr == 0) {
      final err = GetLastError();
      _logService.logError('Failed to subclass WndProc (code $err).', null, null);
    } else {
      _originalWndProcPtr = Pointer.fromAddress(oldProcAddr)
          .cast<NativeFunction<NativeWndProc>>();
      _logService.logInfo('WndProc subclassed successfully.');
    }
  }

  /// הפונקציה שמטפלת בהודעות Windows
  static int _wndProc(int hwnd, int uMsg, int wParam, int lParam) {
    if (uMsg == WM_DEVICECHANGE) {
      const arrival = 0x8000, remove = 0x8004;
      if (wParam == arrival || wParam == remove) {
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
    _logService.logInfo('Refreshing removable drives...');
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
        final volBuf = calloc<Uint16>(MAX_PATH);
        final fsBuf  = calloc<Uint16>(MAX_PATH);
        final snPtr  = calloc<Uint32>();
        final mclPtr = calloc<Uint32>();
        final fsfPtr = calloc<Uint32>();

        final ok = GetVolumeInformation(
          rootPtr,
          volBuf.cast<Utf16>(),
          MAX_PATH,
          snPtr,
          mclPtr,
          fsfPtr,
          fsBuf.cast<Utf16>(),
          MAX_PATH,
        );
        if (ok != 0) {
          final hex = snPtr.value.toRadixString(16).toUpperCase().padLeft(8, '0');
          devices.add(ConnectedDeviceInfo(
            mountPath: root,
            serialNumber: '${hex.substring(0,4)}-${hex.substring(4)}',
          ));
        }
        calloc.free(rootPtr);
        calloc.free(volBuf);
        calloc.free(fsBuf);
        calloc.free(snPtr);
        calloc.free(mclPtr);
        calloc.free(fsfPtr);
      }
      _controller.add(devices);
      _logService.logInfo('Detected ${devices.length} devices.');
    } catch (e, st) {
      _logService.logError('Error during drive refresh', e, st);
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
    final res = await Process.run('volumeid.exe', [mount, formatted], runInShell: true);
    if (res.exitCode != 0) {
      _logService.logError('volumeid.exe failed: ${res.stderr}');
      throw Exception('Ensure volumeid.exe is in PATH and run as admin.');
    }
    await _refreshDevices();
    _logService.logUserActivity('Serial changed to $formatted.');
    return 'Serial changed to $formatted. Replug to apply.';
  }

  void dispose() {
    // שחזור החלון המקורי וסגירת ה־NativeCallable
    if (_originalWndProcPtr.address != 0 && _hwnd != 0) {
      SetWindowLongPtr(_hwnd, GWLP_WNDPROC, _originalWndProcPtr.address);
    }
    _wndProcCallable.close();  // חובה כדי לשחרר משאבים ולמנוע קריסה בלתי צפויה :contentReference[oaicite:2]{index=2}
    if (!_controller.isClosed) _controller.close();
    _logService.logInfo('DeviceService disposed.');
  }
}
