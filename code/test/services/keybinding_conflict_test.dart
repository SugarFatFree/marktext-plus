import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/keybinding_service.dart';

/// Two commands on one combination.
///
/// The lookup takes whichever comes first, so the other simply never fires —
/// no error, and the settings screen showing both as bound. Someone changes a
/// shortcut, the dialog says OK, and either the new one does nothing or a
/// command they did not touch stops working.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = KeybindingService();
  late Directory dir;

  setUp(() {
    // A singleton that writes to the application support directory: point it
    // at a temporary one, and reset it, since these tests reassign keys and
    // would otherwise leak into each other.
    dir = Directory.systemTemp.createTempSync('keybinding_conflict_');
    service.configDirectory = dir.path;
    service.resetToDefaults();
  });
  tearDown(() async {
    await service.pendingWrite;
    service.resetToDefaults();
    await service.pendingWrite;
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('a combination in use names the command using it', () {
    // Bold is Ctrl+B by default.
    expect(service.actionUsing('Ctrl+B'), 'bold');
  });

  test('the command being edited does not count as a conflict with itself',
      () {
    expect(service.actionUsing('Ctrl+B', excluding: 'bold'), isNull);
  });

  test('the same keys written differently are the same keys', () {
    // A reader pressing shift first should not be told a combination is free
    // when it is not.
    expect(service.actionUsing('Shift+Ctrl+K'),
        service.actionUsing('Ctrl+Shift+K'));
  });

  test('a free combination conflicts with nothing', () {
    expect(service.actionUsing('Ctrl+Alt+Shift+F9'), isNull);
  });

  test('assigning taken keys takes them off the other command', () {
    expect(service.getKeybinding('bold'), 'Ctrl+B');
    service.setKeybinding('italic', 'Ctrl+B');

    expect(service.getKeybinding('italic'), 'Ctrl+B');
    expect(service.getKeybinding('bold'), '',
        reason: '两个动作共用一个组合，其中一个就会永远不触发');
  });

  test('after taking them over, exactly one command has them', () {
    service.setKeybinding('italic', 'Ctrl+B');
    final holders = service.keybindings.entries
        .where((e) => e.value == 'Ctrl+B')
        .map((e) => e.key)
        .toList();
    expect(holders, ['italic']);
  });

  test('the command left without keys has no activator', () {
    service.setKeybinding('italic', 'Ctrl+B');
    expect(service.activatorFor('bold', isMacOS: false), isNull,
        reason: '没有绑定时不该给出快捷键，菜单会显示一个按不出来的组合');
  });

  test('assigning a free combination disturbs nothing', () {
    final before = Map<String, String>.from(service.keybindings);
    service.setKeybinding('bold', 'Ctrl+Alt+Shift+F9');
    final after = service.keybindings;
    for (final action in before.keys) {
      if (action == 'bold') continue;
      expect(after[action], before[action], reason: action);
    }
  });

  test('no two commands share a combination after any reassignment', () {
    // The property that matters, checked over the whole table rather than the
    // one pair the test set up.
    service.setKeybinding('italic', 'Ctrl+B');
    service.setKeybinding('bold', 'Ctrl+I');
    service.setKeybinding('find', 'Ctrl+B');

    final seen = <String, String>{};
    final clashes = <String>[];
    service.keybindings.forEach((action, keys) {
      if (keys.isEmpty) return;
      final previous = seen[keys];
      if (previous != null) clashes.add('$keys: $previous / $action');
      seen[keys] = action;
    });
    expect(clashes, isEmpty);
  });
}
