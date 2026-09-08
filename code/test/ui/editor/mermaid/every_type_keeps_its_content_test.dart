import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';

import '../../../support/mermaid_samples.dart';

/// Every diagram type still holds what its sample says.
///
/// The test beside this one checks that each type *draws*: no exception, no
/// error box, not stuck on a spinner, a canvas with area. That is a strong
/// guard against a painter throwing and a weak one against a painter with
/// nothing to paint — an empty diagram passes every one of those assertions,
/// because a blank canvas has area too.
///
/// `MermaidParseResult.hasContent` cannot close it either: it asks whether a
/// payload object was constructed, not whether anything is in it. A parser
/// that built an empty `TimelineChartData` would satisfy it.
///
/// So this counts. The numbers are read off `mermaidSamples` — three slices in
/// the pie sample, three links in the sankey one — which makes them a second
/// list to keep in step with the first, on purpose: editing a sample should
/// make somebody look at what the parser now gets out of it.
void main() {
  const parser = MermaidParser();

  /// What each sample should still contain after parsing.
  ///
  /// Keyed by the type, so the check below can insist every type has an entry
  /// and a new diagram type cannot quietly skip this.
  final expected = <DiagramType, Map<String, int>>{
    DiagramType.flowchart: {'nodes': 4, 'edges': 3},
    DiagramType.sequence: {'nodes': 2, 'edges': 2, 'steps': 2},
    DiagramType.classDiagram: {'classes': 2, 'edges': 1},
    DiagramType.stateDiagram: {'nodes': 4, 'edges': 3},
    DiagramType.erDiagram: {'entities': 3, 'edges': 2},
    DiagramType.journey: {'sections': 1, 'tasks': 2},
    DiagramType.gitGraph: {'commits': 3},
    DiagramType.mindmap: {'branches': 2},
    DiagramType.pieChart: {'slices': 3},
    DiagramType.ganttChart: {'sections': 1, 'tasks': 2},
    // Three periods written with no `section` line of their own, which is how
    // the timeline in Mermaid's own documentation is written. Each becomes a
    // band holding one period.
    DiagramType.timeline: {'sections': 3, 'events': 3},
    DiagramType.kanban: {'columns': 2, 'tasks': 2},
    DiagramType.radar: {'axes': 3, 'curves': 1},
    DiagramType.xyChart: {'series': 1},
    DiagramType.quadrantChart: {'points': 2},
    DiagramType.requirementDiagram: {'requirements': 1},
    DiagramType.sankey: {'links': 3},
    DiagramType.blockDiagram: {'items': 3},
    DiagramType.c4Diagram: {'nodes': 2},
    DiagramType.packet: {'fields': 2},
    DiagramType.architecture: {'nodes': 2, 'groups': 1},
    DiagramType.treemap: {'roots': 1, 'children': 3},
  };

  /// What the parser actually got out of [source], in the same terms.
  Map<String, int> countsFor(MermaidParseResult r) {
    final counts = <String, int>{};
    void put(String key, int value) => counts[key] = value;

    if (r.diagram.nodes.isNotEmpty) put('nodes', r.diagram.nodes.length);
    if (r.diagram.edges.isNotEmpty) put('edges', r.diagram.edges.length);

    final timeline = r.timelineChartData;
    if (timeline != null) {
      put('sections', timeline.sections.length);
      put('events', timeline.sections.expand((s) => s.events).length);
    }
    final kanban = r.kanbanChartData;
    if (kanban != null) {
      put('columns', kanban.columns.length);
      put('tasks', kanban.columns.expand((c) => c.tasks).length);
    }
    final journey = r.journeyData;
    if (journey != null) {
      put('sections', journey.sections.length);
      put('tasks', journey.sections.expand((s) => s.tasks).length);
    }
    final gantt = r.ganttChartData;
    if (gantt != null) {
      put('sections', gantt.sections.length);
      put('tasks', gantt.sections.expand((s) => s.tasks).length);
    }
    final radar = r.radarChartData;
    if (radar != null) {
      put('axes', radar.axes.length);
      put('curves', radar.curves.length);
    }
    final architecture = r.architectureData;
    if (architecture != null) {
      put('nodes', architecture.nodes.length);
      put('groups', architecture.groups.length);
    }
    final treemap = r.treemapData;
    if (treemap != null) {
      put('roots', treemap.roots.length);
      put('children', treemap.roots.expand((n) => n.children).length);
    }
    final mindmapRoot = r.mindmapData?.root;
    if (mindmapRoot != null) put('branches', mindmapRoot.children.length);

    final pie = r.pieChartData;
    if (pie != null) put('slices', pie.slices.length);
    final sankey = r.sankeyChartData;
    if (sankey != null) put('links', sankey.links.length);
    final xy = r.xyChartData;
    if (xy != null) put('series', xy.series.length);
    final quadrant = r.quadrantChartData;
    if (quadrant != null) put('points', quadrant.points.length);
    final requirement = r.requirementDiagramData;
    if (requirement != null) {
      put('requirements', requirement.requirements.length);
    }
    final block = r.blockDiagramData;
    if (block != null) put('items', block.items.length);
    final c4 = r.c4DiagramData;
    if (c4 != null) put('nodes', c4.nodes.length);
    final packet = r.packetData;
    if (packet != null) put('fields', packet.fields.length);
    final sequence = r.sequenceData;
    if (sequence != null) put('steps', sequence.steps.length);
    final classes = r.classDiagramData;
    if (classes != null) put('classes', classes.classes.length);
    final er = r.erDiagramData;
    if (er != null) put('entities', er.entities.length);
    final git = r.gitGraphData;
    if (git != null) put('commits', git.commits.length);
    return counts;
  }

  test('every implemented type is counted here', () {
    final all = DiagramType.values.toSet()..remove(DiagramType.unknown);
    expect(
      all.difference(expected.keys.toSet()),
      isEmpty,
      reason: '新增了图型却没写它该有多少内容，它就可以画空图而无人发现',
    );
  });

  for (final entry in mermaidSamples.entries) {
    test('${entry.key.name} 解析后还留着它的内容', () {
      final result = parser.parseWithData(entry.value);
      expect(result, isNotNull, reason: '${entry.key.name} 的样例根本没解析出结果');

      final counts = countsFor(result!);
      for (final want in expected[entry.key]!.entries) {
        expect(
          counts[want.key],
          want.value,
          reason:
              '${entry.key.name} 的 ${want.key}：样例里有 ${want.value} 个，'
              '解析出 ${counts[want.key]} 个',
        );
      }
    });
  }
}
