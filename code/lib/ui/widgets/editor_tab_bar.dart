import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tab_info.dart';
import '../../providers/tab_provider.dart';

class EditorTabBar extends ConsumerWidget {
  const EditorTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabProvider);
    final tabs = tabState.tabs;
    final activeTabId = tabState.activeTabId;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
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
                    onTap: () => ref.read(tabProvider.notifier).setActiveTab(tab.id),
                    onClose: () => ref.read(tabProvider.notifier).removeTab(tab.id),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
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

class _TabItem extends StatelessWidget {
  final TabInfo tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Colors.transparent,
          border: Border(
            right: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tab.isModified)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              tab.fileName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onClose,
              child: Icon(
                Icons.close,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
