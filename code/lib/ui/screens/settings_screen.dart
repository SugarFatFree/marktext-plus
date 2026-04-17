import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../services/keybinding_service.dart';

enum _Category { general, editor, markdown, theme, keybindings }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  _Category _selected = _Category.general;

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
    }
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
          DropdownButton<String>(
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
              controller: TextEditingController(
                  text: config.autoSaveDelay.toString()),
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
      ],
    );
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
          DropdownButton<int>(
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
        _row(
          l10n.settingsCodeFontFamily,
          SizedBox(
            width: 200,
            child: TextField(
              controller: TextEditingController(text: config.codeFontFamily),
              onSubmitted: (v) {
                ref.read(settingsProvider.notifier)
                    .updateConfig((c) => c.copyWith(codeFontFamily: v.isEmpty ? 'Courier New' : v));
              },
            ),
          ),
        ),
        _row(
          l10n.settingsEditorMaxWidth,
          SizedBox(
            width: 120,
            child: TextField(
              controller: TextEditingController(text: config.editorMaxWidth.toString()),
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
          l10n.settingsTextDirection,
          DropdownButton<String>(
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
          DropdownButton<String>(
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
        _row(
          l10n.settingsEnableHtml,
          Switch(
            value: config.enableHtml,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .updateConfig((c) => c.copyWith(enableHtml: v)),
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
        const SizedBox(height: 24),
        Text(l10n.settingsLightThemes,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AppTheme.lightThemeNames.map((name) {
            return _buildThemeCard(name, config, l10n);
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
            return _buildThemeCard(name, config, l10n);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildThemeCard(String name, AppConfig config, AppLocalizations l10n) {
    final tokens = AppTheme.getTokens(name);
    final selected = config.themeName == name;
    return InkWell(
      onTap: () => ref.read(settingsProvider.notifier).setTheme(name),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_translateKeybindingAction(entry.key, l10n), style: const TextStyle(fontSize: 16)),
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
        builder: (ctx, setDialogState) => AlertDialog(
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
            child: Container(
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
              child: Text(l10n.ok),
            ),
          ],
        ),
      ),
    );
  }

  // -- Helpers --
  Widget _row(String label, Widget control) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          control,
        ],
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
