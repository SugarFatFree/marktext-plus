import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/mcp_provider.dart';
import '../../providers/plugin_provider.dart';
import '../../services/mcp_tools.dart';
import '../../services/plugin_manifest.dart';
import '../../services/plugin_script_runtime.dart';
import '../editor/markdown_renderer.dart';
import 'plugin_apply.dart';
import 'plugin_command_actions.dart';
import 'plugin_icons.dart';
import 'plugin_ui_view.dart';
import '../../services/plugin_ui.dart';

/// The rail of plugin panels down the right-hand side, and the drawer one of
/// them opens.
///
/// `ui.sidebar` was a permission a plugin could ask for and nothing acted on.
/// With nothing contributed there is no rail: a strip of icons with no icons
/// in it is width taken from the document for nothing.
class RightSideBar extends ConsumerStatefulWidget {
  const RightSideBar({super.key});

  @override
  ConsumerState<RightSideBar> createState() => _RightSideBarState();
}

class _RightSideBarState extends ConsumerState<RightSideBar> {
  /// `pluginId/panelId` of the open drawer, or null when only the rail shows.
  String? _open;

  /// The question the running command is waiting on, asked in this drawer.
  ///
  /// The card is where a plugin asks from a menu, and it is the right place
  /// there. Started from this bar it was the wrong one: the question floated
  /// over the document and the answer arrived in the drawer, so one exchange
  /// happened in two places and the panel looked like a pop-up.
  String? _question;
  List<String> _choices = const [];
  Completer<String?>? _answering;
  late final TextEditingController _answer = TextEditingController();

  /// What the panel's command last returned, so the drawer has something to
  /// draw before — and if — the plugin answers again.
  String _content = '';

  /// What the plugin said about [_content]: that it is a rewrite the reader
  /// may accept, and which text it replaces. Dropped on the floor until now,
  /// so the rail showed an answer it gave no way to take.
  bool _canApply = false;
  String _replaces = '';
  String _pluginName = '';

  /// How the plugin asked for its answer to be drawn. The pane grid has read
  /// this from the start — a translation is rendered beside a preview and left
  /// as source beside source — while the drawer showed every answer as plain
  /// text, so a rewrite arrived with its `##` and `**` on show.
  PluginPaneRender _render = PluginPaneRender.text;

  /// Whether the command that fills this drawer is still running.
  ///
  /// Taken from the run itself rather than from the pane's `busy`, which the
  /// drawer never sees: the answer is what `runInto` is awaiting, so it is
  /// still coming until that returns. Without it the reader answered the
  /// question and watched an empty drawer for as long as the model took.
  bool _running = false;

  /// What to answer a panel's question while automation is driving, or null
  /// when a reader is.
  String? _automaticAnswer;

  /// A tree the plugin drew, and where the reader's use of it is collected.
  ///
  /// Drawn here rather than in the card: the reader opened this drawer, so
  /// this is where they are looking. The card is for commands started
  /// somewhere that has no room of its own.
  PluginUiNode? _ui;
  Completer<PluginUiEvent?>? _pending;
  Future<Uint8List> Function(String source)? _images;

  void _closeUi() {
    final pending = _pending;
    _ui = null;
    _pending = null;
    _images = null;
    // A form nobody submitted is a form that was declined, and the run
    // waiting on it has to be told.
    if (pending != null && !pending.isCompleted) pending.complete(null);
    _answering = null;
    _question = null;
    _choices = const [];
  }

  /// Hands [answer] back to the command that asked, or refuses it.
  void _answered(String? answer) {
    final pending = _answering;
    setState(() {
      _question = null;
      _choices = const [];
      _answering = null;
    });
    if (pending != null && !pending.isCompleted) pending.complete(answer);
  }

  /// Refuses the question the drawer is showing, if it is showing one.
  ///
  /// Closing the drawer is how the reader says no. Not called from `dispose`:
  /// answering wakes the command up to finish, and what it does then reads
  /// providers that are going away with the widget.
  void _cancelQuestion() {
    final pending = _answering;
    _answering = null;
    if (pending != null && !pending.isCompleted) pending.complete(null);
  }

