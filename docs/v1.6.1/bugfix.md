# v1.6.1 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-221 | 2026-09-02 | 顶部工具栏图标组没有贴靠窗口右侧，缩放图标语义不清 | P2 | 已修复 |
| BUG-222 | 2026-09-02 | GitHub Topic 插件发现没有使用环境代理，空结果缺少错误反馈 | P1 | 已修复 |
| BUG-223 | 2026-09-02 | AI 大模型 endpoint、model 和密钥引用未在离开设置页时保存 | P1 | 已修复 |
| BUG-224 | 2026-09-02 | 已安装插件没有启用/禁用、卸载和实际使用入口 | P1 | 已修复 |
| BUG-225 | 2026-09-02 | 社区插件列表点击无响应，缺少详情和安装按钮 | P1 | 已修复 |
| BUG-226 | 2026-09-02 | AI API key 没有对应密钥输入和保存入口，插件无法找到真实 key | P1 | 已修复 |
| BUG-227 | 2026-09-02 | 预览区已选中文字却被插件面板误判为没有选区 | P1 | 已修复 |
| BUG-228 | 2026-09-02 | 预览文档底部留白过大，影响滚动阅读 | P2 | 已修复 |
| BUG-229 | 2026-09-03 | 选中文本右键没有翻译菜单，翻译按钮却出现在插件面板标题栏 | P1 | 已修复 |
| BUG-230 | 2026-09-03 | 插件翻译报 "Bad state: plugin process exited"，编辑器启动的是自己 | P0 | 已修复 |
| BUG-231 | 2026-09-03 | 插件设置页仍走 JSON-RPC 问进程，脚本插件打开必然报错 | P1 | 已修复 |
| BUG-232 | 2026-09-03 | 主程序崩溃后插件进程残留，无人知道它还活着 | P1 | 已修复 |
| BUG-233 | 2026-09-03 | 「在文件管理器中显示」被抄成两份并已漂移 | P2 | 已修复 |
| BUG-234 | 2026-09-03 | 插件测试写死本机绝对路径，本地全绿 CI 全红 | P1 | 已修复 |
| BUG-235 | 2026-09-03 | Windows arm64 被记为"做不到"，理由已不成立 | P2 | 已修复 |
| BUG-236 | 2026-09-03 | 发给用户的安装包从来没有 ignoreversion，守卫只查了没人装的那个 | P1 | 已修复 |
| BUG-237 | 2026-09-03 | 产物守卫假设 workflow 里只有一个 matrix，加了第二个就误报 | P2 | 已修复 |
| BUG-238 | 2026-09-03 | 源码编辑器把六成窗格喂给了内边距，长文档最后几行滚不到 | P0 | 已修复 |
| BUG-239 | 2026-09-03 | 插件设成预发布后，市场里再也发现不了它 | P1 | 已修复 |
| BUG-240 | 2026-09-03 | 更新检查指向改名前的组织，只靠 GitHub 的 301 才没坏 | P2 | 已修复 |
| BUG-241 | 2026-09-03 | `minAppVersion` 被读进来就丢掉，是个装饰字段 | P1 | 已修复 |
| BUG-242 | 2026-09-03 | Lua 解释器四处静默失效，正则找不到东西和文档没内容长得一模一样 | P1 | 已固定 |
| BUG-243 | 2026-09-03 | 测试装插件时只拷了入口文件，插件变成多文件后同一个错犯了两次 | P2 | 已修复 |
| BUG-244 | 2026-09-03 | 路径穿越测试是因为错误的原因通过的，守卫根本没被走到 | P1 | 已修复 |

---

## BUG-221：顶部工具栏布局和缩放图标

### 现象

菜单和工具栏同时使用伸缩空间时，右侧图标组没有真正贴靠窗口右边；缩放操作使用加号和减号，不能直观表达放大和缩小。

### 修复方案

菜单区域改为单独 `Expanded`，移除与菜单平分空间的 `Spacer`；缩放按钮改用 `Icons.zoom_in` 和 `Icons.zoom_out`，保留原有快捷键和字体大小范围。

### 验证

