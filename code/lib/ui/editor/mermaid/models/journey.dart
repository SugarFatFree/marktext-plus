/// Data models for User Journey diagrams
library;

/// One step in a user journey.
class JourneyTask {
  /// Creates a task.
  const JourneyTask({
    required this.name,
    required this.score,
    this.actors = const [],
  });

  /// Task label.
  final String name;

  /// Satisfaction score, 1 (worst) to 5 (best).
  ///
  /// Mermaid renders this as a face; here it drives the marker's colour and
  /// vertical position.
  final int score;

  /// Who takes part, from the comma-separated list after the score.
  final List<String> actors;

  /// The score clamped to the 1..5 range mermaid defines.
  int get clampedScore => score < 1 ? 1 : (score > 5 ? 5 : score);
}

/// A named group of tasks.
class JourneySection {
  /// Creates a section.
  const JourneySection({required this.name, this.tasks = const []});

  /// Section heading.
  final String name;

  /// Tasks in declaration order.
  final List<JourneyTask> tasks;
}

/// A parsed user journey diagram.
class JourneyData {
  /// Creates journey data.
  const JourneyData({this.title, this.sections = const []});

  /// Optional diagram title.
  final String? title;

  /// Sections in declaration order.
  final List<JourneySection> sections;

  /// Every task across all sections, left to right.
  List<JourneyTask> get allTasks =>
      [for (final section in sections) ...section.tasks];

  /// Distinct actor names, in first-appearance order.
  ///
  /// Used for the legend, so the order has to be stable rather than sorted.
  List<String> get actors {
    final seen = <String>[];
    for (final task in allTasks) {
      for (final actor in task.actors) {
        if (!seen.contains(actor)) seen.add(actor);
      }
    }
    return seen;
  }
}
