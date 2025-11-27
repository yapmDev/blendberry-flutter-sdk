/// Base exception for remote configuration operations.
///
/// All configuration-related exceptions should extend this class
/// to allow for centralized error handling.
class RemoteConfigException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Optional underlying cause of the exception.
  final Object? cause;

  /// Creates a [RemoteConfigException] with the given [message] and optional [cause].
  RemoteConfigException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'RemoteConfigException: $message\nCaused by: $cause';
    }
    return 'RemoteConfigException: $message';
  }
}

/// Exception thrown when a configuration is not found.
///
/// This can occur when:
/// - The requested environment doesn't exist
/// - The requested version doesn't exist
/// - The configuration was deleted from the backend
class ConfigNotFoundException extends RemoteConfigException {
  /// The environment that was requested.
  final String env;

  /// The version that was requested, if any.
  final String? version;

  /// Creates a [ConfigNotFoundException] for the given [env] and optional [version].
  ConfigNotFoundException(this.env, [this.version])
      : super(
          'Configuration not found for env: $env${version != null ? ", version: $version" : ""}',
        );
}

/// Exception thrown when a sync operation fails.
///
/// This can occur when:
/// - Network errors during sync check
/// - Backend returns invalid sync response
/// - Sync strategy encounters an error
class ConfigSyncException extends RemoteConfigException {
  /// Creates a [ConfigSyncException] with the given [message] and optional [cause].
  ConfigSyncException(String message, [Object? cause]) : super(message, cause);
}

/// Exception thrown when configuration data is invalid or malformed.
///
/// This can occur when:
/// - JSON parsing fails
/// - Required fields are missing
/// - Data format doesn't match expected structure
class ConfigDataException extends RemoteConfigException {
  /// Creates a [ConfigDataException] with the given [message] and optional [cause].
  ConfigDataException(String message, [Object? cause]) : super(message, cause);
}

