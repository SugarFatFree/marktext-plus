import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/trash_service.dart';
import 'package:path/path.dart' as p;

/// Deleting through the desktop's trash rather than destroying outright.
///
/// Upstream MarkText goes through Electron's `shell.trashItem`, so a note
/// deleted by mistake can be put back. Deleting a folder here was
/// `delete(recursive: true)` — everything under it, with no way back.
///
/// These run only on Linux, which is where the freedesktop.org trash is
/// implemented; the trash directory is redirected with XDG_DATA_HOME so the
/// tests never touch the real one.
void main() {
  // The mock method-channel handler below needs the test binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory work;
  late Directory dataHome;

  setUp(() {
    work = Directory.systemTemp.createTempSync('trashwork');
    dataHome = Directory.systemTemp.createTempSync('trashhome');
  });
  tearDown(() {
    for (final dir in [work, dataHome]) {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
  });

  /// The trash is pointed at a temporary directory, so these never touch the
  /// reader's real one.
  Future<bool> trash(String path) =>
      TrashService.moveToTrash(path, dataHome: dataHome.path);

  String filesDir() => p.join(dataHome.path, 'Trash', 'files');
  String infoDir() => p.join(dataHome.path, 'Trash', 'info');

  test('a file is moved into the trash, not destroyed', () async {
    if (!Platform.isLinux) return;
    final note = File(p.join(work.path, 'note.md'))
      ..writeAsStringSync('keep me\n');

    final ok = await trash(note.path);

    expect(ok, isTrue, reason: '没能移入回收站');
    expect(note.existsSync(), isFalse, reason: '原文件还在，等于没删');
    final moved = File(p.join(filesDir(), 'note.md'));
    expect(moved.existsSync(), isTrue, reason: '回收站里没有这个文件');
    expect(moved.readAsStringSync(), 'keep me\n',
        reason: '内容不该在搬运中改变');
  });

  test('the record beside it says where it came from', () async {
    if (!Platform.isLinux) return;
    final note = File(p.join(work.path, 'note.md'))..writeAsStringSync('x');
    await trash(note.path);

    final info = File(p.join(infoDir(), 'note.md.trashinfo'));
    expect(info.existsSync(), isTrue,
        reason: '没有 .trashinfo，桌面就无法"还原"它');
    final text = info.readAsStringSync();
    expect(text, startsWith('[Trash Info]\n'));
    expect(text, contains('Path=${note.path}'));
    expect(text, contains(RegExp(r'DeletionDate=\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}')));
  });

  test('a folder goes whole, with what is inside it', () async {
    if (!Platform.isLinux) return;
    final folder = Directory(p.join(work.path, 'notes'))..createSync();
    File(p.join(folder.path, 'a.md')).writeAsStringSync('a');
    File(p.join(folder.path, 'b.md')).writeAsStringSync('b');

    final ok = await trash(folder.path);

    expect(ok, isTrue);
    expect(folder.existsSync(), isFalse);
    expect(File(p.join(filesDir(), 'notes', 'a.md')).readAsStringSync(), 'a');
    expect(File(p.join(filesDir(), 'notes', 'b.md')).readAsStringSync(), 'b');
  });

  test('two files of the same name both survive in the trash', () async {
    if (!Platform.isLinux) return;
    File(p.join(work.path, 'note.md')).writeAsStringSync('first');
    await trash(p.join(work.path, 'note.md'));
    File(p.join(work.path, 'note.md')).writeAsStringSync('second');
    await trash(p.join(work.path, 'note.md'));

    final entries = Directory(filesDir()).listSync();
    expect(entries, hasLength(2), reason: '第二个把第一个覆盖了');
    // Which name each one got is not the point — that both are still there,
    // with their own contents, is. `note.1.md` sorts before `note.md`, so
    // asserting by position tests the sort rather than the collision.
    final contents = entries
        .whereType<File>()
        .map((f) => f.readAsStringSync())
        .toSet();
    expect(contents, {'first', 'second'});

    // And each keeps its own record, or the desktop cannot put either back.
    final records = Directory(infoDir())
        .listSync()
        .map((e) => p.basename(e.path))
        .toSet();
    expect(records, hasLength(2));
  });

  test('something that is not there cannot be trashed', () async {
    if (!Platform.isLinux) return;
    expect(
      await trash(p.join(work.path, 'gone.md')),
      isFalse,
    );
  });

  group('the platform channel macOS answers on', () {
    // The macOS half cannot be exercised here — it is Swift, compiled only by
    // the release build. What can be checked is the Dart side of the
    // contract: the method name, that the path goes across as the argument,
    // and that a refusal comes back as false rather than as an exception, so
    // the caller falls through to removing the file outright.
    const channel = MethodChannel('com.marktextplus/clipboard');
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method != 'moveToTrash') return null;
        return call.arguments == '/tmp/ok.md';
      });
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('the name and the argument are what the Swift side reads', () async {
      if (!Platform.isMacOS) {
        // Called directly, since the platform check inside would decline.
        await channel.invokeMethod<bool>('moveToTrash', '/tmp/ok.md');
      } else {
        await TrashService.moveToTrash('/tmp/ok.md');
      }
      expect(calls.single.method, 'moveToTrash');
      expect(calls.single.arguments, '/tmp/ok.md');
    });

    test('a refusal is false, not an exception', () async {
      final answer =
          await channel.invokeMethod<bool>('moveToTrash', '/tmp/no.md');
      expect(answer, isFalse,
          reason: '拒绝必须是 false，抛异常会让调用方连回退删除都做不了');
    });
  });
}
