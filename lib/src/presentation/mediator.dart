import 'package:blendberry_flutter_sdk/src/data/repository.dart';
import 'package:blendberry_flutter_sdk/src/domain/entity.dart';
import 'package:blendberry_flutter_sdk/src/domain/exceptions.dart';
import 'package:blendberry_flutter_sdk/src/domain/mapper.dart';
import 'package:blendberry_flutter_sdk/src/domain/service.dart';
import 'package:blendberry_flutter_sdk/src/domain/sync_strategy.dart';
import 'package:blendberry_flutter_sdk/src/presentation/dispatcher.dart';
import 'package:blendberry_flutter_sdk/src/util/logger.dart';

/// Load mode for configuration fetching.
///
/// Determines how the mediator should load configurations.
enum LoadMode {
  /// Only use locally cached configuration, never fetch from remote.
  localOnly,

  /// Always fetch from remote, ignoring local cache.
  remoteOnly,

  /// Check local cache first, sync with remote if needed (default).
  hybrid,
}

/// Acts as the central orchestrator for managing and delivering remote configurations.
///
/// [RemoteConfigMediator] handles the logic of determining whether to use cached
/// configurations or fetch new ones from the backend service. It works with generic
/// [ConfigData] and [ConfigMetadata] interfaces, making it compatible with any backend.
///
/// It also serves as a dispatcher that maps raw configuration data into runtime-ready
/// [RemoteConfig] entities, abstracting away the underlying persistence or networking logic.
///
/// The standard flow (hybrid mode):
/// 1. Check for local data.
/// 2. If available, verify freshness with the backend using [checkForUpdates].
/// 3. If fresh, reuse; otherwise fetch and update.
/// 4. If no local data, fetch from remote and cache.
/// 5. Finally, expose the config through the `dispatch` method.
///
/// Example usage:
/// ```dart
/// final mediator = RemoteConfigMediator(
///   MyBackendService(),
///   MyLocalRepository(),
/// );
/// await mediator.loadConfigs("staging");
/// final config = mediator.dispatch(ThemeConfigMapper());
/// ```
class RemoteConfigMediator implements RemoteConfigDispatcher {
  /// The remote service responsible for fetching and checking configuration data.
  final RemoteConfigService _remoteService;

  /// The local repository used for reading and saving persisted configuration data.
  final LocalConfigRepository _localRepository;

  /// Optional sync strategy for custom sync logic.
  ///
  /// If not provided, uses the service's [checkForUpdates] method directly.
  final SyncStrategy? _syncStrategy;

  /// The load mode determining how configurations are loaded.
  final LoadMode _loadMode;

  /// Logger for configuration operations.
  final ConfigLogger _logger;

  /// Holds the configurations to be dispatched.
  Map<String, dynamic>? _configs;

  /// Creates a [RemoteConfigMediator] with explicit dependencies.
  ///
  /// [remoteService] The service responsible for fetching remote configuration data.
  /// [localRepository] The local repository used to cache and retrieve persisted data.
  /// [syncStrategy] Optional custom sync strategy. If null, uses service's checkForUpdates.
  /// [loadMode] The mode for loading configurations. Defaults to [LoadMode.hybrid].
  /// [logger] Optional logger for configuration operations. Defaults to [NoOpLogger].
  RemoteConfigMediator(
    this._remoteService,
    this._localRepository, {
    SyncStrategy? syncStrategy,
    LoadMode loadMode = LoadMode.hybrid,
    ConfigLogger? logger,
  })  : _syncStrategy = syncStrategy,
        _loadMode = loadMode,
        _logger = logger ?? const NoOpLogger();

  /// Loads and prepares the latest configuration data for dispatching.
  ///
  /// This method's behavior depends on the [LoadMode]:
  /// - [LoadMode.localOnly]: Only uses local cache, throws if not available.
  /// - [LoadMode.remoteOnly]: Always fetches from remote, ignores local cache.
  /// - [LoadMode.hybrid]: Checks local cache, syncs with remote if needed.
  ///
  /// [env] The environment identifier (e.g., "dev", "staging", "prod").
  /// [version] Optional version identifier. If null, fetches latest.
  ///
  /// Throws [ConfigNotFoundException] if configuration is not found.
  /// Throws [ConfigSyncException] if sync check fails.
  /// Throws [ConfigDataException] if data is invalid.
  ///
  /// Must be called once before invoking [dispatch].
  Future<void> loadConfigs(String env, [String? version]) async {
    switch (_loadMode) {
      case LoadMode.localOnly:
        await _loadLocalOnly(env, version);
        break;
      case LoadMode.remoteOnly:
        await _loadRemoteOnly(env, version);
        break;
      case LoadMode.hybrid:
        await _loadHybrid(env, version);
        break;
    }
  }

