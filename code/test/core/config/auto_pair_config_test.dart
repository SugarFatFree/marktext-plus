import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';

/// Auto-closing used to be one unconditional map holding brackets, quotes and
/// markdown syntax together, so none of it could be turned off. Upstream
/// MarkText has offered the three as separate switches all along, and the
/// markdown one is the one people disagree about: typing `*` to begin emphasis
/// and being handed `**` with the caret in the middle interrupts the sentence
/// for some and helps others.
void main() {
  test('all three default to on, which is what the editor already did', () {
    final config = AppConfig();
    expect(config.autoPairBracket, isTrue);
    expect(config.autoPairQuote, isTrue);
    expect(config.autoPairMarkdownSyntax, isTrue);
  });

  test('each survives a round trip through the config file', () {
    // A setting that serialises but does not deserialise reverts on the next
    // launch, and the reader turns it off again and again.
    final off = AppConfig(
      autoPairBracket: false,
      autoPairQuote: false,
      autoPairMarkdownSyntax: false,
    );

    final restored = AppConfig.fromJson(off.toJson());

    expect(restored.autoPairBracket, isFalse);
    expect(restored.autoPairQuote, isFalse);
    expect(restored.autoPairMarkdownSyntax, isFalse);
  });

  test('a config written before these existed keeps the old behaviour', () {
    final old = AppConfig().toJson()
      ..remove('autoPairBracket')
      ..remove('autoPairQuote')
      ..remove('autoPairMarkdownSyntax');

    final restored = AppConfig.fromJson(old);

    expect(restored.autoPairBracket, isTrue);
    expect(restored.autoPairQuote, isTrue);
    expect(restored.autoPairMarkdownSyntax, isTrue);
  });

  test('copyWith changes one without disturbing the others', () {
    final config = AppConfig().copyWith(autoPairMarkdownSyntax: false);

    expect(config.autoPairMarkdownSyntax, isFalse);
    expect(config.autoPairBracket, isTrue);
    expect(config.autoPairQuote, isTrue);
  });
}
