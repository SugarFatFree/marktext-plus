import '../../core/i18n/l10n/app_localizations.dart';
import '../../services/ai_connection_service.dart';

/// What to tell the reader when the AI is not set up yet, in their language.
///
/// The sentence lives here rather than beside the check, for the same reason
/// `describePermission` does: a service may not reach the translations, and a
/// refusal written in the service layer is a refusal that answers in English
/// whichever of the twelve languages the reader chose.
///
/// The switch is exhaustive, so a fifth thing the reader has to fill in cannot
/// be added without a sentence to go with it.
String describeAiSetup(AiSetupProblem problem, AppLocalizations l10n) =>
    switch (problem) {
      AiSetupProblem.disabled => l10n.aiSetupDisabled,
      AiSetupProblem.endpoint => l10n.aiSetupEndpoint,
      AiSetupProblem.model => l10n.aiSetupModel,
      AiSetupProblem.key => l10n.aiSetupKey,
    };

/// [error] worded for the reader, or null when it is not about setting up.
///
/// Anything else keeps the text it came with: a provider's own message about a
/// wrong model or an expired key says far more than a sentence of ours could,
/// and translating it is not ours to do.
String? wordedAiFailure(Object error, AppLocalizations l10n) =>
    error is AiNotConfigured ? describeAiSetup(error.problem, l10n) : null;
