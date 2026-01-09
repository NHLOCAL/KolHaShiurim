import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kol_hashiurim/services/file_service.dart';

import 'helpers/test_log_service.dart';

void main() {
  test('copyFile creates destination and sanitizes filename', () async {
    final tempDir = await Directory.systemTemp.createTemp('copy-test');
    addTearDown(() => tempDir.delete(recursive: true));

    final sourceFile = File('${tempDir.path}/source.txt');
    await sourceFile.writeAsString('content');

    final destinationDir = '${tempDir.path}/dest';
    final service = FileService(TestLogService());

    await service.copyFile(
      sourceFile: sourceFile,
      destinationDirectory: destinationDir,
      newFileName: 'copy name. ',
    );

    final copiedFile = File('$destinationDir/copy name');
    expect(await copiedFile.exists(), isTrue);
    expect(await copiedFile.readAsString(), 'content');
  });

  test('copyFile throws when source is missing', () async {
    final tempDir = await Directory.systemTemp.createTemp('copy-missing');
    addTearDown(() => tempDir.delete(recursive: true));

    final sourceFile = File('${tempDir.path}/missing.txt');
    final service = FileService(TestLogService());

    expect(
      () => service.copyFile(
        sourceFile: sourceFile,
        destinationDirectory: tempDir.path,
        newFileName: 'missing.txt',
      ),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('convertAndCopyFile throws when process fails', () async {
    final tempDir = await Directory.systemTemp.createTemp('convert-fail');
    addTearDown(() => tempDir.delete(recursive: true));

    final sourceFile = File('${tempDir.path}/source.wav');
    await sourceFile.writeAsString('audio');

    final service = FileService(
      TestLogService(),
      processRunner: (_, __) async => ProcessResult(0, 1, '', 'ffmpeg error'),
    );

    expect(
      () => service.convertAndCopyFile(
        sourceFile: sourceFile,
        destinationDirectory: tempDir.path,
        newFileName: 'output.mp3',
        bitrate: 128,
      ),
      throwsException,
    );
  });

  test('convertAndCopyFile throws when output missing', () async {
    final tempDir = await Directory.systemTemp.createTemp('convert-missing');
    addTearDown(() => tempDir.delete(recursive: true));

    final sourceFile = File('${tempDir.path}/source.wav');
    await sourceFile.writeAsString('audio');

    final service = FileService(
      TestLogService(),
      processRunner: (_, __) async => ProcessResult(0, 0, '', ''),
    );

    expect(
      () => service.convertAndCopyFile(
        sourceFile: sourceFile,
        destinationDirectory: tempDir.path,
        newFileName: 'output.mp3',
        bitrate: 128,
      ),
      throwsException,
    );
  });

  test('convertAndCopyFile succeeds when output created', () async {
    final tempDir = await Directory.systemTemp.createTemp('convert-ok');
    addTearDown(() => tempDir.delete(recursive: true));

    final sourceFile = File('${tempDir.path}/source.wav');
    await sourceFile.writeAsString('audio');

    final service = FileService(
      TestLogService(),
      processRunner: (_, arguments) async {
        final outputPath = arguments.last;
        await File(outputPath).writeAsString('converted');
        return ProcessResult(0, 0, '', '');
      },
    );

    await service.convertAndCopyFile(
      sourceFile: sourceFile,
      destinationDirectory: tempDir.path,
      newFileName: 'output.mp3',
      bitrate: 128,
    );

    expect(await File('${tempDir.path}/output.mp3').exists(), isTrue);
  });
}
