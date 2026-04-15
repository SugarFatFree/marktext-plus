import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;
import '../../core/config/app_config.dart';
import '../../providers/editor_provider.dart';
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
  bool _commandsRegistered = false;

  void _registerCommands() {
    if (_commandsRegistered) return;
    _commandsRegistered = true;

    final registry = CommandRegistry.instance;
    registry.clear();

    // Format actions
    final formatLabels = {
      FormatAction.bold: 'Bold',
      FormatAction.italic: 'Italic',
      FormatAction.strikethrough: 'Strikethrough',
      FormatAction.heading1: 'Heading 1',
      FormatAction.heading2: 'Heading 2',
      FormatAction.heading3: 'Heading 3',
      FormatAction.heading4: 'Heading 4',
      FormatAction.heading5: 'Heading 5',
      FormatAction.heading6: 'Heading 6',
      FormatAction.orderedList: 'Ordered List',
      FormatAction.unorderedList: 'Unordered List',
      FormatAction.taskList: 'Task List',
      FormatAction.codeBlock: 'Code Block',
      FormatAction.quoteBlock: 'Quote Block',
      FormatAction.mathBlock: 'Math Block',
      FormatAction.table: 'Table',
      FormatAction.link: 'Link',
      FormatAction.image: 'Image',
      FormatAction.horizontalRule: 'Horizontal Rule',
    };

    for (final entry in formatLabels.entries) {
      registry.register(Command(
        id: 'format.${entry.key.name}',
        label: 'Format: ${entry.value}',
        description: 'Apply ${entry.value} formatting',
        execute: () => ref.read(editorProvider.notifier).applyFormat(entry.key),
      ));
    }

    // File operations
    registry.registerAll([
      Command(
        id: 'file.new',
        label: 'New File',
        description: 'Create a new untitled file',
        execute: () {
          final tab = TabInfo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
          );
          ref.read(tabProvider.notifier).addTab(tab);
        },
      ),
      Command(
        id: 'file.save',
        label: 'Save',
        description: 'Save the current file',
        execute: () => _saveCurrentFile(),
      ),
    ]);

    // View commands
    registry.registerAll([
      Command(
        id: 'view.source',
        label: 'Source Mode',
        description: 'Switch to source code editing mode',
        execute: () =>
            ref.read(settingsProvider.notifier).setEditMode(EditMode.source),
      ),
      Command(
        id: 'view.preview',
        label: 'Preview Mode',
        description: 'Switch to preview mode',
        execute: () =>
            ref.read(settingsProvider.notifier).setEditMode(EditMode.preview),
      ),
      Command(
        id: 'view.split',
        label: 'Split Mode',
        description: 'Switch to split editing mode',
        execute: () =>
            ref.read(settingsProvider.notifier).setEditMode(EditMode.split),
      ),
      Command(
        id: 'view.focusMode',
        label: 'Toggle Focus Mode',
        description: 'Toggle distraction-free focus mode',
        execute: () => ref.read(settingsProvider.notifier).toggleFocusMode(),
      ),
      Command(
        id: 'view.typewriterMode',
        label: 'Toggle Typewriter Mode',
        description: 'Toggle typewriter scrolling mode',
        execute: () =>
            ref.read(settingsProvider.notifier).toggleTypewriterMode(),
      ),
      Command(
        id: 'view.sidebar',
        label: 'Toggle Sidebar',
        description: 'Show or hide the sidebar',
        execute: () => ref.read(settingsProvider.notifier).toggleSideBar(),
      ),
      Command(
        id: 'view.tabbar',
        label: 'Toggle Tab Bar',
        description: 'Show or hide the tab bar',
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

  void _handleDrop(DropDoneDetails details) async {
    final allowedExtensions = {'.md', '.markdown', '.txt'};
    for (final file in details.files) {
      final path = file.path;
      final ext = p.extension(path).toLowerCase();
      if (!allowedExtensions.contains(ext)) continue;
      try {
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

    _registerCommands();

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
