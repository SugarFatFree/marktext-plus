# MarkText Plus v1.6.2

> Release notes. English is the default language; the Chinese section follows.

## English

This release is mostly one kind of fix: things the editor said it was doing and
was not. A permission shown and not enforced, a shortcut drawn beside a menu
item that answered no key, a command palette that presented itself as the list
of everything. Each of those reads as working software right up until you rely
on it.

### Permissions became real

Seventeen permissions were declared, shown to you, and four of them were ever
checked. A plugin whose manifest asked for nothing could still open a pane
beside your document and interrupt you with notifications, and `document.read`
— the one you are most likely to be weighing — meant nothing at all: your
document and your selection went to every plugin regardless.

They are enforced now, in one place, and you can read the list on the plugin's
own page in sentences rather than identifiers. The README had promised, in
twelve languages, that you see permissions before installing. Now you do.

Two ways around the check are closed: a plugin could reach the network through
the host without asking, and `![](http://…)` inside a plugin's markdown went
around the permission, the log and your proxy at once.

### Shortcuts that were only drawings

Eleven keyboard shortcuts appeared in the menus, could be rebound in Settings,
and did nothing when pressed — zoom, print, export PDF, full screen, settings,
new window, quit, and the rest. Flutter draws a menu item's shortcut without
handling it, and the handler that makes them work had been given fourteen
actions and stopped there.

Rebinding had a second half of the same problem: changing Bold to Ctrl+Shift+B
showed the new key in the menu, did nothing when pressed, and left the old key
working.

The command palette listed nine commands beyond formatting, out of
twenty-five. Zoom, print, export, full screen and ten others could not be found
in it at all. Every command with a shortcut is in it now, each showing the key
it is currently bound to.

### Large documents

An 8.6 MB file took four seconds to put anything on screen: how much of the top
to parse first was counted in lines, and a generated report has few lines with
a great deal on each. Counted in bytes, the same file draws in 94 ms.

Typing paused for a sixth of a second every time you stopped, because the word
count walked the whole document on the interface thread; it and the outline run
off it now. Four patterns that degraded to quadratic time on one bad line are
linear: a line of `<!--` had locked the source pane for twelve seconds, a line
of `[^` for two and a half, and a gantt chart with a line of colons took five
and a half.

### The preview kept what it had drawn

Anything that was not typing left the preview showing the old document — a
plugin writing its result back, a file reloaded after changing on disk, an edit
arriving over the automation interface. "Reload images" (F5) did nothing at
all, changing the code font was ignored, four diagram types redrew nothing when
their data changed, and turning inline HTML on waited for your next keystroke.

### Reading and writing

Markdown written with underscores is coloured as you type it, along with
`==marked==`, `++underlined++`, inline maths and footnote markers — the preview
had always drawn all of them; only the source pane knew nothing but asterisks.
A backslash now escapes what follows it there, as it always has in the preview.

Copying a paragraph containing a formula, a picture or a footnote gave plain
text and took every heading, bold run and link with it. `==marked==` exported
to Word with no background at all. Pasting from a web page dropped `<mark>`,
`<u>`, `<sup>` and `<sub>` — all four of which this editor writes itself.

Choosing to overwrite, or reload, a file that changed on disk could fail
silently, which reads exactly like success. One mistyped value in the settings
file reset every setting — theme, fonts, key bindings, open tabs. Quitting
could cut itself short, because a watchdog armed for a close that hangs was
never called off when the close went normally.

### Plugins

A plugin that will not read now says why, and can be removed — the one you most
want to delete was the one with no delete button, since the button was drawn
from a manifest that had failed to load. A plugin package cannot unpack to
gigabytes. A compiled plugin says which machines it was built for before you
install it rather than when you click one of its commands. Remote pictures and
the update check follow your system proxy.

The official translation plugin lost your instruction when a prompt template
lost its placeholders, sent a heading in one request and the text it introduces
in the next, and carried guards that did not guard: `lua_dardo` treats a bare
`return` inside a nested function as doing nothing, which turns `while true do
return end` into an infinite loop and one way a plugin freezes the editor.

### Twelve languages, and one of them read right to left

The editor is translated into twelve languages and said so on its front
page, while the whole plugin surface answered in English whatever you had
chosen: the permissions heading and the sentences under it, the buttons that
open a repository and save a plugin's settings, the message when a search
finds nothing. Sharpest of all, the dialog reporting a failed AI
configuration test was English while the line reporting a successful one was
not — your own language when it worked, and English at the moment you most
needed to read it.

Arabic turns the window around, and thirteen layouts stayed where they were.
A code block put its line numbers across the block from the code they
numbered. The file tree indented away from the names it was nesting. Buttons
sat at the far side of their row from every other button. Code blocks are now
held left to right on purpose — code is not prose — and everything else
follows the direction you read in.

