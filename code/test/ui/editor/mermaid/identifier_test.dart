import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/parser/identifier.dart';
import 'package:marktext_plus/ui/editor/mermaid/parser/mermaid_parser.dart';

void main() {
  group('normalizeMermaidId', () {
    test('leaves plain identifiers alone', () {
      expect(normalizeMermaidId('PlainId'), 'PlainId');
      expect(normalizeMermaidId('node_1'), 'node_1');
      expect(normalizeMermaidId('  padded  '), 'padded');
    });

    test('folds whitespace and punctuation', () {
      expect(normalizeMermaidId('has space'), 'has_space');
      expect(normalizeMermaidId('a-b'), 'a_b');
      expect(normalizeMermaidId('x(y)'), 'x_y_');
    });

    test('keeps dashes when asked, for ER entity names', () {
      expect(normalizeMermaidId('a-b', keepDash: true), 'a-b');
      expect(normalizeMermaidId('a b', keepDash: true), 'a_b');
    });

    test('keeps letters from every script', () {
      // An ASCII+CJK allowlist turned each of these into underscores, so two
      // different names produced the same id and the nodes merged into one.
      expect(normalizeMermaidId('ひらがな'), 'ひらがな');
      expect(normalizeMermaidId('カタカナ'), 'カタカナ');
      expect(normalizeMermaidId('한국어'), '한국어');
      expect(normalizeMermaidId('中文节点'), '中文节点');
      expect(normalizeMermaidId('Класс'), 'Класс');
      expect(normalizeMermaidId('Müller'), 'Müller');
    });

    test('distinct names keep distinct ids', () {
      final ids = [
        'ひらがな',
        'カタカナ',
        '한국어',
        'Müller',
        'Möller',
      ].map(normalizeMermaidId).toSet();
      expect(ids, hasLength(5));
    });
  });

  group('non-Latin diagrams keep their nodes apart', () {
    const parser = MermaidParser();

    test('a Japanese state diagram does not collapse into one state', () {
      final result = parser.parseWithData('''
stateDiagram-v2
  [*] --> ひらがな
  ひらがな --> カタカナ
  カタカナ --> [*]
''');

      expect(result, isNotNull);
      final labels = result!.diagram.nodes.map((n) => n.label).toSet();
      expect(labels, containsAll(['ひらがな', 'カタカナ']));
    });

    test('a Korean class diagram keeps both classes', () {
      final result = parser.parseWithData('''
classDiagram
  고객 <|-- 주문
''');

      expect(result, isNotNull);
      final data = result!.classDiagramData!;
      expect(data.byId('고객'), isNotNull);
      expect(data.byId('주문'), isNotNull);

      final edge = result.diagram.edges.single;
      expect(edge.from, '고객');
      expect(edge.to, '주문');
    });
  });
}
