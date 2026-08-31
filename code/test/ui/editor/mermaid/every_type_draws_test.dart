import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';

/// Every diagram type the app claims, drawn.
///
/// The test beside this one checks that each type parses and reports itself
/// as the right type. Parsing is not drawing: laying a diagram out and
/// painting it is where the work is, and a type that parses and then throws
/// in its layout shows the reader an error box. Nothing covered that.
///
/// The samples are richer than the one-line headers next door on purpose —
/// nodes, edges and labels, so the painters have something to paint.
void main() {
  const samples = <DiagramType, String>{
    DiagramType.flowchart:
        'flowchart TD\n  A[开始] --> B{判断}\n  B -->|是| C[好]\n  B -->|否| D[取消]\n',
    DiagramType.sequence: 'sequenceDiagram\n'
        '  participant 甲\n  participant 乙\n'
        '  甲->>乙: 请求\n  乙-->>甲: 回应\n',
    DiagramType.classDiagram: 'classDiagram\n'
        '  class Animal {\n    +String name\n    +eat()\n  }\n'
        '  Animal <|-- Dog\n',
    DiagramType.stateDiagram:
        'stateDiagram-v2\n  [*] --> 空闲\n  空闲 --> 运行: 启动\n  运行 --> [*]\n',
    DiagramType.erDiagram: 'erDiagram\n'
        '  CUSTOMER ||--o{ ORDER : places\n'
        '  ORDER ||--|{ LINE-ITEM : contains\n',
    DiagramType.journey: 'journey\n  title 一天\n'
        '  section 上午\n    起床: 3: 我\n    通勤: 2: 我\n',
    DiagramType.gitGraph:
        'gitGraph\n  commit\n  branch dev\n  commit\n  checkout main\n  merge dev\n',
    DiagramType.mindmap:
        'mindmap\n  root((核心))\n    分支一\n      叶子\n    分支二\n',
    DiagramType.pieChart: 'pie title 占比\n  "甲" : 40\n  "乙" : 35\n  "丙" : 25\n',
    DiagramType.ganttChart: 'gantt\n  title 计划\n  dateFormat YYYY-MM-DD\n'
        '  section 一期\n  设计 :a1, 2024-01-01, 30d\n  开发 :after a1, 45d\n',
    DiagramType.timeline:
        'timeline\n  title 历程\n  2002 : 起步\n  2010 : 成长\n  2024 : 现在\n',
    DiagramType.kanban:
        'kanban\n  待办\n    t1[写文档]\n  进行中\n    t2[修 bug]\n',
    DiagramType.radar: 'radar-beta\n'
        '  axis 速度["速度"], 体积["体积"], 稳定["稳定"]\n'
        '  curve 本版["本版"]{80, 60, 90}\n',
    DiagramType.xyChart: 'xychart-beta\n  title "月度"\n'
        '  x-axis [一月, 二月, 三月]\n  y-axis "数量" 0 --> 100\n'
        '  bar [30, 60, 90]\n',
    DiagramType.quadrantChart: 'quadrantChart\n  title 优先级\n'
        '  x-axis 低 --> 高\n  y-axis 少 --> 多\n'
        '  甲: [0.3, 0.6]\n  乙: [0.7, 0.2]\n',
    DiagramType.requirementDiagram: 'requirementDiagram\n'
        '  requirement 需求一 {\n  id: 1\n  text: 必须能画图\n'
        '  risk: high\n  verifymethod: test\n  }\n',
    DiagramType.sankey: 'sankey-beta\n\n甲,乙,10\n乙,丙,6\n乙,丁,4\n',
    DiagramType.blockDiagram: 'block-beta\n  columns 3\n  甲 乙 丙\n',
    DiagramType.c4Diagram: 'C4Context\n  title 语境\n'
        '  Person(u, "用户", "使用者")\n  System(s, "系统", "本应用")\n',
    DiagramType.packet: 'packet-beta\n  0-15: "源端口"\n  16-31: "目的端口"\n',
    DiagramType.architecture: 'architecture-beta\n  group g(cloud)[云]\n'
        '  service db(database)[数据库] in g\n'
        '  service api(server)[接口] in g\n  db:R -- L:api\n',
    DiagramType.treemap:
        'treemap-beta\n  "根"\n    "甲": 30\n    "乙": 20\n    "丙": 10\n',
  };

  test('every implemented type has a sample here', () {
    final all = DiagramType.values.toSet()..remove(DiagramType.unknown);
    expect(all.difference(samples.keys.toSet()), isEmpty,
        reason: '新增了图型但这里没有样例，下面那条就漏掉了它');
  });

  for (final entry in samples.entries) {
    testWidgets('${entry.key.name} 能画出来', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? reported;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 700,
              child: MermaidDiagram(
                code: entry.value,
                onError: (message) => reported = message,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull,
          reason: '${entry.key.name} 在布局或绘制时抛了异常');
      expect(reported, isNull, reason: '${entry.key.name} 报错：$reported');

      // What the reader would be looking at: not the spinner, not the error
      // box, and something with area on the screen.
      //
      // Not "the painter is a MermaidPainter": only five of the twenty-two
      // painters extend that base — the rest are CustomPainters of their own —
      // so asking that would fail seventeen types that draw perfectly well.
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: '${entry.key.name} 停在加载状态，没有画出来');
      final box = tester.renderObject<RenderBox>(
        find.byType(MermaidDiagram),
      );
      expect(box.size.width, greaterThan(0));
      expect(box.size.height, greaterThan(0));
      expect(tester.widgetList<CustomPaint>(find.byType(CustomPaint)),
          isNotEmpty,
          reason: '${entry.key.name} 的子树里没有任何画布');
    });
  }
}
