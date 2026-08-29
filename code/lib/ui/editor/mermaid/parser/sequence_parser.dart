import '../models/diagram.dart';
import '../models/edge.dart';
import '../models/node.dart';
import '../models/sequence.dart';
import 'label.dart';

/// Parser for Mermaid sequence diagrams
///
/// Supports syntax like:
/// ```
/// sequenceDiagram
///   participant A as Alice
///   participant B as Bob
///   A->>B: Hello
///   B-->>A: Hi
/// ```
class SequenceParser {
  final List<SequenceParticipant> _participants = [];
  final List<SequenceMessage> _messages = [];
  final Map<String, String> _aliases = {};
  final List<SequenceActivation> _activations = [];
  final List<SequenceStep> _steps = [];
  final List<SequenceBlock> _blocks = [];
  final List<_OpenBlock> _openBlocks = [];
  final List<SequenceGroup> _groups = [];
  final List<_OpenBox> _openBoxes = [];

  /// Next number to stamp on a message, or null when numbering is off.
  int? _autoNumber;
  int _autoNumberStep = 1;

  /// Start index of each bar still open, innermost last, per participant.
  final Map<String, List<int>> _openBars = {};

  /// Parses sequence diagram lines into diagram data
  ///
  /// Returns the generic diagram alongside the activation bars, which have no
  /// place in the node/edge model: a bar is a span over messages, not a thing
  /// joining two participants.
  (MermaidDiagramData, SequenceDiagramData)? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    _participants.clear();
    _messages.clear();
    _aliases.clear();
    _activations.clear();
    _openBars.clear();
    _steps.clear();
    _blocks.clear();
    _openBlocks.clear();
    _groups.clear();
    _openBoxes.clear();
    _autoNumber = null;
    _autoNumberStep = 1;

    // Skip the first line (sequenceDiagram declaration)
    for (var i = 1; i < lines.length; i++) {
      _parseLine(lines[i]);
    }

    // A bar left open — `activate` with no matching `deactivate` — runs to the
    // end of the diagram rather than being discarded.
    for (final entry in _openBars.entries) {
      for (var depth = 0; depth < entry.value.length; depth++) {
        _activations.add(
          SequenceActivation(
            participantId: entry.key,
            startIndex: entry.value[depth],
            endIndex: _steps.length - 1,
            depth: depth,
          ),
        );
      }
    }
    _openBars.clear();

    // A frame left open — a missing `end` — closes at the last row, the same
    // way an unclosed activation does.
    while (_openBlocks.isNotEmpty) {
      _closeBlock();
    }
    while (_openBoxes.isNotEmpty) {
      _closeBox();
    }
    // Innermost frames close first, so the list comes out inside-out.
    _blocks.sort((a, b) {
      final byDepth = a.depth.compareTo(b.depth);
      return byDepth != 0 ? byDepth : a.startIndex.compareTo(b.startIndex);
    });

    // Create nodes from participants
    final nodes = _participants.map((p) => p as MermaidNode).toList();

    // Create edges from messages
    final edges = _messages.map((m) => m as MermaidEdge).toList();

