import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tab_info.dart';
import '../services/word_count_service.dart';
import 'tab_provider.dart';

class WordCountNotifier extends StateNotifier<WordCount> {
  final Ref _ref;
  final WordCountService _service;
  Timer? _debounce;
  String? _lastContent;

  /// [service] is a parameter so a test can hold a count open and let the
  /// next document arrive while it is still running. That window is what the
  /// staleness check below exists for, and reproducing it with a real count
  /// would mean a document large enough to take longer than the debounce —
  /// which on a faster machine simply closes the window again and leaves the
  /// test green having proved nothing.
  WordCountNotifier(this._ref, {WordCountService? service})
      : _service = service ?? WordCountService(),
        super(const WordCount()) {
    _ref.listen<TabInfo?>(activeTabProvider, (prev, next) {
      final content = next?.content ?? '';
      if (content != _lastContent) {
        _lastContent = content;
        _debounceUpdate(content);
      }
    }, fireImmediately: true);
  }

  void _debounceUpdate(String content) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      // Off this isolate for a large document: one pass over eight megabytes
      // is 176 ms, and it was taken here, 300 ms after every pause in typing.
      final count = await _service.countWordsOffThread(content);
      // The document may have moved on while that was happening — a tab
      // switched, or typing resumed and a newer count is already on its way.
      // Writing a stale number into the status bar is worse than a late one.
      if (!mounted || content != _lastContent) return;
      state = count;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final wordCountProvider =
    StateNotifierProvider<WordCountNotifier, WordCount>((ref) {
  return WordCountNotifier(ref);
});
