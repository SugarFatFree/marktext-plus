import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;
import '../../core/config/app_config.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/editor_provider.dart';
import '../../providers/file_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_provider.dart';
import '../../models/tab_info.dart';
import '../../services/command_registry.dart';
import '../../utils/platform_utils.dart';
import '../widgets/app_menu_bar.dart';
import '../widgets/side_bar.dart';
import '../widgets/editor_tab_bar.dart';
import '../widgets/status_bar.dart';
import '../widgets/find_replace_bar.dart';
import '../widgets/command_palette.dart';
import '../editor/source_editor.dart';
import '../editor/markdown_renderer.dart';
import '../editor/split_editor.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _startupFilesProcessed = false;

  void _registerCommands(AppLocalizations l10n) {
    final registry = CommandRegistry.instance;
    registry.clear();

    // Format actions
    final formatLabels = {
      FormatAction.bold: l10n.formatBold,
      FormatAction.italic: l10n.formatItalic,
      FormatAction.strikethrough: l10n.formatStrikethrough,
      FormatAction.heading1: l10n.formatHeading(1),
      FormatAction.heading2: l10n.formatHeading(2),
      FormatAction.heading3: l10n.formatHeading(3),
      FormatAction.heading4: l10n.formatHeading(4),
      FormatAction.heading5: l10n.formatHeading(5),
      FormatAction.heading6: l10n.formatHeading(6),
      FormatAction.orderedList: l10n.formatOrderedList,
      FormatAction.unorderedList: l10n.formatUnorderedList,
      FormatAction.taskList: l10n.formatTaskList,
      FormatAction.codeBlock: l10n.formatCodeBlock,
      FormatAction.quoteBlock: l10n.formatQuoteBlock,
      FormatAction.mathBlock: l10n.formatMathBlock,
      FormatAction.table: l10n.formatTable,
      FormatAction.link: l10n.formatLink,
      FormatAction.image: l10n.formatImage,
      FormatAction.horizontalRule: l10n.formatHorizontalRule,
    };

    for (final entry in formatLabels.entries) {
      registry.register(Command(
        id: 'format.${entry.key.name}',
        label: l10n.commandFormatLabel(entry.value),
        description: l10n.commandFormatDesc(entry.value),
        execute: () => ref.read(editorProvider.notifier).applyFormat(entry.key),
      ));
    }

    // File operations
    registry.registerAll([
      Command(
        id: 'file.new',
        label: l10n.commandNewFile,
        description: l10n.commandNewFileDesc,
        execute: () {
          final tab = TabInfo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
          );
          ref.read(tabProvider.notifier).addTab(tab);
        },
      ),
      Command(
        id: 'file.save',
        label: l10n.commandSave,
        description: l10n.commandSaveDesc,
        execute: () => _saveCurrentFile(),
      ),
    ]);

    // View commands
    registry.registerAll([
      Command(
        id: 'view.source',
        label: l10n.commandSourceMode,
        description: l10n.commandSourceModeDesc,
        execute: () =>
            ref.read(settingsProvider.notifier).setEditMode(EditMode.source),
      ),
      Command(
        id: 'view.preview',
        label: l10n.commandPreviewMode,
        description: l10n.commandPreviewModeDesc,
        execute: () =>
            ref.read(settingsProvider.notifier).setEditMode(EditMode.preview),
      ),
      Command(
        id: 'view.split',
        label: l10n.commandSplitMode,
        description: l10n.commandSplitModeDesc,
        execute: () =>
            ref.read(settingsProvider.notifier).setEditMode(EditMode.split),
      ),
      Command(
        id: 'view.focusMode',
        label: l10n.commandToggleFocusMode,
        description: l10n.commandToggleFocusModeDesc,
        execute: () => ref.read(settingsProvider.notifier).toggleFocusMode(),
      ),
      Command(
        id: 'view.typewriterMode',
        label: l10n.commandToggleTypewriterMode,
        description: l10n.commandToggleTypewriterModeDesc,
        execute: () =>
            ref.read(settingsProvider.notifier).toggleTypewriterMode(),
      ),
      Command(
        id: 'view.sidebar',
        label: l10n.commandToggleSidebar,
        description: l10n.commandToggleSidebarDesc,
        execute: () => ref.read(settingsProvider.notifier).toggleSideBar(),
      ),
      Command(
        id: 'view.tabbar',
        label: l10n.commandToggleTabBar,
        description: l10n.commandToggleTabBarDesc,
        execute: () => ref.read(settingsProvider.notifier).toggleTabBar(),
      ),
    ]);
  }

  void _saveCurrentFile() async {
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null || activeTab.filePath == null) return;
    await File(activeTab.filePath!).writeAsString(activeTab.content);
    ref.read(tabProvider.notifier).markSaved(activeTab.id);
  }

  void _openStartupFiles() async {
    if (_startupFilesProcessed) return;
    _startupFilesProcessed = true;

    final files = ref.read(startupFilesProvider);
    if (files.isEmpty) return;

    final config = ref.read(settingsProvider);
    if (config.fileOpenBehavior == FileOpenBehavior.notSet && mounted) {
      final choice = await _showFileOpenBehaviorDialog();
      if (choice != null) {
        ref.read(settingsProvider.notifier).updateConfig(
          (c) => c.copyWith(fileOpenBehavior: choice),
        );
      }
    }

    for (final path in files) {
      try {
        final content = File(path).readAsStringSync();
        final tab = TabInfo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          filePath: path,
          fileName: p.basename(path),
          content: content,
        );
        ref.read(tabProvider.notifier).addTab(tab);
        ref.read(settingsProvider.notifier).addRecentFile(path);
      } catch (_) {}
    }
  }

  Future<FileOpenBehavior?> _showFileOpenBehaviorDialog() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<FileOpenBehavior>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.fileOpenBehaviorTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.fileOpenBehaviorMessage),
            const SizedBox(height: 16),
            _buildRadioOption(
              ctx,
              l10n.fileOpenBehaviorNewWindow,
              l10n.fileOpenBehaviorNewWindowDesc,
              FileOpenBehavior.newWindow,
            ),
            _buildRadioOption(
              ctx,
              l10n.fileOpenBehaviorExistingWindow,
              l10n.fileOpenBehaviorExistingWindowDesc,
              FileOpenBehavior.existingWindow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(
    BuildContext ctx,
    String title,
    String subtitle,
    FileOpenBehavior value,
  ) {
    return InkWell(
      onTap: () => Navigator.of(ctx).pop(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Radio<FileOpenBehavior>(
              value: value,
              groupValue: null,
              onChanged: (_) => Navigator.of(ctx).pop(value),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDrop(DropDoneDetails details) async {
    final allowedExtensions = {'.md', '.markdown', '.txt'};

    for (final file in details.files) {
      final path = file.path;

      // Check if it's a directory
      final entity = FileSystemEntity.typeSync(path);
      if (entity == FileSystemEntityType.directory) {
        // Open the folder in the file tree
        await ref.read(fileProvider.notifier).loadDirectory(path);
        continue;
      }

      // Handle files
      final ext = p.extension(path).toLowerCase();
      if (!allowedExtensions.contains(ext)) continue;

      try {
        // Open the file from its original location (don't copy)
        final content = await File(path).readAsString();
        final tab = TabInfo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          filePath: path,
          fileName: p.basename(path),
          content: content,
        );
        ref.read(tabProvider.notifier).addTab(tab);
        ref.read(settingsProvider.notifier).addRecentFile(path);
      } catch (_) {
        // Skip files that can't be read
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(settingsProvider);
    final editorState = ref.watch(editorProvider);
    final l10n = AppLocalizations.of(context)!;

    _registerCommands(l10n);
    _openStartupFiles();

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        final isCtrl = PlatformUtils.isMacOS
            ? HardwareKeyboard.instance.isMetaPressed
            : HardwareKeyboard.instance.isControlPressed;

        // Ctrl+P / Cmd+P -> command palette
        if (event.logicalKey == LogicalKeyboardKey.keyP && isCtrl) {
          CommandPalette.show(context);
          return KeyEventResult.handled;
        }

        // Ctrl+F / Cmd+F -> toggle find/replace
        if (event.logicalKey == LogicalKeyboardKey.keyF && isCtrl) {
          ref.read(editorProvider.notifier).toggleFindReplace();
          return KeyEventResult.handled;
        }

        // Ctrl+H / Cmd+H -> toggle find/replace
        if (event.logicalKey == LogicalKeyboardKey.keyH && isCtrl) {
          ref.read(editorProvider.notifier).toggleFindReplace();
          return KeyEventResult.handled;
        }

        if (config.focusMode && event.logicalKey == LogicalKeyboardKey.escape) {
          ref.read(settingsProvider.notifier).toggleFocusMode();
          return KeyEventResult.handled;
        }
        if (editorState.showFindReplace && event.logicalKey == LogicalKeyboardKey.escape) {
          ref.read(editorProvider.notifier).hideFindReplace();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        body: DropTarget(
          onDragDone: _handleDrop,
          child: Column(
            children: [
              if (!config.focusMode) const AppMenuBar(),
              Expanded(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: config.sideBarVisible && !config.focusMode ? 280 : 0,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(),
                      child: config.sideBarVisible && !config.focusMode
                          ? const SideBar()
                          : null,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: config.tabBarVisible && !config.focusMode
                                ? const EditorTabBar()
                                : const SizedBox.shrink(),
                          ),
                          if (editorState.showFindReplace)
                            Builder(
                              builder: (context) {
                                final controller =
                                    ref.read(editorProvider.notifier).controller;
                                final activeTab = ref.watch(activeTabProvider);
                                final isSplit = config.editMode == EditMode.split;
                                if (isSplit && controller != null && activeTab != null) {
                                  return FindReplaceBar(
                                    textController: controller,
                                    rawContent: activeTab.content,
                                    isSplitMode: true,
                                  );
                                } else if (controller != null) {
                                  return FindReplaceBar(
                                      textController: controller);
                                } else if (activeTab != null) {
                                  return FindReplaceBar(
                                      rawContent: activeTab.content);
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          Expanded(
                            child: _buildEditorArea(config.editMode),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!config.focusMode) const StatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorArea(EditMode editMode) {
    final activeTab = ref.watch(activeTabProvider);
    if (activeTab == null) {
      final l10n = AppLocalizations.of(context)!;
      final tokens = AppTheme.getTokens(ref.watch(settingsProvider).themeName);
      final isMac = PlatformUtils.isMacOS;
      final mod = isMac ? '\u2318' : 'Ctrl';
      return Center(
        child: Opacity(
          opacity: 0.6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: 0.3,
                child: Image.asset('assets/app_icon.png', width: 80, height: 80),
              ),
              const SizedBox(height: 16),
              Text(
                'MarkText Plus',
                style: TextStyle(fontSize: 24, color: tokens.colorTextMuted),
              ),
              const SizedBox(height: 24),
              Text(
                '$mod+N    ${l10n.welcomeNewFile}',
                style: TextStyle(fontSize: 13, color: tokens.colorTextMuted),
              ),
              const SizedBox(height: 6),
              Text(
                '$mod+O    ${l10n.welcomeOpenFile}',
                style: TextStyle(fontSize: 13, color: tokens.colorTextMuted),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.welcomeDragHint,
                style: TextStyle(fontSize: 13, color: tokens.colorTextMuted),
              ),
            ],
          ),
        ),
      );
    }
    Widget editor;
    if (activeTab.isLoading) {
      final tokens = AppTheme.getTokens(ref.watch(settingsProvider).themeName);
      editor = Center(
        key: ValueKey('loading_${activeTab.id}'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(tokens.colorAccent),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              activeTab.fileName,
              style: TextStyle(
                fontSize: 13,
                color: tokens.colorTextMuted,
              ),
            ),
          ],
        ),
      );
    } else {
      final content = activeTab.content;

    void onContentChanged(String newContent) {
      ref.read(tabProvider.notifier).updateContent(activeTab.id, newContent);
    }

    // Use ValueKey so the editor rebuilds when switching tabs
    switch (editMode) {
      case EditMode.source:
        editor = SourceEditor(
          key: ValueKey('source_${activeTab.id}'),
          initialContent: content,
          onChanged: onContentChanged,
        );
      case EditMode.preview:
        editor = MarkdownRenderer(
          key: ValueKey('preview_${activeTab.id}'),
          markdown: content,
        );
      case EditMode.split:
        editor = SplitEditor(
          key: ValueKey('split_${activeTab.id}'),
          initialContent: content,
          onChanged: onContentChanged,
        );
    }
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 80),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: editor,
    );
  }
}
