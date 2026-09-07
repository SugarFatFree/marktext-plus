import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// Pictures a plugin's markdown asks for, fetched once and let go of.
///
/// The renderer keeps what it has already loaded so that a rebuild — a caret
/// move, a theme change — does not fetch again; for a plugin that would also
/// mean a fresh line in its log each time.
///
/// The first version put the image revision in the cache key, which reloads
/// correctly and never releases what it replaced. Each entry holds a picture,
/// up to eight megabytes of one, so every "reload images" added a generation
/// and kept the ones before it for as long as the widget lived.
///
/// Emptying on a new revision is the same behaviour without the pile, and
/// these two tests are what says it is the same behaviour.
void main() {
  group('what the cache holds', () {
    Future<Uint8List> nothing(String href) async => Uint8List(0);

    test('a reload replaces the pictures rather than adding to them', () async {
      // The only difference between emptying and keying by revision, and it
      // cannot be seen from the widget: both fetch again, both draw the same
      // thing. What separates them is what is still being held afterwards,
      // and each entry can be eight megabytes of picture.
      final cache = PictureCache();
      await cache.fetch(0, 'a.png', nothing);
      await cache.fetch(0, 'b.png', nothing);
      expect(cache.length, 2);

      await cache.fetch(1, 'a.png', nothing);
      await cache.fetch(1, 'b.png', nothing);
      expect(cache.length, 2,
          reason: '第二代的两张，不是两代的四张——每条最大八兆');

      for (var revision = 2; revision < 12; revision++) {
        await cache.fetch(revision, 'a.png', nothing);
      }
      expect(cache.length, 1, reason: '十次重载之后仍然只握着当前这一张');
    });

    test('the same picture in one revision is fetched once', () async {
      var calls = 0;
      Future<Uint8List> counted(String href) async {
        calls++;
        return Uint8List(0);
      }

      final cache = PictureCache();
      await cache.fetch(0, 'a.png', counted);
      await cache.fetch(0, 'a.png', counted);
      expect(calls, 1, reason: '缓存不生效的话，每次重建都要重新取一遍');

      await cache.fetch(1, 'a.png', counted);
      expect(calls, 2, reason: '换代要重新取，否则「重新加载图片」是摆设');
    });
  });

  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('picture_cache'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  /// A one-pixel PNG, so `Image.memory` has something real to decode.
  final png = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  testWidgets('a picture is fetched once, and again after a reload', (
    tester,
  ) async {
    final asked = <String>[];
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: root.path),
          AppConfig(),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: MarkdownRenderer(
            markdown: '![one](http://elsewhere/a.png)\n\n'
                '![two](http://elsewhere/b.png)\n',
            loadImage: (source) async {
              asked.add(source);
              return png;
            },
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(asked, hasLength(2), reason: '两张图，各取一次');

    // Rebuilds without a reload must not fetch again — that is what the cache
    // is for, and for a plugin each fetch is also a line in its log.
    container.read(editorProvider.notifier).updateCursor(3, 1);
    await tester.pumpAndSettle();
    expect(asked, hasLength(2), reason: '重建不该重新取图');

    // A reload has to reach the network again, or the command does nothing.
    container.read(editorProvider.notifier).reloadImages();
    await tester.pumpAndSettle();
    expect(asked, hasLength(4),
        reason: '「重新加载图片」必须真的重新取，否则这条命令是摆设');
    expect(asked.sublist(2), asked.sublist(0, 2));
  });

  testWidgets('a document picture is asked for again after a reload', (
    tester,
  ) async {
    // The document path, which is what F5 is for. It goes through
    // `Image.network` rather than a loader, so what can be observed is the
    // key the renderer builds — and that key was still saying `image:0:`
    // after a reload, which is how the whole thing came to light.
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: root.path),
          AppConfig(),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: MarkdownRenderer(
            markdown: '![one](http://elsewhere/a.png)\n',
          ),
        ),
      ),
    ));
    await tester.pump();

    Key? keyOfImage() {
      final images = tester.widgetList<Image>(find.byType(Image));
      return images.isEmpty ? null : images.first.key;
    }

    final before = keyOfImage();
    expect(before, isNotNull, reason: '没找到图片控件，这条测试就什么也没测');

    container.read(editorProvider.notifier).reloadImages();
    await tester.pump();

    expect(keyOfImage(), isNot(before),
        reason: 'F5 之后要用新的 key 重新解析图片，否则屏幕上还是取回来的那一张');
  });
}
