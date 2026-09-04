import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_document_edit.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';

/// What a plugin is allowed to write, and where.
///
/// A plugin that rewrites a paragraph is the point of AI writing and AI
/// proofreading, and until now `replace` was reported as something the editor
/// would not do. Doing it means being exact about what gets replaced: the
/// selection if there is one, and the whole document if there is not — never
/// "somewhere near where the caret used to be".
void main() {
  PluginManifest plugin({List<String> permissions = const []}) =>
      PluginManifest(
        id: 'com.example.demo',
        name: 'Demo',
        version: '1.0.0',
        entrypoint: 'plugin.lua',
        runtime: PluginRuntime.lua,
        permissions: permissions,
      );

  group('permission', () {
    test('a plugin that did not ask cannot write', () {
      expect(
        PluginDocumentEdit.of(
          plugin(),
          document: 'hello',
          selection: '',
          replacement: 'goodbye',
        ),
        isNull,
        reason: '没声明 document.write 就不该改得动文档',
      );
    });

    test('a plugin that asked can', () {
      expect(
        PluginDocumentEdit.of(
          plugin(permissions: const ['document.write']),
          document: 'hello',
          selection: '',
          replacement: 'goodbye',
        ),
        isNotNull,
      );
    });
  });

  group('what gets replaced', () {
    final writer = plugin(permissions: const ['document.write']);

    test('the selection, when there is one', () {
      final edit = PluginDocumentEdit.of(
        writer,
        document: 'one two three',
        selection: 'two',
        replacement: 'TWO',
      )!;
      expect(edit.after, 'one TWO three');
      expect(edit.before, 'one two three');
    });

    test('the whole document, when there is not', () {
      final edit = PluginDocumentEdit.of(
        writer,
        document: 'one two three',
        selection: '',
        replacement: 'rewritten',
      )!;
      expect(edit.after, 'rewritten');
    });

    test('the first occurrence, and only that one', () {
      // A proofreader fixing one "teh" must not change every "teh" in the
      // file, and the selection the reader made is one of them.
      final edit = PluginDocumentEdit.of(
        writer,
        document: 'teh cat and teh dog',
        selection: 'teh',
        replacement: 'the',
      )!;
      expect(edit.after, 'the cat and teh dog');
    });

    test('a selection that is not in the document changes nothing', () {
      // The document moved under the plugin while it was thinking. Writing
      // the replacement somewhere arbitrary would be worse than doing
      // nothing.
      expect(
        PluginDocumentEdit.of(
          writer,
          document: 'one two three',
          selection: 'four',
          replacement: 'FOUR',
        ),
        isNull,
      );
    });

    test('replacing something with itself is not an edit', () {
      // Nothing to undo, and nothing to mark the document dirty for.
      expect(
        PluginDocumentEdit.of(
          writer,
          document: 'one two',
          selection: 'two',
          replacement: 'two',
        ),
        isNull,
      );
    });

    test('an empty replacement deletes the selection', () {
      final edit = PluginDocumentEdit.of(
        writer,
        document: 'one two three',
        selection: ' two',
        replacement: '',
      )!;
      expect(edit.after, 'one three');
    });
  });

  test('the edit carries what it replaced, so it can be undone', () {
    final edit = PluginDocumentEdit.of(
      plugin(permissions: const ['document.write']),
      document: 'before',
      selection: '',
      replacement: 'after',
    )!;
    expect(edit.before, 'before');
    expect(edit.after, 'after');
  });
}
