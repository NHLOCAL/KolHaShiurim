import 'package:kol_hashiurim/services/log_service.dart';

class TestLogService extends LogService {
  @override
  Future<void> logInfo(String message) async {}

  @override
  Future<void> logUserActivity(String message) async {}

  @override
  Future<void> logWarning(String message) async {}

  @override
  Future<void> logError(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) async {}
}
