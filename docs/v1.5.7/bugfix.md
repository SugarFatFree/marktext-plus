# v1.5.7 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-212 | 2026-09-01 | 折行写的链接定义不被识别，源码作为正文显示给读者 | P1 | 已修复 |
| BUG-213 | 2026-09-01 | 列表项下用 Tab 缩进的内容，开头的字被静默删掉 | P1 | 已修复 |
| BUG-214 | 2026-09-01 | 缩进漂移一个空格的列表被画成层层嵌套 | P2 | 已修复 |
| BUG-215 | 2026-09-01 | 文档里出现过引用块或带块的列表项，其后所有引用式链接全部失效 | P1 | 已修复 |
| BUG-216 | 2026-09-01 | 从网页粘贴：任务勾选状态、代码语言、样式排版的加粗全部丢失 | P2 | 已修复 |
| BUG-217 | 2026-09-01 | 源码区 Ctrl+A 后复制到 Word 丢失格式，复制到记事本丢失换行 | P1 | 已修复 |
| BUG-218 | 2026-09-01 | 编辑菜单中的复制和剪切没有保留 Markdown 富文本格式 | P2 | 已修复 |

---

## BUG-212：折行写的链接定义不被识别，源码泄漏成正文

### 现象

把网址集中放在文末、并给较长的定义折行——这是很自然的写法：

```markdown
见 [文档][doc] 与 [仓库][repo]。

[doc]: https://example.com/doc
  "使用手册"
[repo]: https://example.com/repo
```

预览里得到的是：

- `[doc]` 的**标题丢失**
- **`"使用手册"` 和 `[repo]: https://example.com/repo` 作为一个段落画给读者看**——
  定义的源码泄漏进了文档正文

也就是说，**一条折行的定义会把它下面的定义一起拖下水**。
网址写在下一行（`[doc]:` 换行再写网址）同样完全不被识别。

### 根因分析

链接定义的识别只有一条单行正则：

```dart
r'^\s{0,3}\[([^\^\]][^\]]*)\]:\s*(\S+)(?:\s+"([^"]*)")?\s*$'
```

它要求标签、网址、标题**全部写在同一行**。而 CommonMark 允许定义跨行：
标签之后、网址之后各可以有**至多一个换行**。

这条正则同时被两处使用——收集定义、以及在块循环里跳过定义行。
不匹配时两处都失效：定义没被收集（链接解析不出来），
也没被跳过（源码落到段落分支被画了出来）。

### 修复方案

换成一个能跨行的小解析器 `_linkDefinitionAt(lines, start)`，
最多读三行（标签行、网址、标题）：

- 至多三格缩进，`[标签]:`，标签内支持 `\]` 转义
- 跨越**至多一个换行**的空白，然后是网址（`<...>` 形式或非空白串）
- 再跨越至多一个换行的空白，然后是可选标题（`"…"` / `'…'` / `(…)`）
- 每一部分之后，该行剩余内容必须为空白

**标题解析失败时回退成「无标题的定义」**——这是规范的要求，
也避免了「因为标题写坏了，整条定义连同下面的定义一起变成正文」。

返回值带 `end`（定义占用到第几行），块循环据此跳过正确的行数。

### 验证

新增 9 条。4 条覆盖折行的各种形式；5 条护栏：单行形式不变、
`[^1]:` 仍是脚注（旧正则专门排除过它，不能丢）、空行会终止定义、
散文里的方括号仍是散文、代码块里展示的定义仍是示例。

把窗口从三行改回一行后，4 条折行测试失败 + 规范棘轮回落。

### 影响

CommonMark 一致性 **486 → 491**，下限同步提到 491。

### 涉及文件

- `code/lib/services/markdown_parser.dart`
- `code/test/services/link_definition_wrapped_test.dart`（新增，9 条）
- `code/test/services/commonmark_spec_test.dart`（下限 486 → 491）

---

## BUG-213：列表项下用 Tab 缩进的内容，开头的字被静默删掉

### 现象

```markdown
- 甲

	乙丙丁戊
```
（第二段用**一个 Tab** 缩进）

预览里第二段显示为「**丙丁戊**」——「乙」被删掉了。
换成有序列表 `1. 甲`，缩进宽度多一列，于是被删掉两个字：「丁戊」。

Tab 缩进的代码围栏更糟：

```markdown
- 甲

	```dart
	var x = 1;
	```
```

围栏根本没被识别，内容变成行内代码，而且 `var` 的 `v` 也被吃掉了。

**这是静默的正文删除**——预览和三条导出路径里都少了字，没有任何提示。

### 根因分析

