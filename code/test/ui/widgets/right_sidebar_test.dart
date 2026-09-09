import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/widgets/plugin_tip.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/mcp_provider.dart';
import 'package:marktext_plus/ui/widgets/right_side_bar.dart';

/// The right side bar exists only when a plugin has put something in it.
///
/// `ui.sidebar` was in the permission list with nothing behind it. A rail of
/// icons with no icons in it is a strip of nothing taking width from the
/// document, so with no panels contributed there is no rail at all.
void main() {
  late Directory support;

  setUp(() {
    support = Directory.systemTemp.createTempSync('right_bar_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => support.path,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'), null);
    if (support.existsSync()) support.deleteSync(recursive: true);
  });

  void install(String id, {required List<Map<String, String>> panels,
      List<String> permissions = const ['ui.sidebar'],
      String script = ''}) {
    final dir = Directory('${support.path}/plugins/$id')
      ..createSync(recursive: true);
    File('${dir.path}/manifest.json').writeAsStringSync(jsonEncode({
      'id': id,
      'name': 'Demo',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
      'permissions': permissions,
      'panels': panels,
    }));
    File('${dir.path}/plugin.lua').writeAsStringSync(script);
  }

  /// Like [pump], but hands back the container so a test can reach the
  /// handler the rail registers for the automation interface.
  Future<ProviderContainer> pumpWithContainer(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: support.path),
            // Off, or writing to a tab arms a five-second timer that outlives
            // the test — which fails as "a Timer is still pending" and says
            // nothing about the drawer.
            AppConfig(autoSave: false),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PluginTipLayer(
            child: Row(
              children: [Expanded(child: SizedBox()), RightSideBar()],
            ),
          ),
        ),
      ),
    ));
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    return container;
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      // The drawer runs the whole command now rather than one step of it, so
      // it reads the settings the way every other command path does — which
      // needs a config service, which a widget test has to hand it.
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: support.path),
            AppConfig(),
          ),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        // The card layer is where a question is asked, and in the running
        // application it wraps the whole window. A drawer that asks needs it
        // present or the question has nowhere to appear.
        home: Scaffold(
          body: PluginTipLayer(
            child: Row(
              children: [Expanded(child: SizedBox()), RightSideBar()],
            ),
          ),
        ),
      ),
    ));
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
  }

  testWidgets('with nothing contributed the bar is not there', (tester) async {
    await pump(tester);
    expect(tester.getSize(find.byType(RightSideBar)).width, 0,
        reason: '没有图标的图标栏就是白占宽度');
  });

  testWidgets('a contributed panel puts an icon in the rail', (tester) async {
    install('com.example.demo',
        panels: [{'id': 'outline', 'title': 'Outline', 'icon': 'list'}]);
    await pump(tester);

    expect(tester.getSize(find.byType(RightSideBar)).width, greaterThan(0));
    expect(find.byIcon(Icons.list), findsOneWidget);
  });

  testWidgets('a panel from a plugin without the permission is not shown',
      (tester) async {
    install('com.example.demo',
        panels: [{'id': 'outline', 'title': 'Outline', 'icon': 'list'}],
        permissions: const []);
    await pump(tester);

    expect(tester.getSize(find.byType(RightSideBar)).width, 0,
        reason: '没申请 ui.sidebar 就不该出现在侧栏');
  });

  testWidgets('pressing the icon opens the drawer, pressing again closes it',
      (tester) async {
    install('com.example.demo',
        panels: [{'id': 'outline', 'title': 'Outline', 'icon': 'list'}]);
    await pump(tester);

    final railOnly = tester.getSize(find.byType(RightSideBar)).width;

    await tester.tap(find.byIcon(Icons.list));
    await tester.pump();
    expect(tester.getSize(find.byType(RightSideBar)).width,
        greaterThan(railOnly));
    expect(find.text('Outline'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.list));
    await tester.pump();
    expect(tester.getSize(find.byType(RightSideBar)).width, railOnly,
        reason: '再点一次该收起抽屉，只留图标栏');
  });

  testWidgets('a panel that asks a question gets to ask it', (tester) async {
    // The drawer used to run one step of the command and render whatever came
    // back as text, so a plugin that opens with a question — which the one
    // official plugin does, since writing needs a brief — filled the drawer
    // with the sentence "a panel cannot ask a question" and offered nowhere
    // to type. Manual testing put it plainly: no input box, so no way to say
    // what to write.
    install('com.example.asker', panels: [
      {'id': 'ask.something', 'title': 'Ask', 'icon': 'edit_note'},
    ], script: '''
function on_command(ctx)
  if ctx.answer == nil then
    return { ask = "What should it say?" }
  end
  return { show = "you said " .. ctx.answer }
end
''');
    await pump(tester);
    await tester.tap(find.byIcon(Icons.edit_note));
    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }

    expect(find.textContaining('cannot ask'), findsNothing,
        reason: '面板不该再用一句话打发掉提问');
    expect(find.textContaining('What should it say?'), findsOneWidget,
        reason: '问题该真的问出来');

    // And asked here. It was asked in the floating card while the answer
    // arrived in this drawer — one exchange in two places, which is what
    // "why is it a pop-up?" was about. The card is still right for a command
    // started from a menu, which has no room of its own.
    expect(
      find.descendant(
        of: find.byType(RightSideBar),
        matching: find.textContaining('What should it say?'),
      ),
      findsOneWidget,
      reason: '从侧边栏点开的命令，问题该问在侧边栏里，不是浮动卡片',
    );
    // The card is not also asking: `findsOneWidget` above would have found
    // two of that question if it were. Not written as "no TextField in the
    // tip layer" — that layer wraps the whole body, so the drawer's own box
    // is inside it.

    // There is somewhere to type, and answering reaches the plugin.
    await tester.enterText(
      find.descendant(
        of: find.byType(RightSideBar),
        matching: find.byType(TextField),
      ),
      'a haiku',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }

    expect(find.textContaining('you said a haiku'), findsOneWidget,
        reason: '答案该回到插件手里，结果该落在同一个抽屉');
  });

  testWidgets('a tree the plugin drew appears in the drawer itself',
      (tester) async {
    // Not in the card. The reader opened this drawer, so this is where they
    // are looking; the card is for commands started somewhere with no room of
    // its own.
    install('com.example.former', panels: [
      {'id': 'form.something', 'title': 'Form', 'icon': 'edit_note'},
    ], script: '''
function on_command(ctx)
  return { ui = { column = {
    { text = "Say what to write" },
    { input = { id = "brief" } },
    { button = { id = "go", label = "Write" } },
  }}}
end

function on_event(ctx, id, values)
  return { show = "got " .. id .. ": " .. (values.brief or "") }
end
''');
    await pump(tester);
    await tester.tap(find.byIcon(Icons.edit_note));
    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }

    expect(find.text('Say what to write'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget,
        reason: '插件画的输入框该出现在抽屉里');

    await tester.enterText(find.byType(TextField), 'make it shorter');
    await tester.tap(find.text('Write'));
    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }

    expect(find.textContaining('got go: make it shorter'), findsOneWidget,
        reason: '按钮该把输入的值带回插件，结果落回抽屉');
  });

  /// Pumps until the plugin's script has run and its answer has arrived.
  Future<void> settlePlugin(WidgetTester tester) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
  }

  testWidgets('a rewrite offered in the drawer can be taken', (tester) async {
    // The defect this covers: the sink the rail passes carried the words and
    // dropped everything the plugin had said about them, so a command that
    // offers a rewrite — which is what the official plugin's writing and
    // proofreading do — showed its answer in the drawer with no way to put it
    // into the document. The same command from the menu offered a button.
    install(
      'com.example.demo',
      panels: [
        {'id': 'rewrite', 'title': 'Rewrite', 'icon': 'list'},
      ],
      permissions: const ['ui.sidebar', 'document.read', 'document.write'],
      script: 'function on_command(ctx)\n'
          '  return { pane = "REWRITTEN", title = "Rewrite",\n'
          '           apply = true, replaces = "old" }\n'
          'end\n',
    );
    await pump(tester);

    await tester.tap(find.byIcon(Icons.list));
    await settlePlugin(tester);

    expect(find.text('REWRITTEN'), findsOneWidget, reason: '抽屉里没有结果');
    expect(
      find.byKey(const Key('plugin-drawer-apply')),
      findsOneWidget,
      reason: '插件说了这段可以采用，抽屉里却没有采用的办法',
    );
  });

  testWidgets('an answer that is not a rewrite offers nothing to take',
      (tester) async {
    // The other half: a panel that only shows something must not grow a
    // button that would replace the document with it.
    install(
      'com.example.demo',
      panels: [
        {'id': 'note', 'title': 'Note', 'icon': 'list'},
      ],
      script: 'function on_command(ctx)\n'
          '  return { pane = "JUST READING", title = "Note" }\n'
          'end\n',
    );
    await pump(tester);

    await tester.tap(find.byIcon(Icons.list));
    await settlePlugin(tester);

    expect(find.text('JUST READING'), findsOneWidget);
    expect(find.byKey(const Key('plugin-drawer-apply')), findsNothing);
  });

  group('driven from the automation interface', () {
    // Why this exists: BUG-369 lived in this path for as long as the path
    // existed, because nothing automated could reach it. `run_plugin_command`
    // runs the menu-bar path, which hands the answer somewhere else entirely.

    testWidgets('pressing a panel by name says what the drawer showed',
        (tester) async {
      install(
        'com.example.demo',
        panels: [
          {'id': 'note', 'title': 'Note', 'icon': 'list'},
        ],
        script: 'function on_command(ctx)\n'
            '  return { pane = "FROM THE PANEL", title = "Note" }\n'
            'end\n',
      );
      final container = await pumpWithContainer(tester);

      final outcome = await container
          .read(mcpProvider.notifier)
          .openPluginPanel!('com.example.demo', 'note', null);
      await settlePlugin(tester);

      expect(outcome.ok, isTrue);
      expect(outcome.said, contains('FROM THE PANEL'));
    });

    testWidgets('a panel that asks is answered, and gets on with it',
        (tester) async {
      // Without an answer the command waits for a reader who is not there.
      install(
        'com.example.demo',
        panels: [
          {'id': 'write', 'title': 'Write', 'icon': 'list'},
        ],
        script: 'function on_command(ctx)\n'
            '  if ctx.answer == nil then\n'
            '    return { ask = "what?" }\n'
            '  end\n'
            '  return { pane = "wrote: " .. ctx.answer, title = "Write" }\n'
            'end\n',
      );
      final container = await pumpWithContainer(tester);

      final outcome = await container
          .read(mcpProvider.notifier)
          .openPluginPanel!('com.example.demo', 'write', 'a summary');
      await settlePlugin(tester);

      expect(outcome.said, contains('wrote: a summary'));
    });

    testWidgets('a panel a plugin has not got is refused, and names the ones '
        'it has', (tester) async {
      install(
        'com.example.demo',
        panels: [
          {'id': 'note', 'title': 'Note', 'icon': 'list'},
        ],
      );
      final container = await pumpWithContainer(tester);

      final outcome = await container
          .read(mcpProvider.notifier)
          .openPluginPanel!('com.example.demo', 'nosuch', null);

      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('note'));
    });

    testWidgets('a plugin without the sidebar permission is refused',
        (tester) async {
      install(
        'com.example.demo',
        panels: [
          {'id': 'note', 'title': 'Note', 'icon': 'list'},
        ],
        permissions: const [],
      );
      final container = await pumpWithContainer(tester);

      final outcome = await container
          .read(mcpProvider.notifier)
          .openPluginPanel!('com.example.demo', 'note', null);

      expect(outcome.ok, isFalse, reason: '没有图标可按，就不该假装按下去了');
    });
  });

  group('the drawer draws what the plugin asked for', () {
    // Siblings of BUG-369, found by asking what else a pane carries that the
    // drawer was throwing away. A pane knows three more things about its
    // answer than the drawer did: whether it is a rewrite (fixed there), how
    // it should be drawn, and whether more is still coming.

    testWidgets('an answer meant to be read is rendered, not shown as source',
        (tester) async {
      install(
        'com.example.demo',
        panels: [
          {'id': 'note', 'title': 'Note', 'icon': 'list'},
        ],
        script: 'function on_command(ctx)\n'
            '  return { pane = "# Heading", title = "Note", as = "preview" }\n'
            'end\n',
      );
      await pump(tester);

      await tester.tap(find.byIcon(Icons.list));
      await settlePlugin(tester);

      // Rendered: the hash is gone and the words are a heading.
      expect(find.text('# Heading'), findsNothing,
          reason: '插件要求按预览画，抽屉却把 Markdown 原样显示了');
      expect(find.text('Heading'), findsWidgets);
    });

    testWidgets('an answer meant to be read as source keeps its markup',
        (tester) async {
      // The other half: rendering everything would hide the markup from a
      // reader comparing it against their own source.
      install(
        'com.example.demo',
        panels: [
          {'id': 'note', 'title': 'Note', 'icon': 'list'},
        ],
        script: 'function on_command(ctx)\n'
            '  return { pane = "# Heading", title = "Note" }\n'
            'end\n',
      );
      await pump(tester);

      await tester.tap(find.byIcon(Icons.list));
      await settlePlugin(tester);

      expect(find.text('# Heading'), findsOneWidget);
    });
  });

  group('the drawer is a conversation, not one shot', () {
    // A panel used to end with its first answer. Not liking it meant closing
    // the drawer and describing the whole thing again from the beginning.

    /// Answers whatever it is asked, and says what it was working on, so a
    /// test can see which text the second round was given.
    const echo = 'function on_command(ctx)\n'
        '  if ctx.answer == nil then\n'
        '    return { ask = "what?" }\n'
        '  end\n'
        '  local about = ctx.selection\n'
        '  if about == nil or about == "" then about = "DOC" end\n'
        '  return { pane = ctx.answer .. " of " .. about, title = "W",\n'
        '           apply = true, replaces = about }\n'
        'end\n';

    testWidgets('a follow-up reworks the answer, not the document again',
        (tester) async {
      install(
        'com.example.demo',
        panels: [
          {'id': 'write', 'title': 'Write', 'icon': 'list'},
        ],
        permissions: const ['ui.sidebar', 'document.read', 'document.write'],
        script: echo,
      );
      final container = await pumpWithContainer(tester);

      // First round, through the automation entry so the question is answered.
      await container
          .read(mcpProvider.notifier)
          .openPluginPanel!('com.example.demo', 'write', 'long');
      await settlePlugin(tester);
      expect(find.text('long of DOC'), findsOneWidget);

      // Second round: type into the box the drawer now offers.
      await tester.enterText(
          find.byKey(const Key('plugin-drawer-follow')), 'shorter');
      await tester.tap(find.byKey(const Key('plugin-drawer-send')));
      await settlePlugin(tester);

      expect(
        find.text('shorter of long of DOC'),
        findsOneWidget,
        reason: '追加的要求应当作用在上一次的结果上',
      );
      expect(
        find.text('long of DOC'),
        findsOneWidget,
        reason: '前一稿该留着，否则看不出这次改了什么',
      );
    });

    testWidgets('nothing to follow up on before there is an answer',
        (tester) async {
      install(
        'com.example.demo',
        panels: [
          {'id': 'write', 'title': 'Write', 'icon': 'list'},
        ],
        script: 'function on_command(ctx)\n'
            '  return { ask = "what?" }\n'
            'end\n',
      );
      await pump(tester);

      await tester.tap(find.byIcon(Icons.list));
      await settlePlugin(tester);

      // Still asking the first question: there is nothing to rework yet.
      expect(find.byKey(const Key('plugin-drawer-follow')), findsNothing);
    });

    testWidgets('what a refinement would replace is still the original',
        (tester) async {
      // The first answer replaces the paragraph it was made from. A shorter
      // second draft replaces the same paragraph — not the draft it came from,
      // which is not in the document at all.
      install(
        'com.example.demo',
        panels: [
          {'id': 'write', 'title': 'Write', 'icon': 'list'},
        ],
        permissions: const ['ui.sidebar', 'document.read', 'document.write'],
        script: echo,
      );
      final container = await pumpWithContainer(tester);

      await container
          .read(mcpProvider.notifier)
          .openPluginPanel!('com.example.demo', 'write', 'long');
      await settlePlugin(tester);
      await tester.enterText(
          find.byKey(const Key('plugin-drawer-follow')), 'shorter');
      await tester.tap(find.byKey(const Key('plugin-drawer-send')));
      await settlePlugin(tester);

      // Apply is still offered — it would have gone if `replaces` had been
      // overwritten with text that is nowhere in the document.
      expect(find.byKey(const Key('plugin-drawer-apply')), findsOneWidget);
    });
  });

  testWidgets('a panel that never asks does not offer a box that goes nowhere',
      (tester) async {
    // The follow-up reaches the plugin as the answer to the question it asks.
    // A command that asks nothing — proofreading, in the official plugin —
    // never reads one, so a box saying "ask for a change" would take the
    // reader's words and drop them.
    install(
      'com.example.demo',
      panels: [
        {'id': 'check', 'title': 'Check', 'icon': 'list'},
      ],
      script: 'function on_command(ctx)\n'
          '  return { pane = "CHECKED", title = "Check" }\n'
          'end\n',
    );
    await pump(tester);

    await tester.tap(find.byIcon(Icons.list));
    await settlePlugin(tester);

    expect(find.text('CHECKED'), findsOneWidget);
    expect(
      find.byKey(const Key('plugin-drawer-follow')),
      findsNothing,
      reason: '这个命令不问问题，追加的要求没有地方可去，就不该摆出输入框',
    );
  });

  testWidgets('pressing that button puts the rewrite in the document',
      (tester) async {
    // The tests above check the button is drawn. Whether it does anything was
    // never checked — and BUG-369 was exactly a button-shaped gap, so "it is
    // there" is not the assertion that matters.
    install(
      'com.example.demo',
      panels: [
        {'id': 'rewrite', 'title': 'Rewrite', 'icon': 'list'},
      ],
      permissions: const ['ui.sidebar', 'document.read', 'document.write'],
      script: 'function on_command(ctx)\n'
          '  return { pane = "NEW", title = "Rewrite",\n'
          '           apply = true, replaces = "OLD" }\n'
          'end\n',
    );
    final container = await pumpWithContainer(tester);
    container.read(tabProvider.notifier).addTab(
      TabInfo(id: 'doc', fileName: 'a.md', content: 'before OLD after'),
    );
    container.read(tabProvider.notifier).setActiveTab('doc');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.list));
    await settlePlugin(tester);
    await tester.tap(find.byKey(const Key('plugin-drawer-apply')));
    await tester.pumpAndSettle();

    expect(
      container.read(tabProvider).tabs.single.content,
      'before NEW after',
      reason: '按了「采用」，文档没有变',
    );
    expect(
      find.byKey(const Key('plugin-drawer-apply')),
      findsNothing,
      reason: '采用之后抽屉该收起来，否则会被采用第二次',
    );
  });

  testWidgets('the undo entry lands on the tab that was changed', (tester) async {
    // Only the source editor ever says which tab the undo history belongs to,
    // and in preview mode — which is where this drawer is used — there is no
    // source editor. So the entry went onto whichever tab was named last: a
    // different document, or none. The change could then not be taken back,
    // and undo in *that* tab would have written this document's text into it.
    install(
      'com.example.demo',
      panels: [
        {'id': 'rewrite', 'title': 'Rewrite', 'icon': 'list'},
      ],
      permissions: const ['ui.sidebar', 'document.read', 'document.write'],
      script: 'function on_command(ctx)\n'
          '  return { pane = "NEW", title = "Rewrite",\n'
          '           apply = true, replaces = "OLD" }\n'
          'end\n',
    );
    final container = await pumpWithContainer(tester);
    container.read(tabProvider.notifier).addTab(
      TabInfo(id: 'doc', fileName: 'a.md', content: 'before OLD after'),
    );
    container.read(tabProvider.notifier).setActiveTab('doc');

    final editor = container.read(editorProvider.notifier);
    // An earlier state of this document, as a source editor would have left
    // behind. Deliberately not the text the rewrite replaces: pushing the same
    // text twice is skipped, and the check below would then see nothing.
    editor.setHistoryTab('doc');
    editor.pushHistory('an earlier draft');
    // And then the reader was last in a source editor on some other tab.
    editor.setHistoryTab('other');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.list));
    await settlePlugin(tester);
    await tester.tap(find.byKey(const Key('plugin-drawer-apply')));
    await tester.pumpAndSettle();

    editor.setHistoryTab('doc');
    expect(
      container.read(editorProvider).canUndo,
      isTrue,
      reason: '插件改了这个标签，撤销记录却记到了别的标签上',
    );

    editor.setHistoryTab('other');
    expect(
      container.read(editorProvider).canUndo,
      isFalse,
      reason: '别的标签不该多出一条它自己没有做过的改动',
    );
  });
}
