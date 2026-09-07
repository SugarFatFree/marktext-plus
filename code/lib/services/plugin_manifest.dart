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


/// When a menu entry applies.
enum PluginMenuCondition {
  /// Offered whichever way things stand.
  always,

  /// Only with something selected.
  selection,

  /// Only with nothing selected.
  noSelection,
}

class PluginMenuItem {
  const PluginMenuItem({
    required this.id,
    required this.title,
    required this.location,
    this.when = PluginMenuCondition.always,
  });

  final String id;
  final String title;
  final String location;

  /// What has to be true for this entry to be worth offering.
  ///
  /// Without it a plugin's entries were all offered at once: "translate the
  /// selection" with nothing selected, and "translate the document" while the
  /// reader was pointing at a paragraph.
  final PluginMenuCondition when;

  bool appliesTo({required bool hasSelection}) => switch (when) {
        PluginMenuCondition.always => true,
        PluginMenuCondition.selection => hasSelection,
        PluginMenuCondition.noSelection => !hasSelection,
      };

  factory PluginMenuItem.fromJson(Map<String, dynamic> json) => PluginMenuItem(
        id: _requiredString(json, 'id'),
        title: _requiredString(json, 'title'),
        location: _requiredString(json, 'location'),
        when: switch ((json['when'] as String?)?.trim()) {
          null || '' || 'always' => PluginMenuCondition.always,
          'selection' => PluginMenuCondition.selection,
          'noSelection' => PluginMenuCondition.noSelection,
          // Ignoring it would quietly make the entry unconditional, which is
          // the opposite of what an author writing `when` is asking for.
          final unknown => throw FormatException(
              'unknown "when" on a menu entry: $unknown. '
              'Expected always, selection or noSelection',
            ),
        },
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'location': location,
        if (when != PluginMenuCondition.always) 'when': when.name,
      };
}