缩进宽度是按**列**量的（`_indentColumns` 把 Tab 展开成至多 4 列），
而 `_dedent` 去缩进时用的是：

```dart
line.substring(strip)     // strip 是列数，substring 按字符
```

一个 Tab 是 **4 列、1 个字符**。于是按列数去截字符，多切掉的部分正是用户的正文。
有序列表的内容起始列更靠右（`1. ` 是 3 列），被吃的字就更多。

代码里**早就有一个按列正确处理的 `_stripIndent(line, columns)`**——
围栏代码块和缩进代码块一直在用它。`_dedent` 是唯一没去问它的地方。
又是「同一条规则有一份正确实现，另一处自己写了个错的」。

### 修复方案

`_dedent` 改用 `_stripIndent`。一行改动。

`_stripIndent` 在 Tab 跨越边界时会把整个 Tab 移除——多去掉的是空白，
**不会碰到正文**，这正是这里需要的性质。

### 验证

新增 7 条。核心断言是**用 Tab 缩进与用空格缩进必须得到同一篇文档**——
这比逐字符比对更能表达意图，也不会因导出器的排版空白而误报。
4 条覆盖丢字的各种形态；3 条护栏：空格缩进结果不变、Tab 缩进的子列表仍是子列表、
四列缩进（Tab 或空格）仍然是代码块。

改回按字符截取后 3 条失败 + 规范棘轮回落。

**一处测试自身的修正**：护栏那条最初拿导出的 HTML 做精确字符串比对，
因标签间的换行而失败。改成折叠标签间空白后再比——那条断言想说的是
「文档结构不变」，不是「导出器怎么排版」。

### 影响

CommonMark 一致性 **491 → 492**，下限同步提到 492。

### 涉及文件

- `code/lib/services/markdown_parser.dart`
- `code/test/services/tab_indent_test.dart`（新增，7 条）
- `code/test/services/commonmark_spec_test.dart`（下限 491 → 492）

---

## BUG-214：缩进漂移一个空格的列表，被画成层层嵌套

### 现象

```markdown
- 甲
 - 乙
  - 丙
   - 丁
```

四个平级的条目（每级只多一个空格），预览里画成了**四层嵌套的列表**。
手写、或从别处粘贴过来的列表，缩进有一两个空格的漂移是很常见的。

有序列表同理：`1. 甲` 下面缩进两个空格的 `2. 乙` 被当成了子项。

### 根因分析

深度是这么算的：

```dart
final widths = itemBlocks.map((b) => _indentColumns(b.first)).toSet().toList()..sort();
...
final depth = widths.indexOf(_indentColumns(block.first));
```

**「文档里出现过多少种不同的缩进宽度，就有多少层」**——
缩进值的排名被当成了层级。四个各差一个空格的条目于是有四种宽度、四个层级。

正确的规则是：一个条目只有缩进到**上一个条目正文的起始列**时，才算它的子项。
`- ` 的正文起始列是 2，`1. ` 是 3，`10. ` 是 4——差一列都算同级。

### 修复方案

改用一个「当前打开的条目」栈，栈里存各层的**正文起始列**：

```dart
while (open.isNotEmpty && indent < open.last) open.removeLast();
depths.add(open.length);
open.add(_contentColumn(block.first));
```

### 一条既有测试的期望值是错的

`ordered lists nest too` 断言 `1. one` / **两空格** `2. nested` 的深度为 `[0, 1, 0]`。
按新规则应当是 `[0, 0, 0]`。

**没有凭我自己读规范就改断言**，而是拿参考实现 `marked` 判：

| 写法 | marked |
|---|---|
| `1. one` + 两空格 `2. nested` | **同级** |
| `1. a` + 三空格 `2. b` | 嵌套 |
| `- 甲` + 一空格 | 同级 |
| `- 甲` + 两空格 | 嵌套 |

参考实现确认新规则正确，**那条断言固化的是解析器过去的行为，不是列表的含义**。
改为同时钉住两侧：两空格同级、三空格嵌套。

### 验证

新增 10 条：无序/有序各自的边界（差一列同级、够到正文列嵌套）、
更宽的标记（`10. ` 需要四列）、漂移后又退回来仍在同一层；
3 条护栏：正常嵌套不变、三层写法仍是三层、Tab 缩进的子项仍嵌套。

把栈里存的列改成「缩进 + 1」（即任何多一点缩进都算子项）后 5 条失败 + 棘轮回落。

### 影响

CommonMark 一致性 **492 → 493**，下限同步提到 493。
分数只涨 1 分，但这一簇里的 5 个例子结构全部修正了——
它们各自还带着别的规范细节（松散列表的 `<p>` 包裹等），所以没有全部转绿。

### 涉及文件

