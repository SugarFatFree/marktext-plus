# MarkText Plus v1.6.3

> Release notes. English is the default language; the Chinese section follows.
>
> **This version is still being written.** What follows covers the changes made
> so far and will grow until the release is cut.

## English

Three fixes so far, and they are all one thing seen from different angles: a
guard that was written to catch the shape of the one failure its author had in
front of them, rather than the rule that failure broke.

### The version number the editor sends out was frozen at 1.6.0

Every plugin-marketplace search identifies this editor to GitHub with a user
agent string. That string was typed out by hand, and the release process — which
carefully updates the version in two files — had never heard of it. It said
1.6.0 while the app shipped 1.6.2.

There was already a guard against exactly this. It had been added after the
About box spent five releases claiming to be v1.0.1. But it looked for a quote
sitting directly against a version number, which is what `'v1.0.1'` looks like,
and `'MarkTextPlus/1.6.0'` has a word in front of the number. The guard now
looks for a version anywhere inside a quoted string, and takes care not to
mistake an address like `127.0.0.1` for one.

### A request that could never end would not have been noticed

After an AI stream left the editor spinning for fifteen minutes, a check was
added: count the requests a file opens, count the waits it bounds, and fail if
there are more of the first. It examined only files that construct an
`HttpClient` and counted only calls named `getUrl`, `postUrl` and so on.

`package:http` does neither — it opens its client out of sight and names its
methods `get` and `post`. So the update check, the one file the guard's own
comment holds up as the example that got this right, was never read by it at
all. An unbounded request could be added there and every test stayed green.
Both the gate and the counting now know about that library.

### The editor can replace itself with a build CI made

`control` takes two new actions. `update_app` fetches a build — from a
published release, or from the package CI already makes for every push —
checks it against the SHA-256 GitHub publishes, and hands it to the installer;
the editor closes and comes back. `install_plugin` is the same thing for a
plugin, along the path the reader's own Install button takes.

The repository is a constant in the code rather than a parameter of the call:
"download something and run it" and "download *this* and run it" are different
powers, and only the second is needed. A build with no published SHA-256 is
refused rather than fetched — that is the one door standing between bytes off
the network and a program running on the machine. An older release is refused,
and so is an update while a document has unsaved work in it, since installing
closes the editor and what is in that tab would go with it.

### Windows installs per-user now ← **uninstall the old copy first**

To `%LocalAppData%\Programs\MarkText Plus` rather than Program Files, so
neither installing nor updating needs administrator rights and neither raises
a UAC prompt. File associations, the Start Menu entry and the desktop shortcut
are unchanged.

**If your current copy went into Program Files**: the new installer cannot see
it — one records itself under HKLM and the other under HKCU — so it installs
fresh and the old one stays where it is. Remove it by hand, once. Every update
after that will leave you alone.

### Updating a plugin no longer throws away what you configured

A plugin's settings are kept inside its own directory, and installing replaces
that directory wholesale, so every update wiped the endpoint, the key and the
target language and the plugin came back looking newly installed. It was
survivable while updating meant deliberately downloading a ZIP; `install_plugin`
makes updating routine, which is what turned this into a fix.

### Markdown that came out wrong

Four things the parser read differently from what you wrote, each of which
could take a large part of a document with it:

- A line reading `` ``` aa ``` `` is a code span. It was opening a code block
  that never closed, so everything below it became code.
- A fence indented four columns opened a code block in the preview while the
  source pane went on colouring the lines inside it as ordinary markdown. Four
  columns of indentation is an indented code block; the two panes agree now.
- A sentence that wrapped before a number — "…is / 14. The number of doors…" —
  was taken apart into a paragraph and a list numbered from fourteen. A
  numbered list interrupts a paragraph only when it is numbered 1, which is
  what GitHub does too.
- A backslash inside a code span was eaten as an escape, so `` `\.` `` came
  out as `.` and `` `C:\temp\*.md` `` lost a separator. A code span is
  literal.

### Adding italic to bold text no longer takes the bold away

