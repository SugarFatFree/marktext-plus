import 'dart:math' as math;
import 'dart:ui';

/// Geometry shared by the painters that draw boxes joined by lines.
///
/// The class diagram and the ER diagram each carried their own byte-identical
/// copy of both of these. Nothing had gone wrong yet, but this file has already
/// shown what happens when one copy is fixed and the others are not — the
/// diagram error box was three copies, and only one of them followed the theme.
/// Where a line aimed at [target] leaves [rect].
///
/// Used to stop an edge at the border of a box rather than running into its
/// middle.
Offset rectEdgePoint(Rect rect, Offset target) {
  final centre = rect.center;
  final dx = target.dx - centre.dx;
  final dy = target.dy - centre.dy;
  if (dx == 0 && dy == 0) return centre;
  final halfWidth = rect.width / 2;
  final halfHeight = rect.height / 2;
  final scaleX = dx == 0 ? double.infinity : halfWidth / dx.abs();
  final scaleY = dy == 0 ? double.infinity : halfHeight / dy.abs();
  final scale = math.min(scaleX, scaleY);
  return Offset(centre.dx + dx * scale, centre.dy + dy * scale);
}
/// Draws a dashed line from [from] to [to].
void drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
  const dashLength = 6.0;
  const gapLength = 4.0;
  final dx = to.dx - from.dx;
  final dy = to.dy - from.dy;
  final distance = math.sqrt(dx * dx + dy * dy);
  if (distance == 0) return;
  final stepX = dx / distance;
  final stepY = dy / distance;
  var travelled = 0.0;
  while (travelled < distance) {
    final segment = math.min(dashLength, distance - travelled);
    canvas.drawLine(
      Offset(from.dx + stepX * travelled, from.dy + stepY * travelled),
      Offset(
        from.dx + stepX * (travelled + segment),
        from.dy + stepY * (travelled + segment),
      ),
      paint,
    );
    travelled += dashLength + gapLength;
  }
}
