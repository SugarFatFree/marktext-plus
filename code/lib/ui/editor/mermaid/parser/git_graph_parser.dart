import '../models/diagram.dart';
import '../models/git_graph.dart';

/// Parser for Mermaid git graphs (`gitGraph`).
///
/// Supports `commit` (with `id:`, `tag:` and `type:` options), `branch`,
/// `checkout` / `switch`, and `merge`.
class GitGraphParser {
  /// Creates a git graph parser.
  const GitGraphParser();

  /// Branch mermaid starts on when nothing else is checked out.
  static const defaultBranch = 'main';

  /// `key: "value"` or `key: value`, used for commit options.
  static final _optionRe = RegExp(r'(\w+)\s*:\s*("([^"]*)"|\S+)');

  /// Parses the cleaned lines of a git graph.
  ///
  /// The first line is the `gitGraph` header and is skipped.
  (MermaidDiagramData, GitGraphData)? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    final body = lines.length > 1 ? lines.sublist(1) : const <String>[];

    final branches = <String>[defaultBranch];
    final commits = <GitCommit>[];
    var current = defaultBranch;
    var column = 0;
    var autoId = 0;
    String? title;

    for (final raw in body) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      final lower = line.toLowerCase();

      if (lower.startsWith('title ')) {
        title = line.substring('title '.length).trim();
        continue;
      }

      // `options { ... }` and accTitle/accDescr carry no drawing information.
      if (lower.startsWith('options') ||
          lower.startsWith('acctitle') ||
          lower.startsWith('accdescr')) {
        continue;
      }

      if (lower.startsWith('branch ')) {
        final name = _firstWord(line.substring('branch '.length));
        if (name.isEmpty) continue;
        if (!branches.contains(name)) branches.add(name);
        // mermaid checks out a branch as soon as it is created.
        current = name;
        continue;
      }

      if (lower.startsWith('checkout ') || lower.startsWith('switch ')) {
        final keyword = lower.startsWith('checkout ') ? 'checkout ' : 'switch ';
        final name = _firstWord(line.substring(keyword.length));
        if (name.isEmpty) continue;
        if (!branches.contains(name)) branches.add(name);
        current = name;
        continue;
      }

      if (lower.startsWith('merge ')) {
        final rest = line.substring('merge '.length).trim();
        final source = _firstWord(rest);
        if (source.isEmpty) continue;
        if (!branches.contains(source)) branches.add(source);

        final options = _parseOptions(rest);
        commits.add(GitCommit(
          id: options['id'] ?? 'merge-$source',
          branch: current,
          column: column++,
          tag: options['tag'],
          type: GitCommitType.merge,
          mergedFrom: source,
        ));
        continue;
      }

      if (lower == 'commit' || lower.startsWith('commit ')) {
        final rest =
            line.length > 'commit'.length ? line.substring('commit'.length) : '';
        final options = _parseOptions(rest);
        commits.add(GitCommit(
          id: options['id'] ?? '${autoId++}',
          branch: current,
          column: column++,
          tag: options['tag'],
          type: _commitType(options['type']),
        ));
        continue;
      }
    }

    if (commits.isEmpty) return null;

    // Drop branches that never received a commit, so empty rows are not drawn.
    final used = branches
        .where((b) => commits.any((c) => c.branch == b || c.mergedFrom == b))
        .toList();

    final data = GitGraphData(
      branches: used.isEmpty ? branches : used,
      commits: commits,
      title: title,
    );

    return (
      MermaidDiagramData(
        type: DiagramType.gitGraph,
        nodes: const [],
        edges: const [],
        title: title,
      ),
      data,
    );
  }

  Map<String, String> _parseOptions(String text) {
    final result = <String, String>{};
    for (final match in _optionRe.allMatches(text)) {
      final key = match.group(1)!.toLowerCase();
      // group(3) is the unquoted body; group(2) keeps quotes for bare values.
      result[key] = match.group(3) ?? match.group(2)!;
    }
    return result;
  }

  GitCommitType _commitType(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'REVERSE':
        return GitCommitType.reverse;
      case 'HIGHLIGHT':
        return GitCommitType.highlight;
      default:
        return GitCommitType.normal;
    }
  }

  String _firstWord(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final space = trimmed.indexOf(RegExp(r'\s'));
    return space == -1 ? trimmed : trimmed.substring(0, space);
  }
}