Select the words inside `**bold**` — not the asterisks, just the words, which is
how most people reach for a format — and press Ctrl+I. You used to get
`*bold*`: one asterisk taken from each side, the bold gone, nothing saying so.
It nests now, `***bold***`, and pressing Ctrl+I again takes the italic back off.

The same press across two bold paragraphs at once lost the bold in both. And
asking for subscript inside `~~struck~~` wrote three tildes, which at the start
of a line is a code fence — the paragraph and everything after it disappeared
into a code block. Three tildes are never written now: subscript and
strikethrough cannot be nested in this flavour, so the one you press takes the
other's place.

Which markers compose and which replace each other is one rule in one place,
asked by all three of the paths that used to answer it differently.

### The source pane paints a nested run as one colour

`***bold***` was painted as `***bold**` in the bold colour followed by a plain
asterisk — the pane saying that last marker is not part of the emphasis, while
the pane beside it read all six. With Ctrl+I on bold text now writing that
shape, every nested run in a document carried a stray asterisk. It is one span
now, bold and italic, and `___bold___` with it.

### Two panes no longer disagree about a run of three before a full stop

`***bold.***after` was tinted bold in the source pane and drawn as six literal
asterisks in the preview. The bold pattern matches `***bold.**` out of that line,
and the flanking rule was asked about the two asterisks the pattern captured
rather than the three that are there — so the character after the "opening
delimiter" was another delimiter, and a run that can neither open nor close
looked like it could do both. The run is measured now, at both ends.

A Chinese sentence reaches this shape far more often, because `。` ends a
sentence where an English full stop would more often fall outside the words
being marked.

### Pasting from the web no longer turns a paragraph into a code block

A `<del>` holding a `<sub>` — strikethrough around a subscript — was written as
`~~~x~~~`, and three tildes at the start of a line open a fenced code block. The
pasted paragraph went inside one, and so did whatever was written after it.

`del` was the only one of the five wrapping tags with no guard on what it was
wrapping, and the guard the other four use would not have caught this one: it
asked whether the text *contains* the marker, and `~x~` only *touches* it. Both
are asked now. When strikethrough and subscript cannot both be written — and in
this flavour they cannot — the inner one is kept, which is what the other four
tags have always done. `<strong><em>` still nests as `***x***`, because a run of
three asterisks is exactly what it means.

### Code pasted from the web keeps its backticks

A run of backticks ends at the next run of the same length, and the converter
always wrote one around an inline `<code>` and three around a `<pre>` without
looking at what was inside. So a JavaScript template literal copied off a page
came back in three pieces with the backticks it was quoting gone, and a code
block that itself contained a fence was split into a block, a paragraph and an
empty block. The delimiter is longer than anything inside it now.

### A large document's first paint no longer cuts a block in half

A document over 1500 lines is shown in two passes, the top of it first. That
first pass could stop inside a `<pre>` or a `$$ … $$` block, which then
swallowed everything after it until the whole document arrived.

### The plugin marketplace speaks your language when it fails

"could not reach GitHub; check the network or a proxy" was English in all
twelve languages — in red, at the moment you most need to understand it. The
two failures you can act on, no network and GitHub asking you to wait, are
translated now, with the seconds.

### Right to left

A quote's accent bar stood on the left in Arabic, across the quote from where
the words start, and the rule between the line numbers and the code stayed on
one side while the numbers moved.

### Smaller

- The explanation of why the About box's version broke was attached to the undo
  and redo method rather than to the About box, where the next person to touch
  it would read it.
- The check that every icon-only button carries a tooltip could not see
  Material 3's named constructors, so an `IconButton.filled` without one would
  have shipped unannounced.
- Setting the view mode over the automation interface said it had happened
  before it had, so an agent asking for the state in the next breath could be
  shown the old one.
- How long each step of starting up took can now be read over the automation
  interface. The log carried one number — "+901 ms before Dart" — and loading
  the executable, booting the engine and reading the snapshot are three
  different problems with three different answers.

## 中文

到目前为止三条修复，其实是同一件事的三个侧面：**守卫是照着作者眼前那一个坏掉的
实例写的，而不是照着被它破坏的规则写的。**

### 编辑器对外报的版本号停在 1.6.0

