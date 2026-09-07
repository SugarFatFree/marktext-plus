import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/providers/word_count_provider.dart';
import 'package:marktext_plus/services/word_count_service.dart';

/// The status bar's count is taken somewhere the window will not feel it.
///
/// `countWords` is one pass and there is no hot spot left in it, but one pass
/// over eight megabytes is 176 ms and it ran on the isolate drawing the
/// window — 300 ms after every pause in typing. A writer in a large document
/// stops to think, and the editor stutters at exactly that moment.
///
/// The off-thread version exists and is tested for agreement in
/// `word_count_service_test`. What this holds is the wiring: a provider that
/// still calls `countWords` directly would pass every one of those tests
/// while nothing about the stutter had changed. Built-and-never-wired-up has
/// happened seven times in this repository.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the provider does not count on the isolate drawing the window', () {
    final source =
        File('lib/providers/word_count_provider.dart').readAsStringSync();

    expect(
      source,
      contains('countWordsOffThread'),
      reason: '状态栏的字数要在别处算，否则大文档里每次停下打字都卡一下',
    );
    // The synchronous one, called from here, is the thing being replaced. Its
    // name is a prefix of the other, so the check has to be for a call rather
    // than for the name appearing at all.
    expect(
      source.contains('countWords(') && !source.contains('countWordsOffThread('),
      isFalse,
      reason: '同步版本还在被调用',
    );
  });

  group('a count that finished late', () {
    late Directory root;
    late ProviderContainer container;
    late _HeldService held;

    setUp(() {
      root = Directory.systemTemp.createTempSync('word_count_stale');
      held = _HeldService();
      container = ProviderContainer(overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: root.path),
            AppConfig(autoSave: false),
          ),
        ),
        wordCountProvider.overrideWith(
          (ref) => WordCountNotifier(ref, service: held),
        ),
      ]);
      container.read(wordCountProvider);
    });

    tearDown(() {
      container.dispose();
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    void open(String id, String content) =>
        container.read(tabProvider.notifier).addTab(
              TabInfo(id: id, fileName: '$id.md', content: content),
            );

    test('does not overwrite the document that replaced it', () async {
      // Taking the count elsewhere opened a window that did not exist while
      // it was synchronous: the answer arrives after the document it
      // describes has gone. A status bar showing the previous document's
      // numbers is worse than one showing them late, because nothing about it
      // looks wrong.
      //
      // Held open deliberately rather than raced. Making a real count outlast
      // the 300 ms debounce needs a document of about 24 MB on this machine,
      // and on a faster one the window closes and the test passes having
      // shown nothing — which is the failure mode that is hardest to notice.
      open('big', 'the long one');
      await Future<void>.delayed(const Duration(milliseconds: 340));
      expect(held.pending, hasLength(1),
          reason: '第一份文档的计数应该已经在进行中，否则这条测试没有窗口可测');

      open('small', 'one two three');
      await Future<void>.delayed(const Duration(milliseconds: 340));
      expect(container.read(wordCountProvider).words, 3,
          reason: '前提：后一份文档的计数已经写进状态栏');

      // Now the first one comes back, describing a document nobody is
      // looking at.
      held.finish('the long one', const WordCount(words: 999));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(wordCountProvider).words, 3,
          reason: '晚到的计数属于已经被换掉的文档，不能覆盖当前这一份');
    });
  });
}

/// A service whose counts finish when the test says so.
class _HeldService implements WordCountService {
  final WordCountService _real = WordCountService();
  final Map<String, Completer<WordCount>> pending = {};

  /// The long document is held; anything else is answered at once.
  ///
  /// Two behaviours in one fake because the test needs one of each: a count
  /// still running, and a later one that completes and reaches the state.
  @override
  Future<WordCount> countWordsOffThread(
    String markdown, {
    int isolateAbove = WordCountService.isolateAboveBytes,
  }) {
    if (markdown == 'the long one') {
      return (pending[markdown] = Completer<WordCount>()).future;
    }
    return Future.value(_real.countWords(markdown));
  }

  @override
  WordCount countWords(String markdown) => _real.countWords(markdown);

  void finish(String markdown, WordCount count) =>
      pending.remove(markdown)!.complete(count);
}
