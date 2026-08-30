import '../models/diagram.dart';
import '../models/gantt.dart';
import 'label.dart';

/// Parser for Mermaid Gantt chart diagrams
///
/// Parses Gantt chart syntax like:
/// ```
/// gantt
///     title A Gantt Diagram
///     dateFormat YYYY-MM-DD
///     section Section 1
///         Task A           :a1, 2024-01-01, 30d
///         Task B           :after a1, 20d
///     section Section 2
///         Task C           :2024-01-15, 12d
/// ```
class GanttParser {
  /// Creates a Gantt chart parser
  const GanttParser();

  /// Parses Gantt chart diagram from cleaned lines
  ///
  /// Returns a tuple of (MermaidDiagramData, GanttChartData) or null if parsing fails
  (MermaidDiagramData, GanttChartData)? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    String? title;
    String dateFormat = 'YYYY-MM-DD';
    String? axisFormat;
    String? excludes;
    bool todayMarker = true;
    String? currentSection;
    final tasks = <GanttTask>[];
    final sections = <GanttSection>[];
    final sectionTasks = <String, List<GanttTask>>{};

    // Default start date if none specified
    var defaultStartDate = DateTime.now();

    // Parse remaining lines
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final lineLower = line.toLowerCase();

      // Parse title
      if (lineLower.startsWith('title ')) {
        title = cleanLabel(line.substring(6)).trim();
        continue;
      }

      // Parse dateFormat
      if (lineLower.startsWith('dateformat ')) {
        dateFormat = line.substring(11).trim();
        continue;
      }

      // Parse axisFormat
      if (lineLower.startsWith('axisformat ')) {
        axisFormat = line.substring(11).trim();
        continue;
      }

      // Parse excludes
      if (lineLower.startsWith('excludes ')) {
        excludes = line.substring(9).trim();
        continue;
      }

      // Parse todayMarker
      if (lineLower.startsWith('todaymarker ')) {
        todayMarker = line.substring(12).trim().toLowerCase() != 'off';
        continue;
      }

      // Parse section
      if (lineLower.startsWith('section ')) {
        currentSection = line.substring(8).trim();
        if (!sectionTasks.containsKey(currentSection)) {
          sectionTasks[currentSection] = [];
        }
        continue;
      }

