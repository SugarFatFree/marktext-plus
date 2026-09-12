import 'package:flutter/material.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../editor/mermaid/mermaid.dart';

/// Why [code] could not be drawn, in the reader's language.
///
/// The Mermaid package depends on nothing but Flutter, so it cannot reach these
/// translations and its own `describeParseFailure` can only answer in English.
/// It hands back the *reason* instead — [MermaidFailureKind] — and the wording
/// belongs here.
///
/// The switch is exhaustive, so a fifth reason cannot be added without a
/// sentence to go with it.
///
/// The diagram type names are not translated: they are what has to be typed. A
/// reader told to write `流程图` would have nowhere to write it.
String describeMermaidFailure(String code, AppLocalizations l10n) {
  final failure = const MermaidParser().describeFailure(code);
  switch (failure.kind) {
    case MermaidFailureKind.empty:
      return l10n.mermaidErrorEmpty;
    case MermaidFailureKind.unknownType:
      return '${l10n.mermaidErrorUnknownType(failure.detail)}\n'
          '${l10n.mermaidSupportedTypes(MermaidParser.supportedTypes.join(', '))}';
    case MermaidFailureKind.headerOnly:
      return l10n.mermaidErrorHeaderOnly;
    case MermaidFailureKind.unparsedBody:
      return l10n.mermaidErrorBadBody;
  }
}

/// What the reader sees in place of a diagram that will not parse.
///
/// One box for both the preview and the export. The export renders each diagram
/// off screen and captures it, and with no builder of its own it captured the
/// package's English panel — which then sat inside the PDF, the Word file and
/// the HTML, in a document the reader sends to somebody else.
///
/// Coloured through the scheme rather than a fixed red: the pale red wash was
/// painted the same in every theme, so a dark one got a bright panel in the
/// middle of the document.
class MermaidFailureBox extends StatelessWidget {
  const MermaidFailureBox({required this.code, super.key});

  /// The diagram source, which is what the wording is worked out from.
  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.mermaidParseError,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            describeMermaidFailure(code, l10n),
            style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
