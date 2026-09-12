import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tab_info.dart';
import '../services/markdown_parser.dart';
import 'tab_provider.dart';

/// One heading in the document's outline.
typedef OutlineEntry = ({int line, int level, String text});

/// Debouncing fixed the frequency; it left the cost where it was.
///
/// Measured here: 4.7 MB over 160,000 lines takes 184 ms, which is the word
/// count's 176 ms in a different place. That comparison is not a coincidence —
/// the note on the old version said this was "the same shape of problem" as
/// the word count and pointed at it for the debounce. The word count moved off
/// this isolate and this one stayed, which is how a sibling gets left behind
/// even when a comment names it.
///
/// **No size threshold, unlike the word count.** That one costs what the
/// document weighs, so bytes decide it. This costs what the document has
/// *lines*: 8.8 MB in 900 long lines is 46 ms, while 1.1 MB in 160,000 short
/// ones is 216 ms. A byte threshold would be the wrong question asked cheaply,
/// and counting lines to ask the right one costs a scan of its own — against
/// a spawn measured at 0.4–1.1 ms.
class OutlineNotifier extends StateNotifier<List<OutlineEntry>> {
  /// Watches the active document.
  ///
  /// [compute] is a parameter so a test can hold one outline open while the
  /// next document arrives. That window is what the staleness check exists
  /// for, and racing a real computation against the debounce would mean a
  /// document large enough to take longer than 300 ms — which on a faster
  /// machine closes the window and leaves the test green having shown nothing.
  OutlineNotifier(
    this._ref, {
    Future<List<OutlineEntry>> Function(String)? compute,
  })  : _compute = compute ?? _offThread,
        super(const []) {
    _ref.listen<TabInfo?>(activeTabProvider, (previous, next) {
      final content = next?.content ?? '';
      if (content == _lastContent) return;
      _lastContent = content;
      _schedule(content);
    }, fireImmediately: true);
  }

  final Ref _ref;
  final Future<List<OutlineEntry>> Function(String) _compute;
  Timer? _debounce;
  String? _lastContent;

  /// The headings, found somewhere the window will not feel it.
  ///
  /// An isolate that will not spawn is not a reason to show no outline: the
  /// fallback does the work here, slowly, rather than leaving the panel empty.
  /// The real off-isolate computation, reachable by name so a test can hold
  /// it to the same answer the synchronous one gives.
  @visibleForTesting
  static Future<List<OutlineEntry>> computeForTest(String content) =>
      _offThread(content);

  static Future<List<OutlineEntry>> _offThread(String content) async {
    try {
      return await Isolate.run(() => MarkdownParser.headingOutline(content));
    } catch (_) {
      return MarkdownParser.headingOutline(content);
    }
  }

  void _schedule(String content) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      final outline = await _compute(content);
      // The document may have been replaced while that was running. An
      // outline belonging to a document nobody is looking at is worse than a
      // late one: the headings look plausible and every line number is wrong.
      if (!mounted || content != _lastContent) return;
      state = outline;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// The current document's headings.
/// The outline of the document being read, computed off the typing path and
/// off the isolate drawing the window.
///
/// The table of contents used to call [MarkdownParser.headingOutline] inside
/// the sidebar's `build`, on a provider it watched for content — run again for
/// every keystroke, and the panel did not even have to be open, only built.
final outlineProvider =
    StateNotifierProvider<OutlineNotifier, List<OutlineEntry>>(
  OutlineNotifier.new,
);