      // Parse task
      final task = _parseTask(line, tasks, defaultStartDate, dateFormat, currentSection);
      if (task != null) {
        tasks.add(task);
        // A task written before any `section` belongs to a default one.
        // Dropping it left the chart with no sections at all, and the painter
        // draws sections — so a gantt without a single `section` line came out
        // completely blank.
        final bucket = currentSection ?? '';
        sectionTasks.putIfAbsent(bucket, () => []).add(task);
        // Update default start date based on last task's end date
        defaultStartDate = task.endDate.add(const Duration(days: 1));
      }
    }

    if (tasks.isEmpty) return null;

    // Build sections list
    for (final entry in sectionTasks.entries) {
      sections.add(GanttSection(name: entry.key, tasks: entry.value));
    }

    final ganttData = GanttChartData(
      title: title,
      tasks: tasks,
      sections: sections,
      dateFormat: dateFormat,
      axisFormat: axisFormat,
      excludes: excludes,
      todayMarker: todayMarker,
    );

    // Create a minimal diagram data for compatibility
    final diagramData = MermaidDiagramData(
      type: DiagramType.ganttChart,
      nodes: const [],
      edges: const [],
      title: title,
    );

    return (diagramData, ganttData);
  }

  /// Parses a single task line
  ///
  /// Formats supported:
  /// - Task name :id, 2024-01-01, 30d
  /// - Task name :id, 2024-01-01, 2024-01-30
  /// - Task name :after id1, 30d
  /// - Task name :done, id, 2024-01-01, 30d
  /// - Task name :active, id, 2024-01-01, 30d
  /// - Task name :crit, id, 2024-01-01, 30d
  /// - Task name :milestone, id, 2024-01-01, 0d
  /// The status a metadata token names, or null when it names something else.
  GanttTaskStatus? _statusFor(String token) => switch (token) {
    'done' => GanttTaskStatus.done,
    'active' => GanttTaskStatus.active,
    'crit' || 'critical' => GanttTaskStatus.critical,
    'milestone' => GanttTaskStatus.milestone,
    _ => null,
  };

  /// How much a status changes the drawing, used to pick between several.
  int _statusRank(GanttTaskStatus status) => switch (status) {
    GanttTaskStatus.milestone => 4,
    GanttTaskStatus.critical => 3,
    GanttTaskStatus.done => 2,
    GanttTaskStatus.active => 1,
    GanttTaskStatus.normal => 0,
  };

  /// The offset of the colon that ends the task's name.
  ///
  /// Returns -1 when the line holds no usable split.
  int _definitionColon(String line, String dateFormat) {
    var from = 0;
    while (true) {
      final at = line.indexOf(':', from);
      if (at == -1) return -1;
      final rest = line.substring(at + 1).trim();
      final firstPart = rest.split(',').first.trim();
      if (_looksLikeDefinitionStart(firstPart, dateFormat)) return at;
      from = at + 1;
    }
  }

  /// Whether [part] could be the first field of a task definition.
  bool _looksLikeDefinitionStart(String part, String dateFormat) {
    if (part.isEmpty) return false;
    if (_statusFor(part.toLowerCase()) != null) return true;
    if (part.toLowerCase().startsWith('after ')) return true;
    if (_isDate(part, dateFormat)) return true;
    // An id, or a bare duration such as `30d`: one token, no spaces and no
    // colon of its own.
    return !part.contains(' ') && !part.contains(':');
  }

  GanttTask? _parseTask(
    String line,
    List<GanttTask> existingTasks,
    DateTime defaultStartDate,
    String dateFormat,
    String? section,
  ) {
    // Which colon separates the name from the definition.
    //
    // Not simply the first: `阶段一: 设计 :a1, 2026-01-01, 3d` is one task
    // whose name contains a colon, and splitting at the first left the name
    // as `阶段一` and the id as `设计 :a1`. Not the last either — a
    // `dateFormat` with a time in it puts colons in the definition, as in
    // `2026-01-01 10:30`.
    //
    // What tells them apart is what follows: a definition begins with a
    // status keyword, an `after …` clause, a date, or a bare id. A name
    // fragment does not.
    final colonIndex = _definitionColon(line, dateFormat);
    if (colonIndex == -1) return null;

    final name = cleanLabel(line.substring(0, colonIndex)).trim();
    final definition = line.substring(colonIndex + 1).trim();

    if (name.isEmpty || definition.isEmpty) return null;

    // Parse the definition parts
    final parts = definition.split(',').map((s) => s.trim()).toList();
    if (parts.isEmpty) return null;

    // Determine status and extract relevant parts
    var status = GanttTaskStatus.normal;
    String? id;
    String? startSpec;
    String? durationSpec;
    var partIndex = 0;

    // Status keywords come first and there may be several — `crit, active` is
    // ordinary mermaid. Consuming only one left the next keyword to be read as
    // the task's id, which both lost the styling and broke `after <id>`.
    while (partIndex < parts.length) {
      final keyword = _statusFor(parts[partIndex].toLowerCase());
      if (keyword == null) break;
      // This model holds one status, so the most telling one wins: a
      // milestone is drawn as a diamond and critical as a red bar, while
      // done and active are only shading.
      if (_statusRank(keyword) > _statusRank(status)) status = keyword;
      partIndex++;
    }

    // Parse remaining parts based on count
    final remainingParts = parts.sublist(partIndex);

    if (remainingParts.isEmpty) return null;

    final dependencies = <String>[];

    if (remainingParts.length == 1) {
      // Just duration: 30d
      durationSpec = remainingParts[0];
      id = _generateId(name, existingTasks);
    } else if (remainingParts.length == 2) {
      // Could be: id, duration OR start, duration OR after id, duration
      final first = remainingParts[0];
      final second = remainingParts[1];

      if (first.toLowerCase().startsWith('after ')) {
        // after id…, duration
        final afterIds = _referencedIds(first, 'after');
        dependencies.addAll(afterIds);
        durationSpec = second;
        id = _generateId(name, existingTasks);

        final latest = _latestEnd(afterIds, existingTasks);
        if (latest != null) {
          defaultStartDate = latest.add(const Duration(days: 1));
        }
        startSpec = null;
      } else if (_isDate(first, dateFormat)) {
        // start, duration
        startSpec = first;
        durationSpec = second;
        id = _generateId(name, existingTasks);
      } else {
        // id, duration
        id = first;
        durationSpec = second;
      }
    } else if (remainingParts.length >= 3) {
      // id, start, duration OR status was already parsed and we have id, start, duration
      id = remainingParts[0];

      final second = remainingParts[1];
      if (second.toLowerCase().startsWith('after ')) {
        final afterIds = _referencedIds(second, 'after');
        dependencies.addAll(afterIds);
        durationSpec = remainingParts[2];

        final latest = _latestEnd(afterIds, existingTasks);
        if (latest != null) {
          defaultStartDate = latest.add(const Duration(days: 1));
        }
      } else {
        startSpec = second;
        durationSpec = remainingParts[2];
      }
    }

    // Parse start date
    DateTime startDate;
    if (startSpec != null) {
      startDate = _parseDate(startSpec, dateFormat) ?? defaultStartDate;
    } else {
      startDate = defaultStartDate;
    }

    // Parse end date/duration
    //
    // `until id…` ends the task where the referenced work begins, which is the
    // counterpart to `after`. It used to land in the duration slot, parse as no
    // duration at all, and draw a zero-length bar.
    DateTime endDate;
    final untilIds = durationSpec == null
        ? const <String>[]
        : _referencedIds(durationSpec, 'until');
    if (untilIds.isNotEmpty) {
      dependencies.addAll(untilIds);
      final earliest = _earliestStart(untilIds, existingTasks);
      // Day ranges here are inclusive, so the bar stops the day before.
      endDate = earliest != null
          ? earliest.subtract(const Duration(days: 1))
          : startDate;
      if (endDate.isBefore(startDate)) endDate = startDate;
    } else if (durationSpec != null) {
      if (_isDate(durationSpec, dateFormat)) {
        // It's an end date
        endDate = _parseDate(durationSpec, dateFormat) ?? startDate;
      } else {
        // It's a duration
        final duration = _parseDuration(durationSpec);
        endDate = startDate.add(Duration(days: duration - 1));
      }
    } else {
      // Default 1 day duration
      endDate = startDate;
    }

    // Ensure milestone has same start and end date
    if (status == GanttTaskStatus.milestone) {
      endDate = startDate;
    }

    return GanttTask(
      id: id ?? _generateId(name, existingTasks),
      name: name,
      startDate: startDate,
      endDate: endDate,
      section: section,
      status: status,
      dependencies: dependencies,
    );
  }

  /// Ids referenced by an `after …` or `until …` spec.
  ///
  /// Mermaid allows several: `after a1 a2` starts once both have finished.
  /// Taking the whole remainder as one id meant a multi-target reference
  /// matched no task at all and silently fell back to "right after whatever
  /// came before me in the source".
  static List<String> _referencedIds(String spec, String keyword) {
    if (!spec.toLowerCase().startsWith('$keyword ')) return const [];
    return spec
        .substring(keyword.length + 1)
        .split(RegExp(r'\s+'))
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// The latest end date among [ids], or null when none of them is known.
  static DateTime? _latestEnd(List<String> ids, List<GanttTask> tasks) {
    DateTime? latest;
    for (final id in ids) {
      for (final task in tasks) {
        if (task.id != id) continue;
        if (latest == null || task.endDate.isAfter(latest)) {
          latest = task.endDate;
        }
      }
    }
    return latest;
  }

  /// The earliest start date among [ids], or null when none is known.
  ///
  /// This is what `until` means: run up to the moment the referenced work
  /// begins.
  static DateTime? _earliestStart(List<String> ids, List<GanttTask> tasks) {
    DateTime? earliest;
    for (final id in ids) {
      for (final task in tasks) {
        if (task.id != id) continue;
        if (earliest == null || task.startDate.isBefore(earliest)) {
          earliest = task.startDate;
        }
      }
    }
    return earliest;
  }

  /// Generates an ID from the task name.
  ///
  /// Only whitespace is folded away. Stripping everything outside `a-z0-9`
  /// turned a task named in Chinese — or in any script but this one — into an
  /// empty id, so every such task shared it and `after <id>` could never
  /// reach one. The id is also made unique against [existingTasks]: two tasks
  /// with the same name would otherwise collide the same way.
  String _generateId(String name, List<GanttTask> existingTasks) {
    var base = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    if (base.isEmpty) base = 'task';

    var candidate = base;
    var suffix = 2;
    while (existingTasks.any((task) => task.id == candidate)) {
      candidate = '${base}_$suffix';
      suffix++;
    }
    return candidate;
  }

  /// Checks if a string looks like a date
  bool _isDate(String str, String format) {
    // Check for common date patterns
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(str)) return true;
    if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(str)) return true;
    if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(str)) return true;
    return false;
  }

  /// Parses a date string according to the format
  DateTime? _parseDate(String dateStr, String format) {
    try {
      // Handle YYYY-MM-DD format
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
        return DateTime.parse(dateStr);
      }

      // Handle DD/MM/YYYY format
      final ddmmyyyy = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(dateStr);
      if (ddmmyyyy != null) {
        final day = int.parse(ddmmyyyy.group(1)!);
        final month = int.parse(ddmmyyyy.group(2)!);
        final year = int.parse(ddmmyyyy.group(3)!);
        return DateTime(year, month, day);
      }

      // Handle MM-DD-YYYY format
      final mmddyyyy = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(dateStr);
      if (mmddyyyy != null) {
        final month = int.parse(mmddyyyy.group(1)!);
        final day = int.parse(mmddyyyy.group(2)!);
        final year = int.parse(mmddyyyy.group(3)!);
        return DateTime(year, month, day);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parses a duration string (e.g., "30d", "2w", "1M")
  int _parseDuration(String duration) {
    final durationPattern = RegExp(r'^(\d+)([dwmMy]?)$');
    final match = durationPattern.firstMatch(duration.trim());

    if (match == null) return 1;

    final value = int.parse(match.group(1)!);
    final unit = match.group(2) ?? 'd';

    switch (unit.toLowerCase()) {
      case 'd':
        return value;
      case 'w':
        return value * 7;
      case 'm':
        return value * 30; // Approximate
      case 'y':
        return value * 365; // Approximate
      default:
        return value;
    }
  }
}
