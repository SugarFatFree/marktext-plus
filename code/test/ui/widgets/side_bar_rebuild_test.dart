import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/ui/widgets/side_bar.dart';

/// The sidebar shows names and highlights. Watching the whole of `tabProvider`
/// had it rebuilding the entire file tree on every keystroke, because the
/// document's text lives in the same state. These two projections decide when
/// it rebuilds, so what they ignore matters as much as what they report.
void main() {
  TabInfo tab(String id, String? path, {String content = '', bool modified = false}) =>
      TabInfo(
        id: id,
        filePath: path,
        fileName: path ?? 'Untitled',
        content: content,
        isModified: modified,
      );

  group('SideBar.openFilesKey', () {
    test('typing does not change it', () {
      final before = TabState(tabs: [tab('1', '/a.md')], activeTabId: '1');
      final after = TabState(
        tabs: [tab('1', '/a.md', content: 'typed', modified: true)],
        activeTabId: '1',
      );

      expect(SideBar.openFilesKey(after), SideBar.openFilesKey(before));
    });

    test('opening a file changes it', () {
      final before = TabState(tabs: [tab('1', '/a.md')], activeTabId: '1');
      final after = TabState(
        tabs: [tab('1', '/a.md'), tab('2', '/b.md')],
        activeTabId: '1',
      );

      expect(SideBar.openFilesKey(after), isNot(SideBar.openFilesKey(before)));
    });

    test('closing a file changes it', () {
      final before = TabState(
        tabs: [tab('1', '/a.md'), tab('2', '/b.md')],
        activeTabId: '1',
      );
      final after = TabState(tabs: [tab('1', '/a.md')], activeTabId: '1');

      expect(SideBar.openFilesKey(after), isNot(SideBar.openFilesKey(before)));
    });

    test('switching tabs changes it', () {
      final tabs = [tab('1', '/a.md'), tab('2', '/b.md')];
      final before = TabState(tabs: tabs, activeTabId: '1');
      final after = TabState(tabs: tabs, activeTabId: '2');

      expect(SideBar.openFilesKey(after), isNot(SideBar.openFilesKey(before)));
    });

    test('renaming a file changes it', () {
      final before = TabState(tabs: [tab('1', '/a.md')], activeTabId: '1');
      final after = TabState(tabs: [tab('1', '/renamed.md')], activeTabId: '1');

      expect(SideBar.openFilesKey(after), isNot(SideBar.openFilesKey(before)));
    });

    test('an untitled tab has no path to report and still differs', () {
      final before = TabState(tabs: [tab('1', null)], activeTabId: '1');
      final after = TabState(tabs: [tab('1', '/saved.md')], activeTabId: '1');

      expect(SideBar.openFilesKey(after), isNot(SideBar.openFilesKey(before)));
    });

    test('two files whose names concatenate the same are told apart', () {
      // Without a separator "/ab" + "/c" and "/a" + "/bc" would read alike.
      final one = TabState(
        tabs: [tab('1', '/ab'), tab('2', '/c')],
        activeTabId: '1',
      );
      final other = TabState(
        tabs: [tab('1', '/a'), tab('2', '/bc')],
        activeTabId: '1',
      );

      expect(SideBar.openFilesKey(one), isNot(SideBar.openFilesKey(other)));
    });
  });

  group('SideBar.activePath', () {
    test('reports the path of the tab in the foreground', () {
      final state = TabState(
        tabs: [tab('1', '/a.md'), tab('2', '/b.md')],
        activeTabId: '2',
      );

      expect(SideBar.activePath(state), '/b.md');
    });

    test('null when nothing is active', () {
      expect(SideBar.activePath(const TabState()), isNull);
    });

    test('null when the active tab has never been saved', () {
      final state = TabState(tabs: [tab('1', null)], activeTabId: '1');

      expect(SideBar.activePath(state), isNull);
    });
  });
}
