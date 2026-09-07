import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every way a plugin can reach the network is behind `network.request`.
///
/// The permission existed and the install dialog listed it, but the one thing
/// that actually made an outbound request on a plugin's behalf — a picture in
/// a plugin-drawn interface — never consulted it. A plugin that had asked for
/// nothing could name any URL and the editor would fetch it, and a URL carries
/// whatever the plugin put in its query string. The permission described a
/// door that was not there.
///
/// The check itself is tested in `plugin_image_loader_test`. What this guards
/// is the wiring: a second call site that hard-codes `allowNetwork: true`
/// would put the door back on the wrong side of the wall, and it would pass
/// every other test in the suite.
void main() {
  Iterable<File> dartFiles(String root) => Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  test('nothing in the app hands out network access without asking', () {
    // Each construction of the loader, with its arguments — enough of the
    // text after the opening bracket to hold them, then cut at the close.
    final sites = <String, String>{};
    for (final file in dartFiles('lib')) {
      final source = file.readAsStringSync();
      for (final match in RegExp('PluginImageLoader\\(').allMatches(source)) {
        var depth = 0;
        var end = match.end;
        for (; end < source.length; end++) {
          if (source[end] == '(') depth++;
          if (source[end] == ')') {
            if (depth == 0) break;
            depth--;
          }
        }
        final arguments = source.substring(match.end, end);
        // The constructor's own declaration matches this pattern too, and it
        // is the one place that legitimately has no permission to consult.
        // `required this.` appears there and never at a call site.
        if (arguments.contains('required this.')) continue;
        sites['${file.path}@${match.start}'] = arguments;
      }
    }

    // If this is empty the test proves nothing, and it would go quiet exactly
    // when the loader was renamed or deleted.
    expect(sites, isNotEmpty, reason: '没扫到任何构造点，说明这条守卫失效了');

    sites.forEach((where, arguments) {
      expect(
        arguments,
        contains('allowNetwork'),
        reason: '$where 构造了图片加载器却没说要不要放行网络',
      );
      expect(
        arguments,
        contains('hasPermission'),
        reason: '$where 的 allowNetwork 不是从权限来的——'
            '写死的 true 会把这道门装在墙的另一边',
      );
    });
  });

  test('the loader will not let a call site skip the question', () {
    final source = File(
      'lib/services/plugin_image_loader.dart',
    ).readAsStringSync();
    expect(
      source,
      contains('required this.allowNetwork'),
      reason: '默认值往哪边都是错的：true 把网络给了没申请的插件，'
          'false 从申请了的插件手里拿走',
    );
  });
}
