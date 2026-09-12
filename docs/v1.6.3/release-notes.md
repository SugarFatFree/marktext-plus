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

### A pasted table keeps its shape when a cell holds two lines

A row ends at a line ending, so a cell cannot hold one — and a `<br>` inside a
cell was written as one. `<td>a<br>b</td><td>c</td>` came back as a row holding
`a` and nothing, then a row holding `b` and `c`: every cell after the break moved
a column and the header stopped describing what was under it. Two breaks in one
cell lost the last two pieces outright. Separate paragraphs in a cell, which is
what a word processor puts on the clipboard, arrived with the words run together
as `onetwo`.

A break in a cell becomes a space now, and a block boundary becomes one too. GFM
writes the break as an inline `<br>`, which this editor reads only when HTML is
turned on and it is off by default — so that would have shown a tag where someone
wrote a line.

### A pasted link is no longer cut short by its own address

A destination ends at the `)` that closes it and a label at the `]`, and the
converter wrote both without asking what was inside. A link to an address holding
an unbalanced bracket came back pointing at the part before it, with the rest
leaking into the paragraph as text; an address holding a space stopped being a
link at all; and a label holding a `]` — "see [1] here" — arrived as literal
characters with the address showing beside them. Images went the same way.

Addresses that need it are written between angle brackets, which the format
allows for exactly this, and brackets in a label are escaped. An address that
needs neither is left alone, so a balanced `http://x/a(b)c` still looks like
itself. A linked thumbnail stays an image: only the label's text is escaped, not
the markup inside it.

### A pasted italic is no longer cut short by an asterisk in the text

An emphasis ends at the run that closes it, so `<em>a*b</em>` — written as
`*a*b*` — came back with the italic stopping at the reader's own asterisk and the
rest of it left as a stray character. Bold went the same way on a doubled one.

The asterisks in the text are escaped rather than the emphasis being dropped,
because dropping it is what the other wrapping tags do and it would cost more
than the bug here: italic around bold is an everyday shape and the markup for the
inner one is asterisks. Nothing is lost now, and a code span inside an emphasis
keeps its asterisks untouched — a backslash in code is a backslash.

### Exported HTML reads back as the document it came from

Five things the export could write and the paste path could not read: a link's
title, inline maths, a maths block, a footnote reference and a footnote
definition. So a document exported to HTML and pasted back — or formatted text
copied between two MarkText windows — came back with its tooltips gone, its
formulas turned into the parentheses `\(a+b\)` reads as, and its footnotes split
into a superscript wrapped around a link, no longer joined to the note they named.

This had happened once before, to four other tags, and the fix then was the four
tags rather than a way of noticing. Now every kind of block and span needs either
a sample that survives the round trip or an exemption saying why it cannot, so a
new kind fails until somebody has decided which it is. Three are exempt, each
with its reason written down.

### A picture pasted from a lazily loading page is the picture

Reading an attribute matched the end of a longer name: asking for `src` found
`data-src`, `href` found `data-href` and `title` found `data-title`, so which
value a paste used was decided by which attribute the page happened to write
first. The whole name has to match now.

On its own that would have been a step backwards for the web as it is, where a
lazily loaded image keeps a placeholder in `src` and its real address in a data
attribute. That fallback is a decision now instead of an accident of attribute
order, and it is only taken when `src` has nothing usable in it — so a picture
this editor inlined on its way out is left exactly as it was.

### Copy as HTML hands over the editor's HTML

Four places turn a selection into HTML for the clipboard — Ctrl+C, Cut, the
menu's Copy, and the preview's copy — and all four parse the markdown and write
it out the way the export does. The one item named after HTML did not: it ran a
chain of regular expressions over the selected text, four inline forms and six
heading levels, and left everything else as it was.

So a list, a table, a link, an image, a code block, a quote, a formula, a
footnote, a highlight, an underline or a raised letter came out as the markdown
that made it; `**加粗。**后面` came out bold where the preview draws asterisks;
and nothing was escaped, so a selection holding `a < b` produced HTML that no
longer said `a < b`. It uses the same conversion as the other four now.

### A regular-expression search anchors to lines, and a replacement can put back what it found

