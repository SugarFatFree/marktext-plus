import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../app.dart';
import '../../core/config/app_config.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tab_info.dart';
import '../../providers/editor_provider.dart';
import '../../providers/file_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_provider.dart';
import '../../services/export_service.dart';
import '../../services/keybinding_service.dart';
import '../../utils/platform_utils.dart';
import '../screens/settings_screen.dart';

class AppMenuBar extends ConsumerWidget {
  const AppMenuBar({super.key});

  static SingleActivator? _parseShortcut(String keys) {
    final parts = keys.split('+');
    if (parts.isEmpty) return null;
    bool ctrl = false, shift = false, alt = false, meta = false;
    String? keyLabel;
    for (final part in parts) {
      switch (part.trim()) {
        case 'Ctrl':
          if (PlatformUtils.isMacOS) { meta = true; } else { ctrl = true; }
        case 'Shift':
          shift = true;
        case 'Alt':
          alt = true;
        case 'Meta':
          meta = true;
        default:
          keyLabel = part.trim();
      }
    }
    if (keyLabel == null) return null;
    final logicalKey = _labelToKey(keyLabel);
    if (logicalKey == null) return null;
    return SingleActivator(logicalKey, control: ctrl, shift: shift, alt: alt, meta: meta);
  }

  static LogicalKeyboardKey? _labelToKey(String label) {
    return switch (label) {
      'A' => LogicalKeyboardKey.keyA,
      'B' => LogicalKeyboardKey.keyB,
      'C' => LogicalKeyboardKey.keyC,
      'D' => LogicalKeyboardKey.keyD,
      'E' => LogicalKeyboardKey.keyE,
      'F' => LogicalKeyboardKey.keyF,
      'G' => LogicalKeyboardKey.keyG,
      'H' => LogicalKeyboardKey.keyH,
      'I' => LogicalKeyboardKey.keyI,
      'J' => LogicalKeyboardKey.keyJ,
      'K' => LogicalKeyboardKey.keyK,
      'L' => LogicalKeyboardKey.keyL,
      'M' => LogicalKeyboardKey.keyM,
      'N' => LogicalKeyboardKey.keyN,
      'O' => LogicalKeyboardKey.keyO,
      'P' => LogicalKeyboardKey.keyP,
      'Q' => LogicalKeyboardKey.keyQ,
      'R' => LogicalKeyboardKey.keyR,
      'S' => LogicalKeyboardKey.keyS,
      'T' => LogicalKeyboardKey.keyT,
      'U' => LogicalKeyboardKey.keyU,
      'V' => LogicalKeyboardKey.keyV,
      'W' => LogicalKeyboardKey.keyW,
      'X' => LogicalKeyboardKey.keyX,
      'Y' => LogicalKeyboardKey.keyY,
      'Z' => LogicalKeyboardKey.keyZ,
      '1' => LogicalKeyboardKey.digit1,
      '2' => LogicalKeyboardKey.digit2,
      '3' => LogicalKeyboardKey.digit3,
      '4' => LogicalKeyboardKey.digit4,
      '5' => LogicalKeyboardKey.digit5,
      '6' => LogicalKeyboardKey.digit6,
      '`' => LogicalKeyboardKey.backquote,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = AppTheme.getTokens(ref.watch(settingsProvider).themeName);
    return Container(
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        border: Border(
          bottom: BorderSide(color: tokens.colorBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.colorBorder.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: MenuBar(
            style: MenuStyle(
              backgroundColor: WidgetStatePropertyAll(tokens.colorSurface),
              elevation: const WidgetStatePropertyAll(0),
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            ),
            children: [
              _buildFileMenu(l10n, ref),
              _buildEditMenu(l10n, ref),
              _buildViewMenu(l10n, ref),
              _buildFormatMenu(l10n, ref),
              _buildWindowMenu(l10n, ref),
              _buildHelpMenu(l10n, ref),
            ],
          ),
        ),
      ),
    );
  }

  void _newFile(WidgetRef ref) {
    final tab = TabInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    ref.read(tabProvider.notifier).addTab(tab);
  }

  void _openFile(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final content = await File(path).readAsString();
    final tab = TabInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filePath: path,
      fileName: p.basename(path),
      content: content,
    );
    ref.read(tabProvider.notifier).addTab(tab);
    ref.read(settingsProvider.notifier).addRecentFile(path);
  }