设置和编辑器相关全量测试通过，静态分析无问题。

## BUG-222：插件发现网络路径

### 现象

点击发现社区插件时，如果 GitHub API 网络不可达或仓库没有可安装 Release，界面容易表现为没有任何结果；请求也没有显式使用系统环境代理。

### 修复方案

GitHub 请求使用 `HttpClient.findProxyFromEnvironment` 解析 `HTTP_PROXY`、`HTTPS_PROXY` 和 `NO_PROXY` 等环境；插件面板显示请求错误和“没有可安装 Release”的明确状态。市场只展示带 ZIP 和 digest 的 Release，因此官方 AI 翻译插件也补充了 `v0.1.0` 可安装 ZIP。

### 验证

插件 catalog、插件管理和设置页面测试通过；请求仍在用户点击后异步执行，不影响启动。

---

## BUG-223：AI 配置离开页面后丢失

### 现象

endpoint、model 和 API key 只有按 Enter 才会写入配置；直接切换页面或关闭设置后再次打开，输入内容消失。

### 根因分析

字段使用 `onSubmitted` 作为唯一保存触发点，普通编辑完成或失焦没有提交配置。

### 修复方案

三个文本字段使用 300ms 防抖写入 `AppConfig`，避免逐字符写磁盘，同时保留 Enter 提交路径。

## BUG-224：插件缺少生命周期和使用入口

### 现象

ZIP 安装后插件只有列表，没有持久化开关、卸载动作，也没有 AI 翻译插件的实际使用入口。

### 修复方案

插件管理器保存启用状态并提供卸载；侧栏插件面板提供开关、卸载和 AI 翻译选区按钮。翻译通过独立进程 JSON-RPC 执行，完成后替换当前源码选区。

---

## BUG-225：社区插件列表缺少详情和安装入口

### 现象

Topic 搜索返回插件后，点击列表项没有任何反馈；安装按钮只存在于不明显的尾部图标，用户无法查看版本、说明、仓库或确认安装。

### 修复方案

社区插件条目现在可点击打开主内容区详情页签，显示版本、描述、仓库和 Community / Unverified 提示，并提供明确的 Install、Open repository 操作；列表仍保留快速下载图标。

### 验证

插件 catalog 和设置页面专项测试、全量测试及静态分析通过。

---

## BUG-226：AI API key 没有真实密钥写入入口

### 现象

用户填写 API key 后点击测试配置，提示 `The API key was not found`；AI 翻译插件也无法取得真实 API key。

### 根因分析

旧设置页把 API key 拆成 reference 和另一个未实现的密钥存储路径，用户无法判断该填什么。

### 修复方案

设置页现在只有一个明文 API key 字段，直接写入 config.json，并通过 `initialize` 的内存参数传给插件。

### 验证

新增配置回归测试，验证单一 API key 往返保存；AI endpoint、设置页和全量测试通过。

---

## BUG-227：预览选区没有传给插件

### 现象

用户在预览区用鼠标选中文本后，从插件面板执行 AI 翻译，插件面板只检查源码 controller，因此提示没有选区。

### 修复方案

源码和预览统一把选中文字发布到 `EditorState.selectedText`；翻译动作读取共享选区，不再依赖当前是否存在源码 controller。

## BUG-228：预览底部留白过大

### 现象

预览底部原本预留约 60% 视口高度，短文档滚到底部会出现大片无内容区域。

### 修复方案

底部留白调整为视口高度的 25%，并设置合理上限，保留末尾滚动空间但不遮挡内容。

---

## BUG-229：翻译入口在插件面板标题栏，不在右键菜单

### 现象

安装 AI 翻译插件后，选中一段文本右键，没有"翻译选中"和"翻译全文"；翻译按钮反而出现在左侧边栏插件面板标题栏的图标里。

### 根因分析

插件的菜单贡献（`menus` 里的 `editor.contextMenu`）根本没有被读取，编辑器的右键菜单是写死的。翻译动作被临时挂在了插件面板自己的工具栏上——那是开发时最容易加按钮的地方，不是用户翻译一段话时会去看的地方。

