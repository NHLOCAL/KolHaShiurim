import 'dart:io';

String sanitizeFileName(String name, {String fallback = 'untitled'}) {
  var sanitized = name.trim();
  if (sanitized.isEmpty) {
    return fallback;
  }

  final invalidChars = Platform.isWindows
      ? RegExp(r'[\\/:*?"<>|]')
      : RegExp(r'[\\/]');
  sanitized = sanitized.replaceAll(invalidChars, '');
  sanitized = sanitized.replaceAll(RegExp(r'[\u0000-\u001F]'), '');
  sanitized = sanitized.trim();
  sanitized = sanitized.replaceAll(RegExp(r'[\. ]+$'), '');

  return sanitized.isEmpty ? fallback : sanitized;
}
