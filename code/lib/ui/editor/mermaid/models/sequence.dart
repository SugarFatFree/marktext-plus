/// Data models specific to sequence diagrams
library;

/// One activation bar: the stretch of a lifeline during which a participant is
/// doing something.
class SequenceActivation {
  /// Creates an activation bar.
  const SequenceActivation({
    required this.participantId,
    required this.startIndex,
    required this.endIndex,
    required this.depth,
  });

  /// The participant whose lifeline the bar is drawn on.
  final String participantId;

  /// Index of the message the bar starts at.
  ///
  /// Positions are message indices rather than pixels because the painter is
  /// the only thing that knows how far apart it spaces messages.
  final int startIndex;

  /// Index of the message the bar ends at. A bar that is never closed runs to
  /// the last message, which is what mermaid does.
  final int endIndex;

  /// Nesting level, zero for the outermost bar.
  ///
  /// A participant can be activated again while already active — the classic
  /// case being a recursive call — and mermaid steps each nested bar sideways
  /// so the two stay distinguishable.
  final int depth;

  @override
  bool operator ==(Object other) =>
      other is SequenceActivation &&
      other.participantId == participantId &&
      other.startIndex == startIndex &&
      other.endIndex == endIndex &&
      other.depth == depth;

  @override
  int get hashCode => Object.hash(participantId, startIndex, endIndex, depth);
}

/// Where a note is pinned relative to the participants it names.
enum SequenceNotePlacement {
  /// To the left of a single participant's lifeline.
  leftOf,

  /// To the right of a single participant's lifeline.
  rightOf,

  /// Across one participant, or spanning from one to another.
  over,
}

/// A note box.
class SequenceNote {
  /// Creates a note.
  const SequenceNote({
    required this.placement,
    required this.participantIds,
    required this.text,
  });

  /// Where the box sits.
  final SequenceNotePlacement placement;

  /// The participants named. `Note over A,B` gives two; the rest give one.
  final List<String> participantIds;

  /// Note body.
  final String text;

  @override
  bool operator ==(Object other) =>
      other is SequenceNote &&
      other.placement == placement &&
      other.text == text &&
      _sameList(other.participantIds, participantIds);

  @override
  int get hashCode =>
      Object.hash(placement, text, Object.hashAll(participantIds));

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// One row of a sequence diagram.
///
/// Messages are not the only thing that takes up a row — a note does too, and
/// before this existed a note would have been drawn on top of the message
/// beside it. Everything that refers to a position in the diagram, activation
/// bars included, counts in steps.
class SequenceStep {
  /// A row holding the message at [messageIndex] in the diagram's edge list.
  const SequenceStep.message(this.messageIndex) : note = null;

  /// A row holding a note.
  const SequenceStep.note(SequenceNote this.note) : messageIndex = -1;

  /// Index into the edge list, or -1 for a note row.
  final int messageIndex;

  /// The note, when this row holds one.
  final SequenceNote? note;

  /// Whether this row holds a note rather than a message.
  bool get isNote => note != null;

  @override
  bool operator ==(Object other) =>
      other is SequenceStep &&
      other.messageIndex == messageIndex &&
      other.note == note;

  @override
  int get hashCode => Object.hash(messageIndex, note);
}

/// Sequence diagram data that does not fit the generic node/edge model.
class SequenceDiagramData {
  /// Creates sequence diagram data.
  const SequenceDiagramData({required this.steps, required this.activations});

  /// Every row of the diagram, in order.
  final List<SequenceStep> steps;

  /// Activation bars, in the order they open. Indices count steps.
  final List<SequenceActivation> activations;

  @override
  bool operator ==(Object other) =>
      other is SequenceDiagramData &&
      _sameList(other.steps, steps) &&
      _sameList(other.activations, activations);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(steps), Object.hashAll(activations));

  static bool _sameList<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
