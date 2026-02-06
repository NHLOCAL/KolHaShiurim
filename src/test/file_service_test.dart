import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kol_hashiurim/services/file_service.dart';
import 'package:kol_hashiurim/services/log_service.dart';
import 'package:path/path.dart' as p;

class _TestLogService extends LogService {
  @override
  Future<void> logInfo(String message) async {}

  @override
  Future<void> logUserActivity(String message) async {}

  @override
  Future<void> logWarning(String message) async {}

  @override
  Future<void> logError(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) async {}
}

void main() {
  test('convertAndCopyFile throws when FFmpeg is unavailable', () async {
    final tempDir = await Directory.systemTemp.createTemp('ffmpeg-missing-');
    addTearDown(() async {
      await tempDir.delete(recursive: true);
    });

    final sourceFile = File(p.join(tempDir.path, 'source.wav'));
    await sourceFile.writeAsString('audio');

    final fileService = FileService(
      _TestLogService(),
      processRunner: (executable, arguments) async {
        return ProcessResult(0, 1, '', 'ffmpeg missing');
      },
    );

    expect(
      () => fileService.convertAndCopyFile(
        sourceFile: sourceFile,
        destinationDirectory: tempDir.path,
        newFileName: 'output.mp3',
        bitrate: 128,
      ),
      throwsException,
    );
  });

  test('convertAndCopyFile creates output when FFmpeg succeeds', () async {
    final tempDir = await Directory.systemTemp.createTemp('ffmpeg-success-');
    addTearDown(() async {
      await tempDir.delete(recursive: true);
    });

    final sourceFile = File(p.join(tempDir.path, 'source.wav'));
    await sourceFile.writeAsString('audio');

    final fileService = FileService(
      _TestLogService(),
      processRunner: (executable, arguments) async {
        if (arguments.length == 1 && arguments.first == '-version') {
          return ProcessResult(0, 0, 'ffmpeg version', '');
        }
        final destinationPath = arguments.last;
        await File(destinationPath).writeAsString('converted');
        return ProcessResult(0, 0, '', '');
      },
    );

    await fileService.convertAndCopyFile(
      sourceFile: sourceFile,
      destinationDirectory: tempDir.path,
      newFileName: 'output.mp3',
      bitrate: 128,
    );

    expect(
      File(p.join(tempDir.path, 'output.mp3')).existsSync(),
      isTrue,
    );
  });
}
