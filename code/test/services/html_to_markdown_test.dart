import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/html_to_markdown.dart';

/// Turning the HTML flavour of a paste into markdown.
///
/// Copying a list or a table out of a browser used to arrive as the plain
/// flavour — the words with their bullets and column breaks flattened into
/// running text. The shapes here are the ones a browser actually puts on the
/// clipboard, including the wrapper Windows adds.
void main() {
  String? convert(String html) => HtmlToMarkdown.convert(html);

  group('blocks', () {
    test('headings keep their level', () {
      expect(convert('<h1>标题</h1>'), '# 标题');
      expect(convert('<h3>小标题</h3>'), '### 小标题');
    });

    test('paragraphs are separated by a blank line', () {
      expect(convert('<p>一段</p><p>二段</p>'), '一段\n\n二段');
    });

    test('a bullet list keeps its items', () {
      expect(convert('<ul><li>一</li><li>二</li></ul>'), '- 一\n- 二');
    });

    test('a numbered list is numbered from one', () {
      expect(convert('<ol><li>甲</li><li>乙</li></ol>'), '1. 甲\n2. 乙');
    });

    test('a nested list is indented under its item', () {
      expect(
        convert('<ul><li>父<ul><li>子</li></ul></li></ul>'),
        '- 父\n  - 子',
      );
    });

    test('a quote is marked on every line', () {
      expect(convert('<blockquote><p>一</p><p>二</p></blockquote>'),
          '> 一\n>\n> 二');
    });

    test('a code block becomes a fence', () {
      expect(convert('<pre><code>void main() {}</code></pre>'),
          '```\nvoid main() {}\n```');
    });

    test('a rule is a rule', () {
      expect(convert('<p>a</p><hr><p>b</p>'), 'a\n\n---\n\nb');
    });
  });

  group('tables', () {
    test('a table becomes a GFM table with a delimiter row', () {
      expect(
        convert('<table><tr><th>名称</th><th>说明</th></tr>'
            '<tr><td>甲</td><td>乙</td></tr></table>'),
        '| 名称 | 说明 |\n|---|---|\n| 甲 | 乙 |',
      );
    });

    test('a short row is padded to the width of the header', () {
      expect(
        convert('<table><tr><td>a</td><td>b</td></tr>'
            '<tr><td>c</td></tr></table>'),
        '| a | b |\n|---|---|\n| c |  |',
      );
    });

    test('a pipe inside a cell is escaped', () {
      // Left as it stands it would split the cell in two.
      expect(
        convert('<table><tr><td>a|b</td><td>c</td></tr></table>'),
        r'| a\|b | c |' '\n|---|---|',
      );
    });
  });

  group('inline markup', () {
    test('bold, italic, strikethrough and code', () {
      expect(convert('<p><strong>粗</strong></p>'), '**粗**');
      expect(convert('<p><em>斜</em></p>'), '*斜*');
      expect(convert('<p><del>删</del></p>'), '~~删~~');
      expect(convert('<p><code>码</code></p>'), '`码`');
      // The older spellings browsers still emit.
      expect(convert('<p><b>粗</b> 和 <i>斜</i></p>'), '**粗** 和 *斜*');
    });

    test('a link keeps its target', () {
      expect(convert('<p><a href="https://x.com">站点</a></p>'),
          '[站点](https://x.com)');
    });

    test('a link with no target is just its text', () {
      expect(convert('<p><a>没有地址</a></p>'), '没有地址');
    });

    test('an image keeps its alt text and source', () {
      expect(convert('<p><img src="a.png" alt="图"></p>'), '![图](a.png)');
    });

    test('markup inside a heading survives', () {
      expect(convert('<h2>说明 <strong>重点</strong></h2>'), '## 说明 **重点**');
    });
  });

  group('what a real clipboard actually carries', () {
    test('the Windows HTML Format wrapper is stripped', () {
      // Windows puts a header and fragment markers around the fragment.
      const clipboard = 'Version:0.9\r\nStartHTML:00000097\r\n'
          '<html><body>\r\n<!--StartFragment--><p>正文</p><!--EndFragment-->\r\n'
          '</body></html>';
      expect(convert(clipboard), '正文');
    });

    test('style and script blocks are dropped', () {
      expect(
        convert('<style>p{color:red}</style><p>正文</p>'
            '<script>alert(1)</script>'),
        '正文',
      );
    });

    test('entities are decoded, and an escaped ampersand only once', () {
      expect(convert('<p>a &amp; b &lt;c&gt; &quot;d&quot;</p>'),
          'a & b <c> "d"');
      expect(convert('<p>&amp;lt;</p>'), '&lt;',
          reason: '&amp;lt; 被解码了两次，变成了一个尖括号');
    });

    test('whitespace between tags is collapsed the way HTML collapses it', () {
      expect(convert('<p>一   行\n   文字</p>'), '一 行 文字');
    });

    test('attributes on the tags are ignored, not printed', () {
      expect(
        convert('<p class="x" style="color:red" dir="ltr">正文</p>'),
        '正文',
      );
    });

    test('an unclosed tag does not lose the rest of the document', () {
      // Browsers emit these; giving up would throw away the whole paste.
      expect(convert('<p>一段<p>二段'), '一段\n\n二段');
    });
  });

  group('a whole page fragment', () {
    test('a mixed fragment keeps every structure it had', () {
      const fragment = '''
<div>
  <h2>安装说明</h2>
  <p>按 <strong>顺序</strong> 执行下面的步骤：</p>
  <ol>
    <li>下载 <a href="https://example.com/dl">安装包</a></li>
    <li>解压到任意目录
      <ul><li>不要放在 <code>Program Files</code> 下</li></ul>
    </li>
  </ol>
  <blockquote><p>提示：需要管理员权限。</p></blockquote>
  <table>
    <tr><th>平台</th><th>状态</th></tr>
    <tr><td>Windows</td><td>可用</td></tr>
  </table>
</div>''';
      final markdown = convert(fragment)!;

      expect(markdown, contains('## 安装说明'));
      expect(markdown, contains('**顺序**'));
      expect(markdown, contains('1. 下载 [安装包](https://example.com/dl)'));
      expect(markdown, contains('  - 不要放在 `Program Files` 下'),
          reason: '子列表没有缩进到父项下面');
      expect(markdown, contains('> 提示：需要管理员权限。'));
      expect(markdown, contains('| 平台 | 状态 |'));
      expect(markdown, contains('| Windows | 可用 |'));
    });
  });

  group('when there is nothing to convert', () {
    test('marked, underlined, raised and lowered text keep their meaning', () {
      // The editor exports `==x==`, `++x++`, `^x^` and `~x~` as <mark>, <u>,
      // <sup> and <sub>, and read none of them back: pasting a page — or the
      // editor's own HTML — dropped the marking and kept only the words.
      expect(convert('<p>看 <mark>重点</mark> 这里</p>'), '看 ==重点== 这里');
      expect(convert('<p>看 <u>压线</u> 这里</p>'), '看 ++压线++ 这里');
      expect(convert('<p>面积 5cm<sup>2</sup></p>'), '面积 5cm^2^');
      expect(convert('<p>水是 H<sub>2</sub>O</p>'), '水是 H~2~O');
    });

    test('a raised phrase with spaces stays plain', () {
      // `^x^` and `~x~` take no spaces — the parser's own rule. Writing the
      // markup anyway would produce a document the editor itself reads as
      // literal carets, which is worse than the plain words.
      //
      // Spaces, not length: a Chinese phrase has none, so it is wrapped and
      // reads back correctly. The first version of this test used one and
      // asserted it stayed plain, which was a claim about the wrong thing.
      expect(convert('<p>see <sup>the note above</sup> here</p>'),
          'see the note above here');
      expect(convert('<p>see <sub>the note below</sub> here</p>'),
          'see the note below here');
      expect(convert('<p>见 <sup>上条</sup> 说明</p>'), '见 ^上条^ 说明',
          reason: '中文短语没有空格，包得起来也读得回来');
    });

    test('an inline tag met at the top level is still read as inline', () {
      // A fragment copied out of a page need not be wrapped in a paragraph:
      // select one word and the clipboard may hold just the tag around it.
      // The list of inline tags the block reader recognises had none of
      // these, so at the top level they were skipped whole.
      expect(convert('<mark>重点</mark>'), '==重点==');
      expect(convert('<u>压线</u>'), '++压线++');
      expect(convert('<sup>2</sup>'), '^2^');
      expect(convert('<sub>2</sub>'), '~2~');
      expect(convert('<code>doThing()</code>'), '`doThing()`');
    });

    test('empty or markup-only html gives null', () {
      // Null rather than empty: the caller then falls back to the plain text,
      // which is a better paste than nothing at all.
      expect(convert(''), isNull);
      expect(convert('   '), isNull);
      expect(convert('<div></div>'), isNull);
      expect(convert('<style>p{}</style>'), isNull);
    });
  });
}
