import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/style.dart';

/// Contrast of text a diagram paints straight onto its own background.
///
/// Most labels sit on a shape that carries its own fill — a white kanban card,
/// a pale yellow note, a coloured journey marker — and stay readable whatever
/// the theme is. A few do not: a sequence diagram's `alt` / `loop` frame title
/// and its `[else]` section labels are drawn on the bare background. Those were
/// a fixed slate grey, which against the dark background came out at 2.3 —
/// below even the 3.0 WCAG allows for large text.
void main() {
  /// Relative luminance, per WCAG 2.1.
  double luminance(int argb) {
    double channel(int shift) {
      final v = ((argb >> shift) & 0xFF) / 255;
      return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
    }

    return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
  }

  double contrast(int a, int b) {
    final la = luminance(a);
    final lb = luminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  test('the measurement itself is right', () {
    // Black on white is 21:1 by definition; without this the other two tests
    // could pass on a broken formula.
    expect(contrast(0xFF000000, 0xFFFFFFFF), closeTo(21, 0.1));
    expect(contrast(0xFF1E1E1E, 0xFF1E1E1E), closeTo(1, 0.001));
  });

  test('dark theme: background text is readable', () {
    final style = MermaidStyle.dark();
    expect(
      contrast(style.onBackgroundTextColor, style.backgroundColor),
      greaterThanOrEqualTo(4.5),
      reason: '深色主题下画在背景上的文字对比度不足',
    );
  });

  test('light theme: background text is readable', () {
    const style = MermaidStyle();
    expect(
      contrast(style.onBackgroundTextColor, style.backgroundColor),
      greaterThanOrEqualTo(4.5),
      reason: '浅色主题下画在背景上的文字对比度不足',
    );
  });

  test('the colour that used to be hardcoded would fail this', () {
    // 0xFF455A64 was written into the sequence painter for both themes. It is
    // fine on white and not on #1E1E1E — which is the whole finding.
    expect(contrast(0xFF455A64, MermaidStyle.dark().backgroundColor),
        lessThan(3.0));
    expect(contrast(0xFF455A64, const MermaidStyle().backgroundColor),
        greaterThan(4.5));
  });
}
