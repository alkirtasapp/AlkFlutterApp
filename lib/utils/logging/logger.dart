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

  static void error(String message, [dynamic error]) {
    _logger.e(message, error: error, stackTrace: StackTrace.current);
  }
}
