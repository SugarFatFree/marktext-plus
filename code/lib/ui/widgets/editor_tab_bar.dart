import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../app.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tab_info.dart';
import '../../providers/settings_provider.dart';
import '../../utils/file_reveal.dart';
import '../../utils/file_utils.dart';
import '../../providers/tab_provider.dart';
import '../../services/file_service.dart';

/// What the user chose when asked about unsaved work.
enum _UnsavedChoice { cancel, discard, save }

class EditorTabBar extends ConsumerWidget {
  const EditorTabBar({super.key});

  /// Closes [tab], asking first when it has unsaved changes.
  ///
  /// Closing used to discard the tab outright. That is survivable for a file
  /// on disk, which auto-save has usually written by then, but a new document
  /// has no path — auto-save skips it entirely — so its contents were lost for
  /// good with nothing asked and nothing said.
  ///
  /// Static so the File menu's Close Tab can go through the same confirmation
  /// rather than growing a second, subtly different copy of it.
  static Future<void> closeTab(
    BuildContext context,
    WidgetRef ref,
    TabInfo tab,
  ) async {
    if (!tab.isModified) {
      ref.read(tabProvider.notifier).removeTab(tab.id);
      return;
    }

    final choice = await _askAboutUnsavedChanges(context, tab);
    if (choice == null || choice == _UnsavedChoice.cancel) return;

    if (choice == _UnsavedChoice.save) {
      final saved = await saveTab(ref, tab);
      // Abandoning the save location prompt means abandoning the close too.
      if (!saved) return;
    }

    ref.read(tabProvider.notifier).removeTab(tab.id);
  }

  static Future<_UnsavedChoice?> _askAboutUnsavedChanges(
    BuildContext context,
    TabInfo tab,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<_UnsavedChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text('${tab.fileName}\n\n${l10n.unsavedChangesMessage}'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_UnsavedChoice.cancel),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_UnsavedChoice.discard),
            child: Text(l10n.dontSave),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_UnsavedChoice.save),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  /// Writes [tab] to disk, prompting for a location if it has never had one.
  ///
  /// Returns false when the user cancels that prompt or the write fails.
  static Future<bool> saveTab(WidgetRef ref, TabInfo tab) async {
    var path = tab.filePath;

    if (path == null) {
      // The picker's title is drawn by the operating system, so it takes a
      // string; this call site is static and reaches the localisations
      // through the navigator, falling back to English if it has no context.
      final context = navigatorKey.currentContext;
      path = await FilePicker.platform.saveFile(
        dialogTitle: context == null
            ? 'Save As'
            : AppLocalizations.of(context)!.fileSaveAs,
        fileName: tab.fileName,
        type: FileType.custom,
        allowedExtensions: FileUtils.markdownExtensions,
      );
      if (path == null) return false;
    }

    try {
      if (tab.filePath == path) {
        // An existing document, so the same check the menu's Save makes:
        // something else may have rewritten it while this tab was open, and
        // closing is not a reason to write over that. A path just chosen in
        // the picker has no baseline to compare against and the picker has
        // already asked about replacing anything there.
        await FileService.saveDocumentIfUnchanged(
          path,
          tab.content,
          expect: tab.diskStamp,
          lineEnding: tab.lineEnding,
          encoding: tab.encoding,
        );
      } else {
        // Save As: the path was just chosen in the picker, which has already
        // asked about replacing anything there, and there is no baseline to
        // compare a file this tab has never read. Written unconditionally on
        // purpose.
        await FileService.saveDocument(path, tab.content,
            lineEnding: tab.lineEnding, encoding: tab.encoding);
      }
    } on FileChangedOnDiskException {
      // The tab stays open and stays modified, which is what keeps the
      // reader's work: closing here would discard it in favour of a version
      // they were never shown. The status bar then carries the same banner
      // auto-save raises, and Ctrl+S offers the three ways out.
      ref.read(tabProvider.notifier).markDiskConflict(tab.id);
      reportDiskConflict(tab.fileName);
      return false;
    } catch (e) {
      // Closing on a failed write would lose the content the save was meant
      // to protect. The reader is told why the tab refused to close.
      reportSaveFailure(e);
      return false;
    }

    // The same three steps the Save As in the menu takes. That one was fixed
    // to rebind the tab and remember the path; this copy of the branch was
    // not, so a document saved through the close prompt stayed untitled and
    // never reached the recent files list.
    if (tab.filePath != path) {
      ref
          .read(tabProvider.notifier)
          .updateTabPath(tab.id, path, p.basename(path));
      ref.read(settingsProvider.notifier).addRecentFile(path);
    }
    await ref.read(tabProvider.notifier).markSaved(tab.id);
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabProvider);
    final tabs = tabState.tabs;
    final activeTabId = tabState.activeTabId;
    final tokens = AppTheme.getTokens(ref.watch(settingsProvider).themeName);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        border: Border(
          bottom: BorderSide(color: tokens.colorBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              itemCount: tabs.length,
              onReorderItem: (oldIndex, newIndex) {
                ref.read(tabProvider.notifier).reorderTabs(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isActive = tab.id == activeTabId;
                return ReorderableDragStartListener(
                  key: ValueKey(tab.id),
                  index: index,
                  child: _TabItem(
                    tab: tab,
                    isActive: isActive,
                    tokens: tokens,
                    onTap: () => ref.read(tabProvider.notifier).setActiveTab(tab.id),
                    onClose: () => closeTab(context, ref, tab),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, size: 16, color: tokens.colorTextMuted),
            onPressed: () {
              final newTab = TabInfo(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
              );
              ref.read(tabProvider.notifier).addTab(newTab);
            },
            tooltip: AppLocalizations.of(context)!.newTab,
          ),
        ],
      ),
    );
  }
}