  @override
  void initState() {
    super.initState();
    // Registered here rather than in the screen, because the drawer is this
    // widget's own state: a panel's answer lands in it, and nothing outside
    // can read it or put a question's answer back.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(mcpProvider.notifier).openPluginPanel = _openForAutomation;
      }
    });
  }

  @override
  void dispose() {
    _closeUi();
    _answer.dispose();
    super.dispose();
  }

  /// Presses the rail icon for [panelId] and says what the drawer showed.
  ///
  /// [answer] is what to reply if the panel asks something. Without it the
  /// command waits for a reader who is not there, so an agent driving this
  /// should give one whenever the panel is known to ask — which is exactly
  /// what a reader does.
  Future<McpOutcome> _openForAutomation(
    String pluginId,
    String panelId,
    String? answer,
  ) async {
    final plugins =
        ref.read(installedPluginManifestsProvider).valueOrNull ??
        const <PluginManifest>[];
    final plugin = plugins.where((p) => p.id == pluginId).firstOrNull;
    if (plugin == null) {
      return mcpRefused('no plugin called "$pluginId" is installed');
    }
    if (!plugin.hasPermission(PluginPermission.uiSidebar)) {
      return mcpRefused(
        '"$pluginId" did not ask for ${PluginPermission.uiSidebar}, so it '
        'draws no icon in the rail',
      );
    }
    final panel = plugin.panels.where((p) => p.id == panelId).firstOrNull;
    if (panel == null) {
      return mcpRefused(
        '"$pluginId" has no panel "$panelId"; it has '
        '${plugin.panels.map((p) => p.id).join(', ')}',
      );
    }

    // Closed first when it is already open, so this always means "press the
    // icon to open", not "toggle whatever it is now".
    if (_open == '$pluginId/$panelId') await _toggle(plugin, panel);
    _automaticAnswer = answer;
    try {
      await _toggle(plugin, panel);
    } finally {
      _automaticAnswer = null;
    }
    if (!mounted) return mcpRefused('the window is gone');
    return mcpDid(
      _content.isEmpty
          ? 'the ${panel.id} panel is open and showing nothing'
          : 'the ${panel.id} panel says: $_content',
    );
  }

  /// The table moved to `plugin_icons.dart` when it turned out to be seven
  /// entries against a plugin asking for an eighth.
  static IconData icon(String name) => PluginIcons.resolve(name);

  /// Puts what the drawer is showing into the document.
  ///
  /// Closes the drawer on success, the way accepting a pane closes the pane:
  /// the answer has been taken, and leaving it up invites taking it twice.
  void _applyContent() {
    final applied = PluginApply.into(
      ref,
      context,
      pluginName: _pluginName,
      replaces: _replaces,
      text: _content,
    );
    if (applied && mounted) {
      setState(() {
        _open = null;
        _content = '';
        _canApply = false;
        _replaces = '';
      });
    }
  }

  Future<void> _toggle(PluginManifest plugin, PluginSidePanel panel) async {
    final key = '${plugin.id}/${panel.id}';
    if (_open == key) {
      _cancelQuestion();
      setState(() {
        _open = null;
        _closeUi();
      });
      return;
    }
    _cancelQuestion();
    setState(() {
      _open = key;
      _content = '';
      _canApply = false;
      _replaces = '';
      _render = PluginPaneRender.text;
      _closeUi();
    });
    // Filled by running the plugin's command of the same id: a panel is a
    // command with a place to put its answer, so there is no second way for a
    // plugin to draw and no second thing for the editor to render.
    //
    // The whole command, not one step of it. It used to be one step, so a
    // plugin that asks a question first — which the one official plugin does
    // — filled the drawer with the sentence "a panel cannot ask a question"
    // and there was nowhere to type an answer. The question is asked in the
    // card, the same as from a menu; what comes back lands here.
    setState(() => _running = true);
    try {
        await PluginCommandActions.runInto(
        ref,
        context: context,
        plugin: plugin,
        command: panel.id,
        into: (
          text, {
          bool append = false,
          bool canApply = false,
          String replaces = '',
          PluginPaneRender render = PluginPaneRender.text,
        }) {
          if (!mounted || _open != key) return;
          setState(() {
            _closeUi();
            _content = append ? '$_content\n\n$text' : text;
            _canApply = canApply;
            _replaces = replaces;
            _render = render;
            _pluginName = plugin.name;
          });
        },
        onAsk: ({
          required String question,
          required List<String> choices,
          required String suggested,
        }) {
          if (!mounted || _open != key) return Future.value(null);
          // Being driven: answer as a reader would rather than waiting for one.
          final automatic = _automaticAnswer;
          if (automatic != null) return Future.value(automatic);
          final completer = Completer<String?>();
          setState(() {
            _content = '';
            _ui = null;
            _question = question;
            _choices = choices;
            _answering = completer;
            _answer.text = suggested;
          });
          return completer.future;
        },
        onUi: (root, title, images) {
          if (!mounted || _open != key) return Future.value(null);
          final completer = Completer<PluginUiEvent?>();
          setState(() {
            _content = '';
            _ui = root;
            _images = images;
            _pending = completer;
          });
          return completer.future;
        },
      );
    } finally {
      // However it ended — finished, refused or threw — nothing more is
      // coming, and a drawer left spinning would be the editor saying
      // something untrue about itself.
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plugins = ref.watch(installedPluginManifestsProvider).valueOrNull ??
        const <PluginManifest>[];
    final contributions = [
      for (final plugin in plugins)
        if (plugin.hasPermission(PluginPermission.uiSidebar))
          for (final panel in plugin.panels) (plugin, panel),
    ];
    if (contributions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    String label((PluginManifest, PluginSidePanel) c) =>
        c.$1.stringsFor(locale)[c.$2.title] ?? c.$2.title;

    final open = contributions
        .where((c) => '${c.$1.id}/${c.$2.id}' == _open)
        .firstOrNull;

    return Row(
      children: [
        if (open != null) ...[
          VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Text(label(open), style: theme.textTheme.titleSmall),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: _question != null
                        ? _AskInDrawer(
                            question: _question!,
                            choices: _choices,
                            controller: _answer,
                            onAnswered: _answered,
                          )
                        : _ui != null
                        ? PluginUiView(
                            root: _ui!,
                            loadImage: _images,
                            onEvent: (id, values) {
                              final pending = _pending;
                              setState(() {
                                _ui = null;
                                _pending = null;
                              });
                              if (pending != null && !pending.isCompleted) {
                                pending.complete((id: id, values: values));
                              }
                            },
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nothing to read yet and still running: say so.
                              // An empty drawer after answering a question
                              // looks exactly like one that failed.
                              if (_running && _content.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              // Drawn the way the plugin asked for, which is
                              // what the pane grid has always done: a rewrite
                              // meant to be read as a document is rendered,
                              // not shown with its markup on display.
                              if (_content.isNotEmpty)
                                _render == PluginPaneRender.preview
                                    ? MarkdownRenderer(markdown: _content)
                                    : SelectableText(_content),
                              // More still coming, with some of it already
                              // readable.
                              if (_running && _content.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                              // The same offer the pane grid makes for the
                              // same answer. Without it the rail could show a
                              // rewrite and give no way to take it.
                              if (_canApply && !_running) ...[
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  key: const Key('plugin-drawer-apply'),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: Text(
                                    AppLocalizations.of(context)?.pluginApply ??
                                        '',
                                  ),
                                  onPressed: _applyContent,
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
        VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
        Container(
          width: 44,
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              const SizedBox(height: 6),
              for (final c in contributions)
                IconButton(
                  tooltip: label(c),
                  isSelected: '${c.$1.id}/${c.$2.id}' == _open,
                  icon: Icon(icon(c.$2.icon), size: 20),
                  onPressed: () => _toggle(c.$1, c.$2),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The question a command asked, in the drawer its answer will fill.
///
/// Deliberately the same three parts the card offers — the question, whatever
/// answers the plugin named, and a box already holding what was chosen last
/// time — so that starting a command here and starting it from a menu are the
/// same exchange in two places rather than two exchanges.
class _AskInDrawer extends StatelessWidget {
  const _AskInDrawer({
    required this.question,
    required this.choices,
    required this.controller,
    required this.onAnswered,
  });

  final String question;
  final List<String> choices;
  final TextEditingController controller;
  final void Function(String? answer) onAnswered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(question, style: theme.textTheme.bodyMedium),
        if (choices.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final choice in choices)
                ActionChip(
                  label: Text(choice),
                  onPressed: () => onAnswered(choice),
                ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 6,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
          // Enter sends it: the reader is answering one question, not writing
          // a document, and reaching for the button is a second gesture for
          // something they have already finished saying.
          onSubmitted: (value) => onAnswered(value),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => onAnswered(null),
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: () => onAnswered(controller.text),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ],
    );
  }
}
