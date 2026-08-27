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

/// Sequence diagram data that does not fit the generic node/edge model.
class SequenceDiagramData {
  /// Creates sequence diagram data.
  const SequenceDiagramData({required this.activations});

  /// Activation bars, in the order they open.
  final List<SequenceActivation> activations;

  @override
  bool operator ==(Object other) {
    if (other is! SequenceDiagramData) return false;
    if (other.activations.length != activations.length) return false;
    for (var i = 0; i < activations.length; i++) {
      if (other.activations[i] != activations[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(activations);
}