- `code/lib/services/markdown_parser.dart`
- `code/test/services/list_indent_depth_test.dart`（新增，10 条）
- `code/test/services/markdown_parser_test.dart`（一条错误期望改正）
- `code/test/services/commonmark_spec_test.dart`（下限 492 → 493）

---

## BUG-215：文档里有引用块之后，所有引用式链接全部失效

### 现象

```markdown
> 引用一句话

见 [手册][doc]。

[doc]: /doc "使用手册"
```

`[手册][doc]` **原样显示成字面文字**，链接完全解析不出来。
把那句引用删掉，链接立刻正常。

不只是引用块——**列表项携带的块**（第二段、代码块等）同样会触发。
换句话说：**只要文档里在引用式链接之前出现过引用块或带块的列表项，
后面所有引用式链接一律失效。**

### 根因分析

`parse()` 开头会 `_linkDefinitions.clear()`，
因为解析器实例会被复用，上一篇文档的定义不能泄漏到下一篇。

但**引用块的内容、以及列表项携带的块，是用同一个解析器实例递归调用 `parse()` 的**。
于是顺序变成：

1. 外层 `parse()` 扫描全文，收集到所有定义
2. 块循环走到引用块 → 递归调用 `parse(引用内容)`
3. **递归那次把 `_linkDefinitions` 清空了**，只收集引用块内部的定义
4. 回到外层，继续处理后面的段落——定义已经没了

### 修复方案

加一个 `_parseDepth` 计数，**只有最外层那次调用才清空**。
嵌套调用沿用外层已收集的定义，并把自己新发现的补进去
（收集用的是 `putIfAbsent`，所以文档序在前的定义仍然优先）。

### 这个缺陷为什么一直没被发现

**CommonMark 规范语料抓不到它。** 语料里每个例子都是孤立的单一构造，
而这个缺陷需要「引用块」和「引用式链接」**同时出现在一篇文档里**——
修复前后规范分数都是 493，纹丝不动。

真正发现它的是另一件事：我在把本版三处解析器改动**逐一送过全部输出路径**
（HTML / PDF / Word / 富文本复制）时，那份「把本周所有新构件放进同一篇文档」
的测试文档里恰好既有引用块又有引用式链接，于是暴露了出来。
**把构件组合进一篇真实文档，比逐个验证更能发现问题。**

### 验证

新增 8 条：引用块、惰性续行的引用块、携带第二段的列表项、引用里套列表、
多层嵌套——各自之后的引用式链接都要能解析；
3 条护栏：定义写在引用之前仍有效、**换一篇文档解析时上一篇的定义不得残留**
（清空本来就是为这个存在的）、未定义的标签仍是散文。

去掉深度判断后 6 条失败。

### 涉及文件

- `code/lib/services/markdown_parser.dart`
- `code/test/services/definitions_survive_nesting_test.dart`（新增，8 条）
- `code/test/services/export_survives_new_constructs_test.dart`
  （文档扩充为累积式，并补上本版构件的断言）

---

## BUG-216：从网页粘贴时丢失勾选状态、代码语言与样式化的排版

### 现象

剪贴板的 HTML 版本转成 Markdown 时，有四处信息被丢掉：

