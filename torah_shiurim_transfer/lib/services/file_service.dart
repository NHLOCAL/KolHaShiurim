import 'dart:io';
import 'package:path/path.dart' as p;

class FileService {
  Future<List<File>> getAudioFiles(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      return [];
    }

    final List<File> audioFiles = [];
    final supportedExtensions = [
      '.mp3',
      '.wav',
      '.m4a',
      '.flac',
      '.aac',
      '.ogg',
      '.wma',
      '.aiff',
      '.alac',
      '.amr',
      '.opus',
      '.dsd',
      '.pcm',
    ];

    await for (final entity in dir.list()) {
      if (entity is File) {
        final extension = p.extension(entity.path).toLowerCase();
        if (supportedExtensions.contains(extension)) {
          audioFiles.add(entity);
        }
      }
    }
    return audioFiles;
  }

  Future<void> copyFile({
    required File sourceFile,
    required String destinationDirectory,
    required String newFileName,
  }) async {
    final destDir = Directory(destinationDirectory);
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    final destinationPath = p.join(destinationDirectory, newFileName);
    await sourceFile.copy(destinationPath);
  }

  Future<void> convertAndCopyFile({
    required File sourceFile,
    required String destinationDirectory,
    required String newFileName,
    required int bitrate,
  }) async {
    final destDir = Directory(destinationDirectory);
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    final destinationPath = p.join(destinationDirectory, newFileName);

    final args = [
      '-i',
      sourceFile.path,
      '-y',
      '-b:a',
      '${bitrate}k',
      destinationPath,
    ];

    final result = await Process.run('ffmpeg', args);

    if (result.exitCode != 0) {
      throw Exception('FFmpeg conversion failed: ${result.stderr}');
    }
  }
}
