import 'package:flutter/material.dart';

/// The icons a plugin may name in its manifest.
///
/// Flutter tree-shakes icon fonts, so `Icons` cannot be indexed by a string
/// at runtime: an icon exists in the built application only if some line of
/// Dart mentions it. That is why this is a table rather than a lookup, and
/// why a plugin cannot simply name any Material icon.
///
/// The table was seven entries long and the one official plugin asked for
/// `edit_note`, which is not among them — so it drew the fallback, and the
/// side bar showed a generic plugin icon for a writing tool. The names below
/// are Material's own, so an author can browse fonts.google.com/icons and
/// use what they find, as long as it is in this list.
///
/// Adding to this list is free and cheap. Taking something out of it changes
/// what an already-published plugin draws.
class PluginIcons {
  const PluginIcons._();

  /// What a plugin gets when it names something not in [byName] — including
  /// when it names nothing at all.
  static const IconData fallback = Icons.extension;

  static const Map<String, IconData> byName = <String, IconData>{
    // Writing and editing
    'edit': Icons.edit,
    'edit_note': Icons.edit_note,
    'spellcheck': Icons.spellcheck,
    'format_paint': Icons.format_paint,
    'text_fields': Icons.text_fields,
    'notes': Icons.notes,
    'article': Icons.article_outlined,
    'description': Icons.description_outlined,

    // Language
    'translate': Icons.translate,
    'language': Icons.language,

    // Models and suggestions
    'auto_awesome': Icons.auto_awesome,
    'lightbulb': Icons.lightbulb_outline,
    'psychology': Icons.psychology_outlined,
    'chat': Icons.chat_bubble_outline,

    // Structure
    'list': Icons.list,
    'table_chart': Icons.table_chart_outlined,
    'account_tree': Icons.account_tree_outlined,
    'bookmark': Icons.bookmark_border,
    'label': Icons.label_outline,

    // Files and links
    'folder': Icons.folder_outlined,
    'image': Icons.image_outlined,
    'link': Icons.link,
    'download': Icons.download_outlined,
    'upload': Icons.upload_outlined,

    // Tools
    'search': Icons.search,
    'settings': Icons.settings,
    'build': Icons.build_outlined,
    'tune': Icons.tune,
    'code': Icons.code,
    'terminal': Icons.terminal,
    'science': Icons.science_outlined,
    'bug_report': Icons.bug_report_outlined,

    // Time and state
    'history': Icons.history,
    'schedule': Icons.schedule,
    'check_circle': Icons.check_circle_outline,
    'star': Icons.star_border,
    'visibility': Icons.visibility_outlined,
    'share': Icons.share_outlined,
    'info': Icons.info_outline,
    'help': Icons.help_outline,
  };

  /// The icon [name] asks for, or [fallback] when the editor has no such
  /// icon — a plugin naming something unknown still gets a rail entry,
  /// because a panel nobody can open is worse than a generic square.
  static IconData resolve(String name) => byName[name] ?? fallback;
}
