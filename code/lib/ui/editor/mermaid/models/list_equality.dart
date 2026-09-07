/// Comparing the lists a diagram's data is made of.
library;

/// Whether [a] and [b] hold equal elements in the same order.
///
/// Every diagram model needs this, because `==` on two Dart lists asks
/// whether they are the same object — and a diagram parsed twice from the
/// same text produces two lists that are equal and not identical. A painter
/// that decides whether to repaint from `data != oldData` gets the wrong
/// answer either way round: the wrong one is a chart still showing the
/// numbers it was edited away from.
///
/// This was written seven times, once inside each model that needed it, under
/// four different names. Nothing made them disagree yet; the reason to have
/// one is that nothing was going to stop them.
bool sameList<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
