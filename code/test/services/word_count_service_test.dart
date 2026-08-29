import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/word_count_service.dart';

void main() {
  final service = WordCountService();

  group('WordCountService', () {
    test('empty text counts nothing', () {
      final count = service.countWords('');
      expect(count.words, 0);
      expect(count.characters, 0);
      expect(count.paragraphs, 0);
    });

    test('counts space-separated words', () {
      expect(service.countWords('hello world').words, 2);
      expect(service.countWords('  spaced   out  ').words, 2);
      // `a-b` is one word: a hyphen between two letters joins them, the way
      // `well-known` is one word. This line asserted the older behaviour of
      // splitting on it.
      expect(service.countWords('a-b c').words, 2);
    });

    test('counts Chinese and Japanese per character', () {
      expect(service.countWords('中文四个字').words, 5);
      // Japanese and Korean used to count as zero: only the basic Han block
      // was recognised, and kana and Hangul matched no other rule either.
      expect(service.countWords('ひらがな').words, 4);
    });

    test('counts Korean by its spaces, not by its characters', () {
      // Korean is written with spaces between words — 띄어쓰기 — so 한국어 is
      // one word meaning "the Korean language", and word processors count it
      // that way. It was counted per character only because the fix for
      // "Japanese and Korean count as zero" put Hangul in the CJK rule; that
      // was a side effect of the fix, not a decision about the language. A
      // Korean document reported roughly three times its real word count.
      expect(service.countWords('한국어').words, 1);
      expect(service.countWords('이것은 한국어 테스트입니다').words, 3);
      expect(service.countWords('안녕하세요, 여러분!').words, 2);
    });

    test('counts non-Latin alphabets as words, not characters', () {
      expect(service.countWords('Привет мир').words, 2);
      expect(service.countWords('Ελλάδα σήμερα').words, 2);
      // An accent used to split the word in three.
      expect(service.countWords('café crème').words, 2);
    });

    test('mixes scripts in one line', () {
      // 混 合 (2) + English (1) + 文 本 (2)
      expect(service.countWords('混合 English 文本').words, 5);
    });

    test('counts characters in code points', () {
      expect(service.countWords('abc').characters, 3);
      // A single emoji occupies two UTF-16 units but is one character.
      expect(service.countWords('👍').characters, 1);
    });

    test('counts paragraphs split by blank lines', () {
      expect(service.countWords('one').paragraphs, 1);
      expect(service.countWords('one\ntwo').paragraphs, 1);
      expect(service.countWords('one\n\ntwo').paragraphs, 2);
      expect(service.countWords('one\n\n\n\ntwo').paragraphs, 2);
      expect(service.countWords('\n\n').paragraphs, 0);
      expect(service.countWords('one\n\n').paragraphs, 1);
    });

    test('an apostrophe or a hyphen stays inside the word', () {
      // Counting the pieces made an English document read several per cent
      // longer than it is.
      expect(service.countWords("don't can't").words, 2);
      expect(service.countWords('well-known state-of-the-art').words, 2);
      // The typographic apostrophe too, which is what most editors insert.
      expect(service.countWords('don\u2019t stop').words, 2);
    });

    test('a joiner with no word open is still not a word', () {
      // Bullets and quotation marks reach the same test.
      expect(service.countWords('- item one\n- item two').words, 4);
      expect(service.countWords("'quoted' word").words, 2);
      expect(service.countWords('a - b').words, 2);
    });

    test('punctuation alone is not a word', () {
      expect(service.countWords('... --- !!!').words, 0);
      expect(service.countWords('，。！').words, 0);
    });
  });
}
