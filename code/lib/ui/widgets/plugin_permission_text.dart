import '../../core/i18n/l10n/app_localizations.dart';
import '../../services/plugin_manifest.dart';

/// What a permission means, in the reader's language.
///
/// This is the list somebody reads to decide whether to install a plugin, and
/// it answered in English whichever of the twelve languages they had chosen —
/// eighteen sentences written into `PluginPermission.describe`, which lives in
/// the service layer where nothing may reach the translations. The same shape as
/// `actionLabel`: the service keeps the identifiers and the English, and the
/// mapping to a translated sentence lives up here with the widgets that draw it.
///
/// `permission_text_covers_test` holds this to `PluginPermission.all`, so a new
/// permission cannot be offered to a reader with nothing to read.
String describePermission(String permission, AppLocalizations l10n) {
  return switch (permission) {
    PluginPermission.documentRead => l10n.permDocumentRead,
    PluginPermission.documentWrite => l10n.permDocumentWrite,
    PluginPermission.uiContextMenu => l10n.permUiContextMenu,
    PluginPermission.uiMenuBar => l10n.permUiMenuBar,
    PluginPermission.uiToolbar => l10n.permUiToolbar,
    PluginPermission.uiSidebar => l10n.permUiSidebar,
    PluginPermission.uiStatusBar => l10n.permUiStatusBar,
    PluginPermission.uiSettings => l10n.permUiSettings,
    PluginPermission.uiCommandPalette => l10n.permUiCommandPalette,
    PluginPermission.uiNotifications => l10n.permUiNotifications,
    PluginPermission.aiChat => l10n.permAiChat,
    PluginPermission.storageLocal => l10n.permStorageLocal,
    PluginPermission.clipboardRead => l10n.permClipboardRead,
    PluginPermission.clipboardWrite => l10n.permClipboardWrite,
    PluginPermission.workspaceRead => l10n.permWorkspaceRead,
    PluginPermission.workspaceWrite => l10n.permWorkspaceWrite,
    PluginPermission.networkRequest => l10n.permNetworkRequest,
    PluginPermission.uiWebview => l10n.permUiWebview,
    // A permission from a newer editor, or a typo in a manifest. Both mean the
    // plugin gets nothing for it, and the reader is told that rather than shown
    // an identifier and left to guess.
    _ => l10n.permUnknown,
  };
}
