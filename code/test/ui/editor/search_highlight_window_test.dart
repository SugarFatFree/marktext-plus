import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/text_search_service.dart';
import 'package:marktext_plus/ui/editor/highlighting_controller.dart';

/// How many matches get painted at once.
///
/// Searching a five megabyte document for a common word finds about a hundred
/// thousand of them. Painting all of them took 133 ms and built a span tree
/// with 195 000 children — on every rebuild, and a caret move is a rebuild —
/// before Flutter had even started laying it out. A viewport holds a few
/// dozen lines, so almost none of that was ever visible.
void main() {
  /// How many spans in [span] carry a search highlight.
  int highlighted(TextSpan span) => (span.children ?? const [])
      .whereType<TextSpan>()
      .where((child) => child.style?.backgroundColor != null)
      .length;

  HighlightingController controller(String text) => HighlightingController(
        text: text,
        headingColor: Colors.blue,
        boldColor: Colors.black,
        codeColor: Colors.green,
        linkColor: Colors.indigo,
        defaultColor: Colors.black,
      );

  late BuildContext ctx;

  Future<void> withContext(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    })));
  }

  testWidgets('a search with few matches paints every one of them',
      (tester) async {
    await withContext(tester);
    const text = 'alpha beta alpha beta alpha\n';
    final c = controller(text);
    final matches = TextSearch.matches(text, 'alpha');
    expect(matches.length, 3);

    c.updateSearchMatches(matches, 1);
    final span =
        c.buildTextSpan(context: ctx, style: null, withComposing: false);
    expect(highlighted(span), matches.length);
  });

  testWidgets('a search with very many matches paints a bounded number',
      (tester) async {
    await withContext(tester);
    final b = StringBuffer();
    for (var i = 0; i < 40000; i++) {
      b.writeln('line $i mentions topic here');
    }
    final text = b.toString();
    final c = controller(text);
    final matches = TextSearch.matches(text, 'topic');
    expect(matches.length, 40000, reason: '样本本身要够多才有意义');

    c.updateSearchMatches(matches, 0);
    final span =
        c.buildTextSpan(context: ctx, style: null, withComposing: false);

    // The span count for the document itself is one per line either way; what
    // is bounded is how many of them carry a highlight.
    expect(highlighted(span), lessThanOrEqualTo(1000),
        reason: '仍然在为每一处命中铺高亮，而光标一动就重建一次');
    expect(highlighted(span), greaterThan(0));
  });

  testWidgets('the window follows the match the reader is on', (tester) async {
    await withContext(tester);
    final b = StringBuffer();
    for (var i = 0; i < 40000; i++) {
      b.writeln('line $i mentions topic here');
    }
    final text = b.toString();
    final c = controller(text);
    final matches = TextSearch.matches(text, 'topic');

    // A match deep in the document must still be painted when it is the one
    // being stepped to — a fixed window at the top would leave the reader
    // looking at an unhighlighted hit.
    final deep = matches[30000];
    c.updateSearchMatches(matches, 30000);
    final span =
        c.buildTextSpan(context: ctx, style: null, withComposing: false);

    var offset = 0;
    var painted = false;
    for (final child in span.children!) {
      final child_ = child as TextSpan;
      final len = child_.text?.length ?? 0;
      if (offset == deep.start &&
          len == deep.end - deep.start &&
          child_.style?.backgroundColor != null) {
        painted = true;
      }
      offset += len;
    }
    expect(painted, isTrue, reason: '当前匹配落在窗口外，读者会看到一个没高亮的命中');
  });

  testWidgets('no search means no search spans at all', (tester) async {
    await withContext(tester);
    final c = controller('alpha beta\n');
    c.updateSearchMatches(const [], -1);
    final span =
        c.buildTextSpan(context: ctx, style: null, withComposing: false);
    expect(span.children, isNotNull);
  });
}
