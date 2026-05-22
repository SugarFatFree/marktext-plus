import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import '../editor/mermaid/widgets/mermaid_diagram.dart';
import '../editor/mermaid/models/style.dart';
import '../editor/mermaid/models/node.dart' show NodeStyle;
import '../editor/mermaid/models/edge.dart' show EdgeStyle;

/// Renders Mermaid diagrams with auto-fit and fullscreen view
class MermaidRenderer extends StatelessWidget {
  final String code;
  final bool isDarkMode;

  const MermaidRenderer({
    super.key,
    required this.code,
    required this.isDarkMode,
  });

  MermaidStyle _buildStyle() {
    final baseStyle = isDarkMode ? MermaidStyle.dark() : const MermaidStyle();
    return MermaidStyle(
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
      nodeSpacingX: 80.0,
      nodeSpacingY: 80.0,
      padding: 30.0,
      fontFamily: baseStyle.fontFamily,
      themeMode: baseStyle.themeMode,
      classDefs: baseStyle.classDefs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _buildStyle();

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
                Tooltip(
                  message: '双击图表全屏查看',
                  child: TextButton.icon(
                    onPressed: () => _openFullscreen(context, style),
                    icon: const Icon(Icons.fullscreen, size: 16),
                    label: const Text('全屏'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
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
          GestureDetector(
            onDoubleTap: () => _openFullscreen(context, style),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Auto-fit: scale down to container width if diagram is too wide
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: _buildDiagram(style),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreen(BuildContext context, MermaidStyle style) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => _MermaidFullscreenView(
          code: code,
          style: style,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildDiagram(MermaidStyle style) {
    return MermaidDiagram(
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
              Text(error, style: TextStyle(color: Colors.red.shade900, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

class _MermaidFullscreenView extends StatefulWidget {
  final String code;
  final MermaidStyle style;

  const _MermaidFullscreenView({required this.code, required this.style});

  @override
  State<_MermaidFullscreenView> createState() => _MermaidFullscreenViewState();
}

class _MermaidFullscreenViewState extends State<_MermaidFullscreenView> {
  final TransformationController _controller = TransformationController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          children: [
            Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent &&
                    HardwareKeyboard.instance.isControlPressed) {
                  final scale = _controller.value.getMaxScaleOnAxis();
                  final delta = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
                  final newScale = (scale * delta).clamp(0.2, 5.0);
                  final focal = event.localPosition;
                  final scaleFactor = newScale / scale;
                  final dx = focal.dx * (1 - scaleFactor);
                  final dy = focal.dy * (1 - scaleFactor);
                  final m = Matrix4.identity()
                    ..setTranslationRaw(dx, dy, 0)
                    ..scale(scaleFactor, scaleFactor, 1.0);
                  _controller.value = m * _controller.value;
                }
              },
              child: InteractiveViewer(
                transformationController: _controller,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.2,
                maxScale: 5.0,
                child: Center(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24),
                    child: MermaidDiagram(code: widget.code, style: widget.style),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                children: [
                  _toolbarButton(Icons.zoom_out_map, '重置', _resetZoom),
                  const SizedBox(width: 8),
                  _toolbarButton(Icons.close, '关闭', () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Ctrl+滚轮缩放    拖动平移    Esc 关闭',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.5),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
