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

/// A document that was closed, kept so it can be opened again.
///
/// The path, not the text. Holding the content of the last ten closed
/// documents would undo what this editor claims about memory, and the copy on
/// disk is what reopening should show anyway. A tab that was never saved has
/// no path and is not kept: closing a modified one asks first, so answering
/// "don't save" is a decision rather than a slip.
class ClosedTab {
  const ClosedTab({
    required this.filePath,
    required this.fileName,
    required this.index,
  });

  final String filePath;
  final String fileName;

  /// Where it sat among the open tabs, so it comes back there rather than at
  /// the end.
  final int index;
}

class TabState {
  final List<TabInfo> tabs;
  final String? activeTabId;

  /// Files shown in the sidebar when no folder is opened.
  /// Independent from [tabs] – closing a tab does NOT remove the entry here.
  final List<OpenedFileEntry> openedFiles;

  /// Documents closed during this session, newest first.
  final List<ClosedTab> recentlyClosed;

  const TabState({
    this.tabs = const [],
    this.activeTabId,
    this.openedFiles = const [],
    this.recentlyClosed = const [],
  });

  TabState copyWith({
    List<TabInfo>? tabs,
    String? activeTabId,
    List<OpenedFileEntry>? openedFiles,
    List<ClosedTab>? recentlyClosed,
  }) {
    return TabState(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId ?? this.activeTabId,
      openedFiles: openedFiles ?? this.openedFiles,
      recentlyClosed: recentlyClosed ?? this.recentlyClosed,
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

    // Which documents just disappeared, so closing one by mistake costs
    // nothing to undo. Recorded here for the same reason as the release
    // below: six ways of closing a tab, one place all six pass through.
    final justClosed = [
      for (var i = 0; i < state.tabs.length; i++)
        // Not one that never finished loading. Restoring a session opens
        // every tab empty and marked loading and drops any it cannot read,
        // and that drop comes through here looking exactly like a close —
        // so the editor would offer to reopen a document nobody closed and
        // nothing can read.
        if (gone.contains(state.tabs[i].id) &&
            state.tabs[i].filePath != null &&
            !state.tabs[i].isLoading)
          ClosedTab(
            filePath: state.tabs[i].filePath!,
            fileName: state.tabs[i].fileName,
            index: i,
          ),
    ];
    final remembered = justClosed.isEmpty
        ? value.recentlyClosed
        : [
            // Rightmost first when several go at once, which is the order
            // they would be reopened in.
            ...justClosed.reversed,
            // One entry per document: closing the same file twice should not
            // make the key walk back through it twice.
            ...value.recentlyClosed.where(
              (old) => justClosed.every((n) => n.filePath != old.filePath),
            ),
          ].take(closedTabsKept).toList();

    // The same object back when nothing closed, rather than a copy of it:
    // this setter runs on every state change, and most of them are a
    // keystroke.
    super.state = identical(remembered, value.recentlyClosed)
        ? value
        : value.copyWith(recentlyClosed: remembered);

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
      // The read took a moment, and in that moment the notifier may have been
      // disposed — the window closing while a watcher event was in flight.
      // Reading `state` then throws, and this is a stream callback, so the
      // throw escapes as an unhandled asynchronous error with nothing to catch
      // it. The same window the stamp refresh already guards against.
      if (!mounted) return;
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
      // The tab keeps what it has, which is the safe outcome. But not in
      // silence when the file is gone: nothing about the tab looked any
      // different — no dot, no banner — so closing it took the last copy of the
      // document with it, and neither the deletion nor the loss was ever
      // mentioned. The reader's own delete does close the tab (`pathDeleted`);
      // this is the other way a file goes away.
      //
      // The banner already says the true thing — "changed on disk, auto-save is
      // paused for this file" — and the three ways out of a conflict still make
      // sense, with Overwrite being the one that puts the file back.
      //
      // Only when it is really gone, not on any read failure: a file another
      // program is part-way through writing is briefly unreadable, and raising
      // a conflict for that is a false alarm the reader then has to clear.
      if (!await File(path).exists() && mounted) {
        _setDiskConflict(tab.id, true);
      }
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

  /// How many closed documents are remembered.
  ///
  /// Bounded because the session is not: each entry is small, which is
  /// exactly the argument that leaves lists like this unbounded.
  static const closedTabsKept = 10;

  /// Opens [tab], at [at] among the open tabs when a position is asked for.
  void addTab(TabInfo tab, {int? at}) {
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
    final tabs = [...state.tabs];
    tabs.insert(at == null ? tabs.length : at.clamp(0, tabs.length), tab);
    state = state.copyWith(
      tabs: tabs,
      activeTabId: tab.id,
      openedFiles: openedFiles,
    );
    if (openedFilesChanged) _persistOpenedFiles();
    _persistSession();
  }

  /// Closes [id], and says whether there was anything to close.
  ///
  /// The answer matters to the automation interface, which used to report
  /// "closed tab X" for an id naming no tab — the same untruth its sibling
  /// [setActiveTab] was given a `bool` to stop telling.
  bool removeTab(String id) {
    if (!state.tabs.any((t) => t.id == id)) return false;
    final tabs = state.tabs.where((t) => t.id != id).toList();
    String? newActiveId = state.activeTabId;
    if (state.activeTabId == id) {
      newActiveId = tabs.isNotEmpty ? tabs.last.id : null;
    }
    state = state.copyWith(tabs: tabs, activeTabId: newActiveId);
    _persistSession();
    return true;
  }

  /// Opens the most recently closed document again, and says whether there
  /// was one.
  ///
  /// Read from disk, because the path is all that was kept — so this shows
  /// what is on disk now, which is also what "don't save" left there.
  Future<bool> reopenLastClosedTab() async {
    final closed = state.recentlyClosed.firstOrNull;
    if (closed == null) return false;

    // Forgotten whether or not the read works. A document deleted since it
    // was closed would otherwise answer this key for the rest of the session,
    // and the one before it could never be reached.
    state = state.copyWith(recentlyClosed: state.recentlyClosed.sublist(1));

    final existing = state.tabs
        .where((t) => t.filePath == closed.filePath)
        .firstOrNull;
    if (existing != null) {
      state = state.copyWith(activeTabId: existing.id);
      return true;
    }

    try {
      final opened = await FileService().readFileWithLineEnding(closed.filePath);
      if (!mounted) return false;
      addTab(
        TabInfo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          filePath: closed.filePath,
          fileName: p.basename(closed.filePath),
          content: opened.content,
          lineEnding: opened.lineEnding,
          encoding: opened.encoding,
          isModified: false,
          // With the content, like every other place that builds a tab from a
          // read: without it this tab has no baseline, and the check that
          // stops a save from writing over somebody else's change never fires.
          diskStamp: opened.stamp,
        ),
        at: closed.index,
      );
      return true;
    } catch (_) {
      // Deleted, moved, or no longer readable. Nothing to say beyond "there
      // was nothing to reopen"; the entry is already gone.
      return false;
    }
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

  /// Makes [id] the active tab, if there is such a tab.
  ///
  /// Returns whether it happened. Writing the id unchecked was harmless while
  /// the tab bar was the only caller — it hands over ids it just drew. The MCP
  /// server offers the same action to anything that can send JSON, and an id
  /// that names no tab left the editor with tabs along the top, nothing below
  /// them, and a report saying the switch had worked.
  bool setActiveTab(String id) {
    if (!state.tabs.any((tab) => tab.id == id)) return false;
    state = state.copyWith(activeTabId: id);
    _persistSession();
    return true;
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
  /// Throws when the file cannot be read, for the same reason
  /// [overwriteOnDisk] does: false is "there was nothing to reread", and a
  /// reader who picked an encoding and saw nothing happen is owed the reason.
  Future<bool> rereadAs(String id, FileEncoding encoding) async {
    final tab = state.tabs.where((t) => t.id == id).firstOrNull;
    if (tab == null || tab.filePath == null || tab.isModified) return false;

    // The baseline first, then the bytes — the order [readFileWithLineEnding]
    // uses, and for the same reason. This path cannot call that helper because
    // it must decode as the encoding the reader chose rather than the one
    // detection guesses.
    final stamp = await FileService.stampOf(tab.filePath!);
    final bytes = await File(tab.filePath!).readAsBytes();
    final text = FileEncoding.decodeAs(bytes, encoding);
    loadTabContent(
      id,
      FileService.normalizeLineEndings(text),
      lineEnding: LineEnding.detect(text),
      encoding: encoding,
      // Without this the tab kept the stamp from before the file was last
      // rewritten, while `loadTabContent` cleared the conflict banner: a way
      // out of the conflict that put the banner away and left the next save to
      // raise it again. `copyWith` reads a null stamp as "leave it alone".
      stamp: stamp,
    );
    return true;
  }

  /// Puts [content] in the tab, and says whether the tab was there to put it
  /// in.
  ///
  /// Same reason as [removeTab]: an id naming no tab used to be reported as a
  /// write that happened.
  ///
  /// [external] for a write that did not come from someone typing: a plugin's
  /// rewrite being accepted, an edit arriving over the automation interface, an
  /// undo with no source editor to restore into. Those have to raise the
  /// revision, because the source editor holds the text in a controller of its
  /// own and only looks at the tab again when that number changes — so without
  /// it the reader watched a blank page stay blank after accepting an answer,
  /// and the next keystroke would have written the blank back over it.
  ///
  /// Not for typing. The editor's own listener calls this on every keystroke,
  /// and raising the revision there would have it re-reading its own text back
  /// from the tab as the reader writes.
  bool updateContent(String id, String content, {bool external = false}) {
    if (!state.tabs.any((tab) => tab.id == id)) return false;
    final tabs = state.tabs.map((tab) {
      if (tab.id == id) {
        return tab.copyWith(
          content: content,
          // An empty tab that has never been saved holds nothing to lose, so
          // it is not "modified" and closes without a word — which is what
          // every other editor does with an untitled document you emptied.
          //
          // Found from the other side: the automation interface can open a
          // tab and write to it but had no way to be rid of one, because
          // `close_tab` refuses unsaved work and there is nobody there to
          // press Save. Clearing the text left it "modified" all the same, so
          // a scratch tab an agent made could only be closed by a person.
          //
          // Not by comparing against the file: that would mean keeping a
          // second copy of the document, and this editor is for large ones.
          // A tab with a file is modified by this call as it always was —
          // emptying a written document *is* an edit.
          isModified: tab.filePath != null || content.isNotEmpty,
          isLoading: false,
          externalRevision:
              external ? tab.externalRevision + 1 : tab.externalRevision,
        );
      }
      return tab;
    }).toList();
    state = state.copyWith(tabs: tabs);
    _scheduleAutoSave(id);
    return true;
  }

  /// Records a restore point before an edit made in the preview.
  ///
  /// The preview is not read-only: a checkbox can be ticked in it and a block
  /// edited in place. Every `pushHistory` in the application was in the source
  /// editor, and preview-only mode does not build one — `DeferredEditorBuilder`
  /// builds the mode on screen and no other — so that tab's undo stack was
  /// empty and Ctrl+Z did nothing whatever. In the split it was coarse rather
  /// than absent: the stack held the source pane's own snapshots, so one press
  /// stepped back past however many boxes had been ticked since the last one.
  ///
  /// The machinery for preview undo was already built and waiting.
  /// [EditorNotifier.hasSourceEditor] exists so undo knows to hand its answer
  /// to the caller instead of writing it into a field, and says so in its own
  /// doc comment. What it never had was a snapshot to go back to.
  ///
  /// The restore point only, not the write: the two ways into the preview's
  /// editing report their new text differently — preview-only mode through the
  /// tab, the split through its own `onChanged`, which is also the path typing
  /// takes — and this is the one thing they both need and neither did.
  ///
  /// Named for what it is rather than for where it was first needed, because
  /// the preview is not the only writer that is not the source editor's own
  /// controller: an agent writing over the automation interface is another, and
  /// it had the same hole. `external` is the word [updateContent] already uses
  /// for a write that did not come from someone typing, and those are exactly
  /// the writes nobody else has recorded a restore point for.
  void recordExternalEdit(String id, String next) {
    final tab = state.tabs.where((t) => t.id == id).firstOrNull;
    if (tab == null || tab.content == next) return;
    final editor = _ref.read(editorProvider.notifier);
    // Preview-only mode never built a source editor, so nothing has told the
    // history which tab it is for. A no-op when it already knows.
    editor.setHistoryTab(id);
    editor.pushHistory(tab.content, tabId: id);
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

  /// How a write to a tab's own file ended.
  ///
  /// Named outcomes rather than a bool, because the two callers answer for
  /// different audiences and must not have to guess which failure they got:
  /// auto-save turns [conflict] into the banner and says nothing about the
  /// rest, while the automation socket has to tell whoever asked *why* nothing
  /// was written.
  ///
  /// Both go through [saveToDisk] so there is one description of what an
  /// ordinary save is — check the file has not changed underneath, write it,
  /// take on the encoding that was actually used, record the new baseline.
  /// Six places wrote a document before this one existed, and the survey that
  /// put them side by side is what found BUG-465: three of them threw away the
  /// encoding the write came back with.
  Future<SaveOutcome> saveToDisk(String id, {String? to}) async {
    final tab = state.tabs.where((t) => t.id == id).firstOrNull;
    if (tab == null) return SaveOutcome.noTab;
    if (to != null) return _saveAs(tab, to);
    if (tab.filePath == null) return SaveOutcome.noFile;
    if (!tab.isModified) return SaveOutcome.nothingToWrite;
    // Already known to be in conflict: writing now would resolve it by
    // discarding whatever is on disk, which is not a decision either caller
    // gets to make on the reader's behalf.
    if (tab.diskConflict) return SaveOutcome.conflict;
    try {
      // What was written may not be the encoding asked for: a character the
      // document's encoding cannot carry is written as UTF-8 instead. The tab
      // takes that on, or the status bar would go on naming an encoding the
      // file is no longer in.
      final written = await FileService.saveDocumentIfUnchanged(
        tab.filePath!,
        tab.content,
        expect: tab.diskStamp,
        lineEnding: tab.lineEnding,
        encoding: tab.encoding,
      );
      await markSaved(id, written: written);
      return SaveOutcome.saved;
    } on FileChangedOnDiskException {
      return SaveOutcome.conflict;
    } catch (_) {
      return SaveOutcome.failed;
    }
  }

  /// Gives a tab its first file, and writes it there.
  ///
  /// The corner this exists for is one automation can walk into and not walk
  /// out of: a tab made over the socket has no file — `new_tab`'s `path` names
  /// it and nothing more — so a save had nothing to write to, a close was
  /// refused because the tab was modified, and `update_app` was refused
  /// because something was unsaved. Three correct refusals adding up to a tab
  /// nobody could be rid of, and an editor that could not update itself.
  ///
  /// Still never "discard": what an automated caller can be asked for is where
  /// to keep something.
  ///
  /// Only a tab that has no file. Moving a document the reader opened, on an
  /// agent's say-so, is a different act and nobody has asked for it.
  Future<SaveOutcome> _saveAs(TabInfo tab, String to) async {
    if (tab.filePath != null) return SaveOutcome.alreadyHasFile;
    // Relative to what? The editor's working directory is not something the
    // caller can see, so a relative path would land somewhere neither of them
    // chose.
    if (!p.isAbsolute(to)) return SaveOutcome.pathNotAbsolute;
    // No picker on this side to ask about replacing, so this does not.
    if (await File(to).exists()) return SaveOutcome.wouldOverwrite;
    try {
      final written = await FileService.saveDocument(
        to,
        tab.content,
        lineEnding: tab.lineEnding,
        encoding: tab.encoding,
      );
      updateTabPath(tab.id, to, p.basename(to));
      await markSaved(tab.id, written: written);
      return SaveOutcome.saved;
    } catch (_) {
      return SaveOutcome.failed;
    }
  }

  Future<void> _performAutoSave(String tabId) async {
    switch (await saveToDisk(tabId)) {
      case SaveOutcome.conflict:
        // Something else rewrote the file while this document was being
        // edited. Auto-save stops here and says so rather than choosing a
        // winner: the reader's work stays in the tab, and what is on disk
        // stays on disk.
        _setDiskConflict(tabId, true);
      case SaveOutcome.failed:
        // Left marked as modified so the close confirmation still fires and
        // the status bar keeps showing the dot: a silent success here would
        // tell the user their work was written when it was not.
        break;
      case SaveOutcome.saved:
      case SaveOutcome.noTab:
      case SaveOutcome.noFile:
      case SaveOutcome.nothingToWrite:
      // Auto-save never passes a place to save, so these three cannot arise
      // here — named rather than defaulted, so that adding a fourth is a
      // compile error somebody has to think about.
      case SaveOutcome.alreadyHasFile:
      case SaveOutcome.pathNotAbsolute:
      case SaveOutcome.wouldOverwrite:
        break;
    }
  }

  /// Records that a tab's file changed underneath the editor.
  void markDiskConflict(String id) => _setDiskConflict(id, true);

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
  /// Throws when the write fails, rather than answering false.
  ///
  /// False meant two things at once — "there was no file to write to" and
  /// "the write did not work" — and the one caller looked at neither. So a
  /// refused write cleared the conflict banner and left the old bytes on
  /// disk, which is the shape of losing work. The failure now reaches
  /// whoever asked for it, the way saving from the tab bar already did.
  Future<bool> overwriteOnDisk(String id) async {
    final tab = state.tabs.where((t) => t.id == id).firstOrNull;
    if (tab?.filePath == null) return false;
    final written = await FileService.saveDocument(
      tab!.filePath!,
      tab.content,
      lineEnding: tab.lineEnding,
      encoding: tab.encoding,
    );
    await markSaved(id, written: written);
    return true;
  }

  /// Throws away the tab's edits and takes what is on disk.
  ///
  /// Throws when the file cannot be read, like [overwriteOnDisk] and
  /// [rereadAs]. These three are the ways out of the same conflict, and a
  /// reader who chose one and saw nothing change is owed the reason — the
  /// banner correctly stays here, which says the conflict is unresolved and
  /// not why it could not be.
  Future<bool> reloadFromDisk(String id) async {
    final tab = state.tabs.where((t) => t.id == id).firstOrNull;
    if (tab?.filePath == null) return false;
    final opened = await FileService().readFileWithLineEnding(tab!.filePath!);
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
  }

  /// Records that [id] has been written to disk, in [written].
  ///
  /// Awaitable, and the stamp is taken before the state is published rather
  /// than by an unawaited call afterwards. That version left a window: the
  /// write had already changed the file's modification time while the tab
  /// still held the stamp taken before it, so a save landing in that window
  /// compared the file against a stamp older than this application's own
  /// write and called it a conflict — the reader told something else had
  /// changed their file when nothing had but them.
  ///
  /// This is the same shape as BUG-149, in the one place that had kept it:
  /// auto-save has gone through here since then.
  ///
  /// [written] is part of the record and not an afterthought. `saveDocument`
  /// answers with the encoding it actually used, which is not always the one
  /// it was asked for: text holding a character the encoding cannot carry is
  /// written as UTF-8 instead. Three of the four save paths threw that answer
  /// away, so the status bar went on naming an encoding the file was no longer
  /// in — and the "read it again as…" menu beside it would then have decoded a
  /// UTF-8 file as GBK, turning the reader's own document into mojibake. Made
  /// required rather than optional so a fifth save path cannot forget it.
  ///
  /// `stamp ?? t.diskStamp` keeps the old baseline when the stat after a write
  /// fails — a null stamp is not a conflict but *no information*, and the check
  /// would be off for that tab from then on.
  ///
  /// Two methods used to do this one job. They agreed on this point, including
  /// the version that wrote `diskStamp: stamp` and looked as though it did not:
  /// `TabInfo.copyWith` reads a null as "leave it alone", which is what
  /// `clearDiskStamp` exists to override. Saying they disagreed is what the
  /// first version of this comment said, and a mutation of each half came back
  /// green until both were removed at once — two nets, either one enough. The
  /// consolidation was still worth doing; the second bug was not there.
  Future<void> markSaved(String id, {required FileEncoding written}) async {
    final tab = state.tabs.where((t) => t.id == id).firstOrNull;
    final path = tab?.filePath;
    final stamp = path == null ? null : await FileService.stampOf(path);
    if (!mounted) return;
    state = state.copyWith(
      tabs: state.tabs
          .map((t) => t.id == id
              ? t.copyWith(
                  isModified: false,
                  diskConflict: false,
                  diskStamp: stamp ?? t.diskStamp,
                  encoding: written,
                )
              : t)
          .toList(),
    );
  }

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

  /// Rebinds a tab to a different file, after a rename or a "save as".
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
      if (!mounted) return false;
      final existing = state.tabs.where((t) => t.filePath == path).firstOrNull;
      if (existing != null) {
        state = state.copyWith(activeTabId: existing.id);
        continue;
      }
      try {
        final opened = await fileService.readFileWithLineEnding(path);
        // Several files, read one after another: the application can be shut
        // down part way through a batch, and adding a tab then throws.
        if (!mounted) return false;
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

/// How [TabNotifier.saveToDisk] ended.
enum SaveOutcome {
  saved,
  noTab,

  /// Nothing on disk to write to. There is no picker on the automation side,
  /// so this is a refusal there rather than a prompt.
  noFile,
  nothingToWrite,

  /// The file changed underneath the editor, so writing would decide which
  /// version survives — which is the reader's decision.
  conflict,
  failed,

  /// A place to save was given for a tab that already has one. Moving a
  /// document the reader opened is a different act.
  alreadyHasFile,
  pathNotAbsolute,

  /// Something is already there, and this side has no picker to ask with.
  wouldOverwrite,
}