`^` and `$` meant the start and end of the whole document, so `^#+ ` — the most
natural thing to type into a regular-expression search here, "find every heading"
— found the first heading only if the document opened with one, and nothing
otherwise. They anchor to lines now, as they do in every other editor. `.` still
does not cross a line.

And a replacement can name what the pattern captured: `$1` through `$99` for a
group, `$&` for the whole match, `$$` for a literal dollar — the spelling every
other editor uses. So searching `\[(.+?)\]\((.+?)\)` and replacing with `$2: $1`
turns every link in the selection around, which is the one thing a
regular-expression replace is for. A group number the pattern does not have is
left as it stands rather than quietly becoming nothing, and a literal search still
replaces literally, so `$5` stays `$5`.

### The AI endpoint accepts the base URL the provider documents

Every provider writes its base URL with the version on the end — OpenAI's
`https://api.openai.com/v1`, Anthropic's `https://api.anthropic.com/v1`, and so
does every service that speaks the same protocol, from a local Ollama to
OpenRouter. That is what gets pasted into the endpoint field, and the version was
appended anyway: the request went to `/v1/v1/chat/completions` and came back a 404
whose body says nothing about a doubled path, so it read as a missing model or a
dead service.

Both spellings work now, with or without the `/v1`. The field's own advice — enter
the root, not the full request path — is true either way, so it has not changed.

### One sentence that was English in every language

A plugin declaring no settings was told so in English — `X has no settings.` —
whatever language the rest of the window was in. It was the only one of the
editor's 403 strings written in the source rather than in the translation files,
and the kind of leak that only somebody reading in another language would notice.

A scan now looks at every place a sentence reaches the reader and fails on a
literal holding two or more running English words, so the next one fails a test
instead of shipping.

### "You have not set the AI up yet" is said in your language, and names one field

Running an AI command before filling in the endpoint, the model and the key is the
first thing anybody meets, and the refusal was an English sentence — in an editor
running in Chinese, Japanese or Arabic. Both places that show it, the plugin
failure dialog and Settings' test button, printed the error exactly as it came.

It is translated now, and it names the one field that is missing instead of
listing three: a reader with only the key blank was being sent to check the
endpoint and the model as well. The field named is the first one missing in the
order they appear on screen, so somebody who has filled in nothing is sent to the
top of the form rather than the bottom.

A provider's own reply is still shown as it came. A 400 about a model that does not
exist or a key that has expired says far more than a sentence of ours could, and
rewriting it would take that away.

### A diagram with a typo no longer explains itself in English inside your PDF

The Mermaid package cannot reach the editor's translations, so its own error box
is English by design and the app words the failure itself. The preview did that;
the export and the fullscreen view did not. So a document with one mistyped
diagram came out of the exporter with a red English panel baked into it — a PDF
the reader then sends to somebody else — and tapping a broken diagram to enlarge
it answered in English too.

All three draw the same box now. The diagram type names inside it stay as they
are, in every language, because they are what has to be typed.

### Editing a large file no longer fills memory with undo history

Every undo step is a whole copy of the document, and the history was bounded at
two hundred steps. For a note that is a few megabytes of history; for a
one-megabyte document it is two hundred megabytes, and for a ten-megabyte one two
gigabytes — per tab, and again for redo. It was the largest thing in the process
and nothing measured it.

The history is bounded by how much text it holds now, as well as by how many
steps. Nothing changes for a document small enough that two hundred copies of it
are cheap, which is almost every Markdown file: everything under about eighty
kilobytes keeps all two hundred steps. Above that the oldest states are dropped
first, and at least one undo is always kept however large the document is.

### Extending a selection through a large document stays smooth

Every selection change copied the whole selected text into the editor's state and
compared it against the one before it, while the three places that want it ask for
it at the moment a command runs. So holding Shift+Down through a large document
copied a progressively larger string on every keypress — the gesture as a whole
quadratic — and a four-megabyte selection then sat in memory until the next one,
beside the document, the text field's own copy and the undo history.

The selection is a range now, and the text is taken when somebody asks. Which pane
answers is unchanged: whichever one the reader touched last, so a plugin run from
the preview is not handed what the source pane had selected a minute ago.

### Moving the caret in a large file is no longer slower than the file

