import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_command_service.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// A plugin can be more than one file.
///
/// The sandbox removed `require` outright, because it can load anything on the
/// disk. That also meant a plugin was one file forever: no splitting a large
/// one up, and no third party wrapping the editor's capabilities in something
/// an author could reuse. What was needed was not "no require" but a require
/// that cannot leave the plugin's own directory.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('plugin_modules_'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  PluginManifest install(Map<String, String> files) {
    final dir = Directory('${root.path}/com.example.demo')
      ..createSync(recursive: true);
    files.forEach((name, source) {
      final file = File('${dir.path}/$name')..parent.createSync(recursive: true);
      file.writeAsStringSync(source);
    });
    return PluginManifest.fromJson({
      'id': 'com.example.demo',
      'name': 'Demo',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
    });
  }

  String run(PluginManifest manifest) {
    final action = PluginCommandService(root.path)
        .start(manifest, const PluginScriptContext(command: 'x'));
    return (action as PluginNotifyAction).message;
  }

  test('a plugin can split itself across files', () {
    final manifest = install({
      'plugin.lua': '''
local greet = require("greet")
function on_command(ctx) return { notify = greet.hello("world") } end
''',
      'greet.lua': '''
local M = {}
function M.hello(name) return "hello " .. name end
return M
''',
    });

    expect(run(manifest), 'hello world');
  });

  test('a module in a subdirectory is named with dots', () {
    final manifest = install({
      'plugin.lua': '''
local text = require("lib.text")
function on_command(ctx) return { notify = text.upper("hi") } end
''',
      'lib/text.lua': '''
return { upper = function(s) return string.upper(s) end }
''',
    });

    expect(run(manifest), 'HI');
  });

  test('a module is loaded once, however often it is required', () {
    final manifest = install({
      'plugin.lua': '''
local a = require("counter")
local b = require("counter")
function on_command(ctx)
  return { notify = tostring(a.n) .. tostring(b.n) .. tostring(a == b) }
end
''',
      'counter.lua': '''
COUNT = (COUNT or 0) + 1
return { n = COUNT }
''',
    });

    expect(run(manifest), '11true', reason: '第二次 require 应返回同一份，而不是再跑一遍');
  });

  test('a dotted name cannot walk out to an absolute path', () {
    // `.` becomes a path separator, so a name that starts with one produces an
    // absolute path — and joining an absolute path throws the plugin's own
    // directory away. `/tmp/plugin_modules_x/secrets.lua` is reachable as
    // `.tmp.plugin_modules_x.secrets`.
    final secrets = File('${root.path}/secrets.lua')
      ..writeAsStringSync('return "stolen"');
    expect(secrets.existsSync(), isTrue);

    final asName = root.path.replaceAll(Platform.pathSeparator, '.');
    final manifest = install({
      'plugin.lua': """
local ok, err = pcall(function() return require("$asName.secrets") end)
function on_command(ctx)
  return { notify = tostring(ok) .. " " .. tostring(err) }
end
""",
    });

    final message = run(manifest);
    expect(message, startsWith('false'), reason: '绝对路径必须被拒绝');
    expect(message, isNot(contains('stolen')));
  });

  test('a link out of the plugin directory is not a way out either', () {
    final secrets = File('${root.path}/secrets.lua')
      ..writeAsStringSync('return "stolen"');
    final manifest = install({
      'plugin.lua': """
local ok, err = pcall(function() return require("escape") end)
function on_command(ctx)
  return { notify = tostring(ok) .. " " .. tostring(err) }
end
""",
    });
    // A name that resolves inside the directory, pointing at a file that is
    // not — which is what checking the name alone cannot catch.
    Link('${root.path}/com.example.demo/escape.lua')
        .createSync(secrets.path);

    final message = run(manifest);
    expect(message, startsWith('false'), reason: '符号链接指向目录外，必须被拒绝');
    expect(message, isNot(contains('stolen')));
  }, skip: Platform.isWindows ? 'symlinks need privileges on Windows' : null);

  test('a module that is not there says so, and names itself', () {
    final manifest = install({
      'plugin.lua': '''
local ok, err = pcall(function() return require("missing") end)
function on_command(ctx) return { notify = tostring(err) } end
''',
    });

    expect(run(manifest), contains('missing'));
  });
}
