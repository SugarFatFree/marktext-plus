import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/bottom_room.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// The room under the last line, which both panes leave.
///
/// In split view they sit side by side, so two different amounts stop them
/// lining up exactly where the reader is looking: at the end of what they are
/// writing. One definition, used by both.
void main() {
  test('the preview asks the same function the source pane does', () {
    for (final height in [400.0, 900.0, 1600.0, 4000.0]) {
      expect(MarkdownRenderer.bottomRoomForHeight(height), bottomRoom(height),
          reason: '两个窗格必须问同一个函数，否则迟早会分道扬镳');
    }
  });

  test('it is a share of the viewport, not a fixed number', () {
    // A fixed 200 pixels is barely noticeable on a tall window and most of the
    // screen on a short one.
    expect(bottomRoom(800), 200);
    expect(bottomRoom(400), 100);
  });

  test('it is capped, so a very tall window is not mostly emptiness', () {
    expect(bottomRoom(4000), 500);
  });

  test('a window of no height asks for no room', () {
    expect(bottomRoom(0), 0);
  });

  testWidgets('the source pane leaves room to scroll the last line up', (
    tester,
  ) async {
    // Measured rather than asserted on the padding value: what matters is that
    // the end of the document can be brought up to where the eye is.
    Future<double> scrollableWith(double bottom) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: TextField(
                controller: TextEditingController(
                  text: List.generate(80, (i) => 'line $i').join('\n'),
                ),
                scrollController: controller,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottom),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return controller.position.maxScrollExtent;
    }

    final without = await scrollableWith(0);
    final with200 = await scrollableWith(200);
    expect(with200 - without, closeTo(200, 1),
        reason: 'InputDecoration 的底部内边距确实会一比一撑长可滚动范围——'
            '早先的注释把这件事说反了');
  });
}
