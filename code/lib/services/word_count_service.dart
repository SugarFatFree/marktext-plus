class WordCount {
  final int words;
  final int characters;
  final int paragraphs;

  const WordCount({
    this.words = 0,
    this.characters = 0,
    this.paragraphs = 0,
  });
}

class WordCountService {
  static final _cjkRegExp = RegExp(r'[\u4e00-\u9fa5]');
  static final _nonCjkWordRegExp = RegExp(r'[a-zA-Z0-9]+');

  WordCount countWords(String markdown) {
    if (markdown.isEmpty) return const WordCount();

    // Characters: total length
    final characters = markdown.length;

    // Paragraphs: split by 2+ newlines, filter empty
    final paragraphs = markdown
        .split(RegExp(r'\n{2,}'))
        .where((p) => p.trim().isNotEmpty)
        .length;

    // Words: CJK characters count individually + non-CJK words split by spaces
    int words = 0;
    // Count CJK characters
    words += _cjkRegExp.allMatches(markdown).length;
    // Remove CJK characters, then count remaining words
    final nonCjk = markdown.replaceAll(_cjkRegExp, ' ');
    words += _nonCjkWordRegExp.allMatches(nonCjk).length;

    return WordCount(
      words: words,
      characters: characters,
      paragraphs: paragraphs,
    );
  }
}
