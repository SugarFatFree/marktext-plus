import '../services/plugin_manifest.dart';

/// One plugin as a catalogue lists it — a search result, or a page for
/// something already installed.
///
/// It lives here rather than beside the service that fetches it because a tab
/// can now hold one: a plugin page is something the editor has open, the same
/// way it has a document open.
class PluginCatalogEntry {
  const PluginCatalogEntry({
    required this.id,
    required this.name,
    required this.version,
    required this.downloadUrl,
    required this.sha256,
    this.description = '',
    this.repositoryUrl,
    this.releaseNotes = '',
    this.publishedAt,
  });

  final String id;
  final String name;
  final String version;

  /// Null for a plugin that is already installed: there is nothing to fetch.
  final Uri? downloadUrl;
  final String sha256;
  final String description;
  final Uri? repositoryUrl;

  /// What the release said had changed. Markdown, as its author wrote it.
  ///
  /// The one thing someone deciding whether to install or update is looking
  /// for, and the detail page had no way to show it.
  final String releaseNotes;

  /// When that release was published, if the date could be read.
  final DateTime? publishedAt;

  /// Whether this is a plugin already on the reader's machine.
  ///
  /// The detail page was built from a search result, so installing a plugin
  /// took its page away: clicking it in the installed list did nothing, and
  /// the version and notes that had been there a moment ago were gone.
  bool get isInstalled => downloadUrl == null;

  /// A page for a plugin that is already installed.
  ///
  /// It has no download to offer and, unless its manifest says otherwise, no
  /// repository to read a README from — so the page shows what the manifest
  /// knows rather than fetching something that is not there.
  /// A page for a plugin that is already installed, in [locale].
  ///
  /// The name and description go through the plugin's own translations, like
  /// every other string it shows. An empty locale still resolves — through the
  /// plugin's default language — so a caller with no locale to hand gets the
  /// author's English rather than a raw key.
  factory PluginCatalogEntry.installed(
    PluginManifest manifest, {
    String locale = '',
  }) {
    final strings = manifest.stringsFor(locale);
    return PluginCatalogEntry(
      id: manifest.id,
      name: strings[manifest.name] ?? manifest.name,
      version: manifest.version,
      downloadUrl: null,
      sha256: '',
      description: strings[manifest.description] ?? manifest.description,
      repositoryUrl: manifest.repository.isEmpty
          ? null
          : Uri.tryParse(manifest.repository),
    );
  }

  factory PluginCatalogEntry.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('catalog entry requires $key');
      }
      return value.trim();
    }

    final published = json['publishedAt'];
    final url = Uri.tryParse(requiredString('downloadUrl'));
    if (url == null || !url.isScheme('https')) {
      throw const FormatException('plugin downloadUrl must use HTTPS');
    }
    return PluginCatalogEntry(
      id: requiredString('id'),
      name: requiredString('name'),
      version: requiredString('version'),
      downloadUrl: url,
      sha256: requiredString('sha256').toLowerCase(),
      description: (json['description'] as String?)?.trim() ?? '',
      repositoryUrl: Uri.tryParse((json['repository'] as String?) ?? ''),
      releaseNotes: (json['releaseNotes'] as String?)?.trim() ?? '',
      // A date nobody can read is worth less than the plugin it is attached
      // to, so it is dropped rather than allowed to hide the entry.
      publishedAt: published is String
          ? DateTime.tryParse(published)?.toUtc()
          : null,
    );
  }
}

/// Whether a catalogue result is something the reader can install, update, or
/// already has.
///
/// Kept apart from [PluginCatalogEntry.isInstalled], which answers a different
/// question — whether this page has anything to fetch — and cannot answer this
/// one: a search result always has a download URL, installed or not.
enum PluginInstallState {
  installable,
  updatable,
  installed;

  /// What [entry] is, given what is on the reader's machine.
  static PluginInstallState of(
    PluginCatalogEntry entry,
    List<PluginManifest> installed,
  ) {
    final present = installed
        .where((plugin) => plugin.id == entry.id)
        .firstOrNull;
    if (present == null) return PluginInstallState.installable;
    return PluginManifest.compareVersions(entry.version, present.version) > 0
        ? PluginInstallState.updatable
        : PluginInstallState.installed;
  }
}
