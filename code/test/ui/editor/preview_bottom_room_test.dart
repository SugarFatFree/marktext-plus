import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

void main() {
  test('preview reserves one quarter of the viewport below the document', () {
    expect(MarkdownRenderer.bottomRoomForHeight(800), 200);
    expect(MarkdownRenderer.bottomRoomForHeight(2000), 500);
  });
}
