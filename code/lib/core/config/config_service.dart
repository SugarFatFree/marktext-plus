import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'app_config.dart';

class ConfigService {
  final String configDir;
  late final String _configPath;

  ConfigService({required this.configDir}) {
    _configPath = p.join(configDir, 'config.json');
  }

  Future<AppConfig> load() async {
    try {
      final file = File(_configPath);
      if (!await file.exists()) return AppConfig();
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return AppConfig.fromJson(json);
    } catch (_) {
      return AppConfig();
    }
  }

  Future<void> save(AppConfig config) async {
    final file = File(_configPath);
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final content = const JsonEncoder.withIndent('  ').convert(config.toJson());
    await file.writeAsString(content);
  }
}
