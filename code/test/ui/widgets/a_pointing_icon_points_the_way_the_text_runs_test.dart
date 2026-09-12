import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/widgets/directional_icon.dart';

/// An icon that points somewhere has to point where the reader is going.
///
/// The editor ships Arabic and lays it out right to left, and the side bar's
/// indentation has been `EdgeInsetsDirectional` for a while — but the arrow
/// beside it was a plain `Icons.keyboard_arrow_right`, so a collapsed folder
/// pointed away from where it would open. Two more were the same: the chevron
/// marking the selected settings category, and the send button of the plugin
/// drawer's prompt box.
///
/// This is the rule in one place, and a guard that nothing reaches around it.
void main() {
  Future<void> pump(WidgetTester tester, TextDirection direction) =>
      tester.pumpWidget(MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: const Column(
            children: [
              DirectionalIcon(Icons.keyboard_arrow_right, size: 16),
              DirectionalIcon(Icons.chevron_right, size: 16),
              DirectionalIcon(Icons.send, size: 18),
            ],
          ),
        ),
      ));

  testWidgets('left to right, the icons are the ones asked for', (
    tester,
  ) async {
    await pump(tester, TextDirection.ltr);
    expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
    expect(find.byType(Transform), findsNothing,
        reason: '从左到右时不应该有任何翻转');
  });

  testWidgets('right to left, the ones with a partner are swapped', (
    tester,
  ) async {
    await pump(tester, TextDirection.rtl);
    expect(find.byIcon(Icons.keyboard_arrow_left), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_right), findsNothing);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('right to left, the one with no partner is flipped', (
    tester,
  ) async {
    // `send` has no mirrored glyph in Material, so it is turned over. A
    // substituted partner would be better — see the note on [DirectionalIcon]
    // about why a flip is not one for the arrows.
    await pump(tester, TextDirection.rtl);
    expect(find.byIcon(Icons.send), findsOneWidget);
    final flipped = tester.widget<Transform>(
      find.ancestor(of: find.byIcon(Icons.send), matching: find.byType(Transform)),
    );
    expect(flipped.transform.entry(0, 0), -1.0,
        reason: '没有沿水平方向翻转，纸飞机还指着读者来的方向');
  });

  test('every partner faces the other way', () {
    // Read from the map itself: an entry that maps an icon to itself, or to
    // one that points the same way, would pass every test above while
    // mirroring nothing.
    for (final entry in DirectionalIcon.partners.entries) {
      expect(entry.key, isNot(entry.value),
          reason: '${entry.key} 映射到了自己');
    }
    expect(DirectionalIcon.partners[Icons.chevron_right], Icons.chevron_left);
    expect(DirectionalIcon.partners[Icons.keyboard_arrow_right],
        Icons.keyboard_arrow_left);
  });

  test('no pointing icon is drawn without going through this', () {
    // The list is Material's: these point somewhere, so they mirror. Anything
    // here outside `directional_icon.dart` is an icon that will face the wrong
    // way in Arabic — and the three that did were found exactly this way.
    const pointing = [
      'arrow_back', 'arrow_forward', 'arrow_back_ios', 'arrow_forward_ios',
      'chevron_left', 'chevron_right', 'keyboard_arrow_left',
      'keyboard_arrow_right', 'keyboard_double_arrow_left',
      'keyboard_double_arrow_right', 'navigate_before', 'navigate_next',
      'first_page', 'last_page', 'format_indent_increase',
      'format_indent_decrease', 'subdirectory_arrow_left',
      'subdirectory_arrow_right', 'send', 'arrow_right_alt',
    ];
    /// Drawn on a canvas rather than in the widget tree, where a text
    /// direction does not reach and the painter mirrors the whole diagram or
    /// nothing. Mermaid draws its own arrowheads from geometry.
    bool exempt(String path) =>
        path.endsWith('/directional_icon.dart') ||
        path.contains('/mermaid/');

    final offenders = <String>[];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('/l10n/'))) {
      if (exempt(file.path)) continue;
      final source = file.readAsStringSync();
      for (final name in pointing) {
        for (final at in RegExp('Icons\\.$name\\b').allMatches(source)) {
          // Going through it is the point, so the name appears in the argument.
          // Read backwards far enough to cross the line break and the
          // indentation a wrapped constructor puts between the two.
          final before = source.substring(
              at.start < 80 ? 0 : at.start - 80, at.start);
          if (before.contains('DirectionalIcon(')) continue;
          final line = source.substring(0, at.start).split('\n').length;
          offenders.add('${file.path}:$line  Icons.$name');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: '这些图标指向某处，所以在阿拉伯语下要镜像——'
            '换成 DirectionalIcon，或者如果它在这里确实不该镜像，'
            '把它加进豁免并写明理由：\n${offenders.join('\n')}');
  });
}