插件市场每次搜索都会带一个 user-agent 告诉 GitHub 自己是谁。那个字符串是手写的，
而发版流程只盯着两个文件里的版本号，从来不知道还有第三处。应用是 1.6.2，它说 1.6.0。

这件事**本来是有守卫的**——「关于」对话框连着五个版本自称 v1.0.1 之后立的。
但它找的是「引号紧贴版本号」，因为 `'v1.0.1'` 就长那样；`'MarkTextPlus/1.6.0'`
版本号前面有字，就漏了。现在改成在任意引号字符串内部找版本号，同时避开
`127.0.0.1` 这类看着像版本号的地址。

### 一个永远结束不了的请求，它也看不见

AI 流让编辑器空转十五分钟之后，立了一条规矩：数一数每个文件发出多少请求、
限住多少次等待，少了就红。但它只看构造了 `HttpClient` 的文件，只数
`getUrl` / `postUrl` 这类名字。

`package:http` 两条都不占——它的客户端开在看不见的地方，方法就叫 `get`、`post`。
于是更新检查，**守卫注释里被当作正面例子引用的那个文件**，从来没被它读过。
往那里加一个没有上限的请求，所有测试照样全绿。现在门槛和计数都认得这个库了。

### 编辑器可以自己更新自己了

`control` 新增两个动作。`update_app` 取一个构建——来自已发布的 release，或来自
CI 为每次推送本来就打好的包——比对 GitHub 公布的 SHA-256，然后交给安装器；
编辑器关闭，再自行回来。`install_plugin` 是同一件事的插件版，走的是读者点
「安装」那条一模一样的路。

仓库是代码里的常量而不是调用方给的参数——「下载一个东西并运行它」和「下载**这一个**
东西并运行它」是两种权力，只需要后者。没有公布 sha256 的构建直接拒绝：那是唯一一道
挡在「网络上来的字节」和「机器上运行的程序」之间的门。比当前旧的 release 会被拒绝；
**有未保存内容时也会被拒绝**——安装要关掉编辑器，那个标签页里的东西会跟着一起没。

### Windows 安装包改为按用户安装 ← **升级前请先卸载旧版**

装到 `%LocalAppData%\Programs\MarkText Plus` 而不是 Program Files，安装与更新都
不再需要管理员权限，也就不再弹 UAC。文件关联、开始菜单项、桌面快捷方式照旧。

**如果你之前装的是 Program Files 版本**：新安装器看不见它（两者的卸载信息一个在
HKLM、一个在 HKCU），会当作全新安装，旧的那份会留在原地。请手动卸载一次旧版。
这是一次性的，之后所有更新都不会再打扰你。

### 更新插件不再清空你填过的设置

插件的设置存在它自己的目录里，而安装是整目录替换——所以每更新一次，端点、密钥、
目标语言全都没了，插件回来时像是刚装上的。以前更新意味着有人专门去下一个 ZIP，
一年碰不到一次；`install_plugin` 让更新成了常规动作，这才把它从「能忍」变成「必须修」。

### 解析错了的 Markdown

四处解析与你写的不一致，每一处都可能带走文档的一大片：

- 一行 `` ``` aa ``` `` 本是行内代码，却开启了一个永不闭合的代码块，
  **它下面的全部内容都变成了代码**。
- 缩进四列的围栏在预览里开了代码块，源码区却照常把里面的行染成普通标记。
  缩进四列是缩进代码块——两个窗格现在说法一致。
- 在「数字.」前换行的句子被拆成一个段落加一个从十四开始的列表。
  有序列表只有编号为 1 时才能打断段落，GitHub 也是这样。
- 代码跨度里的反斜杠被当成转义吃掉：`` `\.` `` 显示成 `.`，
  `` `C:\temp\*.md` `` 少一个分隔符。代码跨度是字面的。

### 给粗体加斜体不再把粗体删掉

选中 `**加粗**` 里面的两个字——不选星号，只选字，这是大多数人加格式的方式——
按 Ctrl+I。以前会得到 `*加粗*`：两边各拿掉一个星号，**粗体没了，也没有任何提示**。
现在会嵌套成 `***加粗***`，再按一次 Ctrl+I 只取消斜体。

