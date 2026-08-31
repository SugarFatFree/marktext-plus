import 'markdown_parser.dart';

/// Resolves `*` and `_` emphasis over a list of already-parsed inline spans.
///
/// A single regular expression cannot say what emphasis means. `*foo **bar***`
/// is an italic holding a bold, and `***foo** bar*` is the same two the other
/// way round, but both are a run of asterisks beside a run of asterisks — the
/// answer depends on what is on each side of every run in the paragraph, which
/// is a decision no one alternative can make. The format describes an
/// algorithm instead: collect the runs, then repeatedly close the leftmost
/// closer against the nearest opener before it.
///
/// This runs after everything else has been recognised, so a code span or a
/// link is an atom here — emphasis may wrap it, and its own text can no longer
/// be mistaken for a delimiter.
List<InlineSpan> resolveEmphasis(List<InlineSpan> spans) {
  final head = _tokenise(spans);
  if (head == null) return spans;
  var any = false;
  for (_Tok? t = head; t != null; t = t.next) {
    if (t.isDelimiter) {
      any = true;
      break;
    }
  }
  // Nothing to resolve: the overwhelming majority of paragraphs. Returning the
  // spans as they came avoids rebuilding a list that would be identical.
  if (!any) return spans;
  return _flatten(_process(head));
}

/// One piece of the paragraph: either a run of `*`/`_`, or anything else.
class _Tok {
  _Tok.atom(this.span)
      : char = '',
        length = 0,
        canOpen = false,
        canClose = false;

  _Tok.delimiter(this.char, this.length, this.canOpen, this.canClose)
      : span = null;

  InlineSpan? span;
  final String char;
  int length;
  bool canOpen;
  bool canClose;

  /// Chained rather than held in a list: an emphasis takes its content out of
  /// the sequence and puts one node back, and doing that in a list moves every
  /// element after it. On `*a` repeated ten thousand times that is ten
  /// thousand moves of ten thousand elements — three seconds for a line the
  /// reader can type by holding a key down.
  _Tok? prev;
  _Tok? next;

  bool get isDelimiter => char.isNotEmpty && length > 0;
}

/// Whether a run of emphasis markers with [before] on its left and [after] on
/// its right may open emphasis, close it, both, or neither.
///
/// The rule the format calls flanking, and the reason `**加粗。**后面` is not
/// bold: the closing run sits between a full stop and a letter. Exported
/// because the source pane tints emphasis as it is typed and has to reach the
/// same answer — a pane that colours what the other pane will not draw is
/// worse than one that colours nothing.
///
/// [char] matters because `_` is stricter than `*`: it does not mark inside a
/// word, so a file_name_like_this stays one word.
({bool canOpen, bool canClose}) emphasisFlanking({
  required String before,
  required String after,
  required String char,
}) {
  final beforeSpace = _isWhitespace(before);
  final afterSpace = _isWhitespace(after);
  final beforePunct = _isPunctuation(before);
  final afterPunct = _isPunctuation(after);

  final left = !afterSpace && (!afterPunct || beforeSpace || beforePunct);
  final right = !beforeSpace && (!beforePunct || afterSpace || afterPunct);

  return (
    canOpen: char == '*' ? left : left && (!right || beforePunct),
    canClose: char == '*' ? right : right && (!left || afterPunct),
  );
}

/// Whether [c] is a character the flanking rules count as punctuation.
bool _isPunctuation(String c) =>
    RegExp(r'''[!-/:-@\[-`{-~¡-¿‐-‧、-】！-･]''')
        .hasMatch(c);

bool _isWhitespace(String c) => c.trim().isEmpty;

_Tok? _tokenise(List<InlineSpan> spans) {
  final tokens = <_Tok>[];
  for (var s = 0; s < spans.length; s++) {
    final span = spans[s];
    if (span.type != InlineType.text) {
      tokens.add(_Tok.atom(span));
      continue;
    }
    final text = span.text;
    var i = 0;
    final buffer = StringBuffer();
    while (i < text.length) {
      final c = text[i];
      if (c != '*' && c != '_') {
        buffer.write(c);
        i++;
        continue;
      }
      if (buffer.isNotEmpty) {
        tokens.add(_Tok.atom(
          InlineSpan(type: InlineType.text, text: buffer.toString()),
        ));
        buffer.clear();
      }
      var j = i;
      while (j < text.length && text[j] == c) {
        j++;
      }
      // The characters on each side decide whether this run may open, close,
      // both or neither. A span of another kind beside it — a code span, a
      // link — counts as an ordinary character, which is what it looks like
      // to a reader.
      final before = i > 0
          ? text[i - 1]
          : (tokens.isNotEmpty ? 'a' : ' ');
      final after = j < text.length
          ? text[j]
          : (s + 1 < spans.length ? 'a' : ' ');

      final flanking = emphasisFlanking(before: before, after: after, char: c);

      tokens.add(
        _Tok.delimiter(c, j - i, flanking.canOpen, flanking.canClose),
      );
      i = j;
    }
    if (buffer.isNotEmpty) {
      tokens.add(_Tok.atom(
        InlineSpan(type: InlineType.text, text: buffer.toString()),
      ));
    }
  }
  if (tokens.isEmpty) return null;
  for (var i = 0; i < tokens.length; i++) {
    tokens[i].prev = i > 0 ? tokens[i - 1] : null;
    tokens[i].next = i + 1 < tokens.length ? tokens[i + 1] : null;
  }
  return tokens.first;
}

