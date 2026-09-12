import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A doc comment describes the member underneath it, and no other.
///
/// Twenty-nine of them described something else. The mechanism is always the
/// same: a new member is written in above an existing one, with the insertion
/// point taken as the `void foo() {` line rather than the top of its doc
/// comment. The doc comment then sits above the *new* member, which now claims
/// two things, and the member that owned it has none at all.
///
/// `reportSaveFailure` was the clearest: a whole paragraph about how all three
/// save paths used to swallow a failure was attached to `reportDiskConflict`,
/// three functions away from the one it is about, while `reportSaveFailure`
/// carried nothing. Two of the twenty-nine were made in the three cycles
/// before this test was written, by exactly that edit, which is why it exists:
/// the analyser has nothing to say about a doc comment whichever member it
/// happens to be above.
///
/// The shape this looks for is a summary, its body, and then a *second*
/// sentence that reads as a summary with no blank `///` line before it. That
/// also describes one honest thing — a member documented in two sections,
/// where both sections are about it — so those are listed in [allowed] with
/// the member they share. Keyed by the second sentence rather than a line
/// number, which any edit above would move.
void main() {
  /// Second summaries that belong to the same member as the first, and what
  /// that member is. Each was read before being put here.
  const allowed = <String, String>{
    'lib/services/export_service.dart|Upstream MarkText sanitises the same path':
        'sanitiseHtmlForExport — one paragraph, and this sentence closes it',
    'lib/services/file_service.dart|Renames [oldPath] to [newPath], refusing':
        'renameFile — it both dispatches on the type and refuses to overwrite',
    'lib/services/html_to_markdown.dart|Escaping the text loses nothing':
        '_escapedEmphasis — the sentence that answers the paragraph above it',
    'lib/services/markdown_parser.dart|Three columns of indentation, not any':
        '_codeFenceRe — the second half of the pattern, in its own section',
    'lib/services/text_search_service.dart|A group that matched nothing':
        'expandReplacement — a rule about the same expansion',
    'lib/utils/file_utils.dart|Every extension this editor treats as':
        'markdownExtensions — why there is one list, then what is in it',
    'lib/models/plugin_catalog_entry.dart|A page for a plugin that is already '
            'installed, in [locale]':
        'PluginCatalogEntry.installed — the page, then the locale it renders in',
    'lib/ui/editor/source_editor.dart|The pair of markers each inline action':
        'wrapMarkers — why there is one table, then the constraint on two rows',
    'lib/ui/widgets/plugin_command_actions.dart|Where a plugin\'s answer goes':
        'PluginTextSink — what it is, then what it had to start carrying',
    'lib/providers/tab_provider.dart|Throws when the write fails':
        'overwriteOnDisk — what it writes, then how it reports failing',
    'lib/ui/widgets/plugin_command_actions.dart|Runs [command], optionally':
        'run — where it is called from, then what it does with the question',
  };

  bool isDoc(String line) => line.trimLeft().startsWith('///');

  test('no doc comment carries a second summary for another member', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('/l10n/'))
        .toList();
    expect(files.length, greaterThan(100),
        reason: '读到的文件太少，取法要跟着改');

    final found = <String>[];
    var checked = 0;
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 1; i < lines.length - 1; i++) {
        final above = lines[i - 1].trim();
        final here = lines[i].trim();
        final below = lines[i + 1].trim();
        if (!isDoc(above) || !isDoc(here)) continue;
        if (above == '///' || here == '///') continue;
        if (!above.endsWith('.')) continue;
        final sentence = here.substring(3).trim();
        if (sentence.isEmpty || sentence[0].toLowerCase() == sentence[0]) {
          continue;
        }
        // A blank `///` under it is what makes it read as a summary rather
        // than a sentence carrying on.
        if (below != '///') continue;
        checked++;
        final key = allowed.keys.firstWhere(
          (k) =>
              k.startsWith('${file.path}|') &&
              sentence.startsWith(k.split('|')[1]),
          orElse: () => '',
        );
        if (key.isEmpty) found.add('${file.path}:${i + 1}  $sentence');
      }
    }

    expect(checked, allowed.length,
        reason: '这条测试查到的处数与 allowed 的条数不再相等——'
            '要么新增了一处，要么 allowed 里有一条已经不存在了');
    expect(found, isEmpty,
        reason: '这些文档注释里挤着第二个摘要。它多半属于另一个成员——'
            '找到那个没有文档的成员，把前半段搬回它头上；'
            '如果两段说的确实是同一个成员，写进 allowed 并说明是哪一个：\n'
            '${found.join('\n')}');
  });
}
