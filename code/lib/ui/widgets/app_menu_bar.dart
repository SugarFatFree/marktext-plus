import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../providers/settings_provider.dart';
import '../../utils/platform_utils.dart';

class AppMenuBar extends ConsumerWidget {
  const AppMenuBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuBar(
      children: [
        _buildFileMenu(context, ref),
        _buildEditMenu(context, ref),
        _buildViewMenu(context, ref),
        _buildFormatMenu(context, ref),
        _buildWindowMenu(context, ref),
        _buildHelpMenu(context, ref),
      ],
    );
  }

  Widget _buildFileMenu(BuildContext context, WidgetRef ref) {
    return SubmenuButton(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.insert_drive_file),
          child: const Text('New File'),
          onPressed: () {},
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.window),
          child: const Text('New Window'),
          onPressed: () {},
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.folder_open),
          onPressed: () {},
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyO,
            control: !PlatformUtils.isMacOS,
            meta: PlatformUtils.isMacOS,
          ),
          child: const Text('Open File'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.folder),
          child: const Text('Open Folder'),
          onPressed: () {},
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.save),
          onPressed: () {},
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyS,
            control: !PlatformUtils.isMacOS,
            meta: PlatformUtils.isMacOS,
          ),
          child: const Text('Save'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.save_as),
          child: const Text('Save As'),
          onPressed: () {},
        ),
        const Divider(height: 1),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              child: const Text('HTML'),
              onPressed: () {},
            ),
            MenuItemButton(
              child: const Text('PDF'),
              onPressed: () {},
            ),
          ],
          child: const Text('Export'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.settings),
          child: const Text('Settings'),
          onPressed: () {},
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.exit_to_app),
          child: const Text('Quit'),
          onPressed: () {},
        ),
      ],
      child: const Text('File'),
    );
  }

  Widget _buildEditMenu(BuildContext context, WidgetRef ref) {
    return SubmenuButton(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.undo),
          onPressed: () {},
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyZ,
            control: !PlatformUtils.isMacOS,
            meta: PlatformUtils.isMacOS,
          ),
          child: const Text('Undo'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.redo),
          onPressed: () {},
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyZ,
            control: !PlatformUtils.isMacOS,
            meta: PlatformUtils.isMacOS,
            shift: true,
          ),
          child: const Text('Redo'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.content_cut),
          child: const Text('Cut'),
          onPressed: () {},
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.content_copy),
          child: const Text('Copy'),
          onPressed: () {},
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.content_paste),
          child: const Text('Paste'),
          onPressed: () {},
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.search),
          child: const Text('Find'),
          onPressed: () {},
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.find_replace),
          child: const Text('Replace'),
          onPressed: () {},
        ),
      ],
      child: const Text('Edit'),
    );
  }

  Widget _buildViewMenu(BuildContext context, WidgetRef ref) {
    final config = ref.watch(settingsProvider);
    return SubmenuButton(
      menuChildren: [
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              child: const Text('Source Code'),
              onPressed: () {
                ref.read(settingsProvider.notifier).setEditMode(EditMode.source);
              },
            ),
            MenuItemButton(
              child: const Text('Preview'),
              onPressed: () {
                ref.read(settingsProvider.notifier).setEditMode(EditMode.preview);
              },
            ),
            MenuItemButton(
              child: const Text('Split View'),
              onPressed: () {
                ref.read(settingsProvider.notifier).setEditMode(EditMode.split);
              },
            ),
          ],
          child: const Text('Edit Mode'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: Text(config.sideBarVisible ? 'Hide Sidebar' : 'Show Sidebar'),
          onPressed: () {
            ref.read(settingsProvider.notifier).toggleSideBar();
          },
        ),
        MenuItemButton(
          child: Text(config.tabBarVisible ? 'Hide Tab Bar' : 'Show Tab Bar'),
          onPressed: () {
            ref.read(settingsProvider.notifier).toggleTabBar();
          },
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: const Text('Focus Mode'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Typewriter Mode'),
          onPressed: () {},
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: const Text('Zoom In'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Zoom Out'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Reset Zoom'),
          onPressed: () {},
        ),
      ],
      child: const Text('View'),
    );
  }

  Widget _buildFormatMenu(BuildContext context, WidgetRef ref) {
    return SubmenuButton(
      menuChildren: [
        MenuItemButton(
          child: const Text('Bold'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Italic'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Strikethrough'),
          onPressed: () {},
        ),
        const Divider(height: 1),
        SubmenuButton(
          menuChildren: List.generate(
            6,
            (i) => MenuItemButton(
              child: Text('Heading ${i + 1}'),
              onPressed: () {},
            ),
          ),
          child: const Text('Heading'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: const Text('Ordered List'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Unordered List'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Task List'),
          onPressed: () {},
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: const Text('Code Block'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Quote Block'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Math Block'),
          onPressed: () {},
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: const Text('Table'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Link'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Image'),
          onPressed: () {},
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: const Text('Horizontal Rule'),
          onPressed: () {},
        ),
      ],
      child: const Text('Format'),
    );
  }

  Widget _buildWindowMenu(BuildContext context, WidgetRef ref) {
    return SubmenuButton(
      menuChildren: [
        MenuItemButton(
          child: const Text('Minimize'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Toggle Full Screen'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Always on Top'),
          onPressed: () {},
        ),
      ],
      child: const Text('Window'),
    );
  }

  Widget _buildHelpMenu(BuildContext context, WidgetRef ref) {
    return SubmenuButton(
      menuChildren: [
        MenuItemButton(
          child: const Text('About MarkText Plus'),
          onPressed: () {},
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: const Text('Check for Updates'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Changelog'),
          onPressed: () {},
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: const Text('Report Bug'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Request Feature'),
          onPressed: () {},
        ),
        const Divider(height: 1),
        MenuItemButton(
          child: const Text('GitHub Repository'),
          onPressed: () {},
        ),
      ],
      child: const Text('Help'),
    );
  }
}
