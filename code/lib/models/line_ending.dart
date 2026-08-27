/// The line ending a document uses on disk.
///
/// The editor holds text in LF regardless; this records what to write back.
/// Normalising on read and then saving LF rewrites every line of a CRLF file,
/// which turns a one-word edit into a whole-file diff.
enum LineEnding {
  lf('LF', '\n'),
  crlf('CRLF', '\r\n');

  const LineEnding(this.label, this.sequence);

  /// What the status bar shows.
  final String label;

  /// The characters written between lines.
  final String sequence;

  /// The convention [raw] uses, as read from disk.
  ///
  /// A file with no line break at all counts as LF: there is nothing to
  /// preserve, and LF is the sane default for a new document.
  static LineEnding detect(String raw) =>
      raw.contains('\r\n') ? LineEnding.crlf : LineEnding.lf;

  /// Rewrites [content], which is in LF, using this convention.
  String apply(String content) =>
      this == LineEnding.lf ? content : content.replaceAll('\n', '\r\n');
}
