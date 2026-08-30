import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/config/app_config.dart';
import '../models/tab_info.dart';
import '../services/file_service.dart';
import '../services/open_document_watcher.dart';
import '../utils/platform_utils.dart';
import 'editor_provider.dart';
import 'settings_provider.dart';
import '../models/file_encoding.dart';
import '../models/line_ending.dart';

import '../core/diagnostics/startup_trace.dart';

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

  /// Notices when an open document is changed by something else — a `git
  /// checkout`, another editor, a formatter.
  final OpenDocumentWatcher _diskWatcher = OpenDocumentWatcher();
  StreamSubscription<String>? _diskSubscription;

  TabNotifier(this._ref) : super(const TabState()) {
    _diskSubscription = _diskWatcher.changes.listen(_onDiskChange);
  }

  /// Keeps the watch set equal to the files currently open.
  ///
  /// Hooked to every state change rather than called from each of the eight
  /// places that add or close a tab: this version has already recorded six
  /// bugs whose cause was one behaviour spread across several call sites and
  /// left to drift.
  @override
  set state(TabState value) {
    // What a closed tab leaves behind is released here for the same reason
    // the watch set is kept here: removeTab did both by hand, and the three
    // ways of closing several at once — others, to the right, all — did
    // neither, so their undo histories stayed for the rest of the session.
    final gone = state.tabs.map((tab) => tab.id).toSet()
      ..removeAll(value.tabs.map((tab) => tab.id));

    super.state = value;

    for (final id in gone) {
      _releaseTab(id);
    }
    _syncDiskWatch();
  }

  /// Lets go of everything kept for a tab that is no longer open.
  void _releaseTab(String id) {
    // A closed tab's undo history would otherwise sit in memory for the rest
    // of the session.
    _ref.read(editorProvider.notifier).forgetHistory(id);
    // Its pending auto-save would fire against a tab that no longer exists.
    _autoSaveTimers.remove(id)?.cancel();
  }

  void _syncDiskWatch() {
    _diskWatcher.watch(
      state.tabs.map((tab) => tab.filePath).whereType<String>().toSet(),
    );
  }

  /// Reloads a document that changed on disk while it had no unsaved edits.
  ///
  /// A document with unsaved edits is left exactly as it is: silently
  /// replacing what somebody is in the middle of writing would be the worse
  /// of the two failures by a wide margin.
  /// The app's own writes are recognised by comparing content, not by
  /// remembering which paths it wrote.
  ///
  /// A flag was wrong for a reason worth keeping: the watcher restarts its
  /// debounce on every event, so a save followed within 300 ms by a formatter
  /// rewriting the file arrives as *one* notification — and the flag ate it,
  /// leaving the tab on the unformatted text and the next save overwriting
  /// what the formatter did. Comparing content skips our own save just as
  /// effectively (the bytes match) while still noticing that case.
  Future<void> _onDiskChange(String path) async {
    final tab = state.tabs
        .where((t) => t.filePath == path && !t.isModified && !t.isLoading)
        .firstOrNull;
    if (tab == null) return;

    try {
      final opened = await FileService().readFileWithLineEnding(path);
      if (opened.content == tab.content) return;

      // Read again from state: the await gave the user time to start typing.
      final current = state.tabs.where((t) => t.id == tab.id).firstOrNull;
      if (current == null || current.isModified) return;

      loadTabContent(
        tab.id,
        opened.content,
        lineEnding: opened.lineEnding,
        encoding: opened.encoding,
        stamp: opened.stamp,
      );
    } catch (_) {
      // The file went away, or was unreadable mid-write. The tab keeps what
      // it has, which is the safe outcome.
    }
  }

  /// Restore opened-file entries from persisted config (no tabs opened).
  /// Reopens the documents that were on screen when the application last
  /// closed.
  ///
  /// The tabs appear immediately, empty and marked loading; their contents
  /// arrive after the first frame. Reading five documents before the window
  /// is shown would be five file reads between the reader and their editor,
  /// and this application is meant to start at once.
  ///
  /// Files that have since been deleted or moved are passed over — restoring
  /// a tab onto a path that no longer exists gives a document that cannot be
  /// read and whose next save would write it back into existence.
  Future<void> restoreSession(List<String> paths, String activePath) async {
    if (paths.isEmpty) return;
    final existing = paths.where((path) => File(path).existsSync()).toList();
    if (existing.isEmpty) return;

    String? activeId;
    final restored = <String, String>{};
    for (var i = 0; i < existing.length; i++) {
      final path = existing[i];
      final id = 'session-$i-${path.hashCode}';
      restored[id] = path;
      if (path == activePath) activeId = id;
    }

    state = state.copyWith(
      tabs: [
        ...state.tabs,
        for (final entry in restored.entries)
          TabInfo(
            id: entry.key,
            filePath: entry.value,
            fileName: p.basename(entry.value),
            content: '',
            isLoading: true,
          ),
      ],
      // Whatever was in front, or the first of them if that one is gone.
      activeTabId: state.activeTabId ?? activeId ?? restored.keys.first,
    );

    for (final entry in restored.entries) {
      if (!mounted) return;
      try {
        final opened = await FileService().readFileWithLineEnding(entry.value);
        if (!mounted) return;
        loadTabContent(
          entry.key,
          opened.content,
          lineEnding: opened.lineEnding,
          encoding: opened.encoding,
          stamp: opened.stamp,
        );
      } catch (_) {
        // Unreadable now — permissions, or a file that went away between the
        // check above and here. Drop the tab rather than leave it spinning.
        if (mounted) removeTab(entry.key);
      }
    }
  }

  void restoreOpenedFiles(List<String> filePaths) {
    StartupTrace.mark('restoring ${filePaths.length} sidebar entries');
    final entries = <OpenedFileEntry>[];
    for (final path in filePaths) {
      if (File(path).existsSync()) {
        entries.add(
          OpenedFileEntry(filePath: path, fileName: p.basename(path)),
        );
      }
    }
    if (entries.isNotEmpty) {
      state = state.copyWith(openedFiles: entries);
    }
  }

  /// Remembers which documents are open and which is in front.
  ///
  /// Written whenever the set of tabs changes rather than at exit: `dispose`
  /// never runs on the way out — the window is destroyed and the process ends
  /// — so anything saved only at shutdown would never be saved at all.
  void _persistSession() {
    final paths = state.tabs
        .map((t) => t.filePath)
        .whereType<String>()
        .toList();
    final active = state.tabs
        .where((t) => t.id == state.activeTabId)
        .map((t) => t.filePath)
        .whereType<String>()
        .firstOrNull;
    _ref.read(settingsProvider.notifier).updateConfig(
          (c) => c.copyWith(sessionTabs: paths, sessionActiveTab: active ?? ''),
        );
  }

  void _persistOpenedFiles() {
    final paths = state.openedFiles.map((f) => f.filePath).toList();
    _ref
        .read(settingsProvider.notifier)
        .updateConfig((c) => c.copyWith(sideBarOpenedFiles: paths));
  }

  /// Stops watching the filesystem, before the process starts shutting down.
  ///
  /// `dispose` never runs on the way out — the window is destroyed and the
  /// process ends without Riverpod tearing anything down, which the startup
  /// trace showed by the absence of its marks. That left the directory watches
  /// live at exit, and on Windows a `ReadDirectoryChangesW` thread holds the
  /// VM back while it is unwound: the window vanished and the process lingered.
  void stopWatchingFiles() {
    StartupTrace.mark('stopping file watches');
    _diskSubscription?.cancel();
    _diskSubscription = null;
    _diskWatcher.dispose();
    for (final timer in _autoSaveTimers.values) {
      timer.cancel();
    }
    _autoSaveTimers.clear();
    StartupTrace.mark('file watches stopped');
  }

  @override
  void dispose() {
    StartupTrace.mark('tab notifier dispose begins');
    _diskSubscription?.cancel();
    _diskWatcher.dispose();
    StartupTrace.mark('disk watcher disposed');
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
    final existing = state.tabs
        .where((t) => t.filePath != null && t.filePath == tab.filePath)
        .firstOrNull;
    if (existing != null) {
      state = state.copyWith(
        activeTabId: existing.id,
        openedFiles: openedFiles,
      );
      if (openedFilesChanged) _persistOpenedFiles();
      return;
    }
    state = state.copyWith(
      tabs: [...state.tabs, tab],
      activeTabId: tab.id,
      openedFiles: openedFiles,
    );
    if (openedFilesChanged) _persistOpenedFiles();
    _persistSession();
  }

  void removeTab(String id) {
    final tabs = state.tabs.where((t) => t.id != id).toList();
    String? newActiveId = state.activeTabId;
    if (state.activeTabId == id) {
      newActiveId = tabs.isNotEmpty ? tabs.last.id : null;
    }
    state = state.copyWith(tabs: tabs, activeTabId: newActiveId);
    _persistSession();
  }

  /// Remove a file from the sidebar opened-files list.
  /// Also closes the corresponding tab if one is open.
  void removeOpenedFile(String filePath) {
    final openedFiles = state.openedFiles
        .where((f) => f.filePath != filePath)
        .toList();
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
    state = state.copyWith(
      tabs: tabs,
      activeTabId: activeId,
      openedFiles: openedFiles,
    );
    _persistOpenedFiles();
  }

  void setActiveTab(String id) {
    state = state.copyWith(activeTabId: id);
    _persistSession();
  }

  /// Changes which line ending [id] is written with.
  ///
  /// Marks the document modified: nothing about the text has changed, but
  /// what would be written to disk has, and leaving it clean would let the
  /// choice be lost by closing the tab.
  void setLineEnding(String id, LineEnding lineEnding) {
    final tabs = state.tabs.map((tab) {
      if (tab.id == id && tab.lineEnding != lineEnding) {
        return tab.copyWith(lineEnding: lineEnding, isModified: true);
      }
      return tab;
    }).toList();
    state = state.copyWith(tabs: tabs);
  }

  /// Reads the file again as [encoding] and shows what it says.
  ///
  /// Detection is a guess, so the reader needs a way to correct it. Rereading
  /// from disk rather than re-interpreting what is on screen: the text in
  /// memory has already been through one decoder, and running it through a
  /// second cannot recover what the first one lost.
  ///
  /// A tab with unsaved edits is left alone — rereading would throw them away
  /// — and so is one with no file behind it.
  Future<bool> rereadAs(String id, FileEncoding encoding) async {
    final tab = state.tabs.where((t) => t.id == id).firstOrNull;
    if (tab == null || tab.filePath == null || tab.isModified) return false;

    try {
      final bytes = await File(tab.filePath!).readAsBytes();
      final text = FileEncoding.decodeAs(bytes, encoding);
      loadTabContent(
        id,
        FileService.normalizeLineEndings(text),
        lineEnding: LineEnding.detect(text),
        encoding: encoding,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void updateContent(String id, String content) {
    final tabs = state.tabs.map((tab) {
      if (tab.id == id) {
        return tab.copyWith(
          content: content,
          isModified: true,
          isLoading: false,
        );
      }
      return tab;
    }).toList();
    state = state.copyWith(tabs: tabs);
    _scheduleAutoSave(id);
  }

  /// Records what a tab's file looks like right now.
  ///
  /// Called wherever a document arrives from disk or goes to it. Doing it at
  /// each of those call sites instead would mean one of them eventually not
  /// doing it — and a tab with no stamp is a tab whose saves are unchecked,
  /// which looks exactly like a tab that is fine.
  Future<void> refreshDiskStamp(String id) async {
    final tab = state.tabs.where((t) => t.id == id).firstOrNull;
    final path = tab?.filePath;
    if (path == null) return;
    final stamp = await FileService.stampOf(path);
    // The stat took a moment, and in that moment the notifier may have been
    // disposed — a tab closed, or the application shutting down. Touching
    // `state` then throws, and this is called without an await, so the throw
    // escapes as an unhandled asynchronous error with nothing to catch it.
    if (!mounted) return;
    if (!state.tabs.any((t) => t.id == id)) return;
    state = state.copyWith(
      tabs: state.tabs
          .map((t) => t.id == id ? t.copyWith(diskStamp: stamp) : t)
          .toList(),
    );
  }

  void loadTabContent(
    String id,
    String content, {
    LineEnding? lineEnding,
    FileEncoding? encoding,
    ({DateTime modified, int size})? stamp,
  }) {
    final tabs = state.tabs.map((tab) {
      if (tab.id == id) {
        // The revision is what tells the editors this text did not come from
        // them; comparing the text itself cannot distinguish the two.
        return tab.copyWith(
          content: content,
          isLoading: false,
          lineEnding: lineEnding,
          encoding: encoding,
          // The content came from disk, so this is what the file looks like.
          diskStamp: stamp,
          diskConflict: false,
          externalRevision: tab.externalRevision + 1,
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

    _autoSaveTimers[tabId] = Timer(
      Duration(milliseconds: config.autoSaveDelay),
      () {
        _autoSaveTimers.remove(tabId);
        _performAutoSave(tabId);
      },
    );
  }

  Future<void> _performAutoSave(String tabId) async {
    final tab = state.tabs.where((t) => t.id == tabId).firstOrNull;
    if (tab == null || tab.filePath == null || !tab.isModified) return;
    // Already known to be in conflict: writing now would resolve it by
    // discarding whatever is on disk, which is not a decision auto-save gets
    // to make.
    if (tab.diskConflict) return;
    try {
      await FileService.saveDocumentIfUnchanged(
        tab.filePath!,
        tab.content,
        expect: tab.diskStamp,
        lineEnding: tab.lineEnding,
        encoding: tab.encoding,
      );
      await _markSavedWithStamp(tabId, tab.filePath!);
    } on FileChangedOnDiskException {
      // Something else rewrote the file while this document was being edited.
      // Auto-save stops here and says so rather than choosing a winner: the
      // reader's work stays in the tab, and what is on disk stays on disk.
      _setDiskConflict(tabId, true);
    } catch (_) {
      // Left marked as modified so the close confirmation still fires and the
      // status bar keeps showing the dot: a silent success here would tell the
      // user their work was written when it was not.
    }
  }

  /// Marks the tab saved and records what the file now looks like, so the
  /// next save compares against this write rather than the original read.
  Future<void> _markSavedWithStamp(String id, String path) async {
    final stamp = await FileService.stampOf(path);
    if (!mounted) return;
    state = state.copyWith(
      tabs: state.tabs
          .map((tab) => tab.id == id
              ? tab.copyWith(
                  isModified: false,
                  diskStamp: stamp,
                  diskConflict: false,
                )
              : tab)
          .toList(),
    );
  }

  /// Records that a tab's file changed underneath the editor.
  void markDiskConflict(String id) => _setDiskConflict(id, true);

  /// Records, or clears, that a tab's file changed underneath the editor.
  void _setDiskConflict(String id, bool conflict) {
    if (state.tabs.where((t) => t.id == id).firstOrNull?.diskConflict ==
        conflict) {
      return;
    }
    state = state.copyWith(
      tabs: state.tabs
          .map((tab) =>
              tab.id == id ? tab.copyWith(diskConflict: conflict) : tab)
          .toList(),
    );
  }

  /// Writes the document over whatever is on disk, and clears the conflict.
  ///
  /// The reader asking for this is the whole reason [saveDocument] still
  /// exists without a check.
  Future<bool> overwriteOnDisk(String id) async {
    final tab = state.tabs.where((t) => t.id == id).firstOrNull;
    if (tab?.filePath == null) return false;
    try {
      await FileService.saveDocument(
        tab!.filePath!,
        tab.content,
        lineEnding: tab.lineEnding,
        encoding: tab.encoding,
      );
      await _markSavedWithStamp(id, tab.filePath!);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Throws away the tab's edits and takes what is on disk.
  Future<bool> reloadFromDisk(String id) async {
    final tab = state.tabs.where((t) => t.id == id).firstOrNull;
    if (tab?.filePath == null) return false;
    try {
      final opened =
          await FileService().readFileWithLineEnding(tab!.filePath!);
      final stamp = await FileService.stampOf(tab.filePath!);
      if (!mounted) return false;
      loadTabContent(
        id,
        opened.content,
        lineEnding: opened.lineEnding,
        encoding: opened.encoding,
      );
      state = state.copyWith(
        tabs: state.tabs
            .map((t) => t.id == id
                ? t.copyWith(
                    isModified: false,
                    diskStamp: stamp,
                    diskConflict: false,
                  )
                : t)
            .toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void markSaved(String id) {
    final tabs = state.tabs.map((tab) {
      if (tab.id == id) {
        return tab.copyWith(isModified: false, diskConflict: false);
      }
      return tab;
    }).toList();
    state = state.copyWith(tabs: tabs);
    // The file on disk is now this document, so the next save compares
    // against this write rather than against whatever was read originally.
    unawaited(refreshDiskStamp(id));
  }

  /// Rebinds a tab to a different file, after a rename or a "save as".
  /// Follows a rename on disk, for a file or for a whole folder.
  ///
  /// Renaming from the sidebar only moved the file and refreshed the tree: an
  /// open tab kept pointing at a path that no longer existed, and the next
  /// save wrote the old file back out. Renaming from the File menu did rebind
  /// its tab, so the two ways of doing the same thing disagreed.
  void pathRenamed(String oldPath, String newPath) {
    final oldPrefix = '$oldPath${p.separator}';

    String? moved(String? path) {
      if (path == null) return null;
      if (path == oldPath) return newPath;
      if (path.startsWith(oldPrefix)) {
        return newPath + path.substring(oldPath.length);
      }
      return null;
    }

    var changed = false;
    final tabs = state.tabs.map((tab) {
      final target = moved(tab.filePath);
      if (target == null) return tab;
      changed = true;
      return tab.copyWith(filePath: target, fileName: p.basename(target));
    }).toList();

    final openedFiles = state.openedFiles.map((entry) {
      final target = moved(entry.filePath);
      if (target == null) return entry;
      changed = true;
      return OpenedFileEntry(filePath: target, fileName: p.basename(target));
    }).toList();

    if (!changed) return;
    state = state.copyWith(tabs: tabs, openedFiles: openedFiles);
    _persistOpenedFiles();
  }

  /// Drops whatever was open under [path], which is no longer on disk.
  ///
  /// No prompt about unsaved work: deleting was asked for explicitly, and
  /// offering to save changes to a file that has just been removed would be a
  /// strange thing to be asked.
  void pathDeleted(String path) {
    final prefix = '$path${p.separator}';
    bool gone(String? filePath) =>
        filePath != null && (filePath == path || filePath.startsWith(prefix));

    final tabs = state.tabs.where((t) => !gone(t.filePath)).toList();
    final openedFiles =
        state.openedFiles.where((f) => !gone(f.filePath)).toList();
    if (tabs.length == state.tabs.length &&
        openedFiles.length == state.openedFiles.length) {
      return;
    }

    var activeId = state.activeTabId;
    if (!tabs.any((t) => t.id == activeId)) {
      activeId = tabs.isNotEmpty ? tabs.last.id : null;
    }
    state = state.copyWith(
      tabs: tabs,
      activeTabId: activeId,
      openedFiles: openedFiles,
    );
    _persistOpenedFiles();
  }

  void updateTabPath(String id, String newPath, String newName) {
    final oldPath = state.tabs.where((t) => t.id == id).firstOrNull?.filePath;

    final tabs = state.tabs.map((tab) {
      if (tab.id == id) {
        return tab.copyWith(filePath: newPath, fileName: newName);
      }
      return tab;
    }).toList();

    // The sidebar's list of opened files, shown when no folder is open, holds
    // its own copy of the path. Left behind, it pointed at a file that had
    // been renamed away and opened a second, stale tab when clicked.
    final openedFiles = state.openedFiles
        .map(
          (entry) => entry.filePath == oldPath
              ? OpenedFileEntry(filePath: newPath, fileName: newName)
              : entry,
        )
        .toList();

    state = state.copyWith(tabs: tabs, openedFiles: openedFiles);
    if (oldPath != newPath) _persistOpenedFiles();
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

  /// Opens [filePaths] because the program was launched again.
  ///
  /// Returns whether they were opened in *this* window; false means the
  /// reader's preference sent them to a new one, and this window should be
  /// left exactly where it was.
  Future<bool> openFilesFromSecondInstance(List<String> filePaths) async {
    // The single-instance layer always routes a second launch here, so this is
    // where the preference has to be honoured: choosing "open in a new window"
    // previously changed nothing, because nothing read the setting.
    if (_ref.read(settingsProvider).fileOpenBehavior ==
        FileOpenBehavior.newWindow) {
      for (final path in filePaths) {
        await PlatformUtils.launchNewWindow(filePath: path);
      }
      return false;
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
          encoding: opened.encoding,
          isModified: false,
          // With the content, like every other place that builds a tab from a
          // read. Without it this tab has no baseline, so the check that stops
          // a save from writing over somebody else's change never fires for a
          // document opened from the command line or a file manager.
          diskStamp: opened.stamp,
        );
        addTab(tab);
      } catch (_) {
        // One unreadable file — deleted since it was last opened, or with no
        // read permission — must not stop the rest of the session from being
        // restored. Encoding is no longer a reason to land here.
      }
    }
    return true;
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