同一个按键作用于两段各自加粗的段落时，两段的粗体会**一起**消失。而在
`~~删除线~~` 里要下标会写出三个波浪号——行首三个波浪号是**代码围栏**，
这一段连同后面的全部内容都会掉进代码块里。现在绝不会写出三个波浪号：
下标与删除线在本方言里无法嵌套，所以你按下的那一个取代另一个。

哪些标记会叠、哪些互相取代，现在是一处的一条规则，从前各自给出不同答案的
三条路径都来问它。

### 源码区把嵌套的强调染成同一个颜色

`***加粗***` 以前被染成 `***加粗**`（加粗色）加一个普通色的星号——窗格在说
最后那个标记不属于这段强调，而旁边的窗格读到的是全部六个。既然 Ctrl+I 作用于
粗体现在就会写出这个形状，文档里每一处嵌套强调都会拖着一个落单的星号。
现在是一段，同时是粗体和斜体，`___加粗___` 也一样。

### 两个窗格不再对 `***加粗。***后面` 各说一套

源码窗格把这一行染成加粗色，预览画的是字面的星号。加粗模式从里面匹配出
`***加粗。**`，而贴合规则被问的是**它捕获的那两个**星号、不是实际存在的三个——
于是「开标记后面」答出来是另一个标记，这个运行看上去既能开又能闭。现在运行是
量出来的。中文句子以 `。` 收尾的频率远高于英文句号出现在被标记的词里，
所以这个形状每天都会遇到。

### 从网页粘贴不再把一个段落变成代码块

`<del>` 里套 `<sub>`——删除线里面套下标——以前写出 `~~~x~~~`，而行首三个波浪号
开启一个代码围栏。粘贴进来的这一段掉进代码块，**接着写的文字也一起进去**。

`del` 是五个包裹类标签里唯一没有守卫的，而另外四个用的那道守卫也挡不住这一种：
它问的是文本**含不含**该标记，而 `~x~` 只是**贴着**它。现在两件都问。
删除线与下标无法同时写出时——在本方言里就是无法——保住里面那个，
这是另外四个标签一直以来的约定。`<strong><em>` 照旧嵌套成 `***x***`，
因为三个星号一串正是它的意思。

### 从网页粘贴的代码保住它的反引号

一段反引号在遇到同样长度的下一段时结束，而转换器从不看内容里有几个——内联一律
写一个，代码块一律写三个。于是从网页复制的 JavaScript 模板字符串回来时断成三截、
它引用的反引号全丢，而本身含有围栏的代码块被拆成一个代码块、一个段落和一个空代码块。
现在分隔符总比内部任何一段更长。

### 大文档的第一屏不再把块切成两半

超过 1500 行的文档分两趟显示，先出顶部。那一趟可能停在 `<pre>` 或 `$$ … $$`
块的中间，未闭合的块会吞掉它后面的全部内容，直到整篇解析到达。

### 插件市场出错时说你的语言

「could not reach GitHub; check the network or a proxy」以前对十二种语言的读者
都是英文——红色的，而那正是最需要看懂的时刻。现在你能据以行动的两种失败
（连不上、GitHub 让你等）都翻译了，连秒数一起。

### 从右往左

阿拉伯语下引用块的竖线站在左边，离它标记的文字最远；源码窗格行号与代码之间的
细线也没跟着行号一起翻到另一侧。

### 其他

- 解释「关于框版本号为什么会写死」的那段注释，原先挂在撤销/重做上，
  下一个改关于框的人读不到。已归位。
- 「每个只有图标的按钮都要带提示」这条检查认不得 Material 3 的三个命名构造，
  一个没有 tooltip 的 `IconButton.filled` 会悄无声息地发出去。
- 通过自动化接口切换视图模式时，答复说「已经切好了」而其实还没有——
  代理紧接着读状态可能读到旧值。
- 启动每一步的耗时现在可以通过自动化接口读到。日志里原本只有一个数
  ——「+901 ms before Dart」——而加载可执行文件、启动引擎、读取快照
  是三个不同的问题，答案也不同。