Every caret move split the whole document into lines — twice. The Format menu
works out whether the table commands apply while it is being built, and it did
that by rebuilding the caret's offset from the line and column the status bar
shows, then handing the document to a table lookup that split it again. Over eight
megabytes that is 36.7 ms each, so an arrow key cost about seventy milliseconds
against a frame of 16.7, and holding one down stuttered.

The text field knows where the caret is, and whether the caret is in a table needs
only the line it is on: 0 µs on the same document. The menu still rebuilds when the
caret moves, because the commands grey out when it leaves a table — what it no
longer does is read the document to find out where it went.

One thing changed with it: in preview mode, where there is no text field, the table
commands are greyed out. They used to light up for a position built from whatever
the source pane last reported, which is not somewhere the reader can see.

### Icons that point somewhere point the way you read

In Arabic the file tree indents to the left, and the arrow on a collapsed folder
pointed right — away from where it opens. Two more: the chevron marking the
selected settings category pointed at the edge of the window rather than at the
panel, and the send button's paper plane pointed back the way you came.

The tree's indentation had been direction-aware for a while; the arrow drawn
inside it had not. All three now mirror, and three title bars whose padding put
the wider margin on the wrong side mirror with them.

### Rereading a file in another encoding is a way out of a conflict again

When something else rewrites a file you have open, the status bar says so and
offers three ways out: reload, overwrite, or read it again in an encoding you
pick. The third put the banner away and left the baseline describing the file as
it was *before* the rewrite — so the next save raised the same conflict, over a
change already sitting in your tab. It now records what it read.

Underneath both: that baseline was taken after the bytes rather than before
them, so a write landing between the two was recorded as already seen and the
next save went over it without asking. The comment beside the code argued for
the other order; the code has been brought round to it. Two reading and writing
helpers that nothing used — one of which truncated the file it opened — are
gone, so the unsafe version is no longer the one found first.

### Jumping to a line goes to that line, and typewriter mode works at all

Six things ask the editing pane to go to a line: the outline, the sidebar's two
search lists, a click in the preview, and the find bar when the preview is the
target. The pane turned the line number into a pixel by multiplying by the line
height, which is short by a line for every long line that wrapped above it —
asking for line 20 of a document of long paragraphs left it 1497 pixels below
the bottom of the window.

Typewriter mode had the same sum in it, and something worse: the line it centred
was jumped back to the nearest edge a frame later, by the code that keeps the
caret on screen when the pane scrolls. Whatever it animated to, the caret ended
up against the bottom edge. The two now take turns instead of fighting, and both
wait for the text to be laid out before asking where anything is.

### The formatting strip appears over the text it belongs to

Its horizontal position was measured against the font; its vertical position
was worked out as `line * lineHeight`, corrected for the scroll by hand. Neither
is what the pane draws: a long line in a narrow split pane wraps into several
visual ones, the line height rounds to a whole pixel, and the scroll correction
did not match. Three wrapped lines above the selection put the strip 317 pixels
too high; on line 550 of a 600 line document it left the screen entirely.

Both coordinates now come from the field that is drawing the text.

### Find Next in a large file no longer freezes the editor

Jumping to a match needed the pixel the match had been drawn at, so that it could
be scrolled a third of the way down — and the line number alone will not do, since
in split view a long line wraps into several visual ones. To get that pixel the
editor laid the whole run of text before the match out a second time: 532 ms at one
megabyte, 2.3 seconds at four, for every press. Walking twenty matches meant nearly
a minute of a frozen window.

The pane is already drawing that text. The position is now read off it, which takes
46 microseconds and accounts for wrapping because it *is* the wrapping. On top of
that, every press used to count the lines before the match by cutting the document
there and splitting the piece into lines — 55 000 strings on a four megabyte
document — for a number only the fallback path ever wanted.

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

### 粘贴的表格在单元格有两行时仍保持形状

表格的一行在换行处结束，所以单元格里不能有换行——而单元格里的 `<br>` 正是写成了
换行。`<td>a<br>b</td><td>c</td>` 回来时变成「a」「（空）」一行、「b」「c」一行：
换行之后的每个单元格都挪了一列，表头也不再对应下面的内容。一个单元格里两个换行，
后两段直接丢失。而单元格里的多个段落——文字处理软件放到剪贴板上就是这个形状——
回来时词被粘成 `onetwo`。

