import 'markdown_parser.dart';

/// Moving a block of markdown up or down past its neighbour.
///
/// Upstream MarkText reorders by dragging a paragraph over another — its
/// `drag/paragraph-reorder` spec asks only that the two swap places in the
/// markdown. This editor works on the source, so the same reordering is a
/// command: the block under the caret trades places with the one before or
/// after it.
///
/// Block, not line, because that is what upstream reorders and because a
/// markdown block is what a person means by "this bit". A list item, a fenced
/// code block and a table each move whole. A selection spanning several lines
/// moves exactly those lines instead, so line-level control is still there for
/// anyone who wants it.
///
/// Free of Flutter so it can be tested directly, and so the menu and the
/// editor ask the same question of the same code.
class BlockMoveService {
  const BlockMoveService._();

  /// The lines a move would pick up, given where the caret and the selection
  /// are, as a half-open `[start, end)` range of line indices.
  ///
  /// Returns null when there is nothing to move — an empty document.
  static ({int start, int end})? span(
    String text,
    int baseOffset,
    int extentOffset,
  ) {
    final lines = text.split('\n');
    if (lines.isEmpty) return null;
    final from = baseOffset <= extentOffset ? baseOffset : extentOffset;
    final to = baseOffset <= extentOffset ? extentOffset : baseOffset;
    final firstLine = _lineOf(lines, from);
    final lastLine = _lineOf(lines, to);

    // A selection touching more than one line moves exactly those lines.
    if (lastLine > firstLine) {
      return (start: firstLine, end: lastLine + 1);
    }

    // Otherwise the whole block the caret is in. Asking the parser rather
    // than guessing keeps a fenced code block — whose blank lines look like
    // block boundaries — together.
    for (final node in MarkdownParser().parse(text)) {
      if (firstLine >= node.sourceStart && firstLine < node.sourceEnd) {
        return (start: node.sourceStart, end: node.sourceEnd);
      }
    }
    // A blank line between blocks belongs to no block; move it alone.
    return (start: firstLine, end: firstLine + 1);
  }

  /// Moves the block or lines at the caret one place [up], returning the new
  /// text and where the selection should follow it, or null if there is
  /// nothing on that side to trade places with.
  ///
  /// The blank lines between two blocks stay between them. Treating a blank
  /// line as the neighbour would make the first press do nothing visible and
  /// require a second one.
  static ({String text, int base, int extent})? move(
    String text,
    int baseOffset,
    int extentOffset, {
    required bool up,
  }) {
    final lines = text.split('\n');
    final found = span(text, baseOffset, extentOffset);
    if (found == null) return null;
    final start = found.start;

    // A document ending in a newline splits to a trailing empty string. It is
    // not a line anyone can move onto, and counting it would let a block slide
    // past the end of the file and pick up a blank line on the way.
    var limit = lines.length;
    if (limit > 0 && lines.last.isEmpty) limit--;
    final end = found.end > limit ? limit : found.end;
    if (start >= end) return null;

    // Two modes, and the difference is the selection. A selection says which
    // lines to move, so it trades with one line. A caret says which block, so
    // it trades with the whole block on the other side.
    final byLine = baseOffset != extentOffset;

    final int nStart;
    final int nEnd;
    if (byLine) {
      if (up) {
        if (start == 0) return null;
        nStart = start - 1;
        nEnd = start;
      } else {
        if (end >= limit) return null;
        nStart = end;
        nEnd = end + 1;
      }
    } else {
      final neighbour = up
          ? _blockBefore(text, start, limit)
          : _blockAfter(text, end, limit);
      if (neighbour == null) return null;
      nStart = neighbour.start;
      nEnd = neighbour.end;
    }

    // Everything between the two — blank lines, usually — keeps its place in
    // the middle.
    final gap = up
        ? lines.sublist(nEnd, start)
        : lines.sublist(end, nStart);
    final block = lines.sublist(start, end);
    final other = lines.sublist(nStart, nEnd);

    final List<String> rebuilt;
    final int newStart;
    if (up) {
      rebuilt = [
        ...lines.sublist(0, nStart),
        ...block,
        ...gap,
        ...other,
        ...lines.sublist(end),
      ];
      newStart = nStart;
    } else {
      rebuilt = [
        ...lines.sublist(0, start),
        ...other,
        ...gap,
        ...block,
        ...lines.sublist(nEnd),
      ];
      newStart = start + other.length + gap.length;
    }

    final newText = rebuilt.join('\n');
    final base = _offsetOfLine(rebuilt, newStart);
    if (baseOffset == extentOffset) {
      return (text: newText, base: base, extent: base);
    }
    final lastMoved = newStart + block.length - 1;
    final extent = _offsetOfLine(rebuilt, lastMoved) +
        (lastMoved < rebuilt.length ? rebuilt[lastMoved].length : 0);
    return (text: newText, base: base, extent: extent);
  }

  /// The last block that ends at or before [line].
  static ({int start, int end})? _blockBefore(String text, int line, int limit) {
    ({int start, int end})? best;
    for (final node in MarkdownParser().parse(text)) {
      if (node.sourceEnd <= line && node.sourceStart < node.sourceEnd) {
        best = (
          start: node.sourceStart,
          end: node.sourceEnd > limit ? limit : node.sourceEnd,
        );
      }
    }
    return best;
  }

  /// The first block that starts at or after [line].
  static ({int start, int end})? _blockAfter(String text, int line, int limit) {
    for (final node in MarkdownParser().parse(text)) {
      if (node.sourceStart >= line && node.sourceStart < limit) {
        return (
          start: node.sourceStart,
          end: node.sourceEnd > limit ? limit : node.sourceEnd,
        );
      }
    }
    return null;
  }

  static int _lineOf(List<String> lines, int offset) {
    var remaining = offset;
    for (var i = 0; i < lines.length; i++) {
      if (remaining <= lines[i].length) return i;
      remaining -= lines[i].length + 1;
    }
    return lines.length - 1;
  }

  static int _offsetOfLine(List<String> lines, int line) {
    var offset = 0;
    for (var i = 0; i < line && i < lines.length; i++) {
      offset += lines[i].length + 1;
    }
    return offset;
  }
}
