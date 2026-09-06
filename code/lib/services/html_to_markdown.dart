/// Turns the HTML flavour of a clipboard paste into markdown.
///
/// Copying a list or a table out of a browser and pasting it here used to
/// yield the plain-text flavour: the structure was gone, and what arrived was
/// the words with their bullets and their column breaks flattened into
/// running text. Upstream MarkText converts the HTML instead, and has a
/// "paste as plain text" command precisely because converting is the default.
///
/// A small, deliberate parser rather than a dependency: what a clipboard
/// carries is a handful of shapes — headings, paragraphs, lists, tables,
/// links, code, emphasis — and a general HTML library brings a great deal of
/// machinery for the rest of the language that this never needs.
class HtmlToMarkdown {
  const HtmlToMarkdown._();

  /// Converts [html] to markdown, or returns null when there is nothing in it
  /// worth converting.
  ///
  /// Null rather than an empty string so a caller can fall back to the plain
  /// text: HTML that turns into nothing is a sign this converter did not
  /// understand it, and the plain flavour is then the better paste.
  static String? convert(String html) {
    final body = _body(html);
    if (body.trim().isEmpty) return null;

    final tokens = _tokenise(body);
    final out = StringBuffer();
    _writeBlocks(tokens, out);

    final markdown = out
        .toString()
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return markdown.isEmpty ? null : markdown;
  }

  /// The contents of `<body>`, or the whole string when there is no body.
  ///
  /// Windows' `HTML Format` wraps the fragment in a full document with its own
  /// header; the browsers' own fragments usually have none.
  static String _body(String html) {
    final match =
        RegExp(r'<body[^>]*>(.*)</body>', dotAll: true, caseSensitive: false)
            .firstMatch(html);
    var text = match?.group(1) ?? html;
    // Comments carry the clipboard's own fragment markers.
    text = _withoutComments(text);
    text = _withoutRawText(text);
    return text;
  }

  /// The text with every complete `<!-- ... -->` removed.
  ///
  /// Written by hand rather than as `RegExp(r'<!--.*?-->')` because the
  /// clipboard is untrusted input and that pattern is quadratic on it: every
  /// `<!--` with no `-->` after it scans to the end of the string before
  /// giving up. Ten thousand of them took 842ms, forty thousand would take
  /// thirteen seconds, and the paste would look like a freeze. Scanning
  /// forward from each opener is linear no matter what arrives.
  ///
  /// An unterminated `<!--` is left in place, which is what the regex did too.
  static String _withoutComments(String text) {
    if (!text.contains('<!--')) return text;
    final out = StringBuffer();
    var at = 0;
    while (true) {
      final open = text.indexOf('<!--', at);
      if (open < 0) break;
      final close = text.indexOf('-->', open + 4);
      if (close < 0) break;
      out.write(text.substring(at, open));
      at = close + 3;
    }
    if (at == 0) return text;
    out.write(text.substring(at));
    return out.toString();
  }

  static final RegExp _rawTextOpen =
      RegExp(r'<(script|style)[^>]*>', caseSensitive: false);

  /// The text with `<script>` and `<style>` elements removed, content and all.
  ///
  /// The same shape as [_withoutComments], two lines above it, and the same
  /// reason — it was on screen while I fixed that one and I did not read it.
  /// Finding the opening tag is fine: `[^>]*` cannot run past the `>` it is
  /// looking for. It was `.*?</\1>` that was quadratic, an opener with no
  /// closer after it scanning to the end of the string before the next one
  /// does it again. Ten thousand `<script>` took 347ms and ten thousand
  /// `<style>` took 955ms.
  ///
  /// An element whose closing tag never arrives is left in place with its
  /// content, which is what the pattern did — and once one of the two names
  /// is known to have no closer left in the string, the openers after it are
  /// skipped without looking again. That is what keeps ten thousand unclosed
  /// `<script>` from costing ten thousand scans.
  static String _withoutRawText(String text) {
    final out = StringBuffer();
    final exhausted = <String>{};
    var written = 0;
    var scan = 0;
    while (true) {
      final matches = _rawTextOpen.allMatches(text, scan).iterator;
      if (!matches.moveNext()) break;
      final opener = matches.current;
      final tag = opener.group(1)!.toLowerCase();
      if (exhausted.contains(tag)) {
        scan = opener.end;
        continue;
      }
      final close = _indexOfClose(text, tag, opener.end);
      if (close < 0) {
        exhausted.add(tag);
        scan = opener.end;
        continue;
      }
      out.write(text.substring(written, opener.start));
      written = close;
      scan = close;
    }
    if (written == 0) return text;
    out.write(text.substring(written));
    return out.toString();
  }

