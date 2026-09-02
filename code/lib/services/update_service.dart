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
  static const _apiUrl = 'https://api.github.com/repos/marktext-plus/marktext-plus/releases/latest';
  static const _releasesUrl = 'https://github.com/marktext-plus/marktext-plus/releases/latest';

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
