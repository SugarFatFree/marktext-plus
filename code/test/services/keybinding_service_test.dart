import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/keybinding_service.dart';

void main() {
  // actionForEvent reads the held modifiers from HardwareKeyboard, whose
  // instance getter needs the services binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = KeybindingService();
  late Directory dir;

  setUp(() {
    // The service is a singleton that persists to the application support
    // directory. Point it at a temporary one so running the tests does not
    // rewrite the developer's own keybindings.
    dir = Directory.systemTemp.createTempSync('keybinding_test_');
    service.configDirectory = dir.path;
  });

  tearDown(() async {
    service.resetToDefaults();
    // Let the write finish before the directory goes, or it lands in a
    // recreated one and litters the temp folder.
    await service.pendingWrite;
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('activatorFor', () {
    test('describes a binding for the menu to display', () {
      final bold = service.activatorFor('bold', isMacOS: false)!;
      expect(bold.trigger, LogicalKeyboardKey.keyB);
      expect(bold.control, isTrue);
      expect(bold.shift, isFalse);
    });

    test('Ctrl means Command on macOS', () {
      final bold = service.activatorFor('bold', isMacOS: true)!;
      expect(bold.meta, isTrue);
      expect(bold.control, isFalse);
    });

    test('an action with no binding has no shortcut', () {
      expect(service.activatorFor('nosuchaction', isMacOS: false), isNull);
    });

    test('the defaults added for headings 4 to 6 and math are real', () {
      // These were listed as customisable in settings with no default, so they
      // showed as blank and nothing could trigger them.
      for (final action in [
        'heading4',
        'heading5',
        'heading6',
        'inlineMath',
        'mathBlock',
      ]) {
        expect(service.activatorFor(action, isMacOS: false), isNotNull,
            reason: '$action should have a default binding');
      }
    });
  });

  group('actionForEvent', () {
    // The modifiers come from HardwareKeyboard, which a unit test cannot press,
    // so this covers the paths that do not depend on them. The full matching
    // table is exercised against the real service in the notes for BUG-060.
    KeyEvent event(LogicalKeyboardKey key) => KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyA,
          logicalKey: key,
          timeStamp: Duration.zero,
        );

    test('a keypress with no modifier held is never a shortcut', () {
      expect(
        service.actionForEvent(event(LogicalKeyboardKey.keyB), isMacOS: false),
        isNull,
      );
    });

    test('a key-up event is not a shortcut', () {
      expect(
        service.actionForEvent(
          const KeyUpEvent(
            physicalKey: PhysicalKeyboardKey.keyA,
            logicalKey: LogicalKeyboardKey.keyB,
            timeStamp: Duration.zero,
          ),
          isMacOS: false,
        ),
        isNull,
      );
    });
  });

  group('rebinding', () {
    test('changing a binding changes what the menu shows', () {
      service.setKeybinding('bold', 'Ctrl+Shift+B');

      final bold = service.activatorFor('bold', isMacOS: false)!;
      expect(bold.shift, isTrue);
    });

    test('resetting restores the defaults', () {
      service.setKeybinding('bold', 'Ctrl+Shift+B');
      service.resetToDefaults();

      expect(service.getKeybinding('bold'), 'Ctrl+B');
    });

    test('a binding that cannot be parsed yields no shortcut', () {
      service.setKeybinding('bold', 'Ctrl+NotAKey');
      expect(service.activatorFor('bold', isMacOS: false), isNull);

      service.setKeybinding('bold', '');
      expect(service.activatorFor('bold', isMacOS: false), isNull);
    });
  });

  group('the default table', () {
    test('no two actions share a combination', () {
      final seen = <String, String>{};
      final clashes = <String>[];
      KeybindingService.defaultKeybindings.forEach((action, keys) {
        final owner = seen[keys];
        if (owner != null) {
          clashes.add('$keys is bound to both $owner and $action');
        } else {
          seen[keys] = action;
        }
      });

      expect(clashes, isEmpty, reason: clashes.join('; '));
    });

    test('function keys are bindable on their own', () {
      // Ordinary letters must not be treated as shortcuts without a modifier,
      // but F3 types nothing, so upstream binds Find Next to it directly.
      final findNext = service.activatorFor('findNext', isMacOS: false)!;
      expect(findNext.trigger, LogicalKeyboardKey.f3);
      expect(findNext.control, isFalse);
      expect(findNext.shift, isFalse);

      final findPrevious =
          service.activatorFor('findPrevious', isMacOS: false)!;
      expect(findPrevious.trigger, LogicalKeyboardKey.f3);
      expect(findPrevious.shift, isTrue);
    });

    test('every binding parses', () {
      for (final entry in KeybindingService.defaultKeybindings.entries) {
        expect(service.activatorFor(entry.key, isMacOS: false), isNotNull,
            reason: '${entry.key} = ${entry.value} does not parse');
      }
    });
  });
}