现在单元格里的换行变成一个空格，块与块之间也是。GFM 的正规写法是内联 `<br>`，
但这个编辑器只在 HTML 开关打开时读它，而默认是关的——那样会让写了一个换行的人
看到一个标签。

### 粘贴的链接不再被自己的网址截断

地址在闭合它的那个 `)` 处结束，标签在 `]` 处结束，而转换器写这两者时从不问内容里
有什么。网址里有不成对括号的链接，回来时只指向括号之前那一截，剩下的漏进正文；
网址里有空格的干脆不再是链接；链接文字里有 `]` 的（比如「see [1] here」）
变成一串字面字符，网址还露在旁边。图片同理。

需要的时候地址用角括号包起来——格式本来就为这件事准备了它——标签里的方括号转义。
不需要时原样不动，所以成对的 `http://x/a(b)c` 看起来还是它本来的样子。
带链接的缩略图仍是图片：只转义标签里的**文字**，不动里面的标记。

### 粘贴的斜体不再被文字里的星号截断

强调在闭合它的那段运行处结束，所以 `<em>a*b</em>`——写成 `*a*b*`——回来时斜体停在
读者自己的那个星号上，后面剩下一个孤零零的字符。粗体在双星号上同样如此。

现在是把文字里的星号转义，而不是丢掉这一层强调：丢掉是其他包裹类标签的做法，
在这里代价比原缺陷更大——斜体里套粗体是每天都有的形状，而内层的标记正是星号。
现在什么都不丢，强调里的代码跨度也原样保留它的星号——代码里的反斜杠就是反斜杠。

### 导出的 HTML 粘贴回来仍是原来那篇文档

导出写得出而粘贴读不回的五样：链接的提示文字、行内公式、公式块、脚注引用、脚注定义。
于是一篇导出成 HTML 再粘回来的文档——或者在两个 MarkText 窗口之间复制格式化内容——
提示没了，公式变成 `\(a+b\)` 被读成的那对括号，脚注拆成上标套链接、
不再连着它指的那条注。

这件事发生过一次，当时是另外四个标签，而那次的修法是补那四个标签，
不是建立一种「会发现」的机制。现在每一种块与每一种内联**要么**有一条能通过往返的样本，
**要么**有一条写明理由的豁免，新增一种就会红到有人做出决定为止。三种是豁免，各有理由。

### 从懒加载网页粘来的图片就是那张图片

读属性时会匹配到更长名字的尾部：问 `src` 找到了 `data-src`，问 `href` 找到 `data-href`，
问 `title` 找到 `data-title`——取到哪个值由页面先写了哪个决定。现在必须整名匹配。

单这一条对现实中的网页是退步：懒加载的图片把占位符放在 `src`、真地址放在 data 属性里。
那个回退现在是一个决定，而不是属性顺序的巧合，并且只在 `src` 没有可用内容时才走——
所以编辑器自己导出时内嵌的图片原样保留。

### 「复制为 HTML」交出的是这个编辑器的 HTML

有四处把选区转成剪贴板上的 HTML——Ctrl+C、剪切、菜单的「复制」、预览自己的复制——
四处都是先解析 Markdown、再按导出的方式写出来。唯一一个名字里带 HTML 的菜单项
不是这样：它对选中的文本跑一串正则，四种内联加六级标题，其余一概原样留下。

于是列表、表格、链接、图片、代码块、引用、公式、脚注、高亮、下划线、上下标
都以写出它们的 Markdown 原样出现；`**加粗。**后面` 变成了粗体，而预览画的是
字面星号；而且一字不转义，所以含 `a < b` 的选区产出的 HTML 已经不再说 `a < b`。
现在它用与那四处相同的那一份转换。

### 正则查找按行锚定，替换可以放回它捕获到的东西

`^` 与 `$` 原先指的是整个文档的开头与结尾，所以 `^#+ `——在这里输入正则查找最自然的
一件事，「找出所有标题」——只在文档恰好以标题开头时找到第一个，否则一个也找不到。
现在它们按行锚定，和其他编辑器一样。`.` 仍然不跨行。

