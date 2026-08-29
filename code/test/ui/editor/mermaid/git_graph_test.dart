import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';

/// Every statement mermaid's gitGraph accepts.
///
/// `cherry-pick` was not one of them here: the line matched nothing, so it was
/// skipped in silence and the history came out one commit short with no sign
/// that anything had been dropped.
void main() {
  const parser = MermaidParser();

  GitGraphData graph(String body) =>
      parser.parseWithData('gitGraph\n$body')!.gitGraphData!;

  test('a plain commit gets an automatic id', () {
    final g = graph('  commit\n  commit\n');
    expect(g.commits.length, 2);
    expect(g.commits.every((c) => c.branch == 'main'), isTrue);
  });

  test('id, tag and type are read off a commit', () {
    final g = graph('  commit id: "one" tag: "v1" type: REVERSE\n');
    final commit = g.commits.single;
    expect(commit.id, 'one');
    expect(commit.tag, 'v1');
    expect(commit.type, GitCommitType.reverse);
  });

  test('branch and checkout move the following commits', () {
    final g = graph('  commit\n  branch develop\n  checkout develop\n  commit\n');
    expect(g.branches, containsAll(['main', 'develop']));
    expect(g.commits.last.branch, 'develop');
  });

  test('switch works where checkout does', () {
    final g = graph('  commit\n  branch dev\n  switch dev\n  commit\n');
    expect(g.commits.last.branch, 'dev');
  });

  test('a merge records where it came from', () {
    final g = graph('  commit\n  branch dev\n  checkout dev\n  commit\n'
        '  checkout main\n  merge dev id: "m" tag: "v2"\n');
    final merge = g.commits.last;
    expect(merge.type, GitCommitType.merge);
    expect(merge.mergedFrom, 'dev');
    expect(merge.id, 'm');
    expect(merge.tag, 'v2');
  });

  test('cherry-pick adds a commit rather than disappearing', () {
    final g = graph('  commit id: "one"\n  branch dev\n  checkout dev\n'
        '  cherry-pick id: "one"\n');
    expect(g.commits.length, 2,
        reason: 'cherry-pick 整行被丢掉了，历史少了一个提交且毫无提示');
    final picked = g.commits.last;
    expect(picked.type, GitCommitType.cherryPick);
    expect(picked.mergedFrom, 'one', reason: '没有记住它是从哪个提交摘来的');
    expect(picked.branch, 'dev');
  });

  test('a cherry-pick may carry a tag', () {
    final g = graph('  commit id: "one"\n  cherry-pick id: "one" tag: "v9"\n');
    expect(g.commits.last.tag, 'v9');
  });

  test('a cherry-pick with no id is not a commit', () {
    // mermaid requires the id; without one there is nothing to pick, and
    // inventing a commit would put a circle on the graph for nothing.
    final g = graph('  commit\n  cherry-pick\n');
    expect(g.commits.length, 1);
  });

  test('every commit type the model defines can be written', () {
    // A type nothing produces is a shape the painter draws for nobody.
    final produced = <GitCommitType>{
      ...graph('  commit\n').commits.map((c) => c.type),
      ...graph('  commit type: REVERSE\n').commits.map((c) => c.type),
      ...graph('  commit type: HIGHLIGHT\n').commits.map((c) => c.type),
      ...graph('  commit\n  branch d\n  checkout d\n  commit\n'
              '  checkout main\n  merge d\n')
          .commits
          .map((c) => c.type),
      ...graph('  commit id: "x"\n  cherry-pick id: "x"\n')
          .commits
          .map((c) => c.type),
    };
    expect(GitCommitType.values.toSet().difference(produced), isEmpty);
  });
}
