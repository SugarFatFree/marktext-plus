import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../editor/mermaid/parser/mermaid_parser.dart';
import '../editor/mermaid/widgets/mermaid_diagram.dart';
import '../editor/mermaid/models/style.dart';
import '../editor/mermaid/models/node.dart' show NodeStyle;
import '../editor/mermaid/models/edge.dart' show EdgeStyle;

/// Renders Mermaid diagrams with auto-fit and fullscreen view
class MermaidRenderer extends StatefulWidget {
  final String code;
  final bool isDarkMode;

  /// Opens this block for editing, when the preview allows it.
  ///
  /// A diagram cannot be edited by double tap the way every other block can:
  /// its own recogniser claims the gesture for fullscreen, and being deeper in
  /// the tree it wins the arena. Null in a read-only preview, where no block
  /// is editable.
  final VoidCallback? onEditSource;

  const MermaidRenderer({
    super.key,
    required this.code,
    required this.isDarkMode,
    this.onEditSource,
  });

  @override
  State<MermaidRenderer> createState() => _MermaidRendererState();
}

class _MermaidRendererState extends State<MermaidRenderer> {
  final GlobalKey _diagramKey = GlobalKey();

  MermaidStyle _buildStyle() {
    final baseStyle = widget.isDarkMode ? MermaidStyle.dark() : const MermaidStyle();
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
      // DagreLayout now dynamically adjusts spacing based on edge labels
      nodeSpacingX: 60.0,
      nodeSpacingY: 60.0,
      padding: 30.0,
      fontFamily: baseStyle.fontFamily,
      themeMode: baseStyle.themeMode,
      classDefs: baseStyle.classDefs,
    );
  }

  Future<void> _saveAsImage(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final boundary = _diagramKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.mermaidCaptureFailed),
            ),
          );
        }
        return;
      }

      // Capture at 2x for higher quality
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      // Let user pick save location
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: l10n.mermaidSaveAs,
        fileName: 'mermaid_diagram.png',
        type: FileType.custom,
        allowedExtensions: ['png'],
        bytes: pngBytes,
      );

      // On desktop, savePath returns the path; on mobile/web, the file is already saved via bytes
      if (savePath != null && !Platform.isAndroid && !Platform.isIOS) {
        await File(savePath).writeAsBytes(pngBytes);
      }

      if (context.mounted && savePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.imageSavedTo(savePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.imageSaveFailed('$e'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _buildStyle();
    final l10n = AppLocalizations.of(context)!;

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
                // A Wrap rather than a Spacer and a run of buttons: four of
                // them no longer fit a narrow preview pane, and a Row that
                // does not fit overflows rather than reflowing.
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                    Tooltip(
                      message: l10n.mermaidFullscreenHint,
                      child: TextButton.icon(
                        key: const Key('mermaid-fullscreen'),
                        onPressed: () => _openFullscreen(context, style),
                        icon: const Icon(Icons.fullscreen, size: 16),
                        label: Text(l10n.mermaidFullscreen),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: l10n.mermaidSaveAsHint,
                      child: TextButton.icon(
                        key: const Key('mermaid-save-as'),
                        onPressed: () => _saveAsImage(context),
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: Text(l10n.mermaidSaveAs),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (widget.onEditSource != null)
                      TextButton.icon(
                        key: const Key('mermaid-edit-source'),
                        onPressed: widget.onEditSource,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(l10n.mermaidEditSource),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    TextButton.icon(
                      key: const Key('mermaid-copy-source'),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: widget.code));
                      },
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      label: Text(l10n.mermaidCopySource),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    ],
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
                  return RepaintBoundary(
                    key: _diagramKey,
                    child: Container(
                      color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                            maxWidth: constraints.maxWidth * 3,
                          ),
                          child: _buildDiagram(style),
                        ),
                      ),
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
      builder: (context) => _MermaidFullscreenView(code: widget.code, style: style),
    );
  }

  /// The parse failure, worded in the reader's language.
  String _localisedFailure(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context)!;
    final failure = const MermaidParser().describeFailure(code);
    switch (failure.kind) {
      case MermaidFailureKind.empty:
        return l10n.mermaidErrorEmpty;
      case MermaidFailureKind.unknownType:
        // The type names stay as they are: they are what has to be typed.
        return '${l10n.mermaidErrorUnknownType(failure.detail)}\n'
            '${l10n.mermaidSupportedTypes(MermaidParser.supportedTypes.join(', '))}';
      case MermaidFailureKind.headerOnly:
        return l10n.mermaidErrorHeaderOnly;
      case MermaidFailureKind.unparsedBody:
        return l10n.mermaidErrorBadBody;
    }
  }

  Widget _buildDiagram(MermaidStyle style) {
    return MermaidDiagram(
      code: widget.code,
      style: style,
      errorBuilder: (context, error) {
        // Through the colour scheme rather than a fixed red: the pale red wash
        // was painted the same in every theme, so on a dark one the message
        // arrived as a bright panel in the middle of the document.
        final scheme = Theme.of(context).colorScheme;
        // `error` is the package's own English sentence. The package depends on
        // nothing but Flutter and so cannot reach these translations; ask it
        // for the reason instead and word it here.
        final detail = _localisedFailure(context, widget.code);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: scheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)!.mermaidParseError,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
              ),
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
    final l10n = AppLocalizations.of(context)!;
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
                    Text(
                      l10n.mermaidViewerTitle,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    _toolbarButton(
                        Icons.zoom_out_map, l10n.viewResetZoom, _resetZoom),
                    const SizedBox(width: 8),
                    _toolbarButton(Icons.close, l10n.close,
                        () => Navigator.of(context).pop()),
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
                        ..scaleByDouble(scaleFactor, scaleFactor, 1.0, 1.0);
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
                child: Center(
                  child: Text(
                    l10n.mermaidViewerHint,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
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
