import 'package:flutter_test/flutter_test.dart';
import 'package:kol_hashiurim/utils/file_name_sanitizer.dart';

void main() {
  test('sanitizeFileName trims and removes trailing dots/spaces', () {
    final result = sanitizeFileName('  lesson name.  ');
    expect(result, 'lesson name');
  });

  test('sanitizeFileName removes path separators', () {
    final result = sanitizeFileName('bad/name.mp3');
    expect(result, 'badname.mp3');
  });

  test('sanitizeFileName strips control characters', () {
    final result = sanitizeFileName('bad\u0000name.mp3');
    expect(result, 'badname.mp3');
  });

  test('sanitizeFileName returns fallback for empty', () {
    final result = sanitizeFileName('   ', fallback: 'fallback');
    expect(result, 'fallback');
  });

  test('sanitizeFileName returns fallback when sanitization empties input', () {
    final result = sanitizeFileName('////', fallback: 'fallback');
    expect(result, 'fallback');
  });

  test('sanitizeFileName preserves prefixes when separators are present', () {
    final result = sanitizeFileName('01 - Intro/Part 1.mp3');
    expect(result, '01 - IntroPart 1.mp3');
  });

  test('sanitizeFileName handles mixed issues', () {
    final result = sanitizeFileName('  01/Intro\u0000.  ');
    expect(result, '01Intro');
  });
}
