import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/image_service.dart';

void main() {
  late Directory root;
  late Directory docDir;
  late String doc;
  late String source;

  setUp(() {
    root = Directory.systemTemp.createTempSync('image_test_');
    docDir = Directory('${root.path}/notes')..createSync(recursive: true);
    doc = '${docDir.path}/note.md';
    File(doc).writeAsStringSync('# note');
    source = '${root.path}/picture.png';
    File(source).writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() => root.deleteSync(recursive: true));

  group('ImageStorageMode.fromConfig', () {
    test('reads the three known values', () {
      expect(ImageStorageMode.fromConfig('copy'), ImageStorageMode.copy);
      expect(ImageStorageMode.fromConfig('folder'), ImageStorageMode.folder);
      expect(ImageStorageMode.fromConfig('link'), ImageStorageMode.link);
    });

    test('falls back to copying rather than losing the image', () {
      expect(ImageStorageMode.fromConfig(''), ImageStorageMode.copy);
      expect(ImageStorageMode.fromConfig('nonsense'), ImageStorageMode.copy);
    });
  });

  group('ImageService.storeImage', () {
    test('copies beside the document by default', () async {
      final link = await ImageService.storeImage(source, doc);

      expect(link, startsWith('assets/images/picture_'));
      expect(File('${docDir.path}/$link').existsSync(), isTrue);
    });

    test('link mode references the file in place and copies nothing', () async {
      final before = docDir.listSync().length;
      final link = await ImageService.storeImage(
        source,
        doc,
        mode: ImageStorageMode.link,
      );

      expect(link, '../picture.png');
      expect(docDir.listSync().length, before);
    });

    test('a relative shared folder is relative to the document', () async {
      final link = await ImageService.storeImage(
        source,
        doc,
        mode: ImageStorageMode.folder,
        folder: 'media',
      );

      expect(link, startsWith('media/picture_'));
      expect(File('${docDir.path}/$link').existsSync(), isTrue);
    });

    test('an absolute shared folder is shared across documents', () async {
      final shared = '${root.path}/shared';
      final link = await ImageService.storeImage(
        source,
        doc,
        mode: ImageStorageMode.folder,
        folder: shared,
      );

      expect(File('${docDir.path}/$link').existsSync(), isTrue);
      expect(Directory(shared).listSync(), hasLength(1));
    });

    test('an unsaved document keeps the original path', () async {
      // There is nowhere to copy to, and inventing a location would put the
      // image somewhere the user will never find it.
      expect(await ImageService.storeImage(source, null), source);
    });

    test('a blank folder setting does not create a nameless directory', () async {
      final link = await ImageService.storeImage(
        source,
        doc,
        mode: ImageStorageMode.folder,
        folder: '   ',
      );

      expect(link, source);
    });

    test('several images dropped at once do not overwrite each other', () async {
      // The name carries a millisecond timestamp, and copying is faster than
      // the clock ticks, so a multi-file drop used to leave only the last one.
      final links = <String>[];
      for (var i = 0; i < 5; i++) {
        links.add(await ImageService.storeImage(source, doc));
      }

      expect(links.toSet(), hasLength(5));
      for (final link in links) {
        expect(File('${docDir.path}/$link').existsSync(), isTrue);
      }
    });
  });

  group('ImageService.isImageFile', () {
    test('recognises the common formats regardless of case', () {
      expect(ImageService.isImageFile('a.PNG'), isTrue);
      expect(ImageService.isImageFile('a.jpeg'), isTrue);
      expect(ImageService.isImageFile('a.webp'), isTrue);
      expect(ImageService.isImageFile('a.md'), isFalse);
      expect(ImageService.isImageFile('a'), isFalse);
    });
  });
}
