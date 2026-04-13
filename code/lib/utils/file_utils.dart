import 'package:path/path.dart' as p;

class FileUtils {
  FileUtils._();

  static String getFileName(String path) => p.basename(path);

  static String getExtension(String path) => p.extension(path).toLowerCase();

  static bool isMarkdownFile(String path) {
    final ext = getExtension(path);
    return ['.md', '.markdown', '.txt'].contains(ext);
  }
}
