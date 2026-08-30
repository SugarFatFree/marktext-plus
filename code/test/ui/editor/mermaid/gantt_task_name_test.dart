import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/gantt.dart';
import 'package:marktext_plus/ui/editor/mermaid/parser/mermaid_parser.dart';

/// Where a Gantt task's name ends and its definition begins.
///
/// The line is `name : field, field, field`, and the colon that divides them
/// is not simply the first one — a task called `阶段一: 设计` has one of its
/// own — nor the last, because a `dateFormat` carrying a time puts colons in
/// the fields. What separates them is what follows: a definition starts with
/// a status keyword, an `after …` clause, a date, or a bare id.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<GanttTask> tasksOf(String body, {String format = 'YYYY-MM-DD'}) {
    final result = MermaidParser()
        .parseWithData('gantt\n dateFormat $format\n section S\n$body');
    expect(result?.ganttChartData, isNotNull, reason: '解析失败：$body');
    return result!.ganttChartData!.sections
        .expand((section) => section.tasks)
        .toList();
  }

  test('an ordinary task keeps its name and id', () {
    final tasks = tasksOf('  普通任务 :a1, 2026-01-01, 3d\n');
    expect(tasks, hasLength(1));
    expect(tasks.single.name, '普通任务');
    expect(tasks.single.id, 'a1');
  });

  test('a name containing a colon keeps all of it', () {
    // The first colon belongs to the name. Splitting there left the name as
    // `阶段一` and made the id `设计 :a1`, so the bar was labelled wrongly and
    // nothing could depend on it by id.
    final tasks = tasksOf('  阶段一: 设计 :a1, 2026-01-01, 3d\n');
    expect(tasks, hasLength(1));
    expect(tasks.single.name, '阶段一: 设计');
    expect(tasks.single.id, 'a1');
  });

  test('a colon in the fields is not mistaken for the separator', () {
    // `HH:mm` in the date format puts a colon after the separator, so taking
    // the last colon instead of the first would break this one.
    final tasks = tasksOf('  带时间 :a1, 2026-01-01 10:30, 3d\n',
        format: 'YYYY-MM-DD HH:mm');
    expect(tasks, hasLength(1));
    expect(tasks.single.name, '带时间');
    expect(tasks.single.id, 'a1');
  });

  test('a name containing a comma is still one task', () {
    // Checked because the first probe could not tell one task called
    // "设计, 评审" from two called "设计" and "评审" — a Dart list prints
    // them identically. It is one.
    final tasks = tasksOf('  设计, 评审 :a1, 2026-01-01, 3d\n');
    expect(tasks, hasLength(1));
    expect(tasks.single.name, '设计, 评审');
  });

  test('a definition starting with a status keyword still splits right', () {
    final tasks = tasksOf('  阶段: 二 :done, crit, b1, 2026-01-01, 2d\n');
    expect(tasks.single.name, '阶段: 二');
    expect(tasks.single.id, 'b1');
  });

  test('a definition starting with a date still splits right', () {
    final tasks = tasksOf('  阶段: 三 :2026-01-01, 2d\n');
    expect(tasks.single.name, '阶段: 三');
  });

  test('a definition starting with after still splits right', () {
    final tasks = tasksOf('  甲 :a1, 2026-01-01, 2d\n'
        '  阶段: 乙 :after a1, 2d\n');
    expect(tasks, hasLength(2));
    expect(tasks.last.name, '阶段: 乙');
  });

  test('a line with no usable colon contributes no task', () {
    // A chart of nothing but such lines does not parse as a chart at all —
    // that is existing behaviour and reasonable, so the assertion is that
    // the line adds nothing beside a real task, not that it stands alone.
    final tasks = tasksOf('  甲 :a1, 2026-01-01, 2d\n'
        '  没有冒号的一行\n');
    expect(tasks, hasLength(1));
    expect(tasks.single.name, '甲');
  });
}
