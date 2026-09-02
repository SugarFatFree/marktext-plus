/// A command a plugin contributes to the host command palette and menus.
class PluginCommand {
  const PluginCommand({required this.id, required this.title});

  final String id;
  final String title;

  factory PluginCommand.fromJson(Map<String, dynamic> json) => PluginCommand(
        id: _requiredString(json, 'id'),
        title: _requiredString(json, 'title'),
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}

/// A toolbar item rendered in a host-defined slot, never at arbitrary pixels.
class PluginToolbarItem {
  const PluginToolbarItem({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final String icon;

  factory PluginToolbarItem.fromJson(Map<String, dynamic> json) =>
      PluginToolbarItem(
        id: _requiredString(json, 'id'),
        title: _requiredString(json, 'title'),
        icon: _requiredString(json, 'icon'),
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'icon': icon};
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('plugin contribution requires a non-empty $key');
  }
  return value.trim();
}

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
    this.permissions = const <String>[],
    this.commands = const <PluginCommand>[],
    this.toolbar = const <PluginToolbarItem>[],
  });

  final String id;
  final String name;
  final String version;
  final String entrypoint;
  final String minAppVersion;
  final List<String> capabilities;
  final List<String> permissions;
  final List<PluginCommand> commands;
  final List<PluginToolbarItem> toolbar;

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) => _requiredString(json, key);
    List<String> strings(String key) {
      final value = json[key];
      if (value == null) return const [];
      if (value is! List || value.any((item) => item is! String)) {
        throw FormatException('$key must be a list of strings');
      }
      return List.unmodifiable(value.cast<String>());
    }

    List<T> objects<T>(String key, T Function(Map<String, dynamic>) parse) {
      final value = json[key];
      if (value == null) return const [];
      if (value is! List || value.any((item) => item is! Map)) {
        throw FormatException('$key must be a list of objects');
      }
      return List.unmodifiable([
        for (final item in value)
          parse(Map<String, dynamic>.from(item as Map)),
      ]);
    }

    return PluginManifest(
      id: requiredString('id'),
      name: requiredString('name'),
      version: requiredString('version'),
      entrypoint: requiredString('entrypoint'),
      minAppVersion: (json['minAppVersion'] as String?)?.trim() ?? '',
      capabilities: strings('capabilities'),
      permissions: strings('permissions'),
      commands: objects('commands', PluginCommand.fromJson),
      toolbar: objects('toolbar', PluginToolbarItem.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'entrypoint': entrypoint,
        if (minAppVersion.isNotEmpty) 'minAppVersion': minAppVersion,
        'capabilities': capabilities,
        if (permissions.isNotEmpty) 'permissions': permissions,
        if (commands.isNotEmpty)
          'commands': commands.map((item) => item.toJson()).toList(),
        if (toolbar.isNotEmpty)
          'toolbar': toolbar.map((item) => item.toJson()).toList(),
      };
}
