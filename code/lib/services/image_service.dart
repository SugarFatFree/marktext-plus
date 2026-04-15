import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pasteboard/pasteboard.dart';

class ImageService {
  static const _imageExtensions = {'.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.svg'};

  static bool isImageFile(String filePath) {
    return _imageExtensions.contains(path.extension(filePath).toLowerCase());
  }

  /// Reads image from clipboard and saves it. Returns relative path (or absolute if mdFilePath is null).
  static Future<String?> pasteImageFromClipboard(String? mdFilePath) async {
    final Uint8List? imageBytes = await Pasteboard.image;
    if (imageBytes == null) return null;

    const ext = '.png';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'image_$timestamp$ext';

    if (mdFilePath != null) {
      final mdDir = path.dirname(mdFilePath);
      final imageDir = path.join(mdDir, 'assets', 'images');
      await Directory(imageDir).create(recursive: true);
      final targetPath = path.join(imageDir, fileName);
      await File(targetPath).writeAsBytes(imageBytes);
      return path.relative(targetPath, from: mdDir);
    } else {
      final tmpDir = await getTemporaryDirectory();
      final targetPath = path.join(tmpDir.path, fileName);
      await File(targetPath).writeAsBytes(imageBytes);
      return targetPath;
    }
  }

  /// Copies an image file to the project's assets/images directory. Returns relative path.
  static Future<String> copyImageToProject(String imagePath, String mdFilePath) async {
    final mdDir = path.dirname(mdFilePath);
    final imageDir = path.join(mdDir, 'assets', 'images');
    await Directory(imageDir).create(recursive: true);

    final ext = path.extension(imagePath);
    final baseName = path.basenameWithoutExtension(imagePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newName = '${baseName}_$timestamp$ext';
    final targetPath = path.join(imageDir, newName);

    await File(imagePath).copy(targetPath);
    return path.relative(targetPath, from: mdDir);
  }
}
