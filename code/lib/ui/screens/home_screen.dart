import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

import '../../core/config/app_config.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/editor_provider.dart';
import '../../providers/file_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_provider.dart';
import '../../providers/update_provider.dart';
import '../../models/tab_info.dart';
import '../../services/command_registry.dart';
import '../../services/update_service.dart';
import '../../core/constants.dart';
import '../../utils/platform_utils.dart';
import '../widgets/app_menu_bar.dart';
import '../widgets/side_bar.dart';
import '../widgets/status_bar.dart';
import '../widgets/find_replace_bar.dart';
import '../widgets/command_palette.dart';
import '../widgets/editor_tab_bar.dart';
import '../editor/source_editor.dart';
import '../editor/markdown_renderer.dart';
import '../editor/split_editor.dart';
import '../../services/keybinding_service.dart';
import '../../services/file_service.dart';
import '../../models/file_encoding.dart';
import '../../models/line_ending.dart';
import '../../core/diagnostics/startup_trace.dart';
import '../../utils/file_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

/// What the user chose when asked about unsaved work on exit.
enum _ExitChoice { cancel, discard, save }

class _HomeScreenState extends ConsumerState<HomeScreen> with WindowListener {
  bool _startupFilesProcessed = false;
  bool _updateCheckDone = false;
  bool _sideBarRestored = false;

