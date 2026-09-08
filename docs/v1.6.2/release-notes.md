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

### Small honesty fixes

"Check for updates" could tell you that you were on the latest version without
having reached anyone. A maths block was called 数学公式 in the command palette
and 数学公式块 in Settings; Russian spelled strikethrough both with and without
its ё. The automation interface reported success for a tab it had not switched
to and a pane it had not closed, and advertised two actions implemented
nowhere.

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

### 几处「说实话」的修正

「检查更新」在没连上任何服务器时也能告诉你「已是最新版本」。
同一个数学块，命令面板叫「数学公式」而设置里叫「数学公式块」；
俄语的删除线有带 ё 和不带 ё 两种写法。自动化接口会为它没有切过去的标签、
没有关掉的窗格回报成功，还宣称支持两个从未实现过的动作。