### 修复方案

`PluginCommandActions.menuItems` 从已安装插件的 manifest 读取贡献点，源码区（`TextField` 的 `contextMenuBuilder`）和预览区（`SelectionArea` 的 `contextMenuBuilder`）都接上；插件面板标题栏那个按钮删掉。

### 验证

`autopair_test` 与 `language_picker_test` 曾因菜单构造里无条件调用 `AppLocalizations.of(context)!` 而报 null，改为贡献点为空时提前返回，不触碰 context。

---

## BUG-230：插件进程启动的是编辑器自己

### 现象

点击翻译，报 `Bad state: plugin process exited`。

### 根因分析

插件打包后里面是 Dart 源码，`PluginManager.startPlugin` 见到 `.dart` 就用 `Platform.resolvedExecutable` 去启动它。在 release 构建里 `Platform.resolvedExecutable` **就是编辑器自己的二进制**——于是编辑器启动了第二个编辑器，然后等它说 JSON-RPC，等不到就报进程退出。

即使修好这一句也没用：用户机器上没有 Dart SDK，`Isolate.spawnUri` 在 AOT release 里也不工作。**插件不能以 Dart 源码的形式分发**，这是模型问题，不是一行代码的问题。

### 修复方案

`.dart` 入口在 manifest 解析阶段就被拒绝，并告诉作者该怎么办（换 `.lua`/`.js`，或 `dart compile exe` 后用 `runtime: "process"`）。编辑器不再为插件启动任何解释器。

### 验证

`plugin_platform_test` 用突变验证过：拆掉守卫后，编辑器真的会去执行那个文本文件（`Actual: <Instance of 'Future<PluginProcessHost>'>`，即根本没抛异常）。

---

## BUG-231：插件设置页问一个不存在的进程

### 现象

脚本插件点"Settings"必然报错。

### 根因分析

设置页是 sidecar 时代写的：起进程、`initialize`、`getSettings`，把返回的 JSON 原文丢进文本框让用户手改。Lua/JS 插件在编辑器内运行，没有进程可问。

### 修复方案

改为按 manifest 声明的 `settings` 字段画真控件（`boolean` 给开关、`password` 遮蔽、`number` 给数字键盘），标题走插件自带的翻译表，值存回插件自己目录下的 `settings.json`。保存后丢弃已加载的脚本，下一条命令即读到新值。

### 验证

`plugin_settings_screen_test` 五项，覆盖默认值、保存、开关取值、密码遮蔽和翻译。

---

## BUG-232：崩溃后插件进程残留

### 现象

主程序被强杀后，它启动过的插件进程继续运行。

### 根因分析

写探针实测确认，不是推测：

```
parent killed; child 475784 still alive: true
```

子进程不会随父进程死亡。`stop()` 里的 `kill()` 只在正常退出路径上被调用，崩溃永远走不到那里。守规矩的插件会在 stdin 收到 EOF 时自己退出，但**没有任何东西强迫插件去读 stdin**。

### 修复方案

两层。正常关闭时先关 stdin 给 2 秒宽限，只对无视信号的才杀；同时把启动过的进程记进 `plugins/running.json`，下次启动时回收。回收前必须确认现在占着这个 pid 的还是同一个程序——**pid 会被系统回收再分配**，光凭编号杀会杀掉用户的浏览器。

### 验证

`plugin_process_registry_test` 八项，含 pid 复用守卫和一个真实起进程再回收的端到端用例。

---

## BUG-233：同一条规则被抄成两份并已漂移

### 现象

「在文件管理器中显示」在标签栏和菜单栏各有一份实现，标签栏用 `explorer`、菜单栏用 `explorer.exe`，一处 await 一处不 await。

### 修复方案

收敛成 `FileReveal`，两个旧调用点改过来，新的"打开插件目录"成为第三个调用者而不是第三份实现。顺带把 Linux 的真相写进代码：`xdg-open` 没有"选中某个文件"的能力，只能打开所在目录。

### 验证

`file_reveal_test` 六项，逐平台校验"选中文件"与"打开目录"两种形态不会混用。

---

