import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kol_hashiurim/services/process_runner.dart';
import 'package:path/path.dart' as p;

String _dartExecutable() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    return p.join(
      flutterRoot,
      'bin',
      'cache',
      'dart-sdk',
      'bin',
      Platform.isWindows ? 'dart.exe' : 'dart',
    );
  }

  final executable = Platform.resolvedExecutable;
  if (p.basenameWithoutExtension(executable) == 'flutter_tester') {
    final cacheDirectory = p.dirname(
      p.dirname(p.dirname(p.dirname(executable))),
    );
    return p.join(
      cacheDirectory,
      'dart-sdk',
      'bin',
      Platform.isWindows ? 'dart.exe' : 'dart',
    );
  }
  return executable;
}

void main() {
  late Directory tempDir;
  late File script;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('process-runner-');
    script = File(p.join(tempDir.path, 'child.dart'));
    await script.writeAsString(r'''
import 'dart:async';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.first == 'success') {
    stdout.write('output');
    stderr.write('diagnostic');
    exitCode = 7;
    return;
  }

  await File(args[1]).writeAsString('$pid');
  await Future<void>.delayed(const Duration(seconds: 30));
  await File(args[2]).writeAsString('late write');
}
''');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('returns exit status and both output streams', () async {
    final result = await runProcess(_dartExecutable(), [
      script.path,
      'success',
    ]);

    expect(result.exitCode, 7);
    expect(result.stdout, 'output');
    expect(result.stderr, 'diagnostic');
  });

  test('kills and reaps child before timeout completes', () async {
    final started = File(p.join(tempDir.path, 'started'));
    final lateWrite = File(p.join(tempDir.path, 'late-write'));

    await expectLater(
      runProcess(_dartExecutable(), [
        script.path,
        'timeout',
        started.path,
        lateWrite.path,
      ], timeout: const Duration(seconds: 5)),
      throwsA(isA<TimeoutException>()),
    );
    expect(await started.exists(), isTrue);

    final childPid = int.parse(await started.readAsString());
    expect(Process.killPid(childPid), isFalse);
    expect(await lateWrite.exists(), isFalse);
  });
}
