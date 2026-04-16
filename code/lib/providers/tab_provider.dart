import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tab_info.dart';
import 'settings_provider.dart';

/// Lightweight record of a file shown in the sidebar (no-folder mode).
class OpenedFileEntry {
  final String filePath;
  final String fileName;

  const OpenedFileEntry({required this.filePath, required this.fileName});
}

class TabState {
  final List<TabInfo> tabs;
  final String? activeTabId;
  /// Files shown in the sidebar when no folder is opened.
  /// Independent from [tabs] – closing a tab does NOT remove the entry here.
  final List<OpenedFileEntry> openedFiles;

  const TabState({
    this.tabs = const [],
    this.activeTabId,
    this.openedFiles = const [],
  });

  TabState copyWith({
    List<TabInfo>? tabs,
    String? activeTabId,
    List<OpenedFileEntry>? openedFiles,
  }) {
    return TabState(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId ?? this.activeTabId,
      openedFiles: openedFiles ?? this.openedFiles,
    );
  }
}

class TabNotifier extends StateNotifier<TabState> {
  final Ref _ref;
  Timer? _autoSaveTimer;

  TabNotifier(this._ref) : super(const TabState());

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void addTab(TabInfo tab) {
    // Also register in openedFiles if it has a real file path
    var openedFiles = state.openedFiles;
    if (tab.filePath != null &&
        !openedFiles.any((f) => f.filePath == tab.filePath)) {
      openedFiles = [
        ...openedFiles,
        OpenedFileEntry(filePath: tab.filePath!, fileName: tab.fileName),
      ];
    }
    // Avoid duplicate tabs for the same file
    final existing = state.tabs.where((t) => t.filePath != null && t.filePath == tab.filePath).firstOrNull;
    if (existing != null) {
      state = state.copyWith(activeTabId: existing.id, openedFiles: openedFiles);
      return;
    }
    state = state.copyWith(
      tabs: [...state.tabs, tab],
      activeTabId: tab.id,
      openedFiles: openedFiles,
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

  /// Remove a file from the sidebar opened-files list.
  /// Also closes the corresponding tab if one is open.
  void removeOpenedFile(String filePath) {
    final openedFiles = state.openedFiles.where((f) => f.filePath != filePath).toList();
    // Also close the tab for this file
    final tab = state.tabs.where((t) => t.filePath == filePath).firstOrNull;
    var tabs = state.tabs;
    var activeId = state.activeTabId;
    if (tab != null) {
      tabs = tabs.where((t) => t.id != tab.id).toList();
      if (activeId == tab.id) {
        activeId = tabs.isNotEmpty ? tabs.last.id : null;
      }
    }
    state = state.copyWith(tabs: tabs, activeTabId: activeId, openedFiles: openedFiles);
  }

  void setActiveTab(String id) {
    state = state.copyWith(activeTabId: id);
  }

  void updateContent(String id, String content) {
    final tabs = state.tabs.map((tab) {
      if (tab.id == id) {
        return tab.copyWith(content: content, isModified: true, isLoading: false);
      }
      return tab;
    }).toList();
    state = state.copyWith(tabs: tabs);
    _scheduleAutoSave(id);
  }

  void loadTabContent(String id, String content) {
    final tabs = state.tabs.map((tab) {
      if (tab.id == id) {
        return tab.copyWith(content: content, isLoading: false);
      }
      return tab;
    }).toList();
    state = state.copyWith(tabs: tabs);
  }

  void failTabLoading(String id) {
    final tabs = state.tabs.where((tab) => tab.id != id).toList();
    String? newActiveId = state.activeTabId;
    if (state.activeTabId == id) {
      newActiveId = tabs.isNotEmpty ? tabs.last.id : null;
    }
    state = state.copyWith(tabs: tabs, activeTabId: newActiveId);
  }

  void _scheduleAutoSave(String tabId) {
    _autoSaveTimer?.cancel();
    final config = _ref.read(settingsProvider);
    if (!config.autoSave) return;

    _autoSaveTimer = Timer(Duration(milliseconds: config.autoSaveDelay), () {
      _performAutoSave(tabId);
    });
  }

  Future<void> _performAutoSave(String tabId) async {
    final tab = state.tabs.where((t) => t.id == tabId).firstOrNull;
    if (tab == null || tab.filePath == null || !tab.isModified) return;
    try {
      await File(tab.filePath!).writeAsString(tab.content);
      markSaved(tabId);
    } catch (_) {
      // Auto-save failed silently
    }
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

  void updateTabPath(String id, String newPath, String newName) {
    final tabs = state.tabs.map((tab) {
      if (tab.id == id) {
        return tab.copyWith(filePath: newPath, fileName: newName);
      }
      return tab;
    }).toList();
    state = state.copyWith(tabs: tabs);
  }

  void reorderTabs(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final tabs = List<TabInfo>.from(state.tabs);
    final tab = tabs.removeAt(oldIndex);
    tabs.insert(newIndex, tab);
    state = state.copyWith(tabs: tabs);
  }

  void closeOtherTabs(String keepId) {
    final kept = state.tabs.where((t) => t.id == keepId).toList();
    state = state.copyWith(tabs: kept, activeTabId: keepId);
  }

  void closeTabsToRight(String id) {
    final index = state.tabs.indexWhere((t) => t.id == id);
    if (index < 0) return;
    final tabs = state.tabs.sublist(0, index + 1);
    final activeId = tabs.any((t) => t.id == state.activeTabId)
        ? state.activeTabId
        : tabs.last.id;
    state = state.copyWith(tabs: tabs, activeTabId: activeId);
  }

  void closeAllTabs() {
    state = state.copyWith(tabs: [], activeTabId: null);
  }
}

final tabProvider = StateNotifierProvider<TabNotifier, TabState>((ref) {
  return TabNotifier(ref);
});

final activeTabProvider = Provider<TabInfo?>((ref) {
  final tabState = ref.watch(tabProvider);
  if (tabState.activeTabId == null) return null;
  return tabState.tabs.where((t) => t.id == tabState.activeTabId).firstOrNull;
});

/// File paths passed as command-line arguments at startup.
final startupFilesProvider = StateProvider<List<String>>((ref) => []);
