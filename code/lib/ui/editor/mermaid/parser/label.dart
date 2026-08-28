/// Turns the text between a diagram's delimiters into what should be drawn.
///
/// Every diagram type writes labels the same way, and each parser was doing
/// its own part of the job: node labels lost their quotes, edge labels kept
/// them, and nothing anywhere understood `<br/>` — the way every mermaid
/// document wraps text inside a box — so the tag was drawn as characters.
library;

/// `<br>`, `<br/>`, `<br />`, in any case.
final RegExp _lineBreak = RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false);

/// The entities a diagram is likely to carry. `&amp;` comes last on purpose:
/// decoding it first would turn `&amp;lt;` into `<`.
const _entities = <String, String>{
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&#39;': "'",
  '&apos;': "'",
  '&nbsp;': ' ',
  '&amp;': '&',
};

/// The label as written, ready to draw.
///
/// Unescapes quotes, drops the pair that delimits the label, turns `<br/>`
/// into a real line break and decodes the handful of entities a diagram
/// carries. Order matters: quotes are stripped before entities are decoded,
/// so a label written `"&quot;quoted&quot;"` keeps its inner quotes.
String cleanLabel(String? raw) {
  if (raw == null) return '';
  var label = raw.replaceAll('\\"', '"').replaceAll("\\'", "'");
  label = _stripDelimiters(label);
  label = label.replaceAll(_lineBreak, '\n');
  for (final entry in _entities.entries) {
    label = label.replaceAll(entry.key, entry.value);
  }
  return label;
}

/// Strips the quotes mermaid uses to wrap a label containing a bracket,
/// comma or space. They are delimiters, not content.
String _stripDelimiters(String label) {
  final trimmed = label.trim();
  if (trimmed.length >= 2 &&
      ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
          (trimmed.startsWith("'") && trimmed.endsWith("'")))) {
    return trimmed.substring(1, trimmed.length - 1);
  }
  return label;
}
