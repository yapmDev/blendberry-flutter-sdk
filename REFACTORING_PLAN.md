# Plan de Refactorización: SDK Abstracto y Configurable

## Objetivo Principal
Transformar el SDK en una librería completamente abstracta y configurable que funcione con **cualquier backend**, donde el SDK solo orquesta y el usuario implementa todas las partes específicas.

---

## Principios de Diseño

1. **Abstracción Total**: El SDK no debe asumir ningún formato de backend
2. **Configurabilidad**: El usuario define cómo se comunica con su backend
3. **Flexibilidad**: Soporte para diferentes estrategias de sincronización
4. **Extensibilidad**: Fácil de extender sin modificar el core
5. **Mantenibilidad**: Código limpio y bien documentado

---

## Fase 1: Abstraer el Modelo de Datos

### Objetivo
Eliminar el acoplamiento con `RemoteConfigModel` y permitir que el usuario defina su propio modelo.

### Cambios Requeridos

#### 1.1 Crear interfaz genérica para datos de configuración
**Archivo**: `lib/src/data/config_data.dart` (NUEVO)

```dart
/// Generic interface for configuration data from any backend
abstract interface class ConfigData {
  /// Extracts the actual configuration values as a map
  Map<String, dynamic> extractConfigs();
  
  /// Extracts metadata for sync/version checking (optional)
  ConfigMetadata? extractMetadata();
}

/// Generic metadata interface for sync strategies
abstract interface class ConfigMetadata {
  /// Any identifier that can be used for sync checking
  /// (version, etag, timestamp, hash, etc.)
  String get syncIdentifier;
}
```

#### 1.2 Hacer el repositorio genérico
**Archivo**: `lib/src/data/repository.dart` (MODIFICAR)

- Cambiar `RemoteConfigModel` por `ConfigData` genérico
- El repositorio debe trabajar con `ConfigData` en lugar de `RemoteConfigModel`
- Métodos de metadata deben usar `ConfigMetadata` genérico

#### 1.3 Mover RemoteConfigModel a opcional/ejemplo
**Archivo**: `lib/src/data/model.dart` (REFACTORIZAR)

- Convertir `RemoteConfigModel` en una implementación de ejemplo de `ConfigData`
- Mover a carpeta `examples/` o marcarlo como `@Deprecated` con alternativa
- Crear documentación de cómo implementar tu propio `ConfigData`

---

## Fase 2: Abstraer el Servicio Remoto

### Objetivo
Hacer `RemoteConfigService` completamente abstracto sin implementación concreta.

### Cambios Requeridos

#### 2.1 Convertir RemoteConfigService en interfaz pura
**Archivo**: `lib/src/domain/service.dart` (REFACTORIZAR COMPLETO)

**Eliminar**:
- Implementación concreta de `fetchConfig`
- Implementación concreta de `lookupRemotely`
- Dependencia de `http` package
- `_baseUrl` field (cada implementación decide cómo manejar URLs)

**Crear interfaz abstracta**:
```dart
/// Completely abstract service for fetching remote configurations
abstract interface class RemoteConfigService {
  /// Fetches configuration data from remote backend
  /// Returns ConfigData or null if not found/error
  Future<ConfigData?> fetchConfig(String env, [String? version]);
  
  /// Optional: Check if update is needed without fetching full config
  /// Returns SyncResult indicating if update is needed
  Future<SyncResult> checkForUpdates(ConfigMetadata localMetadata, String env, [String? version]);
}
```

#### 2.2 Crear sistema de sincronización abstracto
**Archivo**: `lib/src/domain/sync_strategy.dart` (NUEVO)

```dart
/// Result of a sync check operation
enum SyncResult {
  upToDate,      // Local is current
  needsUpdate,   // Remote has newer version
  notFound,      // Remote doesn't have this config
  error,         // Error during check
}

/// Optional: Strategy pattern for different sync mechanisms
abstract interface class SyncStrategy {
  Future<SyncResult> checkForUpdates(
    ConfigMetadata local,
    RemoteConfigService service,
    String env,
    [String? version]
  );
}
```

#### 2.3 Mover implementación concreta a ejemplo
**Archivo**: `example/lib/impl/service.dart` (MOVER LÓGICA)

- La implementación concreta que usa `http` debe estar solo en el ejemplo
- Documentar cómo implementar para diferentes backends (REST, GraphQL, gRPC, etc.)

