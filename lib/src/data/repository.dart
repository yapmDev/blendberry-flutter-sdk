import 'package:blendberry_flutter_sdk/src/data/config_data.dart';

/// Provides an abstract contract for accessing and storing remote configuration data locally.
///
/// Implementations of this interface are responsible for handling local
/// persistence of the configuration model, typically using solutions such as
/// `SharedPreferences`, secure storage, or local databases.
///
/// This abstraction allows you to swap the underlying storage mechanism
/// without affecting business logic.
///
/// The repository works with generic [ConfigData] and [ConfigMetadata] interfaces,
/// making it compatible with any backend format.
abstract interface class LocalConfigRepository {
  /// Checks if any configuration data is currently stored locally.
  bool hasData();

  /// Retrieves the stored configuration metadata.
  ///
  /// Returns `null` if no data is stored or if metadata is not available.
  /// This can be used to validate the current local config against a remote one.
  ConfigMetadata? getMetadata();

  /// Returns the stored configuration key-value pairs.
  ///
  /// These values represent the actual runtime configuration used by the app.
  Map<String, dynamic> getConfigs();

  /// Saves a complete configuration data to local storage.
  ///
  /// This includes both metadata and configuration values.
  /// The implementation should handle serialization of the [ConfigData] as needed.
  Future<void> saveConfig(ConfigData config);

  /// Clears all cached configuration data from local storage.
  ///
  /// This is useful for forcing a fresh fetch on the next load.
  Future<void> clearCache();
}