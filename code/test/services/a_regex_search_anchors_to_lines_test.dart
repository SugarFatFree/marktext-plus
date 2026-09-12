import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/text_search_service.dart';

/// `^` and `$` mean the start and end of a line in a search box.
///
/// They meant the start and end of the whole document, which is what Dart's
/// `RegExp` does without `multiLine`. So `^#+ ` — the most natural thing anyone
/// types into a regular-expression search in a Markdown editor, "find every
/// heading" — found the first heading only if the document opened with one, and
/// nothing otherwise.
///
/// Every editor that offers a regular-expression search anchors these to lines:
/// VS Code, Sublime, IntelliJ, BBEdit. The anchor to the very start of the
/// document that this gives up is close to useless in a search box — the first
/// match is the one you can already see — and Dart's flavour has no `\A` to
/// offer instead, so this is a trade rather than a pure gain, and it is the
/// trade everyone else makes.
///
/// `.` still does not cross a line: that is the other flag, and the same editors
/// leave it off.
void main() {
  const document = '# One\n\n## Two\n\nthree lines\n';

  List<String> found(String pattern) => TextSearch.matches(
        document,
        pattern,
        useRegex: true,
      ).map((range) => document.substring(range.start, range.end)).toList();

  test('a heading pattern finds every heading, not just the first line', () {
    expect(found(r'^#+ '), ['# ', '## ']);
  });

  test('an end-of-line anchor matches at every line end', () {
    expect(found(r'\w+$'), ['One', 'Two', 'lines']);
  });

  test('a start-of-line anchor matches after a blank line too', () {
    expect(found(r'^\w+'), ['three']);
  });

  test('a dot still does not cross a line', () {
    expect(found('One.Two'), isEmpty);
  });

  test('a pattern with no anchor is unaffected', () {
    expect(found(r'\bTwo\b'), ['Two']);
  });

  test('case folding still applies to an anchored pattern', () {
    expect(
      TextSearch.matches(document, r'^#+ ONE',
          useRegex: true, caseSensitive: true),
      isEmpty,
      reason: 'a case-sensitive scan should not match ONE against One',
    );
    expect(
      TextSearch.matches(document, r'^#+ ONE',
              useRegex: true, caseSensitive: false)
          .length,
      1,
      reason: 'the insensitive scan lost the anchor',
    );
  });

  test('an invalid pattern still reports nothing', () {
    expect(found('('), isEmpty);
  });
}
