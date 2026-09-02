import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// How far a bullet has to be indented before it is inside the one above it.
///
/// Every distinct indentation used to be a level of its own, so a list whose
/// bullets drift by a space — which is what a hand-edited or pasted list looks
/// like — drew one list inside another for every bullet. An item is inside
/// another only when it is indented to the column where that item's *text*
/// begins.
///
/// `marked` was the reference for each case here.
void main() {
  List<int> depths(String md) =>
      (MarkdownParser().parse(md).single as ListNode)
          .items
          .map((i) => i.depth)
          .toList();

  String html(String md) =>
      MarkdownParser().parse(md).map(ExportService.nodeToHtml).join();

  group('a bullet puts its text two columns in', () {
    test('one space short of it is a sibling', () {
      expect(depths('- 甲\n - 乙\n'), [0, 0]);
    });

    test('reaching it nests', () {
      expect(depths('- 甲\n  - 乙\n'), [0, 1]);
    });

    test('a list that drifts a space at a time is still one list', () {
      expect(depths('- 甲\n - 乙\n  - 丙\n   - 丁\n'), [0, 0, 0, 0]);
      final out = html('- 甲\n - 乙\n  - 丙\n   - 丁\n');
      expect('<ul>'.allMatches(out).length, 1,
          reason: '一份平铺的列表被画成了嵌套列表');
    });

    test('and coming back out again lands on the same level', () {
      expect(depths('- a\n - b\n  - c\n   - d\n  - e\n - f\n- g\n'),
          [0, 0, 0, 0, 0, 0, 0]);
    });
  });

  group('a numbered step puts its text three columns in', () {
    test('two spaces is short of it', () {
      expect(depths('1. 甲\n  2. 乙\n3. 丙\n'), [0, 0, 0]);
    });

    test('three spaces reaches it', () {
      expect(depths('1. 甲\n   2. 乙\n3. 丙\n'), [0, 1, 0]);
    });

    test('a wider marker needs a wider indent', () {
      // `10. ` is four columns.
      expect(depths('10. 甲\n   - 乙\n'), [0, 0]);
      expect(depths('10. 甲\n    - 乙\n'), [0, 1]);
    });
  });

  group('what must not change', () {
    test('a plainly nested list is still nested', () {
      final out = html('- 甲\n  - 乙\n  - 丙\n- 丁\n');
      expect('<ul>'.allMatches(out).length, 2);
      expect(depths('- 甲\n  - 乙\n  - 丙\n- 丁\n'), [0, 1, 1, 0]);
    });

    test('three levels written properly stay three levels', () {
      expect(depths('- 甲\n  - 乙\n    - 丙\n'), [0, 1, 2]);
    });

    test('a tab-indented sub-item still nests', () {
      expect(depths('- 甲\n\t- 乙\n'), [0, 1]);
    });
  });
}
