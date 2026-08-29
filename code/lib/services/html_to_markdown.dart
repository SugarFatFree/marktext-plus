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
    text = text.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
    text = text.replaceAll(
        RegExp(r'<(script|style)[^>]*>.*?</\1>',
            dotAll: true, caseSensitive: false),
        '');
    return text;
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
          out.write('```\n${_decode(code).trimRight()}\n```\n\n');
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
        out.write('$marker${_inline(own)}\n');

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
          if (text.isNotEmpty) out.write('**$text**');
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
        default:
          index++;
      }
    }
    return out.toString().trim();
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
