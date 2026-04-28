import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../editor/mermaid/widgets/mermaid_diagram.dart';
import '../editor/mermaid/models/style.dart';
import '../editor/mermaid/models/node.dart' show NodeStyle;
import '../editor/mermaid/models/edge.dart' show EdgeStyle;

/// Renders Mermaid diagrams using pure Dart/Flutter implementation
class MermaidRenderer extends StatelessWidget {
  final String code;
  final bool isDarkMode;

  const MermaidRenderer({
    super.key,
    required this.code,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Create custom style with larger font and spacing
    final baseStyle = isDarkMode ? MermaidStyle.dark() : const MermaidStyle();
    final style = MermaidStyle(
      backgroundColor: baseStyle.backgroundColor,
      defaultNodeStyle: NodeStyle(
        fillColor: baseStyle.defaultNodeStyle.fillColor,
        strokeColor: baseStyle.defaultNodeStyle.strokeColor,
        textColor: baseStyle.defaultNodeStyle.textColor,
        fontSize: 16.0, // Increased from 14.0
        strokeWidth: baseStyle.defaultNodeStyle.strokeWidth,
        borderRadius: baseStyle.defaultNodeStyle.borderRadius,
      ),
      defaultEdgeStyle: EdgeStyle(
        strokeColor: baseStyle.defaultEdgeStyle.strokeColor,
        strokeWidth: baseStyle.defaultEdgeStyle.strokeWidth,
        labelFontSize: 14.0, // Edge label font size
      ),
      nodeSpacingX: 80.0, // Increased from 50.0
      nodeSpacingY: 80.0, // Increased from 50.0
      padding: 30.0, // Increased from 20.0
      fontFamily: baseStyle.fontFamily,
      themeMode: baseStyle.themeMode,
      classDefs: baseStyle.classDefs,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schema_outlined, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Mermaid',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                  },
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text('复制源码'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
            child: MermaidDiagram(
              code: code,
              style: style,
              errorBuilder: (context, error) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Mermaid Parse Error',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