## BUG-234：测试写死本机绝对路径

### 现象

本地全部通过，CI 上 `Analyze & Test` 失败，满屏 `PathNotFoundException`。

### 根因分析

AI 翻译插件是独立仓库，测试用绝对路径去读它。CI runner 上只检出主应用仓库。

### 修复方案

从 `Directory.current` 逐级向上查找插件仓库，找不到就 `skip` 并写明原因。

---

## BUG-235：Windows arm64 的"做不到"已经过期

### 现象

`release.yml` 里记着 Windows on ARM 无法构建，理由是 Flutter 不发布 arm64 的 Windows SDK。

### 根因分析

那句话至今仍然成立——732 条 release 全是 x64，`flutter_windows_arm64_*.zip` 是 404。但它掩盖了零件是分开发布的：stable 3.47.2 对应的引擎产物里 `windows-arm64-release` 存在，Dart 的 `dartsdk-windows-arm64-release.zip` 也一直有。缺的只是 release zip 里塞的是 x64 的 Dart，且被 `engine-dart-sdk.stamp` 锁住。

上一次探针失败在 SDK 安装（`Unable to determine Flutter version for channel: stable architecture: arm64`），当时被读成"这条路走不通"，其实那是 `flutter-action` 去找一个不存在的 zip。

### 修复方案

`ci.yml` 增加 `probe-windows-arm64`：在 `windows-11-arm` runner 上照常装 x64 SDK，删掉 stamp 重跑 `update_dart_sdk.ps1` 换成 arm64 Dart，构建后**从 PE 头读 machine type**——不信"构建成功"，只信 `0xAA64`。`continue-on-error`，跑通之前不拖累任何东西。

### 验证

等待 CI 回答。

---

## BUG-236：真正发给用户的安装包从来没有 `ignoreversion`

### 现象

项目里本来有一条守卫测试专门防这件事，注释写着"三轮原生修复被装上却从没运行过"。它一直是绿的。

### 根因分析

它只读 `ci.yml`，而且用 `firstWhere` 只取**第一条** `DestDir` 行。`ci.yml` 是给性能对比用的构建，没人安装它；`release.yml` 才是用户下载的那个——**它从来没被检查过，也从来没带这个标志**。

没有 `ignoreversion`，Inno Setup 会比较版本资源，版本相同时保留已安装的 `.exe`。这正是那条注释描述的失败。

暴露它的是我给 arm64 探针加的一段临时 Inno 脚本：新脚本成了"第一条匹配"，顶替了断言目标，于是测试报的是我的临时脚本有问题——顺着看下去才发现真问题在别处。

### 修复方案

`release.yml` 的 `[Files]` 补上 `ignoreversion`；探针那段临时脚本也遵守同样规则（版本用运行号而非 `0.0.0`），这样它既不触发守卫，也不会顶替真正该被检查的那条。测试改为遍历**两个 workflow 里的每一条**安装包配置，reason 里带上文件名。

---

## BUG-237：产物守卫假设 workflow 里只有一个 matrix

### 现象

给 `build-windows` 加上 arm64 的 matrix 后，`release_assets_test` 报 `linux-amd64.deb`、`linux-x86_64.rpm`、`linux-arm64.deb`、`linux-aarch64.rpm` 四个产物"没人构建"——而它们每次发版都在构建。

### 根因分析

`matrixValues()` 取第一个 `matrix:` 到第一个 `runs-on:`，隐含"整个文件只有一个 matrix"。新的 Windows matrix 排在 `build-linux` 之前，于是切片只覆盖 Windows，Linux 的 `deb_arch`/`rpm_arch` 再也收集不到。

与 BUG-236 是同一类：守卫保护的是**位置**而不是**事实**。误报比漏报更危险——它诱使人去"修"被测对象，而不是修测试的假设。

### 修复方案

按作业切分 workflow，每个作业的产物名用**该作业自己的** matrix 展开。没有选"把所有 matrix 汇总成一张表"这个更小的改法：那会让一个作业的架构去为另一个作业的文件名背书，`macos-arm64.zip` 就能靠 Linux 的 matrix 蒙混过关。

