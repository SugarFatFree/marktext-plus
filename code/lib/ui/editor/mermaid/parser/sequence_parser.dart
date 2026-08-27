import '../models/diagram.dart';
import '../models/edge.dart';
import '../models/node.dart';
import '../models/sequence.dart';

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
            endIndex: _messages.length - 1,
            depth: depth,
          ),
        );
      }
    }
    _openBars.clear();

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
      SequenceDiagramData(activations: List.of(_activations)),
    );
  }

  void _parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return;

    // Parse participant declarations
    if (trimmed.startsWith('participant ') || trimmed.startsWith('actor ')) {
      _parseParticipant(trimmed);
      return;
    }

    // Parse notes
    if (trimmed.startsWith('Note ') || trimmed.startsWith('note ')) {
      // TODO: Handle notes
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
        _openBar(id, _messages.isEmpty ? 0 : _messages.length - 1);
      }
      return;
    }
    if (trimmed.startsWith('deactivate ')) {
      final id = trimmed.substring(11).trim();
      if (id.isNotEmpty) _closeBar(id, _messages.length - 1);
      return;
    }

    // Parse loop/alt/opt/par blocks
    if (trimmed.startsWith('loop ') ||
        trimmed.startsWith('alt ') ||
        trimmed.startsWith('opt ') ||
        trimmed.startsWith('par ') ||
        trimmed == 'end' ||
        trimmed.startsWith('else ')) {
      // TODO: Handle control structures
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
      label = asMatch.group(2)!;
      _aliases[id] = label;
    } else {
      id = remaining;
      label = remaining;
    }

    _participants.add(
      SequenceParticipant(id: id, label: label, participantType: type),
    );
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
    final messagePattern = RegExp(
      r'^([^\s\->+:]+)\s*(--?)(>>?|x|\))?\s*([+-])?\s*([^\s:]+)'
      r'\s*(?::\s*(.*))?$',
    );

    final match = messagePattern.firstMatch(line);
    if (match == null) return;

    final from = match.group(1)!;
    final lineStyle = match.group(2)!;
    final arrowStyle = match.group(3) ?? '';
    // Group 4 is the activation marker, and it always sits in front of the
    // target even though `-` closes the bar on the *sender*: `A->>+B` starts
    // B working, `B-->>-A` is B reporting back and stopping.
    final marker = match.group(4);
    final to = match.group(5)!;
    final messageText = match.group(6)?.trim();

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

    final index = _messages.length;
    _messages.add(
      SequenceMessage(
        from: from,
        to: to,
        label: messageText,
        arrowType: arrowType,
        lineType: lineType,
        messageType: messageType,
        activate: marker == '+',
        deactivate: marker == '-',
      ),
    );

    if (marker == '+') {
      _openBar(to, index);
    } else if (marker == '-') {
      _closeBar(from, index);
    }
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
    }
  }
}
