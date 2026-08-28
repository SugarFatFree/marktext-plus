import '../models/diagram.dart';
import '../models/packet.dart';

/// Parses mermaid `packet-beta` diagrams.
///
/// The grammar is small: a header, an optional title, and one line per field.
/// A field is either an explicit bit range or, since mermaid 11.5, a width
/// relative to wherever the previous field ended:
///
/// ```
/// packet-beta
/// title TCP header
/// 0-15: "Source Port"
/// 16-31: "Destination Port"
/// +32: "Sequence Number"
/// ```
class PacketParser {
  /// Creates a packet parser.
  const PacketParser();

  static final _rangeRe = RegExp(r'^(\d+)\s*-\s*(\d+)\s*:\s*(.+)$');
  static final _singleRe = RegExp(r'^(\d+)\s*:\s*(.+)$');
  static final _relativeRe = RegExp(r'^\+\s*(\d+)\s*:\s*(.+)$');

  /// Returns the diagram and its data, or null if nothing could be read.
  (MermaidDiagramData, PacketDiagramData)? parse(List<String> lines) {
    String? title;
    final fields = <PacketField>[];
    var cursor = 0;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('%%')) continue;
      if (line.startsWith('packet-beta') || line == 'packet') continue;

      if (line.toLowerCase().startsWith('title ')) {
        title = line.substring(6).trim();
        continue;
      }

      final relative = _relativeRe.firstMatch(line);
      if (relative != null) {
        final width = int.parse(relative.group(1)!);
        // `+0` would be a field with no bits in it, which cannot be drawn and
        // would leave the cursor where it was — every following field would
        // then land on top of it.
        if (width <= 0) continue;
        fields.add(PacketField(
          start: cursor,
          end: cursor + width - 1,
          label: _unquote(relative.group(2)!),
        ));
        cursor += width;
        continue;
      }

      final range = _rangeRe.firstMatch(line);
      if (range != null) {
        final start = int.parse(range.group(1)!);
        final end = int.parse(range.group(2)!);
        // A range written backwards is a typo, not an instruction to draw
        // right to left; taking it at face value produced a negative width.
        if (end < start) continue;
        fields.add(PacketField(
          start: start,
          end: end,
          label: _unquote(range.group(3)!),
        ));
        cursor = end + 1;
        continue;
      }

      final single = _singleRe.firstMatch(line);
      if (single != null) {
        final bit = int.parse(single.group(1)!);
        fields.add(PacketField(
          start: bit,
          end: bit,
          label: _unquote(single.group(2)!),
        ));
        cursor = bit + 1;
      }
    }

    if (fields.isEmpty) return null;

    return (
      MermaidDiagramData(
        type: DiagramType.packet,
        nodes: const [],
        edges: const [],
        title: title,
      ),
      PacketDiagramData(fields: fields, title: title),
    );
  }

  static String _unquote(String text) {
    final trimmed = text.trim();
    if (trimmed.length >= 2 &&
        ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
            (trimmed.startsWith("'") && trimmed.endsWith("'")))) {
      return trimmed.substring(1, trimmed.length - 1);
    }
    return trimmed;
  }
}
