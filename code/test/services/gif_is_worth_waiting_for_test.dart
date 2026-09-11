import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:marktext_plus/services/window_capture.dart';

/// How the window's frames are turned into a GIF.
///
/// `encodeGif`'s defaults are a neural-network quantiser with Floyd–Steinberg
/// dithering: right for a photograph, wrong for a window full of flat colour.
/// Measured on ten real screenshots of this editor, recording three seconds
/// took fifty-two seconds on a live client — past the timeout of most callers,
/// which made a tool documented as "five seconds at most" unusable at its own
/// maximum. Dithering a screenshot adds noise to an image that had none, and
/// pays for it twice: in bytes and in accuracy.
///
/// Asserted by size rather than by the clock. A duration would be a limit
/// loose enough to catch nothing on a fast machine and red on its own on a
/// slow one — the reasoning `cost_stays_linear_test` sets out — while the
/// bytes are the same everywhere and carry the same meaning: less noise.
void main() {
  /// Frames that look like this editor, including the part that matters here:
  /// anti-aliased edges.
  ///
  /// A first version drew three flat colours, and both encoders produced byte
  /// for byte the same file — with nothing to smooth, dithering does nothing,
  /// and the test compared a thing against itself. Real text has soft edges,
  /// and it is those the dithering turns into noise.
  List<img.Image> frames(int count) => List.generate(count, (n) {
        final im = img.Image(width: 640, height: 400);
        for (var y = 0; y < 400; y++) {
          for (var x = 0; x < 640; x++) {
            final shade = 236 + ((x + y) ~/ 40) % 20;
            im.setPixelRgb(x, y, shade, shade, shade + 2);
          }
        }
        for (var y = 20; y < 380; y += 18) {
          final width = 120 + ((y * 7 + n * 11) % 400);
          for (var x = 30; x < 30 + width; x++) {
            for (var row = 0; row < 8; row++) {
              // Softer at the ends of each run, the way a glyph is.
              final edge = ((x - 30) < 4 || (30 + width - x) < 4) ? 120 : 0;
              final v = 40 + edge + (row == 0 || row == 7 ? 90 : 0);
              im.setPixelRgb(x, y + row, v, v, v + 4);
            }
          }
        }
        img.fillRect(im,
            x1: 10 + n * 12, y1: 4, x2: 90 + n * 12, y2: 16,
            color: img.ColorRgb8(200, 60, 60));
        return im;
      });

  test('a recording is smaller than the library would have made it', () {
    final ours = WindowCapture.encodeFrames(frames(8), const Duration(milliseconds: 100));

    final animation = frames(8).first;
    animation.frameDuration = 100;
    for (final frame in frames(8).skip(1)) {
      frame.frameDuration = 100;
      animation.addFrame(frame);
    }
    final defaults = img.encodeGif(animation);

    expect(ours.length, lessThan(defaults.length),
        reason: '抖动给平涂界面加的是噪点，噪点要占字节——'
            '${ours.length} vs ${defaults.length}');
  });

  test('and it is a GIF with every frame in it', () {
    final bytes = WindowCapture.encodeFrames(frames(5), const Duration(milliseconds: 100));

    expect(bytes.take(6), 'GIF89a'.codeUnits);
    final decoded = img.decodeGif(Uint8List.fromList(bytes));
    expect(decoded, isNotNull);
    expect(decoded!.numFrames, 5, reason: '录了五帧就要有五帧');
    expect(decoded.width, 640);
  });

  test('one frame still makes a file', () {
    // The capture loop falls back to a single frame when the window would not
    // give it more, and an encoder that returns null there would turn that
    // into a crash rather than a short recording.
    final bytes = WindowCapture.encodeFrames(frames(1), const Duration(milliseconds: 100));
    expect(bytes.take(6), 'GIF89a'.codeUnits);
    expect(img.decodeGif(Uint8List.fromList(bytes))!.numFrames, 1);
  });
}
