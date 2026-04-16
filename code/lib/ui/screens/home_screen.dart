import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;
import '../../core/config/app_config.dart';
import '../../core/i18n/l10n/app_localizations.dart';
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

  void _openStartupFiles() {
    if (_startupFilesProcessed) return;
    _startupFilesProcessed = true;

    final files = ref.read(startupFilesProvider);
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
        // Ctrl+P / Cmd+P -> command palette
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyP &&
            (PlatformUtils.isMacOS
                ? HardwareKeyboard.instance.isMetaPressed
                : HardwareKeyboard.instance.isControlPressed)) {
          CommandPalette.show(context);
          return KeyEventResult.handled;
        }
        if (config.focusMode &&
            event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          ref.read(settingsProvider.notifier).toggleFocusMode();
          return KeyEventResult.handled;
        }
        if (editorState.showFindReplace &&
            event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
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
                                if (controller != null) {
                                  return FindReplaceBar(
                                      textController: controller);
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
      return const Center(child: Text(''));
    }
    final content = activeTab.content;

    void onContentChanged(String newContent) {
      ref.read(tabProvider.notifier).updateContent(activeTab.id, newContent);
    }

    // Use ValueKey so the editor rebuilds when switching tabs
    switch (editMode) {
      case EditMode.source:
        return SourceEditor(
          key: ValueKey(activeTab.id),
          initialContent: content,
          onChanged: onContentChanged,
        );
      case EditMode.preview:
        return MarkdownRenderer(
          key: ValueKey(activeTab.id),
          markdown: content,
        );
      case EditMode.split:
        return SplitEditor(
          key: ValueKey(activeTab.id),
          initialContent: content,
          onChanged: onContentChanged,
        );
    }
  }
}
