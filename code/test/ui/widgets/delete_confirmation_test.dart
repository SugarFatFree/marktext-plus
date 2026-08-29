import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/ui/widgets/side_bar.dart';

/// What the reader is asked before something is removed.
///
/// One message covered all four cases: "Are you sure you want to delete X?".
/// For a folder that is about to take five hundred notes with it, on a
/// platform with no trash to recover them from, that is not enough to agree
/// to. The four now differ in the two ways that matter — whether it is a
/// folder, and whether it can be undone.
void main() {
  late AppLocalizations en;

  setUp(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('a file that can be trashed says so', () {
    final message = deleteConfirmationFor(en, 'note.md',
        isDirectory: false, canTrash: true);
    expect(message, contains('note.md'));
    expect(message.toLowerCase(), contains('trash'));
    expect(message.toLowerCase(), isNot(contains('permanently')));
  });

  test('a folder that can be trashed says what goes with it', () {
    final message = deleteConfirmationFor(en, 'notes',
        isDirectory: true, canTrash: true);
    expect(message.toLowerCase(), contains('trash'));
    expect(message.toLowerCase(), contains('everything in it'),
        reason: '没有说明文件夹里的东西会一起走');
  });

  test('a folder that cannot be trashed says it cannot be undone', () {
    final message = deleteConfirmationFor(en, 'notes',
        isDirectory: true, canTrash: false);
    expect(message.toLowerCase(), contains('permanently'));
    expect(message.toLowerCase(), contains('everything in it'));
    expect(message.toLowerCase(), contains('cannot be undone'));
  });

  test('the four cases are four different questions', () {
    final messages = {
      for (final directory in [false, true])
        for (final trash in [false, true])
          deleteConfirmationFor(en, 'x',
              isDirectory: directory, canTrash: trash),
    };
    expect(messages, hasLength(4),
        reason: '有两种情况问的是同一句话，读者分不出自己同意了什么');
  });

  test('every language answers all four', () async {
    // A missing translation here is a dialog in English in the middle of a
    // localised application, at the one moment it matters most.
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final directory in [false, true]) {
        for (final trash in [false, true]) {
          final message = deleteConfirmationFor(l10n, 'x',
              isDirectory: directory, canTrash: trash);
          expect(message, isNotEmpty, reason: '$locale');
          expect(message, contains('x'), reason: '$locale 的文案里没有文件名');
        }
      }
    }
  });
}
