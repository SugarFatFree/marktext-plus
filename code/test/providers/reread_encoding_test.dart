import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/file_encoding.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';

/// Saying what a file really is when the guess got it wrong.
///
/// Detection is a guess: the share of double-byte pairs tells GBK from
/// Latin-1 well but not perfectly, and nothing tells two single-byte
/// encodings apart at all. Without a way to correct it the reader could see
/// that a document had opened as mojibake and do nothing about it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late ProviderContainer container;

  setUp(() {
    root = Directory.systemTemp.createTempSync('reread');
    container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: root.path),
            AppConfig(autoSave: false),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  /// `Grüße` in Latin-1, which is short enough that the pair test rejects it.
  final latin1Bytes = <int>[0x47, 0x72, 0xFC, 0xDF, 0x65, 0x0A];

  /// A short GBK document — long enough that the guess has something to go on.
  final gbkBytes = <int>[
    0x23, 0x20, 0xB1, 0xEA, 0xCC, 0xE2, 0x0A, 0x0A, 0xD5, 0xE2, 0xCA, 0xC7,
    0xD2, 0xBB, 0xB6, 0xCE, 0xD6, 0xD0, 0xCE, 0xC4, 0xA1, 0xA3, 0x0A,
  ];

  /// Opens a file the way the UI does: detect, then hand the text to a tab.
  TabInfo open(List<int> bytes) {
    final file = File('${root.path}/note.md')..writeAsBytesSync(bytes);
    final (text, encoding) = FileEncoding.decode(Uint8List.fromList(bytes));
    container.read(tabProvider.notifier).addTab(
          TabInfo(
            id: 'note',
            filePath: file.path,
            fileName: 'note.md',
            content: text,
            encoding: encoding,
          ),
        );
    return container.read(tabProvider).tabs.single;
  }

  test('a file can be read again as another encoding', () async {
    final tab = open(gbkBytes);
    expect(tab.encoding, FileEncoding.gbk);

    final ok = await container
        .read(tabProvider.notifier)
        .rereadAs(tab.id, FileEncoding.latin1Encoding);

    expect(ok, isTrue);
    final after = container.read(tabProvider).tabs.single;
    expect(after.encoding, FileEncoding.latin1Encoding);
    expect(after.content, isNot(contains('标题')),
        reason: '按 Latin-1 重读之后不该还是中文');
  });

  test('and back again, from the file rather than from the screen', () async {
    // The text in memory has already been through one decoder; running it
    // through a second cannot recover what the first one lost.
    final tab = open(gbkBytes);
    final tabs = container.read(tabProvider.notifier);

    await tabs.rereadAs(tab.id, FileEncoding.latin1Encoding);
    await tabs.rereadAs(tab.id, FileEncoding.gbk);

    expect(container.read(tabProvider).tabs.single.content, contains('标题'));
  });

  test('a Latin-1 file is left as Latin-1 by the guess', () {
    expect(open(latin1Bytes).encoding, FileEncoding.latin1Encoding);
  });

  test('a document with unsaved edits is not thrown away', () async {
    final tab = open(gbkBytes);
    final tabs = container.read(tabProvider.notifier);
    tabs.updateContent(tab.id, 'work in progress');

    final ok = await tabs.rereadAs(tab.id, FileEncoding.latin1Encoding);

    expect(ok, isFalse);
    expect(container.read(tabProvider).tabs.single.content, 'work in progress');
  });

  test('a document with no file behind it is left alone', () async {
    final tabs = container.read(tabProvider.notifier);
    tabs.addTab(TabInfo(
      id: 'untitled',
      filePath: null,
      fileName: 'Untitled',
      content: 'typed',
    ));

    expect(await tabs.rereadAs('untitled', FileEncoding.gbk), isFalse);
  });
}
