import 'package:blendberry_flutter_sdk/blendberry_flutter_sdk.dart';
import 'package:example/impl/repository.dart';
import 'package:example/impl/service.dart';

/// Example mediator setup using a singleton pattern.
///
/// This demonstrates how to set up the mediator with your own
/// service and repository implementations.
///
/// Shows two approaches:
/// 1. Direct instantiation
/// 2. Using the builder pattern (recommended for complex setups)
class RemoteConfigMediatorImpl {
  static RemoteConfigMediator? _instance;

  static RemoteConfigMediator get instance {
    return _instance ??= _createMediator();
  }

  /// Creates mediator using direct instantiation.
  static RemoteConfigMediator _createMediatorDirect() {
    return RemoteConfigMediator(
      RemoteConfigServiceImpl("http://10.0.2.2:8080/configs"),
      LocalConfigRepositoryImpl(),
      logger: const ConsoleLogger(), // Enable logging for debugging
    );
  }

  /// Creates mediator using builder pattern (recommended).
  static RemoteConfigMediator _createMediator() {
    return RemoteConfigBuilder()
        .withService(RemoteConfigServiceImpl("http://10.0.2.2:8080/configs"))
        .withRepository(LocalConfigRepositoryImpl())
        .withLoadMode(LoadMode.hybrid)
        .enableLogging(true) // Enable console logging
        .build();
  }
}