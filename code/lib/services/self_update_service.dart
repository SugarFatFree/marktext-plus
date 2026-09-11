import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../core/net/answered_within.dart';
import 'app_log.dart';

/// Where a build to install comes from.
enum UpdateSource {
  /// A published release. What a reader gets.
  release('release'),

  /// What CI built for one commit, kept as a workflow artifact.
  ///
  /// This is the one that makes an unattended loop possible: every push to
  /// `dev` is built and packaged already, so a fix can be installed and
  /// driven without publishing a version for it — which this project does not
  /// do without a person having tested it first.
  ciRun('ci');

  const UpdateSource(this.wireName);

  final String wireName;

  static UpdateSource? byWireName(String? name) =>
      values.where((s) => s.wireName == name).firstOrNull;
}

/// One installable build, resolved but not yet fetched.
@immutable
class UpdateBuild {
  const UpdateBuild({
    required this.name,
    required this.url,
    required this.sha256,
    required this.bytes,
    required this.zipped,
    this.version = '',
  });

  /// The file's own name, as the release or the artifact calls it.
  final String name;

  final Uri url;

  /// Lower-case hex, without the `sha256:` GitHub puts in front of it.
  final String sha256;

  final int bytes;

  /// Whether [url] hands back a zip that holds the installer, rather than the
  /// installer itself. Release assets are the file; artifacts are always
  /// wrapped, even when they hold one file.
  final bool zipped;

  /// The version this build calls itself, where that is knowable.
  ///
  /// Empty for an artifact: it is named after a commit, and the version in it
  /// is whatever pubspec said plus a run number. Refusing a downgrade needs a
  /// version, so the refusal does not apply to those — and saying that out
  /// loud is better than comparing an empty string against a real one and
  /// calling the answer a decision.
  final String version;

  String describe() => '$name, ${(bytes / 1048576).toStringAsFixed(1)} MB'
      '${version.isEmpty ? '' : ', version $version'}';
}

/// Replaces this editor with a newer build of itself.
///
/// Every request goes to one repository, named here and not by the caller.
/// The point is not that the caller is untrusted — the interface this is
/// reached through refuses anyone without the token — it is that "download
/// something and run it" and "download *this* and run it" are different
/// powers, and only the second one is needed.
class SelfUpdateService {
  const SelfUpdateService({
    this.within = const Duration(seconds: 30),
    this.stalled = const Duration(seconds: 90),
  });

  /// How long to wait for GitHub to say anything at all.
  final Duration within;

  /// How long a download may go without a single new byte.
  ///
  /// A package is 15-25 MB and the link it comes over is whatever the reader
  /// has. Measured on the machine this was written on, the same 15 MB file
  /// arrived at 14 MB/s one minute and 29 KB/s the next — eight minutes for
  /// the slow one, and a total time limit set anywhere near that would fail a
  /// download that was working perfectly well.
  ///
  /// What a stuck download looks like is different and unmistakable: no bytes
  /// at all. That is what this bounds, which is the same shape BUG-404 landed
  /// on for the AI stream after fifteen minutes of nothing.
  final Duration stalled;

  static const owner = 'SugarFatFree';
  static const repo = 'marktext-plus';

  /// The artifact CI uploads for one commit, by name.
  ///
  /// Mirrors `.github/workflows/ci.yml`, which names them after the commit so
  /// that a build can be found from a sha without reading every run.
  @visibleForTesting
  static String artifactFor(String sha, {String platform = 'windows-x64'}) =>
      '$platform-setup-$sha';

  /// Which release asset is the one for this machine.
  ///
  /// Pure, and separated from the fetching, because choosing wrong is the
  /// failure with consequences: every asset in the list is genuine and its
  /// digest matches, so nothing downstream can notice that the arm64
  /// installer was handed to an x64 machine.
  @visibleForTesting
  static Map<String, dynamic>? chooseReleaseAsset(
    List<dynamic> assets, {
    required String os,
    required String arch,
  }) {
    final wanted = switch (os) {
      'windows' => '-windows-$arch-setup.exe',
      'macos' => '-macos-universal.dmg',
      'linux' => '-linux-$arch.tar.gz',
      _ => null,
    };
    if (wanted == null) return null;
    for (final asset in assets) {
      if (asset is! Map) continue;
      final name = asset['name'];
      if (name is String && name.endsWith(wanted)) {
        return Map<String, dynamic>.from(asset);
      }
    }
    return null;
  }

