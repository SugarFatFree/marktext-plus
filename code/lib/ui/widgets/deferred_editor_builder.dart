import 'package:flutter/material.dart';

/// Builds an expensive editor pane one frame late, and keeps building it.
///
/// The three panes — source, preview, split — are all in the tree at once so
/// switching between them is instant. Building whichever one appears first
/// synchronously made the window wait for it, so this puts a spinner up for
/// one frame and builds after it.
///
/// **It used to keep the widget it built.** `builder` is a closure over the
/// document's text, and calling it once meant the pane went on showing the
/// text as it was the first time that pane was drawn. Everything that
/// rewrites a document without typing went past it: a plugin replacing the
/// selection, a reload from disk, the MCP server's `set_content`. The status
/// bar counted the new text while the preview drew the old — two parts of the
/// same window disagreeing, with nothing to say which was right.
///
/// So what is deferred is the *first* build, not the ones after it. The
/// renderer beneath does its own caching, keyed on the markdown it was given,
/// which is the level that can tell whether anything actually changed.
class DeferredEditorBuilder extends StatefulWidget {
  const DeferredEditorBuilder({
    super.key,
    required this.shouldBuild,
    required this.builder,
  });

  /// Whether this pane is the one on screen.
  final bool shouldBuild;

  /// The pane. Called on every build once the first frame has passed.
  final Widget Function() builder;

  @override
  State<DeferredEditorBuilder> createState() => _DeferredEditorBuilderState();
}

class _DeferredEditorBuilderState extends State<DeferredEditorBuilder> {
  /// Whether the first frame has passed and the pane may be built.
  ///
  /// Stays true once set, including while another pane is showing, so coming
  /// back to this one does not put the spinner up again.
  bool _ready = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.shouldBuild) _schedule();
  }

  @override
  void didUpdateWidget(DeferredEditorBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldBuild && !oldWidget.shouldBuild) _schedule();
  }

  void _schedule() {
    if (_scheduled || _ready) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        _scheduled = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.builder();

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
