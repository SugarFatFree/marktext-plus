import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tab_info.dart';
import '../services/markdown_parser.dart';
import 'tab_provider.dart';

/// One heading in the document's outline.
typedef OutlineEntry = ({int line, int level, String text});

/// The outline of the document being read, recomputed off the typing path.
///
/// The table of contents used to call [MarkdownParser.headingOutline] inside
/// the sidebar's `build`, on a provider it watched for content. That is 402 ms
/// of work on a five megabyte document, run again for every keystroke — the
/// panel does not even have to be open, only built. Debounced the way the word
/// count already was, since it is the same shape of problem.
class OutlineNotifier extends StateNotifier<List<OutlineEntry>> {
  /// Watches the active document.
  OutlineNotifier(this._ref) : super(const []) {
    _ref.listen<TabInfo?>(activeTabProvider, (previous, next) {
      final content = next?.content ?? '';
      if (content == _lastContent) return;
      _lastContent = content;
      _schedule(content);
    }, fireImmediately: true);
  }

  final Ref _ref;
  Timer? _debounce;
  String? _lastContent;

  void _schedule(String content) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) state = MarkdownParser.headingOutline(content);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// The current document's headings.
final outlineProvider =
    StateNotifierProvider<OutlineNotifier, List<OutlineEntry>>(
  OutlineNotifier.new,
);
