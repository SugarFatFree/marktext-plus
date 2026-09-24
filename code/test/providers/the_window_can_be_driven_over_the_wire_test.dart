import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/mcp_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/services/editor_window.dart';
import 'package:marktext_plus/services/mcp_tools.dart';
import 'package:marktext_plus/services/window_placement.dart';

/// The window, driven from outside.
///
/// Asked for from the start — "mcp 还要支持控制客户端的窗口大小、最大化、最小化"
/// — and never built, so the one part of this editor a reader spends all day
/// looking at was the one part automation could not touch. It is also what
/// stands between a machine and the manual test plan: two of its checks are
/// "drag the window from 1200 to 700 to 400 and look for stripes", which
/// needs a hand on the window and an eye on it, and `screenshot` already had
/// the eye.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('mcp_window'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  ProviderContainer boot(EditorWindow window) {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(),
          ),
        ),
        mcpProvider.overrideWith((ref) => McpController(ref, window: window)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<McpOutcome> ask(
    ProviderContainer container,
    Map<String, Object?> arguments,
  ) =>
      container.read(mcpProvider.notifier).performAction('set_window', arguments);

  test('asked for nothing at all it says what it takes', () async {
    final window = _FakeWindow();
    final outcome = await ask(boot(window), const {});

    expect(outcome.ok, isFalse);
    expect(outcome.said, contains('state'));
    expect(outcome.said, contains('width'));
    expect(window.applied, isEmpty, reason: '什么都没说就什么都别做');
    expect(window.resized, isNull);
  });

  group('a named state', () {
    for (final state in WindowState.values) {
      test('${state.name} is applied, and the answer is what it became',
          () async {
        final window = _FakeWindow();
        final outcome = await ask(boot(window), {'state': state.name});

        expect(outcome.ok, isTrue, reason: outcome.said);
        expect(window.applied, [state]);
        expect(outcome.said, contains(state.name));
      });
    }

    test('one it does not know is refused, and the states are named', () async {
      final window = _FakeWindow();
      final outcome = await ask(boot(window), const {'state': 'hologram'});

      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('hologram'));
      for (final state in WindowState.values) {
        expect(outcome.said, contains(state.name));
      }
      expect(window.applied, isEmpty);
    });
  });

  group('a size', () {
    test('is set, and the answer reports what the window became', () async {
      // Not what was asked for. A window manager clamps to the work area and
      // to the window's own minimum, so the requested size and the resulting
      // one are different numbers — and this interface has a rule about
      // which of the two it is allowed to say.
      final window = _FakeWindow(clampTo: const Size(1024, 768));
      final outcome = await ask(boot(window), {'width': 4000, 'height': 3000});

      expect(outcome.ok, isTrue, reason: outcome.said);
      expect(window.resized, const Size(4000, 3000));
      expect(outcome.said, contains('1024'));
      expect(outcome.said, contains('768'));
      expect(outcome.said, isNot(contains('4000')),
          reason: '报出来的必须是量到的，不是要求的');
    });

    test('smaller than a window can usefully be is refused', () async {
      // The same floor the session restore uses, and for the reason written
      // there: below it the title bar is not reliably grabbable, and a reader
      // handed a window they cannot grab has no way back.
      final window = _FakeWindow();
      final outcome = await ask(boot(window), {'width': 100, 'height': 100});

      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('${WindowPlacement.minimumSize.width.round()}'));
      expect(window.resized, isNull, reason: '拒绝之前不许先改');
    });

    test('half a size is not a size', () async {
      final window = _FakeWindow();
      expect((await ask(boot(window), {'width': 900})).ok, isFalse);
      expect((await ask(boot(window), {'height': 600})).ok, isFalse);
      expect(window.resized, isNull);
    });
  });

  test('a state and a size together do both, in that order', () async {
    // Maximising and then resizing would leave the window the size it was:
    // the resize has to be the last word, and the answer has to describe the
    // window that resulted rather than either instruction.
    final window = _FakeWindow();
    final outcome = await ask(
      boot(window),
      {'state': 'normal', 'width': 1200, 'height': 800},
    );

    expect(outcome.ok, isTrue, reason: outcome.said);
    expect(window.applied, [WindowState.normal]);
    expect(window.resized, const Size(1200, 800));
    expect(outcome.said, contains('1200'));
  });
}

/// A window that records what it was told and answers what it holds.
class _FakeWindow implements EditorWindow {
  _FakeWindow({this.clampTo});

  /// What the platform would clamp any requested size to, when it would.
  final Size? clampTo;

  final List<WindowState> applied = [];
  Size? resized;
  WindowState _state = WindowState.normal;
  Size _size = const Size(800, 600);

  @override
  Future<void> apply(WindowState state) async {
    applied.add(state);
    _state = state;
  }

  @override
  Future<void> resize(Size size) async {
    resized = size;
    _size = clampTo ?? size;
    _state = WindowState.normal;
  }

  @override
  Future<WindowReading> read() async =>
      WindowReading(state: _state, size: _size, position: position);

  Offset position = Offset.zero;
}
