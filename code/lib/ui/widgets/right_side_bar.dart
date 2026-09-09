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

  /// The exchange so far: what was asked for, and what came back.
  ///
  /// A panel used to be one shot — ask, answer, done — so a reader who did not
  /// like the result had to close the drawer and start again, describing the
  /// whole thing a second time. Kept as a list so the earlier drafts stay
  /// readable while a later one is being written.
  final List<({String asked, String answer})> _turns = [];

  /// Whether this panel's command asks what to do.
  ///
  /// A follow-up reaches the plugin as the answer to that question, so a
  /// command that never asks has nowhere to read one. Offering the box anyway
  /// would take the reader's words and drop them, which is the editor saying
  /// it can do something it cannot.
  bool _panelAsks = false;

  /// What the reader last asked for, so the answer can be filed under it.
  String _asked = '';

  /// Which panel the drawer is showing, so a follow-up can run the same
  /// command again without going back through the rail.
  PluginManifest? _openPlugin;
  PluginSidePanel? _openPanel;

  /// The box a follow-up is typed into.
  /// One box for the whole exchange — the plugin's question is answered
  /// here, and so is every request after it.
  final TextEditingController _say = TextEditingController();

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
    _say.clear();
    if (answer != null) _asked = answer;
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
    _say.dispose();
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

  /// Files the answer now in [_content] under what was asked for.
  ///
  /// Called from inside the sink's `setState`, so it only arranges the list.
  void _recordTurn() {
    if (_content.isEmpty) return;
    if (_turns.isNotEmpty && _turns.last.asked == _asked) {
      // The same turn growing: a plugin sends its answer in pieces.
      _turns[_turns.length - 1] = (asked: _asked, answer: _content);
    } else {
      _turns.add((asked: _asked, answer: _content));
    }
  }

  /// Sends what is in the box: an answer if the plugin is asking, otherwise a
  /// request to rework what it last said.
  ///
  /// One action for one box. Two — a question form and a follow-up field —
  /// meant the same exchange was typed into in two places.
  void _send() {
    final said = _say.text.trim();
    if (said.isEmpty) return;
    // Answering comes first, and is allowed while the command is running —
    // because a command waiting for its question to be answered *is* running,
    // and refusing to send then leaves the question with no way to answer it.
    if (_answering != null) {
      _answered(said);
      return;
    }
    if (_running) return;
    _sendFollowUp();
  }

  /// Sends whatever is in the follow-up box, if there is a panel to send to.
  void _sendFollowUp() {
    final plugin = _openPlugin;
    final panel = _openPanel;
    if (plugin != null && panel != null) _followUp(plugin, panel);
  }

  /// Asks for the last answer to be reworked.
  ///
  /// The plugin is given its own answer as the part to work on, and the
  /// reader's words as the instruction — the same two things it was given the
  /// first time, so no plugin has to know that this is a second round.
  Future<void> _followUp(PluginManifest plugin, PluginSidePanel panel) async {
    final asked = _say.text.trim();
    if (asked.isEmpty || _running || _content.isEmpty) return;
    final about = _content;
    setState(() {
      _asked = asked;
      _say.clear();
    });
    _automaticAnswer = asked;
    try {
      await _run(plugin, panel, '${plugin.id}/${panel.id}', about: about);
    } finally {
      _automaticAnswer = null;
    }
  }

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
      _openPlugin = plugin;
      _openPanel = panel;
      _content = '';
      _canApply = false;
      _replaces = '';
      _render = PluginPaneRender.text;
      _panelAsks = false;
      _turns.clear();
      _say.clear();
      _closeUi();
    });
    await _run(plugin, panel, key);
  }

  /// Runs [panel]'s command and puts what comes back in the drawer.
  ///
  /// The whole command, not one step of it. It used to be one step, so a
  /// plugin that asks a question first — which the one official plugin does —
  /// filled the drawer with the sentence "a panel cannot ask a question" and
  /// there was nowhere to type an answer.
  ///
  /// [about] is what a follow-up is about: the answer the reader was not happy
  /// with. The plugin reads it as the part to work on, which is how "and make
  /// it shorter" is said in the language it already speaks.
  Future<void> _run(
    PluginManifest plugin,
    PluginSidePanel panel,
    String key, {
    String? about,
  }) async {
    setState(() => _running = true);
    try {
      await PluginCommandActions.runInto(
        ref,
        context: context,
        plugin: plugin,
        command: panel.id,
        about: about,
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
            // The first answer's, kept through every refinement: a shorter
            // rewrite still replaces the paragraph the first one was going to
            // replace, not the draft it was made from.
            if (_replaces.isEmpty) _replaces = replaces;
            _render = render;
            _pluginName = plugin.name;
            _recordTurn();
          });
        },
        onAsk: ({
          required String question,
          required List<String> choices,
          required String suggested,
        }) {
          if (!mounted || _open != key) return Future.value(null);
          _panelAsks = true;
          // Being driven, or following up: answer as a reader would rather
          // than waiting for one.
          final automatic = _automaticAnswer;
          if (automatic != null) return Future.value(automatic);
          final completer = Completer<String?>();
          setState(() {
            _content = '';
            _ui = null;
            _question = question;
            _choices = choices;
            _answering = completer;
            _say.text = suggested;
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
                    child: _ui != null
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
                              // The exchange, oldest first: what was asked for
                              // and what came back. Earlier drafts stay
                              // readable so the reader can see what their last
                              // instruction changed — which is the point of
                              // being able to give another one.
                              for (final turn in _turns) ...[
                                if (turn.asked.isNotEmpty) _Said(turn.asked),
                                // Drawn the way the plugin asked for, which is
                                // what the pane grid has always done: a rewrite
                                // meant to be read as a document is rendered,
                                // not shown with its markup on display.
                                _render == PluginPaneRender.preview
                                    ? MarkdownRenderer(markdown: turn.answer)
                                    : SelectableText(turn.answer),
                                if (turn != _turns.last)
                                  const Divider(height: 24),
                              ],
                              // The plugin's question is a message in the
                              // conversation rather than a form that replaces
                              // it. It used to take over the drawer with a
                              // text field of its own, so a single exchange
                              // was typed into in two different places.
                              if (_question != null) ...[
                                if (_turns.isNotEmpty)
                                  const Divider(height: 24),
                                Text(
                                  _question!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                              // Nothing to read yet and still running: say so.
                              // An empty drawer looks exactly like a failure.
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
                              // More still coming, some already readable.
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
                              // The same offer the pane grid makes for the same
                              // answer. Without it the rail could show a
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
                // One box for the whole exchange, kept at the bottom the way a
                // conversation is typed into. The plugin's first question is
                // answered here too: it used to open a form of its own, so the
                // reader typed in one place to start and another to carry on.
                if (_question != null || (_turns.isNotEmpty && _panelAsks))
                  _SayBox(
                    controller: _say,
                    choices: _question == null ? const [] : _choices,
                    // Waiting *for the reader* is not being busy: the command is still
                                      // running while it holds the question open, and greying the box
                                      // then would leave nowhere to answer it.
                                      busy: _running && _answering == null,
                    onSend: _send,
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
/// One thing the reader asked for, above the answer it produced.
class _Said extends StatelessWidget {
  const _Said(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// The box the whole exchange is typed into, at the bottom of the drawer.
///
/// [choices] are the answers the plugin suggested for the question it is
/// asking; pressing one sends it, which is what the question form used to
/// offer and what a reader still wants when the plugin has named the usual
/// replies.
class _SayBox extends StatelessWidget {
  const _SayBox({
    required this.controller,
    required this.choices,
    required this.busy,
    required this.onSend,
  });

  final TextEditingController controller;
  final List<String> choices;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        if (choices.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final choice in choices)
                  ActionChip(
                    label: Text(choice),
                    onPressed: busy
                        ? null
                        : () {
                            controller.text = choice;
                            onSend();
                          },
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('plugin-drawer-follow'),
                  controller: controller,
                  enabled: !busy,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: l10n?.pluginFollowUpHint,
                  ),
                  onSubmitted: (_) => onSend(),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              IconButton(
                key: const Key('plugin-drawer-send'),
                icon: const Icon(Icons.send, size: 18),
                onPressed: busy ? null : onSend,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

