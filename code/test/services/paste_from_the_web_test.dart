import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/html_to_markdown.dart';

/// What survives a paste from a browser.
///
/// The clipboard's HTML flavour is what a page or a word processor puts there,
/// and three things in it were being dropped on the way to Markdown: a task
/// list's ticks, a code block's language, and every mark a web word processor
/// makes with styles rather than tags.
void main() {
  String? md(String html) => HtmlToMarkdown.convert(html);

  group('a task list keeps its state', () {
    test('ticked and unticked', () {
      expect(
        md('<ul><li><input type="checkbox" checked>已办</li>'
            '<li><input type="checkbox">待办</li></ul>'),
        '- [x] 已办\n- [ ] 待办',
      );
    });

    test('however the attribute is written', () {
      // `checked` is a boolean attribute and pages write it three ways.
      for (final form in ['checked', 'checked=""', 'checked="checked"']) {
        expect(md('<ul><li><input type="checkbox" $form>甲</li></ul>'),
            '- [x] 甲', reason: form);
      }
    });

    test('a list with no boxes is still a plain list', () {
      expect(md('<ul><li>甲</li><li>乙</li></ul>'), '- 甲\n- 乙');
    });

    test('a radio button is not a task box', () {
      expect(md('<ul><li><input type="radio" checked>甲</li></ul>'), '- 甲');
    });
  });

  group('a code block keeps its language', () {
    test('the spelling every site uses', () {
      expect(md('<pre><code class="language-dart">var x = 1;</code></pre>'),
          '```dart\nvar x = 1;\n```');
    });

    test('and the older one, and beside other classes', () {
      expect(md('<pre><code class="lang-python">x = 1</code></pre>'),
          '```python\nx = 1\n```');
      expect(md('<pre><code class="hljs language-go">x := 1</code></pre>'),
          '```go\nx := 1\n```');
    });

    test('a block that says nothing about its language is unlabelled', () {
      expect(md('<pre><code>plain</code></pre>'), '```\nplain\n```');
      expect(md('<pre><code class="highlight">plain</code></pre>'),
          '```\nplain\n```');
    });
  });

  group('a web word processor marks up with styles, not tags', () {
    test('bold, italic and struck through', () {
      expect(
        md('<p><span style="font-weight:700;">粗</span>'
            '<span style="font-style:italic;">斜</span>'
            '<span style="text-decoration:line-through;">删</span></p>'),
        '**粗***斜*~~删~~',
      );
    });

    test('the word as well as the number', () {
      expect(md('<p><span style="font-weight:bold">粗</span></p>'), '**粗**');
      expect(md('<p><span style="font-weight:400">普通</span></p>'), '普通');
    });

    test('a Google Docs fragment, wrapper and all', () {
      // Everything Google Docs puts on the clipboard is wrapped in a `<b>`
      // that says in its own style that it is not bold. Taken at its tag, the
      // whole paste came out in asterisks; skipped entirely, the spans inside
      // became one paragraph each with their marks gone.
      expect(
        md('<b style="font-weight:normal;" id="docs-internal-guid-a">'
            '<span style="font-weight:400;">普通</span>'
            '<span style="font-weight:700;">加粗</span></b>'),
        '普通**加粗**',
      );
    });

    test('and the same thing with paragraphs inside it', () {
      expect(
        md('<b style="font-weight:normal"><p dir="ltr">'
            '<span style="font-weight:400;">普通</span>'
            '<span style="font-weight:700;">加粗</span></p></b>'),
        '普通**加粗**',
      );
    });
  });

  group('what must not change', () {
    test('a real bold tag is still bold', () {
      expect(md('<p><b>该粗</b>与<strong>也粗</strong></p>'), '**该粗**与**也粗**');
    });

    test('a span with nothing to say is invisible', () {
      expect(md('<p><span>普通文字</span></p>'), '普通文字');
      expect(md('<p><span style="color:#333">普通文字</span></p>'), '普通文字');
    });

    test('text-decoration:none is not a strikethrough', () {
      expect(md('<p><span style="text-decoration:none">正常</span></p>'), '正常');
    });

    test('headings, lists, tables and links still convert', () {
      expect(md('<h2>标题</h2>'), '## 标题');
      expect(md('<ol><li>一</li><li>二</li></ol>'), '1. 一\n2. 二');
      expect(md('<p><a href="/u">链接</a></p>'), '[链接](/u)');
      expect(
        md('<table><tr><th>键</th></tr><tr><td>a</td></tr></table>'),
        contains('| 键 |'),
      );
    });
  });
}
