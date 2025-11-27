import 'dart:convert';
import 'package:blendberry_flutter_sdk/blendberry_flutter_sdk.dart';
import 'package:example/util/pref_manager.dart';

class LocalConfigRepositoryImpl implements LocalConfigRepository {

  final _prefsManager = SharedPrefsManager();

  @override
  bool hasData() => _prefsManager.getString("config_json") != null;

  @override
  ConfigMetadata? getMetadata() {
    final configJson = _prefsManager.getString("config_json");
    if (configJson == null) return null;
    final configData = RemoteConfigModel.fromJson(jsonDecode(configJson));
    return configData.extractMetadata();
  }

  @override
  Map<String, dynamic> getConfigs() {
    final configJson = _prefsManager.getString("config_json");
    if (configJson == null) return {};
    final configData = RemoteConfigModel.fromJson(jsonDecode(configJson));
    return configData.extractConfigs();
  }

  @override
  Future<void> saveConfig(ConfigData config) async {
    // This implementation assumes ConfigData is RemoteConfigModel
    // In a real scenario, you might need to handle serialization differently
    // based on the actual ConfigData implementation
    if (config is RemoteConfigModel) {
      await _prefsManager.setString("config_json", jsonEncode(config.toJson()));
    } else {
      // For other ConfigData implementations, you might need custom serialization
      // This is a limitation of this example - in production, you'd handle this properly
      throw UnimplementedError('Serialization for ${config.runtimeType} not implemented');
    }
  }

  @override
  Future<void> clearCache() async {
    await _prefsManager.remove("config_json");
  }
}