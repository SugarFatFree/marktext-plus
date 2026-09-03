import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';

/// What a plugin can say about when its menu entry applies.
///
/// It could not say anything, so both of the translate plugin's entries were
/// offered at once: "translate the selection" with nothing selected, and
/// "translate the document" while the reader was pointing at a paragraph.
void main() {
  PluginMenuItem menu(Map<String, dynamic> extra) => PluginMenuItem.fromJson({
        'id': 'x',
        'title': 'X',
        'location': 'editor.contextMenu',
        ...extra,
      });

  test('an entry with no condition is always offered', () {
    final item = menu({});
    expect(item.appliesTo(hasSelection: true), isTrue);
    expect(item.appliesTo(hasSelection: false), isTrue);
  });

  test('an entry for the selection is not offered without one', () {
    final item = menu({'when': 'selection'});
    expect(item.appliesTo(hasSelection: true), isTrue);
    expect(item.appliesTo(hasSelection: false), isFalse);
  });

  test('an entry for the whole document steps aside for a selection', () {
    final item = menu({'when': 'noSelection'});
    expect(item.appliesTo(hasSelection: false), isTrue);
    expect(item.appliesTo(hasSelection: true), isFalse);
  });

  test('a condition nobody understands is refused, not ignored', () {
    // Ignoring it would silently make the entry unconditional, which is the
    // opposite of what an author writing `when` is asking for.
    expect(() => menu({'when': 'whenTheMoonIsFull'}), throwsFormatException);
  });
}
