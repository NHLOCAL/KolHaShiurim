import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:torah_shiurim_transfer/services/log_service.dart'; // NEW

class FileService {
  final LogService _logService; // NEW: Declare LogService

  FileService(this._logService); // NEW: Constructor takes LogService

  Future<List<File>> getAudioFiles(String directoryPath) async {
    _logService
        .logInfo('Attempting to get audio files from: $directoryPath'); // NEW
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      _logService.logWarning('Directory does not exist: $directoryPath'); // NEW
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

    try {
      // NEW: Add try-catch for directory listing
      await for (final entity in dir.list()) {
        if (entity is File) {
          final extension = p.extension(entity.path).toLowerCase();
          if (supportedExtensions.contains(extension)) {
            audioFiles.add(entity);
          }
        }
      }
      _logService.logInfo(
          'Found ${audioFiles.length} audio files in $directoryPath.'); // NEW
    } catch (e, st) {
      // NEW: Catch and log error
      _logService.logError(
          'Error listing directory $directoryPath for audio files',
          e,
          st); // NEW
    }
    return audioFiles;
  }

  Future<void> copyFile({
    required File sourceFile,
    required String destinationDirectory,
    required String newFileName,
  }) async {
    _logService.logInfo(
        'Attempting to copy file from ${sourceFile.path} to $destinationDirectory/$newFileName'); // NEW
    final destDir = Directory(destinationDirectory);
    if (!await destDir.exists()) {
      _logService.logInfo(
          'Creating destination directory: $destinationDirectory'); // NEW
      try {
        // NEW: Add try-catch for directory creation
        await destDir.create(recursive: true);
      } catch (e, st) {
        // NEW: Catch and log error
        _logService.logError(
            'Failed to create destination directory: $destinationDirectory',
            e,
            st); // NEW
        throw Exception('Failed to create destination directory: $e'); // NEW
      } // NEW
    }

    final destinationPath = p.join(destinationDirectory, newFileName);
    try {
      // NEW: Add try-catch for file copy
      await sourceFile.copy(destinationPath);
      _logService
          .logInfo('File copied successfully to $destinationPath.'); // NEW
    } catch (e, st) {
      // NEW: Catch and log error
      _logService.logError(
          'Failed to copy file from ${sourceFile.path} to $destinationPath',
          e,
          st); // NEW
      throw Exception('Failed to copy file: $e'); // NEW
    } // NEW
  }

  Future<void> convertAndCopyFile({
    required File sourceFile,
    required String destinationDirectory,
    required String newFileName,
    required int bitrate,
  }) async {
    _logService.logInfo(
        'Attempting to convert and copy file from ${sourceFile.path} to $destinationDirectory/$newFileName with bitrate ${bitrate}k'); // NEW
    final destDir = Directory(destinationDirectory);
    if (!await destDir.exists()) {
      _logService.logInfo(
          'Creating destination directory for conversion: $destinationDirectory'); // NEW
      try {
        // NEW: Add try-catch for directory creation
        await destDir.create(recursive: true);
      } catch (e, st) {
        // NEW: Catch and log error
        _logService.logError(
            'Failed to create destination directory for conversion: $destinationDirectory',
            e,
            st); // NEW
        throw Exception('Failed to create destination directory: $e'); // NEW
      } // NEW
    }
    final destinationPath = p.join(destinationDirectory, newFileName);

    final args = [
      '-i',
      sourceFile.path,
      '-y', // Overwrite output files without asking
      '-b:a', // Audio bitrate
      '${bitrate}k',
      destinationPath,
    ];

    try {
      // NEW: Add try-catch for process execution
      _logService.logInfo('Executing FFmpeg with arguments: $args'); // NEW
      final result = await Process.run('ffmpeg', args);

      if (result.exitCode != 0) {
        _logService.logError(
            'FFmpeg conversion failed (exit code ${result.exitCode}). StdOut: ${result.stdout}, StdErr: ${result.stderr}',
            null,
            StackTrace.current); // NEW
        throw Exception('FFmpeg conversion failed: ${result.stderr}');
      }
      _logService
          .logInfo('FFmpeg conversion successful to $destinationPath.'); // NEW
    } on ProcessException catch (e, st) {
      // NEW: Catch and log specific ProcessException
      _logService.logError(
          'ProcessException during FFmpeg execution', e, st); // NEW
      throw Exception(
          'Failed to execute ffmpeg. Is it installed and in your PATH? Error: $e'); // NEW
    } catch (e, st) {
      // NEW: Catch and log other errors
      _logService.logError(
          'Unknown error during FFmpeg conversion', e, st); // NEW
      rethrow;
    } // NEW
  }
}
