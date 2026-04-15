import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tab_info.dart';
import '../../providers/tab_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';

class EditorTabBar extends ConsumerWidget {
  const EditorTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabProvider);
    final tabs = tabState.tabs;
    final activeTabId = tabState.activeTabId;
    final config = ref.watch(settingsProvider);
    final tokens = AppTheme.getTokens(config.themeName);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        border: Border(
          bottom: BorderSide(
            color: tokens.colorBorder,
            width: 1,
          ),
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
            icon: Icon(Icons.add, size: 20, color: tokens.colorTextMuted),
            onPressed: () {
              final newTab = TabInfo(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
              );
              ref.read(tabProvider.notifier).addTab(newTab);
            },
            tooltip: 'New Tab',
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
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
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _isHovered = false;
  bool _isCloseHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.tokens.colorBg
                : _isHovered
                    ? widget.tokens.colorSurfaceHover
                    : Colors.transparent,
            borderRadius: widget.isActive
                ? const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  )
                : BorderRadius.zero,
            border: Border(
              right: BorderSide(
                color: widget.tokens.colorBorder,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.tab.isModified)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '●',
                    style: TextStyle(
                      color: widget.tokens.colorAccent,
                      fontSize: 13,
                      height: 1,
                    ),
                  ),
                ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
                  color: widget.isActive ? widget.tokens.colorText : widget.tokens.colorTextMuted,
                ),
                child: Text(widget.tab.fileName),
              ),
              const SizedBox(width: 8),
              if (_isHovered || widget.isActive)
                MouseRegion(
                  onEnter: (_) => setState(() => _isCloseHovered = true),
                  onExit: (_) => setState(() => _isCloseHovered = false),
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _isCloseHovered
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: _isCloseHovered
                            ? Colors.red
                            : widget.tokens.colorTextMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
