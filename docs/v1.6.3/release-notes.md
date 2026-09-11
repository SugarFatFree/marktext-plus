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

### Smaller

- The explanation of why the About box's version broke was attached to the undo
  and redo method rather than to the About box, where the next person to touch
  it would read it.
- The check that every icon-only button carries a tooltip could not see
  Material 3's named constructors, so an `IconButton.filled` without one would
  have shipped unannounced.
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

### 其他

- 解释「关于框版本号为什么会写死」的那段注释，原先挂在撤销/重做上，
  下一个改关于框的人读不到。已归位。
- 「每个只有图标的按钮都要带提示」这条检查认不得 Material 3 的三个命名构造，
  一个没有 tooltip 的 `IconButton.filled` 会悄无声息地发出去。
- 启动每一步的耗时现在可以通过自动化接口读到。日志里原本只有一个数
  ——「+901 ms before Dart」——而加载可执行文件、启动引擎、读取快照
  是三个不同的问题，答案也不同。