/// Closes delimiters, leftmost closer first, against the nearest opener.
///
/// Returns the head of the chain, which changes when the first token is one of
/// the two that an emphasis consumes.
_Tok _process(_Tok head) {
  // How far back it is worth looking for an opener, per closing run. Once a
  // search has failed for a given character and length class, no later closer
  // of that class can succeed further back either — without this the search is
  // quadratic on a line of unmatched markers.
  final openersBottom = <String, _Tok?>{};

  _Tok? closer = head;
  var first = head;

  while (closer != null) {
    if (!closer.isDelimiter || !closer.canClose) {
      closer = closer.next;
      continue;
    }

    final key = '${closer.char}${closer.length % 3}${closer.canOpen}';
    final bottom = openersBottom[key];

    _Tok? opener;
    for (var candidate = closer.prev;
        candidate != null && !identical(candidate, bottom);
        candidate = candidate.prev) {
      if (!candidate.isDelimiter) continue;
      if (candidate.char != closer.char || !candidate.canOpen) continue;
      // The rule of three: when one of the two runs can both open and close,
      // their lengths may not sum to a multiple of three unless both are.
      // Without it `foo***bar***baz` comes out inside out.
      final oddMatch = (closer.canOpen || candidate.canClose) &&
          (closer.length + candidate.length) % 3 == 0 &&
          !(closer.length % 3 == 0 && candidate.length % 3 == 0);
      if (oddMatch) continue;
      opener = candidate;
      break;
    }

    if (opener == null) {
      // Nothing to close against. Remember how far this search reached, so the
      // next closer of the same class does not walk the same ground.
      openersBottom[key] = closer.prev;
      // A run that could also open stays where it is — something later may
      // close on it — and one that cannot becomes the characters it is made of.
      if (!closer.canOpen) closer.canClose = false;
      closer = closer.next;
      continue;
    }

    final strong = opener.length >= 2 && closer.length >= 2;
    final used = strong ? 2 : 1;

    final content = <InlineSpan>[];
    for (var tok = opener.next; tok != null && !identical(tok, closer);
        tok = tok.next) {
      if (tok.isDelimiter) {
        content.add(InlineSpan(
          type: InlineType.text,
          text: tok.char * tok.length,
        ));
      } else if (tok.span != null) {
        content.add(tok.span!);
      }
    }

    final wrapped = _Tok.atom(InlineSpan(
      type: strong ? InlineType.bold : InlineType.italic,
      text: _plainOf(content),
      children: content,
    ));

    // The content between the two runs becomes one node.
    opener.next = wrapped;
    wrapped.prev = opener;
    wrapped.next = closer;
    closer.prev = wrapped;

    opener.length -= used;
    closer.length -= used;

    if (opener.length == 0) {
      final before = opener.prev;
      wrapped.prev = before;
      if (before == null) {
        first = wrapped;
      } else {
        before.next = wrapped;
      }
    }
    if (closer.length == 0) {
      final after = closer.next;
      wrapped.next = after;
      after?.prev = wrapped;
      closer = after;
    }
  }

  return first;
}

/// The text of [spans] with no markup, for the span's own `text` field.
String _plainOf(List<InlineSpan> spans) => [
      for (final s in spans)
        if (s.children.isEmpty) s.text else _plainOf(s.children),
    ].join();

List<InlineSpan> _flatten(_Tok head) {
  final out = <InlineSpan>[];
  for (_Tok? tok = head; tok != null; tok = tok.next) {
    if (tok.isDelimiter) {
      out.add(InlineSpan(
        type: InlineType.text,
        text: tok.char * tok.length,
      ));
    } else if (tok.span != null) {
      out.add(tok.span!);
    }
  }
  return out;
}