Four buttons drawn as an icon alone now say what they are, on hover and to a
screen reader: the close on the find bar, the × on a tab, the search in the
sidebar, and the send in the plugin drawer.

### The model's answer arrives as it is written

Asking a plugin to rewrite, proofread or translate used to show a spinner until
the whole answer was ready. It now appears a piece at a time, the way it is
written.

Behind that was a worse fault, found by running it: a streamed answer waited
for the connection to close and for nothing else. A provider that keeps the
connection open after its last word never returned — measured at fifteen
minutes on a real machine, with no error, nothing in the log, and no way to
stop it. Two things end the wait now, and neither of them is the socket.

Three smaller ones in the same panel: pressing Apply on a rewrite left the
source pane blank and the next keystroke wrote the blank back; a pane that had
not yet been filled decided a rewrite would replace the whole document rather
than what you had selected; and the box you type follow-up instructions into
vanished while the model was working.

### Two ways a document could be damaged

A code fence written under a list item came apart if what was inside it looked
like a list item — which is what a page explaining list syntax contains. The
fence became two empty code blocks and its contents were promoted to real
items. A heading or a quote in the same fence was never at risk, so the fault
showed up only in the one document most likely to contain it.

On a task list the same shape was worse: the preview drew a tickable box for a
line of code, and ticking it wrote into the code block and left the task alone.

### JavaScript plugins on Linux never started

The Linux package carried the plugin shim and not the engine behind it, so
`getJavascriptRuntime()` threw and every JavaScript plugin failed to start —
with nothing in the editor able to say why, since the failure was inside a
dependency. Windows was unaffected. Both desktop builds now check their own
output for the engine before they are packaged.

### Nothing waits forever

Four requests had a size limit and no time limit: testing the AI connection,
listing the plugin marketplace, fetching a plugin's README, and downloading a
plugin. A server that accepts a connection and then says nothing left each of
them spinning with no way to stop and nothing to report. Every request this
editor makes is now bounded, and the message names who went quiet.

### Mermaid diagrams in the Format menu

Fifty-two format commands, and the menu offered fifty-one. The missing one was
the fenced diagram block — the only one of its family you cannot get by typing
two or three characters, since it takes a fence, a word, and a first line that
decides the diagram's kind. It was reachable from the `/` menu and nowhere
else.

### Permissions, the rest of them

The menu bar had asked for its permission since it was written and the
right-click menu asked for none, so a plugin you had approved without it
appeared there anyway. A settings page needed no permission either.

Seven of the eighteen permissions are marked in the SDK now, in all twelve
languages: they are real, you are shown them, and the editor has not built the
thing they would grant. Asking for one gains a plugin nothing today. They stay
listed because they are part of the manifest and will be honoured when the
capability arrives — but an author reading "add a toolbar button" and getting
no button had lost an evening to a sentence.

### What the editor will now tell you

`get_state` reports how much memory the process is holding, and opening a
document leaves a line saying how big it was, in what encoding, and how long
the read and the decode took. Both exist because a claim nobody can measure is
one nobody can keep: this editor's first promise is that it stays light, and
until now the only way to read that number was a log line the preview wrote —
so it could be had while a heavy document was open and not once it was closed,
which is the wrong way round for the only question worth asking.

### Small honesty fixes

"Check for updates" could tell you that you were on the latest version without
having reached anyone. A maths block was called 数学公式 in the command palette
and 数学公式块 in Settings; Russian spelled strikethrough both with and without
its ё. The automation interface reported success for a tab it had not switched
to and a pane it had not closed, and advertised two actions implemented
nowhere.

A plugin the editor cannot run — a compiled one, or one with no code at all —
still got an icon in the right-hand rail, and pressing it answered that the
plugin had no script. The web pane a plugin draws in wrote where the page had
been to the log on every platform except the one most readers use, where it
wrote nothing at all. The front page promised that a test fails if four times
the document costs more than six times the work; it fails above eight, and had
since the limit was raised.

The automation interface took an answer for a plugin's question and passed it
on for panels only — a command that asked one sat waiting for a button nobody
was there to press. Recording the window as a GIF took fifty-two seconds for
three seconds of video, past the patience of anything that asked for it; it now
takes about eight, and the file is a third of the size.
---

## 简体中文

这一版修的大多是同一类问题：**编辑器说了、却没有做到的事**。
权限列出来了却没强制，快捷键画在菜单旁边却按不动，命令面板自称是全部命令。
这类问题在你真正依赖它之前，看起来都像是好的。

### 权限从「展示」变成「强制」

17 项权限被声明、被展示，真正检查过的只有 4 项。一个什么都没申请的插件，
照样能在你的文档旁边开窗格、照样能弹通知；而 `document.read`——
最可能让你犹豫的那一条——**完全不起作用**：你的文档和选中的文字，
不管插件申请没申请，都会送过去。