---

## Fase 3: Refactorizar el Mediator

### Objetivo
Hacer el mediator completamente genérico y configurable, sin asumir formatos específicos.

### Cambios Requeridos

#### 3.1 Hacer mediator genérico
**Archivo**: `lib/src/presentation/mediator.dart` (REFACTORIZAR COMPLETO)

**Cambios principales**:
- Eliminar dependencia de `RemoteConfigModel`
- Usar `ConfigData` genérico
- Hacer sync strategy opcional/configurable
- Mejorar manejo de errores (eliminar `assert`)
- Permitir diferentes flujos de carga

**Nueva estructura**:
```dart
abstract class RemoteConfigMediator implements RemoteConfigDispatcher {
  final RemoteConfigService _remoteService;
  final LocalConfigRepository _localRepository;
  final SyncStrategy? _syncStrategy; // Optional
  
  RemoteConfigMediator(
    this._remoteService,
    this._localRepository, {
    SyncStrategy? syncStrategy,
  });
  
  // Load configs with proper error handling
  Future<void> loadConfigs(String env, [String? version]);
  
  // Dispatch with mapper
  @override
  T dispatch<T extends RemoteConfig>(RemoteConfigMapper<T> mapper);
}
```

#### 3.2 Mejorar manejo de errores
- Eliminar todos los `assert()`
- Crear excepciones personalizadas
- Permitir callbacks de error opcionales
- Logging opcional/configurable

**Archivo**: `lib/src/domain/exceptions.dart` (NUEVO)

```dart
class RemoteConfigException implements Exception {
  final String message;
  final Object? cause;
  RemoteConfigException(this.message, [this.cause]);
}

class ConfigNotFoundException extends RemoteConfigException {
  ConfigNotFoundException(String env, [String? version])
    : super('Configuration not found for env: $env${version != null ? ", version: $version" : ""}');
}

class ConfigSyncException extends RemoteConfigException {
  ConfigSyncException(String message, [Object? cause]) : super(message, cause);
}
```

#### 3.3 Hacer flujo de carga configurable
- Permitir diferentes modos: `localOnly`, `remoteOnly`, `hybrid` (default)
- Permitir deshabilitar sync check
- Permitir forzar refresh

---

## Fase 4: Abstraer el Repositorio Local

### Objetivo
Hacer el repositorio más flexible para diferentes formatos de almacenamiento.

### Cambios Requeridos

#### 4.1 Hacer metadata genérica
**Archivo**: `lib/src/data/repository.dart` (REFACTORIZAR)

- Cambiar `RemoteConfigMetadata` por `ConfigMetadata` genérico
- El repositorio debe poder serializar/deserializar cualquier `ConfigData`
- Agregar método para limpiar cache

**Nueva interfaz**:
```dart
abstract interface class LocalConfigRepository {
  bool hasData();
  ConfigMetadata? getMetadata(); // Nullable si no hay datos
  Map<String, dynamic> getConfigs();
  Future<void> saveConfig(ConfigData config);
  Future<void> clearCache(); // Nuevo
}
```

---

## Fase 5: Sistema de Configuración y Extensibilidad

### Objetivo
Permitir configuración avanzada y extensibilidad.

### Cambios Requeridos

#### 5.1 Crear builder/configuration pattern
**Archivo**: `lib/src/presentation/config_builder.dart` (NUEVO)

```dart
class RemoteConfigBuilder {
  RemoteConfigService? _service;
  LocalConfigRepository? _repository;
  SyncStrategy? _syncStrategy;
  LoadMode _loadMode = LoadMode.hybrid;
  bool _enableLogging = false;
  
  RemoteConfigBuilder withService(RemoteConfigService service) { ... }
  RemoteConfigBuilder withRepository(LocalConfigRepository repository) { ... }
  RemoteConfigBuilder withSyncStrategy(SyncStrategy strategy) { ... }
  RemoteConfigBuilder withLoadMode(LoadMode mode) { ... }
  RemoteConfigBuilder enableLogging(bool enable) { ... }
  
  RemoteConfigMediator build();
}

enum LoadMode {
  localOnly,   // Solo usa cache local
  remoteOnly,  // Siempre fetch remoto
  hybrid,      // Check local, sync si necesario (default)
}
```

#### 5.2 Crear sistema de logging opcional
**Archivo**: `lib/src/util/logger.dart` (NUEVO)

