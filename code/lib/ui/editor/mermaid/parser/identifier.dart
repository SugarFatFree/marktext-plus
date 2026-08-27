/// Turns a diagram label into a key usable for node lookup.
///
/// Only whitespace and punctuation are folded away. Every letter, mark and
/// digit is kept, in any script: an ASCII-only allowlist mapped kana, Hangul,
/// Cyrillic, Greek and accented Latin all to the same run of underscores, so
/// two differently-spelled nodes collapsed into one.
library;

/// Anything that is not a letter, combining mark, digit or underscore.
final RegExp _unsafe = RegExp(r'[^\p{L}\p{M}\p{N}_]', unicode: true);

/// Same, but keeping `-`, which entity-relationship names use verbatim.
final RegExp _unsafeKeepingDash = RegExp(r'[^\p{L}\p{M}\p{N}_\-]', unicode: true);

String normalizeMermaidId(String raw, {bool keepDash = false}) {
  return raw.trim().replaceAll(keepDash ? _unsafeKeepingDash : _unsafe, '_');
}
