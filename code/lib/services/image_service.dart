import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pasteboard/pasteboard.dart';

/// Where a dropped or pasted image should end up.
enum ImageStorageMode {
  /// Copy it into a folder beside the document.
  copy,

  /// Copy it into one folder shared by every document.
  folder,

  /// Leave it where it is and link to it.
  link;

  /// Reads the mode out of its stored string, falling back to [copy] for an
  /// unknown value rather than losing the image.
  static ImageStorageMode fromConfig(String value) {
    switch (value) {
      case 'folder':
        return ImageStorageMode.folder;
      case 'link':
        return ImageStorageMode.link;
      default:
        return ImageStorageMode.copy;
    }
  }
}

class ImageService {
  static const _imageExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.bmp',
    '.webp',
    '.svg',
  };

  /// Folder used beside a document when no other folder is configured.
  static const defaultFolder = 'assets/images';

  static bool isImageFile(String filePath) {
    return _imageExtensions.contains(path.extension(filePath).toLowerCase());
  }

  /// Reads an image from the clipboard and stores it according to [mode].
  ///
  /// Returns the path to write into the markdown — relative to the document
  /// where that is possible, absolute otherwise — or null when the clipboard
  /// holds no image.
  static Future<String?> pasteImageFromClipboard(
    String? mdFilePath, {
    ImageStorageMode mode = ImageStorageMode.copy,
    String folder = defaultFolder,
  }) async {
    final Uint8List? imageBytes = await Pasteboard.image;
    if (imageBytes == null) return null;

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // A pasted image has no file of its own, so it has to be written
    // somewhere even in link mode.
    final directory = await _targetDirectory(mdFilePath, mode, folder);
    if (directory == null) {
      final tmpDir = await getTemporaryDirectory();
      final targetPath = _unusedPath(tmpDir.path, 'image_$timestamp', '.png');
      await File(targetPath).writeAsBytes(imageBytes);
      return targetPath;
    }

    await Directory(directory).create(recursive: true);
    final targetPath = _unusedPath(directory, 'image_$timestamp', '.png');
    await File(targetPath).writeAsBytes(imageBytes);
    return _linkFor(targetPath, mdFilePath);
  }

  /// Stores [imagePath] according to [mode] and returns the path to link.
  static Future<String> storeImage(
    String imagePath,
    String? mdFilePath, {
    ImageStorageMode mode = ImageStorageMode.copy,
    String folder = defaultFolder,
  }) async {
    if (mode == ImageStorageMode.link) {
      return _linkFor(imagePath, mdFilePath);
    }

    final directory = await _targetDirectory(mdFilePath, mode, folder);
    if (directory == null) return imagePath;

    await Directory(directory).create(recursive: true);

    final ext = path.extension(imagePath);
    final baseName = path.basenameWithoutExtension(imagePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetPath = _unusedPath(directory, '${baseName}_$timestamp', ext);

    await File(imagePath).copy(targetPath);
    return _linkFor(targetPath, mdFilePath);
  }

  /// A path in [directory] that no file occupies yet.
  ///
  /// The millisecond timestamp is not enough on its own: dropping several
  /// images at once copies them faster than the clock ticks, and the later
  /// ones would silently overwrite the earlier.
  static String _unusedPath(String directory, String stem, String ext) {
    var candidate = path.join(directory, '$stem$ext');
    var counter = 1;
    while (File(candidate).existsSync()) {
      candidate = path.join(directory, '$stem-$counter$ext');
      counter++;
    }
    return candidate;
  }

  /// Resolves the directory images go into, or null when there is nowhere
  /// sensible — an unsaved document with no shared folder configured.
  static Future<String?> _targetDirectory(
    String? mdFilePath,
    ImageStorageMode mode,
    String folder,
  ) async {
    if (mode == ImageStorageMode.folder) {
      final trimmed = folder.trim();
      if (trimmed.isEmpty) return null;
      // A relative shared folder is still relative to the document; only an
      // absolute one is genuinely shared across projects.
      if (path.isAbsolute(trimmed)) return trimmed;
      if (mdFilePath == null) return null;
      return path.join(path.dirname(mdFilePath), trimmed);
    }

    if (mdFilePath == null) return null;
    return path.join(path.dirname(mdFilePath), defaultFolder);
  }

  /// Relative to the document when both share a root, absolute otherwise.
  ///
  /// A relative path computed across drives or roots comes out as a chain of
  /// `..` segments that no longer resolves, so those stay absolute.
  static String _linkFor(String target, String? mdFilePath) {
    if (mdFilePath == null) return toMarkdownSeparators(target);
    final mdDir = path.dirname(mdFilePath);
    if (path.rootPrefix(path.absolute(target)) !=
        path.rootPrefix(path.absolute(mdDir))) {
      return toMarkdownSeparators(target);
    }
    return toMarkdownSeparators(path.relative(target, from: mdDir));
  }

  /// Wraps a link for use as a markdown destination.
  ///
  /// A bare destination cannot contain a space: `![](my photo.png)` is not an
  /// image at all, it is that text. Angle brackets are how CommonMark says to
  /// write one that does — and the parser here reads them. This matters
  /// because the names come from the reader's own files, and on Windows a
  /// screenshot arrives called "屏幕截图 2026-08-28.png".
  ///
  /// Percent-encoding is the fallback for the one case brackets cannot cover:
  /// a path that already contains `>`.
  static String markdownDestination(String link) {
    if (!link.contains(RegExp(r'\s'))) return link;
    if (!link.contains('>')) return '<$link>';
    return link.replaceAll(' ', '%20');
  }

  /// Rewrites a filesystem path for use inside a markdown link.
  ///
  /// A markdown link is a URL, and Windows' backslash is an escape character
  /// there: `assets\_private\a.png` loses its separator to the escape rule
  /// and stops resolving, and even where it survives the document only works
  /// on the machine that wrote it. Forward slashes resolve on Windows too.
  ///
  /// [separator] is a parameter so the Windows behaviour can be tested from
  /// any platform.
  @visibleForTesting
  static String toMarkdownSeparators(String value, {String? separator}) {
    // Not written as a default parameter value: `path.separator` is decided
    // at runtime, and a default has to be a compile-time constant.
    final actual = separator ?? path.separator;
    return actual == '/' ? value : value.replaceAll(actual, '/');
  }
}
