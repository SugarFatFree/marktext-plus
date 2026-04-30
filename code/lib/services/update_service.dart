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

  static Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      final tagName = json['tag_name'] as String?;
      if (tagName == null) return null;

      final remoteVersion = tagName.replaceFirst('v', '');
      if (_isNewer(remoteVersion, currentVersion)) {
        return UpdateInfo(
          version: remoteVersion,
          url: json['html_url'] as String? ?? _releasesUrl,
          releaseNotes: json['body'] as String? ?? '',
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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