```dart
abstract interface class ConfigLogger {
  void debug(String message);
  void info(String message);
  void warning(String message);
  void error(String message, [Object? error]);
}

class NoOpLogger implements ConfigLogger { ... }
class ConsoleLogger implements ConfigLogger { ... }
```

---

## Fase 6: Documentación y Ejemplos

### Objetivo
Documentar cómo usar el SDK con diferentes backends.

### Cambios Requeridos

#### 6.1 Actualizar README
- Ejemplos de implementación para diferentes backends
- Guía de migración desde versión anterior
- Ejemplos de diferentes estrategias de sync

#### 6.2 Crear ejemplos de implementación
**Nuevos archivos en `example/`**:
- `example/impl/rest_backend_service.dart` - Ejemplo REST
- `example/impl/graphql_backend_service.dart` - Ejemplo GraphQL
- `example/impl/firebase_backend_service.dart` - Ejemplo Firebase
- `example/impl/custom_sync_strategy.dart` - Ejemplo sync personalizado

#### 6.3 Documentación de arquitectura
**Archivo**: `docs/ARCHITECTURE.md` (NUEVO)
- Explicar diseño de abstracciones
- Cómo extender el SDK
- Mejores prácticas

---

## Fase 7: Testing y Calidad

### Objetivo
Asegurar calidad del código refactorizado.

### Cambios Requeridos

#### 7.1 Tests unitarios
- Tests para mediator con mocks
- Tests para diferentes sync strategies
- Tests de error handling
- Tests de edge cases

#### 7.2 Tests de integración
- Tests con diferentes implementaciones de servicio
- Tests con diferentes repositorios
- Tests de flujos completos

#### 7.3 Validación
- Eliminar todos los `assert()`
- Validar inputs
- Manejo robusto de errores

---

## Orden de Implementación Recomendado

1. **Fase 1** (Modelo de datos) - Base para todo lo demás
2. **Fase 2** (Servicio remoto) - Core de la abstracción
3. **Fase 4** (Repositorio) - Necesario para Fase 3
4. **Fase 3** (Mediator) - Depende de Fases 1, 2, 4
5. **Fase 5** (Configuración) - Mejora la experiencia
6. **Fase 6** (Documentación) - En paralelo con desarrollo
7. **Fase 7** (Testing) - Continuo durante desarrollo

---

## Archivos a Crear

1. `lib/src/data/config_data.dart` - Interfaces genéricas
2. `lib/src/domain/sync_strategy.dart` - Sistema de sync
3. `lib/src/domain/exceptions.dart` - Excepciones personalizadas
4. `lib/src/presentation/config_builder.dart` - Builder pattern
5. `lib/src/util/logger.dart` - Sistema de logging
6. `docs/ARCHITECTURE.md` - Documentación de arquitectura

## Archivos a Modificar

1. `lib/src/data/repository.dart` - Hacer genérico
2. `lib/src/data/model.dart` - Convertir en ejemplo
3. `lib/src/domain/service.dart` - Hacer completamente abstracto
4. `lib/src/presentation/mediator.dart` - Refactorizar completamente
5. `lib/blendberry_flutter_sdk.dart` - Actualizar exports
6. `README.md` - Actualizar documentación

## Archivos a Eliminar/Mover

1. `lib/src/data/environment.dart` - Mover a opcional o eliminar (muy específico)
2. Implementaciones concretas del SDK → Mover a `example/`

---

## Checklist de Validación

- [ ] No hay dependencias de `http` en el core del SDK
- [ ] No hay implementaciones concretas en el SDK (solo interfaces)
- [ ] Todos los `assert()` eliminados
- [ ] Manejo de errores robusto
- [ ] Tests completos
- [ ] Documentación actualizada
- [ ] Ejemplos funcionando
- [ ] Backward compatibility considerada (o versión mayor)

---

## Notas Importantes

1. **Breaking Changes**: Esta refactorización introduce breaking changes. Considerar versión 2.0.0
2. **Migración**: Crear guía de migración para usuarios existentes
3. **Performance**: Asegurar que las abstracciones no impacten performance
4. **Simplicidad**: Mantener la API simple aunque internamente sea compleja

---

## Próximos Pasos

1. Revisar y aprobar este plan
2. Crear branch `refactor/abstract-sdk`
3. Comenzar con Fase 1
4. Implementar fase por fase con tests
5. Actualizar documentación en cada fase

