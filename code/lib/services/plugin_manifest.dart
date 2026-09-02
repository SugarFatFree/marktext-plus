/// Metadata declared by an installed MarkText Plus plugin.
///
/// The manifest is the only plugin data read during startup. Executable code
/// is never imported into the editor process.
class PluginManifest {
  const PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.entrypoint,
    this.minAppVersion = '',
    this.capabilities = const <String>[],
  });

  final String id;
  final String name;
  final String version;
  final String entrypoint;
  final String minAppVersion;
  final List<String> capabilities;

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('plugin manifest requires a non-empty $key');
      }
      return value.trim();
    }

    final rawCapabilities = json['capabilities'];
    final capabilities = rawCapabilities == null
        ? const <String>[]
        : rawCapabilities is List
            ? rawCapabilities.whereType<String>().toList(growable: false)
            : throw const FormatException('capabilities must be a list');

    return PluginManifest(
      id: requiredString('id'),
      name: requiredString('name'),
      version: requiredString('version'),
      entrypoint: requiredString('entrypoint'),
      minAppVersion: (json['minAppVersion'] as String?)?.trim() ?? '',
      capabilities: List.unmodifiable(capabilities),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'entrypoint': entrypoint,
        if (minAppVersion.isNotEmpty) 'minAppVersion': minAppVersion,
        'capabilities': capabilities,
      };
}
