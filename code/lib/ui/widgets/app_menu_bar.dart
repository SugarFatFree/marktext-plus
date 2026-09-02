import '../../utils/file_utils.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../app.dart';
import '../../core/config/app_config.dart';
import '../../core/diagnostics/startup_trace.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tab_info.dart';
import '../../providers/editor_provider.dart';
import '../../services/table_edit_service.dart';
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
import '../../services/clipboard_service.dart';
import '../../services/rich_copy_service.dart';
import 'package:window_manager/window_manager.dart';
import '../../providers/window_provider.dart';
import '../../providers/update_provider.dart';
import '../../services/update_service.dart';
import '../../core/constants.dart';

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
        // The toolbar stands down when the window is too narrow for it: every
        // one of its buttons is also an item in the menus beside it, and the
        // bar was striped from about 780 pixels down. A scrolling row is not
        // an option here — the Spacer that holds the toolbar to the right
        // edge needs a bounded width, which a scrolling row does not give.
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
          children: [
            // The menus scroll on their own when six of them will not fit;
            // the Spacer stays outside, in a row that still has a width, so
            // the toolbar keeps its place at the right edge.
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: MenuBar(
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
              ),
            ),
            if (constraints.maxWidth >= 820)
              _buildToolbarIcons(ref, tokens, l10n),
          ],
          ),
        ),
      ),
    );
  }

  /// Opens an empty tab.
  ///
  /// Public so the command palette runs this rather than its own copy: that
  /// copy left the name out, and a new document created from the palette came
  /// up called "Untitled" whatever language the app was in.
  static void newFile(WidgetRef ref, AppLocalizations l10n) {
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
      allowedExtensions: FileUtils.markdownExtensions,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    try {
      final opened = await FileService().readFileWithLineEnding(path);
      final tab = TabInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        filePath: path,
        fileName: p.basename(path),
        content: opened.content,
        lineEnding: opened.lineEnding,
        encoding: opened.encoding,
        diskStamp: opened.stamp,
      );
      ref.read(tabProvider.notifier).addTab(tab);
      ref.read(settingsProvider.notifier).addRecentFile(path);
    } catch (e) {
      // A file can stop being readable between being picked and being read —
      // permissions, a network share going away, something else deleting it.
      // The sidebar's open has always said so; this one gave no tab and no
      // message.
      reportOpenFailure(e);
    }
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
      try {
        await FileService.saveDocumentIfUnchanged(
          activeTab.filePath!,
          activeTab.content,
          expect: activeTab.diskStamp,
          lineEnding: activeTab.lineEnding,
          encoding: activeTab.encoding,
        );
      } on FileChangedOnDiskException {
        // Something else rewrote the file while it was open. Which version
        // wins is the reader's decision, not this function's — writing
        // anyway is how the other version disappears without anyone seeing
        // it happen.
        await _resolveSaveConflict(ref, activeTab);
        return;
      } catch (e) {
        // Left marked as modified, so the dot in the tab bar and the close
        // confirmation both keep telling the truth about what is on disk —
        // and said out loud, because a silent Ctrl+S is indistinguishable
        // from one that worked.
        reportSaveFailure(e);
        return;
      }
      await ref.read(tabProvider.notifier).markSaved(activeTab.id);
    } else {
      _saveFileAs(ref);
    }
  }

  /// Asks which version of a file that changed underneath the editor to keep.
  ///
  /// Three answers, and no default: overwrite what is on disk, throw away the
  /// edits and take what is on disk, or do neither and decide later. Cancel
  /// leaves the tab modified and in conflict, which is what stops auto-save
  /// from quietly answering the question instead.
  static Future<void> _resolveSaveConflict(WidgetRef ref, TabInfo tab) async {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saveConflictTitle),
        content: Text(l10n.saveConflictBody(tab.fileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: Text(l10n.saveConflictCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('reload'),
            child: Text(l10n.saveConflictReload),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('overwrite'),
            child: Text(l10n.saveConflictOverwrite),
          ),
        ],
      ),
    );

    final notifier = ref.read(tabProvider.notifier);
    switch (choice) {
      case 'overwrite':
        await notifier.overwriteOnDisk(tab.id);
      case 'reload':
        await notifier.reloadFromDisk(tab.id);
      default:
        // Neither: the tab keeps the edits and stays in conflict, so the
        // banner remains and auto-save stays out of it.
        notifier.markDiskConflict(tab.id);
    }
  }

  /// The localisations, when a context is available.
  ///
  /// The file picker's title is shown by the operating system, so it has to be
  /// a string rather than a widget — and these call sites are static, with no
  /// context of their own. Falls back to English if the navigator has none,
  /// which is better than showing nothing.
  static AppLocalizations? get _l10n {
    final context = navigatorKey.currentContext;
    return context == null ? null : AppLocalizations.of(context);
  }

  static void _saveFileAs(WidgetRef ref) async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) return;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: _l10n?.fileSaveAs ?? 'Save As',
      fileName: activeTab.fileName,
      type: FileType.custom,
      allowedExtensions: FileUtils.markdownExtensions,
    );
    if (path == null) return;
    try {
      await FileService.saveDocument(path, activeTab.content,
          lineEnding: activeTab.lineEnding, encoding: activeTab.encoding);
    } catch (e) {
      reportSaveFailure(e);
      return;
    }

    // Rebind the tab to where it was actually written. Without this an
    // untitled document stayed untitled: the title bar kept saying so, and
    // the next Ctrl+S asked for a location all over again.
    ref
        .read(tabProvider.notifier)
        .updateTabPath(activeTab.id, path, p.basename(path));
    await ref.read(tabProvider.notifier).markSaved(activeTab.id);
    ref.read(settingsProvider.notifier).addRecentFile(path);
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
    await _relocate(ref, oldPath, newPath);
  }

  /// Moves the open document to another folder.
  ///
  /// `file.move-file` in upstream MarkText, which this menu never had.
  ///
  /// Moving and renaming are one operation — both are `File.rename` to a new
  /// path — so both go through the same call. `FileService.moveFile` was an
  /// alias for `renameFile` with no callers at all; a second name for one
  /// operation is how the two drift apart later, so it is gone rather than
  /// wired up.
  void _moveFile(WidgetRef ref) async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null || activeTab.filePath == null) return;
    final oldPath = activeTab.filePath!;

    final folder = await FilePicker.platform.getDirectoryPath();
    if (folder == null) return;
    final newPath = p.join(folder, p.basename(oldPath));
    if (newPath == oldPath) return;
    await _relocate(ref, oldPath, newPath);
  }

  /// Renames or moves [oldPath], and tells the reader when it cannot.
  ///
  /// Goes through the provider rather than calling `File.rename` here. The
  /// menu used to do its own rename, which meant it also skipped the guard
  /// the service grew: `File.rename` replaces the destination without a word,
  /// so renaming a note onto a name already in use destroyed the note that
  /// had it — no prompt, no undo, nothing on screen. The sidebar's rename was
  /// fixed; this one was the copy that did not keep up.
  Future<void> _relocate(
    WidgetRef ref,
    String oldPath,
    String newPath,
  ) async {
    final ctx = navigatorKey.currentContext;
    try {
      await ref.read(fileProvider.notifier).renameNode(oldPath, newPath);
    } on PathExistsException {
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(ctx)!.fileNameTaken)),
        );
      }
      return;
    } catch (e) {
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(ctx)!.fileOperationFailed('$e')),
          ),
        );
      }
      return;
    }
    // The same call the sidebar makes, so the two ways of moving a document
    // cannot drift apart again.
    ref.read(tabProvider.notifier).pathRenamed(oldPath, newPath);
  }

  Widget _buildFileMenu(
      BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    final hasDocument = ref.watch(activeTabProvider) != null;
    return SubmenuButton(
      menuChildren: [
        MenuItemButton(
          child: Text(l10n.fileNew),
          onPressed: () => newFile(ref, l10n),
        ),
        MenuItemButton(
          shortcut: _shortcut('newWindow'),
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
        _buildRecentFilesMenu(context, l10n, ref),
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
        MenuItemButton(
          onPressed: hasDocument ? () => _moveFile(ref) : null,
          child: Text(l10n.fileMove),
        ),
        const Divider(height: 1),
        MenuItemButton(
          shortcut: _shortcut('closeTab'),
          child: Text(l10n.fileCloseTab),
          onPressed: () => _closeActiveTab(context, ref),
        ),
        const Divider(height: 1),
        // Greyed out with nothing open. Closing the last tab leaves no
        // document at all, and each of these began by returning quietly when
        // it found none — the reader clicked Export and nothing happened,
        // with nothing to say why.
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: hasDocument ? () => _exportHtml(ref) : null,
              child: Text(l10n.fileExportHtml),
            ),
            MenuItemButton(
              shortcut: _shortcut('exportPdf'),
              onPressed: hasDocument ? () => _exportPdf(ref) : null,
              child: Text(l10n.fileExportPdf),
            ),
            MenuItemButton(
              onPressed: hasDocument ? () => _exportWord(ref) : null,
              child: Text(l10n.fileExportWord),
            ),
          ],
          child: Text(l10n.fileExport),
        ),
        // Beside Export, which is where upstream puts it, and laid out by the
        // same code the PDF export uses so the paper matches the file.
        MenuItemButton(
          shortcut: _shortcut('print'),
          onPressed: hasDocument ? () => _print(ref) : null,
          child: Text(l10n.filePrint),
        ),
        const Divider(height: 1),
        MenuItemButton(
          shortcut: _shortcut('settings'),
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
          shortcut: _shortcut('quit'),
          // `close`, not `exit(0)`: the window is set to prevent closing, so
          // this reaches the same handler the title bar's close button does —
          // which asks about unsaved work and records the window geometry.
          // Quitting from the menu used to end the process outright, losing
          // every modified tab without a word.
          child: Text(l10n.fileQuit),
          onPressed: () => windowManager.close(),
        ),
      ],
      child: Text(l10n.menuFile, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildEditMenu(AppLocalizations l10n, WidgetRef ref) {
    // Undo and redo availability only. The whole provider would rebuild the
    // menu bar on every cursor move.
    final editorState = ref.watch(
      editorProvider.select((s) => (canUndo: s.canUndo, canRedo: s.canRedo)),
    );
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
            final html = RichCopyService.htmlForMarkdownSelection(selected);
            // Deliberately not awaited: cutting must update the editor
            // immediately while the native clipboard receives both flavours.
            unawaited(ClipboardService.copyWithHtml(selected, html));
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
            final html = RichCopyService.htmlForMarkdownSelection(selected);
            // Deliberately not awaited: the menu should return immediately
            // while the native clipboard receives both flavours.
            unawaited(ClipboardService.copyWithHtml(selected, html));
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
        // Beside "duplicate line", which is where upstream puts them.
        MenuItemButton(
          shortcut: _shortcut('createParagraph'),
          child: Text(l10n.editCreateParagraph),
          onPressed: () => ref
              .read(editorProvider.notifier)
              .applyFormat(FormatAction.createParagraph),
        ),
        MenuItemButton(
          shortcut: _shortcut('deleteParagraph'),
          child: Text(l10n.editDeleteParagraph),
          onPressed: () => ref
              .read(editorProvider.notifier)
              .applyFormat(FormatAction.deleteParagraph),
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
        // Searching every file in the folder was only ever reachable by
        // finding the magnifying glass in the sidebar. Upstream puts it in
        // this menu next to Find, the label was already translated into all
        // twelve languages, and nothing referred to it.
        MenuItemButton(
          child: Text(l10n.editFindInFiles),
          onPressed: () {
            final settings = ref.read(settingsProvider.notifier);
            if (!ref.read(settingsProvider).sideBarVisible) {
              settings.toggleSideBar();
            }
            ref.read(sideBarTabProvider.notifier).state = SideBarTab.search;
          },
        ),
      ],
      child: Text(l10n.menuEdit, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildViewMenu(
      BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    final config = ref.watch(settingsProvider);
    return SubmenuButton(
      menuChildren: [
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              shortcut: _shortcut('sourceMode'),
              child: Text(l10n.viewSourceCode),
              onPressed: () {
                ref.read(settingsProvider.notifier).setEditMode(EditMode.source);
              },
            ),
            MenuItemButton(
              shortcut: _shortcut('previewMode'),
              child: Text(l10n.viewPreview),
              onPressed: () {
                ref.read(settingsProvider.notifier).setEditMode(EditMode.preview);
              },
            ),
            MenuItemButton(
              shortcut: _shortcut('splitMode'),
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
          shortcut: _shortcut('toggleSidebar'),
          child: Text(config.sideBarVisible ? l10n.viewHideSidebar : l10n.viewShowSidebar),
          onPressed: () {
            ref.read(settingsProvider.notifier).toggleSideBar();
          },
        ),
        MenuItemButton(
          shortcut: _shortcut('toggleTabBar'),
          child: Text(config.tabBarVisible ? l10n.viewHideTabBar : l10n.viewShowTabBar),
          onPressed: () {
            ref.read(settingsProvider.notifier).toggleTabBar();
          },
        ),
        // The table of contents was reachable only by finding its icon in the
        // sidebar; the command palette had no entry at all.
        MenuItemButton(
          shortcut: _shortcut('reloadImages'),
          // A picture edited outside the app kept showing its old self:
          // Flutter caches a decoded image against its path.
          child: Text(l10n.viewReloadImages),
          onPressed: () => ref.read(editorProvider.notifier).reloadImages(),
        ),
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
          shortcut: _shortcut('commandPalette'),
          child: Text(l10n.viewCommandPalette),
          onPressed: () => CommandPalette.show(context),
        ),
        const Divider(height: 1),
        MenuItemButton(
          shortcut: _shortcut('focusMode'),
          child: Text(config.focusMode ? '${l10n.viewFocusMode} \u2713' : l10n.viewFocusMode),
          onPressed: () {
            ref.read(settingsProvider.notifier).toggleFocusMode();
          },
        ),
        MenuItemButton(
          shortcut: _shortcut('typewriterMode'),
          child: Text(config.typewriterMode ? '${l10n.viewTypewriterMode} \u2713' : l10n.viewTypewriterMode),
          onPressed: () {
            ref.read(settingsProvider.notifier).toggleTypewriterMode();
          },
        ),
        const Divider(height: 1),
        MenuItemButton(
          shortcut: _shortcut('zoomIn'),
          child: Text(l10n.viewZoomIn),
          onPressed: () {
            final newSize = (config.fontSize + 2).clamp(12.0, 32.0);
            ref.read(settingsProvider.notifier).setFontSize(newSize);
          },
        ),
        MenuItemButton(
          shortcut: _shortcut('zoomOut'),
          child: Text(l10n.viewZoomOut),
          onPressed: () {
            final newSize = (config.fontSize - 2).clamp(12.0, 32.0);
            ref.read(settingsProvider.notifier).setFontSize(newSize);
          },
        ),
        MenuItemButton(
          shortcut: _shortcut('resetZoom'),
          child: Text(l10n.viewResetZoom),
          onPressed: () {
            ref.read(settingsProvider.notifier).setFontSize(16.0);
          },
        ),
      ],
      child: Text(l10n.menuView, style: const TextStyle(fontSize: 13)),
    );
  }

  /// Where the caret is, as an offset into the active document.
  ///
  /// The editor keeps the caret as a line and a column for the status bar;
  /// the table commands need an offset into the same text the menu can see.
  static int? _caretOffset(WidgetRef ref) {
    final tab = ref.watch(activeTabProvider);
    if (tab == null) return null;
    final editor = ref.watch(editorProvider);
    final lines = tab.content.split('\n');
    if (editor.cursorLine >= lines.length) return null;
    var offset = 0;
    for (var i = 0; i < editor.cursorLine; i++) {
      offset += lines[i].length + 1;
    }
    return offset + editor.cursorCol.clamp(0, lines[editor.cursorLine].length);
  }

  Widget _buildFormatMenu(AppLocalizations l10n, WidgetRef ref) {
    void fmt(FormatAction action) => ref.read(editorProvider.notifier).applyFormat(action);

    // The table commands only mean anything inside a table, and two of them
    // do not apply even there. Greying them out says so before they are
    // pressed, rather than leaving the reader with a menu entry that does
    // nothing — which is how the replace buttons used to read.
    final caret = _caretOffset(ref);
    final tab = ref.watch(activeTabProvider);
    final table = (caret == null || tab == null)
        ? null
        : TableEditService.locate(tab.content, caret);

    MenuItemButton tableItem(String label, FormatAction action, TableEdit edit) =>
        MenuItemButton(
          onPressed:
              (table != null && table.can(edit)) ? () => fmt(action) : null,
          child: Text(label),
        );
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
              shortcut: _shortcut('clearFormatting'),
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
              shortcut: _shortcut('frontMatter'),
              // Front matter only counts as front matter at the very top of
              // the file, so this ignores the caret and inserts there.
              child: Text(l10n.formatFrontMatter),
              onPressed: () => fmt(FormatAction.frontMatter),
            ),
            MenuItemButton(
              shortcut: _shortcut('htmlBlock'),
              child: Text(l10n.formatHtmlBlock),
              onPressed: () => fmt(FormatAction.htmlBlock),
            ),
            MenuItemButton(
              shortcut: _shortcut('toParagraph'),
              child: Text(l10n.paragraphToParagraph),
              onPressed: () => fmt(FormatAction.toParagraph),
            ),
            MenuItemButton(
              shortcut: _shortcut('looseList'),
              // Upstream carries this as a checkbox; a menu here has no state
              // to check against, so it reads as the action it performs.
              child: Text(l10n.paragraphLooseList),
              onPressed: () => fmt(FormatAction.looseList),
            ),
            const Divider(height: 1),
            MenuItemButton(
              shortcut: _shortcut('moveBlockUp'),
              child: Text(l10n.paragraphMoveBlockUp),
              onPressed: () => fmt(FormatAction.moveBlockUp),
            ),
            MenuItemButton(
              shortcut: _shortcut('moveBlockDown'),
              child: Text(l10n.paragraphMoveBlockDown),
              onPressed: () => fmt(FormatAction.moveBlockDown),
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
            SubmenuButton(
              menuChildren: [
                tableItem(l10n.formatTableInsertRowAbove,
                    FormatAction.tableInsertRowAbove, TableEdit.insertRowAbove),
                tableItem(l10n.formatTableInsertRowBelow,
                    FormatAction.tableInsertRowBelow, TableEdit.insertRowBelow),
                tableItem(l10n.formatTableDeleteRow,
                    FormatAction.tableDeleteRow, TableEdit.deleteRow),
                const Divider(height: 1),
                tableItem(
                    l10n.formatTableInsertColumnLeft,
                    FormatAction.tableInsertColumnLeft,
                    TableEdit.insertColumnLeft),
                tableItem(
                    l10n.formatTableInsertColumnRight,
                    FormatAction.tableInsertColumnRight,
                    TableEdit.insertColumnRight),
                tableItem(l10n.formatTableDeleteColumn,
                    FormatAction.tableDeleteColumn, TableEdit.deleteColumn),
                const Divider(height: 1),
                tableItem(l10n.formatTableAlignLeft,
                    FormatAction.tableAlignLeft, TableEdit.alignLeft),
                tableItem(l10n.formatTableAlignCenter,
                    FormatAction.tableAlignCenter, TableEdit.alignCenter),
                tableItem(l10n.formatTableAlignRight,
                    FormatAction.tableAlignRight, TableEdit.alignRight),
                tableItem(l10n.formatTableAlignNone,
                    FormatAction.tableAlignNone, TableEdit.alignNone),
                const Divider(height: 1),
                tableItem(l10n.formatTableTidy, FormatAction.tableTidy,
                    TableEdit.tidy),
              ],
              child: Text(l10n.formatTableSubmenu),
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
    final isFullScreen = ref.watch(fullScreenProvider);
    final isAlwaysOnTop = ref.watch(alwaysOnTopProvider);

    return SubmenuButton(
      menuChildren: [
        MenuItemButton(
          // Was SystemNavigator.pop, which asks the app to leave the current
          // route — on desktop that is a way to quit, not to minimise.
          child: Text(l10n.windowMinimize),
          onPressed: () => windowManager.minimize(),
        ),
        MenuItemButton(
          shortcut: _shortcut('fullScreen'),
          child: Text(
            isFullScreen ? '${l10n.windowFullScreen} \u2713' : l10n.windowFullScreen,
          ),
          onPressed: () => _toggleFullScreen(ref),
        ),
        MenuItemButton(
          child: Text(
            isAlwaysOnTop
                ? '${l10n.windowAlwaysOnTop} \u2713'
                : l10n.windowAlwaysOnTop,
          ),
          onPressed: () => _toggleAlwaysOnTop(ref),
        ),
      ],
      child: Text(l10n.menuWindow, style: const TextStyle(fontSize: 13)),
    );
  }

  /// Both toggles ask the window what it is doing before flipping it, so a
  /// change made outside the menu cannot leave them inverted.
  static Future<void> _toggleFullScreen(WidgetRef ref) async {
    final next = !await windowManager.isFullScreen();
    await windowManager.setFullScreen(next);
    ref.read(fullScreenProvider.notifier).state = next;
  }

  static Future<void> _toggleAlwaysOnTop(WidgetRef ref) async {
    final next = !await windowManager.isAlwaysOnTop();
    await windowManager.setAlwaysOnTop(next);
    ref.read(alwaysOnTopProvider.notifier).state = next;
  }

  /// Asks GitHub whether there is a newer release and says what it found.
  ///
  /// A check that reports nothing looks like a menu item that does nothing,
  /// so all three outcomes — newer version, up to date, could not reach the
  /// server — are shown.
  static Future<void> _checkForUpdatesNow(
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final result = await UpdateService.checkForUpdate(AppConstants.appVersion);
    final update = result.update;

    if (update != null) {
      // The status bar indicator is the app's existing way of saying this.
      ref.read(updateProvider.notifier).setUpdate(update);
    }

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final message = !result.reachable
        ? l10n.updateCheckFailed
        : update != null
            ? '${l10n.updateAvailable}: ${update.version}'
            : l10n.updateUpToDate;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shows the reader where the startup trace went.
  ///
  /// The installer puts the program under Program Files, which it cannot write
  /// to, so the trace falls back to the config directory — and finding that by
  /// hand means knowing both that `%APPDATA%` is not expanded by PowerShell
  /// and what the version resource calls the company. Someone who has been
  /// asked for a log should not have to work that out.
  static Future<void> _openDiagnosticLog() async {
    final context = navigatorKey.currentContext;
    final path = StartupTrace.logPath;
    if (path == null) {
      if (context == null || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.diagnosticLogMissing)),
      );
      return;
    }
    try {
      if (Platform.isWindows) {
        // Selects the file in Explorer rather than opening the folder, so the
        // one that matters is the one already highlighted.
        await Process.run('explorer.exe', ['/select,', path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
      } else {
        await Process.run('xdg-open', [p.dirname(path)]);
      }
    } catch (e) {
      if (context == null || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fileOperationFailed('$e'))),
      );
    }
  }

  Widget _buildHelpMenu(AppLocalizations l10n, WidgetRef ref) {
    return SubmenuButton(
      menuChildren: [
        MenuItemButton(
          onPressed: _openDiagnosticLog,
          child: Text(l10n.helpOpenDiagnosticLog),
        ),
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
          // Was a link to the releases page: an item called "Check for
          // Updates" that checks nothing. The app already knows how to ask.
          child: Text(l10n.helpCheckUpdates),
          onPressed: () => _checkForUpdatesNow(ref, l10n),
        ),
        MenuItemButton(
          child: Text(l10n.helpChangelog),
          onPressed: () => _launchUrl('https://github.com/marktext-plus/marktext-plus/releases'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: Text(l10n.helpReportBug),
          onPressed: () => _launchUrl('https://github.com/marktext-plus/marktext-plus/issues'),
        ),
        MenuItemButton(
          child: Text(l10n.helpRequestFeature),
          onPressed: () => _launchUrl('https://github.com/marktext-plus/marktext-plus/issues'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: Text(l10n.helpGitHub),
          onPressed: () => _launchUrl('https://github.com/marktext-plus/marktext-plus'),
        ),
      ],
      child: Text(l10n.menuHelp, style: const TextStyle(fontSize: 13)),
    );
  }

  void _exportHtml(WidgetRef ref) async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) return;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: _exportTitle(_l10n?.fileExportHtml ?? 'HTML'),
      fileName: '${p.basenameWithoutExtension(activeTab.fileName)}.html',
      type: FileType.custom,
      allowedExtensions: ['html'],
    );
    if (path == null) return;
    // Diagrams are drawn here and carried into the file, the same way the PDF
    // and Word exports have always done it. Without them the export described
    // each diagram and left a script from a CDN to draw it, so the diagrams
    // were blank for anyone offline — or on a network that does not reach
    // jsdelivr, which is most company networks.
    // Failure is reported by `runExport`, which also says the export is
    // running and where it went. An unwritable path, a folder where a file
    // was expected, a diagram that will not render — said out loud, because
    // this is an `async void` handler and a throw here has nothing to catch
    // it: choosing a filename and pressing Export used to do nothing at all.
    await runExport(p.basename(path), () async {
      final mermaidImages = await _renderMermaidImages(activeTab.content);
      // The tab's own path is what relative image references resolve against.
      await ExportService.exportToHtml(
        activeTab.content,
        path,
        sourcePath: activeTab.filePath,
        enableHtml: ref.read(settingsProvider).enableHtml,
        mermaidImages: mermaidImages,
      );
    });
  }

  void _exportPdf(WidgetRef ref) async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) return;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: _exportTitle(_l10n?.fileExportPdf ?? 'PDF'),
      fileName: '${p.basenameWithoutExtension(activeTab.fileName)}.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (path == null) return;
    await runExport(p.basename(path), () async {
      final mermaidImages = await _renderMermaidImages(activeTab.content);
      await ExportService.exportToPdf(
        activeTab.content,
        path,
        mermaidImages: mermaidImages,
        sourcePath: activeTab.filePath,
        enableHtml: ref.read(settingsProvider).enableHtml,
      );
    });
  }

  /// Hands the document to the system print dialog.
  ///
  /// Through the printing plugin rather than by writing a PDF and opening it:
  /// the dialog's own page setup — printer, paper, range, copies — only
  /// reaches a document that is laid out for it.
  void _print(WidgetRef ref) async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) return;
    try {
      final mermaidImages = await _renderMermaidImages(activeTab.content);
      final enableHtml = ref.read(settingsProvider).enableHtml;
      await Printing.layoutPdf(
        name: p.basenameWithoutExtension(activeTab.fileName),
        onLayout: (_) async => Uint8List.fromList(
          await ExportService.pdfBytes(
            activeTab.content,
            mermaidImages: mermaidImages,
            sourcePath: activeTab.filePath,
            enableHtml: enableHtml,
          ),
        ),
      );
    } catch (e) {
      // Includes "there is no printing service here", which a Linux box
      // without CUPS answers with. Better said than swallowed.
      reportExportFailure(e);
    }
  }

  void _exportWord(WidgetRef ref) async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) return;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: _exportTitle(_l10n?.fileExportWord ?? 'Word'),
      fileName: '${p.basenameWithoutExtension(activeTab.fileName)}.docx',
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );
    if (path == null) return;
    await runExport(p.basename(path), () async {
      final mermaidImages = await _renderMermaidImages(activeTab.content);
      await ExportService.exportToDocx(
        activeTab.content,
        path,
        mermaidImages: mermaidImages,
        sourcePath: activeTab.filePath,
        enableHtml: ref.read(settingsProvider).enableHtml,
      );
    });
  }

  Future<Map<String, Uint8List>> _renderMermaidImages(String markdown) async {
    final parser = MarkdownParser();
    final ast = parser.parse(markdown);
    final images = <String, Uint8List>{};

    // Keyed by the diagram itself, and found by the same walk the export
    // uses. Both sides used to count blocks and index into this map, which
    // held only while they counted the same things — and both counted only
    // the top level, so a diagram under a numbered step reached the export
    // with no picture at all.
    for (final node in MarkdownParser.walk(ast)) {
      if (node is CodeBlockNode &&
          MermaidParser.handlesLanguage(node.language)) {
        if (images.containsKey(node.code)) continue;
        try {
          final bytes = await _renderMermaidToImage(node.code);
          if (bytes != null) images[node.code] = bytes;
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
          // No width: this is drawn off screen for an export, so it should be
          // the whole diagram at its own size. Forcing 800 meant a diagram
          // wider than that was laid out at its full width inside a box that
          // was not — and the capture kept only the left 800 pixels. Every
          // export of a wide diagram was missing its right-hand side, in the
          // PDF, the Word file and the HTML alike.
          child: Container(
            color: Colors.white,
            child: MermaidDiagram(
              code: code,
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
    } catch (_) {
      // A diagram that will not render leaves `result` null, and the caller
      // simply leaves that one out of the export rather than failing the
      // whole document.
    }

    entry.remove();
    return result;
  }

  void _newWindow() async {
    await PlatformUtils.launchNewWindow();
  }

  void _launchUrl(String url) async {
    // `Uri.parse` throws on a malformed address and `launchUrl` throws when
    // the desktop has no handler registered — a machine with no browser set
    // answers that way. The preview's own link opening was given this
    // treatment; the Help menu's was not, so its entries did nothing at all
    // there.
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) throw FormatException('not a URI', url);
      if (!await launchUrl(uri)) throw StateError('no handler for $url');
    } catch (e) {
      reportOpenFailure(e);
    }
  }

  /// "Export" and the format, in the user's language.
  ///
  /// The two halves are separate menu entries already — a submenu labelled
  /// Export holding HTML, PDF and Word — so no new copy is needed.
  static String _exportTitle(String format) {
    final export = _l10n?.fileExport ?? 'Export';
    return '$export $format';
  }

  Widget _buildRecentFilesMenu(
    BuildContext context,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
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
                    onPressed: () =>
                        _openRecentFile(context, ref, filePath),
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

  void _openRecentFile(
    BuildContext context,
    WidgetRef ref,
    String filePath,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) {
      // Returning quietly left the entry in the list and the reader clicking
      // it again. A recent file that has been moved or deleted is the
      // commonest thing to find in this menu, and the list is the one place
      // that can put it right.
      final settings = ref.read(settingsProvider.notifier);
      final remaining = [
        ...ref.read(settingsProvider).recentFiles.where((p) => p != filePath),
      ];
      await settings.updateConfig((c) => c.copyWith(recentFiles: remaining));
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.recentFileMissing)),
      );
      return;
    }
    try {
      final opened = await FileService().readFileWithLineEnding(filePath);
      final tab = TabInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        filePath: filePath,
        fileName: p.basename(filePath),
        content: opened.content,
        lineEnding: opened.lineEnding,
        encoding: opened.encoding,
        diskStamp: opened.stamp,
      );
      ref.read(tabProvider.notifier).addTab(tab);
      ref.read(settingsProvider.notifier).addRecentFile(filePath);
    } catch (e) {
      // The existence check above passed, so this is a file that is there and
      // cannot be read — which needs saying just as much.
      reportOpenFailure(e);
    }
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
          icon: const Icon(Icons.zoom_out),
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
          icon: const Icon(Icons.zoom_in),
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
