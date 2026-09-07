import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/kanban.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/quadrant_chart.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/radar.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/xy_chart.dart';

/// A diagram whose data changed is not the diagram it was.
///
/// Every mermaid painter decides whether to repaint from
/// `data != oldDelegate.data`. So a model whose `==` skips the list its data
/// lives in reports "nothing changed" after the reader edits the numbers, and
/// the chart on screen keeps the values it was edited away from. Four of them
/// did: kanban, quadrant, radar and xy chart.
///
/// Nothing about that looks wrong. The document says one thing, the picture
/// says another, and no error is raised by either.
void main() {
  group('changing the data makes the model unequal', () {
    test('xy chart', () {
      const a = XYChartData(
        series: [XYChartSeries(type: XYSeriesType.bar, values: [1, 2, 3])],
        title: 'Sales',
      );
      const b = XYChartData(
        series: [XYChartSeries(type: XYSeriesType.bar, values: [9, 9, 9])],
        title: 'Sales',
      );
      expect(a, isNot(b));

      const one = XYChartData(
        series: [XYChartSeries(type: XYSeriesType.bar, values: [1])],
        title: 'Sales',
        xAxisCategories: ['Jan'],
      );
      const two = XYChartData(
        series: [XYChartSeries(type: XYSeriesType.bar, values: [1])],
        title: 'Sales',
        xAxisCategories: ['Feb'],
      );
      expect(one, isNot(two), reason: '换了横轴标签也是换了图');
    });

    test('radar', () {
      const a = RadarChartData(
        axes: [RadarAxis(id: 'a', label: 'A')],
        curves: [RadarCurve(id: 'c', label: 'C', values: [1])],
        title: 'T',
      );
      const b = RadarChartData(
        axes: [RadarAxis(id: 'a', label: 'A')],
        curves: [RadarCurve(id: 'c', label: 'C', values: [9])],
        title: 'T',
      );
      expect(a, isNot(b));
    });

    test('kanban', () {
      const a = KanbanChartData(columns: [
        KanbanColumn(
          id: 'x',
          title: 'X',
          tasks: [KanbanTask(id: '1', description: 'write it')],
        )
      ]);
      const b = KanbanChartData(columns: [
        KanbanColumn(
          id: 'x',
          title: 'X',
          tasks: [KanbanTask(id: '1', description: 'ship it')],
        )
      ]);
      expect(a, isNot(b));
    });

    test('quadrant', () {
      const a = QuadrantChartData(
        points: [QuadrantPoint(label: 'p', x: 0.1, y: 0.1)],
        title: 'T',
      );
      const b = QuadrantChartData(
        points: [QuadrantPoint(label: 'p', x: 0.9, y: 0.9)],
        title: 'T',
      );
      expect(a, isNot(b));
    });
  });

  test('equal models agree on their hash', () {
    // `XYChartSeries` compared on `type` alone while hashing `type` and the
    // number of values, so two series it called equal could land in different
    // buckets. Whatever `==` decides, `hashCode` has to follow.
    const a = XYChartSeries(type: XYSeriesType.bar, values: [1, 2]);
    const b = XYChartSeries(type: XYSeriesType.bar, values: [1, 2]);
    expect(a, b);
    expect(a.hashCode, b.hashCode);

    const c = XYChartSeries(type: XYSeriesType.bar, values: [1, 2, 3]);
    expect(a, isNot(c), reason: '值不同就不是同一条序列');
  });

  test('every list a diagram model holds is compared by its ==', () {
    // The reconciliation, so the fifth one cannot drift in quietly. A model
    // that keeps a list out of `==` on purpose has to say so here.
    const exempt = <String, String>{};

    final directory = Directory('lib/ui/editor/mermaid/models');
    final offenders = <String>[];
    var classesChecked = 0;

    for (final file in directory.listSync().whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final match
          in RegExp(r'class (\w+)[^{]*\{').allMatches(source)) {
        final name = match.group(1)!;
        final body = _bodyAt(source, match.end - 1);
        final equality = _equalityIn(body);
        if (equality == null) continue;
        classesChecked++;
        final lists = RegExp(
          r'^\s*final\s+(?:List|Map|Set)<[^>]*>\s+(\w+);',
          multiLine: true,
        ).allMatches(body).map((m) => m.group(1)!);
        for (final field in lists) {
          if (exempt.containsKey('$name.$field')) continue;
          if (!RegExp('\\b$field\\b').hasMatch(equality)) {
            offenders.add('$name.$field');
          }
        }
      }
    }

    expect(classesChecked, greaterThan(5),
        reason: '一个带 == 的模型都没扫到，这条守卫已失效');
    expect(offenders, isEmpty,
        reason: '这些集合没有进 ==，改了它们图表不会重绘：$offenders');
  });
}

/// The body of the block whose opening brace is at [at].
String _bodyAt(String source, int at) {
  var depth = 0;
  for (var i = at; i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}') {
      depth--;
      if (depth == 0) return source.substring(at + 1, i);
    }
  }
  return '';
}

/// The text of a class's `operator ==`, in either of the forms used here.
String? _equalityIn(String classBody) {
  final block = RegExp(r'bool operator ==\s*\([^)]*\)\s*\{').firstMatch(classBody);
  if (block != null) return _bodyAt(classBody, block.end - 1);
  final arrow =
      RegExp(r'bool operator ==\s*\([^)]*\)\s*=>(.*?);', dotAll: true)
          .firstMatch(classBody);
  return arrow?.group(1);
}
