import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import '../editor/mermaid/widgets/mermaid_diagram.dart';
import '../editor/mermaid/models/style.dart';
import '../editor/mermaid/models/node.dart' show NodeStyle;
import '../editor/mermaid/models/edge.dart' show EdgeStyle;

/// Renders Mermaid diagrams with zoom and pan support
class MermaidRenderer extends StatefulWidget {
  final String code;
  final bool isDarkMode;

  const MermaidRenderer({
    super.key,
    required this.code,
    required this.isDarkMode,
  });

  @override
  State<MermaidRenderer> createState() => _MermaidRendererState();
}

class _MermaidRendererState extends State<MermaidRenderer> {
  final TransformationController _transformController = TransformationController();
  bool _isInteractive = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.isDarkMode ? MermaidStyle.dark() : const MermaidStyle();
    final style = MermaidStyle(
      backgroundColor: baseStyle.backgroundColor,
      defaultNodeStyle: NodeStyle(
        fillColor: baseStyle.defaultNodeStyle.fillColor,
        strokeColor: baseStyle.defaultNodeStyle.strokeColor,
        textColor: baseStyle.defaultNodeStyle.textColor,
        fontSize: 16.0,
        strokeWidth: baseStyle.defaultNodeStyle.strokeWidth,
        borderRadius: baseStyle.defaultNodeStyle.borderRadius,
      ),
      defaultEdgeStyle: EdgeStyle(
        strokeColor: baseStyle.defaultEdgeStyle.strokeColor,
        strokeWidth: baseStyle.defaultEdgeStyle.strokeWidth,
        labelFontSize: 14.0,
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
                if (_isInteractive)
                  TextButton.icon(
                    onPressed: _resetZoom,
                    icon: const Icon(Icons.zoom_out_map, size: 16),
                    label: const Text('重置'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: widget.code));
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
          GestureDetector(
            onDoubleTap: () => setState(() => _isInteractive = !_isInteractive),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
              child: _isInteractive
                  ? Listener(
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent &&
                            HardwareKeyboard.instance.isControlPressed) {
                          final scale = _transformController.value.getMaxScaleOnAxis();
                          final delta = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
                          final newScale = (scale * delta).clamp(0.3, 3.0);
                          final focalPoint = event.localPosition;
                          final scaleFactor = newScale / scale;
                          final dx = focalPoint.dx * (1 - scaleFactor);
                          final dy = focalPoint.dy * (1 - scaleFactor);
                          final matrix = Matrix4.identity()
                            ..setTranslationRaw(dx, dy, 0)
                            ..scale(scaleFactor, scaleFactor, 1.0);
                          _transformController.value = matrix * _transformController.value;
                        }
                      },
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        boundaryMargin: const EdgeInsets.all(200),
                        minScale: 0.3,
                        maxScale: 3.0,
                        child: _buildDiagram(style),
                      ),
                    )
                  : _buildDiagram(style),
            ),
          ),
          if (!_isInteractive)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              child: Text(
                '双击图表进入缩放模式 (Ctrl+滚轮缩放, 拖动平移)',
                style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiagram(MermaidStyle style) {
    return MermaidDiagram(
      code: widget.code,
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
    );
  }
}