    return (
      MermaidDiagramData(
        type: DiagramType.sequence,
        nodes: nodes,
        edges: edges,
        direction: DiagramDirection.leftToRight,
      ),
      SequenceDiagramData(
        steps: List.of(_steps),
        activations: List.of(_activations),
        blocks: List.of(_blocks),
        groups: List.of(_groups),
      ),
    );
  }

  void _parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return;

    // `autonumber`, optionally `autonumber <start> <step>` or `autonumber off`
    final auto = _autoNumberPattern.firstMatch(trimmed);
    if (auto != null) {
      _setAutoNumber(auto.group(1)?.trim());
      return;
    }

    // `box … end` groups participants. It shares the `end` keyword with the
    // control frames, so it has to be tracked even to keep those nesting
    // correctly — an unrecognised `box` would leave its `end` closing whatever
    // frame happened to be open.
    if (_boxOpenPattern.hasMatch(trimmed)) {
      _openBox(trimmed.substring(3).trim());
      return;
    }

    // Parse participant declarations
    if (trimmed.startsWith('participant ') || trimmed.startsWith('actor ')) {
      _parseParticipant(trimmed);
      return;
    }

    // Parse notes
    if (trimmed.toLowerCase().startsWith('note ')) {
      _parseNote(trimmed);
      return;
    }

    // Parse activate/deactivate
    //
    // `A->>B: ask` followed by `activate B` is how the same diagram gets
    // written without the `+` shorthand, and it has to mean the same thing —
    // so the bar opens on the message just seen, not the one still to come.
    // Before any message at all it opens on the first.
    if (trimmed.startsWith('activate ')) {
      final id = trimmed.substring(9).trim();
      if (id.isNotEmpty) {
        _ensureParticipant(id);
        _openBar(id, _steps.isEmpty ? 0 : _steps.length - 1);
      }
      return;
    }
    if (trimmed.startsWith('deactivate ')) {
      final id = trimmed.substring(11).trim();
      if (id.isNotEmpty) _closeBar(id, _steps.length - 1);
      return;
    }

    // Parse loop/alt/opt/par blocks
    //
    // The keyword must be followed by whitespace or nothing at all: a message
    // from a participant called `looper` starts with `loop` too.
    // `end` closes the innermost thing that is open. A box is only ever open
    // around participant declarations, before any frame starts, so preferring
    // the frame is right in both orders.
    if (trimmed.toLowerCase() == 'end') {
      if (_openBlocks.isNotEmpty) {
        _closeBlock();
      } else {
        _closeBox();
      }
      return;
    }

    final section = _blockSectionPattern.firstMatch(trimmed);
    if (section != null && _openBlocks.isNotEmpty) {
      _startSection(section.group(2)?.trim());
      return;
    }

    final opening = _blockOpenPattern.firstMatch(trimmed);
    if (opening != null) {
      _openBlock(
        _blockKindFor(opening.group(1)!.toLowerCase()),
        opening.group(2)?.trim(),
      );
      return;
    }

    // Parse messages
    _parseMessage(trimmed);
  }

  void _parseParticipant(String line) {
    ParticipantType type = ParticipantType.participant;
    String remaining = line;

    if (line.startsWith('actor ')) {
      type = ParticipantType.actor;
      remaining = line.substring(6).trim();
    } else if (line.startsWith('participant ')) {
      remaining = line.substring(12).trim();
    }

    // Check for alias: participant A as Alice
    // The identifier may be any script, same as in a message line.
    final asPattern = RegExp(r'^([^\s]+)\s+as\s+(.+)$');
    final asMatch = asPattern.firstMatch(remaining);

    String id;
    String label;

    if (asMatch != null) {
      id = asMatch.group(1)!;
      label = cleanLabel(asMatch.group(2)!);
      _aliases[id] = label;
    } else {
      id = remaining;
      label = remaining;
    }

    _participants.add(
      SequenceParticipant(id: id, label: label, participantType: type),
    );
    _recordInBox(id);
  }

  void _parseMessage(String line) {
    // Message patterns:
    // A->B: message (solid line, no arrow)
    // A-->B: message (dotted line, no arrow)
    // A->>B: message (solid line, arrow)
    // A-->>B: message (dotted line, arrow)
    // A-xB: message (solid line, cross)
    // A--xB: message (dotted line, cross)
    // A-)B: message (solid line, async)
    // A--)B: message (dotted line, async)

    // `\w` covers neither the space before a target (`A-x B`), the activation
    // markers (`A->>+B`), nor any name outside ASCII — so a diagram written in
    // Chinese produced no participants and no messages at all.
    //
    // `<` is excluded from the sender for the same reason mermaid's own actor
    // token excludes it (`[^\+<\->\->:\n,;]+`): mermaid 11 writes a
    // bidirectional message as `A<<->>B`, and without that exclusion the
    // sender greedily became `A<<` — a participant that does not exist got a
    // lifeline of its own, and the arrow lost its second head.
    final messagePattern = RegExp(
      r'^([^\s\-<>+:]+)\s*(<<)?(--?)(>>?|x|\))?\s*([+-])?\s*([^\s:]+)'
      r'\s*(?::\s*(.*))?$',
    );

    final match = messagePattern.firstMatch(line);
    if (match == null) return;

    final from = match.group(1)!;
    final bidirectional = match.group(2) != null;
    final lineStyle = match.group(3)!;
    final arrowStyle = match.group(4) ?? '';
    // Group 4 is the activation marker, and it always sits in front of the
    // target even though `-` closes the bar on the *sender*: `A->>+B` starts
    // B working, `B-->>-A` is B reporting back and stopping.
    final marker = match.group(5);
    final to = match.group(6)!;
    final messageText = match.group(7)?.trim();

    // Determine line type
    final lineType = lineStyle == '--' ? LineType.dotted : LineType.solid;

    // Determine arrow type
    ArrowType arrowType;
    MessageType messageType;

    if (arrowStyle.contains('>>')) {
      arrowType = ArrowType.arrow;
      messageType = lineType == LineType.dotted
          ? MessageType.reply
          : MessageType.sync;
    } else if (arrowStyle.contains('x')) {
      arrowType = ArrowType.cross;
      messageType = MessageType.sync;
    } else if (arrowStyle.contains(')')) {
      arrowType = ArrowType.arrow;
      messageType = lineType == LineType.dotted
          ? MessageType.asyncReply
          : MessageType.async;
    } else if (arrowStyle.contains('>')) {
      arrowType = ArrowType.arrow;
      messageType = MessageType.sync;
    } else {
      arrowType = ArrowType.none;
      messageType = MessageType.sync;
    }

    // Auto-create participants if not declared
    _ensureParticipant(from);
    _ensureParticipant(to);

    // `autonumber` stamps each message with its position. The number goes in
    // front of the text because that is where mermaid draws it.
    var label = messageText == null ? null : cleanLabel(messageText);
    final number = _autoNumber;
    if (number != null) {
      label = label == null || label.isEmpty ? '$number' : '$number $label';
      _autoNumber = number + _autoNumberStep;
    }

    _messages.add(
      SequenceMessage(
        from: from,
        to: to,
        label: label,
        arrowType: arrowType,
        lineType: lineType,
        bidirectional: bidirectional,
        messageType: messageType,
        activate: marker == '+',
        deactivate: marker == '-',
      ),
    );
    _steps.add(SequenceStep.message(_messages.length - 1));

    final index = _steps.length - 1;
    if (marker == '+') {
      _openBar(to, index);
    } else if (marker == '-') {
      _closeBar(from, index);
    }
  }

  /// The keyword opening a framed region, and the condition after it.
  static final _blockOpenPattern = RegExp(
    r'^(loop|alt|opt|par|critical|break|rect)(?:\s+(.*))?$',
    caseSensitive: false,
  );

  /// The keyword starting another branch of the frame already open.
  static final _blockSectionPattern = RegExp(
    r'^(else|and|option)(?:\s+(.*))?$',
    caseSensitive: false,
  );

  SequenceBlockKind _blockKindFor(String keyword) => switch (keyword) {
    'alt' => SequenceBlockKind.alt,
    'opt' => SequenceBlockKind.opt,
    'par' => SequenceBlockKind.par,
    'critical' => SequenceBlockKind.critical,
    'break' => SequenceBlockKind.breakBlock,
    'rect' => SequenceBlockKind.rect,
    _ => SequenceBlockKind.loop,
  };

  void _openBlock(SequenceBlockKind kind, String? label) {
    _openBlocks.add(
      _OpenBlock(
        kind: kind,
        depth: _openBlocks.length,
        label: label == null || label.isEmpty ? null : label,
        start: _steps.length,
      ),
    );
  }

  void _startSection(String? label) {
    final open = _openBlocks.last;
    open.sections.add(
      SequenceBlockSection(
        label: open.label,
        startIndex: open.start,
        endIndex: _steps.length - 1,
      ),
    );
    open.label = label == null || label.isEmpty ? null : label;
    open.start = _steps.length;
  }

  void _closeBlock() {
    if (_openBlocks.isEmpty) return;

    final open = _openBlocks.removeLast();
    open.sections.add(
      SequenceBlockSection(
        label: open.label,
        startIndex: open.start,
        endIndex: _steps.length - 1,
      ),
    );
    _blocks.add(
      SequenceBlock(
        kind: open.kind,
        depth: open.depth,
        sections: List.of(open.sections),
      ),
    );
  }

  /// `Note`, the placement, the participants, then the text after the colon.
  static final _notePattern = RegExp(
    r'^note\s+(left of|right of|over)\s+([^:]+?)\s*(?::\s*(.*))?$',
    caseSensitive: false,
  );

  /// `Note left of A: text`, `Note right of A: text`, `Note over A,B: text`.
  void _parseNote(String line) {
    final match = _notePattern.firstMatch(line);
    if (match == null) return;

    final placement = switch (match.group(1)!.toLowerCase()) {
      'left of' => SequenceNotePlacement.leftOf,
      'right of' => SequenceNotePlacement.rightOf,
      _ => SequenceNotePlacement.over,
    };

    final ids = match
        .group(2)!
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return;

    // `left of` and `right of` name exactly one participant; a second name
    // there is the author's mistake, not something to guess at.
    final participants = placement == SequenceNotePlacement.over
        ? ids.take(2).toList()
        : ids.take(1).toList();
    for (final id in participants) {
      _ensureParticipant(id);
    }

    _steps.add(
      SequenceStep.note(
        SequenceNote(
          placement: placement,
          participantIds: participants,
          text: match.group(3)?.trim() ?? '',
        ),
      ),
    );
  }

  void _openBar(String id, int startIndex) {
    (_openBars[id] ??= []).add(startIndex);
  }

  void _closeBar(String id, int endIndex) {
    final open = _openBars[id];
    if (open == null || open.isEmpty) return;

    final depth = open.length - 1;
    final start = open.removeLast();
    if (open.isEmpty) _openBars.remove(id);

    // A bar that closes on the message that opened it would be invisible; it
    // is given the one message of height mermaid gives it.
    _activations.add(
      SequenceActivation(
        participantId: id,
        startIndex: start,
        endIndex: endIndex < start ? start : endIndex,
        depth: depth,
      ),
    );
  }

  void _ensureParticipant(String id) {
    if (!_participants.any((p) => p.id == id)) {
      _participants.add(SequenceParticipant(id: id, label: _aliases[id] ?? id));
      _recordInBox(id);
    }
  }

  /// Files a newly declared participant under the box currently open.
  void _recordInBox(String id) {
    if (_openBoxes.isEmpty) return;
    final box = _openBoxes.last;
    if (!box.participantIds.contains(id)) box.participantIds.add(id);
  }

  /// `autonumber`, on its own or with `off`, or with a start and a step.
  static final _autoNumberPattern = RegExp(
    r'^autonumber(?:\s+(.*))?$',
    caseSensitive: false,
  );

  void _setAutoNumber(String? rest) {
    if (rest == null || rest.isEmpty) {
      _autoNumber = 1;
      _autoNumberStep = 1;
      return;
    }
    if (rest.toLowerCase() == 'off') {
      _autoNumber = null;
      return;
    }

    final numbers = rest
        .split(RegExp(r'\s+'))
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    _autoNumber = numbers.isNotEmpty ? numbers.first : 1;
    _autoNumberStep = numbers.length > 1 ? numbers[1] : 1;
  }

  /// `box` on its own, or followed by a colour and a name.
  static final _boxOpenPattern = RegExp(
    r'^box(?:\s+(.*))?$',
    caseSensitive: false,
  );

  /// `rgb(1,2,3)`, `rgba(1,2,3,0.5)` or `#abc` / `#aabbcc` leading a box line.
  static final _boxRgbPattern = RegExp(
    r'^(rgba?\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*(?:,\s*[\d.]+\s*)?\)|#[0-9a-fA-F]{3,8})\s*(.*)$',
  );

  /// The colour words mermaid's own examples use.
  ///
  /// A box line is `box <colour> <name>` with both parts optional, so the only
  /// way to tell `box Aqua Group` from a group actually called "Aqua Group" is
  /// to try the first word as a colour — which is what mermaid does too.
  static const _boxColorNames = <String, int>{
    'transparent': 0x00000000,
    'aqua': 0xFF00FFFF,
    'black': 0xFF000000,
    'blue': 0xFF0000FF,
    'fuchsia': 0xFFFF00FF,
    'gray': 0xFF808080,
    'grey': 0xFF808080,
    'green': 0xFF008000,
    'lightblue': 0xFFADD8E6,
    'lightgreen': 0xFF90EE90,
    'lightgrey': 0xFFD3D3D3,
    'lightyellow': 0xFFFFFFE0,
    'lime': 0xFF00FF00,
    'maroon': 0xFF800000,
    'navy': 0xFF000080,
    'olive': 0xFF808000,
    'orange': 0xFFFFA500,
    'pink': 0xFFFFC0CB,
    'purple': 0xFF800080,
    'red': 0xFFFF0000,
    'silver': 0xFFC0C0C0,
    'teal': 0xFF008080,
    'white': 0xFFFFFFFF,
    'yellow': 0xFFFFFF00,
  };

  void _openBox(String rest) {
    int? color;
    var label = rest;

    final rgb = _boxRgbPattern.firstMatch(rest);
    if (rgb != null) {
      color = _parseCssColor(rgb.group(1)!);
      label = rgb.group(2)!.trim();
    } else {
      final space = rest.indexOf(' ');
      final firstWord = (space == -1 ? rest : rest.substring(0, space))
          .toLowerCase();
      final named = _boxColorNames[firstWord];
      if (named != null) {
        color = named;
        label = space == -1 ? '' : rest.substring(space + 1).trim();
      }
    }

    _openBoxes.add(_OpenBox(label: label.isEmpty ? null : label, color: color));
  }

  void _closeBox() {
    if (_openBoxes.isEmpty) return;
    final box = _openBoxes.removeLast();
    _groups.add(
      SequenceGroup(
        label: box.label,
        participantIds: List.of(box.participantIds),
        color: box.color,
      ),
    );
  }

  /// Turns `rgb(…)`, `rgba(…)` or `#rgb` / `#rrggbb` into ARGB.
  int? _parseCssColor(String text) {
    if (text.startsWith('#')) {
      var hex = text.substring(1);
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join();
      }
      if (hex.length == 6) hex = 'FF$hex';
      return int.tryParse(hex, radix: 16);
    }

    final numbers = RegExp(r'[\d.]+')
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toList();
    if (numbers.length < 3) return null;

    final r = int.tryParse(numbers[0]) ?? 0;
    final g = int.tryParse(numbers[1]) ?? 0;
    final b = int.tryParse(numbers[2]) ?? 0;
    final a = numbers.length > 3
        ? ((double.tryParse(numbers[3]) ?? 1) * 255).round()
        : 255;
    return (a.clamp(0, 255) << 24) |
        (r.clamp(0, 255) << 16) |
        (g.clamp(0, 255) << 8) |
        b.clamp(0, 255);
  }
}

/// A frame whose `end` has not been read yet.
class _OpenBlock {
  _OpenBlock({
    required this.kind,
    required this.depth,
    required this.label,
    required this.start,
  });

  final SequenceBlockKind kind;
  final int depth;

  /// Condition of the branch currently being read.
  String? label;

  /// First row of the branch currently being read.
  int start;

  final List<SequenceBlockSection> sections = [];
}

/// A `box` whose `end` has not been read yet.
class _OpenBox {
  _OpenBox({required this.label, required this.color});

  final String? label;
  final int? color;
  final List<String> participantIds = [];
}
