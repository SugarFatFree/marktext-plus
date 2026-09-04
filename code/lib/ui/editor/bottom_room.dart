/// How much empty space goes under the last line of a document.
///
/// Enough that the end of a document can be scrolled up to where the eye is,
/// instead of staying pinned to the bottom edge of the window.
///
/// One definition, because the source pane and the preview sit side by side in
/// split view: two different amounts and they stop lining up exactly where the
/// reader is looking, at the end of what they are writing.
///
/// A share of the viewport rather than a fixed number — on a tall window a
/// fixed 200 pixels is barely noticeable, and on a short one it is most of the
/// screen — and capped, because a quarter of a very tall window is more empty
/// space than anyone wants to scroll through.
double bottomRoom(double height) => (height * 0.25).clamp(0.0, 500.0);
