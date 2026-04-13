import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_provider.dart';
import '../widgets/app_menu_bar.dart';
import '../widgets/side_bar.dart';
import '../widgets/editor_tab_bar.dart';
import '../widgets/status_bar.dart';
import '../editor/source_editor.dart';
import '../editor/markdown_renderer.dart';
import '../editor/split_editor.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(settingsProvider);

    return Scaffold(
      body: Column(
        children: [
          const AppMenuBar(),
          Expanded(
            child: Row(
              children: [
                if (config.sideBarVisible) const SideBar(),
                Expanded(
                  child: Column(
                    children: [
                      if (config.tabBarVisible) const EditorTabBar(),
                      Expanded(
                        child: _buildEditorArea(config.editMode, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const StatusBar(),
        ],
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