  /// Where `</tag>` ends at or after [from], ignoring case; -1 when absent.
  static int _indexOfClose(String text, String tag, int from) {
    final close = '</$tag>';
    final n = close.length;
    for (var i = from; i + n <= text.length; i++) {
      var same = true;
      for (var j = 0; j < n; j++) {
        var c = text.codeUnitAt(i + j);
        if (c >= 0x41 && c <= 0x5A) c += 0x20;
        if (c != close.codeUnitAt(j)) {
          same = false;
          break;
        }
      }
      if (same) return i + n;
    }
    return -1;
  }

  /// One tag or one run of text.
  static List<_Token> _tokenise(String html) {
    final tokens = <_Token>[];
    final tagRe = RegExp(r'<(/?)([a-zA-Z][a-zA-Z0-9]*)([^>]*)>');
    var at = 0;
    for (final match in tagRe.allMatches(html)) {
      if (match.start > at) {
        tokens.add(_Token.text(html.substring(at, match.start)));
      }
      tokens.add(_Token.tag(
        name: match.group(2)!.toLowerCase(),
        closing: match.group(1)! == '/',
        attributes: match.group(3)!,
      ));
      at = match.end;
    }
    if (at < html.length) tokens.add(_Token.text(html.substring(at)));
    return tokens;
  }

