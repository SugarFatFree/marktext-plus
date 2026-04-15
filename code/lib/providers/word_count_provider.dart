import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tab_info.dart';
import '../services/word_count_service.dart';
import 'tab_provider.dart';

class WordCountNotifier extends StateNotifier<WordCount> {
  final Ref _ref;
  final WordCountService _service = WordCountService();
  Timer? _debounce;
  String? _lastContent;

  WordCountNotifier(this._ref) : super(const WordCount()) {
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
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        state = _service.countWords(content);
      }
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