  @override
  void initState() {
    super.initState();
    StartupTrace.mark('home screen initState');
    // The listener lives here rather than above MaterialApp because closing
    // has to be able to show a dialog, which needs a Navigator and the
    // localisations in scope.
    windowManager.addListener(this);
    _preventCloseWhileUnsaved();

    // Run startup side-effects after the first frame so we don't mutate
    // providers during the widget tree build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StartupTrace.mark('first frame painted');
      if (!mounted) return;
      _openStartupFiles();
      _checkForUpdates();
      _restoreSideBarDirectory();
      StartupTrace.mark('startup side-effects dispatched');
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _preventCloseWhileUnsaved() async {
    try {
      await windowManager.setPreventClose(true);
    } catch (_) {
      // No window to manage; the app simply closes as before.
    }
  }

  /// Intercepts the window's close button.
  ///
  /// Closing the window used to end the process outright, discarding every
  /// modified tab at once — the same loss as closing a tab, over the whole
  /// session.
  @override
  void onWindowClose() async {
    StartupTrace.mark('close requested');
    final unsaved = ref
        .read(tabProvider)
        .tabs
        .where((t) => t.isModified)
        .toList();

    if (unsaved.isEmpty || !mounted) {
      // The common path: geometry has to be recorded here too, or it would
      // only ever be saved when something was left unsaved.
      await _saveWindowGeometry();
      StartupTrace.mark('window geometry saved');
      // The marks around this live inside stopWatchingFiles itself; repeating
      // them here printed each one twice and made the close look as if it had
      // run through the handler two times.
      ref.read(tabProvider.notifier).stopWatchingFiles();
      // Written before destroy: the call may not return.
      StartupTrace.flush();
      StartupTrace.armShutdownWatchdog();
      await windowManager.destroy();
      StartupTrace.mark('window destroyed');
      StartupTrace.flush();
      return;
    }

    final choice = await _askAboutUnsavedOnExit(unsaved);
    if (choice == null || choice == _ExitChoice.cancel) return;

    if (choice == _ExitChoice.save) {
      for (final tab in unsaved) {
        final saved = await EditorTabBar.saveTab(ref, tab);
        // Abandoning one save abandons the exit: quitting anyway would lose
        // exactly the work the user asked to keep.
        if (!saved) return;
      }
    }

    await _saveWindowGeometry();
    StartupTrace.mark('window geometry saved (after prompt)');
    ref.read(tabProvider.notifier).stopWatchingFiles();
    StartupTrace.flush();
    StartupTrace.armShutdownWatchdog();
    await windowManager.destroy();
    StartupTrace.mark('window destroyed');
    StartupTrace.flush();
  }

  /// Records the window's size, position and maximised state for next launch.
  ///
  /// Done here because the window still exists; the previous attempt ran on
  /// AppLifecycleState.detached, by which point position was unreachable — it
  /// wrote zeros and false over whatever had been stored.
  Future<void> _saveWindowGeometry() async {
    try {
      // Together rather than one after another: three independent reads over
      // the platform channel, each a round trip to the Windows thread, and
      // they were being waited on in sequence while the window sat there.
      final (maximized, size, position) = await (
        windowManager.isMaximized(),
        windowManager.getSize(),
        windowManager.getPosition(),
      ).wait;
      StartupTrace.mark('window bounds read');

      await ref
          .read(settingsProvider.notifier)
          .saveWindowState(
            width: size.width,
            height: size.height,
            x: position.dx,
            y: position.dy,
            isMaximized: maximized,
          );
      StartupTrace.mark('window state written to config');
    } catch (_) {
      // Nothing to record without a window; closing continues regardless.
      StartupTrace.mark('window geometry could not be read');
    }
  }

  Future<_ExitChoice?> _askAboutUnsavedOnExit(List<TabInfo> unsaved) {
    final l10n = AppLocalizations.of(context)!;
    const maxListed = 5;
    final names = unsaved.take(maxListed).map((t) => t.fileName).join('\n');
    final extra = unsaved.length > maxListed
        ? '\n… ${unsaved.length - maxListed}'
        : '';

    return showDialog<_ExitChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text('$names$extra\n\n${l10n.unsavedChangesMessage}'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ExitChoice.cancel),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ExitChoice.discard),
            child: Text(l10n.dontSave),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(_ExitChoice.save),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _restoreSideBarDirectory() {
    if (_sideBarRestored) return;
    _sideBarRestored = true;

    final config = ref.read(settingsProvider);
    if (config.sideBarDirectory.isNotEmpty) {
      final dir = Directory(config.sideBarDirectory);
      if (dir.existsSync()) {
        ref.read(fileProvider.notifier).loadDirectory(config.sideBarDirectory);
      }
    }
    if (config.sideBarOpenedFiles.isNotEmpty) {
      ref
          .read(tabProvider.notifier)
          .restoreOpenedFiles(config.sideBarOpenedFiles);
    }
  }

  void _checkForUpdates() async {
    if (_updateCheckDone) return;
    _updateCheckDone = true;

    final config = ref.read(settingsProvider);
    final lastCheck = DateTime.tryParse(config.lastUpdateCheck);
    final now = DateTime.now();

    if (lastCheck != null && now.difference(lastCheck).inHours < 24) return;

    await ref
        .read(settingsProvider.notifier)
        .updateConfig(
          (c) => c.copyWith(lastUpdateCheck: now.toIso8601String()),
        );

    // The automatic check stays quiet when it cannot reach GitHub; only a
    // check the user asked for reports that.
    final update = (await UpdateService.checkForUpdate(AppConstants.appVersion))
        .update;
    if (update != null && update.version != config.skipVersion) {
      ref.read(updateProvider.notifier).setUpdate(update);
    }
  }

  /// The localisations the command palette was last filled from.
  ///
  /// [build] runs on every cursor move, because it watches the editor state,
  /// and rebuilding thirty commands with their formatted labels each time was
  /// pure garbage. The command list only depends on the language.
  AppLocalizations? _commandsBuiltFrom;

  void _registerCommands(AppLocalizations l10n) {
    if (identical(_commandsBuiltFrom, l10n)) return;
    _commandsBuiltFrom = l10n;

    final registry = CommandRegistry.instance;
    registry.clear();

    // Format actions
    final formatLabels = {
      FormatAction.bold: l10n.formatBold,
      FormatAction.italic: l10n.formatItalic,
      FormatAction.strikethrough: l10n.formatStrikethrough,
      FormatAction.heading1: l10n.formatHeading(1),
      FormatAction.heading2: l10n.formatHeading(2),
      FormatAction.heading3: l10n.formatHeading(3),
      FormatAction.heading4: l10n.formatHeading(4),
      FormatAction.heading5: l10n.formatHeading(5),
      FormatAction.heading6: l10n.formatHeading(6),
      FormatAction.orderedList: l10n.formatOrderedList,
      FormatAction.unorderedList: l10n.formatUnorderedList,
      FormatAction.taskList: l10n.formatTaskList,
      FormatAction.codeBlock: l10n.formatCodeBlock,
      FormatAction.quoteBlock: l10n.formatQuoteBlock,
      FormatAction.mathBlock: l10n.formatMathBlock,
      FormatAction.table: l10n.formatTable,
      FormatAction.link: l10n.formatLink,
      FormatAction.image: l10n.formatImage,
      FormatAction.horizontalRule: l10n.formatHorizontalRule,
      FormatAction.frontMatter: l10n.formatFrontMatter,
      FormatAction.htmlBlock: l10n.formatHtmlBlock,
      // The seventeen that the menu offered and this map did not, so they were
      // in every menu and unreachable from the palette. Both go through the
      // same applyFormat, so the only thing that had been missing was the
      // entry here — which is exactly the kind of omission a second list of
      // the same things produces.
      FormatAction.underline: l10n.formatUnderline,
      FormatAction.highlight: l10n.formatHighlight,
      FormatAction.superscript: l10n.formatSuperscript,
      FormatAction.subscript: l10n.formatSubscript,
      FormatAction.inlineCode: l10n.formatInlineCode,
      FormatAction.inlineMath: l10n.formatInlineMath,
      FormatAction.clearFormatting: l10n.formatClearFormatting,
      FormatAction.copyAsMarkdown: l10n.editCopyAsMarkdown,
      FormatAction.copyAsHtml: l10n.editCopyAsHtml,
      FormatAction.selectAll: l10n.editSelectAll,
      FormatAction.duplicateLine: l10n.editDuplicateLine,
      FormatAction.promoteHeading: l10n.paragraphPromoteHeading,
      FormatAction.demoteHeading: l10n.paragraphDemoteHeading,
      FormatAction.toParagraph: l10n.paragraphToParagraph,
      FormatAction.looseList: l10n.paragraphLooseList,
      FormatAction.createParagraph: l10n.editCreateParagraph,
      FormatAction.deleteParagraph: l10n.editDeleteParagraph,
    };

    for (final entry in formatLabels.entries) {
      registry.register(
        Command(
          id: 'format.${entry.key.name}',
          label: l10n.commandFormatLabel(entry.value),
          description: l10n.commandFormatDesc(entry.value),
          execute: () =>
              ref.read(editorProvider.notifier).applyFormat(entry.key),
        ),
      );
    }

    // File operations
    registry.registerAll([
      Command(
        id: 'file.new',
        label: l10n.commandNewFile,
        description: l10n.commandNewFileDesc,
        execute: () => AppMenuBar.newFile(ref, l10n),
      ),
      Command(
        id: 'file.save',
        label: l10n.commandSave,
        description: l10n.commandSaveDesc,
        execute: () => AppMenuBar.saveFile(ref),
      ),
    ]);

    // View commands
    registry.registerAll([
      Command(
        id: 'view.source',
        label: l10n.commandSourceMode,
        description: l10n.commandSourceModeDesc,
        execute: () =>
            ref.read(settingsProvider.notifier).setEditMode(EditMode.source),
      ),
      Command(
        id: 'view.preview',
        label: l10n.commandPreviewMode,
        description: l10n.commandPreviewModeDesc,
        execute: () =>
            ref.read(settingsProvider.notifier).setEditMode(EditMode.preview),
      ),
      Command(
        id: 'view.split',
        label: l10n.commandSplitMode,
        description: l10n.commandSplitModeDesc,
        execute: () =>
            ref.read(settingsProvider.notifier).setEditMode(EditMode.split),
      ),
      Command(
        id: 'view.focusMode',
        label: l10n.commandToggleFocusMode,
        description: l10n.commandToggleFocusModeDesc,
        execute: () => ref.read(settingsProvider.notifier).toggleFocusMode(),
      ),
      Command(
        id: 'view.typewriterMode',
        label: l10n.commandToggleTypewriterMode,
        description: l10n.commandToggleTypewriterModeDesc,
        execute: () =>
            ref.read(settingsProvider.notifier).toggleTypewriterMode(),
      ),
      Command(
        id: 'view.sidebar',
        label: l10n.commandToggleSidebar,
        description: l10n.commandToggleSidebarDesc,
        execute: () => ref.read(settingsProvider.notifier).toggleSideBar(),
      ),
      Command(
        id: 'view.tabbar',
        label: l10n.commandToggleTabBar,
        description: l10n.commandToggleTabBarDesc,
        execute: () => ref.read(settingsProvider.notifier).toggleTabBar(),
      ),
    ]);
  }


  void _openStartupFiles() async {
    if (_startupFilesProcessed) return;
    _startupFilesProcessed = true;

    final files = ref.read(startupFilesProvider);
    if (files.isEmpty) return;

    // Opening behaviour is a preference, not a question to ask on launch.
    // `notSet` simply means "use the current window"; Settings is where it
    // gets changed. Upstream MarkText behaves the same way.

    for (final path in files) {
      try {
        // Create tab with loading state first
        final tabId = DateTime.now().millisecondsSinceEpoch.toString();
        final tab = TabInfo(
          id: tabId,
          filePath: path,
          fileName: p.basename(path),
          content: '',
          isLoading: true,
        );
        ref.read(tabProvider.notifier).addTab(tab);
        StartupTrace.mark('loading tab added');

        // Force a frame to render the loading indicator
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            StartupTrace.mark('loading frame painted');
            final bytes = await _readDocument(path);
            StartupTrace.mark('file read (${bytes.length} bytes)');
            final (raw, encoding) = FileEncoding.decode(bytes);
            StartupTrace.mark('decoded (${encoding.name})');
            ref
                .read(tabProvider.notifier)
                .loadTabContent(
                  tabId,
                  FileService.normalizeLineEndings(raw),
                  lineEnding: LineEnding.detect(raw),
                  encoding: encoding,
                );
            StartupTrace.mark('content handed to the tab');
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => StartupTrace.mark('document painted'),
            );
          } catch (e) {
            // Handle error: remove the loading tab or show error state
            ref.read(tabProvider.notifier).removeTab(tabId);
          }
        });

