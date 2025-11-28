# Architecture Documentation

This document explains the architecture and design decisions of Flutter Remote Config.

---

## Design Philosophy

The SDK is built on the principle of **complete abstraction**. It makes no assumptions about:

- Your backend API format (REST, GraphQL, gRPC, etc.)
- Your data structure
- Your sync mechanism (version, ETag, timestamp, etc.)
- Your storage mechanism (SharedPreferences, SQLite, Hive, etc.)

Instead, it provides **interfaces** that you implement to match your specific needs.

---

## Architecture Layers

### 1. Presentation Layer

**Purpose**: Orchestrates configuration loading and dispatching.

**Components**:
- `RemoteConfigMediator`: Main orchestrator that coordinates between service and repository
- `RemoteConfigBuilder`: Fluent builder for configuring mediators
- `LoadMode`: Enum defining how configurations are loaded

**Responsibilities**:
- Decide when to fetch from remote vs use local cache
- Coordinate sync checking
- Handle errors and logging
- Dispatch configurations to mappers

### 2. Domain Layer

**Purpose**: Business logic and abstractions.

**Components**:
- `RemoteConfigService`: Abstract interface for remote fetching
- `SyncStrategy`: Optional abstract interface for custom sync logic
- `RemoteConfigMapper`: Interface for mapping raw data to domain objects
- `RemoteConfig`: Marker interface for domain configuration entities
- Exceptions: `ConfigNotFoundException`, `ConfigSyncException`, `ConfigDataException`

**Responsibilities**:
- Define contracts for remote communication
- Define contracts for sync checking
- Define contracts for data mapping
- Provide exception types

### 3. Data Layer

**Purpose**: Data models and storage abstractions.

**Components**:
- `ConfigData`: Abstract interface for configuration data
- `ConfigMetadata`: Abstract interface for sync metadata
- `LocalConfigRepository`: Abstract interface for local storage
- `RemoteConfigModel`: Example implementation (optional, for reference)

**Responsibilities**:
- Define contracts for data structures
- Define contracts for local storage
- Provide example implementations

### 4. Utility Layer

**Purpose**: Cross-cutting concerns.

**Components**:
- `ConfigLogger`: Interface for logging
- `NoOpLogger`: Default logger (no-op)
- `ConsoleLogger`: Development logger

**Responsibilities**:
- Provide logging infrastructure
- Support debugging and monitoring

---

## Data Flow

### Hybrid Mode (Default)

```
1. User calls loadConfigs(env, version)
   │
   ├─> Check if local repository has data
   │   │
   │   ├─> Yes: Get local metadata
   │   │   │
   │   │   └─> Call service.checkForUpdates(localMetadata, env, version)
   │   │       │
   │   │       ├─> SyncResult.upToDate
   │   │       │   └─> Use local cache
   │   │       │
   │   │       ├─> SyncResult.needsUpdate
   │   │       │   └─> Fetch from remote → Save to local → Use
   │   │       │
   │   │       ├─> SyncResult.notFound
   │   │       │   └─> Use local cache as fallback
   │   │       │
   │   │       └─> SyncResult.error
   │   │           └─> Use local cache as fallback
   │   │
   │   └─> No: Fetch from remote → Save to local → Use
   │
   └─> Configurations ready for dispatch
```

### Remote Only Mode

```
1. User calls loadConfigs(env, version)
   │
   └─> Always fetch from remote → Save to local → Use
```

### Local Only Mode

```
1. User calls loadConfigs(env, version)
   │
   └─> Use local cache (throw if not available)
```

---

## Extension Points

### 1. Custom Backend Service

Implement `RemoteConfigService` to match your backend:

```dart
class MyBackendService implements RemoteConfigService {
  @override
  Future<ConfigData?> fetchConfig(String env, [String? version]) {
    // Your implementation
  }

  @override
  Future<SyncResult> checkForUpdates(...) {
    // Your sync logic
  }
}
```

### 2. Custom Data Format

Implement `ConfigData` and `ConfigMetadata`:

```dart
class MyConfigData implements ConfigData {
  // Your data structure
  @override
  Map<String, dynamic> extractConfigs() { ... }
  @override
  ConfigMetadata? extractMetadata() { ... }
}
```

### 3. Custom Sync Strategy

Implement `SyncStrategy` for advanced sync logic:

```dart
class MySyncStrategy implements SyncStrategy {
  @override
  Future<SyncResult> checkForUpdates(...) {
    // Custom sync logic
  }
}
```

### 4. Custom Storage

Implement `LocalConfigRepository`:

```dart
class MyRepository implements LocalConfigRepository {
  // Your storage implementation
}
```

### 5. Custom Logging

Implement `ConfigLogger`:

```dart
class MyLogger implements ConfigLogger {
  // Your logging implementation
}
```

---

## Design Patterns Used

### 1. Strategy Pattern

- `SyncStrategy`: Different sync mechanisms
- `LoadMode`: Different loading strategies
- `ConfigLogger`: Different logging strategies

### 2. Repository Pattern

- `LocalConfigRepository`: Abstracts local storage
- `RemoteConfigService`: Abstracts remote fetching

### 3. Builder Pattern

- `RemoteConfigBuilder`: Fluent API for configuration

### 4. Adapter Pattern

- `ConfigData`: Adapts different backend formats to common interface
- `RemoteConfigMapper`: Adapts raw data to domain objects

### 5. Mediator Pattern

- `RemoteConfigMediator`: Coordinates between service and repository

---

## Error Handling Strategy

The SDK uses exceptions for error handling:

1. **ConfigNotFoundException**: Configuration doesn't exist
   - Thrown when: Remote service returns 404, or local cache is empty in `localOnly` mode
   - Recovery: User should handle by providing fallback or retrying

2. **ConfigSyncException**: Sync check failed
   - Thrown when: Network error during sync check
   - Recovery: SDK falls back to local cache in hybrid mode

3. **ConfigDataException**: Invalid or malformed data
   - Thrown when: Parsing fails, required fields missing
   - Recovery: User should handle by logging and using fallback

All exceptions extend `RemoteConfigException` for easy catching:

```dart
try {
  await mediator.loadConfigs('prod');
} on RemoteConfigException catch (e) {
  // Handle any config error
}
```

---

## Thread Safety

The SDK is designed to be used from a single isolate. If you need multi-threaded access:

1. Use a singleton mediator
2. Ensure your implementations are thread-safe
3. Consider using locks for concurrent access

---

## Performance Considerations

### Caching

- Configurations are cached locally after first fetch
- Sync checks are lightweight (no full data transfer)
- Local cache is used when remote is unavailable

### Network Efficiency

- `checkForUpdates` should be lightweight (HEAD request, metadata only)
- Full fetch only happens when update is needed
- Consider implementing request batching if needed

### Memory

- Configurations are stored as `Map<String, dynamic>`
- Large configurations may impact memory
- Consider implementing lazy loading for very large configs

---

## Testing Strategy

### Unit Tests

Test each component in isolation:

- Mock `RemoteConfigService`
- Mock `LocalConfigRepository`
- Test mediator logic with different scenarios

### Integration Tests

Test with real implementations:

- Use a test backend service
- Use in-memory repository
- Verify end-to-end flow

### Example Tests

See `/example` directory for integration test examples.

---

## Future Enhancements

Potential improvements:

1. **Retry Logic**: Automatic retry on network failures
2. **Background Sync**: Periodic sync in background
3. **Config Versioning**: Support for multiple config versions
4. **A/B Testing**: Built-in support for feature flags
5. **Analytics**: Track config usage and changes
6. **Encryption**: Encrypt sensitive config values
7. **Validation**: Schema validation for config data

---

## Migration Guide

If migrating from a previous version:

1. Update service implementation to new interface
2. Update data models to implement `ConfigData`
3. Update repository to use `ConfigData` instead of `RemoteConfigModel`
4. Update mediator instantiation (now uses builder or direct constructor)
5. Handle new exception types

See `CHANGELOG.md` for detailed migration steps.

