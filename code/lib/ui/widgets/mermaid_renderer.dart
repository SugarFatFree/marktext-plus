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
    // Increase spacing for diagrams with long edge labels (state diagrams especially)
    final maxLabelLen = _estimateMaxEdgeLabelLength();
    // Each char adds ~10px space; cap at 200px extra
    final extraSpacing = (maxLabelLen * 10).clamp(0, 200).toDouble();
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
      nodeSpacingX: 80.0 + extraSpacing,
      nodeSpacingY: 80.0 + extraSpacing,
      padding: 30.0,
      fontFamily: baseStyle.fontFamily,
      themeMode: baseStyle.themeMode,
      classDefs: baseStyle.classDefs,
    );
  }

  /// Estimate the longest edge label length in the source code (for spacing adjustment).
  int _estimateMaxEdgeLabelLength() {
    int max = 0;
    for (final line in code.split('\n')) {
      final trimmed = line.trim();
      // Match `... --> ... : label` or `... -->|label| ...`
      final m1 = RegExp(r'-->\s*[^:|]+?\s*:\s*(.+)$').firstMatch(trimmed);
      final m2 = RegExp(r'-->\|([^|]+)\|').firstMatch(trimmed);
      final label = (m1?.group(1) ?? m2?.group(1) ?? '').trim();
      // Chinese chars count as ~2 width
      final width = label.runes.fold<int>(0, (acc, r) => acc + (r > 127 ? 2 : 1));
      if (width > max) max = width;
    }
    return max;
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
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                        maxWidth: constraints.maxWidth * 3,
                      ),
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
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _MermaidFullscreenView(code: code, style: style),
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
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.1,
        vertical: size.height * 0.1,
      ),
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Title bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schema_outlined, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Mermaid 图表查看',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    _toolbarButton(Icons.zoom_out_map, '重置', _resetZoom),
                    const SizedBox(width: 8),
                    _toolbarButton(Icons.close, '关闭', () => Navigator.of(context).pop()),
                  ],
                ),
              ),
              // Diagram viewer
              Expanded(
                child: Listener(
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
                        padding: const EdgeInsets.all(24),
                        child: MermaidDiagram(code: widget.code, style: widget.style),
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom hint
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: const Center(
                  child: Text(
                    'Ctrl+滚轮缩放    拖动平移    Esc 关闭',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.black54, size: 18),
        ),
      ),
    );
  }
}
