import 'package:flutter/material.dart';

import '../config/responsive_config.dart';
import '../layout/layout_engine.dart';
import '../models/git_graph.dart';
import '../models/style.dart';

/// Paints git graphs: one row per branch, one column per commit.
class GitGraphPainter extends CustomPainter {
  /// Creates a git graph painter.
  const GitGraphPainter({
    required this.gitData,
    required this.style,
    this.deviceConfig,
  });

  /// The git graph to render.
  final GitGraphData gitData;

  /// Style configuration.
  final MermaidStyle style;

  /// Responsive device configuration.
  final MermaidDeviceConfig? deviceConfig;

  /// Colours cycled through per branch row.
  static const _branchColors = <Color>[
    Color(0xFF1976D2),
    Color(0xFF388E3C),
    Color(0xFFF57C00),
    Color(0xFF7B1FA2),
    Color(0xFF00838F),
    Color(0xFFC2185B),
  ];

  static const double _commitRadius = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (gitData.commits.isEmpty) return;

    final padding = style.padding;
    final textColor = Color(
      style.defaultNodeStyle.textColor ?? MermaidColors.defaultTextColor,
    );

    var top = padding;
    if (gitData.title != null) {
      _drawText(
        canvas,
        gitData.title!,
        Offset(size.width / 2, top),
        TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: style.fontFamily,
          color: textColor,
        ),
        centred: true,
      );
      top += 44.0;
    } else {
      top += 8.0;
    }

    _drawBranchRows(canvas, size, top, padding, textColor);
    _drawConnections(canvas, top, padding);
    _drawCommits(canvas, top, padding, textColor);
  }

  @override
  bool shouldRepaint(covariant GitGraphPainter oldDelegate) {
    return gitData != oldDelegate.gitData || style != oldDelegate.style;
  }

  /// A tinted rail per branch, with its name in the left gutter.
  void _drawBranchRows(
    Canvas canvas,
    Size size,
    double top,
    double padding,
    Color textColor,
  ) {
    for (var row = 0; row < gitData.branches.length; row++) {
      final branch = gitData.branches[row];
      final y = _yForRow(row, top);
      final colour = _branchColors[row % _branchColors.length];

      canvas.drawLine(
        Offset(padding + GitGraphLayout.labelGutter - 20, y),
        Offset(size.width - padding, y),
        Paint()
          ..color = colour.withValues(alpha: 0.25)
          ..strokeWidth = 2,
      );

      _drawText(
        canvas,
        branch,
        Offset(padding + GitGraphLayout.labelGutter - 28, y),
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: style.fontFamily,
          color: colour,
        ),
        centred: false,
        rightAligned: true,
        verticallyCentred: true,
        maxWidth: GitGraphLayout.labelGutter - 32,
      );
    }
  }

  /// Straight runs along a branch, plus a bend for each merge.
  void _drawConnections(Canvas canvas, double top, double padding) {
    for (final branch in gitData.branches) {
      final onBranch =
          gitData.commits.where((c) => c.branch == branch).toList();
      if (onBranch.length < 2) continue;

      final colour =
          _branchColors[gitData.rowOf(branch) % _branchColors.length];
      final paint = Paint()
        ..color = colour
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      for (var i = 1; i < onBranch.length; i++) {
        canvas.drawLine(
          _centreOf(onBranch[i - 1], top, padding),
          _centreOf(onBranch[i], top, padding),
          paint,
        );
      }
    }

    for (final commit in gitData.commits) {
      final source = commit.mergedFrom;
      if (source == null) continue;

      final from = gitData.lastCommitOn(source, commit.column);
      if (from == null) continue;

      final start = _centreOf(from, top, padding);
      final end = _centreOf(commit, top, padding);
      final colour =
          _branchColors[gitData.rowOf(source) % _branchColors.length];

      // Leave the source row horizontally before curving, so the merge reads
      // as coming from that branch rather than cutting across the diagram.
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + GitGraphLayout.columnWidth * 0.6,
          start.dy,
          end.dx - GitGraphLayout.columnWidth * 0.6,
          end.dy,
          end.dx,
          end.dy,
        );

      canvas.drawPath(
        path,
        Paint()
          ..color = colour.withValues(alpha: 0.8)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawCommits(
    Canvas canvas,
    double top,
    double padding,
    Color textColor,
  ) {
    for (final commit in gitData.commits) {
      final centre = _centreOf(commit, top, padding);
      final colour =
          _branchColors[gitData.rowOf(commit.branch) % _branchColors.length];

      switch (commit.type) {
        case GitCommitType.highlight:
          canvas.drawCircle(
            centre,
            _commitRadius + 2,
            Paint()
              ..color = colour
              ..strokeWidth = 3
              ..style = PaintingStyle.stroke,
          );
          canvas.drawCircle(
            centre,
            _commitRadius - 2,
            Paint()..color = colour,
          );
        case GitCommitType.reverse:
          canvas.drawCircle(
            centre,
            _commitRadius,
            Paint()
              ..color = Color(style.backgroundColor)
              ..style = PaintingStyle.fill,
          );
          canvas.drawCircle(
            centre,
            _commitRadius,
            Paint()
              ..color = colour
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke,
          );
          final cross = Paint()
            ..color = colour
            ..strokeWidth = 2;
          const arm = _commitRadius * 0.6;
          canvas.drawLine(
            Offset(centre.dx - arm, centre.dy - arm),
            Offset(centre.dx + arm, centre.dy + arm),
            cross,
          );
          canvas.drawLine(
            Offset(centre.dx + arm, centre.dy - arm),
            Offset(centre.dx - arm, centre.dy + arm),
            cross,
          );
        case GitCommitType.merge:
          canvas.drawCircle(
            centre,
            _commitRadius,
            Paint()
              ..color = Color(style.backgroundColor)
              ..style = PaintingStyle.fill,
          );
          canvas.drawCircle(
            centre,
            _commitRadius,
            Paint()
              ..color = colour
              ..strokeWidth = 2.5
              ..style = PaintingStyle.stroke,
          );
        case GitCommitType.normal:
          canvas.drawCircle(centre, _commitRadius, Paint()..color = colour);
      }

      _drawText(
        canvas,
        commit.id,
        Offset(centre.dx, centre.dy + _commitRadius + 6),
        TextStyle(
          fontSize: 11,
          fontFamily: style.fontFamily,
          color: textColor,
        ),
        centred: true,
        maxWidth: GitGraphLayout.columnWidth - 6,
      );

      if (commit.tag != null && commit.tag!.isNotEmpty) {
        _drawTag(canvas, commit.tag!, centre, colour);
      }
    }
  }

  void _drawTag(Canvas canvas, String tag, Offset centre, Color colour) {
    final painter = TextPainter(
      text: TextSpan(
        text: tag,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: style.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final rect = Rect.fromCenter(
      center: Offset(centre.dx, centre.dy - _commitRadius - 12),
      width: painter.width + 10,
      height: painter.height + 4,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = colour,
    );
    painter.paint(
      canvas,
      Offset(rect.center.dx - painter.width / 2,
          rect.center.dy - painter.height / 2),
    );
  }

  Offset _centreOf(GitCommit commit, double top, double padding) {
    return Offset(
      padding +
          GitGraphLayout.labelGutter +
          commit.column * GitGraphLayout.columnWidth,
      _yForRow(gitData.rowOf(commit.branch), top),
    );
  }

  double _yForRow(int row, double top) =>
      top + row * GitGraphLayout.rowHeight + GitGraphLayout.rowHeight / 2;

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle textStyle, {
    required bool centred,
    bool rightAligned = false,
    bool verticallyCentred = false,
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);

    var dx = position.dx;
    if (centred) {
      dx -= painter.width / 2;
    } else if (rightAligned) {
      dx -= painter.width;
    }
    final dy =
        verticallyCentred ? position.dy - painter.height / 2 : position.dy;
    painter.paint(canvas, Offset(dx, dy));
  }
}