  /// Loads configuration using local-only mode.
  Future<void> _loadLocalOnly(String env, [String? version]) async {
    _logger.debug('Loading configuration in localOnly mode for env: $env');
    
    if (!_localRepository.hasData()) {
      _logger.error('No local configuration found for env: $env');
      throw ConfigNotFoundException(env, version);
    }

    _configs = _localRepository.getConfigs();
    if (_configs == null || _configs!.isEmpty) {
      _logger.error('Local configuration data is empty');
      throw ConfigDataException('Local configuration data is empty');
    }
    
    _logger.info('Configuration loaded from local cache');
  }

  /// Loads configuration using remote-only mode.
  Future<void> _loadRemoteOnly(String env, [String? version]) async {
    _logger.debug('Loading configuration in remoteOnly mode for env: $env');
    
    _logger.info('Fetching configuration from remote service...');
    final configData = await _remoteService.fetchConfig(env, version);
    if (configData == null) {
      _logger.error('Configuration not found for env: $env${version != null ? ", version: $version" : ""}');
      throw ConfigNotFoundException(env, version);
    }

    try {
      _configs = configData.extractConfigs();
      _logger.debug('Configuration extracted, saving to local repository...');
      await _localRepository.saveConfig(configData);
      _logger.info('Configuration loaded and cached successfully');
    } catch (e) {
      _logger.error('Failed to extract or save configuration', e);
      throw ConfigDataException('Failed to extract or save configuration', e);
    }
  }

  /// Loads configuration using hybrid mode (check local, sync if needed).
  Future<void> _loadHybrid(String env, [String? version]) async {
    _logger.debug('Loading configuration in hybrid mode for env: $env');
    
    if (_localRepository.hasData()) {
      _logger.debug('Local configuration found, checking for updates...');
      final localMetadata = _localRepository.getMetadata();
      if (localMetadata != null) {
        // Check if update is needed
        _logger.debug('Checking for updates with sync identifier: ${localMetadata.syncIdentifier}');
        final syncResult = _syncStrategy != null
            ? await _syncStrategy!.checkForUpdates(
                localMetadata,
                _remoteService,
                env,
                version,
              )
            : await _remoteService.checkForUpdates(localMetadata, env, version);

        switch (syncResult) {
          case SyncResult.upToDate:
            // Use local cache
            _logger.info('Local configuration is up-to-date, using cache');
            _configs = _localRepository.getConfigs();
            return;

          case SyncResult.needsUpdate:
            // Fetch and update
            _logger.info('Update available, fetching from remote...');
            await _loadRemoteOnly(env, version);
            return;

          case SyncResult.notFound:
            // Remote doesn't have this config, but we have local
            // Use local as fallback
            _logger.warning('Configuration not found on remote, using local cache as fallback');
            _configs = _localRepository.getConfigs();
            return;

          case SyncResult.error:
            // Sync check failed, use local as fallback
            _logger.warning('Sync check failed, using local cache as fallback');
            _configs = _localRepository.getConfigs();
            return;
        }
      } else {
        // Local data exists but no metadata, fetch fresh
        _logger.debug('Local data exists but no metadata, fetching fresh...');
        await _loadRemoteOnly(env, version);
      }
    } else {
      // No local data, fetch from remote
      _logger.debug('No local configuration found, fetching from remote...');
      await _loadRemoteOnly(env, version);
    }
  }

  /// Maps the raw configuration into a domain-specific [RemoteConfig] using the given [mapper].
  ///
  /// This method must be called after [loadConfigs] has successfully completed.
  ///
  /// Throws [StateError] if [loadConfigs] has not been called or failed.
  @override
  T dispatch<T extends RemoteConfig>(RemoteConfigMapper<T> mapper) {
    if (_configs == null) {
      _logger.error('Attempted to dispatch configuration before loading');
      throw StateError(
        'Configuration not loaded. Call loadConfigs() first.',
      );
    }
    _logger.debug('Dispatching configuration with mapper: ${mapper.runtimeType}');
    return mapper.map(_configs!);
  }
}