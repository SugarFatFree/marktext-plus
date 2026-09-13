import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UpdateInfo {
  final String version;
  final String url;
  final String releaseNotes;
  const UpdateInfo({required this.version, required this.url, required this.releaseNotes});
}

class UpdateService {
  static const _apiUrl = 'https://api.github.com/repos/SugarFatFree/marktext-plus/releases/latest';
  static const _releasesUrl = 'https://github.com/SugarFatFree/marktext-plus/releases/latest';

  /// Whether the automatic check should go out at all.
  ///
  /// A function of its own because it is the whole of the decision, and the
  /// request it guards cannot be made in a test: three inputs, one answer.
  ///
  /// [enabled] is the reader's setting, off by nothing but their choice —
  /// this was the one connection the editor made without being asked and the
  /// one they could not stop. [lastCheck] and [now] keep it to once a day,
  /// which is what it always did.
  static bool shouldCheckAutomatically({
    required bool enabled,
    required DateTime? lastCheck,
    required DateTime now,
  }) {
    if (!enabled) return false;
    if (lastCheck == null) return true;
    // A clock that moved backwards leaves a check in the future. Its age is
    // negative, which is not "checked recently"; it is a stamp this cannot
    // reason about, so it checks again.
    final age = now.difference(lastCheck);
    if (age.isNegative) return true;
    return age.inHours >= 24;
  }

  /// Asks GitHub for the latest release.
  ///
  /// Reports whether the check actually happened, separately from whether it
  /// found anything: the automatic check on startup wants to stay quiet when
  /// the network is down, but a check the user asked for must not answer
  /// "you are on the latest version" when it never got an answer.
  static Future<({UpdateInfo? update, bool reachable})> checkForUpdate(
    String currentVersion,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return (update: null, reachable: false);
      }

      final json = jsonDecode(response.body);
      final tagName = json['tag_name'] as String?;
      if (tagName == null) return (update: null, reachable: false);

      final remoteVersion = tagName.replaceFirst('v', '');
      if (_isNewer(remoteVersion, currentVersion)) {
        return (
          update: UpdateInfo(
            version: remoteVersion,
            url: json['html_url'] as String? ?? _releasesUrl,
            releaseNotes: json['body'] as String? ?? '',
          ),
          reachable: true,
        );
      }
      return (update: null, reachable: true);
    } catch (_) {
      return (update: null, reachable: false);
    }
  }

  /// Whether [remote] names a later version than [current].
  ///
  /// This is what decides whether the reader is told an update is waiting, so
  /// it being wrong is not quiet: issue #1 was this comparison measuring
  /// every release against a stale constant, and everyone on a current build
  /// was told for weeks that there was something newer.
  ///
  /// Opened up so it can be tested. It reaches the network otherwise, and a
  /// comparison that only runs against whatever GitHub answers today is a
  /// comparison nobody has checked.
  @visibleForTesting
  static bool isNewer(String remote, String current) =>
      _isNewer(remote, current);

  static bool _isNewer(String remote, String current) {
    final r = remote.split('.').map(int.tryParse).toList();
    final c = current.split('.').map(int.tryParse).toList();
    for (int i = 0; i < 3; i++) {
      final rv = i < r.length ? (r[i] ?? 0) : 0;
      final cv = i < c.length ? (c[i] ?? 0) : 0;
      if (rv > cv) return true;
      if (rv < cv) return false;
    }
    return false;
  }
}
