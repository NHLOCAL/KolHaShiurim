import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

// רמות לוג שונות
enum LogLevel { info, userActivity, warning, error }

class LogService {
  late File _logFile;
  static const String _logFileName = 'app_log.txt'; // שם קובץ הלוג
  static const String _logDirectoryName =
      'logs'; // תיקיית הלוג בתוך תיקיית התמיכה של האפליקציה

  // Debug-only console logging (avoids printing in release builds).
  void _debugLog(String message) {
    assert(() {
      debugPrint(message);
      return true;
    }());
  }

  // אתחול שירות הלוג
  Future<void> init() async {
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      final logDir = Directory(p.join(appSupportDir.path, _logDirectoryName));

      // וודא שהתיקייה קיימת, אם לא - צור אותה (כולל תיקיות אב)
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      _logFile = File(p.join(logDir.path, _logFileName));
      // הדפסת נתיב הלוג לקונסול לפיתוח ודיבוג
      _debugLog('Log file path: ${_logFile.path}');
    } catch (e, st) {
      // אם האתחול נכשל, הדפס שגיאה לקונסול
      _debugLog('Failed to initialize LogService: $e\n$st');
    }
  }

  // פונקציה פנימית לכתיבת הודעה לקובץ הלוג
  Future<void> _writeLog(LogLevel level, String message) async {
    try {
      // וודא שקובץ הלוג קיים לפני כתיבה אליו
      if (!await _logFile.exists()) {
        await _logFile.create(recursive: true);
      }

      final timestamp = DateTime.now()
          .toIso8601String(); // חותמת זמן בתקן ISO 8601
      final levelTag = level.name.toUpperCase(); // שם רמת הלוג באותיות גדולות
      final logEntry = '[$timestamp][$levelTag] $message\n'; // פורמט שורת הלוג
      // כתיבת השורה לקובץ במצב הוספה (append), וודא שמירה מיידית (flush)
      await _logFile.writeAsString(
        logEntry,
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      // אם הכתיבה לקובץ נכשלת, הדפס שגיאה לקונסול
      _debugLog(
        'ERROR: Failed to write to log file: $e. Message: [$level.name] $message',
      );
    }
  }

  // פונקציות ציבוריות לכתיבת לוגים ברמות שונות
  Future<void> logInfo(String message) async {
    await _writeLog(LogLevel.info, message);
  }

  Future<void> logUserActivity(String message) async {
    await _writeLog(LogLevel.userActivity, message);
  }

  Future<void> logWarning(String message) async {
    await _writeLog(LogLevel.warning, message);
  }

  Future<void> logError(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) async {
    String fullMessage = message;
    if (error != null) {
      fullMessage += '\nError Details: $error';
    }
    if (stackTrace != null) {
      fullMessage += '\nStackTrace: $stackTrace';
    }
    await _writeLog(LogLevel.error, fullMessage);
  }
}

