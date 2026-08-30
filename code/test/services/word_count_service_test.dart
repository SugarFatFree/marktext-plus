import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/word_count_service.dart';

void main() {
  _destinationsAreNotWords();
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

/// Where a link says to go is not part of what the reader is reading.
///
/// `见[链接](https://example.com/very/long/path)这里` reads as five characters
/// and was counted as eleven words. A document with references in it reported
/// a length its prose does not have, and a word count is the number a writer
/// works to. Upstream MarkText counts what it draws, and what it draws is the
/// label.
void _destinationsAreNotWords() {
  final service = WordCountService();

  group('a destination is not counted', () {
    test('a link counts its label only', () {
      expect(
        service.countWords('见[链接](https://example.com/very/long/path)这里')
            .words,
        service.countWords('见链接这里').words,
      );
    });

    test('an image counts its alt text only', () {
      expect(
        service.countWords('![一张图](/path/to/image.png)').words,
        service.countWords('一张图').words,
      );
    });

    test('an address with brackets in it is still skipped whole', () {
      // `…/wiki/A_(b)` — one nested pair, which addresses do carry.
      expect(
        service.countWords('见[条目](https://ex.com/wiki/A_(b))这里').words,
        service.countWords('见条目这里').words,
      );
    });
  });

  group('what the reader never sees is not counted', () {
    test('the metadata block at the top', () {
      // A title, an author and a few tags added fourteen words to a document
      // that has five.
      expect(
        service
            .countWords('---\ntitle: 我的文档标题\nauthor: 某人\ntags: 甲 乙 丙\n---\n\n正文一句话。')
            .words,
        service.countWords('正文一句话。').words,
      );
    });

    test('a note left in an HTML comment', () {
      expect(
        service.countWords('正文<!-- 这是给编辑看的注释文字 -->结束').words,
        service.countWords('正文结束').words,
      );
    });

    test('a comment spanning lines', () {
      expect(
        service.countWords('正文\n<!--\n很多\n注释文字\n-->\n结束').words,
        service.countWords('正文\n结束').words,
      );
    });
  });

  group('what only looks like something invisible', () {
    test('three dashes that never close are not front matter', () {
      // One line that looks like an opener must not swallow the document.
      final counted = service.countWords('---\n正文一句话。\n还有一句。').words;
      expect(counted, greaterThan(4));
    });

    test('an unclosed comment ends at the document, not before it', () {
      expect(service.countWords('正文<!-- 没有闭合').words, greaterThan(0));
    });

    test('a rule below text is not front matter', () {
      // `---` under a paragraph is a heading underline, not an opener: only
      // the very first line can open a metadata block.
      expect(service.countWords('标题\n---\n正文').words,
          service.countWords('标题\n正文').words);
    });
  });

  group('what is still counted', () {
    test('an autolink is text the reader sees', () {
      // `<https://example.com>` is displayed as itself, so it counts.
      expect(service.countWords('<https://example.com>').words,
          greaterThan(1));
    });

    test('brackets that are not a link', () {
      expect(service.countWords('见 [注一] 这里').words,
          service.countWords('见 注一 这里').words);
    });

    test('an unclosed destination does not swallow the document', () {
      // A `(` with no `)` must end at the line, or the rest of the file would
      // stop counting.
      final counted = service.countWords('见[链接](未闭合\n后面还有很多字').words;
      expect(counted, greaterThan(4));
    });

    test('emphasis markers were never words anyway', () {
      expect(service.countWords('这是一段**中文**文字').words,
          service.countWords('这是一段中文文字').words);
    });
  });
}