现在它们在同一个地方被强制执行，插件页面上用完整句子告诉你它申请了什么，
而不是 `document.read` 这样的标识符。README 曾用 12 种语言承诺
「安装前给你看权限」，现在这句话才成立。

两条绕过检查的路也堵上了：插件可以让宿主替它发网络请求而不申请权限；
插件 markdown 里的 `![](http://…)` 一次绕过权限、日志和你的代理。

### 只是画上去的快捷键

**十一个快捷键**在菜单里画着、在设置里能改，按下去毫无反应——
放大、打印、导出 PDF、全屏、设置、新窗口、退出等等。
Flutter 只负责画出菜单项的快捷键，不负责执行它；
而负责执行的那段代码当初列了十四个动作就停下了。

重新绑定还有同一问题的另一半：把「加粗」改成 Ctrl+Shift+B，
菜单显示新键、**按下去没反应，而旧的 Ctrl+B 照样加粗**。

命令面板在格式命令之外只列了 9 条，而实际有 25 条。
放大、打印、导出、全屏等十六条**在里面根本搜不到**。
现在每个带快捷键的命令都在，且各自显示当前绑定的键。

### 大文档

8.6 MB 的文件要四秒才能显示出东西：先解析多少「顶部」是按**行数**算的，
而一份生成的报告往往行数很少、每行很长。改按字节算之后，同一个文件 94 毫秒出首帧。

每次停下打字都会卡约六分之一秒，因为状态栏字数在界面线程上统计整篇；
现在它和大纲都移出了界面线程。四处会在一行坏输入上退化成二次方的正则改成了线性：
一行 `<!--` 曾让源码窗格卡十二秒，一行 `[^` 卡两秒半，
甘特图里一行冒号要五秒半。

### 预览守着它画过的东西

只要不是打字引起的改动，预览就停在旧内容上——插件写回结果、
文件在磁盘上变了之后重新载入、通过自动化接口传进来的编辑。
「重新加载图片」（F5）**什么都不做**，改代码字体没有反应，
四种图表改了数据不重绘，打开行内 HTML 要等你下一次敲键才生效。

### 读与写

用下划线写的 Markdown 现在会随打随染色，`==高亮==`、`++下划线++`、
行内公式和脚注标记也是——预览一直都画得出来，只有源码窗格除了星号什么都不认。
反斜杠转义在那里也生效了，这一点预览一直是对的。

复制含公式、图片或脚注的段落会得到纯文本，连带丢掉其中所有标题、加粗和链接。
`==高亮==` 导出到 Word 完全没有底色。从网页粘贴会丢掉
`<mark>` `<u>` `<sup>` `<sub>`——而这四种标记这个编辑器自己都会写。

磁盘上文件变了之后选「覆盖」或「重新加载」，失败时可能一声不响，
而那看起来和成功一模一样。设置文件里一个字段类型写错，
会让**全部设置**恢复默认——主题、字体、快捷键、打开的标签页。
退出可能被自己切断：为「关不掉」准备的看门狗，在正常关闭完成后没人撤下它。

### 插件

读不进来的插件现在会说明原因，也**能删掉了**——你最想删的那个，
恰恰是原来没有删除按钮的那个，因为按钮是从加载失败的 manifest 画出来的。
插件包不会解压出几个 GB。编译型插件在你安装之前就说明它为哪些机器构建过，
而不是等你点了它的命令才说。文档里的远程图片和更新检查会走你的系统代理。

官方翻译插件：提示词模板丢了占位符时，**你刚输入的内容也跟着消失**；
标题被留在上一批请求里，而它要介绍的正文在下一批；
还有几个不起作用的守卫——`lua_dardo` 把嵌套函数里的裸 `return` 当作空操作，
于是 `while true do return end` 成了死循环，这正是插件冻住编辑器的一种方式。

### 十二种语言，其中一种从右往左读

编辑器翻译成 12 种语言，首页也这样写着，而**整个插件界面对所有读者都说英语**，
不管你选了哪种：权限标题和它下面的句子、打开仓库和保存插件设置的按钮、
搜索没有结果时的那句话。最刺眼的是——**AI 配置测试失败的对话框是英文，
而成功提示是你的语言**：好的时候说你的话，坏的时候说英语，
而坏的时候恰恰是最需要看懂的时候。

阿拉伯语会把窗口整个调头，而有十三处布局没跟着调。带行号的代码块，
**行号被甩到了它所标注内容的另一头**；文件树朝着名字的反方向缩进；
按钮落在这一行所有别的按钮的对面。现在代码块**有意**保持从左往右——
代码不是散文——其余一切跟着你阅读的方向走。

