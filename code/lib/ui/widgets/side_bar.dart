import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/file_node.dart';
import '../../providers/file_provider.dart';

enum SideBarTab { files, search, toc, settings }

class SideBar extends ConsumerStatefulWidget {
  const SideBar({super.key});

  @override
  ConsumerState<SideBar> createState() => _SideBarState();
}

class _SideBarState extends ConsumerState<SideBar> {
  SideBarTab _selectedTab = SideBarTab.files;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildIconColumn(),
          Expanded(child: _buildContentArea()),
        ],
      ),
    );
  }

  Widget _buildIconColumn() {
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildIconButton(Icons.folder_outlined, SideBarTab.files, 'Files'),
          _buildIconButton(Icons.search, SideBarTab.search, 'Search'),
          _buildIconButton(Icons.list, SideBarTab.toc, 'TOC'),
          const Spacer(),
          _buildIconButton(Icons.settings, SideBarTab.settings, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, SideBarTab tab, String tooltip) {
    final isSelected = _selectedTab == tab;
    return IconButton(
      icon: Icon(icon),
      color: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurface,
      onPressed: () => setState(() => _selectedTab = tab),
      tooltip: tooltip,
    );
  }

  Widget _buildContentArea() {
    switch (_selectedTab) {
      case SideBarTab.files:
        return _buildFileTree();
      case SideBarTab.search:
        return const Center(child: Text('Search'));
      case SideBarTab.toc:
        return const Center(child: Text('Table of Contents'));
      case SideBarTab.settings:
        return const Center(child: Text('Settings'));
    }
  }

  Widget _buildFileTree() {
    final fileNodes = ref.watch(fileProvider);
    if (fileNodes.isEmpty) {
      return const Center(child: Text('No files'));
    }
    return ListView(
      children: fileNodes.map((node) => _buildFileNode(node, 0)).toList(),
    );
  }

  Widget _buildFileNode(FileNode node, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (node.isDirectory) {
              ref.read(fileProvider.notifier).toggleExpand(node.path);
            }
          },
          child: Padding(
            padding: EdgeInsets.only(left: depth * 16.0 + 8, right: 8),
            child: Row(
              children: [
                if (node.isDirectory)
                  Icon(
                    node.isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 16,
                  ),
                Icon(
                  node.isDirectory ? Icons.folder : Icons.insert_drive_file,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    node.name,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (node.isDirectory && node.isExpanded)
          ...node.children.map((child) => _buildFileNode(child, depth + 1)),
      ],
    );
  }
}
