/// Generic interface for configuration data from any backend.
///
/// This interface abstracts away the specific format of configuration data,
/// allowing the SDK to work with any backend implementation. Users must
/// implement this interface to match their backend's response format.
///
/// Example usage:
/// ```dart
/// class MyBackendConfig implements ConfigData {
///   final Map<String, dynamic> data;
///   final String version;
///   final DateTime lastModified;
///
///   MyBackendConfig(this.data, this.version, this.lastModified);
///
///   @override
///   Map<String, dynamic> extractConfigs() => data;
///
///   @override
///   ConfigMetadata? extractMetadata() => MyConfigMetadata(version, lastModified);
/// }
/// ```
abstract interface class ConfigData {
  /// Extracts the actual configuration values as a map.
  ///
  /// This method should return the key-value pairs that represent
  /// the actual runtime configuration used by the application.
  Map<String, dynamic> extractConfigs();

  /// Extracts metadata for sync/version checking.
  ///
  /// Returns metadata that can be used to determine if a configuration
  /// update is needed. Returns `null` if metadata is not available or
  /// not needed for sync checking.
  ConfigMetadata? extractMetadata();
}

/// Generic metadata interface for sync strategies.
///
/// This interface provides a way to identify and compare configurations
/// without loading the full configuration data. The [syncIdentifier] can
/// be a version string, ETag, timestamp, hash, or any other identifier
/// that your backend uses for change detection.
///
/// Example usage:
/// ```dart
/// class MyConfigMetadata implements ConfigMetadata {
///   final String version;
///   final DateTime lastModified;
///
///   MyConfigMetadata(this.version, this.lastModified);
///
///   @override
///   String get syncIdentifier => '$version-${lastModified.millisecondsSinceEpoch}';
/// }
/// ```
abstract interface class ConfigMetadata {
  /// Any identifier that can be used for sync checking.
  ///
  /// This could be:
  /// - A version string (e.g., "1.0.0")
  /// - An ETag (e.g., "W/\"abc123\"")
  /// - A timestamp (e.g., "2024-01-01T00:00:00Z")
  /// - A hash (e.g., "sha256:abc123...")
  /// - A combination of the above
  ///
  /// The format is entirely up to your backend implementation.
  String get syncIdentifier;
}

