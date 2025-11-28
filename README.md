# Flutter Remote Config

A **completely abstract and configurable** Flutter SDK for managing remote configurations. Works with **any backend** - you implement the interfaces to match your backend's API.

---

## Overview

Flutter Remote Config is a flexible, backend-agnostic remote configuration system that allows mobile applications to fetch and update configurations dynamically from any backend service. The SDK provides a clean architecture with complete abstraction - you implement the interfaces to match your specific backend format.

**Key Philosophy**: The SDK only orchestrates. You implement how it communicates with your backend.

---

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
- [Implementing Your Backend](#implementing-your-backend)
- [Examples](#examples)
- [API Reference](#api-reference)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- ✅ **Backend Agnostic**: Works with any backend (REST, GraphQL, gRPC, Firebase, etc.)
- ✅ **Completely Abstract**: No assumptions about your backend format
- ✅ **Flexible Sync**: Customizable sync strategies (version-based, ETag, timestamp, etc.)
- ✅ **Multiple Load Modes**: `localOnly`, `remoteOnly`, or `hybrid` (default)
- ✅ **Offline Support**: Local caching with automatic sync
- ✅ **Type-Safe**: Generic mappers for type-safe configuration access
- ✅ **Logging**: Optional logging system for debugging
- ✅ **Error Handling**: Comprehensive exception handling
- ✅ **Builder Pattern**: Fluent API for easy configuration

---

## Architecture

The SDK follows a clean architecture with complete abstraction:

```
┌─────────────────────────────────────────┐
│     Your Application Code               │
│  (Uses RemoteConfig via Mappers)        │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│     Presentation Layer                  │
│  - RemoteConfigMediator (orchestrator)  │
│  - RemoteConfigBuilder (configuration)  │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│     Domain Layer                        │
│  - RemoteConfigService (abstract)       │
│  - SyncStrategy (abstract, optional)    │
│  - RemoteConfigMapper (your mappers)    │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│     Data Layer                          │
│  - ConfigData (abstract)                │
│  - ConfigMetadata (abstract)            │
│  - LocalConfigRepository (abstract)     │
└─────────────────────────────────────────┘
```

### What You Implement

1. **`RemoteConfigService`**: How to fetch from your backend
2. **`ConfigData`**: Your backend's response format
3. **`ConfigMetadata`**: How to identify/config versions
4. **`LocalConfigRepository`**: How to store locally
5. **`RemoteConfigMapper`**: How to map to your domain objects

### What the SDK Provides

- Orchestration logic (mediator)
- Sync checking strategies
- Caching and offline support
- Error handling
- Logging infrastructure
- Builder pattern for configuration

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_remote_config: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### Development Version

To use the latest development version from GitHub:

```yaml
dependencies:
  flutter_remote_config:
    git:
      url: git://github.com/blendberry/flutter-remote-config.git
      ref: main
```

---

## Quick Start

### 1. Implement Your Backend Service

```dart
class MyBackendService implements RemoteConfigService {
  @override
  Future<ConfigData?> fetchConfig(String env, [String? version]) async {
    // Your implementation - REST, GraphQL, gRPC, etc.
    final response = await http.get('https://api.example.com/config/$env');
    return MyConfigData.fromJson(jsonDecode(response.body));
  }

  @override
  Future<SyncResult> checkForUpdates(
    ConfigMetadata local,
    String env, [
    String? version,
  ]) async {
    // Your sync logic - ETag, version, timestamp, etc.
    final response = await http.head('https://api.example.com/config/$env');
    final remoteETag = response.headers['etag'];
    return remoteETag == local.syncIdentifier
        ? SyncResult.upToDate
        : SyncResult.needsUpdate;
  }
}
```

### 2. Implement Your Config Data

```dart
class MyConfigData implements ConfigData {
  final Map<String, dynamic> data;
  final String version;
  final String etag;

  MyConfigData(this.data, this.version, this.etag);

  @override
  Map<String, dynamic> extractConfigs() => data;

  @override
  ConfigMetadata? extractMetadata() => MyConfigMetadata(version, etag);
}

class MyConfigMetadata implements ConfigMetadata {
  final String version;
  final String etag;

  MyConfigMetadata(this.version, this.etag);

  @override
  String get syncIdentifier => '$version-$etag';
}
```

### 3. Implement Your Local Repository

```dart
class MyLocalRepository implements LocalConfigRepository {
  final SharedPreferences _prefs;

  MyLocalRepository(this._prefs);

  @override
  bool hasData() => _prefs.containsKey('config');

  @override
  ConfigMetadata? getMetadata() {
    final json = _prefs.getString('config_metadata');
    return json != null ? MyConfigMetadata.fromJson(jsonDecode(json)) : null;
  }

  @override
  Map<String, dynamic> getConfigs() {
    final json = _prefs.getString('config');
    return json != null ? jsonDecode(json) : {};
  }

  @override
  Future<void> saveConfig(ConfigData config) async {
    if (config is MyConfigData) {
      await _prefs.setString('config', jsonEncode(config.extractConfigs()));
      await _prefs.setString('config_metadata', jsonEncode(config.extractMetadata()?.toJson()));
    }
  }

  @override
  Future<void> clearCache() async {
    await _prefs.remove('config');
    await _prefs.remove('config_metadata');
  }
}
```

### 4. Create Your Mapper

```dart
class ThemeConfigMapper implements RemoteConfigMapper<ThemeConfig> {
  @override
  ThemeConfig map(Map<String, dynamic> map) {
    return ThemeConfig(
      useDarkTheme: map['useDarkTheme'] ?? false,
      primaryColor: Color(map['primaryColor'] ?? 0xFF000000),
    );
  }
}
```

### 5. Use the SDK

```dart
// Using builder pattern (recommended)
final mediator = RemoteConfigBuilder()
    .withService(MyBackendService())
    .withRepository(MyLocalRepository(await SharedPreferences.getInstance()))
    .withLoadMode(LoadMode.hybrid)
    .enableLogging(true)
    .build();

// Load configurations
await mediator.loadConfigs('production');

// Use configurations
final themeConfig = mediator.dispatch(ThemeConfigMapper());
if (themeConfig.useDarkTheme) {
  // Apply dark theme
}
```

---

## Core Concepts

### Load Modes

- **`LoadMode.hybrid`** (default): Check local cache, sync with remote if needed
- **`LoadMode.localOnly`**: Only use local cache, never fetch remote
- **`LoadMode.remoteOnly`**: Always fetch from remote, ignore local cache

### Sync Strategies

The SDK supports different sync mechanisms:

- **Version-based**: Compare version strings
- **ETag-based**: Use HTTP ETags
- **Timestamp-based**: Compare last modification dates
- **Hash-based**: Compare content hashes
- **Custom**: Implement your own `SyncStrategy`

### Error Handling

The SDK throws specific exceptions:

- `ConfigNotFoundException`: Configuration not found
- `ConfigSyncException`: Sync check failed
- `ConfigDataException`: Invalid or malformed data

Always wrap `loadConfigs()` in try-catch:

```dart
try {
  await mediator.loadConfigs('production');
} on ConfigNotFoundException {
  // Handle not found
} on ConfigSyncException {
  // Handle sync error
} on ConfigDataException {
  // Handle data error
}
```

---

## Implementing Your Backend

### REST API Example

See `example/lib/services/example_config_service.dart` for a complete REST implementation example.

### GraphQL Example

```dart
class GraphQLConfigService implements RemoteConfigService {
  final GraphQLClient _client;

  GraphQLConfigService(this._client);

  @override
  Future<ConfigData?> fetchConfig(String env, [String? version]) async {
    final query = '''
      query GetConfig(\$env: String!, \$version: String) {
        config(env: \$env, version: \$version) {
          data
          version
          etag
        }
      }
    ''';
    
    final result = await _client.query(QueryOptions(
      document: gql(query),
      variables: {'env': env, 'version': version},
    ));
    
    if (result.hasException) return null;
    return GraphQLConfigData.fromJson(result.data!['config']);
  }

  @override
  Future<SyncResult> checkForUpdates(
    ConfigMetadata local,
    String env, [
    String? version,
  ]) async {
    // Implement GraphQL sync check
    // ...
  }
}
```

### Firebase Remote Config Example

```dart
class FirebaseConfigService implements RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  FirebaseConfigService(this._remoteConfig);

  @override
  Future<ConfigData?> fetchConfig(String env, [String? version]) async {
    await _remoteConfig.fetchAndActivate();
    final data = _remoteConfig.getAll();
    return FirebaseConfigData(data, _remoteConfig.lastFetchTime);
  }

  @override
  Future<SyncResult> checkForUpdates(
    ConfigMetadata local,
    String env, [
    String? version,
  ]) async {
    final lastFetch = _remoteConfig.lastFetchTime;
    return lastFetch.isAfter(local.lastModified)
        ? SyncResult.needsUpdate
        : SyncResult.upToDate;
  }
}
```

---

## Examples

A complete working example is available in the `/example` directory demonstrating:

- REST API implementation
- Local storage with SharedPreferences
- Custom mappers
- Error handling
- Builder pattern usage

To run the example:

```bash
cd example
flutter pub get
flutter run
```

---

## API Reference

### RemoteConfigService

Abstract interface for fetching remote configurations.

```dart
abstract interface class RemoteConfigService {
  Future<ConfigData?> fetchConfig(String env, [String? version]);
  Future<SyncResult> checkForUpdates(ConfigMetadata local, String env, [String? version]);
}
```

### ConfigData

Abstract interface for configuration data.

```dart
abstract interface class ConfigData {
  Map<String, dynamic> extractConfigs();
  ConfigMetadata? extractMetadata();
}
```

### ConfigMetadata

Abstract interface for sync metadata.

```dart
abstract interface class ConfigMetadata {
  String get syncIdentifier;
}
```

### LocalConfigRepository

Abstract interface for local storage.

```dart
abstract interface class LocalConfigRepository {
  bool hasData();
  ConfigMetadata? getMetadata();
  Map<String, dynamic> getConfigs();
  Future<void> saveConfig(ConfigData config);
  Future<void> clearCache();
}
```

### RemoteConfigMediator

Main orchestrator for configuration management.

```dart
class RemoteConfigMediator {
  RemoteConfigMediator(
    RemoteConfigService remoteService,
    LocalConfigRepository localRepository, {
    SyncStrategy? syncStrategy,
    LoadMode loadMode = LoadMode.hybrid,
    ConfigLogger? logger,
  });

  Future<void> loadConfigs(String env, [String? version]);
  T dispatch<T extends RemoteConfig>(RemoteConfigMapper<T> mapper);
}
```

### RemoteConfigBuilder

Fluent builder for creating mediators.

```dart
final mediator = RemoteConfigBuilder()
    .withService(MyService())
    .withRepository(MyRepository())
    .withSyncStrategy(MySyncStrategy())
    .withLoadMode(LoadMode.hybrid)
    .enableLogging(true)
    .build();
```

---

## Contributing

We welcome contributions! Please see our contributing guidelines.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Why This Architecture?

This SDK is designed to be **completely backend-agnostic**. Unlike other remote config SDKs that assume a specific backend format, this SDK lets you:

- Use any backend (REST, GraphQL, gRPC, Firebase, AWS, etc.)
- Define your own data format
- Implement your own sync strategy
- Choose your own storage mechanism

The SDK only provides the **orchestration logic** - you provide the **implementation details** that match your backend.
