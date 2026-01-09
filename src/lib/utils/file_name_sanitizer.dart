import 'dart:io';
import 'package:path/path.dart' as p;

String sanitizeFileName(String name, {String fallback = 'untitled'}) {
  final baseName = p.basename(name).trim();
  if (baseName.isEmpty) {
    return fallback;
  }

  final invalidChars = Platform.isWindows
      ? RegExp(r'[\\/:*?"<>|]')
      : RegExp(r'[\\/]');
  var sanitized = baseName.replaceAll(invalidChars, '');
  sanitized = sanitized.replaceAll(RegExp(r'[\u0000-\u001F]'), '');
  sanitized = sanitized.trim();
  sanitized = sanitized.replaceAll(RegExp(r'[\. ]+$'), '');

  return sanitized.isEmpty ? fallback : sanitized;
}
