import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_command_service.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// The plugin's own `blocks.split`, asked directly.
///
/// It was reached through three layers before this — split, then the batcher
/// that joins neighbours back up to 1500 characters, then the prompt template
/// — and each of them hid the signal. Mutating the fence rule three separate
/// ways changed nothing observable at the far end, which read as "the rule is
/// covered" when it meant "the fixture cannot see it".
///
/// A block boundary is what this file looks at, and nothing else.
void main() {
  const path = 'marktext-plus-plugins/marktext-plus-ai-translate-plugin';
  String? findRepo() {
    var directory = Directory.current;
    for (var level = 0; level < 6; level++) {
      final candidate = '${directory.path}/$path';
      if (File('$candidate/lib/blocks.lua').existsSync()) return candidate;
      final parent = directory.parent;
      if (parent.path == directory.path) break;
      directory = parent;
    }
    return null;
  }

  final repo = findRepo();
  final present = repo != null;

  late Directory root;
  const id = 'com.example.blocks';
  const manifest = PluginManifest(
    id: id,
    name: 'Blocks',
    version: '1.0.0',
    entrypoint: 'plugin.lua',
    runtime: PluginRuntime.lua,
    permissions: ['document.read'],
  );

  setUp(() {
    if (!present) return;
    root = Directory.systemTemp.createTempSync('blocks_');
    final dir = Directory('${root.path}/$id/lib')..createSync(recursive: true);
    File('$repo/lib/blocks.lua').copySync('${dir.path}/blocks.lua');
    // The real module, driven by a script that does nothing but report where
    // the boundaries fell.
    File('${root.path}/$id/plugin.lua').writeAsStringSync('''
local blocks = require("lib.blocks")
function on_command(ctx)
  return { show = table.concat(blocks.split(ctx.document or ""), "\\n<CUT>\\n") }
end
''');
  });
  tearDown(() {
    if (present && root.existsSync()) root.deleteSync(recursive: true);
  });

  /// Where [document] was cut, as a list of blocks.
  List<String> split(String document) {
    final service = PluginCommandService(root.path);
    addTearDown(service.dispose);
    final action = service.start(
      manifest,
      PluginScriptContext(command: 'go', document: document),
    );
    return (action as PluginShowAction).text.split('\n<CUT>\n');
  }

  /// A fenced block with blank lines inside it, which is the only thing that
  /// makes a wrong cut visible: solid text has nowhere to cut either way.
  String fenced(String open, String inner, String close) =>
      '$open\n$inner\nvoid a() {\n\n}\n$inner\nvoid b() {\n\n}\n$close';

  test('a plain fenced block is one block', () {
    expect(
      split(fenced('```dart', 'x = 1;', '```')),
      hasLength(1),
      reason: '围栏内的空行是代码的一部分，不是段落之间的空行',
    );
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a fence shown inside a longer fence does not end it', () {
    // A document explaining markdown puts ``` inside a ```` block.
    expect(
      split(fenced('````markdown', '```', '````')),
      hasLength(1),
      reason: '``` 比 ```` 短，闭合不了它',
    );
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('backticks do not close a tilde block', () {
    expect(
      split(fenced('~~~', '```', '~~~')),
      hasLength(1),
      reason: '不同的围栏字符不能互相闭合',
    );
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a fence carrying a language does not close a block', () {
    // A closing fence has nothing after it, so ```js inside a block is code.
    expect(
      split(fenced('```', '```js', '```')),
      hasLength(1),
      reason: '带语言标记的行不是收尾，它是块里的内容',
    );
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('paragraphs outside a fence are still separate blocks', () {
    // The guard against fixing the above by never cutting at all.
    expect(split('One.\n\nTwo.\n\nThree.'), hasLength(3));
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a fence ends the paragraph above it', () {
    expect(
      split('Prose.\n```\ncode\n```\nMore prose.'),
      hasLength(3),
      reason: '代码块上面的段落是它自己的块，两者一起交给模型正是切分要避免的',
    );
  }, skip: present ? null : '插件仓库不在这台机器上');
}
