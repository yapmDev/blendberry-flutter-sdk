import 'dart:convert';
import 'package:blendberry_flutter_sdk/blendberry_flutter_sdk.dart';
import 'package:http/http.dart' as http;

/// Example implementation of [RemoteConfigService] using HTTP REST API.
///
/// This is a concrete implementation that demonstrates how to implement
/// [RemoteConfigService] for a REST backend. You should adapt this to
/// match your own backend's API format.
///
/// This implementation assumes:
/// - GET /{env}?version={version} for fetching configs
/// - GET /lookup?env={env}&version={version}&lastModDate={date} for sync check
/// - Response format matches [RemoteConfigModel] JSON structure
class RemoteConfigServiceImpl implements RemoteConfigService {
  final String baseUrl;

  RemoteConfigServiceImpl(this.baseUrl);

  @override
  Future<ConfigData?> fetchConfig(String env, [String? version]) async {
    final url = Uri.parse('$baseUrl/$env').replace(queryParameters: {
      "version": version ?? "latest"
    });
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return RemoteConfigModel.fromJson(jsonDecode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      // Handle network errors gracefully
      return null;
    }
  }

  @override
  Future<SyncResult> checkForUpdates(
    ConfigMetadata local,
    String env, [
    String? version,
  ]) async {
    // This implementation assumes the backend supports a lookup endpoint
    // that accepts the sync identifier and returns a status string.
    // You should adapt this to match your backend's sync mechanism.
    
    final url = Uri.parse('$baseUrl/lookup').replace(queryParameters: {
      "env": env,
      "version": version ?? "latest",
      "syncIdentifier": local.syncIdentifier,
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        switch (responseBody) {
          case "UP_TO_DATE":
            return SyncResult.upToDate;
          case "NEEDS_TO_UPDATE":
            return SyncResult.needsUpdate;
          case "NOT_FOUND":
            return SyncResult.notFound;
          default:
            return SyncResult.error;
        }
      } else if (response.statusCode == 404) {
        return SyncResult.notFound;
      } else {
        return SyncResult.error;
      }
    } catch (e) {
      return SyncResult.error;
    }
  }
}
