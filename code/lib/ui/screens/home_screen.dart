import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../providers/settings_provider.dart';
import '../widgets/app_menu_bar.dart';
import '../widgets/side_bar.dart';
import '../widgets/editor_tab_bar.dart';
import '../widgets/status_bar.dart';

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
                        child: _buildEditorArea(config.editMode),
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

  Widget _buildEditorArea(EditMode editMode) {
    final label = switch (editMode) {
      EditMode.source => 'Source Editor',
      EditMode.preview => 'Preview',
      EditMode.split => 'Split View',
    };
    return Center(
      child: Text(label, style: const TextStyle(fontSize: 18)),
    );
  }
}
