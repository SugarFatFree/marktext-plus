import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// Which pane carries out a command from the Format menu.
///
/// The editors for all three modes live in one IndexedStack so that switching
/// modes does not throw their state away — which means the source pane is
/// still built, and still running, while the reader is looking at the preview.
/// It was taking every format command with it: the reader selected a line in
/// the preview, pressed Format, and the change landed wherever the source
/// pane's caret happened to be, which for a document nobody had typed in was
/// the first line.
void main() {
  test('the source pane acts when it is the one being looked at', () {
    expect(
      SourceEditor.actsOnFormat(
        mode: EditMode.source,
        previewBlockEditing: false,
      ),
      isTrue,
    );
  });

  test('it does not act while the reader is in the preview', () {
    expect(
      SourceEditor.actsOnFormat(
        mode: EditMode.preview,
        previewBlockEditing: false,
      ),
      isFalse,
      reason: '读者在看预览，源码窗格不在屏幕上，它的光标位置无人可见',
    );
  });

  test('in split view it acts, since both panes are on screen', () {
    expect(
      SourceEditor.actsOnFormat(
        mode: EditMode.split,
        previewBlockEditing: false,
      ),
      isTrue,
    );
  });

  test('but stands aside for a block open in the preview', () {
    // Otherwise both panes carry out the same command, in two places.
    expect(
      SourceEditor.actsOnFormat(
        mode: EditMode.split,
        previewBlockEditing: true,
      ),
      isFalse,
    );
  });

  test('and it never acts in preview, block open or not', () {
    for (final editing in [true, false]) {
      expect(
        SourceEditor.actsOnFormat(
          mode: EditMode.preview,
          previewBlockEditing: editing,
        ),
        isFalse,
      );
    }
  });
}
