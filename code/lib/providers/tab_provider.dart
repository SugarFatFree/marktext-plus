import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../core/config/app_config.dart';
import '../models/tab_info.dart';
import '../services/file_service.dart';
import '../utils/platform_utils.dart';
import 'editor_provider.dart';
import 'settings_provider.dart';
import '../models/line_ending.dart';

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
  /// One pending auto-save per document.
  ///
  /// A single shared timer meant that editing a second tab cancelled the first
  /// tab's pending save and never rescheduled it, so that document silently
  /// stayed unwritten while auto-save was switched on.
  final Map<String, Timer> _autoSaveTimers = {};

  TabNotifier(this._ref) : super(const TabState());

  /// Restore opened-file entries from persisted config (no tabs opened).
  void restoreOpenedFiles(List<String> filePaths) {
    final entries = <OpenedFileEntry>[];
    for (final path in filePaths) {
      if (File(path).existsSync()) {
        entries.add(OpenedFileEntry(filePath: path, fileName: p.basename(path)));
      }
    }
    if (entries.isNotEmpty) {
      state = state.copyWith(openedFiles: entries);
    }
  }

  void _persistOpenedFiles() {
    final paths = state.openedFiles.map((f) => f.filePath).toList();
    _ref.read(settingsProvider.notifier).updateConfig(
      (c) => c.copyWith(sideBarOpenedFiles: paths),
    );
  }

  @override
  void dispose() {
    for (final timer in _autoSaveTimers.values) {
      timer.cancel();
    }
    _autoSaveTimers.clear();
    super.dispose();
  }

  void addTab(TabInfo tab) {
    // Also register in openedFiles if it has a real file path
    var openedFiles = state.openedFiles;
    var openedFilesChanged = false;
    if (tab.filePath != null &&
        !openedFiles.any((f) => f.filePath == tab.filePath)) {
      openedFiles = [
        ...openedFiles,
        OpenedFileEntry(filePath: tab.filePath!, fileName: tab.fileName),
      ];
      openedFilesChanged = true;
    }
    // Avoid duplicate tabs for the same file
    final existing = state.tabs.where((t) => t.filePath != null && t.filePath == tab.filePath).firstOrNull;
    if (existing != null) {
      state = state.copyWith(activeTabId: existing.id, openedFiles: openedFiles);
      if (openedFilesChanged) _persistOpenedFiles();
      return;
    }
    state = state.copyWith(
      tabs: [...state.tabs, tab],
      activeTabId: tab.id,
      openedFiles: openedFiles,
    );
    if (openedFilesChanged) _persistOpenedFiles();
  }

  void removeTab(String id) {
    // A closed tab's undo history would otherwise sit in memory for the rest
    // of the session.
    _ref.read(editorProvider.notifier).forgetHistory(id);
    // Its pending auto-save would fire against a tab that no longer exists.
    _autoSaveTimers.remove(id)?.cancel();

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
    _persistOpenedFiles();
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

  void loadTabContent(String id, String content, {LineEnding? lineEnding}) {
    final tabs = state.tabs.map((tab) {
      if (tab.id == id) {
        return tab.copyWith(
          content: content,
          isLoading: false,
          lineEnding: lineEnding,
        );
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
    _autoSaveTimers.remove(tabId)?.cancel();
    final config = _ref.read(settingsProvider);
    if (!config.autoSave) return;

    _autoSaveTimers[tabId] =
        Timer(Duration(milliseconds: config.autoSaveDelay), () {
      _autoSaveTimers.remove(tabId);
      _performAutoSave(tabId);
    });
  }

  Future<void> _performAutoSave(String tabId) async {
    final tab = state.tabs.where((t) => t.id == tabId).firstOrNull;
    if (tab == null || tab.filePath == null || !tab.isModified) return;
    try {
      await FileService.saveDocument(tab.filePath!, tab.content,
          lineEnding: tab.lineEnding);
      markSaved(tabId);
    } catch (_) {
      // Left marked as modified so the close confirmation still fires and the
      // status bar keeps showing the dot: a silent success here would tell the
      // user their work was written when it was not.
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

  /// Moves the tab at [oldIndex] so that it ends up at [newIndex].
  ///
  /// [newIndex] is the final index after removal, which is what
  /// `ReorderableListView.onReorderItem` already reports — unlike the
  /// deprecated `onReorder`, no off-by-one adjustment is needed here.
  void reorderTabs(int oldIndex, int newIndex) {
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

  Future<void> openFilesFromSecondInstance(List<String> filePaths) async {
    // The single-instance layer always routes a second launch here, so this is
    // where the preference has to be honoured: choosing "open in a new window"
    // previously changed nothing, because nothing read the setting.
    if (_ref.read(settingsProvider).fileOpenBehavior ==
        FileOpenBehavior.newWindow) {
      for (final path in filePaths) {
        await PlatformUtils.launchNewWindow(filePath: path);
      }
      return;
    }

    final fileService = FileService();
    for (final path in filePaths) {
      final existing = state.tabs.where((t) => t.filePath == path).firstOrNull;
      if (existing != null) {
        state = state.copyWith(activeTabId: existing.id);
        continue;
      }
      try {
        final opened = await fileService.readFileWithLineEnding(path);
        final tab = TabInfo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          filePath: path,
          fileName: p.basename(path),
          content: opened.content,
          lineEnding: opened.lineEnding,
          isModified: false,
        );
        addTab(tab);
      } catch (_) {}
    }
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
