import 'package:blendberry_flutter_sdk/src/data/config_data.dart';
import 'package:blendberry_flutter_sdk/src/domain/service.dart';

/// Result of a sync check operation.
///
/// This enum represents the possible outcomes when checking if a local
/// configuration needs to be updated from the remote backend.
enum SyncResult {
  /// Local configuration is up-to-date with the remote.
  upToDate,

  /// Remote has a newer version that should be fetched.
  needsUpdate,

  /// No matching configuration exists on the remote server.
  notFound,

  /// An error occurred during the sync check.
  error,
}

/// Optional strategy pattern for different sync mechanisms.
///
/// Different backends may use different mechanisms to check for updates:
/// - Version-based (semantic versioning)
/// - ETag-based (HTTP ETags)
/// - Timestamp-based (last modification date)
/// - Hash-based (content hash)
/// - Custom logic
///
/// Implement this interface to provide your own sync checking logic.
///
/// Example usage:
/// ```dart
/// class ETagSyncStrategy implements SyncStrategy {
///   @override
///   Future<SyncResult> checkForUpdates(
///     ConfigMetadata local,
///     RemoteConfigService service,
///     String env, [
///     String? version,
///   ]) async {
///     // Custom ETag checking logic
///   }
/// }
/// ```
abstract interface class SyncStrategy {
  /// Checks if the local configuration needs to be updated.
  ///
  /// [local] The metadata of the locally stored configuration.
  /// [service] The remote service to check against.
  /// [env] The environment identifier.
  /// [version] Optional version identifier.
  ///
  /// Returns a [SyncResult] indicating whether an update is needed.
  Future<SyncResult> checkForUpdates(
    ConfigMetadata local,
    RemoteConfigService service,
    String env, [
    String? version,
  ]);
}

