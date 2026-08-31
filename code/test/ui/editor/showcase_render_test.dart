import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// The document that uses every construct, drawn rather than parsed.
///
/// The other tests over this fixture parse it and read the tree. Nothing drew
/// it: a construct that parses cleanly and then throws while being laid out —
/// a widget span with no size, a painter given a negative width — would reach
/// a reader as a red screen and no test at all. Emphasis nesting, ruby
/// annotations and `<img>` tags all changed the drawing side this week.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('showcase'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<void> draw(WidgetTester tester, String markdown) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(enableHtml: true),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MarkdownRenderer(markdown: markdown, onSourceChanged: (_) {}),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('the whole showcase draws without throwing', (tester) async {
    await draw(tester, File('test/fixtures/showcase.md').readAsStringSync());
    expect(tester.takeException(), isNull);
  });

  testWidgets('so does everything changed this week, together',
      (tester) async {
    // The constructs whose drawing changed, in one document and beside each
    // other, since that is where the interference would be.
    await draw(tester, '''
# 标题里的 **加粗** 与 [链接](/url)

**加粗里有 [链接](/url) 和 *斜体* 与 `代码`**，还有 <ruby>漢<rt>hàn</rt></ruby> 注音。

<img src="missing.png" alt="缺失的图" width="120">

- [ ] 任务里的 **加粗 [链接](/url)**
- 换行续写的一条，
在下一行继续。

> 引用第一行
引用续行，里面有 **加粗**。

| 表头 **粗** | 说明 |
|---|---|
| `代码` | [链接](/url) |

```mermaid
graph TD
    A[开始] --> B[结束]
```
''');
    expect(tester.takeException(), isNull);
  });
}
