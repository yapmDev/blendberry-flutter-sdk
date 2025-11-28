import 'package:flutter_remote_config/flutter_remote_config.dart';
import 'app_config.dart';

/// Mapper that converts raw configuration data into AppConfig domain entity.
///
/// This mapper implements the RemoteConfigMapper interface to transform
/// the generic `Map<String, dynamic>` into a strongly-typed AppConfig object.
class AppConfigMapper implements RemoteConfigMapper<AppConfig> {
  @override
  AppConfig map(Map<String, dynamic> map) {
    // Extract and validate configuration values
    final theme = map['theme'] as String? ?? 'light';
    final apiUrl = map['apiUrl'] as String? ?? 'https://api.default.com';

    // Extract nested feature flags
    final featuresMap = map['features'] as Map<String, dynamic>? ?? {};
    final features = FeatureFlags(
      featureA: featuresMap['featureA'] as bool? ?? false,
      featureB: featuresMap['featureB'] as bool? ?? false,
      featureC: featuresMap['featureC'] as bool? ?? false,
    );

    // Extract nested settings
    final settingsMap = map['settings'] as Map<String, dynamic>? ?? {};
    final settings = AppSettings(
      timeout: settingsMap['timeout'] as int? ?? 30,
      retries: settingsMap['retries'] as int? ?? 3,
    );

    return AppConfig(
      theme: theme,
      apiUrl: apiUrl,
      features: features,
      settings: settings,
    );
  }
}