替换文本也可以指名模式捕获到的东西了：`$1` 到 `$99` 是分组，`$&` 是整个匹配，
`$$` 是一个字面的美元号——所有其他编辑器用的就是这套拼法。于是查
`\[(.+?)\]\((.+?)\)`、替换为 `$2: $1`，选区里每个链接的文字与地址就都对调了，
而这正是正则替换唯一的用途。模式里没有的组号原样保留，不会悄悄变成空；
字面查找仍然字面替换，`$5` 还是 `$5`。

### AI 端点接受供应商文档里给的那个 base URL

每家供应商写出的 base URL 都带版本段——OpenAI 的 `https://api.openai.com/v1`、
Anthropic 的 `https://api.anthropic.com/v1`，所有说同一套协议的服务也一样，
从本机的 Ollama 到 OpenRouter。粘进端点框里的就是它，而代码仍然会再追加一次版本段：
请求发到了 `/v1/v1/chat/completions`，回来一个 404，而响应体里不会提路径重复，
于是读起来像是「模型不存在」或「服务挂了」。

现在带不带 `/v1` 都能用。输入框自己那句提示——填根地址、不要填完整请求路径——
两种写法下都成立，所以没有改动。

### 一句在所有语言里都是英文的话

没有声明任何设置项的插件，其设置页会用英文告知——`X has no settings.`——
无论窗口其余部分是哪种语言。它是编辑器 403 条文案里唯一写在源码而不是翻译文件里的一条，
而这种泄漏只有用别的语言阅读的人才会注意到。

现在有一条扫描守卫，检查句子能到达读者的每一个位置，只要字面量里出现两个以上
连写的英文单词就失败——下一次泄漏会红在测试里，而不是发到读者手上。

### 「还没配好 AI」这句话会用你的语言说，并且只点出一个字段

还没填端点、模型和密钥就运行 AI 命令，是任何人都会先遇到的一步，而那句拒绝是英文的——
在一个界面为中文、日文或阿拉伯文的编辑器里。两个显示它的地方（插件失败对话框与设置页的
测试按钮）都原样打印了错误文本。

现在它被翻译了，而且**只点出缺的那一个字段**，不再列出三个：原先只有密钥为空的读者，
会被要求把端点和模型也检查一遍。点出的是按屏幕顺序**第一个**缺的，
所以三个都没填的人会被送到表单顶部，而不是底部。

供应商自己的回复仍然原样显示。一个「模型不存在」或「密钥已过期」的 400 响应，
说的比我们的句子多得多，改写它等于把这些信息拿走。

### 打错的图表不再在你的 PDF 里用英文解释自己

Mermaid 包够不到编辑器的翻译，所以它自带的错误框按设计是英文的，由应用自己措辞。
预览这样做了，**导出和全屏查看没有**。于是一份只有一处图表打错的文档，
导出后里面烙着一块英文红色面板——而那是读者要发给别人的 PDF；
点开那个坏图表放大，答复也是英文。

现在三处画的是同一个框。框里的图表类型名在任何语言下都保持原文，
因为它们是要照着打出来的东西。

### 编辑大文件不再让撤销历史占满内存

每一步撤销都是整份文档的副本，而历史的上限是**两百步**。对一篇笔记这是几 MB 的历史；
对一个 1 MB 的文档是 200 MB；对一个 10 MB 的文档是 **2 GB**——每个标签页一套，
重做还有一套。它是进程里最大的一块，而没有任何东西在量它。

现在历史**同时**受「保存了多少文字」和「多少步」两个上限约束。文档小到「两百份副本
很便宜」时行为完全不变，而这几乎是全部 Markdown 文件：**约 80 KB 以下一步不少**。
超过之后先丢最旧的状态，并且无论文档多大，**至少保留一次撤销**。

### 在大文档里扩展选区不再越选越卡

每次选区变化都会把整段选中的文字拷进编辑器状态、再与上一次的整串比较一遍，
而真正要用它的三个地方都是在命令运行的那一刻才去读。于是在大文档里按住 Shift+↓，
每一次按键都拷一个更大的字符串——整个手势是平方级的——而一个 4 MB 的选区随后
一直留在内存里，与文档本体、文本框自己那份、撤销历史并列。

现在选区是一个范围，文字在有人要的时候才取。**哪个窗格答话的规则没有变**：
读者最后动过的那个，所以从预览运行的插件不会拿到源码区一分钟前选的东西。

### 在大文件里移动光标不再比文件本身还慢

