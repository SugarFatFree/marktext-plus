import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/keybinding_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(settingsProvider);
    final tokens = AppTheme.getTokens(config.themeName);

    final categories = [
      (Icons.settings, l10n.settingsGeneral, const _GeneralPage()),
      (Icons.edit, l10n.settingsEditor, const _EditorPage()),
      (Icons.palette, l10n.settingsTheme, const _ThemePage()),
      (Icons.keyboard, l10n.settingsKeybindings, const _KeybindingsPage()),
      (Icons.code, l10n.settingsMarkdown, const _MarkdownPage()),
    ];

    return Scaffold(
      backgroundColor: tokens.colorBg,
      appBar: AppBar(
        title: Text(l10n.fileSettings),
        backgroundColor: tokens.colorSurface,
        foregroundColor: tokens.colorText,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: categories
              .map((c) => _CategoryCard(
                    icon: c.$1,
                    title: c.$2,
                    tokens: tokens,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => c.$3),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ── Card widget ──────────────────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final AppThemeTokens tokens;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.tokens,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.tokens.colorSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.tokens.colorBorder),
            boxShadow: _hovered
                ? [BoxShadow(color: widget.tokens.colorBorder, blurRadius: 8, offset: const Offset(0, 4))]
                : [],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 28, color: widget.tokens.colorAccent),
              const SizedBox(height: 10),
              Text(widget.title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: widget.tokens.colorText)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared scaffold for detail pages ─────────────────────────────────────────

class _DetailScaffold extends ConsumerWidget {
  final String title;
  final List<Widget> children;

  const _DetailScaffold({required this.title, required this.children});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTheme.getTokens(ref.watch(settingsProvider).themeName);
    return Scaffold(
      backgroundColor: tokens.colorBg,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: tokens.colorSurface,
        foregroundColor: tokens.colorText,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [...children, const SizedBox(height: 32), const _ResetButton()],
      ),
    );
  }
}

// ── Setting row ───────────────────────────────────────────────────────────────

class _Row extends ConsumerWidget {
  final String label;
  final Widget control;

  const _Row(this.label, this.control);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTheme.getTokens(ref.watch(settingsProvider).themeName);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: tokens.colorText)),
          control,
        ],
      ),
    );
  }
}

// ── Reset button ──────────────────────────────────────────────────────────────

class _ResetButton extends ConsumerWidget {
  const _ResetButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = AppTheme.getTokens(ref.watch(settingsProvider).themeName);
    return Center(
      child: ElevatedButton.icon(
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.settingsResetDefaults),
              content: Text(l10n.confirmResetMessage),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.ok)),
              ],
            ),
          );
          if (ok == true && context.mounted) {
            await ref.read(settingsProvider.notifier).resetDefaults();
          }
        },
        icon: const Icon(Icons.restore),
        label: Text(l10n.settingsResetDefaults),
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.colorSurface,
          foregroundColor: tokens.colorText,
        ),
      ),
    );
  }
}

// ── General ───────────────────────────────────────────────────────────────────

class _GeneralPage extends ConsumerWidget {
  const _GeneralPage();

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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(settingsProvider);
    final locale = ref.watch(localeProvider);
    final localeKey = locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;

    return _DetailScaffold(
      title: l10n.settingsGeneral,
      children: [
        _Row(
          l10n.settingsLanguage,
          DropdownButton<String>(
            value: _localeMap.containsKey(localeKey) ? localeKey : 'en_US',
            items: _localeMap.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              ref.read(localeProvider.notifier).setLocale(LocaleNotifier.parseLocale(v));
              ref.read(settingsProvider.notifier).setLocale(v);
            },
          ),
        ),
        _Row(
          l10n.settingsAutoSave,
          Switch(
            value: config.autoSave,
            onChanged: (v) => ref.read(settingsProvider.notifier).updateConfig((c) => c.copyWith(autoSave: v)),
          ),
        ),
        _Row(
          l10n.settingsAutoSaveDelay,
          DropdownButton<int>(
            value: config.autoSaveDelay,
            items: [1000, 2000, 3000, 5000]
                .map((ms) => DropdownMenuItem(value: ms, child: Text('${ms}ms')))
                .toList(),
            onChanged: (v) {
              if (v != null) ref.read(settingsProvider.notifier).updateConfig((c) => c.copyWith(autoSaveDelay: v));
            },
          ),
        ),
      ],
    );
  }
}

// ── Editor ────────────────────────────────────────────────────────────────────

class _EditorPage extends ConsumerWidget {
  const _EditorPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(settingsProvider);

