/// Data models for Git graph diagrams
library;

/// How a commit should be drawn.
enum GitCommitType {
  /// Filled circle — the default.
  normal,

  /// Crossed circle, for a reverted commit.
  reverse,

  /// Thicker ring, for a commit worth calling out.
  highlight,

  /// Merge commit, produced by a `merge` line rather than a `commit` line.
  merge,
}

/// One commit on one branch.
class GitCommit {
  /// Creates a commit.
  const GitCommit({
    required this.id,
    required this.branch,
    required this.column,
    this.tag,
    this.type = GitCommitType.normal,
    this.mergedFrom,
  });

  /// Commit label — from `id: "..."` when given, otherwise generated.
  final String id;

  /// Branch this commit sits on.
  final String branch;

  /// Horizontal position: commits advance one column each, in source order.
  final int column;

  /// Tag text from `tag: "..."`.
  final String? tag;

  /// How to draw it.
  final GitCommitType type;

  /// For a merge commit, the branch that was merged in.
  final String? mergedFrom;
}

/// A parsed git graph.
class GitGraphData {
  /// Creates git graph data.
  const GitGraphData({
    required this.branches,
    required this.commits,
    this.title,
  });

  /// Branch names in the order they first appear, which is also row order.
  final List<String> branches;

  /// Commits in source order.
  final List<GitCommit> commits;

  /// Optional diagram title.
  final String? title;

  /// Row index of [branch], or 0 when it is unknown.
  int rowOf(String branch) {
    final index = branches.indexOf(branch);
    return index < 0 ? 0 : index;
  }

  /// The last commit on [branch] before [column], or null if there is none.
  ///
  /// Merge lines need this to know where to draw from.
  GitCommit? lastCommitOn(String branch, int column) {
    GitCommit? found;
    for (final commit in commits) {
      if (commit.branch == branch && commit.column < column) found = commit;
    }
    return found;
  }

  /// Highest column index used, or -1 when there are no commits.
  int get lastColumn =>
      commits.isEmpty ? -1 : commits.map((c) => c.column).reduce((a, b) => a > b ? a : b);
}