/// A panel a plugin contributes to the right side bar.
///
/// The side bar is a rail of icons, so a panel has one. Opening it runs the
/// plugin's command of the same id, and whatever that returns fills the
/// drawer.
class PluginSidePanel {
  const PluginSidePanel({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;

  /// The name of an icon the editor knows. A panel with nothing to draw would
  /// be a gap in the rail that opens something, so it is required.
  final String icon;

  factory PluginSidePanel.fromJson(Map<String, dynamic> json) =>
      PluginSidePanel(
        id: _requiredString(json, 'id'),
        title: _requiredString(json, 'title'),
        icon: _requiredString(json, 'icon'),
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'icon': icon};
}

class PluginSettingPage {
  const PluginSettingPage({required this.id, required this.title});

  final String id;
  final String title;

  factory PluginSettingPage.fromJson(Map<String, dynamic> json) =>
      PluginSettingPage(
        id: _requiredString(json, 'id'),
        title: _requiredString(json, 'title'),
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}

/// What a plugin is allowed to do.
///
/// Modelled on how VS Code and IntelliJ describe an extension: a broad surface
/// declared up front rather than a narrow one. The difference is that nothing
/// here is reviewed by anybody, so what a plugin declares is shown to the
/// reader and enforced by the editor rather than taken on trust.
class PluginPermission {
  const PluginPermission._();

  // -- The document the reader has open --

  /// Read the selection and the document text.
  static const documentRead = 'document.read';

  /// Change the document — replace the selection, insert text.
  static const documentWrite = 'document.write';

  // -- Places a plugin may put things --

  /// An entry in the editor's right-click menu.
  static const uiContextMenu = 'ui.contextMenu';

  /// An entry in the top menu bar.
  static const uiMenuBar = 'ui.menuBar';

  /// A button in the toolbar.
  static const uiToolbar = 'ui.toolbar';

  /// A panel of its own in the side bar.
  static const uiSidebar = 'ui.sidebar';

  /// An item in the status bar.
  static const uiStatusBar = 'ui.statusBar';

  /// A settings page of its own.
  static const uiSettings = 'ui.settings';

  /// Commands in the command palette.
  static const uiCommandPalette = 'ui.commandPalette';

  /// Messages to the reader.
  static const uiNotifications = 'ui.notifications';

  // -- Capabilities --

  /// Ask the model the reader configured. The API key is never handed over.
  static const aiChat = 'ai.chat';

  /// Keep its own settings file, inside its own directory.
  static const storageLocal = 'storage.local';

  /// Read the clipboard.
  static const clipboardRead = 'clipboard.read';

  /// Write the clipboard.
  static const clipboardWrite = 'clipboard.write';

  /// Read files under the folder the reader opened.
  static const workspaceRead = 'workspace.read';

  /// Write files under the folder the reader opened.
  static const workspaceWrite = 'workspace.write';

  /// Make HTTP requests of its own choosing. The widest thing a plugin can
  /// ask for: anything it can read, it can send anywhere.
  static const networkRequest = 'network.request';

  /// Open a web view of its own and load its own page in it.
  ///
  /// Carries [networkRequest] with it, and the reader is told so: a page in a
  /// web view fetches whatever it likes, and a permission list that said only
  /// "opens a web view" would be describing a smaller thing than what was
  /// granted. The traffic goes through the editor's own local proxy, so it
  /// follows the system proxy and is written to the plugin's log — which is
  /// how the reader can find out what a plugin has been talking to.
  static const uiWebview = 'ui.webview';

  /// Every permission this version of the editor understands.
  static const all = <String>[
    documentRead,
    documentWrite,
    uiContextMenu,
    uiMenuBar,
    uiToolbar,
    uiSidebar,
    uiStatusBar,
    uiSettings,
    uiCommandPalette,
    uiNotifications,
    aiChat,
    storageLocal,
    clipboardRead,
    clipboardWrite,
    workspaceRead,
    workspaceWrite,
    networkRequest,
    uiWebview,
  ];

  /// Permissions that another permission brings with it.
  ///
  /// A web view can fetch anything, so declaring it grants network access
  /// whether or not the manifest says so. Listing it is not a formality: the
  /// reader decides from this list, and a list that understates what was
  /// granted is worse than no list.
  static const implied = <String, List<String>>{
    uiWebview: [networkRequest],
  };

  /// [declared] together with everything those permissions imply.
  static List<String> withImplied(Iterable<String> declared) {
    final out = <String>[...declared];
    for (final permission in declared) {
      for (final extra in implied[permission] ?? const <String>[]) {
        if (!out.contains(extra)) out.add(extra);
      }
    }
    return out;
  }

  /// What to tell the reader this permission lets the plugin do.
  static String describe(String permission) => switch (permission) {
        documentRead => 'Read the open document and your selection',
        documentWrite => 'Change the open document',
        uiContextMenu => 'Add entries to the right-click menu',
        uiMenuBar => 'Add entries to the menu bar',
        uiToolbar => 'Add buttons to the toolbar',
        uiSidebar => 'Add a panel to the side bar',
        uiStatusBar => 'Add an item to the status bar',
        uiSettings => 'Add a settings page',
        uiCommandPalette => 'Add commands to the command palette',
        uiNotifications => 'Show you messages',
        aiChat => 'Ask the AI model you configured (never sees your API key)',
        storageLocal => 'Keep its own settings',
        clipboardRead => 'Read your clipboard',
        clipboardWrite => 'Write to your clipboard',
        workspaceRead => 'Read files in the folder you opened',
        workspaceWrite => 'Write files in the folder you opened',
        networkRequest => 'Send requests to any server it chooses',
        uiWebview => 'Open its own web page inside the editor, which can '
            'reach any server (the editor logs where)',
        _ => 'Unrecognised permission — this version grants nothing for it',
      };
}

/// How a plugin's code runs, if it has any.
///
/// A plugin has to run on a machine that has nothing installed but the editor.
/// That rules out shipping source for a language whose toolchain the reader
/// would have to install, and it is why [PluginRuntime.lua] is the default for
/// anything with logic in it: the interpreter is part of the editor.
enum PluginRuntime {
  /// No code at all — themes, snippets, syntax rules.
  data,

  /// A Lua script, run by the editor's own pure-Dart interpreter.
  lua,

  /// A JavaScript script, run by the editor's embedded QuickJS engine.
  js,

  /// A prebuilt executable the plugin ships for each platform it supports.
  process,
}

/// One field on a plugin's own settings page.
class PluginSettingField {
  const PluginSettingField({
    required this.key,
    required this.title,
    this.type = 'text',
    this.defaultValue = '',
  });

  final String key;
  final String title;

  /// `text`, `password`, `boolean` or `number`. The host draws the control.
  final String type;
  final String defaultValue;

  factory PluginSettingField.fromJson(Map<String, dynamic> json) =>
      PluginSettingField(
        key: _requiredString(json, 'key'),
        title: _requiredString(json, 'title'),
        type: (json['type'] as String?)?.trim() ?? 'text',
        defaultValue: (json['default'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'type': type,
        if (defaultValue.isNotEmpty) 'default': defaultValue,
      };
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
    this.description = '',
    this.minAppVersion = '',
    this.repository = '',
    this.capabilities = const <String>[],
    this.permissions = const <String>[],
    this.commands = const <PluginCommand>[],
    this.toolbar = const <PluginToolbarItem>[],
    this.menus = const <PluginMenuItem>[],
    this.pages = const <PluginSettingPage>[],
    this.panels = const <PluginSidePanel>[],
    this.runtime = PluginRuntime.data,
    this.settings = const <PluginSettingField>[],
    this.defaultLocale = 'en',
    this.locales = const <String, Map<String, String>>{},
    this.entrypoints = const <String, Map<String, String>>{},
  });

  final String id;
  final String name;
  final String version;
  final String entrypoint;

  /// One line saying what this plugin does, for the plugin list.
  ///
  /// Like every other string a plugin shows, this may be a key into its own
  /// [locales] — the reader's language is not the author's.
  final String description;

  final String minAppVersion;

  /// Where the plugin came from, if it said. Shown on its detail page so an
  /// installed plugin can still be read about.
  final String repository;
  final List<String> capabilities;
  final List<String> permissions;
  final List<PluginCommand> commands;
  final List<PluginToolbarItem> toolbar;
  final List<PluginMenuItem> menus;
  final List<PluginSettingPage> pages;

  /// Panels this plugin puts in the right side bar. Needs `ui.sidebar`.
  final List<PluginSidePanel> panels;

  /// How this plugin's code runs, if it has any.
  final PluginRuntime runtime;

  /// The fields the host draws on this plugin's own settings page.
  final List<PluginSettingField> settings;

  /// The language the plugin's own strings fall back to.
  final String defaultLocale;

  /// The plugin's own strings, by language code. A plugin can ship as many
  /// languages as its author wants without the editor shipping any of them.
  final Map<String, Map<String, String>> locales;

  /// Whether the reader granted [permission] by installing this plugin.
  ///
  /// A permission this version does not understand grants nothing: a typo in a
  /// manifest, and a capability from a newer editor, both mean the same thing
  /// here — the plugin does not get it.
  bool hasPermission(String permission) =>
      PluginPermission.all.contains(permission) &&
      permissions.contains(permission);

  /// A compiled plugin's executables, by operating system and then by
  /// architecture.
  ///
  /// The system is the part a plugin author always has to answer — a Windows
  /// build is a different file from a Linux one. The architecture often is
  /// not: a macOS universal binary is one file holding both, which is what
  /// this application itself ships, and a plugin should not have to write the
  /// same path twice to say so. So an entry is either one path for the whole
  /// system, or a table of architectures with an optional shared `default`.
  ///
  /// Stored resolved: `{'macos': {'default': ..., 'arm64': ...}}`.
  final Map<String, Map<String, String>> entrypoints;

  /// The architectures the editor knows how to name.
  static const architectures = ['x64', 'arm64'];

  /// The platforms this plugin runs on, as concrete `os-arch` names.
  ///
  /// Concrete on purpose: telling the reader a plugin "supports macOS" leaves
  /// them to work out whether that includes the machine in front of them.
  List<String> get supportedPlatforms => [
        for (final os in entrypoints.keys)
          for (final arch in architectures)
            if (_lookUp(os, arch) != null) '$os-$arch',
      ];

  /// Whether this plugin can run on [platform], named `os-arch`.
  bool supportsPlatform(String platform) =>
      runtime != PluginRuntime.process || entrypointFor(platform) != null;

  /// What to execute on [platform], or null when the author did not build it.
  ///
  /// An architecture built for on purpose wins over the shared one; a plugin
  /// that ships both means the specialised build to be used.
  String? entrypointFor(String platform) {
    if (runtime != PluginRuntime.process) return entrypoint;
    final split = platform.lastIndexOf('-');
    if (split == -1) return null;
    return _lookUp(platform.substring(0, split), platform.substring(split + 1));
  }

  String? _lookUp(String os, String arch) {
    final forOs = entrypoints[os];
    if (forOs == null) return null;
    return forOs[arch] ?? forOs['default'];
  }

  /// Whether an editor at [appVersion] is new enough for this plugin.
  ///
  /// `minAppVersion` was parsed, stored and written back out, and checked
  /// nowhere: a plugin declaring 1.7.0 installed and ran on 1.6.1, reaching
  /// for whatever it was written against and failing however that happened to
  /// fail. The author had said plainly what they needed and nothing listened.
  ///
  /// A version neither side can read is not a reason to refuse: the plugin is
  /// allowed, because being unable to compare is not evidence of a mismatch.
  bool isSupportedBy(String appVersion) =>
      compareVersions(appVersion, minAppVersion) >= 0;

  /// [a] against [b] as version numbers: negative, zero, positive.
  ///
  /// Zero when either cannot be read as three numbers — two versions nobody
  /// can parse say nothing about which is newer, and guessing would be worse
  /// than admitting it. The one comparison, so "is this an update" and "is
  /// this editor new enough" cannot drift apart.
  static int compareVersions(String a, String b) {
    final left = _versionParts(a);
    final right = _versionParts(b);
    if (left == null || right == null) return 0;
    for (var i = 0; i < 3; i++) {
      if (left[i] != right[i]) return left[i] > right[i] ? 1 : -1;
    }
    return 0;
  }

  /// `1.10.0` as [1, 10, 0], or null when it is not three numbers.
  ///
  /// Compared as numbers, because as text "1.10.0" sorts before "1.9.0".
  static List<int>? _versionParts(String version) {
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(version.trim());
    if (match == null) return null;
    return [
      for (var group = 1; group <= 3; group++) int.parse(match.group(group)!),
    ];
  }

  /// The plugin's strings in [locale], falling back to its default language.
  ///
  /// `zh_CN` finds `zh`: a plugin author who wrote one Chinese translation
  /// should not have to enumerate every region that speaks it.
  ///
  /// The fallback is per key, not per map. Returning the best-matching map
  /// whole meant that a language which had translated most of a plugin but
  /// not all of it showed the reader raw keys where the untranslated strings
  /// belonged — worse than the English the author had already written, and
  /// something the author could only find by reading in that language.
  Map<String, String> stringsFor(String locale) {
    final language = locale.split(RegExp(r'[_-]')).first;
    final byPriority = [
      locales[defaultLocale],
      locales[language],
      locales[locale],
    ];
    final resolved = <String, String>{};
    for (final strings in byPriority) {
      if (strings != null) resolved.addAll(strings);
    }
    return resolved;
  }

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

    final runtime = switch ((json['runtime'] as String?)?.trim()) {
      'lua' => PluginRuntime.lua,
      'js' => PluginRuntime.js,
      'process' => PluginRuntime.process,
      null || '' => PluginRuntime.data,
      final unknown => throw FormatException('unknown plugin runtime: $unknown'),
    };

    // Wrong keys are refused rather than skipped. A silently dropped
    // `windwos` or `arm-64` becomes "this plugin does not support your
    // platform" at the moment the reader clicks, with nothing to explain it.
    const systems = ['windows', 'macos', 'linux'];
    final entrypoints = <String, Map<String, String>>{};
    final rawEntrypoints = json['entrypoints'];
    if (rawEntrypoints is Map) {
      for (final entry in rawEntrypoints.entries) {
        final os = entry.key;
        if (os is! String || !systems.contains(os)) {
          throw FormatException(
            'unknown operating system in "entrypoints": $os. '
            'Expected one of ${systems.join(', ')}',
          );
        }
        final value = entry.value;
        if (value is String) {
          // One file for the whole system: a macOS universal binary, or
          // anything else that does not vary by architecture.
          entrypoints[os] = {'default': value};
          continue;
        }
        if (value is! Map || value.isEmpty) {
          throw FormatException(
            '"entrypoints.$os" must be a path, or a table of architectures',
          );
        }
        final byArch = <String, String>{};
        for (final arch in value.entries) {
          final key = arch.key;
          if (key is! String ||
              (key != 'default' &&
                  !PluginManifest.architectures.contains(key))) {
            throw FormatException(
              'unknown architecture in "entrypoints.$os": $key. '
              'Expected default, ${PluginManifest.architectures.join(', ')}',
            );
          }
          if (arch.value is! String) {
            throw FormatException('"entrypoints.$os.$key" must be a path');
          }
          byArch[key] = arch.value as String;
        }
        entrypoints[os] = byArch;
      }
    }

    if (runtime == PluginRuntime.process && entrypoints.isEmpty) {
      throw const FormatException(
        'a compiled plugin must name an executable per operating system in '
        '"entrypoints", either one path or a table of architectures',
      );
    }

    final everyExecutable = [
      for (final byArch in entrypoints.values) ...byArch.values,
    ];
    final entrypoint = runtime == PluginRuntime.process
        ? everyExecutable.first
        : requiredString('entrypoint');
    for (final candidate in [entrypoint, ...everyExecutable]) {
      if (candidate.toLowerCase().endsWith('.dart')) {
        // Running this would need a Dart SDK on the reader's machine, which
        // the editor does not install and cannot assume. Dart compiles to a
        // real executable — `dart compile exe` — and that is what a compiled
        // plugin ships. Refusing here says so at install time instead of at
        // the moment the reader clicks the command.
        throw const FormatException(
          'a plugin cannot ship Dart source: use a .lua or .js script, or '
          'compile it and ship the executable with runtime "process"',
        );
      }
    }

    final rawLocales = json['locales'];
    final locales = <String, Map<String, String>>{};
    if (rawLocales is Map) {
      for (final entry in rawLocales.entries) {
        final value = entry.value;
        if (entry.key is! String || value is! Map) continue;
        locales[entry.key as String] = {
          for (final s in value.entries)
            if (s.key is String && s.value is String)
              s.key as String: s.value as String,
        };
      }
    }

    return PluginManifest(
      id: requiredString('id'),
      name: requiredString('name'),
      version: requiredString('version'),
      entrypoint: entrypoint,
      description: (json['description'] as String?)?.trim() ?? '',
      minAppVersion: (json['minAppVersion'] as String?)?.trim() ?? '',
      repository: (json['repository'] as String?)?.trim() ?? '',
      capabilities: strings('capabilities'),
      permissions: strings('permissions'),
      commands: objects('commands', PluginCommand.fromJson),
      toolbar: objects('toolbar', PluginToolbarItem.fromJson),
      menus: objects('menus', PluginMenuItem.fromJson),
      pages: objects('pages', PluginSettingPage.fromJson),
      panels: objects('panels', PluginSidePanel.fromJson),
      runtime: runtime,
      settings: objects('settings', PluginSettingField.fromJson),
      defaultLocale: (json['defaultLocale'] as String?)?.trim() ?? 'en',
      locales: locales,
      entrypoints: entrypoints,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'entrypoint': entrypoint,
        if (description.isNotEmpty) 'description': description,
        if (minAppVersion.isNotEmpty) 'minAppVersion': minAppVersion,
        if (repository.isNotEmpty) 'repository': repository,
        'capabilities': capabilities,
        if (permissions.isNotEmpty) 'permissions': permissions,
        if (commands.isNotEmpty)
          'commands': commands.map((item) => item.toJson()).toList(),
        if (toolbar.isNotEmpty)
          'toolbar': toolbar.map((item) => item.toJson()).toList(),
        if (menus.isNotEmpty)
          'menus': menus.map((item) => item.toJson()).toList(),
        if (pages.isNotEmpty)
          'pages': pages.map((item) => item.toJson()).toList(),
        if (panels.isNotEmpty)
          'panels': panels.map((item) => item.toJson()).toList(),
        if (runtime != PluginRuntime.data) 'runtime': runtime.name,
        if (settings.isNotEmpty)
          'settings': settings.map((item) => item.toJson()).toList(),
        if (entrypoints.isNotEmpty) 'entrypoints': entrypoints,
        if (locales.isNotEmpty) ...{
          'defaultLocale': defaultLocale,
          'locales': locales,
        },
      };
}