  /// `x64` or `arm64`, as the package names spell it.
  @visibleForTesting
  static String archName(String abi) =>
      abi.contains('arm64') || abi.contains('aarch64') ? 'arm64' : 'x64';

  /// Whether [ref] is already the full commit hash CI names its builds after.
  ///
  /// Forty hexadecimal characters. Anything else — a short sha, a branch, a
  /// tag — names a commit without being the string the artifact is called,
  /// and has to be asked about before it can be looked up.
  @visibleForTesting
  static bool isFullSha(String ref) =>
      RegExp(r'^[0-9a-f]{40}$').hasMatch(ref.trim().toLowerCase());

  /// The commit [ref] points at, as the forty characters CI used.
  ///
  /// This request exists because of a mismatch that would have shown up the
  /// first time anyone used this and never before: CI names its artifacts
  /// after `github.sha`, which is the whole hash, and every way a person
  /// comes by a commit — `git log --oneline`, a pull request page, a CI run
  /// summary — gives them the short one. Looking up
  /// `windows-x64-setup-a66c89d` finds nothing, and the sentence that came
  /// back said the commit had never been built.
  ///
  /// Resolving it through the API rather than refusing also means a branch
  /// works: `ref: dev` installs whatever the tip of dev built.
  Future<String> _fullSha(String ref, String? token) async {
    if (isFullSha(ref)) return ref.trim().toLowerCase();
    final commit = await _json(
      Uri.https('api.github.com', '/repos/$owner/$repo/commits/$ref'),
      token,
      'the commit lookup',
    );
    final sha = commit is Map ? commit['sha'] : null;
    if (sha is! String || !isFullSha(sha)) {
      throw FormatException('"$ref" does not name a commit in this repository');
    }
    return sha;
  }

  HttpClient _client() {
    final client = HttpClient();
    client.findProxy = (uri) => HttpClient.findProxyFromEnvironment(
          uri,
          environment: Platform.environment,
        );
    client.userAgent = 'MarkTextPlus';
    return client;
  }

