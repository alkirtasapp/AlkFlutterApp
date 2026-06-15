import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AlkLoggerHelper {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount:0,  
      errorMethodCount: 5,   // Show stack trace for errors
      noBoxingByDefault: true, // Remove borders

    ),
    // In release mode: only show warnings and errors
    // In debug mode: show all logs including debug
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  static void debug(String message) {
    _logger.d(message);
  }

  static void info(String message) {
    _logger.i(message);
  }

  static void warning(String message) {
    _logger.w(message);
  }

  static void error(String message, [dynamic errorOrStackTrace, StackTrace? stackTrace]) {
    // Tolerate the legacy pattern: AlkLoggerHelper.error('msg', stackTrace)
    // The logger package rejects a StackTrace passed as the `error` parameter,
    // which would crash the app — especially fatal inside catch-blocks.
    Object? error = errorOrStackTrace;
    StackTrace? st = stackTrace;
    if (error is StackTrace) {
      st ??= error;
      error = null;
    }
    try {
      _logger.e(message, error: error, stackTrace: st ?? StackTrace.current);
    } catch (e) {
      // Last-resort guard — never let the logger itself crash the app.
      debugPrint('AlkLoggerHelper.error fallback: $message | err=$error | $e');
    }
  }
}