  void _openFolder(WidgetRef ref) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;
    ref.read(fileProvider.notifier).loadDirectory(result);
  }

  void _saveFile(WidgetRef ref) async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) return;
    if (activeTab.filePath != null) {
      await File(activeTab.filePath!).writeAsString(activeTab.content);
      ref.read(tabProvider.notifier).markSaved(activeTab.id);
    } else {
      _saveFileAs(ref);
    }
  }

  void _saveFileAs(WidgetRef ref) async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) return;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save As',
      fileName: activeTab.fileName,
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown', 'txt'],
    );
    if (path == null) return;
    await File(path).writeAsString(activeTab.content);
    ref.read(tabProvider.notifier).markSaved(activeTab.id);
  }

  void _renameFile(WidgetRef ref) async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null || activeTab.filePath == null) return;
    final oldPath = activeTab.filePath!;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final l10n = AppLocalizations.of(ctx)!;
    final controller = TextEditingController(text: p.basename(oldPath));
    final newName = await showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.fileRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.newNameHintDialog),
          onSubmitted: (value) => Navigator.of(dialogCtx).pop(value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(controller.text), child: Text(l10n.ok)),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == p.basename(oldPath)) return;
    final newPath = p.join(p.dirname(oldPath), newName);
    await File(oldPath).rename(newPath);
    ref.read(tabProvider.notifier).updateTabPath(activeTab.id, newPath, newName);
  }

  Widget _buildFileMenu(AppLocalizations l10n, WidgetRef ref) {
    return SubmenuButton(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.insert_drive_file),
          child: Text(l10n.fileNew),
          onPressed: () => _newFile(ref),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.window),
          child: Text(l10n.fileNewWindow),
          onPressed: () => _newWindow(),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.folder_open),
          onPressed: () => _openFile(ref),
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyO,
            control: !PlatformUtils.isMacOS,
            meta: PlatformUtils.isMacOS,
          ),
          child: Text(l10n.fileOpen),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.folder),
          child: Text(l10n.fileOpenFolder),
          onPressed: () => _openFolder(ref),
        ),
        _buildRecentFilesMenu(l10n, ref),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.save),
          onPressed: () => _saveFile(ref),
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyS,
            control: !PlatformUtils.isMacOS,
            meta: PlatformUtils.isMacOS,
          ),
          child: Text(l10n.fileSave),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.save_as),
          child: Text(l10n.fileSaveAs),
          onPressed: () => _saveFileAs(ref),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.drive_file_rename_outline),
          child: Text(l10n.fileRename),
          onPressed: () => _renameFile(ref),
        ),
        const Divider(height: 1),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              child: Text(l10n.fileExportHtml),
              onPressed: () => _exportHtml(ref),
            ),
            MenuItemButton(
              child: Text(l10n.fileExportPdf),
              onPressed: () => _exportPdf(ref),
            ),
          ],
          child: Text(l10n.fileExport),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.settings),
          child: Text(l10n.fileSettings),
          onPressed: () {
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.exit_to_app),
          child: Text(l10n.fileQuit),
          onPressed: () => exit(0),
        ),
      ],
      child: Text(l10n.menuFile, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEditMenu(AppLocalizations l10n, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    return SubmenuButton(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.undo),
          onPressed: editorState.canUndo
              ? () => ref.read(editorProvider.notifier).undo()
              : null,
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyZ,
            control: !PlatformUtils.isMacOS,
            meta: PlatformUtils.isMacOS,
          ),
          child: Text(l10n.editUndo),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.redo),
          onPressed: editorState.canRedo
              ? () => ref.read(editorProvider.notifier).redo()
              : null,
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyZ,
            control: !PlatformUtils.isMacOS,
            meta: PlatformUtils.isMacOS,
            shift: true,
          ),
          child: Text(l10n.editRedo),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.content_cut),
          child: Text(l10n.editCut),
          onPressed: () {
            final controller = ref.read(editorProvider.notifier).controller;
            if (controller == null) return;
            final sel = controller.selection;
            if (!sel.isValid || sel.isCollapsed) return;
            final text = controller.text;
            final selected = text.substring(sel.start, sel.end);
            Clipboard.setData(ClipboardData(text: selected));
            controller.value = TextEditingValue(
              text: text.substring(0, sel.start) + text.substring(sel.end),
              selection: TextSelection.collapsed(offset: sel.start),
            );
          },
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.content_copy),
          child: Text(l10n.editCopy),
          onPressed: () {
            final controller = ref.read(editorProvider.notifier).controller;
            if (controller == null) return;
            final sel = controller.selection;
            if (!sel.isValid || sel.isCollapsed) return;
            final selected = controller.text.substring(sel.start, sel.end);
            Clipboard.setData(ClipboardData(text: selected));
          },
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.content_paste),
          child: Text(l10n.editPaste),
          onPressed: () async {
            final controller = ref.read(editorProvider.notifier).controller;
            if (controller == null) return;
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data?.text == null) return;
            final sel = controller.selection;
            final text = controller.text;
            final offset = sel.isValid ? sel.start : text.length;
            final end = sel.isValid ? sel.end : text.length;
            final paste = data!.text!;
            controller.value = TextEditingValue(
              text: text.substring(0, offset) + paste + text.substring(end),
              selection: TextSelection.collapsed(offset: offset + paste.length),
            );
          },
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.copy),
          child: Text(l10n.editCopyAsMarkdown),
          onPressed: () => ref.read(editorProvider.notifier).applyFormat(FormatAction.copyAsMarkdown),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.code),
          child: Text(l10n.editCopyAsHtml),
          onPressed: () => ref.read(editorProvider.notifier).applyFormat(FormatAction.copyAsHtml),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.select_all),
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyA,
            control: !PlatformUtils.isMacOS,
            meta: PlatformUtils.isMacOS,
          ),
          child: Text(l10n.editSelectAll),
          onPressed: () => ref.read(editorProvider.notifier).applyFormat(FormatAction.selectAll),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.content_copy),
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyD,
            control: !PlatformUtils.isMacOS,
            meta: PlatformUtils.isMacOS,
          ),
          child: Text(l10n.editDuplicateLine),
          onPressed: () => ref.read(editorProvider.notifier).applyFormat(FormatAction.duplicateLine),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.search),
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyF,
            control: !PlatformUtils.isMacOS,
            meta: PlatformUtils.isMacOS,
          ),
          child: Text(l10n.editFind),
          onPressed: () => ref.read(editorProvider.notifier).toggleFindReplace(),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.find_replace),
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyH,
            control: !PlatformUtils.isMacOS,
            meta: PlatformUtils.isMacOS,
          ),
          child: Text(l10n.editReplace),
          onPressed: () => ref.read(editorProvider.notifier).toggleFindReplace(),
        ),
      ],
      child: Text(l10n.menuEdit, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildViewMenu(AppLocalizations l10n, WidgetRef ref) {
    final config = ref.watch(settingsProvider);
    final isMac = PlatformUtils.isMacOS;
    return SubmenuButton(
      menuChildren: [
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              shortcut: SingleActivator(
                LogicalKeyboardKey.digit1,
                control: !isMac, meta: isMac, alt: true,
              ),
              child: Text(l10n.viewSourceCode),
              onPressed: () {
                ref.read(settingsProvider.notifier).setEditMode(EditMode.source);
              },
            ),
            MenuItemButton(
              shortcut: SingleActivator(
                LogicalKeyboardKey.digit2,
                control: !isMac, meta: isMac, alt: true,
              ),
              child: Text(l10n.viewPreview),
              onPressed: () {
                ref.read(settingsProvider.notifier).setEditMode(EditMode.preview);
              },
            ),
            MenuItemButton(
              shortcut: SingleActivator(
                LogicalKeyboardKey.digit3,
                control: !isMac, meta: isMac, alt: true,
              ),
              child: Text(l10n.viewSplitView),
              onPressed: () {
                ref.read(settingsProvider.notifier).setEditMode(EditMode.split);
              },
            ),
          ],
          child: Text(l10n.viewEditMode),
        ),
        const Divider(height: 1),
        MenuItemButton(
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyB,
            control: !isMac, meta: isMac, shift: true,
          ),
          child: Text(config.sideBarVisible ? l10n.viewHideSidebar : l10n.viewShowSidebar),
          onPressed: () {
            ref.read(settingsProvider.notifier).toggleSideBar();
          },
        ),
        MenuItemButton(
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyT,
            control: !isMac, meta: isMac, alt: true,
          ),
          child: Text(config.tabBarVisible ? l10n.viewHideTabBar : l10n.viewShowTabBar),
          onPressed: () {
            ref.read(settingsProvider.notifier).toggleTabBar();
          },
        ),
        const Divider(height: 1),
        MenuItemButton(
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyF,
            control: !isMac, meta: isMac, shift: true,
          ),
          child: Text(config.focusMode ? '${l10n.viewFocusMode} \u2713' : l10n.viewFocusMode),
          onPressed: () {
            ref.read(settingsProvider.notifier).toggleFocusMode();
          },
        ),
        MenuItemButton(
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyW,
            control: !isMac, meta: isMac, shift: true,
          ),
          child: Text(config.typewriterMode ? '${l10n.viewTypewriterMode} \u2713' : l10n.viewTypewriterMode),
          onPressed: () {
            ref.read(settingsProvider.notifier).toggleTypewriterMode();
          },
        ),
        const Divider(height: 1),
        MenuItemButton(
          shortcut: SingleActivator(
            LogicalKeyboardKey.equal,
            control: !isMac, meta: isMac,
          ),
          child: Text(l10n.viewZoomIn),
          onPressed: () {
            final newSize = (config.fontSize + 2).clamp(12.0, 32.0);
            ref.read(settingsProvider.notifier).setFontSize(newSize);
          },
        ),
        MenuItemButton(
          shortcut: SingleActivator(
            LogicalKeyboardKey.minus,
            control: !isMac, meta: isMac,
          ),
          child: Text(l10n.viewZoomOut),
          onPressed: () {
            final newSize = (config.fontSize - 2).clamp(12.0, 32.0);
            ref.read(settingsProvider.notifier).setFontSize(newSize);
          },
        ),
        MenuItemButton(
          shortcut: SingleActivator(
            LogicalKeyboardKey.digit0,
            control: !isMac, meta: isMac,
          ),
          child: Text(l10n.viewResetZoom),
          onPressed: () {
            ref.read(settingsProvider.notifier).setFontSize(16.0);
          },
        ),
      ],
      child: Text(l10n.menuView, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFormatMenu(AppLocalizations l10n, WidgetRef ref) {
    void fmt(FormatAction action) => ref.read(editorProvider.notifier).applyFormat(action);
    final kb = KeybindingService();
    final headingActions = [
      FormatAction.heading1, FormatAction.heading2, FormatAction.heading3,
      FormatAction.heading4, FormatAction.heading5, FormatAction.heading6,
    ];
    final headingKeys = ['heading1', 'heading2', 'heading3', 'heading4', 'heading5', 'heading6'];
    return SubmenuButton(
      menuChildren: [
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding('bold')),
              child: Text(l10n.formatBold),
              onPressed: () => fmt(FormatAction.bold),
            ),
            MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding('italic')),
              child: Text(l10n.formatItalic),
              onPressed: () => fmt(FormatAction.italic),
            ),
            MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding('strikethrough')),
              child: Text(l10n.formatStrikethrough),
              onPressed: () => fmt(FormatAction.strikethrough),
            ),
            MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding('underline')),
              child: Text(l10n.formatUnderline),
              onPressed: () => fmt(FormatAction.underline),
            ),
            MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding('highlight')),
              child: Text(l10n.formatHighlight),
              onPressed: () => fmt(FormatAction.highlight),
            ),
            MenuItemButton(
              child: Text(l10n.formatClearFormatting),
              onPressed: () => fmt(FormatAction.clearFormatting),
            ),
          ],
          child: Text(l10n.formatTextSubmenu),
        ),
        SubmenuButton(
          menuChildren: List.generate(
            6,
            (i) => MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding(headingKeys[i])),
              child: Text(l10n.formatHeading(i + 1)),
              onPressed: () => fmt(headingActions[i]),
            ),
          ),
          child: Text(l10n.formatHeadingSubmenu),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding('orderedList')),
              child: Text(l10n.formatOrderedList),
              onPressed: () => fmt(FormatAction.orderedList),
            ),
            MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding('unorderedList')),
              child: Text(l10n.formatUnorderedList),
              onPressed: () => fmt(FormatAction.unorderedList),
            ),
            MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding('taskList')),
              child: Text(l10n.formatTaskList),
              onPressed: () => fmt(FormatAction.taskList),
            ),
            MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding('quoteBlock')),
              child: Text(l10n.formatQuoteBlock),
              onPressed: () => fmt(FormatAction.quoteBlock),
            ),
          ],
          child: Text(l10n.formatBlocksSubmenu),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding('codeBlock')),
              child: Text(l10n.formatCodeBlock),
              onPressed: () => fmt(FormatAction.codeBlock),
            ),
            MenuItemButton(
              child: Text(l10n.formatMathBlock),
              onPressed: () => fmt(FormatAction.mathBlock),
            ),
            MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding('inlineCode')),
              child: Text(l10n.formatInlineCode),
              onPressed: () => fmt(FormatAction.inlineCode),
            ),
            MenuItemButton(
              child: Text(l10n.formatInlineMath),
              onPressed: () => fmt(FormatAction.inlineMath),
            ),
          ],
          child: Text(l10n.formatCodeSubmenu),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding('table')),
              child: Text(l10n.formatTable),
              onPressed: () => fmt(FormatAction.table),
            ),
            MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding('link')),
              child: Text(l10n.formatLink),
              onPressed: () => fmt(FormatAction.link),
            ),
            MenuItemButton(
              shortcut: _parseShortcut(kb.getKeybinding('image')),
              child: Text(l10n.formatImage),
              onPressed: () => fmt(FormatAction.image),
            ),
            MenuItemButton(
              child: Text(l10n.formatHorizontalRule),
              onPressed: () => fmt(FormatAction.horizontalRule),
            ),
            MenuItemButton(
              child: Text(l10n.formatSuperscript),
              onPressed: () => fmt(FormatAction.superscript),
            ),
            MenuItemButton(
              child: Text(l10n.formatSubscript),
              onPressed: () => fmt(FormatAction.subscript),
            ),
          ],
          child: Text(l10n.formatInsertSubmenu),
        ),
      ],
      child: Text(l10n.menuFormat, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildWindowMenu(AppLocalizations l10n, WidgetRef ref) {
    return SubmenuButton(
      menuChildren: [
        MenuItemButton(
          child: Text(l10n.windowMinimize),
          onPressed: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
        ),
        MenuItemButton(
          child: Text(l10n.windowFullScreen),
          onPressed: () {
            // Full screen toggle not available without window_manager
          },
        ),
        MenuItemButton(
          child: Text(l10n.windowAlwaysOnTop),
          onPressed: () {
            // Always on top not available without window_manager
          },
        ),
      ],
      child: Text(l10n.menuWindow, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHelpMenu(AppLocalizations l10n, WidgetRef ref) {
    return SubmenuButton(
      menuChildren: [
        MenuItemButton(
          child: Text(l10n.helpAbout),
          onPressed: () {
            showAboutDialog(
              context: navigatorKey.currentContext!,
              applicationName: 'MarkText Plus',
              applicationVersion: 'v1.0.1',
              applicationLegalese: 'MIT License\nBased on MarkText by Luo Ran',
            );
          },
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: Text(l10n.helpCheckUpdates),
          onPressed: () => _launchUrl('https://github.com/user/marktext-plus/releases'),
        ),
        MenuItemButton(
          child: Text(l10n.helpChangelog),
          onPressed: () => _launchUrl('https://github.com/user/marktext-plus/releases'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: Text(l10n.helpReportBug),
          onPressed: () => _launchUrl('https://github.com/user/marktext-plus/issues'),
        ),
        MenuItemButton(
          child: Text(l10n.helpRequestFeature),
          onPressed: () => _launchUrl('https://github.com/user/marktext-plus/issues'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: Text(l10n.helpGitHub),
          onPressed: () => _launchUrl('https://github.com/user/marktext-plus'),
        ),
      ],
      child: Text(l10n.menuHelp, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _exportHtml(WidgetRef ref) async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) return;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export HTML',
      fileName: '${p.basenameWithoutExtension(activeTab.fileName)}.html',
      type: FileType.custom,
      allowedExtensions: ['html'],
    );
    if (path == null) return;
    await ExportService.exportToHtml(activeTab.content, path);
  }

  void _exportPdf(WidgetRef ref) async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) return;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export PDF',
      fileName: '${p.basenameWithoutExtension(activeTab.fileName)}.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (path == null) return;
    await ExportService.exportToPdf(activeTab.content, path);
  }

  void _newWindow() async {
    final executable = Platform.resolvedExecutable;
    if (PlatformUtils.isMacOS) {
      await Process.start('open', ['-n', '-a', executable]);
    } else {
      await Process.start(executable, [], mode: ProcessStartMode.detached);
    }
  }

  void _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  Widget _buildRecentFilesMenu(AppLocalizations l10n, WidgetRef ref) {
    final recentFiles = ref.watch(settingsProvider).recentFiles;
    return SubmenuButton(
      menuChildren: recentFiles.isEmpty
          ? [
              MenuItemButton(
                onPressed: null,
                child: Text(l10n.fileNoRecentFiles),
              ),
            ]
          : recentFiles
              .map((filePath) => MenuItemButton(
                    child: Text(
                      p.basename(filePath),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => _openRecentFile(ref, filePath),
                  ))
              .toList(),
      child: Text(l10n.fileRecentFiles),
    );
  }

  void _openRecentFile(WidgetRef ref, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;
    final content = await file.readAsString();
    final tab = TabInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filePath: filePath,
      fileName: p.basename(filePath),
      content: content,
    );
    ref.read(tabProvider.notifier).addTab(tab);
    ref.read(settingsProvider.notifier).addRecentFile(filePath);
  }
}