class _TabItem extends ConsumerStatefulWidget {
  final TabInfo tab;
  final bool isActive;
  final AppThemeTokens tokens;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    required this.tab,
    required this.isActive,
    required this.tokens,
    required this.onTap,
    required this.onClose,
  });

  @override
  ConsumerState<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends ConsumerState<_TabItem> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isCloseHovered = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (_isClosing) return;
    setState(() => _isClosing = true);
    // Immediately call onClose to switch content, while tab fades out
    widget.onClose();
    _fadeController.reverse();
  }

  void _showContextMenu(BuildContext context, Offset position) async {
    final l10n = AppLocalizations.of(context)!;
    final tab = widget.tab;
    final hasFilePath = tab.filePath != null;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(value: 'close', height: 36, child: Text(l10n.closeFile, style: const TextStyle(fontWeight: FontWeight.normal))),
        PopupMenuItem(value: 'close_others', height: 36, child: Text(l10n.closeOtherTabs, style: const TextStyle(fontWeight: FontWeight.normal))),
        PopupMenuItem(value: 'close_right', height: 36, child: Text(l10n.closeTabsToRight, style: const TextStyle(fontWeight: FontWeight.normal))),
        PopupMenuItem(value: 'close_all', height: 36, child: Text(l10n.closeAllTabs, style: const TextStyle(fontWeight: FontWeight.normal))),
        if (hasFilePath) ...[
          const PopupMenuDivider(),
          PopupMenuItem(value: 'copy_name', height: 36, child: Text(l10n.copyFileName, style: const TextStyle(fontWeight: FontWeight.normal))),
          PopupMenuItem(value: 'copy_path', height: 36, child: Text(l10n.copyFilePath, style: const TextStyle(fontWeight: FontWeight.normal))),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'reveal', height: 36, child: Text(l10n.revealInExplorer, style: const TextStyle(fontWeight: FontWeight.normal))),
        ],
      ],
    );
    if (result == null || !mounted) return;

    switch (result) {
      case 'close':
        widget.onClose();
      case 'close_others':
        await _closeMany(
          ref.read(tabProvider).tabs.where((t) => t.id != tab.id).toList(),
          () => ref.read(tabProvider.notifier).closeOtherTabs(tab.id),
        );
      case 'close_right':
        await _closeMany(
          _tabsRightOf(ref, tab.id),
          () => ref.read(tabProvider.notifier).closeTabsToRight(tab.id),
        );
      case 'close_all':
        await _closeMany(
          ref.read(tabProvider).tabs.toList(),
          () => ref.read(tabProvider.notifier).closeAllTabs(),
        );
      case 'copy_name':
        await Clipboard.setData(ClipboardData(text: tab.fileName));
      case 'copy_path':
        if (tab.filePath != null) {
          await Clipboard.setData(ClipboardData(text: tab.filePath!));
        }
      case 'reveal':
        if (tab.filePath != null) {
          await FileReveal.selectFile(tab.filePath!);
        }
    }
  }

  List<TabInfo> _tabsRightOf(WidgetRef ref, String id) {
    final tabs = ref.read(tabProvider).tabs;
    final index = tabs.indexWhere((t) => t.id == id);
    return index < 0 ? const [] : tabs.sublist(index + 1);
  }

  /// Runs [close] after asking about any unsaved tabs among [closing].
  ///
  /// Closing several tabs at once used to discard all of them without asking,
  /// which loses more than the single-tab case it mirrors.
  Future<void> _closeMany(List<TabInfo> closing, void Function() close) async {
    final unsaved = closing.where((t) => t.isModified).toList();
    if (unsaved.isEmpty) {
      close();
      return;
    }

    final choice = await _askAboutUnsavedTabs(unsaved);
    if (choice == null || choice == _UnsavedChoice.cancel) return;

    if (choice == _UnsavedChoice.save) {
      for (final tab in unsaved) {
        final saved = await EditorTabBar.saveTab(ref, tab);
        // Abandoning one save abandons the whole operation: closing the rest
        // would still lose this tab's work.
        if (!saved) return;
      }
    }

    close();
  }

  Future<_UnsavedChoice?> _askAboutUnsavedTabs(List<TabInfo> unsaved) {
    final l10n = AppLocalizations.of(context)!;
    // Naming the files matters here: with several tabs the user cannot
    // otherwise tell what they are about to discard.
    const maxListed = 5;
    final names = unsaved.take(maxListed).map((t) => t.fileName).join('\n');
    final extra = unsaved.length > maxListed
        ? '\n… ${unsaved.length - maxListed}'
        : '';

    return showDialog<_UnsavedChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text('$names$extra\n\n${l10n.unsavedChangesMessage}'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_UnsavedChoice.cancel),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_UnsavedChoice.discard),
            child: Text(l10n.dontSave),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_UnsavedChoice.save),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizeTransition(
        sizeFactor: _fadeAnimation,
        axis: Axis.horizontal,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            onSecondaryTapUp: (details) {
              _showContextMenu(context, details.globalPosition);
            },
            child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.tokens.colorBg
                : _isHovered
                    ? widget.tokens.colorSurfaceHover
                    : Colors.transparent,
            borderRadius: widget.isActive
                ? const BorderRadius.vertical(top: Radius.circular(8))
                : BorderRadius.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.tab.isModified)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: widget.tokens.colorAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isActive ? widget.tokens.colorText : widget.tokens.colorTextMuted,
                  fontWeight: FontWeight.normal,
                ),
                child: Text(widget.tab.fileName),
              ),
              if (widget.isActive || _isHovered) ...[
                const SizedBox(width: 8),
                MouseRegion(
                  onEnter: (_) => setState(() => _isCloseHovered = true),
                  onExit: (_) => setState(() => _isCloseHovered = false),
                  child: GestureDetector(
                    onTap: _handleClose,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _isCloseHovered
                            ? widget.tokens.colorAccent.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: _isCloseHovered
                            ? widget.tokens.colorAccent
                            : widget.tokens.colorTextMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }
}
