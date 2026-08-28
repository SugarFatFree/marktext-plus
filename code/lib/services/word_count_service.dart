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
  /// Counts words, characters and paragraphs in one pass over the text.
  ///
  /// The previous version ran three regular expressions over the document and
  /// built a full copy of it to strip CJK, which cost about 280 ms on a
  /// megabyte — on the UI isolate, every time typing settled. It also counted
  /// only `[a-zA-Z0-9]` and the basic Han block, so Japanese, Korean and
  /// Russian documents reported **zero** words, and `café` counted as two.
  WordCount countWords(String markdown) {
    if (markdown.isEmpty) return const WordCount();

    int words = 0;
    int characters = 0;
    int paragraphs = 0;

    bool inWord = false;
    bool paragraphHasText = false;
    int newlineRun = 0;

    for (final rune in markdown.runes) {
      // Counted in code points, so an emoji or a rare ideograph is one
      // character rather than the two UTF-16 units it occupies.
      characters++;

      if (rune == 0x0A) {
        newlineRun++;
        inWord = false;
        if (newlineRun >= 2 && paragraphHasText) {
          paragraphs++;
          paragraphHasText = false;
        }
        continue;
      }
      if (rune != 0x0D) newlineRun = 0;

      if (_isCjk(rune)) {
        // Chinese, Japanese and Korean are counted per character, which is
        // how word counts are quoted in those languages.
        words++;
        inWord = false;
        paragraphHasText = true;
      } else if (_isWordCharacter(rune)) {
        if (!inWord) {
          words++;
          inWord = true;
        }
        paragraphHasText = true;
      } else if (inWord && _isWordJoiner(rune)) {
        // An apostrophe or a hyphen between two letters belongs to the word:
        // `don't` is one word and `state-of-the-art` is one, and counting the
        // pieces made an English document read several per cent long.
        //
        // No lookahead is needed. Leaving `inWord` set is exactly what stops
        // the letter after the joiner from starting a new word, and a joiner
        // with nothing after it changes no count at all.
        paragraphHasText = true;
      } else {
        inWord = false;
        if (rune != 0x20 && rune != 0x09 && rune != 0x0D) {
          paragraphHasText = true;
        }
      }
    }

    if (paragraphHasText) paragraphs++;

    return WordCount(
      words: words,
      characters: characters,
      paragraphs: paragraphs,
    );
  }

  /// Scripts written without spaces between words.
  static bool _isCjk(int rune) =>
      (rune >= 0x1100 && rune <= 0x11FF) || // Hangul Jamo
      (rune >= 0x3040 && rune <= 0x30FF) || // Hiragana, Katakana
      (rune >= 0x3400 && rune <= 0x4DBF) || // CJK extension A
      (rune >= 0x4E00 && rune <= 0x9FFF) || // CJK unified ideographs
      (rune >= 0xAC00 && rune <= 0xD7AF) || // Hangul syllables
      (rune >= 0xF900 && rune <= 0xFAFF) || // CJK compatibility ideographs
      (rune >= 0x20000 && rune <= 0x2FA1F); // CJK extensions B and beyond

  /// Everything that is not whitespace or punctuation, so that Cyrillic,
  /// Greek and accented Latin all count as parts of a word.
  /// Characters that join a word rather than ending it.
  ///
  /// Only counted as such between two word characters — a bullet `-` or a
  /// quotation mark on its own reaches this test with no word open.
  static bool _isWordJoiner(int rune) =>
      rune == 0x27 || // apostrophe
      rune == 0x2019 || // right single quotation mark, the typographic one
      rune == 0x2D; // hyphen-minus

  static bool _isWordCharacter(int rune) {
    if (rune <= 0x20) return false; // control characters and space
    if (rune >= 0x21 && rune <= 0x2F) return false; // ! through /
    if (rune >= 0x3A && rune <= 0x40) return false; // : through @
    if (rune >= 0x5B && rune <= 0x60) return rune == 0x5F; // keep _
    if (rune >= 0x7B && rune <= 0x7F) return false; // { through DEL
    if (rune >= 0x2000 && rune <= 0x206F) return false; // general punctuation
    if (rune >= 0x3000 && rune <= 0x303F) return false; // CJK punctuation
    if (rune >= 0xFF01 && rune <= 0xFF20) return false; // fullwidth punctuation
    return true;
  }
}
