/// Data models for packet diagrams (`packet-beta`).
library;

/// One named run of bits.
class PacketField {
  /// Creates a packet field spanning [start]..[end] inclusive.
  const PacketField({
    required this.start,
    required this.end,
    required this.label,
  });

  /// First bit of the field, counting from zero.
  final int start;

  /// Last bit of the field, inclusive — a one-bit field has `end == start`.
  final int end;

  /// The field's name.
  final String label;

  /// How many bits the field occupies.
  int get width => end - start + 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PacketField &&
          other.start == start &&
          other.end == end &&
          other.label == label;

  @override
  int get hashCode => Object.hash(start, end, label);
}

/// A complete packet diagram.
class PacketDiagramData {
  /// Creates packet diagram data.
  const PacketDiagramData({
    required this.fields,
    this.title,
    this.bitsPerRow = 32,
  });

  /// Optional title drawn above the packet.
  final String? title;

  /// The fields, in the order they were written.
  final List<PacketField> fields;

  /// How many bits one row of the drawing holds. Mermaid's default is 32.
  final int bitsPerRow;

  /// The number of rows the drawing needs.
  ///
  /// A field may straddle a row boundary, so this is driven by the last bit
  /// used rather than by the field count.
  int get rowCount {
    if (fields.isEmpty) return 0;
    var last = 0;
    for (final field in fields) {
      if (field.end > last) last = field.end;
    }
    return last ~/ bitsPerRow + 1;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PacketDiagramData &&
          other.title == title &&
          other.bitsPerRow == bitsPerRow &&
          _sameFields(other.fields, fields);

  static bool _sameFields(List<PacketField> a, List<PacketField> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(title, bitsPerRow, Object.hashAll(fields));
}
