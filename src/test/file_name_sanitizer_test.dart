import 'package:flutter_test/flutter_test.dart';
import 'package:kol_hashiurim/utils/file_name_sanitizer.dart';

void main() {
  test('sanitizeFileName trims and removes trailing dots/spaces', () {
    final result = sanitizeFileName('  lesson name.  ');
    expect(result, 'lesson name');
  });

  test('sanitizeFileName strips control characters', () {
    final result = sanitizeFileName('bad\u0000name.mp3');
    expect(result, 'badname.mp3');
  });

  test('sanitizeFileName returns fallback for empty', () {
    final result = sanitizeFileName('   ', fallback: 'fallback');
    expect(result, 'fallback');
  });
}
