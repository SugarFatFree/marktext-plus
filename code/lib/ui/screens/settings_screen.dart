import 'dart:convert';
import '../../core/constants.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../services/keybinding_service.dart';
import '../../services/image_service.dart';
import '../../services/ai_connection_service.dart';
import '../../providers/mcp_provider.dart';

enum _Category { general, editor, markdown, theme, keybindings, ai, mcp }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  _Category _selected = _Category.general;

  /// The text fields' controllers, kept rather than made in build.
  ///
  /// A controller built inside build is a new one on every rebuild: the old
  /// one is never disposed, and the field is reset to whatever the config
  /// says. These fields commit on Enter, so anything typed and not yet
  /// submitted was thrown away the moment something else on the screen
  /// rebuilt it — flipping any switch was enough.
  final _fields = <String, TextEditingController>{};

  /// What the config last said, so a value changed elsewhere still reaches
  /// the field while what the reader is typing does not get overwritten.
  final _lastFromConfig = <String, String>{};
  Timer? _aiSaveTimer;
  bool _testingAi = false;

  void _queueAiField(String field, String value) {
    _aiSaveTimer?.cancel();
    _aiSaveTimer = Timer(
        const Duration(milliseconds: AppConstants.debounceDelay), () {
      if (!mounted) return;
      final notifier = ref.read(settingsProvider.notifier);
      notifier.updateConfig((config) => switch (field) {
            'endpoint' => config.copyWith(aiEndpoint: value.trim()),
            'model' => config.copyWith(aiModel: value.trim()),
            'apiKey' => config.copyWith(aiApiKey: value),
            _ => config,
          });
    });
  }

  @override
  void dispose() {
    _aiSaveTimer?.cancel();
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// The controller for [key], showing [value] unless the reader is midway
  /// through replacing it.
  TextEditingController _field(String key, String value) {
    final controller =
        _fields.putIfAbsent(key, () => TextEditingController(text: value));
    if (_lastFromConfig[key] != value) {
      _lastFromConfig[key] = value;
      if (controller.text != value) controller.text = value;
    }
    return controller;
  }

  static const _localeMap = {
    'en_US': 'English',
    'zh_CN': '简体中文',
    'ja_JP': '日本語',
    'ko_KR': '한국어',
    'de_DE': 'Deutsch',
    'fr_FR': 'Français',
    'it_IT': 'Italiano',
    'ru_RU': 'Русский',
    'es_ES': 'Español',
    'pt_PT': 'Português',
    'ar_SA': 'العربية',
    'pt_BR': 'Português (Brasil)',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(settingsProvider);
    final tokens = AppTheme.getTokens(config.themeName);

    return Scaffold(
      backgroundColor: tokens.colorBg,
      appBar: AppBar(
        title: Text(l10n.fileSettings),
        backgroundColor: tokens.colorSurface,
        foregroundColor: tokens.colorText,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: tokens.colorBorder),
        ),
      ),
      body: Row(
        children: [
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: tokens.colorSurface,
              boxShadow: [
                BoxShadow(
                  color: tokens.colorBorder.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(1, 0),
                ),
              ],
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: [
                _catTile(_Category.general, l10n.settingsGeneral, Icons.settings, tokens),
                _catTile(_Category.editor, l10n.settingsEditor, Icons.edit, tokens),
                _catTile(_Category.markdown, l10n.settingsMarkdown, Icons.code, tokens),
                _catTile(_Category.theme, l10n.settingsTheme, Icons.palette, tokens),
                _catTile(_Category.keybindings, l10n.settingsKeybindings, Icons.keyboard, tokens),
                _catTile(_Category.ai, l10n.settingsAi, Icons.auto_awesome, tokens),
                _catTile(_Category.mcp, l10n.settingsMcp, Icons.hub_outlined,
                    tokens),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey(_selected),
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _content(l10n),
                  const SizedBox(height: 32),
                  _resetButton(l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _catTile(_Category cat, String label, IconData icon, AppThemeTokens tokens) {
    final isSelected = _selected == cat;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _selected = cat),
          hoverColor: tokens.colorSurfaceHover.withValues(alpha: 0.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? tokens.colorAccentMuted : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                ? Border.all(color: tokens.colorAccent.withValues(alpha: 0.3), width: 1)
                : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? tokens.colorAccent : tokens.colorTextMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? tokens.colorAccent : tokens.colorText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: tokens.colorAccent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(AppLocalizations l10n) {
    switch (_selected) {
      case _Category.general:
        return _generalSection(l10n);
      case _Category.editor:
        return _editorSection(l10n);
      case _Category.markdown:
        return _markdownSection(l10n);
      case _Category.theme:
        return _themeSection(l10n);
      case _Category.keybindings:
        return _keybindingsSection(l10n);
      case _Category.ai:
        return _aiSection(l10n);
      case _Category.mcp:
        return _mcpSection(l10n);
    }
  }

  // -- MCP --
  Widget _mcpSection(AppLocalizations l10n) {
    final config = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final status = ref.watch(mcpProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsMcp, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        // Said before the switch, not after: it opens a port on the reader's
        // machine, and that is the thing to know before turning it on.
        Text(
          l10n.settingsMcpWarning,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        _row(
          l10n.settingsMcpEnabled,
          Switch(
            value: config.mcpEnabled,
            onChanged: (value) => notifier.updateConfig(
              (c) => c.copyWith(
                mcpEnabled: value,
                // Made the first time it is switched on, and kept: rolling it
                // every launch would silently break a configuration the
                // reader had already written into their agent.
                mcpToken: c.mcpToken.isEmpty ? newMcpToken() : c.mcpToken,
              ),
            ),
          ),
        ),
        if (config.mcpEnabled) ...[
          _row(
            l10n.settingsMcpPort,
            SizedBox(
              width: 220,
              child: TextField(
                controller: _field(
                  'mcpPort',
                  '${status.port ?? config.mcpPort}',
                ),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  helperText: status.running
                      ? 'listening on ${status.port}'
                      : (status.error ?? l10n.settingsMcpStopped),
                  helperMaxLines: 3,
                ),
                onSubmitted: (value) {
                  final port = int.tryParse(value.trim());
                  if (port == null || port < 1024 || port > 65535) return;
                  notifier.updateConfig((c) => c.copyWith(mcpPort: port));
                },
              ),
            ),
          ),
          _row(
            l10n.settingsMcpToken,
            SizedBox(
              width: 320,
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      config.mcpToken,
                      maxLines: 1,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.settingsMcpNewToken,
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: () => notifier.updateConfig(
                      (c) => c.copyWith(mcpToken: newMcpToken()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.settingsMcpConfig, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _mcpExample(l10n, status, config),
        ],
      ],
    );
  }

  /// What to paste into the agent's MCP configuration.
  ///
  /// Shown filled in — the port it actually got and the token it actually
  /// has — because a sample with placeholders in it is a second thing to get
  /// right.
  Widget _mcpExample(
    AppLocalizations l10n,
    McpStatus status,
    AppConfig config,
  ) {
    final theme = Theme.of(context);
    final port = status.port ?? config.mcpPort;
    final example = const JsonEncoder.withIndent('  ').convert({
      'mcpServers': {
        'marktext-plus': {
          'type': 'http',
          'url': 'http://127.0.0.1:$port/mcp',
          'headers': {'Authorization': 'Bearer ${config.mcpToken}'},
        },
      },
    });
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            example,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: example)),
              icon: const Icon(Icons.copy, size: 16),
              label: Text(l10n.settingsMcpCopy),
            ),
          ),
        ],
      ),
    );
  }

  // -- General --
  Widget _generalSection(AppLocalizations l10n) {
    final config = ref.watch(settingsProvider);
    final locale = ref.watch(localeProvider);
    final localeKey = locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsGeneral,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        _row(
          l10n.settingsLanguage,
          SizedBox(
            width: 220,
            child: DropdownButton<String>(
              isExpanded: true,
                value: _localeMap.containsKey(localeKey) ? localeKey : 'en_US',
                items: _localeMap.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  final loc = LocaleNotifier.parseLocale(v);
                  ref.read(localeProvider.notifier).setLocale(loc);
                  ref.read(settingsProvider.notifier).setLocale(v);
                },
              ),
          ),
        ),
        _row(
          l10n.settingsAutoSave,
          Switch(
            value: config.autoSave,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .updateConfig((c) => c.copyWith(autoSave: v)),
          ),
        ),
        _row(
          l10n.settingsAutoSaveDelay,
          SizedBox(
            width: 120,
            child: TextField(
              controller:
                  _field('autoSaveDelay', config.autoSaveDelay.toString()),
              keyboardType: TextInputType.number,
              onSubmitted: (v) {
                final d = int.tryParse(v) ?? 5000;
                ref
                    .read(settingsProvider.notifier)
                    .updateConfig((c) => c.copyWith(autoSaveDelay: d));
              },
            ),
          ),
        ),
        _row(
          l10n.fileOpenBehavior,
          SizedBox(
            width: 220,
            child: DropdownButton<FileOpenBehavior>(
              isExpanded: true,
                value: config.fileOpenBehavior,
                items: [
                  DropdownMenuItem(
                    value: FileOpenBehavior.notSet,
                    child: Text(l10n.fileOpenBehaviorNotSet),
                  ),
                  DropdownMenuItem(
                    value: FileOpenBehavior.newWindow,
                    child: Text(l10n.fileOpenBehaviorNewWindow),
                  ),
                  DropdownMenuItem(
                    value: FileOpenBehavior.existingWindow,
                    child: Text(l10n.fileOpenBehaviorExistingWindow),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  ref
                      .read(settingsProvider.notifier)
                      .updateConfig((c) => c.copyWith(fileOpenBehavior: value));
                },
              ),
          ),
        ),
      ],
    );
  }

  // -- AI --
  Widget _aiSection(AppLocalizations l10n) {
    final config = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsAi,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        _row(
          l10n.settingsAiEnabled,
          Switch(
            value: config.aiEnabled,
            onChanged: (value) => notifier.updateConfig(
              (c) => c.copyWith(aiEnabled: value),
            ),
          ),
        ),
        _row(
          l10n.settingsAiProvider,
          SizedBox(
            width: 220,
            child: DropdownButton<AiProvider>(
              isExpanded: true,
              value: config.aiProvider,
              items: [
                DropdownMenuItem(
                  value: AiProvider.openai,
                  child: Text(l10n.settingsAiOpenai),
                ),
                DropdownMenuItem(
                  value: AiProvider.anthropic,
                  child: Text(l10n.settingsAiAnthropic),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                notifier.updateConfig((c) => c.copyWith(aiProvider: value));
              },
            ),
          ),
        ),
        Text(
          l10n.settingsAiEndpointHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _testingAi ? null : () => _testAiConfiguration(l10n),
            icon: _testingAi
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.network_check),
            label: Text(l10n.settingsAiTest),
          ),
        ),
        const SizedBox(height: 8),
        _row(
          l10n.settingsAiEndpoint,
          SizedBox(
            width: 360,
            child: TextField(
              controller: _field('aiEndpoint', config.aiEndpoint),
              onChanged: (value) => _queueAiField('endpoint', value),
              onSubmitted: (value) => notifier.updateConfig(
                (c) => c.copyWith(aiEndpoint: value.trim()),
              ),
            ),
          ),
        ),
        _row(
          l10n.settingsAiModel,
          SizedBox(
            width: 360,
            child: TextField(
              controller: _field('aiModel', config.aiModel),
              onChanged: (value) => _queueAiField('model', value),
              onSubmitted: (value) => notifier.updateConfig(
                (c) => c.copyWith(aiModel: value.trim()),
              ),
            ),
          ),
        ),
        _row(
          l10n.settingsAiApiKey,
          SizedBox(
            width: 360,
            child: TextField(
              controller: _field('aiApiKey', config.aiApiKey),
              obscureText: false,
              onChanged: (value) => _queueAiField('apiKey', value),
              onSubmitted: (value) => notifier.updateConfig(
                (c) => c.copyWith(aiApiKey: value),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.settingsAiSecurityHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _testAiConfiguration(AppLocalizations l10n) async {
    setState(() => _testingAi = true);
    try {
      final config = ref.read(settingsProvider);
      await AiConnectionService.testConnection(config);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsAiTestSuccess)),
      );
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('AI configuration test failed'),
          content: SingleChildScrollView(
            child: SelectableText('$error'),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: '$error'));
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy error'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _testingAi = false);
    }
  }

  // -- Editor --
  Widget _editorSection(AppLocalizations l10n) {
    final config = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsEditor,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        _row(
          '${l10n.settingsFontSize}: ${config.fontSize.toInt()}',
          SizedBox(
            width: 300,
            child: Slider(
              value: config.fontSize,
              min: 12, max: 32, divisions: 20,
              label: config.fontSize.toInt().toString(),
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setFontSize(v),
            ),
          ),
        ),
        _row(
          '${l10n.settingsLineHeight}: ${config.lineHeight.toStringAsFixed(1)}',
          SizedBox(
            width: 300,
            child: Slider(
              value: config.lineHeight,
              min: 1.2, max: 2.0, divisions: 8,
              label: config.lineHeight.toStringAsFixed(1),
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .updateConfig((c) => c.copyWith(lineHeight: v)),
            ),
          ),
        ),
        _row(
          l10n.settingsTabSize,
          SizedBox(
            width: 220,
            child: DropdownButton<int>(
              isExpanded: true,
                value: config.tabSize,
                items: const [
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 4, child: Text('4')),
                  DropdownMenuItem(value: 8, child: Text('8')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateConfig((c) => c.copyWith(tabSize: v));
                  }
                },
              ),
          ),
        ),
        _row(
          // The editor's body font was applied all along but had nowhere to be
          // chosen: only the code font had a row, so the setting sat at
          // 'monospace' whatever anyone wanted.
          l10n.settingsEditorFontFamily,
          SizedBox(
            width: 200,
            child: TextField(
              controller: _field('fontFamily', config.fontFamily),
              onSubmitted: (v) {
                ref.read(settingsProvider.notifier).updateConfig(
                      (c) => c.copyWith(
                        fontFamily: v.isEmpty ? 'monospace' : v,
                      ),
                    );
              },
            ),
          ),
        ),
        _row(
          l10n.settingsCodeFontFamily,
          SizedBox(
            width: 200,
            child: TextField(
              controller: _field('codeFontFamily', config.codeFontFamily),
              onSubmitted: (v) {
                ref.read(settingsProvider.notifier)
                    .updateConfig((c) => c.copyWith(codeFontFamily: v.isEmpty ? 'Courier New' : v));
              },
            ),
          ),
        ),
        _row(
          l10n.settingsCodeFontSize,
          SizedBox(
            width: 120,
            child: TextField(
              controller: _field(
                'codeFontSize',
                config.codeFontSize.toStringAsFixed(0),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (v) {
                final size = double.tryParse(v);
                if (size == null) return;
                ref.read(settingsProvider.notifier).updateConfig(
                      // Clamped: a zero or a stray 400 from the keyboard makes
                      // the document unreadable with no obvious way back.
                      (c) => c.copyWith(codeFontSize: size.clamp(8.0, 48.0)),
                    );
              },
            ),
          ),
        ),
        _row(
          l10n.settingsEditorMaxWidth,
          SizedBox(
            width: 120,
            child: TextField(
              controller:
                  _field('editorMaxWidth', config.editorMaxWidth.toString()),
              keyboardType: TextInputType.number,
              onSubmitted: (v) {
                final w = int.tryParse(v) ?? 800;
                ref.read(settingsProvider.notifier)
                    .updateConfig((c) => c.copyWith(editorMaxWidth: w));
              },
            ),
          ),
        ),
        _row(
          l10n.settingsImageStorage,
          SizedBox(
            width: 220,
            child: DropdownButton<String>(
              isExpanded: true,
                value: const {'copy', 'folder', 'link'}.contains(config.imageStorageMode)
                    ? config.imageStorageMode
                    : 'copy',
                items: [
                  DropdownMenuItem(
                      value: 'copy', child: Text(l10n.settingsImageStorageCopy)),
                  DropdownMenuItem(
                      value: 'folder', child: Text(l10n.settingsImageStorageFolder)),
                  DropdownMenuItem(
                      value: 'link', child: Text(l10n.settingsImageStorageLink)),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  ref
                      .read(settingsProvider.notifier)
                      .updateConfig((c) => c.copyWith(imageStorageMode: v));
                },
              ),
          ),
        ),
        // Only the shared-folder option has a folder to configure.
        if (config.imageStorageMode == 'folder')
          _row(
            l10n.settingsImageFolder,
            SizedBox(
              width: 200,
              child: TextField(
                controller: _field('imageFolder', config.imageFolder),
                onSubmitted: (v) {
                  final folder = v.trim();
                  ref.read(settingsProvider.notifier).updateConfig(
                        (c) => c.copyWith(
                          imageFolder:
                              folder.isEmpty ? ImageService.defaultFolder : folder,
                        ),
                      );
                },
              ),
            ),
          ),
        _row(
          l10n.settingsTextDirection,
          SizedBox(
            width: 220,
            child: DropdownButton<String>(
              isExpanded: true,
                value: config.textDirection,
                items: [
                  DropdownMenuItem(value: 'ltr', child: Text(l10n.settingsTextDirectionLtr)),
                  DropdownMenuItem(value: 'rtl', child: Text(l10n.settingsTextDirectionRtl)),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref.read(settingsProvider.notifier)
                        .updateConfig((c) => c.copyWith(textDirection: v));
                  }
                },
              ),
          ),
        ),
      ],
    );
  }

  // -- Markdown --
  Widget _markdownSection(AppLocalizations l10n) {
    final config = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsMarkdown,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        _row(
          l10n.settingsBulletListMarker,
          SizedBox(
            width: 220,
            child: DropdownButton<String>(
              isExpanded: true,
                value: config.bulletListMarker,
                items: const [
                  DropdownMenuItem(value: '-', child: Text('-')),
                  DropdownMenuItem(value: '*', child: Text('*')),
                  DropdownMenuItem(value: '+', child: Text('+')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateConfig((c) => c.copyWith(bulletListMarker: v));
                  }
                },
              ),
          ),
        ),
        _row(
          l10n.settingsEnableHtml,
          Switch(
            value: config.enableHtml,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .updateConfig((c) => c.copyWith(enableHtml: v)),
          ),
        ),
        _row(
          l10n.settingsWrapCodeBlocks,
          Switch(
            value: config.wrapCodeBlocks,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .updateConfig((c) => c.copyWith(wrapCodeBlocks: v)),
          ),
        ),
        _row(
          l10n.settingsCodeBlockLineNumbers,
          Switch(
            value: config.codeBlockLineNumbers,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .updateConfig((c) => c.copyWith(codeBlockLineNumbers: v)),
          ),
        ),
        _row(
          l10n.settingsAutoPairBracket,
          Switch(
            value: config.autoPairBracket,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .updateConfig((c) => c.copyWith(autoPairBracket: v)),
          ),
        ),
        _row(
          l10n.settingsAutoPairQuote,
          Switch(
            value: config.autoPairQuote,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .updateConfig((c) => c.copyWith(autoPairQuote: v)),
          ),
        ),
        _row(
          l10n.settingsAutoPairMarkdown,
          Switch(
            value: config.autoPairMarkdownSyntax,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .updateConfig((c) => c.copyWith(autoPairMarkdownSyntax: v)),
          ),
        ),
      ],
    );
  }

  // -- Theme --
  String _translateThemeName(String name, AppLocalizations l10n) {
    return switch (name) {
      'redGraphite' => l10n.themeRedGraphite,
      'shibuya' => l10n.themeShibuya,
      'pinkBlossom' => l10n.themePinkBlossom,
      'skyBlue' => l10n.themeSkyBlue,
      'darkGraphite' => l10n.themeDarkGraphite,
      'dieciOLED' => l10n.themeDieciOLED,
      'nord' => l10n.themeNord,
      'midnight' => l10n.themeMidnight,
      _ => name,
    };
  }

  Widget _themeSection(AppLocalizations l10n) {
    final config = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsTheme,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _row(
          l10n.settingsFollowSystemTheme,
          Switch(
            value: config.followSystemTheme,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .updateConfig((c) => c.copyWith(followSystemTheme: v)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          config.followSystemTheme
              ? l10n.settingsFollowSystemThemeHint
              : '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Text(l10n.settingsLightThemes,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AppTheme.lightThemeNames.map((name) {
            return _buildThemeCard(name, config, l10n, isDarkGroup: false);
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(l10n.settingsDarkThemes,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AppTheme.darkThemeNames.map((name) {
            return _buildThemeCard(name, config, l10n, isDarkGroup: true);
          }).toList(),
        ),
      ],
    );
  }

  /// One theme card.
  ///
  /// [isDarkGroup] says which of the two lists it came from. While the theme
  /// follows the system, a card no longer sets *the* theme: the light cards
  /// choose what is used when the system is light and the dark cards what is
  /// used when it is dark, so which card looks selected has to follow the same
  /// rule. Getting that wrong would show a tick next to a theme that is not in
  /// use.
  Widget _buildThemeCard(
    String name,
    AppConfig config,
    AppLocalizations l10n, {
    required bool isDarkGroup,
  }) {
    final tokens = AppTheme.getTokens(name);
    final selected = config.followSystemTheme
        ? (isDarkGroup ? config.darkModeTheme : config.lightModeTheme) == name
        : config.themeName == name;
    return InkWell(
      onTap: () {
        final notifier = ref.read(settingsProvider.notifier);
        if (!config.followSystemTheme) {
          notifier.setTheme(name);
        } else if (isDarkGroup) {
          notifier.updateConfig((c) => c.copyWith(darkModeTheme: name));
        } else {
          notifier.updateConfig((c) => c.copyWith(lightModeTheme: name));
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 140, height: 90,
        decoration: BoxDecoration(
          color: tokens.colorSurface,
          border: Border.all(
            color: selected ? tokens.colorAccent : tokens.colorBorder,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: tokens.colorAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Text(_translateThemeName(name, l10n),
                style: TextStyle(color: tokens.colorText, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // -- Keybindings --
  String _translateKeybindingAction(String action, AppLocalizations l10n) {
    return switch (action) {
      'bold' => l10n.keybindingBold,
      'italic' => l10n.keybindingItalic,
      'underline' => l10n.keybindingUnderline,
      'strikethrough' => l10n.keybindingStrikethrough,
      'heading1' => l10n.keybindingHeading1,
      'heading2' => l10n.keybindingHeading2,
      'heading3' => l10n.keybindingHeading3,
      'heading4' => l10n.keybindingHeading4,
      'heading5' => l10n.keybindingHeading5,
      'heading6' => l10n.keybindingHeading6,
      'orderedList' => l10n.keybindingOrderedList,
      'unorderedList' => l10n.keybindingUnorderedList,
      'taskList' => l10n.keybindingTaskList,
      'codeBlock' => l10n.keybindingCodeBlock,
      'quoteBlock' => l10n.keybindingQuoteBlock,
      'table' => l10n.keybindingTable,
      'link' => l10n.keybindingLink,
      'image' => l10n.keybindingImage,
      'inlineCode' => l10n.keybindingInlineCode,
      'inlineMath' => l10n.keybindingInlineMath,
      'mathBlock' => l10n.keybindingMathBlock,
      'find' => l10n.keybindingFind,
      'replace' => l10n.keybindingReplace,
      'save' => l10n.keybindingSave,
      'open' => l10n.keybindingOpen,
      'undo' => l10n.keybindingUndo,
      'redo' => l10n.keybindingRedo,
      'selectAll' => l10n.keybindingSelectAll,
      'duplicateLine' => l10n.keybindingDuplicateLine,
      'highlight' => l10n.keybindingHighlight,
      'closeTab' => l10n.fileCloseTab,
      'findNext' => l10n.editFindNext,
      'findPrevious' => l10n.editFindPrevious,
      // These two had been in the map since it gained promote and demote
      // heading, but never here, so the settings list showed their raw action
      // names next to every other row's translated one.
      'promoteHeading' => l10n.paragraphPromoteHeading,
      'demoteHeading' => l10n.paragraphDemoteHeading,
      // The twenty-four that used to be hard-coded on their menu items or had
      // no shortcut at all. They reuse the menu's own labels, so the settings
      // list names them the same way the menu does.
      'sourceMode' => l10n.viewSourceCode,
      'previewMode' => l10n.viewPreview,
      'splitMode' => l10n.viewSplitView,
      'toggleSidebar' => l10n.viewHideSidebar,
      'toggleTabBar' => l10n.viewHideTabBar,
      'commandPalette' => l10n.viewCommandPalette,
      'focusMode' => l10n.viewFocusMode,
      'typewriterMode' => l10n.viewTypewriterMode,
      'zoomIn' => l10n.viewZoomIn,
      'zoomOut' => l10n.viewZoomOut,
      'resetZoom' => l10n.viewResetZoom,
      'newWindow' => l10n.fileNewWindow,
      'settings' => l10n.fileSettings,
      'quit' => l10n.fileQuit,
      'print' => l10n.filePrint,
      'exportPdf' => l10n.fileExportPdf,
      'reloadImages' => l10n.viewReloadImages,
      'fullScreen' => l10n.windowFullScreen,
      'clearFormatting' => l10n.formatClearFormatting,
      'createParagraph' => l10n.editCreateParagraph,
      'deleteParagraph' => l10n.editDeleteParagraph,
      'toParagraph' => l10n.paragraphToParagraph,
      'looseList' => l10n.paragraphLooseList,
      'moveBlockUp' => l10n.paragraphMoveBlockUp,
      'moveBlockDown' => l10n.paragraphMoveBlockDown,
      'frontMatter' => l10n.formatFrontMatter,
      'htmlBlock' => l10n.formatHtmlBlock,
      _ => action,
    };
  }

  Widget _keybindingsSection(AppLocalizations l10n) {
    final service = KeybindingService();
    final bindings = service.keybindings;

    final entries = bindings.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsKeybindings,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  // Same as _row: the action's name is the only part that can
                  // give way, so it is the part that does. Fifty-nine of
                  // these rows overflowed together as soon as the window was
                  // narrower than about a thousand pixels.
                  Expanded(
                    child: Text(
                      _translateKeybindingAction(entry.key, l10n),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(entry.value, style: const TextStyle(fontFamily: 'monospace')),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        tooltip: l10n.keybindingsEdit,
                        onPressed: () => _showKeybindingDialog(entry.key, entry.value, l10n),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () {
              service.resetToDefaults();
              setState(() {});
            },
            icon: const Icon(Icons.restore),
            label: Text(l10n.keybindingsReset),
          ),
        ),
      ],
    );
  }

  void _showKeybindingDialog(String action, String currentKeys, AppLocalizations l10n) {
    String captured = '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Recomputed as keys are captured, so the warning follows what is
          // on screen rather than what was there when the dialog opened.
          final conflict = captured.isEmpty
              ? null
              : KeybindingService().actionUsing(captured, excluding: action);
          return AlertDialog(
          title: Text('${l10n.keybindingsEdit}: ${_translateKeybindingAction(action, l10n)}'),
          content: KeyboardListener(
            focusNode: FocusNode()..requestFocus(),
            onKeyEvent: (event) {
              if (event is KeyDownEvent) {
                final parts = <String>[];
                if (HardwareKeyboard.instance.isControlPressed) parts.add('Ctrl');
                if (HardwareKeyboard.instance.isShiftPressed) parts.add('Shift');
                if (HardwareKeyboard.instance.isAltPressed) parts.add('Alt');
                if (HardwareKeyboard.instance.isMetaPressed) parts.add('Meta');
                final key = event.logicalKey.keyLabel;
                if (!['Control Left', 'Control Right', 'Shift Left', 'Shift Right',
                      'Alt Left', 'Alt Right', 'Meta Left', 'Meta Right'].contains(key)) {
                  parts.add(key);
                }
                if (parts.isNotEmpty) {
                  setDialogState(() => captured = parts.join('+'));
                }
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  captured.isEmpty ? l10n.keybindingsPressKeys : captured,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'monospace',
                    color: captured.isEmpty
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                        : null,
                  ),
                ),
              ),
            ),
                // Said before the button is pressed, not discovered afterwards
                // by finding that a command stopped working. Two actions on
                // one combination is invisible: the lookup takes whichever
                // comes first and the other simply never fires.
                if (conflict != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.keybindingsConflict(
                            _translateKeybindingAction(conflict, l10n),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: captured.isEmpty ? null : () {
                KeybindingService().setKeybinding(action, captured);
                Navigator.pop(ctx);
                setState(() {});
              },
              // The button names what pressing it does: taking a shortcut off
              // another command is a different act from assigning a free one.
              child: Text(conflict == null
                  ? l10n.ok
                  : l10n.keybindingsTakeOver),
            ),
          ],
        );
        },
      ),
    );
  }

  // -- Helpers --
  /// Below this much room a row stacks instead of sitting side by side.
  static const _stackRowsBelow = 420.0;

  Widget _row(String label, Widget control) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      // Side by side while there is room, stacked when there is not.
      //
      // A dropdown is as wide as its longest option and a field has a width
      // it needs to be usable; only the label can give way. Laid out with
      // neither able to, the page overflowed to the right as soon as the
      // window was narrower than about 1000 pixels — striped, not scrollable,
      // and worse in every language whose words run longer than English's.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final label0 = Text(label, style: const TextStyle(fontSize: 16));
          if (constraints.maxWidth < _stackRowsBelow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label0,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: control),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: label0),
              const SizedBox(width: 16),
              control,
            ],
          );
        },
      ),
    );
  }

  Widget _resetButton(AppLocalizations l10n) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.settingsResetDefaults),
              content: Text(l10n.confirmResetMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.ok),
                ),
              ],
            ),
          );
          if (ok == true && mounted) {
            await ref.read(settingsProvider.notifier).resetDefaults();
          }
        },
        icon: const Icon(Icons.restore),
        label: Text(l10n.settingsResetDefaults),
      ),
    );
  }
}
