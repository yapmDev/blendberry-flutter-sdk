import 'package:blendberry_flutter_sdk/src/data/config_data.dart';
import 'package:blendberry_flutter_sdk/src/domain/sync_strategy.dart';

/// Completely abstract service for fetching remote configurations.
///
/// This interface defines the contract for communicating with any remote
/// configuration backend. Implementations must provide their own logic for:
/// - How to construct requests (REST, GraphQL, gRPC, etc.)
/// - How to parse responses
/// - How to handle errors
/// - How to check for updates
///
/// The SDK does not provide any concrete implementation - you must implement
/// this interface to match your backend's API.
///
/// Example usage:
/// ```dart
/// class MyBackendService implements RemoteConfigService {
///   @override
///   Future<ConfigData?> fetchConfig(String env, [String? version]) async {
///     // Your implementation here
///   }
///
///   @override
///   Future<SyncResult> checkForUpdates(
///     ConfigMetadata local,
///     String env, [
///     String? version,
///   ]) async {
///     // Your sync logic here
///   }
/// }
/// ```
abstract interface class RemoteConfigService {
  /// Fetches configuration data from remote backend.
  ///
  /// [env] The environment identifier (e.g., "dev", "staging", "prod").
  /// [version] Optional version identifier. If `null`, should fetch the latest version.
  ///
  /// Returns [ConfigData] if found, or `null` if not found or on error.
  /// Implementations should handle errors gracefully and return `null` rather than throwing.
  Future<ConfigData?> fetchConfig(String env, [String? version]);

  /// Checks if the local configuration needs to be updated.
  ///
  /// This method should perform a lightweight check (without fetching the full config)
  /// to determine if an update is available. The implementation depends on your
  /// backend's sync mechanism (ETag, version, timestamp, hash, etc.).
  ///
  /// [local] The metadata of the locally stored configuration.
  /// [env] The environment identifier.
  /// [version] Optional version identifier.
  ///
  /// Returns a [SyncResult] indicating whether an update is needed.
  Future<SyncResult> checkForUpdates(
    ConfigMetadata local,
    String env, [
    String? version,
  ]);
}