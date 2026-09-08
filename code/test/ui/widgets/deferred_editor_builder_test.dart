import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/widgets/deferred_editor_builder.dart';

/// A pane built one frame late still follows the document afterwards.
///
/// Reported from a running build over the editor's own MCP server: writing a
/// document's text and looking at the preview showed the *previous*
/// document, while the status bar counted the new one. Two parts of the same
/// window disagreeing, and no error anywhere.
///
/// The cause was that the built widget was kept: `builder` closes over the
/// text, and calling it once meant the pane showed the text as it was the
/// first time that pane appeared. Typing goes through the source editor's own
/// controller and was unaffected — everything else was not: a plugin
/// replacing the selection, a reload from disk, `set_content`.
void main() {
  /// Pumps [child] and lets the deferred first frame pass.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  testWidgets('the first build waits a frame, then appears', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DeferredEditorBuilder(
        shouldBuild: true,
        builder: () => const Text('the document'),
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget,
        reason: '第一帧先给骨架，不让窗口等着建编辑器');
    expect(find.text('the document'), findsNothing);

    await settle(tester);
    expect(find.text('the document'), findsOneWidget);
  });

  testWidgets('a change to what the builder returns reaches the screen',
      (tester) async {
    Widget app(String text) => MaterialApp(
          home: DeferredEditorBuilder(
            shouldBuild: true,
            builder: () => Text(text),
          ),
        );

    await tester.pumpWidget(app('first version'));
    await settle(tester);
    expect(find.text('first version'), findsOneWidget);

    await tester.pumpWidget(app('second version'));
    await tester.pump();

    expect(find.text('second version'), findsOneWidget,
        reason: '文档被改写之后，这一格必须画新的那份——'
            '插件替换、磁盘重载、MCP 写入都走这条路');
    expect(find.text('first version'), findsNothing,
        reason: '旧的那份不能还留在屏幕上');
  });

  testWidgets('coming back to a pane does not show the spinner again',
      (tester) async {
    Widget app({required bool visible}) => MaterialApp(
          home: DeferredEditorBuilder(
            shouldBuild: visible,
            builder: () => const Text('the document'),
          ),
        );

    await tester.pumpWidget(app(visible: true));
    await settle(tester);
    expect(find.text('the document'), findsOneWidget);

    // Another pane takes the screen, then this one comes back.
    await tester.pumpWidget(app(visible: false));
    await tester.pump();
    await tester.pumpWidget(app(visible: true));
    await tester.pump();

    expect(find.text('the document'), findsOneWidget,
        reason: '切走再切回来不该重新转圈——那是原来那份缓存唯一买到的东西，'
            '换成一个标志位同样买得到');
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a pane that was never shown builds nothing', (tester) async {
    var built = 0;
    await tester.pumpWidget(MaterialApp(
      home: DeferredEditorBuilder(
        shouldBuild: false,
        builder: () {
          built++;
          return const Text('never');
        },
      ),
    ));
    await settle(tester);

    expect(built, 0, reason: '没轮到它显示就不该建——这才是「延迟」的意义');
    expect(find.text('never'), findsNothing);
  });
}
