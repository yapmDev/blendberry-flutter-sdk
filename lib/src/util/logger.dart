/// Abstract interface for logging configuration operations.
///
/// Implement this interface to provide custom logging behavior.
/// The SDK will use this logger to report debug information, warnings, and errors.
///
/// Example usage:
/// ```dart
/// class MyLogger implements ConfigLogger {
///   @override
///   void debug(String message) => print('[DEBUG] $message');
///
///   @override
///   void info(String message) => print('[INFO] $message');
///
///   @override
///   void warning(String message) => print('[WARN] $message');
///
///   @override
///   void error(String message, [Object? error]) {
///     print('[ERROR] $message');
///     if (error != null) print(error);
///   }
/// }
/// ```
abstract interface class ConfigLogger {
  /// Logs a debug message.
  ///
  /// Used for detailed information that is typically only of interest
  /// when diagnosing problems.
  void debug(String message);

  /// Logs an informational message.
  ///
  /// Used for general informational messages about the configuration flow.
  void info(String message);

  /// Logs a warning message.
  ///
  /// Used for potentially harmful situations that don't prevent operation.
  void warning(String message);

  /// Logs an error message.
  ///
  /// Used for error events that might still allow the application to continue.
  ///
  /// [message] The error message.
  /// [error] Optional error object or exception.
  void error(String message, [Object? error]);
}

/// Logger implementation that does nothing (no-op).
///
/// This is the default logger used when no logger is provided.
/// Useful for production environments where logging is not needed.
class NoOpLogger implements ConfigLogger {
  const NoOpLogger();

  @override
  void debug(String message) {
    // No-op
  }

  @override
  void info(String message) {
    // No-op
  }

  @override
  void warning(String message) {
    // No-op
  }

  @override
  void error(String message, [Object? error]) {
    // No-op
  }
}

/// Logger implementation that prints to console.
///
/// Useful for development and debugging. Not recommended for production.
class ConsoleLogger implements ConfigLogger {
  const ConsoleLogger();

  @override
  void debug(String message) {
    print('[Config DEBUG] $message');
  }

  @override
  void info(String message) {
    print('[Config INFO] $message');
  }

  @override
  void warning(String message) {
    print('[Config WARN] $message');
  }

  @override
  void error(String message, [Object? error]) {
    print('[Config ERROR] $message');
    if (error != null) {
      print('[Config ERROR] Cause: $error');
    }
  }
}

