import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../models/packet.dart';
import '../models/style.dart';

/// Draws a `packet-beta` diagram: rows of bit cells with the fields laid over
/// them.
///
/// A field wider than the row it starts in is drawn as one box per row it
/// covers, the way mermaid draws it — the alternative, a single box that runs
/// off the edge, loses the bit alignment that is the whole point of the chart.
class PacketPainter extends CustomPainter {
  /// Creates a packet painter.
  const PacketPainter({
    required this.packetData,
    required this.style,
    this.deviceConfig,
  });

  /// The packet to render.
  final PacketDiagramData packetData;

  /// Style configuration.
  final MermaidStyle style;

  /// Responsive device configuration.
  final MermaidDeviceConfig? deviceConfig;

  /// Height of one row of bits.
  static const rowHeight = 44.0;

  /// Height of the bit-number strip above each row.
  static const rulerHeight = 16.0;

  /// Height taken by the title, when there is one.
  static const titleHeight = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (packetData.fields.isEmpty) return;

    final padding = style.padding;
    var top = padding;

    if (packetData.title != null) {
      _drawText(
        canvas,
        packetData.title!,
        Rect.fromLTWH(padding, top, size.width - padding * 2, titleHeight),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(style.defaultNodeStyle.textColor ?? 0xFF212121),
          fontFamily: style.fontFamily,
        ),
      );
      top += titleHeight;
    }

    final bits = packetData.bitsPerRow;
    final gridWidth = size.width - padding * 2;
    final bitWidth = gridWidth / bits;

    final border = Paint()
      ..color = Color(style.defaultNodeStyle.strokeColor ?? 0xFF9E9E9E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()..color = Color(style.defaultNodeStyle.fillColor ?? 0xFFECEFF1);

    for (var row = 0; row < packetData.rowCount; row++) {
      final rulerTop = top + row * (rowHeight + rulerHeight);
      final rowTop = rulerTop + rulerHeight;

      for (final field in packetData.fields) {
        final rowFirst = row * bits;
        final rowLast = rowFirst + bits - 1;
        if (field.end < rowFirst || field.start > rowLast) continue;

        final from = field.start < rowFirst ? rowFirst : field.start;
        final to = field.end > rowLast ? rowLast : field.end;
        final rect = Rect.fromLTWH(
          padding + (from - rowFirst) * bitWidth,
          rowTop,
          (to - from + 1) * bitWidth,
          rowHeight,
        );
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, border);
        _drawText(
          canvas,
          field.label,
          rect.deflate(3),
          style: TextStyle(
            fontSize: 11,
            color: Color(style.defaultNodeStyle.textColor ?? 0xFF212121),
            fontFamily: style.fontFamily,
          ),
        );
      }

      // The bit numbers at the ends of the row. Numbering every bit is
      // unreadable at 32 columns, and mermaid labels the ends too.
      final rowFirst = row * bits;
      _drawText(
        canvas,
        '$rowFirst',
        Rect.fromLTWH(padding, rulerTop, bitWidth * 4, rulerHeight),
        style: _rulerStyle,
        align: TextAlign.left,
      );
      _drawText(
        canvas,
        '${rowFirst + bits - 1}',
        Rect.fromLTWH(
          padding + gridWidth - bitWidth * 4,
          rulerTop,
          bitWidth * 4,
          rulerHeight,
        ),
        style: _rulerStyle,
        align: TextAlign.right,
      );
    }
  }

  TextStyle get _rulerStyle => TextStyle(
        fontSize: 10,
        color: Color(style.onBackgroundTextColor),
        fontFamily: style.fontFamily,
      );

  void _drawText(
    Canvas canvas,
    String text,
    Rect box, {
    required TextStyle style,
    TextAlign align = TextAlign.center,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: box.width < 0 ? 0 : box.width);
    final dx = switch (align) {
      TextAlign.left => box.left,
      TextAlign.right => box.right - painter.width,
      _ => box.left + (box.width - painter.width) / 2,
    };
    painter.paint(canvas, Offset(dx, box.top + (box.height - painter.height) / 2));
  }

  @override
  bool shouldRepaint(covariant PacketPainter oldDelegate) =>
      packetData != oldDelegate.packetData || style != oldDelegate.style;
}
