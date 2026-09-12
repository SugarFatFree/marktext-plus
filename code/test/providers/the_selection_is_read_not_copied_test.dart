import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';

/// The selection is read when somebody asks for it, not copied when it changes.
///
/// Three places want the selected text and all three ask for it at the moment a
/// command runs. It was pushed into the editor state on every selection change
/// instead: a substring of the selection, then a comparison of that whole string
/// against the one before it, then a state notification. Holding Shift+Down
/// through a large document copied a progressively larger string on every
/// keypress — the gesture as a whole quadratic — and a four-megabyte selection
/// then sat in the state until the next one, beside the document, the field's own
/// copy and the undo history.
///
/// Measured: a partial substring of half a megabyte is 1.1 ms and of four
/// megabytes 3.6 ms. Select-All was free, because Dart hands back the same string
/// for the whole range — which is why this was invisible to anybody who tried it
/// by selecting everything.
void main() {
  late Directory configDir;
  late ProviderContainer container;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('selection_read');
    container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(),
        ),
      ),
    ]);
  });
  tearDown(() {
    container.dispose();
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  EditorNotifier notifier() => container.read(editorProvider.notifier);

  TextEditingController attach(String text) {
    final controller = TextEditingController(text: text);
    addTearDown(controller.dispose);
    notifier().setController(controller);
    return controller;
  }

  group('what the readers get', () {
    test('the source pane selection, taken when asked', () {
      final controller = attach('one two three');
      controller.selection = const TextSelection(baseOffset: 4, extentOffset: 7);
      notifier().setSourceSelection(controller.selection);
      expect(notifier().selectedText(), 'two');
    });

    test('nothing when the caret is just sitting there', () {
      final controller = attach('one two three');
      controller.selection = const TextSelection.collapsed(offset: 4);
      notifier().setSourceSelection(controller.selection);
      expect(notifier().selectedText(), isEmpty);
    });

    test('the preview selection, which has no offsets to take', () {
      notifier().setPreviewSelection('a heading');
      expect(notifier().selectedText(), 'a heading');
    });

    /// The two panes used to write to one field, so the last one to change won.
    /// That has to keep holding: a plugin run from the preview must not be handed
    /// what the source pane had selected a minute ago.
    test('the pane that changed last is the one that answers', () {
      final controller = attach('one two three');
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 3);
      notifier().setSourceSelection(controller.selection);
      expect(notifier().selectedText(), 'one');

      notifier().setPreviewSelection('from the preview');
      expect(notifier().selectedText(), 'from the preview');

      controller.selection = const TextSelection(baseOffset: 4, extentOffset: 7);
      notifier().setSourceSelection(controller.selection);
      expect(notifier().selectedText(), 'two',
          reason: '源码区重新选择之后，预览的旧选区还在答话');
    });

    test('a collapsed caret in the source clears what the preview said', () {
      final controller = attach('one two three');
      notifier().setPreviewSelection('from the preview');
      controller.selection = const TextSelection.collapsed(offset: 0);
      notifier().setSourceSelection(controller.selection);
      expect(notifier().selectedText(), isEmpty,
          reason: '把光标放回源码区之后，预览的旧选区仍然被当作当前选区');
    });

    test('a range outside the text does not throw', () {
      final controller = attach('short');
      notifier().setSourceSelection(
          const TextSelection(baseOffset: 0, extentOffset: 9999));
      expect(notifier().selectedText(), 'short');
      controller.selection = const TextSelection.collapsed(offset: 0);
    });
  });

  /// The guard. Recording a selection must cost the same whatever it covers,
  /// which is what "supports large files" means on this path.
  ///
  /// The range stops one character short of the end on purpose. `substring` over
  /// the whole of a string hands back the same object and costs nothing, so a
  /// guard written with Select-All would measure the one case that was never
  /// expensive — which is exactly why this went unnoticed. The comment on
  /// `setSourceSelection` says so, and I wrote this test with Select-All anyway;
  /// the mutation that restores the copying is what caught it.
  test('recording a selection costs the same however big it is', () {
    final small = attach('x' * (40 * 1024));
    int fastest(TextEditingController controller, int end) {
      var best = 1 << 30;
      for (var round = 0; round < 2000; round++) {
        final selection = TextSelection(baseOffset: 0, extentOffset: end - 1);
        final watch = Stopwatch()..start();
        notifier().setSourceSelection(selection);
        watch.stop();
        // A different range each round, or a setter that short-circuits on an
        // unchanged value would measure nothing.
        notifier().setSourceSelection(const TextSelection.collapsed(offset: 0));
        if (watch.elapsedMicroseconds < best) best = watch.elapsedMicroseconds;
      }
      return best;
    }

    final tiny = fastest(small, 40 * 1024);
    final large = attach('y' * (4 * 1024 * 1024));
    final huge = fastest(large, 4 * 1024 * 1024);

    // Before this change the large one took a four-megabyte copy and the small
    // one a forty-kilobyte copy — about a hundred times apart.
    expect(huge, lessThan((tiny + 2) * 8),
        reason: '记录一个大选区比记录一个小选区贵得多（$huge µs vs $tiny µs）——'
            '说明它在拷贝选区，而不是记下范围');
  });
}