    return _DetailScaffold(
      title: l10n.settingsEditor,
      children: [
        _Row(
          '${l10n.settingsFontSize}: ${config.fontSize.toInt()}',
          SizedBox(
            width: 240,
            child: Slider(
              value: config.fontSize,
              min: 12, max: 32, divisions: 20,
              label: config.fontSize.toInt().toString(),
              onChanged: (v) => ref.read(settingsProvider.notifier).setFontSize(v),
            ),
          ),
        ),
        _Row(
          '${l10n.settingsLineHeight}: ${config.lineHeight.toStringAsFixed(1)}',
          SizedBox(
            width: 240,
            child: Slider(
              value: config.lineHeight,
              min: 1.2, max: 2.0, divisions: 8,
              label: config.lineHeight.toStringAsFixed(1),
              onChanged: (v) => ref.read(settingsProvider.notifier).updateConfig((c) => c.copyWith(lineHeight: v)),
            ),
          ),
        ),
        _Row(
          l10n.settingsTabSize,
          DropdownButton<int>(
            value: config.tabSize,
            items: [2, 4, 8].map((s) => DropdownMenuItem(value: s, child: Text('$s'))).toList(),
            onChanged: (v) {
              if (v != null) ref.read(settingsProvider.notifier).updateConfig((c) => c.copyWith(tabSize: v));
            },
          ),
        ),
        _Row(
          l10n.settingsCodeFontFamily,
          SizedBox(
            width: 180,
            child: TextField(
              controller: TextEditingController(text: config.codeFontFamily),
              onSubmitted: (v) => ref.read(settingsProvider.notifier)
                  .updateConfig((c) => c.copyWith(codeFontFamily: v.isEmpty ? 'Courier New' : v)),
            ),
          ),
        ),
        _Row(
          l10n.settingsEditorMaxWidth,
          SizedBox(
            width: 100,
            child: TextField(
              controller: TextEditingController(text: config.editorMaxWidth.toString()),
              keyboardType: TextInputType.number,
              onSubmitted: (v) {
                final w = int.tryParse(v) ?? 800;
                ref.read(settingsProvider.notifier).updateConfig((c) => c.copyWith(editorMaxWidth: w));
              },
            ),
          ),
        ),
        _Row(
          l10n.settingsTextDirection,
          DropdownButton<String>(
            value: config.textDirection,
            items: const [
              DropdownMenuItem(value: 'ltr', child: Text('LTR')),
              DropdownMenuItem(value: 'rtl', child: Text('RTL')),
            ],
            onChanged: (v) {
              if (v != null) ref.read(settingsProvider.notifier).updateConfig((c) => c.copyWith(textDirection: v));
            },
          ),
        ),
      ],
    );
  }
}

// ── Theme ─────────────────────────────────────────────────────────────────────

class _ThemePage extends ConsumerWidget {
  const _ThemePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(settingsProvider);

    return _DetailScaffold(
      title: l10n.settingsTheme,
      children: [
        _Row(
          l10n.settingsDarkMode,
          Switch(
            value: config.darkMode,
            onChanged: (v) => ref.read(settingsProvider.notifier).updateConfig((c) => c.copyWith(darkMode: v)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: AppTheme.themeNames.map((name) {
              final theme = AppTheme.getTheme(name);
              final tokens = AppTheme.getTokens(name);
              final selected = config.themeName == name;
              return GestureDetector(
                onTap: () => ref.read(settingsProvider.notifier).setTheme(name),
                child: Container(
                  width: 140, height: 90,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? tokens.colorAccent : tokens.colorBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: tokens.colorAccent, shape: BoxShape.circle),
                      ),
                      const SizedBox(height: 8),
                      Text(name, style: TextStyle(color: tokens.colorText, fontSize: 13)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Keybindings ───────────────────────────────────────────────────────────────

class _KeybindingsPage extends ConsumerStatefulWidget {
  const _KeybindingsPage();

  @override
  ConsumerState<_KeybindingsPage> createState() => _KeybindingsPageState();
}

class _KeybindingsPageState extends ConsumerState<_KeybindingsPage> {
  String? _editingAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(settingsProvider);
    final tokens = AppTheme.getTokens(config.themeName);
    final service = KeybindingService();
    final bindings = service.keybindings;

    return Scaffold(
      backgroundColor: tokens.colorBg,
      appBar: AppBar(
        title: Text(l10n.settingsKeybindings),
        backgroundColor: tokens.colorSurface,
        foregroundColor: tokens.colorText,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ...bindings.entries.map((entry) {
            final action = entry.key;
            final binding = entry.value;
            final isEditing = _editingAction == action;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(_translateAction(action, l10n),
                        style: TextStyle(fontSize: 14, color: tokens.colorText)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: isEditing
                        ? Focus(
                            autofocus: true,
                            onKeyEvent: (node, event) {
                              if (event is! KeyDownEvent) return KeyEventResult.ignored;
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
                              if (parts.length >= 2) {
                                service.setKeybinding(action, parts.join('+'));
                                setState(() => _editingAction = null);
                              }
                              return KeyEventResult.handled;
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: tokens.colorSurfaceHover,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: tokens.colorAccent),
                              ),
                              child: Text(l10n.keybindingsPressKeys,
                                  style: TextStyle(fontSize: 13, color: tokens.colorTextMuted)),
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: tokens.colorSurface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: tokens.colorBorder),
                                  ),
                                  child: Text(binding,
                                      style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: tokens.colorText)),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, size: 16, color: tokens.colorTextMuted),
                                tooltip: l10n.keybindingsEdit,
                                onPressed: () => setState(() => _editingAction = action),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          }),
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
      ),
    );
  }

  String _translateAction(String action, AppLocalizations l10n) {
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
}

// ── Markdown ──────────────────────────────────────────────────────────────────

class _MarkdownPage extends ConsumerWidget {
  const _MarkdownPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(settingsProvider);

    return _DetailScaffold(
      title: l10n.settingsMarkdown,
      children: [
        _Row(
          l10n.settingsBulletListMarker,
          DropdownButton<String>(
            value: config.bulletListMarker,
            items: const [
              DropdownMenuItem(value: '-', child: Text('-')),
              DropdownMenuItem(value: '*', child: Text('*')),
              DropdownMenuItem(value: '+', child: Text('+')),
            ],
            onChanged: (v) {
              if (v != null) ref.read(settingsProvider.notifier).updateConfig((c) => c.copyWith(bulletListMarker: v));
            },
          ),
        ),
        _Row(
          l10n.settingsEnableHtml,
          Switch(
            value: config.enableHtml,
            onChanged: (v) => ref.read(settingsProvider.notifier).updateConfig((c) => c.copyWith(enableHtml: v)),
          ),
        ),
      ],
    );
  }
}
