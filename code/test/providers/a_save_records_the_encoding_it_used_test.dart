import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/file_encoding.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/services/file_service.dart';

/// What a tab records after it has been written to disk.
///
/// `saveDocument` answers with the encoding it actually used, which is not
/// always the one it was asked for: a character the encoding cannot carry makes
/// it write UTF-8 instead, and its own doc comment says the caller has to take
/// that on "so the status bar keeps telling the truth". Auto-save did. Ctrl+S,
/// Save As and the overwrite a reader chooses out of a conflict all threw the
/// answer away — so the status bar went on naming Latin-1 for a file written as
/// UTF-8, and the "read it again as…" menu beside it would then have decoded
/// that file as Latin-1 and handed the reader mojibake.
///
/// The other half is a property rather than a bug that was there: a stat that
/// fails after a write must leave the baseline alone, because a null baseline is
/// not a conflict but *no information* and would turn the check off for that tab
/// from then on. Two methods recorded "this tab has been saved" and *both* held
/// that line — one by its own `??`, the other through `TabInfo.copyWith`, which
/// reads a null as "leave it alone". Mutating either half came back green; only
/// removing both at once turns the last test here red, which is what says it
/// pins the property and not one of the two nets.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late String path;
  late ProviderContainer container;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('saveencoding');
    path = '${dir.path}/note.md';
    File(path).writeAsStringSync('plain\n');
    container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: dir.path),
          AppConfig(autoSave: false),
        ),
      ),
    ]);
  });
  tearDown(() {
    container.dispose();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  /// A tab that believes its file is Latin-1, holding a character Latin-1
  /// cannot carry.
  Future<TabInfo> openAsLatin1(String content) async {
    container.read(tabProvider.notifier).addTab(TabInfo(
          id: 'tab',
          filePath: path,
          fileName: 'note.md',
          content: content,
          encoding: FileEncoding.latin1Encoding,
          diskStamp: await FileService.stampOf(path),
        ));
    return container.read(tabProvider).tabs.single;
  }

  TabInfo tabNow() => container.read(tabProvider).tabs.single;

  test('a write that had to fall back is recorded as what it wrote', () async {
    // 中文 is not in Latin-1, so the write is UTF-8 whatever the tab says.
    final tab = await openAsLatin1('一段中文\n');
    final written = await FileService.saveDocument(
      tab.filePath!,
      tab.content,
      encoding: tab.encoding,
    );
    expect(written, FileEncoding.utf8Encoding,
        reason: 'Latin-1 装不下这段文字，写盘时应当退回 UTF-8——'
            '这个用例本身就靠这一点，先确认它成立');

    await container.read(tabProvider.notifier).markSaved(tab.id, written: written);

    expect(tabNow().encoding, FileEncoding.utf8Encoding,
        reason: '状态栏还写着 Latin-1，而文件已经是 UTF-8；'
            '读者从那里选「按 Latin-1 重读」就会得到乱码');
    // And the file really is what the tab now says it is.
    final back = await FileService().readFileWithLineEnding(path);
    expect(back.content, '一段中文\n');
  });

  test('a write in the encoding asked for leaves it alone', () async {
    final tab = await openAsLatin1('plain text\n');
    final written = await FileService.saveDocument(
      tab.filePath!,
      tab.content,
      encoding: tab.encoding,
    );
    expect(written, FileEncoding.latin1Encoding);
    await container.read(tabProvider.notifier).markSaved(tab.id, written: written);
    expect(tabNow().encoding, FileEncoding.latin1Encoding,
        reason: '没有退回的必要时，不该把读者选的编码改掉');
  });

  test('a stat that fails after a write keeps the old baseline', () async {
    final tab = await openAsLatin1('plain\n');
    expect(tab.diskStamp, isNotNull);
    await FileService.saveDocument(path, 'mine\n', encoding: tab.encoding);

    // The file goes away between the write and the record, which is what a
    // network share dropping out looks like from here: `stampOf` answers null.
    File(path).deleteSync();
    await container
        .read(tabProvider.notifier)
        .markSaved(tab.id, written: FileEncoding.latin1Encoding);

    expect(tabNow().diskStamp, isNotNull,
        reason: '基准被置空了。空基准不是「有冲突」而是「什么都不知道」，'
            '所以这个标签页此后每一次保存都不再检查——而且不会说。'
            '两层兜底任去其一都不会红，两层同时去掉才会：这条守的是那个属性');
    expect(tabNow().isModified, isFalse);
  });
}
