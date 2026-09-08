import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/widgets/window_actions.dart';

/// Each window action does the thing its name promises.
///
/// `window_action_coverage_test` compares lists: every bindable name reaches
/// something in [WindowActions], nothing in [WindowActions] is unbindable,
/// every one has a label. That is the guard BUG-330 earned — eleven shortcuts
/// were drawn in the menus, could be rebound, and answered no key.
///
/// Ask what damage leaves it green and the answer is the same defect one
/// level down: `WindowAction('zoomIn', (_, __) {})` is in the list, is
/// bindable, has a label, and does nothing. So does `WindowAction('zoomOut',
/// (_, ref) => _zoomBy(ref, 2))`, which zooms the wrong way. Nothing ran any
/// of these.
///
/// Ten of the twenty-five cannot be staged from a test — they open a file
/// picker, start another process, or close the window. They are named in
/// [cannotBeStaged] with the reason, and a check at the bottom insists the
/// two lists together account for every action, so a new one cannot arrive
/// untested by saying nothing.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('win_actions'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  /// The ones whose effect leaves this process, and why.
  const cannotBeStaged = <String, String>{
    'save': '打开保存对话框或写盘',
    'open': '打开文件选择器',
    'closeTab': '要有一个活动标签，且可能弹出确认框',
    'newWindow': '启动另一个进程',
    'settings': '往 navigatorKey 上 push，测试里那个 key 没有 state',
    'quit': '关闭窗口',
    'print': '打开系统打印对话框',
    'exportPdf': '打开保存对话框',
    'fullScreen': '要求 window_manager 改变真实窗口',
    'commandPalette': '弹出对话框——由 command_palette_test 单独覆盖',
  };

  /// Runs [name] and hands back the container to look at afterwards.
  Future<ProviderContainer> run(
    WidgetTester tester,
    String name, {
    AppConfig? from,
  }) async {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            from ?? AppConfig(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    late BuildContext context;
    late WidgetRef ref;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (c, r, _) {
              context = c;
              ref = r;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      ),
    );

    final action = WindowActions.byName(name);
    expect(action, isNotNull, reason: '$name 不在 WindowActions 里');
    action!.run(context, ref);
    await tester.pumpAndSettle();
    return container;
  }

  // What this file exercises, declared rather than accumulated as the tests
  // run: a set filled by the test bodies is empty when one test is run on its
  // own, and the accounting below would then fail for a reason that has
  // nothing to do with the code. The groups iterate these same lists, so
  // there is still only one place to add an action.
  const viewModes = [
    ('sourceMode', EditMode.source),
    ('previewMode', EditMode.preview),
    ('splitMode', EditMode.split),
  ];
  final toggles = <(String, bool Function(AppConfig))>[
    ('toggleTabBar', (c) => c.tabBarVisible),
    ('toggleSidebar', (c) => c.sideBarVisible),
    ('focusMode', (c) => c.focusMode),
    ('typewriterMode', (c) => c.typewriterMode),
  ];
  const zoomActions = ['zoomIn', 'zoomOut', 'resetZoom'];
  const findBarActions = ['find', 'replace'];
  const stepActions = [('findNext', true), ('findPrevious', false)];
  const otherActions = ['reloadImages'];

  final exercised = <String>{
    for (final (name, _) in viewModes) name,
    for (final (name, _) in toggles) name,
    ...zoomActions,
    ...findBarActions,
    for (final (name, _) in stepActions) name,
    ...otherActions,
  };

  group('the view modes', () {
    for (final (name, mode) in viewModes) {
      testWidgets('$name 切到 ${mode.name}', (tester) async {
        // Started from a different mode on purpose: an action that does
        // nothing would pass if the editor was already in the mode it names.
        final other = mode == EditMode.source
            ? EditMode.preview
            : EditMode.source;
        final container = await run(
          tester,
          name,
          from: AppConfig(editMode: other),
        );
        expect(container.read(settingsProvider).editMode, mode);
      });
    }
  });

  group('the toggles', () {
    for (final (name, read) in toggles) {
      testWidgets('$name 翻转它管的那一项', (tester) async {
        final before = AppConfig();
        final was = read(before);
        final container = await run(tester, name, from: before);
        expect(
          read(container.read(settingsProvider)),
          !was,
          reason: '$name 没有改变它自己那一项',
        );
      });
    }
  });

  group('zoom', () {
    testWidgets('zoomIn 放大，zoomOut 缩小，方向不能互换', (tester) async {
      final inward = await run(
        tester,
        'zoomIn',
        from: AppConfig(fontSize: 16),
      );
      expect(inward.read(settingsProvider).fontSize, greaterThan(16));

      final outward = await run(
        tester,
        'zoomOut',
        from: AppConfig(fontSize: 16),
      );
      expect(outward.read(settingsProvider).fontSize, lessThan(16));
    });

    testWidgets('resetZoom 回到默认字号', (tester) async {
      final container = await run(
        tester,
        'resetZoom',
        from: AppConfig(fontSize: 28),
      );
      expect(
        container.read(settingsProvider).fontSize,
        WindowActions.defaultZoom,
      );
    });
  });

  group('the find bar', () {
    for (final name in findBarActions) {
      testWidgets('$name 打开查找栏', (tester) async {
        final container = await run(tester, name);
        expect(container.read(editorProvider).showFindReplace, isTrue);
      });
    }

    for (final (name, forward) in stepActions) {
      testWidgets('$name 提出一次步进请求，方向是 $forward', (tester) async {
        final container = await run(tester, name);
        final state = container.read(editorProvider);
        expect(state.findStepRequest, greaterThan(0), reason: '没有提出请求');
        expect(state.findStepForward, forward, reason: '方向反了');
      });
    }
  });

  testWidgets('reloadImages 让图片作废一次', (tester) async {
    final container = await run(tester, 'reloadImages');
    expect(
      container.read(editorProvider).imageRevision,
      greaterThan(0),
      reason: 'F5 曾经完全不做事，这一条是那件事的守卫',
    );
  });

  test('every action is either exercised above or named as unstageable', () {
    final all = WindowActions.all.map((a) => a.name).toSet();
    final accounted = exercised.union(cannotBeStaged.keys.toSet());

    expect(
      all.difference(accounted),
      isEmpty,
      reason: '这些动作既没被跑过，也没说明为什么跑不了——它们可以什么都不做而无人发现',
    );
    expect(
      accounted.difference(all),
      isEmpty,
      reason: '这里提到了 WindowActions 里没有的名字，说明清单已经过期',
    );
  });
}
