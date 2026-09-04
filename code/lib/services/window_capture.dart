import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

/// Pictures of the editor window.
///
/// The window is drawn under a [RepaintBoundary] whose key lives here, so
/// anything that wants a picture asks this rather than reaching into the
/// widget tree. Nothing else in the application knows it is being watched.
class WindowCapture {
  WindowCapture({this.pixelRatio = 1.0});

  /// Attached to the boundary wrapped around the whole window.
  static final GlobalKey boundary = GlobalKey(debugLabel: 'window-capture');

  /// One device pixel per logical pixel by default: a screenshot is for
  /// looking at, and a retina-sized PNG of a whole window is megabytes of
  /// base64 down a socket.
  final double pixelRatio;

  bool get available => _renderer != null;

  RenderRepaintBoundary? get _renderer {
    final object = boundary.currentContext?.findRenderObject();
    return object is RenderRepaintBoundary ? object : null;
  }

  /// The window as a PNG.
  Future<List<int>> png() async {
    final image = await _snap();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('the window would not encode');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// The window over [length], as an animated GIF.
  ///
  /// Frames are taken on a timer rather than from the engine's frame callback:
  /// what is wanted is an animation at a watchable rate, not every frame the
  /// editor happened to draw.
  Future<List<int>> gif(Duration length, int fps) async {
    final interval = Duration(microseconds: (1000000 / fps).round());
    final frames = <img.Image>[];
    final deadline = DateTime.now().add(length);

    while (DateTime.now().isBefore(deadline)) {
      frames.add(await _frame());
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) break;
      await Future<void>.delayed(remaining < interval ? remaining : interval);
    }
    if (frames.isEmpty) frames.add(await _frame());

    final animation = frames.first;
    animation.frameDuration = interval.inMilliseconds;
    for (final frame in frames.skip(1)) {
      frame.frameDuration = interval.inMilliseconds;
      animation.addFrame(frame);
    }
    return img.encodeGif(animation);
  }

  Future<img.Image> _frame() async {
    final image = await _snap();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) throw StateError('the window would not encode');
      return img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: data.buffer,
        numChannels: 4,
      );
    } finally {
      image.dispose();
    }
  }

  Future<ui.Image> _snap() async {
    final renderer = _renderer;
    if (renderer == null) {
      throw StateError('the window is not on screen; is the editor running?');
    }
    return renderer.toImage(pixelRatio: pixelRatio);
  }
}
