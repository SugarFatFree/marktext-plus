import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/outline_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// The outline is found somewhere the window will not feel it.
///
/// The sibling of the word count, and its own note said so: "the same shape of
/// problem", pointing at the word count for the debounce it copied. The word
/// count later moved off this isolate and this one stayed — a sibling left
/// behind even though a comment named it.
///
/// 4.7 MB over 160,000 lines takes 184 ms here, run 300 ms after every pause
/// in typing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the provider does not scan the document on the isolate drawing it',
      () {
    final source =
        File('lib/providers/outline_provider.dart').readAsStringSync();
    expect(source, contains('Isolate.run'),
        reason: '大纲要在别处算，否则大文档里每次停下打字都卡一下');

    // Not only that the name appears. Reverting the call while leaving the
    // helper behind puts the scan straight back on this isolate, and a check
    // for the string alone would not notice — which is how it behaved when
    // that mutation was tried.
    expect(
      RegExp(r'state\s*=\s*MarkdownParser\.headingOutline').hasMatch(source),
      isFalse,
      reason: '又在这个 isolate 上直接算并赋值了',
    );
    expect(source, contains('await _compute('),
        reason: '定时器里要等那个异步计算，而不是绕过它');
  });

  test('the answer is the same on either isolate', () async {
    final document = List.generate(
      500,
      (i) => '${'#' * (1 + i % 6)} Heading $i\n\nSome text under it.\n',
    ).join('\n');

    final here = MarkdownParser.headingOutline(document);
    final there = await OutlineNotifier.computeForTest(document);

    expect(there.length, here.length);
    for (var i = 0; i < here.length; i++) {
      expect(there[i].line, here[i].line);
      expect(there[i].level, here[i].level);
      expect(there[i].text, here[i].text);
    }
  });

  group('an outline that finished late', () {
    late Directory root;
    late ProviderContainer container;
    late Map<String, Completer<List<OutlineEntry>>> held;

    setUp(() {
      root = Directory.systemTemp.createTempSync('outline_stale');
      held = {};
      container = ProviderContainer(overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: root.path),
            AppConfig(autoSave: false),
          ),
        ),
        outlineProvider.overrideWith(
          (ref) => OutlineNotifier(ref, compute: (content) {
            // The long one is held open; anything else answers at once.
            if (content == 'the long one') {
              return (held[content] = Completer<List<OutlineEntry>>()).future;
            }
            return Future.value(MarkdownParser.headingOutline(content));
          }),
        ),
      ]);
      container.read(outlineProvider);
    });

    tearDown(() {
      container.dispose();
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    void open(String id, String content) =>
        container.read(tabProvider.notifier).addTab(
              TabInfo(id: id, fileName: '$id.md', content: content),
            );

    test('does not replace the outline of the document now open', () async {
      // Going off-isolate opened a window that did not exist while this was
      // synchronous: the answer arrives after the document it describes has
      // gone. An outline from the previous document is worse than a late one,
      // because the headings look plausible and every line number is wrong —
      // and those line numbers are what clicking an entry scrolls to.
      open('big', 'the long one');
      await Future<void>.delayed(const Duration(milliseconds: 340));
      expect(held, hasLength(1),
          reason: '第一份文档的大纲应该正在算，否则这条测试没有窗口可测');

      open('small', '# Only heading\n\ntext\n');
      await Future<void>.delayed(const Duration(milliseconds: 340));
      expect(container.read(outlineProvider).map((e) => e.text), ['Only heading'],
          reason: '前提：后一份文档的大纲已经写进状态');

      held.remove('the long one')!.complete(
        const [(line: 0, level: 1, text: 'Stale heading')],
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(outlineProvider).map((e) => e.text), ['Only heading'],
          reason: '晚到的大纲属于已经被换掉的文档，不能覆盖当前这一份');
    });
  });
}