  Future<dynamic> _json(Uri url, String? token, String what) async {
    final client = _client();
    try {
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      final response = await request.close().answeredWithin(within, what);
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('$what answered ${response.statusCode}: '
            '${body.length > 200 ? '${body.substring(0, 200)}…' : body}');
      }
      return jsonDecode(body);
    } finally {
      client.close(force: true);
    }
  }

  /// The build [source] and [ref] name, ready to fetch.
  Future<UpdateBuild> find({
    required UpdateSource source,
    String ref = '',
    String? token,
    String os = '',
    String abi = '',
  }) async {
    final onOs = os.isEmpty ? Platform.operatingSystem : os;
    // `Platform.version` ends with the ABI it was built for — `windows_x64`,
    // `windows_arm64` — which is the machine's own answer rather than a guess
    // from the environment. An arm64 host running the x64 build reports x64,
    // and that is the right answer: it is the build that has to be replaced.
    final arch = archName(abi.isEmpty ? Platform.version : abi);

    switch (source) {
      case UpdateSource.release:
        final where = ref.isEmpty ? 'latest' : 'tags/$ref';
        final release =
            await _json(Uri.https('api.github.com', '/repos/$owner/$repo/releases/$where'),
                token, 'the release listing');
        if (release is! Map || release['assets'] is! List) {
          throw const FormatException('that release has no assets');
        }
        final asset = chooseReleaseAsset(
          release['assets'] as List,
          os: onOs,
          arch: arch,
        );
        if (asset == null) {
          throw FormatException(
            'that release has nothing for $onOs $arch — it has: '
            '${(release['assets'] as List).map((a) => a is Map ? a['name'] : a).join(', ')}',
          );
        }
        return UpdateBuild(
          name: asset['name'] as String,
          url: Uri.parse(asset['browser_download_url'] as String),
          sha256: digestOf(asset['digest']),
          bytes: (asset['size'] as num?)?.toInt() ?? 0,
          zipped: false,
          version: ((release['tag_name'] as String?) ?? '').replaceFirst('v', ''),
        );

      case UpdateSource.ciRun:
        if (ref.isEmpty) {
          throw const FormatException('a CI build needs the commit it was built from');
        }
        if (token == null || token.isEmpty) {
          // Artifacts are not public, on a public repository or otherwise.
          // Saying so here is the difference between one sentence and a 404
          // the reader would spend an afternoon on.
          throw const FormatException(
            'a CI build needs a GitHub token; artifacts are never public',
          );
        }
        if (onOs != 'windows') {
          throw FormatException('CI keeps no installable package for $onOs');
        }
        final sha = await _fullSha(ref, token);
        final name = artifactFor(sha, platform: '$onOs-$arch');
        final listing = await _json(
          Uri.https('api.github.com', '/repos/$owner/$repo/actions/artifacts',
              {'name': name, 'per_page': '1'}),
          token,
          'the artifact listing',
        );
        final artifacts = listing is Map ? listing['artifacts'] : null;
        if (artifacts is! List || artifacts.isEmpty) {
          throw FormatException('CI has no artifact called "$name" — '
              'either that commit was not built, or its artifacts have '
              'expired${sha == ref.trim() ? '' : ' ("$ref" is $sha)'}');
        }
        final artifact = artifacts.first as Map;
        if (artifact['expired'] == true) {
          throw FormatException('the artifact "$name" has expired');
        }
        return UpdateBuild(
          name: name,
          url: Uri.parse(artifact['archive_download_url'] as String),
          sha256: digestOf(artifact['digest']),
          bytes: (artifact['size_in_bytes'] as num?)?.toInt() ?? 0,
          zipped: true,
        );
    }
  }

  /// The SHA-256 GitHub published for a build, or a refusal.
  ///
  /// Public to be tested on its own. It is the one check standing between
  /// "a program arrived over the network" and "a program is running on the
  /// reader's machine", and every other test in this feature would pass with
  /// it deleted.
  @visibleForTesting
  static String digestOf(dynamic digest) {
    if (digest is! String || !digest.startsWith('sha256:')) {
      // Without one there is nothing to check the download against, and this
      // download is a program that will be run.
      throw const FormatException('that build carries no SHA-256');
    }
    return digest.substring('sha256:'.length).toLowerCase();
  }

  /// Fetches [build], checks its digest, and leaves the installer on disk.
  ///
  /// Returns the file to run. Nothing is run here: applying is a separate
  /// step so that a caller can stop between them, and so the two failures —
  /// "it did not arrive intact" and "it would not install" — never share a
  /// message.
  Future<File> fetch(UpdateBuild build, {Directory? into, String? token}) async {
    final directory = into ??
        Directory(p.join(Directory.systemTemp.path, 'marktext-plus-update'))
      ..createSync(recursive: true);
    final client = _client();
    try {
      final request = await client.getUrl(build.url);
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      request.followRedirects = true;
      final response = await request.close().answeredWithin(within, 'the download');
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('the download answered ${response.statusCode}');
      }
      final bytes = <int>[];
      var announced = 0;
      await for (final chunk in response.timeout(stalled)) {
        bytes.addAll(chunk);
        // Every four megabytes, so that a slow download can be told apart
        // from a stopped one by reading the log rather than by waiting.
        if (bytes.length - announced >= 4 * 1048576) {
          announced = bytes.length;
          AppLog.instance.info(
            '${(bytes.length / 1048576).toStringAsFixed(0)} MB of '
            '${(build.bytes / 1048576).toStringAsFixed(0)} MB',
            source: 'update',
          );
        }
      }
      final got = sha256.convert(bytes).toString();
      if (got != build.sha256) {
        throw FormatException(
          'the download does not match its SHA-256 (expected ${build.sha256}, '
          'got $got) — nothing was run',
        );
      }
      return build.zipped
          ? _unwrap(bytes, directory)
          : (File(p.join(directory.path, build.name))..writeAsBytesSync(bytes));
    } finally {
      client.close(force: true);
    }
  }

  /// Pulls the one installer out of an artifact's zip.
  ///
  /// Entry names are refused if they climb out of [directory], the same way a
  /// plugin archive's are: this zip comes from CI rather than from a stranger,
  /// but "where it came from" is not a property the unpacking can check.
  static File _unwrap(List<int> bytes, Directory directory) {
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      if (!entry.name.toLowerCase().endsWith('.exe')) continue;
      final target = File(p.join(directory.path, p.basename(entry.name)));
      if (!p.isWithin(directory.path, target.path)) {
        throw FormatException('that archive wanted to write to ${entry.name}');
      }
      target.writeAsBytesSync(entry.content as List<int>);
      return target;
    }
    throw const FormatException('that artifact holds no installer');
  }

  /// Where the installer should write its own account of what it did.
  ///
  /// `startup-trace.log` sits beside this; both exist for the same reason.
  static String installLogIn(String directory) =>
      p.join(directory, 'update-install.log');

  /// What the installer said, folded into one line, and the file removed.
  ///
  /// Read at startup, because that is the first moment the editor exists
  /// again after an update. Without it a failed install leaves nothing at all
  /// to look at from a session that is not sitting at the machine: the editor
  /// either comes back at the old version or does not come back, and neither
  /// says whether the installer refused, could not write to the directory, or
  /// was never run. Inno keeps that account; this is what carries it across
  /// the restart that loses everything else.
  ///
  /// Removed once read, so it is reported after the update that produced it
  /// and not on every launch thereafter.
  ///
  /// Costs one `existsSync` on a launch where no update happened.
  static String? readInstallLog(String directory) {
    final file = File(installLogIn(directory));
    if (!file.existsSync()) return null;
    String? said;
    try {
      // Decoded leniently. Inno writes its log in whatever the machine's code
      // page is, so a single accented character in a path made the strict
      // decoder throw and turned a perfectly good account into "could not be
      // read" — the one answer that is worse than the log itself.
      final lines = const LineSplitter()
          .convert(utf8.decode(file.readAsBytesSync(), allowMalformed: true))
          .where((line) => line.trim().isNotEmpty)
          .toList();
      // Inno's last lines are its conclusion. The whole file is thousands of
      // lines of individual file copies, which is not what anybody reading a
      // log wants to find in it.
      final tail = lines.length <= 3 ? lines : lines.sublist(lines.length - 3);
      said = tail.join(' | ');
    } catch (error) {
      said = 'could not be read: $error';
    }
    try {
      file.deleteSync();
    } catch (_) {
      // Leaving it is better than failing a launch over it; the worst that
      // happens is the same line again next time.
    }
    return said;
  }

  /// What to tell the installer, so that it replaces *this* copy.
  ///
  /// `/DIR` is the one that matters and it was missing. Without it the
  /// installer writes to its own default — `%LocalAppData%\Programs` for a
  /// per-user install — which is very often not where the running copy
  /// lives: this project's own reader keeps theirs on D:. The install then
  /// succeeds, `/RESTARTAPPLICATIONS` brings back the copy it closed, which
  /// is the old one at the old path, and the update reports success while
  /// nothing has changed. A second, newer, unused copy sits elsewhere on the
  /// disk, and the editor cannot even run both: the single-instance name is
  /// a fixed string, so starting the new one just raises the old window.
  ///
  /// Pointing it at the directory this executable is in makes the update an
  /// update rather than a second installation, wherever the reader put it.
  @visibleForTesting
  static List<String> installerArguments(String directory, {String? logPath}) => [
        '/VERYSILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
        // Ends this process, through the Restart Manager, and brings it back.
        '/CLOSEAPPLICATIONS',
        '/RESTARTAPPLICATIONS',
        '/DIR=$directory',
        // Its own account of what it did, for the session that will not be
        // here to watch. Everything this process could have reported goes
        // away with the process.
        if (logPath != null) '/LOG=$logPath',
      ];

  /// Runs [installer] and lets it replace this editor.
  ///
  /// The installer does the replacing, not this code. A running program cannot
  /// overwrite its own files on Windows, and the part that works around that
  /// — closing the app, swapping the files, starting it again — is exactly
  /// what Inno Setup already does correctly. Writing a second one of those
  /// would put the reader's editor at risk of a half-finished swap, and this
  /// machine is not one anybody can reach a shell on to repair it.
  ///
  /// `/CLOSEAPPLICATIONS` is what ends this process; `/RESTARTAPPLICATIONS`
  /// is what brings it back, and with it the MCP server, on the same port and
  /// the same token, both of which live in the configuration file.
  Future<String> apply(File installer, {String? logDirectory}) async {
    if (!Platform.isWindows) {
      throw UnsupportedError(
        'installing in place is only written for Windows so far',
      );
    }
    AppLog.instance.info(
      'running ${p.basename(installer.path)} to replace this build',
      source: 'update',
    );
    final here = p.dirname(Platform.resolvedExecutable);
    final logPath = logDirectory == null ? null : installLogIn(logDirectory);
    await Process.start(
      installer.path,
      installerArguments(here, logPath: logPath),
      mode: ProcessStartMode.detached,
    );
    return 'the installer is running against $here; '
        'this editor will close and come back';
  }
}
