import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../app.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../models/file_node.dart';
import '../../models/tab_info.dart';
import '../../providers/editor_provider.dart';
import '../../providers/file_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_provider.dart';
import '../screens/settings_screen.dart';

enum SideBarTab { files, search, toc }

class SideBar extends ConsumerStatefulWidget {
  const SideBar({super.key});

  @override
  ConsumerState<SideBar> createState() => _SideBarState();
}

class _SideBarState extends ConsumerState<SideBar> {
  SideBarTab _selectedTab = SideBarTab.files;
  final TextEditingController _searchController = TextEditingController();
  List<_SearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          _buildIconColumn(l10n),
          Expanded(child: _buildContentArea(l10n)),
        ],
      ),
    );
  }

  Widget _buildIconColumn(AppLocalizations l10n) {
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
          _buildIconButton(Icons.folder_outlined, SideBarTab.files, l10n.sidebarFiles),
          _buildIconButton(Icons.search, SideBarTab.search, l10n.sidebarSearch),
          _buildIconButton(Icons.list, SideBarTab.toc, l10n.sidebarToc),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings),
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: () {
              navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: l10n.sidebarSettings,
          ),
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

  Widget _buildContentArea(AppLocalizations l10n) {
    switch (_selectedTab) {
      case SideBarTab.files:
        return _buildFileTree(l10n);
      case SideBarTab.search:
        return _buildSearchPanel(l10n);
      case SideBarTab.toc:
        return _buildTocPanel(l10n);
    }
  }

  // -- Files Panel --

  Widget _buildFileTree(AppLocalizations l10n) {
    final fileNodes = ref.watch(fileProvider);
    if (fileNodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.noOpenFolder,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      children: fileNodes.map((node) => _buildFileNode(node, 0)).toList(),
    );
  }

  Widget _buildFileNode(FileNode node, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onSecondaryTapUp: (details) {
            _showFileContextMenu(context, details.globalPosition, node);
          },
          child: InkWell(
            onTap: () {
              if (node.isDirectory) {
                ref.read(fileProvider.notifier).toggleExpand(node.path);
              } else {
                _openFileInTab(node.path);
              }
            },
            child: Padding(
              padding: EdgeInsets.only(left: depth * 16.0 + 8, right: 8),
              child: SizedBox(
                height: 28,
                child: Row(
                  children: [
                    if (node.isDirectory)
                      Icon(
                        node.isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 16,
                      ),
                    if (!node.isDirectory) const SizedBox(width: 16),
                    Icon(
                      node.isDirectory ? Icons.folder : Icons.insert_drive_file,
                      size: 16,
                      color: node.isDirectory
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
          ),
        ),
        if (node.isDirectory && node.isExpanded)
          ...node.children.map((child) => _buildFileNode(child, depth + 1)),
      ],
    );
  }

  void _showFileContextMenu(BuildContext context, Offset position, FileNode node) async {
    final parentDir = node.isDirectory ? node.path : p.dirname(node.path);
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        const PopupMenuItem(value: 'new_file', child: Text('New File')),
        const PopupMenuItem(value: 'new_folder', child: Text('New Folder')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'rename', child: Text('Rename')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
    if (result == null || !mounted) return;
    switch (result) {
      case 'new_file':
        if (!mounted) return;
        final name = await _showInputDialog(this.context, 'New File', 'File name');
        if (name != null && name.isNotEmpty) {
          await ref.read(fileProvider.notifier).createNode(p.join(parentDir, name));
        }
      case 'new_folder':
        if (!mounted) return;
        final name = await _showInputDialog(this.context, 'New Folder', 'Folder name');
        if (name != null && name.isNotEmpty) {
          await ref.read(fileProvider.notifier).createNode(p.join(parentDir, name), isDirectory: true);
        }
      case 'rename':
        if (!mounted) return;
        final newName = await _showInputDialog(this.context, 'Rename', 'New name', initialValue: node.name);
        if (newName != null && newName.isNotEmpty && newName != node.name) {
          final newPath = p.join(p.dirname(node.path), newName);
          await ref.read(fileProvider.notifier).renameNode(node.path, newPath);
        }
      case 'delete':
        if (!mounted) return;
        final confirmed = await _showConfirmDialog(this.context, 'Delete "${node.name}"?');
        if (confirmed == true) {
          await ref.read(fileProvider.notifier).deleteNode(node.path);
        }
    }
  }

  Future<String?> _showInputDialog(BuildContext context, String title, String hint, {String? initialValue}) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
  }

  void _openFileInTab(String filePath) async {
    try {
      final content = await File(filePath).readAsString();
      final tab = TabInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        filePath: filePath,
        fileName: p.basename(filePath),
        content: content,
      );
      ref.read(tabProvider.notifier).addTab(tab);
      ref.read(settingsProvider.notifier).addRecentFile(filePath);
    } catch (_) {
      // Non-text file or read error, ignore
    }
  }

  // -- Search Panel --

  Widget _buildSearchPanel(AppLocalizations l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchPlaceholder,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: const OutlineInputBorder(),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search, size: 18),
                      onPressed: _performSearch,
                    ),
            ),
            onSubmitted: (_) => _performSearch(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (_searchResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.searchResultCount(_searchResults.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty ? '' : l10n.searchNoResults,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return InkWell(
                      onTap: () => _openFileInTab(result.filePath),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.basename(result.filePath),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              result.matchLine,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final fileNodes = ref.read(fileProvider);
    if (fileNodes.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    final results = <_SearchResult>[];
    final rootPath = ref.read(fileProvider.notifier).currentDirectory;
    if (rootPath != null) {
      await _searchInDirectory(Directory(rootPath), query, results);
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _searchInDirectory(
      Directory dir, String query, List<_SearchResult> results) async {
    try {
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.md' || ext == '.markdown' || ext == '.txt') {
            try {
              final content = await entity.readAsString();
              final lines = content.split('\n');
              for (int i = 0; i < lines.length; i++) {
                if (lines[i].toLowerCase().contains(query.toLowerCase())) {
                  results.add(_SearchResult(
                    filePath: entity.path,
                    lineNumber: i + 1,
                    matchLine: lines[i].trim(),
                  ));
                }
              }
            } catch (_) {}
          }
        } else if (entity is Directory) {
          final name = p.basename(entity.path);
          if (!name.startsWith('.')) {
            await _searchInDirectory(entity, query, results);
          }
        }
      }
    } catch (_) {}
  }

  // -- TOC Panel --

  Widget _buildTocPanel(AppLocalizations l10n) {
    final activeTab = ref.watch(activeTabProvider);
    final content = activeTab?.content ?? '';

    final headings = <_TocEntry>[];
    final lines = content.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(lines[i]);
      if (match != null) {
        headings.add(_TocEntry(
          level: match.group(1)!.length,
          text: match.group(2)!,
          lineNumber: i + 1,
        ));
      }
    }

    if (headings.isEmpty) {
      return Center(
        child: Text(
          l10n.tocEmpty,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: headings.length,
      itemBuilder: (context, index) {
        final heading = headings[index];
        return InkWell(
          onTap: () {
            ref.read(editorProvider.notifier).scrollToLine(heading.lineNumber);
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: (heading.level - 1) * 16.0 + 8,
              right: 8,
              top: 4,
              bottom: 4,
            ),
            child: Text(
              heading.text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: heading.level <= 2 ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}

class _SearchResult {
  final String filePath;
  final int lineNumber;
  final String matchLine;

  _SearchResult({
    required this.filePath,
    required this.lineNumber,
    required this.matchLine,
  });
}

class _TocEntry {
  final int level;
  final String text;
  final int lineNumber;

  _TocEntry({
    required this.level,
    required this.text,
    required this.lineNumber,
  });
}
