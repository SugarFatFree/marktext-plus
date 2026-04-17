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

class _TabItemState extends ConsumerState<_TabItem> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isCloseHovered = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (_isClosing) return;
    setState(() => _isClosing = true);
    // Immediately call onClose to switch content, while tab fades out
    widget.onClose();
    _fadeController.reverse();
  }

  void _showContextMenu(BuildContext context, Offset position) async {
    final l10n = AppLocalizations.of(context)!;
    final tab = widget.tab;
    final hasFilePath = tab.filePath != null;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(value: 'close', height: 36, child: Text(l10n.closeFile, style: const TextStyle(fontWeight: FontWeight.normal))),
        PopupMenuItem(value: 'close_others', height: 36, child: Text(l10n.closeOtherTabs, style: const TextStyle(fontWeight: FontWeight.normal))),
        PopupMenuItem(value: 'close_right', height: 36, child: Text(l10n.closeTabsToRight, style: const TextStyle(fontWeight: FontWeight.normal))),
        PopupMenuItem(value: 'close_all', height: 36, child: Text(l10n.closeAllTabs, style: const TextStyle(fontWeight: FontWeight.normal))),
        if (hasFilePath) ...[
          const PopupMenuDivider(),
          PopupMenuItem(value: 'copy_name', height: 36, child: Text(l10n.copyFileName, style: const TextStyle(fontWeight: FontWeight.normal))),
          PopupMenuItem(value: 'copy_path', height: 36, child: Text(l10n.copyFilePath, style: const TextStyle(fontWeight: FontWeight.normal))),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'reveal', height: 36, child: Text(l10n.revealInExplorer, style: const TextStyle(fontWeight: FontWeight.normal))),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizeTransition(
        sizeFactor: _fadeAnimation,
        axis: Axis.horizontal,
        child: MouseRegion(
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
                  fontWeight: FontWeight.normal,
                ),
                child: Text(widget.tab.fileName),
              ),
              if (widget.isActive || _isHovered) ...[
                const SizedBox(width: 8),
                MouseRegion(
                  onEnter: (_) => setState(() => _isCloseHovered = true),
                  onExit: (_) => setState(() => _isCloseHovered = false),
                  child: GestureDetector(
                    onTap: _handleClose,
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
        ),
      ),
    );
  }
}
