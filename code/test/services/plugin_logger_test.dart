import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_logger.dart';

void main() {
  test('plugin logger writes an isolated file and rotates oversized logs', () async {
    final directory = await Directory.systemTemp.createTemp('plugin_log_');
    addTearDown(() => directory.delete(recursive: true));
    final logger = PluginLogger('com.example.demo', directory.path, maxBytes: 32);

    await logger.info('first');
    await logger.error('second');
    expect(File(logger.path).readAsStringSync(), contains('[ERROR] second'));
    expect(File('${logger.path}.1').readAsStringSync(), contains('[INFO] first'));
  });
}
