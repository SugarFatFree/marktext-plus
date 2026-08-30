import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/parser/mermaid_parser.dart';

/// What a diagram that will not draw says about itself.
///
/// This is the whole of what a reader gets when their diagram does not appear,
/// so the words have to be right: the thing quoted back should be the thing to
/// correct, and quoting nothing at all says nothing at all.
void main() {
  MermaidFailure failureOf(String source) =>
      const MermaidParser().describeFailure(source);

  group('an unrecognised type quotes the word to fix', () {
    test('a misspelling quotes the word, not the line', () {
      // `grahp TD` is `graph` misspelled. Quoting `grahp td` back invites the
      // reader to look for a fault in the direction too.
      final failure = failureOf('grahp TD\n  A --> B');
      expect(failure.kind, MermaidFailureKind.unknownType);
      expect(failure.detail, 'grahp');
    });

    test('a type nobody implements', () {
      expect(failureOf('wobbleChart\n  A --> B').detail, 'wobblechart');
    });
  });

  group('what is really empty is called empty', () {
    test('nothing at all', () {
      expect(failureOf('').kind, MermaidFailureKind.empty);
    });

    test('only comments', () {
      expect(failureOf('%% 只有注释\n%% 再来一行').kind, MermaidFailureKind.empty);
    });

    test('only front matter', () {
      // It names no type, so `Unrecognised diagram type: ""` was all the
      // reader got — a quotation with nothing in it.
      final failure = failureOf('---\ntitle: 标题\n---');
      expect(failure.kind, MermaidFailureKind.empty);
      expect(failure.detail, isEmpty);
    });
  });

  group('a type that is understood', () {
    test('a header with nothing under it', () {
      final failure = failureOf('graph TD');
      expect(failure.kind, MermaidFailureKind.headerOnly);
      expect(failure.detail, 'flowchart');
    });

    test('a body that could not be read names the diagram', () {
      // The reader is told which syntax to check, in Mermaid's own words.
      final failure = failureOf('gantt\n  这一行不是任务');
      expect(failure.detail, 'Gantt chart');
    });
  });
}