| 粘贴来源 | 丢了什么 |
|---|---|
| GitHub / Notion 的待办清单 | `<input type="checkbox" checked>` → `- 已办`，**勾选状态全没了** |
| 任何文档站的代码块 | `class="language-dart"` → 光秃秃的 ` ``` `，**语言丢失，粘过来没有高亮** |
| Google Docs 等网页文字处理器 | `<span style="font-weight:700">` **完全不识别**，加粗/斜体/删除线全变普通文字 |
| Google Docs 的片段 | 它把内容包在 `<b style="font-weight:normal">` 里——**内联场景下整段会被错误加粗** |

### 根因分析

- **勾选状态**：`_writeList` 只写 `- ` 或 `1. `，从不看条目里有没有 `<input>`。
- **代码语言**：`pre` 分支只取文本，不读内层 `<code>` 的 `class`。
- **样式排版**：转换器只认标签（`<b>`/`<i>`/`<del>`），而网页文字处理器用的是内联样式。
- **Google Docs 的包裹层**：`<b>` 分支无条件加粗，不看它自己的 style 是否说了「不粗」。

### 一处先被证伪、再被证实的猜想

我最初以为 Google Docs 的外层 `<b style="font-weight:normal">` 会让**整段粘贴变粗**。
实测：**不会**——因为它包着块级 `<p>`，块级处理会跳过该标签。

但顺着这条线继续试内联场景（复制一个片段、没有 `<p>`），
`<p><b style="font-weight:normal">不该粗</b></p>` **确实**输出了 `**不该粗**`。
**猜想的方向对、给出的机制错**；不实测就会把这条当成不存在。

### 修复方案

- `_taskBox`：条目里找 `<input type="checkbox">`，输出 `[x] ` / `[ ] `。
  `checked` 是布尔属性，三种写法（裸写、`=""`、`="checked"`）都认。
- `_codeLanguage`：读内层 `<code>` 的 class，支持 `language-` 与 `lang-` 两种前缀，
  且能从 `hljs language-go` 这类多值 class 里挑出来。
- `_style` / `_wrapStyled`：解析内联样式里的 `font-weight`（`bold` 与 ≥600 的数值）、
  `font-style`、`text-decoration`。`text-decoration:none` 不能当成删除线。
- `<b>`/`<strong>` 若自身 style 声明了非粗体字重，就不加粗。
- 块级遇到行内包裹标签（`span`/`b`/`strong`/`i`/`em`/`u`/`del`/`s`/`a`/`font`）时，
  内部没有块级元素就整体按行内处理——否则 Google Docs 的片段会变成
  「一个 span 一个段落」且样式全失。

### 验证

新增 15 条。护栏 6 条：真正的 `<b>` 仍加粗、无样式的 span 不留痕迹、
`text-decoration:none` 不是删除线、单选框不是任务框、
未标语言的代码块仍是无标签围栏、标题/列表/表格/链接照常转换。

四处修复分别破坏后共 8 条失败。

### 涉及文件

- `code/lib/services/html_to_markdown.dart`
- `code/test/services/paste_from_the_web_test.dart`（新增，15 条）

---

## BUG-217：源码区全选复制丢失富文本格式和换行

### 现象

在源码编辑区使用 `Ctrl+A` 后再按 `Ctrl+C`，粘贴到 Word 时标题、粗体、列表等 Markdown 语义全部消失；粘贴到记事本时部分 Windows 路径下的换行也会丢失。

### 根因分析

源码编辑区之前让 Flutter `TextField` 处理默认复制。默认实现只写入 `ClipboardData.text`，没有写入 `HTML Format`，因此 Word 只能收到 Markdown 源文字符号，无法恢复标题和强调。Windows 原生剪贴板的 `CF_UNICODETEXT` 写入也直接使用 LF；部分 Windows 文本消费者要求标准 CRLF，导致纯文本粘贴时换行不稳定。

### 修复方案

- 在源码编辑器的 `Ctrl+C` / `Cmd+C` 分支中截取当前选择，同时保留原始 Markdown 作为纯文本，并通过 `RichCopyService.htmlForMarkdownSelection` 生成 HTML 富文本。
- 统一走 `ClipboardService.copyWithHtml`，Word 等富文本应用读取 HTML，记事本等纯文本应用读取原始内容。
- Windows 写入 `CF_UNICODETEXT` 前将 LF 规范化为 CRLF，避免文本应用吞掉换行。
- 未选中文本时继续交给 Flutter 默认行为，避免改变光标和普通输入流程。

### 验证

新增服务测试验证源码 Markdown 会生成标题、粗体和列表 HTML，并验证 Windows 纯文本的 LF → CRLF 规范化；复制专测试例通过。完整测试与静态分析均通过。

### 涉及文件

- `code/lib/ui/editor/source_editor.dart`
- `code/lib/services/rich_copy_service.dart`
- `code/lib/services/clipboard_service.dart`
- `code/test/services/rich_copy_test.dart`
- `code/test/services/clipboard_channel_test.dart`

---

## BUG-218：编辑菜单复制和剪切未保留富文本格式

### 现象

源码区通过编辑菜单执行“复制”或“剪切”时，粘贴到 Word 只有 Markdown 源文本，标题、粗体、列表和链接没有格式。

### 根因分析

快捷键路径已改为调用 `ClipboardService.copyWithHtml`，但编辑菜单的两个入口仍直接调用 `Clipboard.setData(ClipboardData(text: selected))`，形成了第二份落后的复制实现。

### 修复方案

复制和剪切菜单统一调用 `RichCopyService.htmlForMarkdownSelection` 生成 HTML，并通过 `ClipboardService.copyWithHtml` 同时写入纯文本和 HTML；剪切仍立即删除编辑器中的选区。

### 验证

新增菜单复制守卫测试，确认复制和剪切入口各调用一次富文本转换与双格式剪贴板服务；`unawaited` 守卫、全量测试和静态分析通过。

### 涉及文件

- `code/lib/ui/widgets/app_menu_bar.dart`
- `code/test/ui/widgets/menu_copy_rich_guard_test.dart`
