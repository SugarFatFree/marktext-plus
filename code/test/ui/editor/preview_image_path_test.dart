import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// An image written with a path relative to the document.
///
/// `![](./img/x.png)` is how images are ordinarily written in markdown, and
/// the path is relative to the file the markdown is in. `File('./img/x.png')`
/// resolves against the *process's* working directory instead, which is
/// wherever the application happened to be started from — so the picture was
/// simply not found. The export side already resolved these correctly against
/// the document's directory; the preview did not.
void main() {
  late Directory docDir;
  late Directory configDir;

  /// The smallest thing `Image.file` will accept as a PNG.
  final onePixelPng = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);

  setUp(() {
    docDir = Directory.systemTemp.createTempSync('previewimg');
    configDir = Directory.systemTemp.createTempSync('previewimgcfg');
    Directory('${docDir.path}/img').createSync();
    File('${docDir.path}/img/x.png').writeAsBytesSync(onePixelPng);
  });
  tearDown(() {
    for (final dir in [docDir, configDir]) {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
  });

  Future<void> pump(WidgetTester tester, String markdown) async {
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    container.read(tabProvider.notifier).addTab(
          TabInfo(
            id: 'doc',
            fileName: 'note.md',
            filePath: '${docDir.path}/note.md',
            content: markdown,
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: MarkdownRenderer(markdown: markdown)),
        ),
      ),
    );
    await tester.pump();
  }

  /// The path `Image.file` was actually pointed at.
  String? fileImagePath(WidgetTester tester) {
    final images = tester.widgetList<Image>(find.byType(Image));
    for (final image in images) {
      final provider = image.image;
      if (provider is FileImage) return provider.file.path;
    }
    return null;
  }

  testWidgets('a path relative to the document resolves against its folder',
      (tester) async {
    await pump(tester, '![x](./img/x.png)\n');
    expect(fileImagePath(tester), '${docDir.path}/img/x.png',
        reason: '相对路径没有按文档所在目录解析');
  });

  testWidgets('a bare relative path resolves too', (tester) async {
    await pump(tester, '![x](img/x.png)\n');
    expect(fileImagePath(tester), '${docDir.path}/img/x.png');
  });

  testWidgets('an absolute path is left as it is', (tester) async {
    final absolute = '${docDir.path}/img/x.png';
    await pump(tester, '![x]($absolute)\n');
    expect(fileImagePath(tester), absolute);
  });

  testWidgets('a network image is not touched', (tester) async {
    await pump(tester, '![x](https://example.com/x.png)\n');
    final images = tester.widgetList<Image>(find.byType(Image));
    expect(images.any((i) => i.image is NetworkImage), isTrue);
  });

  // A picture wider than the preview was the other thing to check here, and
  // it needs nothing: a WidgetSpan's child is laid out with the paragraph's
  // own constraints — measured, a 2000-wide child inside a 400-wide parent
  // comes out 400 — and RenderImage constrains with
  // `constrainSizeAndAttemptToPreserveAspectRatio`, so a large photo is
  // scaled down rather than clipped or squashed. No test here, because the
  // one that could be written proves nothing: `Image.file` never decodes in
  // a widget test, so the rectangle measured is 0x0 and any assertion about
  // it passes whatever the code does.
}
