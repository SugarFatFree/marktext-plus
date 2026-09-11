import '../services/plugin_manager.dart';
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
    this.isPrerelease = false,
    this.permissions = const <String>[],
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

  /// Whether the release this came from is a pre-release.
  ///
  /// Shown in the list, because "0.1.3" and "0.1.3, pre-release" are not the
  /// same promise, and the reader is entitled to know which one they took.
  final bool isPrerelease;

  /// What the plugin asked to be allowed to do, as its manifest listed it.
  ///
  /// Empty means the editor has not seen the package — a search result is a
  /// release on GitHub, not a manifest — and the page says nothing rather
  /// than showing an empty list, which would read as "asks for nothing".
  final List<String> permissions;

  /// Whether [key] is a name for this plugin.
  ///
  /// Automation knows a plugin by the id in its manifest — the one
  /// `run_plugin_command` takes — and a search result does not carry one: it
  /// is a release on GitHub, and the manifest is inside the archive nobody
  /// has downloaded yet. So the manifest id is matched the long way round,
  /// through [repository], which an installed plugin declares and which
  /// points at the same place GitHub found.
  ///
  /// The other two keys need nothing installed: the catalogue's own id, and
  /// `owner/repo` as a person would write it.
  ///
  /// Case is ignored throughout. GitHub treats repository names that way, and
  /// a caller who types the owner in the wrong case means the same plugin.
  bool namedBy(String key, {String repository = ''}) {
    final wanted = key.trim().toLowerCase();
    if (wanted.isEmpty) return false;
    if (id.toLowerCase() == wanted) return true;
    final mine = _ownerAndRepo(repositoryUrl?.toString() ?? '');
    if (mine.isNotEmpty && mine == wanted) return true;
    if (repository.trim().isEmpty) return false;
    return mine.isNotEmpty && mine == _ownerAndRepo(repository);
  }

  /// `owner/repo` out of whatever shape the URL came in.
  ///
  /// A manifest's `repository` is written by its author: with or without the
  /// scheme, with or without `.git`, with or without a trailing slash. All of
  /// those name one repository, and comparing the strings as given would say
  /// they name four.
  static String _ownerAndRepo(String url) {
    if (url.trim().isEmpty) return '';
    var rest = url.trim().toLowerCase();
    for (final prefix in ['https://', 'http://', 'git@', 'ssh://']) {
      if (rest.startsWith(prefix)) rest = rest.substring(prefix.length);
    }
    if (rest.startsWith('github.com/')) rest = rest.substring('github.com/'.length);
    if (rest.startsWith('github.com:')) rest = rest.substring('github.com:'.length);
    if (rest.endsWith('.git')) rest = rest.substring(0, rest.length - 4);
    while (rest.endsWith('/')) {
      rest = rest.substring(0, rest.length - 1);
    }
    final parts = rest.split('/').where((p) => p.isNotEmpty).toList();
    return parts.length >= 2 ? '${parts[0]}/${parts[1]}' : '';
  }

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
      permissions: manifest.permissions,
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
      isPrerelease: json['prerelease'] == true,
    );
  }

  /// The same shape [PluginCatalogEntry.fromJson] reads.
  ///
  /// For the catalogue cache. Discovery costs one search plus a request per
  /// repository found — thirty of them against sixty unauthenticated requests
  /// an hour — so doing it on every start runs the reader out of quota in two
  /// or three launches, which is what "try again in 819 seconds" was.
  ///
  /// `permissions` is deliberately not written: a search result never has any
  /// (they come from the package, which has not been downloaded), so a cached
  /// empty list would be indistinguishable from a plugin that asks for
  /// nothing.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'downloadUrl': downloadUrl.toString(),
    'sha256': sha256,
    if (description.isNotEmpty) 'description': description,
    if (repositoryUrl != null) 'repository': repositoryUrl.toString(),
    if (releaseNotes.isNotEmpty) 'releaseNotes': releaseNotes,
    if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
    if (isPrerelease) 'prerelease': true,
  };
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
  ///
  /// Matched on the repository, not the id. The two ids are not the same kind
  /// of thing: a catalogue entry is identified by where it was found —
  /// `github.owner.repo` — and an installed plugin by whatever its manifest
  /// calls itself. Comparing them meant every discovered plugin looked
  /// uninstalled, however many times the reader had installed it.
  static PluginInstallState of(
    PluginCatalogEntry entry,
    List<PluginManifest> installed, {
    Map<String, PluginSource> sources = const {},
  }) {
    final wanted = _repositoryKey(entry.repositoryUrl?.toString());
    final present = installed.where((plugin) {
      if (plugin.id == entry.id) return true;
      final theirs = _repositoryKey(plugin.repository);
      return wanted != null && theirs == wanted;
    }).firstOrNull;
    if (present == null) return PluginInstallState.installable;
    if (PluginManifest.compareVersions(entry.version, present.version) > 0) {
      return PluginInstallState.updatable;
    }
    // A pre-release is updated in place, so the version is the same before and
    // after and says nothing about whether there is anything new. The archive
    // does: a different SHA-256 is a different plugin. With nothing recorded —
    // installed before this was kept, or from a ZIP by hand — the version is
    // all there is, and claiming an update on no evidence would offer one
    // every time the list is drawn.
    final was = sources[present.id]?.digest ?? '';
    final now = entry.sha256;
    if (was.isNotEmpty && now.isNotEmpty && was != now) {
      return PluginInstallState.updatable;
    }
    return PluginInstallState.installed;
  }

  /// A repository URL reduced to what identifies it.
  ///
  /// A manifest is written by hand, so the same repository arrives spelled
  /// several ways — a trailing slash, a `.git`, a capital letter. Null for a
  /// plugin that names none, so that two anonymous plugins are not each other.
  static String? _repositoryKey(String? url) {
    if (url == null) return null;
    final parsed = Uri.tryParse(url.trim());
    if (parsed == null || parsed.host.isEmpty) return null;
    var path = parsed.path;
    if (path.endsWith('.git')) path = path.substring(0, path.length - 4);
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    if (path.isEmpty) return null;
    return '${parsed.host}$path'.toLowerCase();
  }
}