### 验证

三次突变全部被抓：承诺一个没人构建的平台、macOS 借用别的作业的 arm64、Windows 借用 Linux 的 `deb_arch`。

第一次突变本身是错的——那行产物名在 build-macos 和 release 清单里各有一份，我改到了前一份，结果"全过"，差点据此断定守卫已死。**突变验证也要验证突变本身打对了位置。**

---

## BUG-238：源码编辑器把六成窗格喂给了内边距

### 现象

源码视图打开一篇长文档，往下滚到底，最后若干行滚不出来；窗格越高，滚不到的越多。分栏模式下更明显——源码那半边看着「短了一截」。

### 根因分析

`InputDecoration` 的 `contentPadding` 底部被设成了一个跟随窗格高度的值，本意是「别让最后一行贴着底边」。

**`contentPadding` 不会把可滚动范围撑长，它是把文字能画的那个盒子缩小。** 给它 60% 的窗格高度，就是把 60% 的窗格判给了空白，而不是在文末补 60% 的余量。两者在短文档上看不出差别（都够放），只有长到需要滚动时，差别才等于「最后那段永远够不着」。

这一条属于 CLAUDE.md 里记的第二类视角：**编辑器说了与事实不符的话**——窗格看着有那么大，能用的却没有。

### 修复方案

底部余量改成跟内容有关而与窗格无关的常量——两行的高度：

```dart
// A little room under the last line so it is not glued to the
// bottom edge (#2) — and only a little.
// ... padding inside an InputDecoration does not extend what can
// be scrolled: it shrinks the box the text is drawn in.
final bottomRoom = 2 * config.fontSize * config.lineHeight;
```

### 验证

`source_editor_viewport_test` 断言的是「文档最后一行可达」，不是内边距等于某个数。突变回旧逻辑后失败信息正是「最后一行不可见」。

### 涉及文件

`lib/ui/editor/source_editor.dart`、`test/ui/editor/source_editor_viewport_test.dart`

---

## BUG-239：插件设成预发布后，市场里再也发现不了它

### 现象

按要求把 AI 翻译插件改成预发布之后，编辑器的插件市场里它消失了；仓库里明明有 release。

### 根因分析

发现走的是 GitHub 的 `releases/latest`，而**这个接口按定义就排除预发布**。它不是「最新的 release」，是「最新的正式 release」。仓库里只有预发布时，它返回 404。

这个缺陷是我自己引进来的：把发布方式改成预发布是用户明确要求的，但改完没有回头问「发现这一侧还成立吗」。

### 修复方案

改为列 releases 再自己挑：`newestRelease()` 跳过草稿和没有发布时间的条目，按 `published_at` 取最新，预发布同样算数。

### 验证

`plugin_prerelease_test` 用只含预发布的 releases 列表断言能发现；再用「草稿 + 预发布」断言选中的是预发布而不是草稿。

### 涉及文件

`lib/services/plugin_catalog_service.dart`、`test/services/plugin_prerelease_test.dart`

---

## BUG-240：更新检查指向改名前的组织

### 现象

没有现象——这正是麻烦所在。更新检查一直能用。

### 根因分析

`update_service.dart` 里的仓库地址还是组织改名前的那个，能用只是因为 GitHub 对改过名的仓库做了 301 永久重定向。这类「靠上游好心才没坏」的引用，会在上游哪天不再重定向时一次性坏掉，且现场没有任何线索指向真正原因。

### 修复方案

改成当前的组织与仓库名。

### 验证

断言的是常量里的组织名，不是「请求能成功」——后者在修复前后都是绿的，证明不了任何事。

### 涉及文件

`lib/services/update_service.dart`

---

## BUG-241：`minAppVersion` 被读进来就丢掉

### 现象

一个声明 `minAppVersion: "9.9.9"` 的插件，在任何版本的编辑器上都能装、都能跑。

### 根因分析

`PluginManifest` 解析了这个字段并保存下来，然后没有任何地方读它。**读了却不用，比根本没有这个字段更糟**：插件作者会以为自己已经把兼容性说清楚了，于是不再做防御，而编辑器什么也没做。

