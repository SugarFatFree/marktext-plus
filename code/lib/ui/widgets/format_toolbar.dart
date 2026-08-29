import 'package:flutter/material.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/editor_provider.dart';

/// One button on the floating toolbar.
class FormatToolbarItem {
  const FormatToolbarItem({
    required this.action,
    required this.icon,
    required this.tooltip,
  });

  final FormatAction action;
  final IconData icon;
  final String tooltip;
}

/// The commands the toolbar offers, in order.
///
/// Six, deliberately. Upstream MarkText's toolbar is about this size, and the
/// point of a toolbar that appears over the text is that it can be read at a
/// glance — every command is already in the Format menu and on a shortcut, so
/// a longer strip would only be in the way.
List<FormatToolbarItem> formatToolbarItems(AppLocalizations l10n) => [
      FormatToolbarItem(
        action: FormatAction.bold,
        icon: Icons.format_bold,
        tooltip: l10n.formatBold,
      ),
      FormatToolbarItem(
        action: FormatAction.italic,
        icon: Icons.format_italic,
        tooltip: l10n.formatItalic,
      ),
      FormatToolbarItem(
        action: FormatAction.strikethrough,
        icon: Icons.format_strikethrough,
        tooltip: l10n.formatStrikethrough,
      ),
      FormatToolbarItem(
        action: FormatAction.inlineCode,
        icon: Icons.code,
        tooltip: l10n.formatInlineCode,
      ),
      FormatToolbarItem(
        action: FormatAction.highlight,
        icon: Icons.format_color_fill,
        tooltip: l10n.formatHighlight,
      ),
      FormatToolbarItem(
        action: FormatAction.link,
        icon: Icons.link,
        tooltip: l10n.formatLink,
      ),
    ];

/// A small strip of formatting commands, shown over the text while some of it
/// is selected.
///
/// Upstream MarkText shows one on every selection; its `inline/format-toolbar`
/// spec asks that it appear and that its buttons wrap the selection.
class FormatToolbar extends StatelessWidget {
  const FormatToolbar({
    super.key,
    required this.items,
    required this.onSelected,
    required this.themeName,
  });

  final List<FormatToolbarItem> items;
  final ValueChanged<FormatAction> onSelected;
  final String themeName;

  /// The strip's height and the width of one button.
  ///
  /// Exported because whoever positions the toolbar has to know how tall it
  /// is, and a second copy of the number in the caller would drift from this
  /// one — the strip would then sit over the line it is about instead of
  /// beside it, and nothing would say why.
  static const double height = 34;
  static const double buttonWidth = 30;

  /// The width of a strip holding [count] buttons.
  static double widthFor(int count) => count * buttonWidth + 8;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.getTokens(themeName);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(6),
      color: tokens.colorSurface,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: tokens.colorBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        // Sized rather than left to its children, so [height] is the truth
        // rather than a guess about what the buttons will add up to.
        height: height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items)
              SizedBox(
                width: buttonWidth,
                height: height,
                child: IconButton(
                  // Small enough to sit over a line of text without hiding
                  // the line above it.
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  tooltip: item.tooltip,
                  icon: Icon(item.icon, color: tokens.colorText),
                  onPressed: () => onSelected(item.action),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
