import '../models/diagram.dart';
import '../models/journey.dart';

/// Parser for Mermaid user journey diagrams (`journey`).
///
/// Supports `title`, `section`, and task lines of the form
/// `Task name: <score>: Actor, Other`. The actor list is optional.
class JourneyParser {
  /// Creates a journey parser.
  const JourneyParser();

  /// Parses the cleaned lines of a journey diagram.
  ///
  /// The first line is the `journey` header and is skipped.
  (MermaidDiagramData, JourneyData)? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    final body = lines.length > 1 ? lines.sublist(1) : const <String>[];

    String? title;
    final sections = <JourneySection>[];
    var currentName = '';
    var currentTasks = <JourneyTask>[];
    var sawSection = false;

    void flush() {
      if (!sawSection && currentTasks.isEmpty) return;
      sections.add(JourneySection(name: currentName, tasks: currentTasks));
      currentTasks = <JourneyTask>[];
    }

    for (final raw in body) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      final lower = line.toLowerCase();

      if (lower.startsWith('title ')) {
        title = line.substring('title '.length).trim();
        continue;
      }

      if (lower.startsWith('section ')) {
        if (sawSection) flush();
        currentName = line.substring('section '.length).trim();
        sawSection = true;
        continue;
      }

      final task = _parseTask(line);
      if (task != null) currentTasks.add(task);
    }

    flush();

    if (sections.isEmpty) return null;

    final data = JourneyData(title: title, sections: sections);
    if (data.allTasks.isEmpty) return null;

    return (
      MermaidDiagramData(
        type: DiagramType.journey,
        nodes: const [],
        edges: const [],
        title: title,
      ),
      data,
    );
  }

  /// Parses `Task name: 5: Alice, Bob`.
  ///
  /// Split from the right on the first two colons only, so a task name may
  /// itself contain a colon.
  JourneyTask? _parseTask(String line) {
    final parts = line.split(':');
    if (parts.length < 2) return null;

    // The score is the part after the name; anything beyond is the actor list.
    final score = int.tryParse(parts[1].trim());
    if (score == null) return null;

    final actors = parts.length > 2
        ? parts
            .sublist(2)
            .join(':')
            .split(',')
            .map((a) => a.trim())
            .where((a) => a.isNotEmpty)
            .toList()
        : const <String>[];

    return JourneyTask(
      name: parts[0].trim(),
      score: score,
      actors: actors,
    );
  }
}
