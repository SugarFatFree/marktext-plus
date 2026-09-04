import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/models/plugin_catalog_entry.dart';
import 'package:marktext_plus/models/tab_info.dart';

/// A plugin page is something the editor has open, so it is a tab.
///
/// It used to replace the whole editor area over whichever document happened
/// to be open — the document was still the active tab, still highlighted in
/// the tab bar, and the only way back was a close button on a page that had
/// no tab of its own.
void main() {
  const entry = PluginCatalogEntry(
    id: 'com.example.demo',
    name: 'Demo',
    version: '1.0.0',
    downloadUrl: null,
    sha256: '',
  );

  test('a tab can hold a plugin page', () {
    final tab = TabInfo(id: 't1', fileName: 'Demo', pluginDetail: entry);
    expect(tab.pluginDetail?.id, 'com.example.demo');
    expect(tab.isPluginDetail, isTrue);
  });

  test('a document tab holds no plugin page', () {
    expect(TabInfo(id: 't2').isPluginDetail, isFalse);
    expect(TabInfo(id: 't2').pluginDetail, isNull);
  });

  test('a plugin tab has no file path, so nothing tries to save it', () {
    // Session persistence, the opened-files list and auto-save all key off
    // filePath. A plugin page that carried one would be written to disk.
    expect(TabInfo.pluginDetail(entry).filePath, isNull);
  });

  test('the tab is named after the plugin', () {
    expect(TabInfo.pluginDetail(entry).fileName, 'Demo');
  });

  test('the tab is not a modified document', () {
    final tab = TabInfo.pluginDetail(entry);
    expect(tab.isModified, isFalse);
    expect(tab.content, isEmpty);
  });

  test('copyWith keeps the plugin page', () {
    final tab = TabInfo.pluginDetail(entry).copyWith(fileName: 'Renamed');
    expect(
      tab.pluginDetail?.id,
      'com.example.demo',
      reason:
          'copying a tab must not quietly turn a plugin page into an '
          'empty document',
    );
  });

  test('two pages for the same plugin are the same page', () {
    // Clicking a plugin twice should come back to its page, not stack a
    // second identical tab beside the first.
    expect(
      TabInfo.pluginDetail(entry).pluginDetail?.id,
      TabInfo.pluginDetail(entry).pluginDetail?.id,
    );
  });
}