### 修复方案

`isSupportedBy(appVersion)` 逐段比较三位版本号（缺位或非法时放行，不因为解析不了就拒装），安装时检查一次，运行前再检查一次——因为编辑器可能在插件装好之后降级。

### 验证

同版本、更高版本、更低版本三种情况分别断言；突变成「永远返回 true」后，「更低版本」那条失败。

### 涉及文件

`lib/services/plugin_manifest.dart`、`lib/services/plugin_manager.dart`、`lib/services/plugin_command_service.dart`、`test/services/plugin_compatibility_test.dart`

---

## BUG-242：Lua 解释器四处静默失效

### 现象

按段落切分文档的代码在编辑器里跑出来是「整篇文档一个字都没有」，同样的代码在标准 Lua 里正常。

### 根因分析

插件用的是 `lua_dardo`——纯 Dart 写的 Lua，这正是脚本插件不需要装任何东西的原因，但它不完整。找到四处：

| 写法 | 实际行为 |
|------|----------|
| `#someString` | 抛 `length error`；而 `#表` 是好的，所以摸不出区别 |
| `%s` / `%S` 字符类 | 匹配不到任何东西，于是每一行看起来都是空行 |
| `s:gmatch("(.-)\n")` | 一个结果都不返回 |
| `s:gmatch("[^\n]*")` | 永远停在一个空匹配上，不往前走 |

四处**全都静默失败**。这是最费时间的地方：一个找不到东西的正则，和一篇没有内容的文档，长得一模一样。

### 修复方案

不是修解释器，而是把它钉住：`lua_dialect_test` 对这四条各写一个断言，描述的是**当前实际行为**。将来若换掉或升级解释器，这些断言会失败，那时该做的是更新这张表而不是让它继续误导人。SDK README 的「What this Lua does not do」一节列出了替代写法。

### 验证

四条断言各自独立；把任何一条改成「标准 Lua 的正确行为」都会失败。

### 涉及文件

`test/services/lua_dialect_test.dart`、SDK `README.md` 及 11 份译文

---

## BUG-243：测试装插件时只拷了入口文件

### 现象

插件改成多文件（入口 + `lib/`）之后，几个插件测试报「找不到模块」。

### 根因分析

那些测试用「拷贝入口文件」的方式装插件——在插件只有一个文件的年代这是对的，成了多文件之后它装的是半个插件。

**同一个错误犯了两次**：第一次改的是发现它的那一处，没有去找还有谁在这么干。

### 修复方案

改成遍历插件目录逐个拷贝，并把这个动作收敛成测试辅助函数，这样「装一个插件」只有一处实现。

### 验证

多文件插件的 `require` 在测试里能解析成功；把辅助函数改回只拷入口，所有多文件用例一起失败。

### 涉及文件

`test/services/plugin_modules_test.dart`、`test/services/sdk_examples_test.dart`

---

## BUG-244：路径穿越测试是因为错误的原因通过的

### 现象

没有现象——测试是绿的。是在给 `require` 写守卫时顺手核对，才发现它绿得不对。

### 根因分析

用例传的是 `..secrets` 这类名字，而模块解析会把 `.` 转成路径分隔符，于是它变成了 `//secrets.lua`——一个绝对路径下并不存在的文件。测试确实拿到了「加载失败」，但失败发生在**文件不存在**，根本没走到穿越守卫。守卫就算整个删掉，这条测试照样绿。

这是 CLAUDE.md 里「两种无效的破坏」之外的第三种：**断言通过的原因和以为的不是同一个**。

### 修复方案

用例改用临时目录的真实路径构造一个确实存在、且确实在插件目录之外的目标文件，再加一条软链接指向外部的用例——软链接那条专门检验「解析之后再判断是否仍在目录内」这一步。

### 验证

两条用例分别对应两道守卫（名字检查、解析后的包含性检查）；删掉任一道，对应那条失败，且失败信息说得出是哪一道。

### 涉及文件

`lib/services/plugin_command_service.dart`、`test/services/plugin_modules_test.dart`
