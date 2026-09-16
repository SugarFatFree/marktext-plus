import '../core/config/app_config.dart';

/// Which pane carries out a format command, and whether any of them does.
///
/// The editors for all three modes live in one IndexedStack, so switching
/// modes keeps their state — and keeps the source pane building and running
/// while the reader is looking at the preview. It was taking every format
/// command with it: a line selected in the preview, Format pressed, and the
/// change landing wherever that pane's caret happened to be, which in a
/// document nobody had typed in is the first line.
///
/// Here rather than on the source pane because the answer is now needed by
/// something that is not a pane: the automation interface has to know whether
/// a format command it sends will reach anything, and reporting one that went
/// nowhere is the fault this repository keeps finding.
abstract final class FormatTarget {
  /// The source pane takes it.
  ///
  /// In split view both panes are on screen, so it acts — unless the preview
  /// has a block open, in which case the pane being typed in takes it.
  static bool sourcePane({
    required EditMode mode,
    required bool previewBlockEditing,
  }) {
    if (mode == EditMode.preview) return false;
    return !previewBlockEditing;
  }

  /// A block opened for editing in the preview takes it.
  static bool previewBlock({required bool previewBlockEditing}) =>
      previewBlockEditing;

  /// Whether anything at all will carry it out.
  ///
  /// False in exactly one case: the preview with no block open, where there is
  /// no field to act in. A command sent then sits in the state and fires the
  /// moment a pane appears, which is worse than being refused.
  static bool anything({
    required EditMode mode,
    required bool previewBlockEditing,
  }) =>
      sourcePane(mode: mode, previewBlockEditing: previewBlockEditing) ||
      previewBlock(previewBlockEditing: previewBlockEditing);
}
