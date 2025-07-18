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
      // Standard
      '.mp3', '.wav', '.m4a', '.flac', '.aac', '.ogg', '.wma',
      // Apple
      '.aiff', '.alac',
      // Other
      '.amr', '.opus', '.dsd', '.pcm',
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
}