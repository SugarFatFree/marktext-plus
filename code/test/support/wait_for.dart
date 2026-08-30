/// Waits until [condition] holds, or gives up after [within].
///
/// A fixed sleep is a bet that a chain of asynchronous work — a timer, a
/// stat, an encode, a write, a rename — finishes inside a chosen number of
/// milliseconds. That bet is won on a developer's machine and lost on a
/// loaded CI runner, where it reads as a failure of the thing under test
/// rather than of the waiting: `tab_reload_test` failed twice on CI and never
/// locally before this existed.
///
/// Polling asks the question instead of guessing the answer, and costs
/// nothing when the condition is already true. The generous deadline is for
/// the slow case only; a passing test returns as soon as it can.
///
/// Returns whether the condition ended up true, so a caller may assert on it
/// — though asserting the real thing afterwards gives a better message.
Future<bool> waitFor(
  bool Function() condition, {
  Duration within = const Duration(seconds: 5),
  Duration poll = const Duration(milliseconds: 20),
}) async {
  final deadline = DateTime.now().add(within);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return true;
    await Future<void>.delayed(poll);
  }
  return condition();
}
