import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import '../../services/markdown_parser.dart';
import '../../utils/platform_utils.dart';
import '../screens/settings_screen.dart';
import '../editor/mermaid/widgets/mermaid_diagram.dart';
import '../editor/mermaid/models/style.dart';
import 'editor_tab_bar.dart';
import '../editor/mermaid/parser/mermaid_parser.dart';
import '../../providers/sidebar_provider.dart';
import 'command_palette.dart';
import '../../services/file_service.dart';

class AppMenuBar extends ConsumerWidget {
  const AppMenuBar({super.key});

  /// The shortcut configured for [action], or null when it has none.
  ///
  /// Both the label a menu shows and the key that actually fires now come from
  /// the same place, so a rebound shortcut cannot display one thing and do
  /// another.
  static SingleActivator? _shortcut(String action) =>
      KeybindingService().activatorFor(action, isMacOS: PlatformUtils.isMacOS);

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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            MenuBar(
              style: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(tokens.colorSurface),
                elevation: const WidgetStatePropertyAll(0),
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              ),
              children: [
                _buildFileMenu(context, l10n, ref),
                _buildEditMenu(l10n, ref),
                _buildViewMenu(context, l10n, ref),
                _buildFormatMenu(l10n, ref),
                _buildWindowMenu(l10n, ref),
                _buildHelpMenu(l10n, ref),
              ],
            ),
            const Spacer(),
            _buildToolbarIcons(ref, tokens, l10n),
          ],
        ),
      ),
    );
  }

  void _newFile(WidgetRef ref, AppLocalizations l10n) {
    final tab = TabInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      // TabInfo defaults to the English 'Untitled'; it is a model and has no
      // way to reach the localisations, so the name is passed in here.
      fileName: l10n.untitled,
    );
    ref.read(tabProvider.notifier).addTab(tab);
  }

  /// Opens a file through the picker. Shared with the shortcut dispatcher.
  static void openFile(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final opened = await FileService().readFileWithLineEnding(path);
    final tab = TabInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filePath: path,
      fileName: p.basename(path),
      content: opened.content,
      lineEnding: opened.lineEnding,
    );
    ref.read(tabProvider.notifier).addTab(tab);
    ref.read(settingsProvider.notifier).addRecentFile(path);
  }

  void _openFolder(WidgetRef ref) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;
    ref.read(fileProvider.notifier).loadDirectory(result);
    ref.read(settingsProvider.notifier).updateConfig(
      (c) => c.copyWith(sideBarDirectory: result),
    );
  }

  /// Writes the active tab back to disk, asking for a location if it has
  /// none. Shared with the shortcut dispatcher.
  static void saveFile(WidgetRef ref) async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) return;
    if (activeTab.filePath != null) {
      await FileService.saveDocument(activeTab.filePath!, activeTab.content,
          lineEnding: activeTab.lineEnding);
      ref.read(tabProvider.notifier).markSaved(activeTab.id);
    } else {
      _saveFileAs(ref);
    }
  }

  static void _saveFileAs(WidgetRef ref) async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) return;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save As',
      fileName: activeTab.fileName,
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown', 'txt'],
    );
    if (path == null) return;
    await FileService.saveDocument(path, activeTab.content,
        lineEnding: activeTab.lineEnding);
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

  Widget _buildFileMenu(
      BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    return SubmenuButton(
      menuChildren: [
        MenuItemButton(
          child: Text(l10n.fileNew),
          onPressed: () => _newFile(ref, l10n),
        ),
        MenuItemButton(
          child: Text(l10n.fileNewWindow),
          onPressed: () => _newWindow(),
        ),
        const Divider(height: 1),
        MenuItemButton(
          onPressed: () => openFile(ref),
          shortcut: _shortcut('open'),
          child: Text(l10n.fileOpen),
        ),
        MenuItemButton(
          child: Text(l10n.fileOpenFolder),
          onPressed: () => _openFolder(ref),
        ),
        _buildRecentFilesMenu(l10n, ref),
        const Divider(height: 1),
        MenuItemButton(
          onPressed: () => saveFile(ref),
          shortcut: _shortcut('save'),
          child: Text(l10n.fileSave),
        ),
        MenuItemButton(
          child: Text(l10n.fileSaveAs),
          onPressed: () => _saveFileAs(ref),
        ),
        MenuItemButton(
          child: Text(l10n.fileRename),
          onPressed: () => _renameFile(ref),
        ),
        const Divider(height: 1),
        MenuItemButton(
          shortcut: _shortcut('closeTab'),
          child: Text(l10n.fileCloseTab),
          onPressed: () => _closeActiveTab(context, ref),
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
            MenuItemButton(
              child: Text(l10n.fileExportWord),
              onPressed: () => _exportWord(ref),
            ),
          ],
          child: Text(l10n.fileExport),
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: Text(l10n.fileSettings),
          onPressed: () {
            navigatorKey.currentState?.push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const SettingsScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: Text(l10n.fileQuit),
          onPressed: () => exit(0),
        ),
      ],
      child: Text(l10n.menuFile, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildEditMenu(AppLocalizations l10n, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    return SubmenuButton(
      menuChildren: [
        MenuItemButton(
          onPressed: editorState.canUndo
              ? () => ref.read(editorProvider.notifier).undo()
              : null,
          shortcut: _shortcut('undo'),
          child: Text(l10n.editUndo),
        ),
        MenuItemButton(
          onPressed: editorState.canRedo
              ? () => ref.read(editorProvider.notifier).redo()
              : null,
          shortcut: _shortcut('redo'),
          child: Text(l10n.editRedo),
        ),
        const Divider(height: 1),
        MenuItemButton(
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
          child: Text(l10n.editCopyAsMarkdown),
          onPressed: () => ref.read(editorProvider.notifier).applyFormat(FormatAction.copyAsMarkdown),
        ),
        MenuItemButton(
          child: Text(l10n.editCopyAsHtml),
          onPressed: () => ref.read(editorProvider.notifier).applyFormat(FormatAction.copyAsHtml),
        ),
        const Divider(height: 1),
        MenuItemButton(
          shortcut: _shortcut('selectAll'),
          child: Text(l10n.editSelectAll),
          onPressed: () => ref.read(editorProvider.notifier).applyFormat(FormatAction.selectAll),
        ),
        MenuItemButton(
          shortcut: _shortcut('duplicateLine'),
          child: Text(l10n.editDuplicateLine),
          onPressed: () => ref.read(editorProvider.notifier).applyFormat(FormatAction.duplicateLine),
        ),
        const Divider(height: 1),
        MenuItemButton(
          shortcut: _shortcut('find'),
          child: Text(l10n.editFind),
          onPressed: () => ref.read(editorProvider.notifier).toggleFindReplace(),
        ),
        MenuItemButton(
          shortcut: _shortcut('findNext'),
          child: Text(l10n.editFindNext),
          onPressed: () => ref
              .read(editorProvider.notifier)
              .stepToFindMatch(forward: true),
        ),
        MenuItemButton(
          shortcut: _shortcut('findPrevious'),
          child: Text(l10n.editFindPrevious),
          onPressed: () => ref
              .read(editorProvider.notifier)
              .stepToFindMatch(forward: false),
        ),
        MenuItemButton(
          shortcut: _shortcut('replace'),
          child: Text(l10n.editReplace),
          onPressed: () => ref.read(editorProvider.notifier).toggleFindReplace(),
        ),
      ],
      child: Text(l10n.menuEdit, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildViewMenu(
      BuildContext context, AppLocalizations l10n, WidgetRef ref) {
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
        // The table of contents was reachable only by finding its icon in the
        // sidebar; the command palette had no entry at all.
        MenuItemButton(
          child: Text(l10n.sidebarToc),
          onPressed: () {
            final settings = ref.read(settingsProvider.notifier);
            if (!ref.read(settingsProvider).sideBarVisible) {
              settings.toggleSideBar();
            }
            ref.read(sideBarTabProvider.notifier).state = SideBarTab.toc;
          },
        ),
        MenuItemButton(
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyP,
            control: !isMac, meta: isMac,
          ),
          child: Text(l10n.viewCommandPalette),
          onPressed: () => CommandPalette.show(context),
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
      child: Text(l10n.menuView, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildFormatMenu(AppLocalizations l10n, WidgetRef ref) {
    void fmt(FormatAction action) => ref.read(editorProvider.notifier).applyFormat(action);
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
              shortcut: _shortcut('bold'),
              child: Text(l10n.formatBold),
              onPressed: () => fmt(FormatAction.bold),
            ),
            MenuItemButton(
              shortcut: _shortcut('italic'),
              child: Text(l10n.formatItalic),
              onPressed: () => fmt(FormatAction.italic),
            ),
            MenuItemButton(
              shortcut: _shortcut('strikethrough'),
              child: Text(l10n.formatStrikethrough),
              onPressed: () => fmt(FormatAction.strikethrough),
            ),
            MenuItemButton(
              shortcut: _shortcut('underline'),
              child: Text(l10n.formatUnderline),
              onPressed: () => fmt(FormatAction.underline),
            ),
            MenuItemButton(
              shortcut: _shortcut('highlight'),
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
              shortcut: _shortcut(headingKeys[i]),
              child: Text(l10n.formatHeading(i + 1)),
              onPressed: () => fmt(headingActions[i]),
            ),
          ),
          child: Text(l10n.formatHeadingSubmenu),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              shortcut: _shortcut('promoteHeading'),
              child: Text(l10n.paragraphPromoteHeading),
              onPressed: () => fmt(FormatAction.promoteHeading),
            ),
            MenuItemButton(
              shortcut: _shortcut('demoteHeading'),
              child: Text(l10n.paragraphDemoteHeading),
              onPressed: () => fmt(FormatAction.demoteHeading),
            ),
            MenuItemButton(
              // Front matter only counts as front matter at the very top of
              // the file, so this ignores the caret and inserts there.
              child: Text(l10n.formatFrontMatter),
              onPressed: () => fmt(FormatAction.frontMatter),
            ),
            MenuItemButton(
              child: Text(l10n.formatHtmlBlock),
              onPressed: () => fmt(FormatAction.htmlBlock),
            ),
            MenuItemButton(
              child: Text(l10n.paragraphToParagraph),
              onPressed: () => fmt(FormatAction.toParagraph),
            ),
          ],
          child: Text(l10n.menuParagraph),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              shortcut: _shortcut('orderedList'),
              child: Text(l10n.formatOrderedList),
              onPressed: () => fmt(FormatAction.orderedList),
            ),
            MenuItemButton(
              shortcut: _shortcut('unorderedList'),
              child: Text(l10n.formatUnorderedList),
              onPressed: () => fmt(FormatAction.unorderedList),
            ),
            MenuItemButton(
              shortcut: _shortcut('taskList'),
              child: Text(l10n.formatTaskList),
              onPressed: () => fmt(FormatAction.taskList),
            ),
            MenuItemButton(
              shortcut: _shortcut('quoteBlock'),
              child: Text(l10n.formatQuoteBlock),
              onPressed: () => fmt(FormatAction.quoteBlock),
            ),
          ],
          child: Text(l10n.formatBlocksSubmenu),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              shortcut: _shortcut('codeBlock'),
              child: Text(l10n.formatCodeBlock),
              onPressed: () => fmt(FormatAction.codeBlock),
            ),
            MenuItemButton(
              shortcut: _shortcut('mathBlock'),
              child: Text(l10n.formatMathBlock),
              onPressed: () => fmt(FormatAction.mathBlock),
            ),
            MenuItemButton(
              shortcut: _shortcut('inlineCode'),
              child: Text(l10n.formatInlineCode),
              onPressed: () => fmt(FormatAction.inlineCode),
            ),
            MenuItemButton(
              shortcut: _shortcut('inlineMath'),
              child: Text(l10n.formatInlineMath),
              onPressed: () => fmt(FormatAction.inlineMath),
            ),
          ],
          child: Text(l10n.formatCodeSubmenu),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              shortcut: _shortcut('table'),
              child: Text(l10n.formatTable),
              onPressed: () => fmt(FormatAction.table),
            ),
            MenuItemButton(
              shortcut: _shortcut('link'),
              child: Text(l10n.formatLink),
              onPressed: () => fmt(FormatAction.link),
            ),
            MenuItemButton(
              shortcut: _shortcut('image'),
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
      child: Text(l10n.menuFormat, style: const TextStyle(fontSize: 13)),
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
      child: Text(l10n.menuWindow, style: const TextStyle(fontSize: 13)),
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
          onPressed: () => _launchUrl('https://github.com/SugarFatFree/marktext-plus/releases'),
        ),
        MenuItemButton(
          child: Text(l10n.helpChangelog),
          onPressed: () => _launchUrl('https://github.com/SugarFatFree/marktext-plus/releases'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: Text(l10n.helpReportBug),
          onPressed: () => _launchUrl('https://github.com/SugarFatFree/marktext-plus/issues'),
        ),
        MenuItemButton(
          child: Text(l10n.helpRequestFeature),
          onPressed: () => _launchUrl('https://github.com/SugarFatFree/marktext-plus/issues'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: Text(l10n.helpGitHub),
          onPressed: () => _launchUrl('https://github.com/SugarFatFree/marktext-plus'),
        ),
      ],
      child: Text(l10n.menuHelp, style: const TextStyle(fontSize: 13)),
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
    // The tab's own path is what relative image references resolve against.
    await ExportService.exportToHtml(
      activeTab.content,
      path,
      sourcePath: activeTab.filePath,
    );
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
    final mermaidImages = await _renderMermaidImages(activeTab.content);
    await ExportService.exportToPdf(
      activeTab.content,
      path,
      mermaidImages: mermaidImages,
      sourcePath: activeTab.filePath,
    );
  }

  void _exportWord(WidgetRef ref) async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) return;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Word',
      fileName: '${p.basenameWithoutExtension(activeTab.fileName)}.docx',
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );
    if (path == null) return;
    final mermaidImages = await _renderMermaidImages(activeTab.content);
    await ExportService.exportToDocx(
      activeTab.content,
      path,
      mermaidImages: mermaidImages,
      sourcePath: activeTab.filePath,
    );
  }

  Future<Map<String, Uint8List>> _renderMermaidImages(String markdown) async {
    final parser = MarkdownParser();
    final ast = parser.parse(markdown);
    final images = <String, Uint8List>{};
    int index = 0;

    for (final node in ast) {
      // Must agree with ExportService's own test, which also asks the parser:
      // the export indexes into this map by counting diagram blocks, so a
      // disagreement embeds the wrong picture.
      if (node is CodeBlockNode &&
          MermaidParser.handlesLanguage(node.language)) {
        final key = 'mermaid_$index';
        index++;
        try {
          final bytes = await _renderMermaidToImage(node.code);
          if (bytes != null) images[key] = bytes;
        } catch (_) {
          // Skip failed renders
        }
      }
    }
    return images;
  }

  Future<Uint8List?> _renderMermaidToImage(String code) async {
    final key = GlobalKey();

    final overlay = Overlay.of(navigatorKey.currentContext!);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -9999,
        top: -9999,
        child: RepaintBoundary(
          key: key,
          child: Container(
            color: Colors.white,
            width: 800,
            child: MermaidDiagram(
              code: code,
              width: 800,
              style: const MermaidStyle(),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Wait for layout + paint
    for (int i = 0; i < 5; i++) {
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    Uint8List? result;
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null && boundary.hasSize && boundary.size.width > 0) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          result = byteData.buffer.asUint8List();
        }
      }
    } catch (_) {}

    entry.remove();
    return result;
  }

  void _newWindow() async {
    await PlatformUtils.launchNewWindow();
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
          : [
              ...recentFiles.map((filePath) => MenuItemButton(
                    child: Text(
                      p.basename(filePath),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => _openRecentFile(ref, filePath),
                  )),
              const Divider(height: 1),
              // The list only ever grew; there was no way to empty it.
              MenuItemButton(
                child: Text(l10n.fileClearRecentFiles),
                onPressed: () => ref
                    .read(settingsProvider.notifier)
                    .updateConfig((c) => c.copyWith(recentFiles: const [])),
              ),
            ],
      child: Text(l10n.fileRecentFiles),
    );
  }

  /// Closes the active tab through the tab bar's confirmation, so an unsaved
  /// document is not discarded without asking.
  static void _closeActiveTab(BuildContext context, WidgetRef ref) {
    final tab = ref.read(activeTabProvider);
    if (tab == null) return;
    EditorTabBar.closeTab(context, ref, tab);
  }

  void _openRecentFile(WidgetRef ref, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;
    final opened = await FileService().readFileWithLineEnding(filePath);
    final tab = TabInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filePath: filePath,
      fileName: p.basename(filePath),
      content: opened.content,
      lineEnding: opened.lineEnding,
    );
    ref.read(tabProvider.notifier).addTab(tab);
    ref.read(settingsProvider.notifier).addRecentFile(filePath);
  }

  Widget _buildToolbarIcons(
      WidgetRef ref, AppThemeTokens tokens, AppLocalizations l10n) {
    final config = ref.watch(settingsProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edit mode switch
        IconButton(
          icon: Icon(_getEditModeIcon(config.editMode)),
          iconSize: 18,
          tooltip: _getEditModeTooltip(config.editMode, l10n),
          onPressed: () => _cycleEditMode(ref, config.editMode),
        ),
        const SizedBox(width: 4),
        // Search
        IconButton(
          icon: const Icon(Icons.search),
          iconSize: 18,
          tooltip: l10n.sidebarSearch,
          onPressed: () => ref.read(editorProvider.notifier).toggleFindReplace(),
        ),
        const SizedBox(width: 4),
        // Sidebar toggle
        IconButton(
          icon: Icon(config.sideBarVisible ? Icons.menu_open : Icons.menu),
          iconSize: 18,
          tooltip: config.sideBarVisible ? l10n.viewHideSidebar : l10n.viewShowSidebar,
          onPressed: () => ref.read(settingsProvider.notifier).toggleSideBar(),
        ),
        const SizedBox(width: 4),
        // Zoom out
        IconButton(
          icon: const Icon(Icons.remove),
          iconSize: 18,
          tooltip: l10n.viewZoomOut,
          onPressed: () {
            final newSize = (config.fontSize - 1).clamp(12.0, 32.0);
            ref.read(settingsProvider.notifier).setFontSize(newSize);
          },
        ),
        const SizedBox(width: 4),
        // Zoom in
        IconButton(
          icon: const Icon(Icons.add),
          iconSize: 18,
          tooltip: l10n.viewZoomIn,
          onPressed: () {
            final newSize = (config.fontSize + 1).clamp(12.0, 32.0);
            ref.read(settingsProvider.notifier).setFontSize(newSize);
          },
        ),
      ],
    );
  }

  IconData _getEditModeIcon(EditMode mode) {
    return switch (mode) {
      EditMode.source => Icons.code,
      EditMode.preview => Icons.visibility,
      EditMode.split => Icons.view_column,
    };
  }

  String _getEditModeTooltip(EditMode mode, AppLocalizations l10n) {
    return switch (mode) {
      EditMode.source => l10n.commandSourceMode,
      EditMode.preview => l10n.commandPreviewMode,
      EditMode.split => l10n.commandSplitMode,
    };
  }

  void _cycleEditMode(WidgetRef ref, EditMode current) {
    final next = switch (current) {
      EditMode.source => EditMode.preview,
      EditMode.preview => EditMode.split,
      EditMode.split => EditMode.source,
    };
    ref.read(settingsProvider.notifier).setEditMode(next);
  }
}
