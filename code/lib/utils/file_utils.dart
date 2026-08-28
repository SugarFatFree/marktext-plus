import 'package:path/path.dart' as p;

class FileUtils {
  FileUtils._();

  /// The file types this editor opens, without their leading dot.
  ///
  /// One list, because there were six: the startup argument filter, the
  /// sidebar's search, `FileNode.isMarkdown`, and three file pickers each had
  /// their own copy. They happened to agree, but adding a type meant editing
  /// six places, and the one that was forgotten would fail in its own
  /// particular way — a file that opens but cannot be found by search, or one
  /// the picker will not show.
  ///
  /// `mmd`, `mdown`, `mdtxt` and `mdtext` are what upstream MarkText registers
  /// as well. `txt` is ours: the editor opens plain text, and the installer
  /// only offers this app for it rather than claiming it.
  /// Every extension this editor treats as a markdown document.
  ///
  /// The same eleven upstream MarkText accepts (`MARKDOWN_EXTENSIONS` in
  /// `common/filesystem/paths.ts`), plus `mmd`. A file the upstream editor
  /// opens and this one refuses is a parity gap the reader meets as a double
  /// click that does nothing.
  static const markdownExtensions = <String>[
    'markdown',
    'mdown',
    'mkdn',
    'md',
    'mkd',
    'mdwn',
    'mdtxt',
    'mdtext',
    'mdx',
    'mmd',
    'text',
    'txt',
  ];

  /// The same list with leading dots, which is how [getExtension] reports them.
  static final markdownExtensionsWithDot =
      List<String>.unmodifiable(markdownExtensions.map((e) => '.$e'));

  static String getFileName(String path) => p.basename(path);

  static String getExtension(String path) => p.extension(path).toLowerCase();

  static bool isMarkdownFile(String path) =>
      markdownExtensionsWithDot.contains(getExtension(path));
}