四个只有图标的按钮现在有名字了，悬停能看到，读屏软件也念得出：
查找栏的关闭、标签页的关闭、侧栏搜索、插件抽屉的发送。

### 模型的回答，边写边出现

让插件改写、纠错或翻译，过去是一直转圈直到整段答案备齐。现在它一段一段地出现，
就像它被写出来的样子。

这背后藏着一个更糟的毛病，是**跑起来才发现的**：流式读取只等一个出口——连接关闭。
而 provider 说完最后一个字并不关连接，于是永远回不来——真机实测**转了十五分钟**，
没有报错、日志里没有一行、也没有办法停下。现在有两个出口，而且都不是 socket。

同一个面板里还有三处：改写点「采用」之后源码窗格是空白的，下一次敲键会把空白写回去；
还没填内容的空窗格把「替换整篇」定死了，你选中的那段被忽略；
以及模型工作期间，你用来追加要求的输入框会整个消失。

### 两种会损坏正文的情形

写在列表项底下的代码围栏，**如果里面的内容看起来像列表项，就会被拆开**——
而那正是一篇讲列表语法的文档里会有的东西。围栏变成两个空代码块，
里面的内容被升格成了真的列表项。同一个围栏里换成标题或引用从来不会出事，
所以这个毛病只在最可能写到它的那一种文档里现身。

在任务列表上更糟：预览会给代码块里的那一行画出一个可勾选的框，
**勾它会改写代码块，而你真正想勾的那一项纹丝不动**。

### Linux 上的 JavaScript 插件从来没能启动

Linux 安装包里带的是插件外壳，没有它背后的引擎，于是 `getJavascriptRuntime()`
直接抛错，**每一个 JavaScript 插件都起不来**——而且编辑器这边说不出原因，
因为失败发生在依赖内部。Windows 不受影响。现在两个桌面构建在打包之前，
都会检查自己的产物里有没有这个引擎。

### 不再有永远的等待

有四处请求只有大小上限、没有时间上限：测试 AI 连接、列出插件市场、
取插件的 README、下载插件。对方接了连接却一句话不说时，
它们每一个都会一直转下去，既停不掉也报不出。
现在这个编辑器发出的每一个请求都有时限，而且超时的那句话会说清**是谁不出声**。

### Mermaid 图进了格式菜单

五十二条格式命令，菜单提供了五十一条。缺的那一条是带围栏的图表块——
**它偏偏是这一族里唯一不能靠敲两三个字符得到的**：要记住围栏、记住那个词、
还要记住第一行决定图的种类。此前它只能从 `/` 菜单进入。

### 权限，剩下的那些

菜单栏从写下那天起就查自己的权限，而右键菜单一条都不查——
所以一个你在没有这条权限的情况下批准的插件，照样出现在那里。设置页也同样不需要权限。

十八个权限里有七个，现在在 SDK 文档里**被明确标注**（十二种语言都是）：
它们是真的、也会展示给你，但编辑器还没有做出它们所授予的那个能力。
今天声明它们，插件什么也得不到。它们仍列在那里，因为它们是清单的一部分、
将来做出来时会被兑现——但一个作者读到「加一个工具栏按钮」、照做之后什么都没发生，
**为一句话赔上了一个晚上**。

### 编辑器现在愿意告诉你的事

`get_state` 会报出进程占用了多少内存；打开一个文档会留下一行，
说清它多大、什么编码、读盘与解码用了多久。两者都是因为
**没人能测量的承诺就是没人能守住的承诺**：这个编辑器的第一条承诺是「占用低」，
而在此之前读到这个数字的唯一途径是预览写的一行日志——
于是开着大文档时读得到，关掉之后读不到，
而唯一值得问的问题恰恰是后者。

### 几处「说实话」的修正

「检查更新」在没连上任何服务器时也能告诉你「已是最新版本」。
同一个数学块，命令面板叫「数学公式」而设置里叫「数学公式块」；
俄语的删除线有带 ё 和不带 ё 两种写法。自动化接口会为它没有切过去的标签、
没有关掉的窗格回报成功，还宣称支持两个从未实现过的动作。
编辑器跑不了的插件——编译型的，或者根本没有代码的——**照样在右侧栏里得到一个图标**，
按下去回答的是「这个插件没有脚本」。插件画界面的那个网页窗格，
会把页面去过哪里写进日志——除了**大多数读者正在用的那个平台**，在那里它什么都不写。
首页承诺「四倍的文档不超过六倍的开销，否则测试失败」；实际的上限是八倍，
而且从它被调高的那天起就是。

自动化接口收下「插件提问的答案」之后，只转交给面板——
**一条会提问的命令会一直等着一个没有人去按的按钮**。
把窗口录成 GIF，三秒的画面要等五十二秒，超过了任何调用方的耐心；
现在约八秒，文件还小了三分之二。