        ref.read(settingsProvider.notifier).addRecentFile(path);
      } catch (_) {
        // A file named on the command line that cannot be opened is skipped;
        // the others still open. The inner catch above has already removed
        // the tab that was created for it.
      }
    }
  }

  /// Reads [path] off the UI isolate.
  ///
  /// Returns the bytes as they are: the encoding and the line endings are
  /// worked out on the main isolate, where the result is needed anyway,
  /// rather than sending a record across the boundary.
  ///
  /// Bytes rather than a string because `readAsString` throws on anything but
  /// UTF-8, and the catch around this call removes the tab — so a file in any
  /// other encoding used to open and vanish.
  static Future<Uint8List> _readFileInIsolate(String path) async {
    return File(path).readAsBytes();
  }

  /// Above this size, reading moves off the UI isolate.
  ///
  /// Measured rather than guessed: reading and decoding 10 MiB costs tens of
  /// milliseconds, so half a megabyte is far inside one frame. Below the
  /// threshold the isolate is pure overhead — and the *first* `compute` in a
  /// process has to start an isolate and load the app snapshot, which is
  /// exactly the one that runs while the user waits for their document.
  static const _isolateReadThreshold = 512 * 1024;

  /// Reads [path], going off the UI isolate only when that is worth doing.
  static Future<Uint8List> _readDocument(String path) async {
    final file = File(path);
    var small = false;
    try {
      small = await file.length() <= _isolateReadThreshold;
    } on FileSystemException {
      // Let the read itself report the problem, as it did before.
    }
    // Awaited inside no try: a failure here has to reach the caller, which is
    // what removes the tab it created.
    if (small) return file.readAsBytes();
    return compute(_readFileInIsolate, path);
  }

  void _handleDrop(DropDoneDetails details) async {
    // The shared list, not a private copy: this one had three of the seven
    // extensions the rest of the program accepts, so dropping a `.mmd` or a
    // `.mdown` did nothing whatever.
    final allowedExtensions = FileUtils.markdownExtensionsWithDot;
    var refused = 0;

    for (final file in details.files) {
      final path = file.path;

      // Check if it's a directory
      final entity = FileSystemEntity.typeSync(path);
      if (entity == FileSystemEntityType.directory) {
        // Open the folder in the file tree
        await ref.read(fileProvider.notifier).loadDirectory(path);
        await ref
            .read(settingsProvider.notifier)
            .updateConfig((c) => c.copyWith(sideBarDirectory: path));
        continue;
      }

      // Handle files
      final ext = p.extension(path).toLowerCase();
      if (!allowedExtensions.contains(ext)) {
        // Counted rather than passed over: a window that swallows what is
        // dropped on it and says nothing looks broken.
        refused++;
        continue;
      }

      try {
        // Create tab with loading state first
        final tabId = DateTime.now().millisecondsSinceEpoch.toString();
        final tab = TabInfo(
          id: tabId,
          filePath: path,
          fileName: p.basename(path),
          content: '',
          isLoading: true,
        );
        ref.read(tabProvider.notifier).addTab(tab);

        // Force a frame to render the loading indicator
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            final bytes = await _readDocument(path);
            final (raw, encoding) = FileEncoding.decode(bytes);
            ref
                .read(tabProvider.notifier)
                .loadTabContent(
                  tabId,
                  FileService.normalizeLineEndings(raw),
                  lineEnding: LineEnding.detect(raw),
                  encoding: encoding,
                );
          } catch (e) {
            ref.read(tabProvider.notifier).removeTab(tabId);
          }
        });

        ref.read(settingsProvider.notifier).addRecentFile(path);
      } catch (_) {
        // Skip files that can't be read
      }
    }

    if (refused > 0 && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dropNotMarkdown(refused))),
      );
    }
  }

  /// Runs the window-level action bound to [event], if any.
  ///
  /// Flutter's MenuItemButton.shortcut only *displays* a shortcut — "shortcuts
  /// are not automatically handled", per its own documentation — so every
  /// shortcut in the menus was decorative. This handles the ones that are not
  /// about the text: opening, saving, find and replace.
  ///
  /// Anything that edits the document is handled inside [SourceEditor]
  /// instead, so that Ctrl+A and friends still belong to the find bar or a
  /// settings field when that is where the caret is.
  bool _runShortcut(KeyEvent event) {
    final action = KeybindingService().actionForEvent(
      event,
      isMacOS: PlatformUtils.isMacOS,
    );
    if (action == null) return false;

    final editor = ref.read(editorProvider.notifier);
    switch (action) {
      case 'find':
      case 'replace':
        editor.toggleFindReplace();
        return true;
      case 'save':
        AppMenuBar.saveFile(ref);
        return true;
      case 'open':
        AppMenuBar.openFile(ref);
        return true;
      case 'findNext':
        editor.stepToFindMatch(forward: true);
        return true;
      case 'findPrevious':
        editor.stepToFindMatch(forward: false);
        return true;
      case 'closeTab':
        final tab = ref.read(activeTabProvider);
        if (tab != null) EditorTabBar.closeTab(context, ref, tab);
        return true;

      // The view actions, answered here as well as by the menu because focus
      // mode takes the menu bar out of the tree — and with it every shortcut
      // the menu registers, including the one that leaves focus mode.
      //
      // Written out as key comparisons once (Ctrl+Alt+1, Ctrl+Shift+B and the
      // rest), which held only while the table said the same thing: rebinding
      // one in Settings left the old key working here.
      case 'commandPalette':
        CommandPalette.show(context);
        return true;
      case 'sourceMode':
        ref.read(settingsProvider.notifier).setEditMode(EditMode.source);
        return true;
      case 'previewMode':
        ref.read(settingsProvider.notifier).setEditMode(EditMode.preview);
        return true;
      case 'splitMode':
        ref.read(settingsProvider.notifier).setEditMode(EditMode.split);
        return true;
      case 'toggleTabBar':
        ref.read(settingsProvider.notifier).toggleTabBar();
        return true;
      case 'toggleSidebar':
        ref.read(settingsProvider.notifier).toggleSideBar();
        return true;
      case 'focusMode':
        ref.read(settingsProvider.notifier).toggleFocusMode();
        return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    StartupTrace.markOnce('home screen first build');
    final config = ref.watch(settingsProvider);
    // Only the find bar's visibility is read here. Watching the whole editor
    // state rebuilt this entire screen on every cursor move.
    final showFindReplace = ref.watch(
      editorProvider.select((s) => s.showFindReplace),
    );
    final l10n = AppLocalizations.of(context)!;

    _registerCommands(l10n);

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        // Escape is not a rebindable action; the rest come from the table.
        if (config.focusMode && event.logicalKey == LogicalKeyboardKey.escape) {
          ref.read(settingsProvider.notifier).toggleFocusMode();
          return KeyEventResult.handled;
        }
        if (showFindReplace && event.logicalKey == LogicalKeyboardKey.escape) {
          ref.read(editorProvider.notifier).hideFindReplace();
          return KeyEventResult.handled;
        }

        return _runShortcut(event)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      },
      child: Scaffold(
        body: DropTarget(
          onDragDone: _handleDrop,
          child: Column(
            children: [
              if (!config.focusMode) const AppMenuBar(),
              Expanded(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: config.sideBarVisible && !config.focusMode
                          ? 280
                          : 0,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(),
                      child: config.sideBarVisible && !config.focusMode
                          ? const SideBar()
                          : null,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: config.tabBarVisible && !config.focusMode
                                ? const EditorTabBar()
                                : const SizedBox.shrink(),
                          ),
                          if (showFindReplace)
                            Builder(
                              builder: (context) {
                                final controller = ref
                                    .read(editorProvider.notifier)
                                    .controller;
                                final activeTab = ref.watch(activeTabProvider);
                                final isSplit =
                                    config.editMode == EditMode.split;
                                if (isSplit &&
                                    controller != null &&
                                    activeTab != null) {
                                  return FindReplaceBar(
                                    textController: controller,
                                    rawContent: activeTab.content,
                                    isSplitMode: true,
                                  );
                                } else if (controller != null) {
                                  return FindReplaceBar(
                                    textController: controller,
                                  );
                                } else if (activeTab != null) {
                                  return FindReplaceBar(
                                    rawContent: activeTab.content,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          Expanded(child: _zoomable(_buildEditorArea(config.editMode))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!config.focusMode) const StatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// Wraps the editing area so Ctrl and the wheel change the text size.
  ///
  /// Asked for in #4: the zoom commands sit on Ctrl+Shift+= and Ctrl+Shift+-,
  /// because Ctrl+= and Ctrl+- are what promotes and demotes a heading here,
  /// and the reporter's point stands — the wheel is the gesture people reach
  /// for, and it needs no key to be free.
  Widget _zoomable(Widget child) {
    return Listener(
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        if (!HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isMetaPressed) {
          return;
        }
        // Up is bigger, as it is everywhere else.
        final step = event.scrollDelta.dy < 0 ? 1.0 : -1.0;
        final config = ref.read(settingsProvider);
        final size = (config.fontSize + step).clamp(_minZoom, _maxZoom);
        if (size == config.fontSize) return;
        ref.read(settingsProvider.notifier).setFontSize(size);
      },
      child: child,
    );
  }

  /// The range the zoom commands and the wheel share.
  static const _minZoom = 12.0;
  static const _maxZoom = 32.0;

  Widget _buildEditorArea(EditMode editMode) {
    final activeTab = ref.watch(activeTabProvider);
    if (activeTab == null) {
      final l10n = AppLocalizations.of(context)!;
      final tokens = AppTheme.getTokens(ref.watch(settingsProvider).themeName);
      final isMac = PlatformUtils.isMacOS;
      final mod = isMac ? '\u2318' : 'Ctrl';
      return Center(
        child: Opacity(
          opacity: 0.6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'MarkText Plus',
                style: TextStyle(fontSize: 24, color: tokens.colorTextMuted),
              ),
              const SizedBox(height: 24),
              Text(
                '$mod+N    ${l10n.welcomeNewFile}',
                style: TextStyle(fontSize: 13, color: tokens.colorTextMuted),
              ),
              const SizedBox(height: 6),
              Text(
                '$mod+O    ${l10n.welcomeOpenFile}',
                style: TextStyle(fontSize: 13, color: tokens.colorTextMuted),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.welcomeDragHint,
                style: TextStyle(fontSize: 13, color: tokens.colorTextMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (activeTab.isLoading) {
      final tokens = AppTheme.getTokens(ref.watch(settingsProvider).themeName);
      return Center(
        key: ValueKey('loading_${activeTab.id}'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(tokens.colorAccent),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              activeTab.fileName,
              style: TextStyle(
                fontSize: 14,
                color: tokens.colorTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 12,
                color: tokens.colorTextMuted.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    final content = activeTab.content;

    void onContentChanged(String newContent) {
      ref.read(tabProvider.notifier).updateContent(activeTab.id, newContent);
    }

    // Use IndexedStack to keep all editor states, avoiding rebuild on mode switch
    final currentIndex = editMode.index;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      switchInCurve: Curves.easeOut,
      child: IndexedStack(
        key: ValueKey('editors_${activeTab.id}_$currentIndex'),
        index: currentIndex,
        sizing: StackFit.expand,
        children: [
          // EditMode.source (index 0)
          _DeferredEditorBuilder(
            key: ValueKey('source_${activeTab.id}'),
            shouldBuild: currentIndex == 0,
            builder: () => SourceEditor(
              key: ValueKey('source_inner_${activeTab.id}'),
              tabId: activeTab.id,
              initialContent: content,
              // Without this the editor never adopts a reload: it deliberately
              // ignores a content change it cannot tell apart from its own
              // typing, and the revision is what tells it apart.
              externalRevision: activeTab.externalRevision,
              onChanged: onContentChanged,
            ),
          ),
          // EditMode.preview (index 1)
          _DeferredEditorBuilder(
            key: ValueKey('preview_${activeTab.id}'),
            shouldBuild: currentIndex == 1,
            builder: () => MarkdownRenderer(
              key: ValueKey('preview_inner_${activeTab.id}'),
              markdown: content,
              onSourceChanged: onContentChanged,
            ),
          ),
          // EditMode.split (index 2)
          _DeferredEditorBuilder(
            key: ValueKey('split_${activeTab.id}'),
            shouldBuild: currentIndex == 2,
            builder: () => SplitEditor(
              key: ValueKey('split_inner_${activeTab.id}'),
              tabId: activeTab.id,
              initialContent: content,
              externalRevision: activeTab.externalRevision,
              onChanged: onContentChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Deferred editor builder that shows a skeleton screen while building
class _DeferredEditorBuilder extends StatefulWidget {
  const _DeferredEditorBuilder({
    super.key,
    required this.shouldBuild,
    required this.builder,
  });

  final bool shouldBuild;
  final Widget Function() builder;

  @override
  State<_DeferredEditorBuilder> createState() => _DeferredEditorBuilderState();
}

class _DeferredEditorBuilderState extends State<_DeferredEditorBuilder> {
  Widget? _cachedWidget;
  bool _isBuilding = false;

  @override
  void didUpdateWidget(_DeferredEditorBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldBuild && !oldWidget.shouldBuild && _cachedWidget == null) {
      _startBuild();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.shouldBuild) {
      _startBuild();
    }
  }

  void _startBuild() {
    if (_isBuilding || _cachedWidget != null) return;
    _isBuilding = true;

    // Defer build to next frame to show skeleton first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _cachedWidget = widget.builder();
        _isBuilding = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedWidget != null) {
      return _cachedWidget!;
    }

    // Show skeleton screen while building
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
