import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme/app_theme.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fileSettings)),
      body: Row(
        children: [
          SizedBox(
            width: 200,
            child: ListView(
              children: [
                _catTile(_Category.general, l10n.settingsGeneral, Icons.settings),
                _catTile(_Category.editor, l10n.settingsEditor, Icons.edit),
                _catTile(_Category.markdown, l10n.settingsMarkdown, Icons.code),
                _catTile(_Category.theme, l10n.settingsTheme, Icons.palette),
                _catTile(_Category.keybindings, l10n.settingsKeybindings, Icons.keyboard),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
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

  Widget _catTile(_Category cat, String label, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: _selected == cat,
      onTap: () => setState(() => _selected = cat),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settingsKeybindings,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            Text(l10n.comingSoon),
          ],
        );
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
  Widget _themeSection(AppLocalizations l10n) {
    final config = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsTheme,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        _row(
          l10n.settingsDarkMode,
          Switch(
            value: config.darkMode,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .updateConfig((c) => c.copyWith(darkMode: v)),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AppTheme.themeNames.map((name) {
            final theme = AppTheme.getTheme(name);
            final selected = config.themeName == name;
            return InkWell(
              onTap: () => ref.read(settingsProvider.notifier).setTheme(name),
              child: Container(
                width: 150, height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(
                    color: selected ? theme.colorScheme.primary : Colors.grey,
                    width: selected ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(name,
                        style: TextStyle(color: theme.colorScheme.onSurface)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
