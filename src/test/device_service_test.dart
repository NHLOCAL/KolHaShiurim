import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:kol_hashiurim/models/device_info.dart';
import 'package:kol_hashiurim/services/device_service.dart';

import 'helpers/test_log_service.dart';

void main() {
  test(
    'VolumeID lookup prefers the application directory, then PATH',
    () async {
      final root = await Directory.systemTemp.createTemp('volumeid_lookup_');
      try {
        final appDirectory = await Directory(p.join(root.path, 'app')).create();
        final pathDirectory = await Directory(
          p.join(root.path, 'path'),
        ).create();
        final appExecutable = p.join(appDirectory.path, 'KolHaShiurim.exe');
        final pathTool = File(p.join(pathDirectory.path, 'Volumeid.exe'));
        await pathTool.writeAsBytes([1]);

        expect(
          await findVolumeIdExecutable(
            applicationExecutable: appExecutable,
            pathEnvironment: pathDirectory.path,
          ),
          pathTool.path,
        );

        final appTool = File(p.join(appDirectory.path, 'Volumeid.exe'));
        await appTool.writeAsBytes([1]);
        expect(
          await findVolumeIdExecutable(
            applicationExecutable: appExecutable,
            pathEnvironment: pathDirectory.path,
          ),
          appTool.path,
        );

        await appTool.writeAsBytes([]);
        await pathTool.delete();
        expect(
          await findVolumeIdExecutable(
            applicationExecutable: appExecutable,
            pathEnvironment: pathDirectory.path,
          ),
          isNull,
        );
      } finally {
        await root.delete(recursive: true);
      }
    },
  );

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
