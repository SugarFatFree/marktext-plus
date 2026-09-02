import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'plugin_manager.dart';
import 'plugin_manifest.dart';

class PluginCatalogEntry {
  const PluginCatalogEntry({
    required this.id,
    required this.name,
    required this.version,
    required this.downloadUrl,
    required this.sha256,
    this.description = '',
  });

  final String id;
  final String name;
  final String version;
  final Uri downloadUrl;
  final String sha256;
  final String description;

  factory PluginCatalogEntry.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('catalog entry requires $key');
      }
      return value.trim();
    }

    final url = Uri.tryParse(requiredString('downloadUrl'));
    if (url == null || !url.isScheme('https')) {
      throw const FormatException('plugin downloadUrl must use HTTPS');
    }
    return PluginCatalogEntry(
      id: requiredString('id'),
      name: requiredString('name'),
      version: requiredString('version'),
      downloadUrl: url,
      sha256: requiredString('sha256').toLowerCase(),
      description: (json['description'] as String?)?.trim() ?? '',
    );
  }
}

/// Reads the signed/transport-secured plugin registry lazily.
class PluginCatalogService {
  Future<List<PluginCatalogEntry>> fetch(Uri registryUrl) async {
    if (!registryUrl.isScheme('https')) {
      throw ArgumentError.value(registryUrl, 'registryUrl', 'must use HTTPS');
    }
    final client = HttpClient();
    try {
      final request = await client.getUrl(registryUrl);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('registry returned ${response.statusCode}');
      }
      final json = jsonDecode(await utf8.decoder.bind(response).join());
      if (json is! Map || json['plugins'] is! List) {
        throw const FormatException('registry must contain a plugins list');
      }
      return [
        for (final item in json['plugins'])
          PluginCatalogEntry.fromJson(item as Map<String, dynamic>),
      ];
    } finally {
      client.close(force: true);
    }
  }

  /// Downloads one catalog entry to a temporary file, verifies its digest,
  /// then delegates extraction and manifest validation to [manager].
  Future<PluginManifest> install(
    PluginCatalogEntry entry,
    PluginManager manager,
  ) async {
    final client = HttpClient();
    final temporary = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'marktext-plugin-${entry.id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}.zip',
    );
    try {
      final request = await client.getUrl(entry.downloadUrl);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('plugin download returned ${response.statusCode}');
      }
      final bytes = await response.fold<List<int>>([], (all, chunk) {
        all.addAll(chunk);
        return all;
      });
      final digest = sha256.convert(bytes).toString();
      if (digest != entry.sha256) {
        throw const FormatException('plugin SHA-256 does not match catalog');
      }
      await temporary.writeAsBytes(bytes, flush: true);
      return await manager.installZip(temporary);
    } finally {
      client.close(force: true);
      if (await temporary.exists()) await temporary.delete();
    }
  }
}
