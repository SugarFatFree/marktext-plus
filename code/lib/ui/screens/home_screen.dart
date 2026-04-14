import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../providers/editor_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_provider.dart';
import '../widgets/app_menu_bar.dart';
import '../widgets/side_bar.dart';
import '../widgets/editor_tab_bar.dart';
import '../widgets/status_bar.dart';
import '../widgets/find_replace_bar.dart';
import '../editor/source_editor.dart';
import '../editor/markdown_renderer.dart';
import '../editor/split_editor.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(settingsProvider);
    final editorState = ref.watch(editorProvider);

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
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
        body: Column(
          children: [
            if (!config.focusMode) const AppMenuBar(),
            Expanded(
              child: Row(
                children: [
                  if (config.sideBarVisible && !config.focusMode) const SideBar(),
                  Expanded(
                    child: Column(
                      children: [
                        if (config.tabBarVisible && !config.focusMode) const EditorTabBar(),
                        if (editorState.showFindReplace)
                          Builder(
                            builder: (context) {
                              final controller = ref.read(editorProvider.notifier).controller;
                              if (controller != null) {
                                return FindReplaceBar(textController: controller);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        Expanded(
                          child: _buildEditorArea(config.editMode, ref),
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
    );
  }

  Widget _buildEditorArea(EditMode editMode, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);
    final content = activeTab?.content ?? '';

    void onContentChanged(String newContent) {
      if (activeTab != null) {
        ref.read(tabProvider.notifier).updateContent(activeTab.id, newContent);
      }
    }

    switch (editMode) {
      case EditMode.source:
        return SourceEditor(
          initialContent: content,
          onChanged: onContentChanged,
        );
      case EditMode.preview:
        return MarkdownRenderer(markdown: content);
      case EditMode.split:
        return SplitEditor(
          initialContent: content,
          onChanged: onContentChanged,
        );
    }
  }
}
