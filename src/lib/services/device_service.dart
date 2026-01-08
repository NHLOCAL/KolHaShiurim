import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:kol_hashiurim/models/device_info.dart';
import 'package:kol_hashiurim/services/log_service.dart';
import 'package:kol_hashiurim/services/device_scanner_isolate.dart';

typedef DeviceScanner = Future<List<ConnectedDeviceInfo>> Function();

class DeviceService {
  final _controller = StreamController<List<ConnectedDeviceInfo>>.broadcast();
  final LogService _logService;
  Timer? _pollingTimer;
  Future<List<ConnectedDeviceInfo>>? _scanFuture;
  final DeviceScanner _scanDevices;
  static const _pollingInterval = Duration(seconds: 4);

  DeviceService(this._logService, {DeviceScanner? scanDevices})
      : _scanDevices = scanDevices ?? _scanDevicesViaIsolate {
    _logService.logInfo('DeviceService initialized (Isolate Mode).');
  }

  Stream<List<ConnectedDeviceInfo>> watchConnectedDevices() =>
      _controller.stream.distinct((a, b) => _areEqual(a, b));

  Future<List<ConnectedDeviceInfo>> getConnectedDevices() async {
    _scanFuture ??= _performScan();
    return _scanFuture!;
  }

  void startPolling() {
    if (_pollingTimer?.isActive ?? false) {
      return;
    }
    _logService.logInfo('Starting device polling via Isolate.');
    _performScanAndEmit();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) => _performScanAndEmit());
  }

  void stopPolling() {
    if (_pollingTimer?.isActive ?? false) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
      _logService.logInfo('Device polling stopped.');
    }
  }

  Future<void> _performScanAndEmit() async {
    try {
      final devices = await getConnectedDevices();
      if (!_controller.isClosed) {
        _controller.add(devices);
      }
    } catch (e, st) {
      _logService.logError('Error in polling loop', e, st);
    }
  }

  Future<List<ConnectedDeviceInfo>> _performScan() async {
    try {
      return await _scanDevices();
    } catch (e, st) {
      _logService.logError('Fatal error in isolate scan', e, st);
      return [];
    } finally {
      _scanFuture = null;
    }
  }

  static Future<List<ConnectedDeviceInfo>> _scanDevicesViaIsolate() async {
    final isolateResults = await compute(scanDevicesSync, null);
    final devices = isolateResults
        .map(
          (d) => ConnectedDeviceInfo(
            mountPath: d.path,
            serialNumber: d.serial,
          ),
        )
        .toList();

    devices.sort((a, b) => a.mountPath.compareTo(b.mountPath));
    return devices;
  }

  bool _areEqual(List<ConnectedDeviceInfo> a, List<ConnectedDeviceInfo> b) {
    if (a.length != b.length) return false;
    final sa = a.map((d) => d.serialNumber).toSet();
    final sb = b.map((d) => d.serialNumber).toSet();
    return sa.containsAll(sb) && sb.containsAll(sa);
  }

  Future<String> changeVolumeSerialNumber(String mount, String serial) async {
    stopPolling(); 
    _logService.logUserActivity('Changing serial for $mount to $serial.');
    
    final s = serial.replaceAll('-', '');
    if (!RegExp(r'^[0-9A-Fa-f]{8}$').hasMatch(s)) {
      startPolling();
      throw const FormatException('Use 8 hex digits, e.g. 1234ABCD.');
    }
    final formatted = '${s.substring(0, 4)}-${s.substring(4)}';

    try {
      final tempDir = await getTemporaryDirectory();
      final volumeIdPath = p.join(tempDir.path, 'Volumeid.exe');
      final volumeIdFile = File(volumeIdPath);
      
      if (!await volumeIdFile.exists()) {
         final byteData = await rootBundle.load('assets/bin/Volumeid.exe');
         await volumeIdFile.writeAsBytes(
           byteData.buffer.asUint8List(
             byteData.offsetInBytes,
             byteData.lengthInBytes,
           ),
         );
      }

      final result = await Process.run(volumeIdPath, [
        mount.substring(0, mount.length - 1), 
        formatted,
      ], runInShell: true);

      if (result.exitCode != 0) {
        throw Exception('Failed: ${result.stderr}');
      }

      _logService.logUserActivity('Serial changed successfully.');
      return 'Serial changed to $formatted. Replug device.';
    } catch (e, st) {
      _logService.logError('Error running volumeid.exe', e, st);
      rethrow;
    } finally {
      startPolling(); 
    }
  }

  void dispose() {
    stopPolling();
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
