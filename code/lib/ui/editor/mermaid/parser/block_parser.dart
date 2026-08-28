/// Parser for block diagrams
library;

import '../models/block_diagram.dart';
import '../models/diagram.dart';
import '../models/node.dart';

/// Parser for Mermaid block diagrams (`block-beta`).
///
/// A grid rather than a graph: `columns n` sets the width, each following line
/// lists the blocks that fill it, and the rows wrap on their own.
class BlockParser {
  /// Creates a block diagram parser.
  const BlockParser();

  /// `columns 3`
  static final _columnsRe = RegExp(r'^columns\s+(\d+)$', caseSensitive: false);

  /// `a --> b`, optionally `a -- "label" --> b` or `a -->|label| b`.
  static final _arrowRe = RegExp(
    r'^(\S+)\s*(?:--\s*"([^"]*)"\s*)?-{1,2}>\s*(?:\|([^|]*)\|\s*)?(\S+)$',
  );

  /// A block: an id, an optional bracketed label, and an optional `:span`.
  ///
  /// The two-character brackets are listed before the one-character ones:
  /// alternation takes the first that matches, so `[[` written after `[`
  /// would never be reached and `f[["Stadium"]]` would keep a stray bracket.
  static final _blockRe = RegExp(
    r'^([^\s\[\](){}<>:"]+)'
    r'(?:(\[\(|\[\[|\[|\(\[|\(\(|\(|\{\{|\{|>)'
    r'(.*?)(\)\]|\]\]|\]\)|\]|\)\)|\)|\}\}|\}))?'
    r'(?::(\d+))?$',
  );

  /// Parses a block diagram from cleaned lines.
  ///
  /// Returns null when there is nothing to draw, so the renderer can fall back
  /// to showing the source rather than an empty box.
  (MermaidDiagramData, BlockDiagramData)? parse(List<String> lines) {
    if (lines.isEmpty) return null;

    var columns = 1;
    var columnsGiven = false;
    final items = <BlockItem>[];
    final arrows = <BlockArrow>[];
    var spaceCount = 0;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.toLowerCase().startsWith('block-beta')) continue;
      // A nested `block:group … end` is not laid out as a sub-grid yet; its
      // contents are placed in the outer grid rather than dropped.
      if (line.toLowerCase() == 'end' ||
          line.toLowerCase().startsWith('block:')) {
        continue;
      }
      if (line.toLowerCase().startsWith('style ') ||
          line.toLowerCase().startsWith('classdef ') ||
          line.toLowerCase().startsWith('class ')) {
        continue;
      }

      final columnsMatch = _columnsRe.firstMatch(line);
      if (columnsMatch != null) {
        columns = int.tryParse(columnsMatch.group(1)!) ?? 1;
        columnsGiven = true;
        continue;
      }

      final arrow = _arrowRe.firstMatch(line);
      if (arrow != null) {
        arrows.add(
          BlockArrow(
            from: arrow.group(1)!,
            to: arrow.group(4)!,
            label: arrow.group(2) ?? arrow.group(3),
          ),
        );
        continue;
      }

      for (final token in _splitBlocks(line)) {
        final item = _parseBlock(token, spaceCount);
        if (item == null) continue;
        if (item.isSpace) spaceCount++;
        items.add(item);
      }
    }

    if (items.isEmpty) return null;

    return (
      MermaidDiagramData(
        type: DiagramType.blockDiagram,
        nodes: const [],
        edges: const [],
      ),
      BlockDiagramData(
        // Without `columns`, mermaid puts everything on one row.
        columns: columnsGiven ? columns : items.length,
        items: items,
        arrows: arrows,
      ),
    );
  }

  /// Splits a row into its blocks.
  ///
  /// Not `split(' ')`: a label may hold spaces — `a["Two words"] b` is two
  /// blocks — so brackets and quotes are tracked and only a space outside
  /// both separates.
  List<String> _splitBlocks(String line) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    var depth = 0;
    var inQuote = false;

    for (var i = 0; i < line.length; i++) {
      final c = line[i];

      if (c == '"') {
        inQuote = !inQuote;
        buffer.write(c);
        continue;
      }
      if (!inQuote) {
        if (c == '[' || c == '(' || c == '{') depth++;
        if (c == ']' || c == ')' || c == '}') depth--;
        if (c == ' ' && depth <= 0) {
          if (buffer.isNotEmpty) tokens.add(buffer.toString());
          buffer.clear();
          continue;
        }
      }
      buffer.write(c);
    }

    if (buffer.isNotEmpty) tokens.add(buffer.toString());
    return tokens;
  }

  BlockItem? _parseBlock(String token, int spaceIndex) {
    final spaceMatch = RegExp(
      r'^space(?::(\d+))?$',
      caseSensitive: false,
    ).firstMatch(token);
    if (spaceMatch != null) {
      return BlockItem(
        id: '__space_$spaceIndex',
        label: '',
        span: int.tryParse(spaceMatch.group(1) ?? '') ?? 1,
        isSpace: true,
      );
    }

    final match = _blockRe.firstMatch(token);
    if (match == null) return null;

    final id = match.group(1)!;
    final open = match.group(2);
    final label = _unquote(match.group(3)?.trim() ?? '');

    return BlockItem(
      id: id,
      label: label.isEmpty ? id : label,
      shape: _shapeFor(open),
      span: int.tryParse(match.group(5) ?? '') ?? 1,
    );
  }

  NodeShape _shapeFor(String? open) => switch (open) {
    '[(' => NodeShape.cylinder,
    '([' => NodeShape.stadium,
    '(' => NodeShape.roundedRect,
    '((' => NodeShape.circle,
    '[[' => NodeShape.subroutine,
    '{' => NodeShape.diamond,
    '{{' => NodeShape.hexagon,
    '>' => NodeShape.parallelogram,
    _ => NodeShape.rectangle,
  };

  String _unquote(String text) {
    if (text.length >= 2 && text.startsWith('"') && text.endsWith('"')) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }
}
