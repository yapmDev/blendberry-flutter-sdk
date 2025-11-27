import 'package:blendberry_flutter_sdk/src/data/repository.dart';
import 'package:blendberry_flutter_sdk/src/domain/service.dart';
import 'package:blendberry_flutter_sdk/src/domain/sync_strategy.dart';
import 'package:blendberry_flutter_sdk/src/presentation/mediator.dart';
import 'package:blendberry_flutter_sdk/src/util/logger.dart';

/// Builder for creating and configuring [RemoteConfigMediator] instances.
///
/// This builder provides a fluent API for configuring all aspects of the mediator,
/// making it easier to set up complex configurations.
///
/// Example usage:
/// ```dart
/// final mediator = RemoteConfigBuilder()
///   .withService(MyBackendService())
///   .withRepository(MyLocalRepository())
///   .withSyncStrategy(MyCustomSyncStrategy())
///   .withLoadMode(LoadMode.hybrid)
///   .enableLogging(true)
///   .build();
/// ```
class RemoteConfigBuilder {
  RemoteConfigService? _service;
  LocalConfigRepository? _repository;
  SyncStrategy? _syncStrategy;
  LoadMode _loadMode = LoadMode.hybrid;
  ConfigLogger? _logger;
  bool _enableLogging = false;

  /// Sets the remote service for fetching configurations.
  ///
  /// This is required and must be called before [build].
  RemoteConfigBuilder withService(RemoteConfigService service) {
    _service = service;
    return this;
  }

  /// Sets the local repository for caching configurations.
  ///
  /// This is required and must be called before [build].
  RemoteConfigBuilder withRepository(LocalConfigRepository repository) {
    _repository = repository;
    return this;
  }

  /// Sets a custom sync strategy for checking updates.
  ///
  /// If not set, the mediator will use the service's [checkForUpdates] method directly.
  RemoteConfigBuilder withSyncStrategy(SyncStrategy strategy) {
    _syncStrategy = strategy;
    return this;
  }

  /// Sets the load mode for configuration fetching.
  ///
  /// Defaults to [LoadMode.hybrid].
  RemoteConfigBuilder withLoadMode(LoadMode mode) {
    _loadMode = mode;
    return this;
  }

  /// Enables or disables logging.
  ///
  /// When enabled, uses [ConsoleLogger]. When disabled, uses [NoOpLogger].
  /// You can also set a custom logger using [withLogger].
  RemoteConfigBuilder enableLogging(bool enable) {
    _enableLogging = enable;
    return this;
  }

  /// Sets a custom logger for configuration operations.
  ///
  /// This overrides the [enableLogging] setting.
  RemoteConfigBuilder withLogger(ConfigLogger logger) {
    _logger = logger;
    return this;
  }

  /// Builds and returns a configured [RemoteConfigMediator].
  ///
  /// Throws [StateError] if required dependencies ([withService] and [withRepository])
  /// have not been set.
  RemoteConfigMediator build() {
    if (_service == null) {
      throw StateError(
        'RemoteConfigService is required. Call withService() before build().',
      );
    }
    if (_repository == null) {
      throw StateError(
        'LocalConfigRepository is required. Call withRepository() before build().',
      );
    }

    final logger = _logger ?? (_enableLogging ? const ConsoleLogger() : const NoOpLogger());

    return RemoteConfigMediator(
      _service!,
      _repository!,
      syncStrategy: _syncStrategy,
      loadMode: _loadMode,
      logger: logger,
    );
  }
}

