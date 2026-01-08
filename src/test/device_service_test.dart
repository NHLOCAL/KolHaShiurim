import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kol_hashiurim/models/device_info.dart';
import 'package:kol_hashiurim/services/device_service.dart';

import 'helpers/test_log_service.dart';

void main() {
  test('getConnectedDevices avoids overlapping scans', () async {
    final completer = Completer<List<ConnectedDeviceInfo>>();
    var scanCount = 0;

    final service = DeviceService(
      TestLogService(),
      scanDevices: () async {
        scanCount++;
        return completer.future;
      },
    );

    final firstScan = service.getConnectedDevices();
    final secondScan = service.getConnectedDevices();

    completer.complete([
      ConnectedDeviceInfo(mountPath: '/mnt/usb', serialNumber: 'ABCD-1234'),
    ]);

    final results = await Future.wait([firstScan, secondScan]);
    expect(results[0], hasLength(1));
    expect(results[1], hasLength(1));
    expect(scanCount, 1);

    service.dispose();
  });
}
