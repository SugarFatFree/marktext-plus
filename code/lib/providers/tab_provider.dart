import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tab_info.dart';

class TabState {
  final List<TabInfo> tabs;
  final String? activeTabId;

  const TabState({
    this.tabs = const [],
    this.activeTabId,
  });

  TabState copyWith({
    List<TabInfo>? tabs,
    String? activeTabId,
  }) {
    return TabState(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId ?? this.activeTabId,
    );
  }
}

class TabNotifier extends StateNotifier<TabState> {
  TabNotifier() : super(const TabState());

  void addTab(TabInfo tab) {
    state = state.copyWith(
      tabs: [...state.tabs, tab],
      activeTabId: tab.id,
    );
  }

  void removeTab(String id) {
    final tabs = state.tabs.where((t) => t.id != id).toList();
    String? newActiveId = state.activeTabId;
    if (state.activeTabId == id) {
      newActiveId = tabs.isNotEmpty ? tabs.last.id : null;
    }
    state = state.copyWith(tabs: tabs, activeTabId: newActiveId);
  }

  void setActiveTab(String id) {
    state = state.copyWith(activeTabId: id);
  }

  void updateContent(String id, String content) {
    final tabs = state.tabs.map((tab) {
      if (tab.id == id) {
        return tab.copyWith(content: content, isModified: true);
      }
      return tab;
    }).toList();
    state = state.copyWith(tabs: tabs);
  }

  void markSaved(String id) {
    final tabs = state.tabs.map((tab) {
      if (tab.id == id) {
        return tab.copyWith(isModified: false);
      }
      return tab;
    }).toList();
    state = state.copyWith(tabs: tabs);
  }
}

final tabProvider = StateNotifierProvider<TabNotifier, TabState>((ref) {
  return TabNotifier();
});

final activeTabProvider = Provider<TabInfo?>((ref) {
  final tabState = ref.watch(tabProvider);
  if (tabState.activeTabId == null) return null;
  return tabState.tabs.where((t) => t.id == tabState.activeTabId).firstOrNull;
});
