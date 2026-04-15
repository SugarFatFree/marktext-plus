import 'package:flutter/material.dart';
import 'syntax_highlighter.dart';

class HighlightingController extends TextEditingController {
  Color headingColor;
  Color boldColor;
  Color codeColor;
  Color linkColor;
  Color defaultColor;

  HighlightingController({
    super.text,
    required this.headingColor,
    required this.boldColor,
    required this.codeColor,
    required this.linkColor,
    required this.defaultColor,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final highlighted = MarkdownSyntaxHighlighter.highlight(
      text,
      headingColor: headingColor,
      boldColor: boldColor,
      codeColor: codeColor,
      linkColor: linkColor,
      defaultColor: defaultColor,
    );

    return TextSpan(
      style: style,
      children: highlighted.children,
    );
  }
}