  static void _writeBlocks(List<_Token> tokens, StringBuffer out) {
    var index = 0;
    while (index < tokens.length) {
      final token = tokens[index];
      if (token.isText) {
        final text = _clean(token.text);
        if (text.isNotEmpty) out.write('$text\n\n');
        index++;
        continue;
      }

      if (token.closing) {
        index++;
        continue;
      }

      switch (token.name) {
        case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
          final level = int.parse(token.name.substring(1));
          final (inner, next) = _until(tokens, index, token.name);
          out.write('${'#' * level} ${_inline(inner)}\n\n');
          index = next;
        case 'span' || 'b' || 'strong' || 'i' || 'em' || 'u' || 'del' || 's' ||
              'a' || 'font' || 'mark' || 'sup' || 'sub' || 'ins' || 'code':
          // An inline tag met where a block was expected. Word processors on
          // the web wrap what they put on the clipboard in one — Google Docs
          // in a `<b>`, others in a `<span>` or a `<font>` — and skipping the
          // tag left its children to be met one at a time, so a styled run
          // came out as one paragraph per span with its emphasis gone.
          //
          // Read as inline unless it really does hold blocks, which is the
          // same question the div below answers.
          final (inner, next) = _until(tokens, index, token.name);
          if (inner.any((t) => t.isTag && _isBlock(t.name))) {
            // Blocks inside it: the wrapper's own styling has nowhere to go —
            // markdown cannot put a heading in bold — so only its contents
            // carry over, which is what the div below does too.
            _writeBlocks(inner, out);
          } else {
            final text = _inline([
              token,
              ...inner,
              _Token.tag(name: token.name, closing: true, attributes: ''),
            ]);
            if (text.isNotEmpty) out.write('$text\n\n');
          }
          index = next;
        case 'div':
          // A div is a container, not a paragraph: browsers wrap whole
          // fragments in one, and treating it as a paragraph flattened every
          // heading, list and table inside it into a single run of text.
          final (inner, next) = _until(tokens, index, 'div');
          if (inner.any((t) => t.isTag && _isBlock(t.name))) {
            _writeBlocks(inner, out);
          } else {
            final text = _inline(inner);
            if (text.isNotEmpty) out.write('$text\n\n');
          }
          index = next;
        case 'p':
          final (inner, next) = _until(tokens, index, 'p');
          final text = _inline(inner);
          if (text.isNotEmpty) out.write('$text\n\n');
          index = next;
        case 'ul' || 'ol':
          final (inner, next) = _until(tokens, index, token.name);
          _writeList(inner, out, ordered: token.name == 'ol');
          out.write('\n');
          index = next;
        case 'blockquote':
          final (inner, next) = _until(tokens, index, token.name);
          final nested = StringBuffer();
          _writeBlocks(inner, nested);
          for (final line in nested.toString().trim().split('\n')) {
            out.write(line.isEmpty ? '>\n' : '> $line\n');
          }
          out.write('\n');
          index = next;
        case 'pre':
          final (inner, next) = _until(tokens, index, token.name);
          final code = inner.map((t) => t.isText ? t.text : '').join();
          // The language, where the page says what it is. Every site that
          // shows code says so on the `<code>` element — GitHub, Prism and
          // highlight.js all write `language-dart` — and dropping it meant a
          // snippet pasted from documentation arrived with no colouring at
          // all, in a program whose fences carry a language.
          final language = _codeLanguage(inner);
          out.write('```$language\n${_decode(code).trimRight()}\n```\n\n');
          index = next;
        case 'table':
          final (inner, next) = _until(tokens, index, token.name);
          _writeTable(inner, out);
          index = next;
        case 'hr':
          out.write('---\n\n');
          index++;
        case 'br':
          out.write('\n');
          index++;
        default:
          index++;
      }
    }
  }

  static void _writeList(
    List<_Token> tokens,
    StringBuffer out, {
    required bool ordered,
  }) {
    var number = 1;
    var index = 0;
    while (index < tokens.length) {
      final token = tokens[index];
      if (token.isTag && !token.closing && token.name == 'li') {
        final (inner, next) = _until(tokens, index, 'li');
        // A list inside a list item is written under it, indented.
        final nestedStart = inner.indexWhere(
            (t) => t.isTag && !t.closing && (t.name == 'ul' || t.name == 'ol'));
        final own = nestedStart < 0 ? inner : inner.sublist(0, nestedStart);
        final marker = ordered ? '${number++}. ' : '- ';
        // A checkbox in the item is the item's state, and it is the whole
        // point of a list that has them. It used to be dropped, so a list of
        // things to do pasted from a page arrived with everything unticked
        // and nothing to say which had been done.
        out.write('$marker${_taskBox(own)}${_inline(own)}\n');

        if (nestedStart >= 0) {
          final nested = StringBuffer();
          _writeList(
            inner.sublist(nestedStart + 1),
            nested,
            ordered: inner[nestedStart].name == 'ol',
          );
          for (final line in nested.toString().trimRight().split('\n')) {
            if (line.isNotEmpty) out.write('  $line\n');
          }
        }
        index = next;
        continue;
      }
      index++;
    }
  }

  static void _writeTable(List<_Token> tokens, StringBuffer out) {
    final rows = <List<String>>[];
    var index = 0;
    while (index < tokens.length) {
      final token = tokens[index];
      if (token.isTag && !token.closing && token.name == 'tr') {
        final (inner, next) = _until(tokens, index, 'tr');
        final cells = <String>[];
        var at = 0;
        while (at < inner.length) {
          final cell = inner[at];
          if (cell.isTag && !cell.closing && (cell.name == 'td' ||
              cell.name == 'th')) {
            final (content, after) = _until(inner, at, cell.name);
            // A pipe inside a cell would split it; escaping is how GFM keeps
            // one there.
            cells.add(_inline(content).replaceAll('|', r'\|'));
            at = after;
            continue;
          }
          at++;
        }
        if (cells.isNotEmpty) rows.add(cells);
        index = next;
        continue;
      }
      index++;
    }

    if (rows.isEmpty) return;
    final width = rows.first.length;
    out.write('| ${rows.first.join(' | ')} |\n');
    out.write('|${List.filled(width, '---').join('|')}|\n');
    for (final row in rows.skip(1)) {
      final cells = List.of(row);
      while (cells.length < width) {
        cells.add('');
      }
      out.write('| ${cells.take(width).join(' | ')} |\n');
    }
    out.write('\n');
  }

  /// Blocks that cannot contain a paragraph, and so close an open one.
  ///
  /// `<p>one<p>two` is two paragraphs in HTML — the closing tag is optional
  /// and browsers put it on the clipboard that way. Taking everything to the
  /// end of the document instead ran the two together into one line.
  /// Whether a tag introduces a block, rather than inline content.
  static bool _isBlock(String name) => _closesParagraph.contains(name);

  static const _closesParagraph = {
    'p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    'ul', 'ol', 'table', 'blockquote', 'pre', 'hr',
  };

  /// The tokens up to [name]'s closing tag, and the index just past it.
  static (List<_Token>, int) _until(
    List<_Token> tokens,
    int openAt,
    String name,
  ) {
    final implicitlyClosed = name == 'p' || name == 'li';
    // A list item may hold a list, and that list holds items of its own —
    // those must not be mistaken for a sibling closing this one.
    var listDepth = 0;
    var depth = 0;
    for (var i = openAt; i < tokens.length; i++) {
      final token = tokens[i];
      if (!token.isTag) continue;

      if (token.name == 'ul' || token.name == 'ol') {
        listDepth += token.closing ? -1 : 1;
      }

      if (token.name == name) {
        if (token.closing) {
          depth--;
          if (depth == 0) return (tokens.sublist(openAt + 1, i), i + 1);
          continue;
        }
        // A second `<p>` before the first has closed ends the first, rather
        // than nesting inside it — paragraphs do not nest. The same for a
        // sibling `<li>`, but only at this item's own level.
        if (implicitlyClosed && depth == 1 && listDepth <= 0) {
          return (tokens.sublist(openAt + 1, i), i);
        }
        depth++;
        continue;
      }

      if (implicitlyClosed &&
          depth == 1 &&
          !token.closing &&
          name == 'p' &&
          _closesParagraph.contains(token.name)) {
        return (tokens.sublist(openAt + 1, i), i);
      }
    }
    // Genuinely unclosed at the end of the document: take the rest.
    return (tokens.sublist(openAt + 1), tokens.length);
  }

  /// Inline markup within one block.
  static String _inline(List<_Token> tokens) {
    final out = StringBuffer();
    var index = 0;
    while (index < tokens.length) {
      final token = tokens[index];
      if (token.isText) {
        out.write(_clean(token.text));
        index++;
        continue;
      }
      if (token.closing) {
        index++;
        continue;
      }

      switch (token.name) {
        case 'strong' || 'b':
          final (inner, next) = _until(tokens, index, token.name);
          final text = _inline(inner);
          // A `<b>` that says in its own style that it is not bold is not
          // bold. Google Docs wraps everything it puts on the clipboard in
          // exactly that — `<b style="font-weight:normal">` — so a fragment
          // copied out of it arrived with the whole paste in asterisks.
          final reallyBold = !_styleSaysNotBold(token.attributes);
          if (text.isNotEmpty) out.write(reallyBold ? '**$text**' : text);
          index = next;
        case 'em' || 'i':
          final (inner, next) = _until(tokens, index, token.name);
          final text = _inline(inner);
          if (text.isNotEmpty) out.write('*$text*');
          index = next;
        case 'del' || 's' || 'strike':
          final (inner, next) = _until(tokens, index, token.name);
          out.write('~~${_inline(inner)}~~');
          index = next;
        case 'code':
          final (inner, next) = _until(tokens, index, token.name);
          out.write('`${_inline(inner)}`');
          index = next;
        case 'a':
          final (inner, next) = _until(tokens, index, 'a');
          final href = _attribute(token.attributes, 'href');
          final text = _inline(inner);
          out.write(href == null || href.isEmpty ? text : '[$text]($href)');
          index = next;
        case 'img':
          final src = _attribute(token.attributes, 'src') ?? '';
          final alt = _attribute(token.attributes, 'alt') ?? '';
          if (src.isNotEmpty) out.write('![$alt]($src)');
          index++;
        case 'br':
          out.write('  \n');
          index++;
        // Four tags this editor has markdown for, and read none of them
        // back: it exports `==x==`, `++x++`, `^x^` and `~x~` as these, so
        // even its own HTML came back with the marking gone — never mind a
        // page, where <sup> is how a footnote reference is written.
        case 'mark':
          final (inner, next) = _until(tokens, index, 'mark');
          final text = _inline(inner);
          out.write(_canWrap(text, '==') ? '==$text==' : text);
          index = next;
        case 'u' || 'ins':
          final (inner, next) = _until(tokens, index, token.name);
          final text = _inline(inner);
          out.write(_canWrap(text, '++') ? '++$text++' : text);
          index = next;
        case 'sup':
          final (inner, next) = _until(tokens, index, 'sup');
          final text = _inline(inner);
          out.write(_canWrap(text, '^', tight: true) ? '^$text^' : text);
          index = next;
        case 'sub':
          final (inner, next) = _until(tokens, index, 'sub');
          final text = _inline(inner);
          out.write(_canWrap(text, '~', tight: true) ? '~$text~' : text);
          index = next;
        case 'span':
          // Word processors on the web mark up with styles rather than with
          // tags: Google Docs writes `font-weight:700` where a page would
          // write `<b>`. Without this, everything pasted from one arrived as
          // plain text with its emphasis gone.
          final (inner, next) = _until(tokens, index, 'span');
          final text = _inline(inner);
          out.write(_wrapStyled(text, token.attributes));
          index = next;
        default:
          index++;
      }
    }
    return out.toString().trim();
  }

  /// Whether [text] can be wrapped in [marker] and still read back as markup.
  ///
  /// `^x^` and `~x~` are defined as a run with no whitespace in it — the
  /// parser's own rule — so a phrase cannot be written that way. Writing it
  /// anyway would produce a document this editor reads back as literal
  /// carets, which is worse than the plain words. Text already containing the
  /// marker is refused for the same reason.
  static bool _canWrap(String text, String marker, {bool tight = false}) =>
      text.isNotEmpty &&
      !text.contains(marker) &&
      (!tight || !text.contains(RegExp(r'\s')));

  /// One declaration out of a `style` attribute.
  static String? _style(String attributes, String property) {
    final style = _attribute(attributes, 'style');
    if (style == null) return null;
    for (final declaration in style.split(';')) {
      final colon = declaration.indexOf(':');
      if (colon < 0) continue;
      if (declaration.substring(0, colon).trim().toLowerCase() != property) {
        continue;
      }
      return declaration.substring(colon + 1).trim().toLowerCase();
    }
    return null;
  }

  /// Whether a `<b>`'s own style contradicts it.
  static bool _styleSaysNotBold(String attributes) {
    final weight = _style(attributes, 'font-weight');
    if (weight == null) return false;
    return !_isBoldWeight(weight);
  }

  static bool _isBoldWeight(String weight) {
    if (weight == 'bold' || weight == 'bolder') return true;
    final number = int.tryParse(weight);
    return number != null && number >= 600;
  }

  /// [text] with whatever the span's style asks for around it.
  static String _wrapStyled(String text, String attributes) {
    if (text.isEmpty) return text;
    var out = text;
    final decoration = _style(attributes, 'text-decoration') ??
        _style(attributes, 'text-decoration-line');
    if (decoration != null && decoration.contains('line-through')) {
      out = '~~$out~~';
    }
    final style = _style(attributes, 'font-style');
    if (style == 'italic' || style == 'oblique') out = '*$out*';
    final weight = _style(attributes, 'font-weight');
    if (weight != null && _isBoldWeight(weight)) out = '**$out**';
    return out;
  }

  /// `[x] ` or `[ ] ` when the item carries a checkbox, and nothing when it
  /// does not.
  static String _taskBox(List<_Token> item) {
    for (final token in item) {
      if (!token.isTag || token.closing || token.name != 'input') continue;
      final type = _attribute(token.attributes, 'type')?.toLowerCase();
      if (type != 'checkbox') continue;
      // `checked` is a boolean attribute: it may be written bare, or as
      // `checked=""`, or as `checked="checked"`. Its presence is what counts.
      final ticked = RegExp(r'(^|\s)checked(\s|=|$)')
          .hasMatch(token.attributes);
      return ticked ? '[x] ' : '[ ] ';
    }
    return '';
  }

  /// The language a `<pre>` block's `<code>` element names, or an empty
  /// string.
  ///
  /// `class="language-dart"` is what GitHub, Prism and highlight.js all
  /// write; `lang-dart` is the older spelling. The class list may hold other
  /// names beside it — highlight.js writes `hljs language-dart`.
  static String _codeLanguage(List<_Token> inner) {
    for (final token in inner) {
      if (!token.isTag || token.closing || token.name != 'code') continue;
      final classes = _attribute(token.attributes, 'class') ?? '';
      for (final name in classes.split(RegExp(r'\s+'))) {
        for (final prefix in const ['language-', 'lang-']) {
          if (name.length > prefix.length && name.startsWith(prefix)) {
            return name.substring(prefix.length);
          }
        }
      }
    }
    return '';
  }

  static String? _attribute(String attributes, String name) {
    final match = RegExp('$name\\s*=\\s*(?:"([^"]*)"|\'([^\']*)\')',
            caseSensitive: false)
        .firstMatch(attributes);
    if (match == null) return null;
    return _decode(match.group(1) ?? match.group(2) ?? '');
  }

  /// Collapses the whitespace HTML would collapse, and decodes entities.
  static String _clean(String text) =>
      _decode(text.replaceAll(RegExp(r'\s+'), ' '));

  static String _decode(String text) => text
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      // Last, or an escaped ampersand would be decoded twice.
      .replaceAll('&amp;', '&');
}

class _Token {
  const _Token.text(this.text)
      : name = '',
        closing = false,
        attributes = '',
        isText = true;

  const _Token.tag({
    required this.name,
    required this.closing,
    required this.attributes,
  })  : text = '',
        isText = false;

  final String text;
  final String name;
  final bool closing;
  final String attributes;
  final bool isText;

  bool get isTag => !isText;
}
