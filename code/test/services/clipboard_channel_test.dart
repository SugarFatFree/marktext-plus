import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/clipboard_service.dart';

/// Rich copy on the two platforms that had none.
///
/// Copying a heading out of the preview and pasting it into a word processor
/// kept the heading on Windows and nowhere else: the HTML flavour was written
/// through a Win32 call, and macOS and Linux fell straight back to plain text.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the channel has one name, spelled the same in three languages', () {
    // Dart asks on it, the GTK runner answers on it, and so does the macOS
    // app delegate. A typo in any one of them is a copy that silently loses
    // its formatting on that platform alone.
    const name = 'com.marktextplus/clipboard';
    expect(File('lib/services/clipboard_service.dart').readAsStringSync(),
        contains(name));
    expect(File('linux/runner/my_application.cc').readAsStringSync(),
        contains(name));
    expect(File('macos/Runner/AppDelegate.swift').readAsStringSync(),
        contains(name));
  });

  test('both flavours are sent, under the names the runners read', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.marktextplus/clipboard'),
      (call) async {
        calls.add(call);
        return true;
      },
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('com.marktextplus/clipboard'), null);
    });

    // Only exercised where a channel exists; Windows goes through FFI.
    if (!Platform.isLinux && !Platform.isMacOS) return;

    await ClipboardService.copyWithHtml('Title', '<h1>Title</h1>');

    expect(calls, hasLength(1));
    expect(calls.single.method, 'copyWithHtml');
    final args = calls.single.arguments as Map;
    expect(args['text'], 'Title');
    expect(args['html'], '<h1>Title</h1>');
  });

  test('the HTML flavour is asked for by name', () async {
    if (!Platform.isLinux && !Platform.isMacOS) return;

    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.marktextplus/clipboard'),
      (call) async {
        calls.add(call);
        return '<p>正文</p>';
      },
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('com.marktextplus/clipboard'), null);
    });

    expect(await ClipboardService.readHtml(), '<p>正文</p>');
    expect(calls.single.method, 'readHtml');
  });

  test('a clipboard with no HTML on it reads as nothing', () async {
    if (!Platform.isLinux && !Platform.isMacOS) return;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.marktextplus/clipboard'),
      (call) async => null,
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('com.marktextplus/clipboard'), null);
    });

    // Null, not an empty string: text copied from a text editor has no HTML
    // flavour at all, and that is the ordinary case.
    expect(await ClipboardService.readHtml(), isNull);
  });

  test('a runner without the method is not an error', () async {
    if (!Platform.isLinux && !Platform.isMacOS) return;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.marktextplus/clipboard'),
      (call) async => throw MissingPluginException(),
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('com.marktextplus/clipboard'), null);
    });

    expect(await ClipboardService.readHtml(), isNull);
  });

  test('both runners answer readHtml, not only one of them', () {
    // Written twice in two languages; a paste that keeps its formatting on
    // Linux and loses it on macOS is the kind of difference nobody reports.
    expect(File('linux/runner/my_application.cc').readAsStringSync(),
        contains('readHtml'));
    expect(File('macos/Runner/AppDelegate.swift').readAsStringSync(),
        contains('readHtml'));
  });

  test('a runner that cannot take it still leaves the text behind', () async {
    if (!Platform.isLinux && !Platform.isMacOS) return;

    final plain = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.marktextplus/clipboard'),
      (call) async => throw PlatformException(code: 'unimplemented'),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') plain.add(call);
        return null;
      },
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockMethodCallHandler(
            const MethodChannel('com.marktextplus/clipboard'), null)
        ..setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await ClipboardService.copyWithHtml('Title', '<h1>Title</h1>');

    expect(plain, hasLength(1),
        reason: '富文本写不进去时，连纯文本都没留下——复制变成了什么都没发生');
    expect((plain.single.arguments as Map)['text'], 'Title');
  });
}
