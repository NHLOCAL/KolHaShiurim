import 'dart:async';
import 'dart:io';

Future<ProcessResult> runProcess(
  String executable,
  List<String> arguments, {
  Duration? timeout,
}) async {
  final process = await Process.start(executable, arguments);
  final stdout = process.stdout.transform(systemEncoding.decoder).join();
  final stderr = process.stderr.transform(systemEncoding.decoder).join();
  await process.stdin.close();

  late final int exitCode;
  try {
    exitCode = timeout == null
        ? await process.exitCode
        : await process.exitCode.timeout(timeout);
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
    await process.exitCode;
    await Future.wait([stdout, stderr]);
    rethrow;
  }

  final output = await Future.wait([stdout, stderr]);
  return ProcessResult(process.pid, exitCode, output[0], output[1]);
}
