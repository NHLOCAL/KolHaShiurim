import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:kol_hashiurim/services/log_service.dart';
import 'package:kol_hashiurim/utils/file_name_sanitizer.dart';

typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

class FileService {
  final LogService _logService;
  final ProcessRunner _processRunner;
  bool? _ffmpegAvailable;

  FileService(
    this._logService, {
    ProcessRunner? processRunner,
  }) : _processRunner = processRunner ?? Process.run;

  String _getSafeFileName(String newFileName) {
    final extension = p.extension(newFileName);
    final fallbackName =
        extension.isNotEmpty ? 'untitled$extension' : 'untitled';
    return sanitizeFileName(
      newFileName,
      fallback: fallbackName,
    );
  }

  Future<void> _ensureFfmpegAvailable() async {
    if (_ffmpegAvailable == true) {
      return;
    }
    try {
      final result = await _processRunner('ffmpeg', ['-version']);
      if (result.exitCode == 0) {
        _ffmpegAvailable = true;
        await _logService.logInfo('FFmpeg availability check passed.');
        return;
      }
      _ffmpegAvailable = false;
      await _logService.logError(
        'FFmpeg availability check failed (exit code ${result.exitCode}). StdOut: ${result.stdout}, StdErr: ${result.stderr}',
        null,
        StackTrace.current,
      );
      throw Exception(
        'FFmpeg is not available. Please install FFmpeg and ensure it is in your PATH.',
      );
    } on ProcessException catch (e, st) {
      _ffmpegAvailable = false;
      await _logService.logError(
        'FFmpeg availability check failed with ProcessException',
        e,
        st,
      );
      throw Exception(
        'Failed to execute ffmpeg. Please install FFmpeg and ensure it is in your PATH. Error: $e',
      );
    }
  }

  Future<List<File>> getAudioFiles(String directoryPath) async {
    _logService.logInfo(
      'Attempting to get audio files from: $directoryPath',
    ); // NEW
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
        'Found ${audioFiles.length} audio files in $directoryPath.',
      ); // NEW
    } catch (e, st) {
      // NEW: Catch and log error
      _logService.logError(
        'Error listing directory $directoryPath for audio files',
        e,
        st,
      ); // NEW
    }
    return audioFiles;
  }

  Future<void> copyFile({
    required File sourceFile,
    required String destinationDirectory,
    required String newFileName,
  }) async {
    if (!await sourceFile.exists()) {
      _logService.logWarning(
        'Source file missing before copy: ${sourceFile.path}',
      );
      throw FileSystemException(
        'Source file does not exist',
        sourceFile.path,
      );
    }
    final safeFileName = _getSafeFileName(newFileName);
    if (safeFileName != newFileName) {
      _logService.logInfo(
        'Sanitized copy filename from "$newFileName" to "$safeFileName".',
      );
    }
    _logService.logInfo(
      'Attempting to copy file from ${sourceFile.path} to $destinationDirectory/$safeFileName',
    );
    final destDir = Directory(destinationDirectory);
    if (!await destDir.exists()) {
      _logService.logInfo(
        'Creating destination directory: $destinationDirectory',
      );
      try {
        await destDir.create(recursive: true);
      } catch (e, st) {
        _logService.logError(
          'Failed to create destination directory: $destinationDirectory',
          e,
          st,
        );
        throw Exception('Failed to create destination directory: $e');
      }
    }

    final destinationPath = p.join(destinationDirectory, safeFileName);
    try {
      await sourceFile.copy(destinationPath);
      if (!await File(destinationPath).exists()) {
        _logService.logError(
          'Copy reported success but destination file missing: $destinationPath',
          null,
          StackTrace.current,
        );
        throw Exception('Copy did not produce destination file.');
      }
      _logService.logInfo(
        'File copied successfully to $destinationPath.',
      );
    } catch (e, st) {
      _logService.logError(
        'Failed to copy file from ${sourceFile.path} to $destinationPath',
        e,
        st,
      );
      throw Exception('Failed to copy file: $e');
    }
  }

  Future<void> convertAndCopyFile({
    required File sourceFile,
    required String destinationDirectory,
    required String newFileName,
    required int bitrate,
  }) async {
    if (!await sourceFile.exists()) {
      _logService.logWarning(
        'Source file missing before conversion: ${sourceFile.path}',
      );
      throw FileSystemException(
        'Source file does not exist',
        sourceFile.path,
      );
    }
    final safeFileName = _getSafeFileName(newFileName);
    if (safeFileName != newFileName) {
      _logService.logInfo(
        'Sanitized conversion filename from "$newFileName" to "$safeFileName".',
      );
    }
    _logService.logInfo(
      'Attempting to convert and copy file from ${sourceFile.path} to $destinationDirectory/$safeFileName with bitrate ${bitrate}k',
    );
    await _ensureFfmpegAvailable();
    final destDir = Directory(destinationDirectory);
    if (!await destDir.exists()) {
      _logService.logInfo(
        'Creating destination directory for conversion: $destinationDirectory',
      );
      try {
        await destDir.create(recursive: true);
      } catch (e, st) {
        _logService.logError(
          'Failed to create destination directory for conversion: $destinationDirectory',
          e,
          st,
        );
        throw Exception('Failed to create destination directory: $e');
      }
    }
    final destinationPath = p.join(destinationDirectory, safeFileName);

    final args = [
      '-i',
      sourceFile.path,
      '-y', // Overwrite output files without asking
      '-b:a', // Audio bitrate
      '${bitrate}k',
      destinationPath,
    ];

    try {
      _logService.logInfo('Executing FFmpeg with arguments: $args');
      final result = await _processRunner('ffmpeg', args);

      if (result.exitCode != 0) {
        _logService.logError(
          'FFmpeg conversion failed (exit code ${result.exitCode}). StdOut: ${result.stdout}, StdErr: ${result.stderr}',
          null,
          StackTrace.current,
        );
        throw Exception('FFmpeg conversion failed: ${result.stderr}');
      }
      if (!await File(destinationPath).exists()) {
        _logService.logError(
          'FFmpeg reported success but output file is missing: $destinationPath',
          null,
          StackTrace.current,
        );
        throw Exception(
          'FFmpeg conversion did not produce an output file.',
        );
      }
      _logService.logInfo(
        'FFmpeg conversion successful to $destinationPath.',
      );
    } on ProcessException catch (e, st) {
      _logService.logError(
        'ProcessException during FFmpeg execution',
        e,
        st,
      );
      throw Exception(
        'Failed to execute ffmpeg. Is it installed and in your PATH? Error: $e',
      );
    } catch (e, st) {
      _logService.logError(
        'Unknown error during FFmpeg conversion',
        e,
        st,
      );
      rethrow;
    }
  }
}