每次光标移动都会把整篇文档切成行——**两次**。格式菜单在构建时判断表格命令是否适用，
而它的做法是先用状态栏显示的行列**重新算出**光标偏移量，再把整篇文档交给表格查找、
又切一次。8 MB 文档下每次 36.7 ms，于是按一次方向键约七十毫秒，而一帧是 16.7 ms，
按住方向键就持续卡顿。

文本框本来就知道光标在哪；而「光标在表格里吗」只需要它所在的那一行——同一份文档上
**0 µs**。菜单仍然会在光标移动时重建，因为命令要随光标离开表格而置灰；
**不再做的是重建时去读整篇文档**。

随之改变的一件事：预览模式下没有文本框，表格命令现在**置灰**。以前它们会按源码窗格
最后报告的位置点亮，而那个位置读者在预览里看不见。

### 指向某处的图标，现在指着你阅读的方向

阿拉伯语下文件树往左缩进，而折叠文件夹的箭头指右——**背对它要展开的地方**。
另有两处：设置里标记当前分类的箭头指向窗口边缘而不是内容面板，
发送按钮的纸飞机指着你读过来的方向。

文件树的**缩进**早就随方向镜像了，画在它里面的那个箭头没有。现在三处都会镜像；
另有三条标题栏的内边距把较宽的一侧放错了边，一并跟着镜像。

### 「按别的编码重读」重新成为一条走得通的出路

打开的文件被别的程序改写时，状态栏会说明，并给出三条出路：重新加载、覆盖、
或按你选的编码重新读取。第三条会把横幅收起来，却让基准继续描述**改写之前**的
文件——于是下一次保存又弹出同一个冲突，而冲突的内容正是你标签页里已经有的那份。
现在它会记下自己读到的东西。

两者底下还有一层：那个基准是**在读完字节之后**取的，而不是之前，所以落在两者之间
的写入会被记成「已经看过」，下一次保存不问一声就盖过去。代码旁边的注释主张的正是
另一种顺序，现在代码跟上了。另外删掉了两个没人用的读写辅助方法——其中一个一打开
文件就把它截断——这样先被找到的不再是不安全那半。

### 跳到某一行会真的跳到那一行，打字机模式也终于生效

有六个地方会让编辑窗格跳到某一行：大纲、侧栏的两个搜索列表、在预览里点击定位、
以及查找栏在以预览为目标时。窗格把行号乘以行高当作像素——**上方每有一条换行的
长行就少算一行**。在长段落较多的文档里点大纲的第 20 行，那一行落在窗口**下方
1497 像素**处。

打字机模式里是同一个乘法，还多一件更糟的：它居中之后，**下一帧就被「把光标滚进
视野」的那段代码跳回最近边缘**。所以不管它动画到哪，光标最后都贴在底边——
这个模式从来没真正生效过。现在两者**轮流**而不是互相抵消，并且都等排版完成后
再去问位置。

### 格式工具条浮在它所属的那段文字上方

它的**水平**位置一直是按字体量出来的；**垂直**位置却是用「行号 × 行高」算出来、
再手工减去滚动量的。两者都不是窗格实际画的：分屏的窄窗格里一条长行会换成好几条
视觉行，行高会被取整到整像素，手工减的滚动量也对不上。选区上方只要有三条换行的
长行，工具条就偏高 **317 像素**；600 行文档的第 550 行上，它直接飘出屏幕。

现在两个坐标都从正在画这段文字的那个字段读。

### 在大文件里按「查找下一个」不再冻结编辑器

跳到一个匹配，需要知道它被画在**哪个像素**上，才能把它滚到视口三分之一处——
光有行号不够，因为分屏时一条长行会换行成好几条视觉行。而编辑器拿到那个像素的办法，
是把匹配**之前的全部文字重新排版一遍**：1 MB 上 532 ms，4 MB 上 **2.3 秒**，
每按一次都付。走完二十个匹配，窗口冻结将近一分钟。

那段文字本来就正由窗格画着。现在位置直接从它那里读，**46 微秒**，
并且天然算上换行——因为它就是换行本身。此外，每按一次还会先把文档在匹配处切开、
把前半截分成行来数行号（4 MB 上 5.5 万个字符串），而这个数**只有兜底那条路用得上**。

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
