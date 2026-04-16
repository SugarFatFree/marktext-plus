import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tab_info.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_provider.dart';

class EditorTabBar extends ConsumerWidget {
  const EditorTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabProvider);
    final tabs = tabState.tabs;
    final activeTabId = tabState.activeTabId;
    final tokens = AppTheme.getTokens(ref.watch(settingsProvider).themeName);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        border: Border(
          bottom: BorderSide(color: tokens.colorBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              itemCount: tabs.length,
              onReorder: (oldIndex, newIndex) {
                ref.read(tabProvider.notifier).reorderTabs(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isActive = tab.id == activeTabId;
                return ReorderableDragStartListener(
                  key: ValueKey(tab.id),
                  index: index,
                  child: _TabItem(
                    tab: tab,
                    isActive: isActive,
                    tokens: tokens,
                    onTap: () => ref.read(tabProvider.notifier).setActiveTab(tab.id),
                    onClose: () => ref.read(tabProvider.notifier).removeTab(tab.id),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, size: 16, color: tokens.colorTextMuted),
            onPressed: () {
              final newTab = TabInfo(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
              );
              ref.read(tabProvider.notifier).addTab(newTab);
            },
            tooltip: AppLocalizations.of(context)!.newTab,
          ),
        ],
      ),
    );
  }
}

class _TabItem extends ConsumerStatefulWidget {
  final TabInfo tab;
  final bool isActive;
  final AppThemeTokens tokens;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    required this.tab,
    required this.isActive,
    required this.tokens,
    required this.onTap,
    required this.onClose,
  });

  @override
  ConsumerState<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends ConsumerState<_TabItem> {
  bool _isHovered = false;
  bool _isCloseHovered = false;

  void _showContextMenu(BuildContext context, Offset position) async {
    final l10n = AppLocalizations.of(context)!;
    final tab = widget.tab;
    final hasFilePath = tab.filePath != null;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(value: 'close', child: Text(l10n.closeFile)),
        PopupMenuItem(value: 'close_others', child: Text(l10n.closeOtherTabs)),
        PopupMenuItem(value: 'close_right', child: Text(l10n.closeTabsToRight)),
        PopupMenuItem(value: 'close_all', child: Text(l10n.closeAllTabs)),
        if (hasFilePath) ...[
          const PopupMenuDivider(),
          PopupMenuItem(value: 'copy_name', child: Text(l10n.copyFileName)),
          PopupMenuItem(value: 'copy_path', child: Text(l10n.copyFilePath)),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'reveal', child: Text(l10n.revealInExplorer)),
        ],
      ],
    );
    if (result == null || !mounted) return;

    switch (result) {
      case 'close':
        widget.onClose();
      case 'close_others':
        ref.read(tabProvider.notifier).closeOtherTabs(tab.id);
      case 'close_right':
        ref.read(tabProvider.notifier).closeTabsToRight(tab.id);
      case 'close_all':
        ref.read(tabProvider.notifier).closeAllTabs();
      case 'copy_name':
        await Clipboard.setData(ClipboardData(text: tab.fileName));
      case 'copy_path':
        if (tab.filePath != null) {
          await Clipboard.setData(ClipboardData(text: tab.filePath!));
        }
      case 'reveal':
        if (tab.filePath != null) {
          final dir = p.dirname(tab.filePath!);
          if (Platform.isWindows) {
            Process.run('explorer', ['/select,', tab.filePath!]);
          } else if (Platform.isMacOS) {
            Process.run('open', ['-R', tab.filePath!]);
          } else {
            Process.run('xdg-open', [dir]);
          }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (details) {
          _showContextMenu(context, details.globalPosition);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.tokens.colorBg
                : _isHovered
                    ? widget.tokens.colorSurfaceHover
                    : Colors.transparent,
            borderRadius: widget.isActive
                ? const BorderRadius.vertical(top: Radius.circular(8))
                : BorderRadius.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.tab.isModified)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: widget.tokens.colorAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isActive ? widget.tokens.colorText : widget.tokens.colorTextMuted,
                  fontWeight: widget.isActive ? FontWeight.w500 : FontWeight.normal,
                ),
                child: Text(widget.tab.fileName),
              ),
              if (widget.isActive || _isHovered) ...[
                const SizedBox(width: 8),
                MouseRegion(
                  onEnter: (_) => setState(() => _isCloseHovered = true),
                  onExit: (_) => setState(() => _isCloseHovered = false),
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _isCloseHovered
                            ? widget.tokens.colorAccent.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: _isCloseHovered
                            ? widget.tokens.colorAccent
                            : widget.tokens.colorTextMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
