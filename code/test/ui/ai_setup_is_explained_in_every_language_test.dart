import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/services/ai_chat_service.dart';
import 'package:marktext_plus/services/ai_connection_service.dart';
import 'package:marktext_plus/ui/widgets/ai_setup_text.dart';

/// "You have not set the AI up yet" is said in the reader's language.
///
/// It is the first thing anybody meets: install the AI plugin, run a command,
/// and before any of this works the endpoint, the model and the key have to be
/// filled in. That refusal was a `FormatException` carrying an English sentence,
/// and both places that show it — the plugin failure dialog and Settings' test
/// button — print the error as it stands. So a reader whose editor is in Chinese
/// was told *"Set the AI endpoint, model and API key in Settings first"*.
///
/// The permission refusal beside it was already done this way: the service says
/// which plugin and which permission, and the sentence is looked up in the
/// reader's language. This is the same shape, and the same shape as the plugin
/// marketplace's failures, which were English for every reader until BUG-432.
///
/// Naming the one thing that is missing is also better than listing three: the
/// old sentence sent the reader to check the endpoint and the model when only
/// the key was blank.
void main() {
  AppConfig configured({
    bool enabled = true,
    String endpoint = 'https://api.openai.com/v1',
    String model = 'gpt-4o',
    String key = 'sk-test',
  }) =>
      AppConfig(
        aiEnabled: enabled,
        aiEndpoint: endpoint,
        aiModel: model,
        aiApiKey: key,
      );

  group('the service says which piece is missing', () {
    test('AI turned off', () {
      expect(
        () => AiConnectionService.testConnection(configured(enabled: false)),
        throwsA(isA<AiNotConfigured>()
            .having((e) => e.problem, 'problem', AiSetupProblem.disabled)),
      );
    });

    test('no model', () {
      expect(
        () => AiConnectionService.testConnection(configured(model: '  ')),
        throwsA(isA<AiNotConfigured>()
            .having((e) => e.problem, 'problem', AiSetupProblem.model)),
      );
    });

    test('no key', () {
      expect(
        () => AiConnectionService.testConnection(configured(key: '')),
        throwsA(isA<AiNotConfigured>()
            .having((e) => e.problem, 'problem', AiSetupProblem.key)),
      );
    });

    test('asking the model with nothing set up', () {
      for (final (config, problem) in [
        (configured(enabled: false), AiSetupProblem.disabled),
        (configured(endpoint: ''), AiSetupProblem.endpoint),
        (configured(model: ''), AiSetupProblem.model),
        (configured(key: ''), AiSetupProblem.key),
      ]) {
        expect(
          () => AiChatService.complete(config: config, prompt: 'translate this'),
          throwsA(isA<AiNotConfigured>()
              .having((e) => e.problem, 'problem', problem)),
          reason: '$problem',
        );
      }
    });

    /// The key is checked last on purpose: a reader who has filled in nothing
    /// should be sent to the endpoint first, which is the field at the top.
    test('the piece named is the first one missing', () {
      expect(
        () => AiChatService.complete(
            config: configured(endpoint: '', model: '', key: ''), prompt: 'x'),
        throwsA(isA<AiNotConfigured>()
            .having((e) => e.problem, 'problem', AiSetupProblem.endpoint)),
      );
    });
  });

  group('and every piece has a sentence', () {
    test('in English, none of them falling through', () async {
      final english = await AppLocalizations.delegate.load(const Locale('en'));
      final said = <String>{};
      for (final problem in AiSetupProblem.values) {
        final text = describeAiSetup(problem, english);
        expect(text, isNotEmpty, reason: '$problem 没有句子');
        said.add(text);
      }
      expect(said, hasLength(AiSetupProblem.values.length),
          reason: '两个不同的问题给出了同一句话，读者会去改错的字段：$said');
    });

    test('in each of the twelve', () async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        for (final problem in AiSetupProblem.values) {
          expect(describeAiSetup(problem, l10n), isNotEmpty,
              reason: '$locale 缺 $problem 的句子');
        }
      }
    });

    test('and not in English for a reader who is not reading English', () async {
      final english = await AppLocalizations.delegate.load(const Locale('en'));
      final chinese = await AppLocalizations.delegate.load(const Locale('zh'));
      for (final problem in AiSetupProblem.values) {
        expect(
          describeAiSetup(problem, chinese),
          isNot(describeAiSetup(problem, english)),
          reason: '$problem 的中文与英文相同——多半是没翻译',
        );
      }
    });
  });

  /// The sentences being right says nothing about anybody showing them. Both
  /// places that display an AI failure print the error as it stands unless they
  /// ask, and `wordedAiFailure` is the asking. A translation written and never
  /// reached is the same as no translation.
  group('and the two places that show a failure ask for it', () {
    test('an AI setup refusal is worded, anything else is left alone',
        () async {
      final chinese = await AppLocalizations.delegate.load(const Locale('zh'));
      expect(
        wordedAiFailure(const AiNotConfigured(AiSetupProblem.key), chinese),
        chinese.aiSetupKey,
      );
      expect(
        wordedAiFailure(
            const FormatException('AI provider returned HTTP 401'), chinese),
        isNull,
        reason: '供应商自己的回复被改写了——它说的比我们的句子多',
      );
    });

    test('both surfaces call it', () {
      const surfaces = [
        'lib/ui/widgets/plugin_command_actions.dart',
        'lib/ui/screens/settings_screen.dart',
      ];
      for (final path in surfaces) {
        final source = File(path)
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');
        expect(source, contains('wordedAiFailure('),
            reason: '$path 直接显示了 error，读者会看到英文；'
                '两处都必须问一次 wordedAiFailure');
      }
    });
  });
}
