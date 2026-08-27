import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../../app.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/file_node.dart';
import '../../models/tab_info.dart';
import '../../models/file_encoding.dart';
import '../../providers/editor_provider.dart';
import '../../providers/file_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_provider.dart';
import '../screens/settings_screen.dart';
import '../../providers/sidebar_provider.dart';
import '../../services/file_service.dart';
import '../../services/markdown_parser.dart';


class SideBar extends ConsumerStatefulWidget {
  const SideBar({super.key});

  @override
  ConsumerState<SideBar> createState() => _SideBarState();
}

class _SideBarState extends ConsumerState<SideBar> {
  SideBarTab? _hoveredTab;
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
    final config = ref.watch(settingsProvider);
    final tokens = AppTheme.getTokens(config.themeName);
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        border: Border(
          right: BorderSide(color: tokens.colorBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildIconColumn(l10n, tokens),
          Expanded(child: _buildContentArea(l10n)),
        ],
      ),
    );
  }

  Widget _buildIconColumn(AppLocalizations l10n, AppThemeTokens tokens) {
    return Container(
      width: 40,
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        border: Border(
          right: BorderSide(color: tokens.colorBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),
          _buildIconButton(Icons.folder_outlined, SideBarTab.files, l10n.sidebarFiles, tokens),
          _buildIconButton(Icons.search, SideBarTab.search, l10n.sidebarSearch, tokens),
          _buildIconButton(Icons.list, SideBarTab.toc, l10n.sidebarToc, tokens),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: IconButton(
              icon: Icon(Icons.settings, size: 18, color: tokens.colorTextMuted),
              onPressed: () {
                navigatorKey.currentState?.push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const SettingsScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          )),
                          child: child,
                        ),
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
              tooltip: l10n.sidebarSettings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, SideBarTab tab, String tooltip, AppThemeTokens tokens) {
    final isSelected = ref.watch(sideBarTabProvider) == tab;
    final isHovered = _hoveredTab == tab;
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredTab = tab),
        onExit: (_) => setState(() => _hoveredTab = null),
        child: GestureDetector(
          onTap: () => ref.read(sideBarTabProvider.notifier).state = tab,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? tokens.colorSurfaceHover
                  : isHovered
                      ? tokens.colorSurfaceHover.withValues(alpha: 0.5)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isSelected ? tokens.colorAccent : tokens.colorTextMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(AppLocalizations l10n) {
    final selectedTab = ref.watch(sideBarTabProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: KeyedSubtree(
        key: ValueKey(selectedTab),
        child: switch (selectedTab) {
          SideBarTab.files => _buildFileTree(l10n),
          SideBarTab.search => _buildSearchPanel(l10n),
          SideBarTab.toc => _buildTocPanel(l10n),
        },
      ),
    );
  }

  // -- Files Panel --

  Widget _buildFileTree(AppLocalizations l10n) {
    final fileNodes = ref.watch(fileProvider);
    final tabState = ref.watch(tabProvider);
    final currentDir = ref.watch(fileProvider.notifier).currentDirectory;

    if (fileNodes.isNotEmpty) {
      // Collect opened files that are NOT inside the current directory
      final externalFiles = <OpenedFileEntry>[];
      if (currentDir != null) {
        for (final file in tabState.openedFiles) {
          if (!file.filePath.startsWith(currentDir)) {
            externalFiles.add(file);
          }
        }
      }

      return ListView(
        children: [
          ...fileNodes.map((node) => _buildFileNode(node, 0)),
          // Show externally opened files below the directory tree
          if (externalFiles.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 12, bottom: 4),
              child: Text(
                l10n.sidebarFiles,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ),
            ...externalFiles.map((file) => _buildExternalFileItem(file, tabState, l10n)),
          ],
        ],
      );
    }

    // No folder opened – show opened files list
    if (tabState.openedFiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.noOpenFolder,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      children: tabState.openedFiles.map((file) {
        return _buildExternalFileItem(file, tabState, l10n);
      }).toList(),
    );
  }

  Widget _buildExternalFileItem(OpenedFileEntry file, TabState tabState, AppLocalizations l10n) {
    final isActive = tabState.tabs.any((t) => t.filePath == file.filePath && t.id == tabState.activeTabId);
    return GestureDetector(
      onSecondaryTapUp: (details) {
        _showOpenedFileContextMenu(context, details.globalPosition, file);
      },
      child: InkWell(
        onTap: () => _openFileInTab(file.filePath),
        hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 4),
          child: SizedBox(
            height: 28,
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file,
                  size: 16,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    file.fileName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 12),
                    iconSize: 12,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    onPressed: () {
                      ref.read(tabProvider.notifier).removeOpenedFile(file.filePath);
                    },
                    tooltip: l10n.closeFile,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileNode(FileNode node, int depth) {
    final l10n = AppLocalizations.of(context)!;
    final tabState = ref.watch(tabProvider);
    final isOpenedInTab = !node.isDirectory &&
        tabState.tabs.any((t) => t.filePath == node.path);
    final isRootFolder = depth == 0 && node.isDirectory;

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
              padding: EdgeInsets.only(left: depth * 16.0 + 8, right: 4),
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
                    if (isRootFolder || isOpenedInTab)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 12),
                          iconSize: 12,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          onPressed: () {
                            if (isRootFolder) {
                              // Close the entire folder and all its files
                              final folderPath = node.path;
                              ref.read(fileProvider.notifier).closeDirectory();
                              ref.read(settingsProvider.notifier).updateConfig(
                                (c) => c.copyWith(sideBarDirectory: ''),
                              );

                              // Close all tabs for files in this folder
                              final tabState = ref.read(tabProvider);
                              for (final tab in tabState.tabs) {
                                if (tab.filePath != null && tab.filePath!.startsWith(folderPath)) {
                                  ref.read(tabProvider.notifier).removeOpenedFile(tab.filePath!);
                                }
                              }
                            } else {
                              // Close the file tab
                              ref.read(tabProvider.notifier).removeOpenedFile(node.path);
                            }
                          },
                          tooltip: isRootFolder ? l10n.fileOpenFolder : l10n.closeFile,
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
    final l10n = AppLocalizations.of(context)!;
    final parentDir = node.isDirectory ? node.path : p.dirname(node.path);
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(value: 'new_file', child: Text(l10n.fileNew)),
        PopupMenuItem(value: 'new_folder', child: Text(l10n.newFolder)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
        PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
      ],
    );
    if (result == null || !mounted) return;
    switch (result) {
      case 'new_file':
        if (!mounted) return;
        final name = await _showInputDialog(this.context, l10n.fileNew, l10n.fileNameHint);
        if (name != null && name.isNotEmpty) {
          await ref.read(fileProvider.notifier).createNode(p.join(parentDir, name));
        }
      case 'new_folder':
        if (!mounted) return;
        final name = await _showInputDialog(this.context, l10n.newFolder, l10n.folderNameHint);
        if (name != null && name.isNotEmpty) {
          await ref.read(fileProvider.notifier).createNode(p.join(parentDir, name), isDirectory: true);
        }
      case 'rename':
        if (!mounted) return;
        final newName = await _showInputDialog(this.context, l10n.rename, l10n.newNameHint, initialValue: node.name);
        if (newName != null && newName.isNotEmpty && newName != node.name) {
          final newPath = p.join(p.dirname(node.path), newName);
          await ref.read(fileProvider.notifier).renameNode(node.path, newPath);
        }
      case 'delete':
        if (!mounted) return;
        final confirmed = await _showConfirmDialog(this.context, l10n.confirmDeleteFile(node.name));
        if (confirmed == true) {
          await ref.read(fileProvider.notifier).deleteNode(node.path);
        }
    }
  }

  Future<String?> _showInputDialog(BuildContext context, String title, String hint, {String? initialValue}) {
    final l10n = AppLocalizations.of(context)!;
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text), child: Text(l10n.ok)),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirm),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.delete)),
        ],
      ),
    );
  }

  void _showOpenedFileContextMenu(BuildContext context, Offset position, OpenedFileEntry file) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(value: 'copy_name', child: Text(l10n.copyFileName)),
        PopupMenuItem(value: 'copy_path', child: Text(l10n.copyFilePath)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'close', child: Text(l10n.closeFile)),
        PopupMenuItem(value: 'delete', child: Text(l10n.deleteFile)),
      ],
    );
    if (result == null || !mounted) return;
    switch (result) {
      case 'copy_name':
        await Clipboard.setData(ClipboardData(text: file.fileName));
      case 'copy_path':
        await Clipboard.setData(ClipboardData(text: file.filePath));
      case 'close':
        ref.read(tabProvider.notifier).removeOpenedFile(file.filePath);
      case 'delete':
        if (!mounted) return;
        final confirmed = await _showConfirmDialog(
          this.context,
          l10n.confirmDeleteFile(file.fileName),
        );
        if (confirmed == true) {
          try {
            await File(file.filePath).delete();
            ref.read(tabProvider.notifier).removeOpenedFile(file.filePath);
          } catch (_) {
            // Ignore delete errors
          }
        }
    }
  }

  /// Opens [filePath] in a tab, optionally scrolling to [line].
  ///
  /// [line] is 1-based. A search result knows which line it matched, and
  /// dropping that on the way to the editor left the reader at the top of the
  /// file with no idea where the hit was.
  void _openFileInTab(String filePath, {int? line}) async {
    final tabNotifier = ref.read(tabProvider.notifier);
    final currentTabs = ref.read(tabProvider);

    // Fast path: if a tab for this file already exists, just switch to it
    final existing = currentTabs.tabs.where(
      (t) => t.filePath != null && t.filePath == filePath,
    ).firstOrNull;
    if (existing != null) {
      tabNotifier.setActiveTab(existing.id);
      if (line != null) ref.read(editorProvider.notifier).scrollToLine(line);
      return;
    }

    // Optimistic UI: create tab immediately with loading state
    final tabId = DateTime.now().millisecondsSinceEpoch.toString();
    final tab = TabInfo(
      id: tabId,
      filePath: filePath,
      fileName: p.basename(filePath),
      content: '',
      isLoading: true,
    );
    tabNotifier.addTab(tab);
    ref.read(settingsProvider.notifier).addRecentFile(filePath);

    // Load file content asynchronously
    try {
      // Through FileService so CRLF is normalised and remembered; reading
      // the file directly left \r\n in the document, which breaks Markdown
      // syntax in the preview and in every export.
      final opened = await FileService().readFileWithLineEnding(filePath);
      if (!mounted) return;
      tabNotifier.loadTabContent(tabId, opened.content,
          lineEnding: opened.lineEnding, encoding: opened.encoding);
      // Requested before the new editor exists; it reads the pending target
      // when it initialises.
      if (line != null) ref.read(editorProvider.notifier).scrollToLine(line);
    } catch (_) {
      // Read failed – remove the loading tab
      if (!mounted) return;
      tabNotifier.failTabLoading(tabId);
    }
  }

  // -- Search Panel --

  Widget _buildSearchPanel(AppLocalizations l10n) {
    final rootPath = ref.watch(fileProvider.notifier).currentDirectory;
    if (rootPath == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.noOpenFolder,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
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
                // The list is capped; saying "500 results" when there are
                // more would be a quiet lie about what was searched.
                _searchResults.length >= _maxSearchResults
                    ? '${l10n.searchResultCount(_searchResults.length)}+'
                    : l10n.searchResultCount(_searchResults.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: _searchController.text.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 36,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.searchNoResults,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return InkWell(
                      onTap: () => _openFileInTab(
                        result.filePath,
                        line: result.lineNumber,
                      ),
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

  /// Documents worth searching.
  static const _searchableExtensions = {'.md', '.markdown', '.txt'};

  /// Directories that are never the user's own notes and can hold tens of
  /// thousands of files.
  static const _skippedDirectories = {
    'node_modules',
    'vendor',
    'build',
    'dist',
    'target',
  };

  /// Beyond this the result list stops being useful and starts being a
  /// memory problem: a common word across a large folder runs to tens of
  /// thousands of hits, each one a string in a list widget.
  static const _maxSearchResults = 500;

  /// Distinguishes one search from the next.
  ///
  /// Starting a second search while the first is still walking the tree used
  /// to let the slower one finish last and overwrite the newer results.
  int _searchGeneration = 0;

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final rootPath = ref.read(fileProvider.notifier).currentDirectory;
    if (rootPath == null) return;

    final generation = ++_searchGeneration;
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    final results = <_SearchResult>[];
    await _searchInDirectory(
      Directory(rootPath),
      query.toLowerCase(),
      results,
      generation,
    );

    if (!mounted || generation != _searchGeneration) return;
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  /// Walks [dir] collecting matches for [lowercaseQuery].
  ///
  /// The query arrives already lowercased: it used to be lowercased again for
  /// every line of every file.
  Future<void> _searchInDirectory(
    Directory dir,
    String lowercaseQuery,
    List<_SearchResult> results,
    int generation,
  ) async {
    if (results.length >= _maxSearchResults) return;
    if (generation != _searchGeneration) return;

    List<FileSystemEntity> entities;
    try {
      // Asynchronous: listSync walked the whole tree on the UI isolate, so a
      // large folder froze the window until the search finished.
      entities = await dir.list(followLinks: false).toList();
    } catch (_) {
      return;
    }

    for (final entity in entities) {
      if (results.length >= _maxSearchResults) return;
      if (generation != _searchGeneration) return;

      if (entity is Directory) {
        final name = p.basename(entity.path);
        if (name.startsWith('.') || _skippedDirectories.contains(name)) {
          continue;
        }
        await _searchInDirectory(entity, lowercaseQuery, results, generation);
        continue;
      }

      if (entity is! File) continue;
      if (!_searchableExtensions
          .contains(p.extension(entity.path).toLowerCase())) {
        continue;
      }

      try {
        // Through the shared decode: `readAsString` throws on anything but
        // UTF-8, and the catch below then skipped the file entirely — a
        // legacy document was simply unsearchable.
        final (text, _) = FileEncoding.decode(await entity.readAsBytes());
        final lines = text.split('\n');
        for (int i = 0; i < lines.length; i++) {
          if (!lines[i].toLowerCase().contains(lowercaseQuery)) continue;
          results.add(_SearchResult(
            filePath: entity.path,
            lineNumber: i + 1,
            matchLine: lines[i].trim(),
          ));
          if (results.length >= _maxSearchResults) return;
        }
      } catch (_) {
        // Unreadable or not text; nothing to search.
      }
    }
  }

  // -- TOC Panel --

  Widget _buildTocPanel(AppLocalizations l10n) {
    final activeTab = ref.watch(activeTabProvider);
    final content = activeTab?.content ?? '';

    // Shared with the preview, which maps its Nth heading widget to the Nth
    // entry here: two readings of the same document would put every entry
    // after the first disagreement on the wrong line.
    final headings = [
      for (final heading in MarkdownParser.headingOutline(content))
        _TocEntry(
          level: heading.level,
          text: heading.text,
          lineNumber: heading.line,
        ),
    ];

    if (headings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.segment_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.tocEmpty,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
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
          hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: EdgeInsets.only(
              left: (heading.level - 1) * 16.0 + 8,
              right: 8,
              top: 6,
              bottom: 6,
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
