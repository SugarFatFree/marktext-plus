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
| BUG-245 | 2026-09-04 | 社区插件列表对已安装的插件仍然只给下载按钮 | P1 | 已修复 |
| BUG-246 | 2026-09-04 | 插件详情页盖在某个标签页上，被盖的文档还是活动标签 | P1 | 已修复 |
| BUG-247 | 2026-09-04 | 翻译时全局遮罩，恰好挡住读者要对照的那篇文档 | P0 | 已修复 |
| BUG-248 | 2026-09-04 | 逐段翻译期间窗格什么也不说，看不出还在不在做 | P1 | 已修复 |
| BUG-249 | 2026-09-04 | 翻译途中关掉窗格/悬浮窗，`Cannot use ref after the widget was disposed` | P0 | 已修复 |
| BUG-250 | 2026-09-04 | 关掉窗格不算取消，译文一段段又把它顶回来 | P1 | 已修复 |
| BUG-251 | 2026-09-04 | 分屏下从源码半边翻译全文，译文却按预览渲染 | P1 | 已修复 |
| BUG-252 | 2026-09-04 | 「四宫格」是 360px 边条加 240px 底带，四格四个尺寸 | P1 | 已修复 |
| BUG-253 | 2026-09-04 | 悬浮提示被渲染成 32×32 并跑到正文第一行旁边 | P1 | 已修复 |
| BUG-254 | 2026-09-04 | 插件只翻译了一半的语言，其余键直接消失 | P2 | 已修复 |
| BUG-255 | 2026-09-04 | 装完插件，社区列表还是下载按钮——两套 id 从来就对不上 | P1 | 已修复 |
| BUG-256 | 2026-09-04 | 插件列表显示包名 `com.marktextplus.ai-translate` | P2 | 已修复 |
| BUG-257 | 2026-09-04 | 结果有第三个容器：贴最右的 380 固定条，既非宫格也非侧边栏 | P1 | 已修复 |
| BUG-258 | 2026-09-04 | 悬浮窗不能拖动 | P2 | 已修复 |
| BUG-259 | 2026-09-04 | 关闭悬浮窗时整个窗口闪一下 | P1 | 已修复 |
| BUG-260 | 2026-09-04 | 目标语言弹窗是个独立大对话框，比它通向的答案还大 | P1 | 已修复 |
| BUG-261 | 2026-09-04 | 全文翻译一段一个请求，几十次往返 | P1 | 已修复 |

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

---

## BUG-245：社区插件列表对已安装的插件仍然只给下载按钮

### 现象

在线安装完一个插件，「发现社区插件」列表里那一条纹丝不动，还是那个下载按钮。想确认到底装没装，只能再按一次。

### 根因分析

列表的 trailing 恒为下载按钮，从不问「这个插件是不是已经在盘上了」。

`PluginCatalogEntry.isInstalled` 看着像能回答，其实不能——它的定义是 `downloadUrl == null`，回答的是「这个页面有没有东西可下载」。搜索结果**永远**带下载地址，所以它对社区列表恒为 false。**两个不同的问题共用了一个名字**，这就是缺陷的根。

### 修复方案

新增 `PluginInstallState.of(entry, installed)`，拿条目去问**已装清单**：没找到同 id → 可安装；找到且目录版本更新 → 可更新；否则 → 已安装。

版本比较没有再写一份：`PluginManifest.compareVersions` 从 `isSupportedBy` 里提出来，两处共用，这样「这是不是更新」和「编辑器版本够不够」不会各自漂移。无法解析的版本返回 0（视作已安装），因为两个都读不懂的版本号说明不了谁更新，据此提示更新会让人反复下载同一个东西。

### 验证

五种情形各一条断言。突变成「更新也算已安装」时，「目录里更新的版本是更新，不是已安装」那条失败；把 `isSupportedBy` 改成恒真时，兼容性测试挂三条——证明提取后两边都还守得住。

### 涉及文件

`plugin_catalog_entry.dart`、`plugin_manifest.dart`、`plugin_panel.dart`、`plugin_detail_view.dart`、`plugin_install_state_test.dart`

---

## BUG-246：插件详情页盖在某个标签页上

### 现象

点开插件详情，它不是新标签页，而是直接盖在当前已打开的某个标签页上；被盖住的那个文档仍然是活动标签、仍然在标签栏里高亮。看着别扭，也不知道怎么回去。

### 根因分析

详情页是一个 `StateProvider`，`_buildEditorArea` 在最前面短路：只要它非空，就整块替换编辑区。所以「编辑器打开了一个插件页」这件事，在标签栏里没有任何体现。

### 修复方案

插件页就是编辑器打开的东西，所以它是标签页。`TabInfo` 增加 `pluginDetail`，`TabInfo.pluginDetail(entry)` 造一个 id 为 `plugin:<插件 id>`、**没有文件路径**的标签——会话持久化、已打开文件列表、自动保存全都以文件路径为准，一个页面不是文件。同一插件再点一次是回到那个标签，不是叠第二个。

页内原来的关闭按钮去掉了：标签页自己有关闭按钮，两个只会让人按错。标签栏给插件页加了一个扩展图标，否则它混在文档里像一个打不开的文档。

### 验证

`plugin_detail_tab_test` 断言无文件路径、名称取自插件、`copyWith` 不会把插件页悄悄变成空文档。

### 涉及文件

`tab_info.dart`、`plugin_provider.dart`、`home_screen.dart`、`plugin_detail_view.dart`、`editor_tab_bar.dart`、`plugin_detail_tab_test.dart`

---

## BUG-247：翻译时全局遮罩

### 现象

「翻译选中内容」和「翻译全文」一按下去就是全窗口遮罩加转圈，几秒钟内什么都动不了。

### 根因分析

`_withProgress` 用的是 `showDialog(barrierDismissible: false)`。

模型要花几秒，而这几秒**恰好**是读者想滚动原文去对照的时候——遮罩把唯一要对照的东西挡住了。这不是「加载中要有反馈」的问题，是反馈选错了容器。

### 修复方案

短答案改用贴在文档区右上角的悬浮卡片（`PluginTipLayer`）：先转圈说「进行中」，模型回来后同一张卡片换成译文，带复制和关闭。不引入任何遮罩，文档照常滚动，卡片不随之移动。

`PluginShowAction` 也一并从对话框改成这张卡片——它本来的注释就写着「sized to a note」，容器早就该是便签而不是对话框。

### 验证

断言显示提示前后 `ModalBarrier` 数量不变（MaterialApp 自带一个），且卡片尺寸远小于屏幕。

### 涉及文件

`plugin_tip.dart`、`plugin_command_actions.dart`、`home_screen.dart`、`plugin_progress_widget_test.dart`

---

## BUG-248：逐段翻译期间窗格什么也不说

### 现象

全文翻译打开窗格后，在第一段回来之前是一片空白；后续每段之间也看不出还在不在做。

### 根因分析

窗格内容没有「还在做」这个状态。宿主知道（脚本返回了 `nextPrompt`），但没告诉窗格。

### 修复方案

`PluginPaneContent.busy`，由 `PluginPaneContent.fromAction` 一处决定：**「还在工作」就是「还有下一步」**。这条规则原先散在调用点上，把它写成 `busy: false` 不会让任何测试失败——所以它被收进工厂并单独加了守卫。

显示分两处：还没有内容时说在正文区（空窗格顶着一个转圈的标题栏看着像坏了），第一段落地后移到标题栏（进度不该压在读者要看的东西上）。

插件侧配合：全文翻译改为**先返回空窗格再问模型**。宿主读 `pane` 早于 `ai`，所以「空正文 + 有下一步」正是「正在进行」的样子；原来先问模型，屏幕在第一段回来前毫无变化。

### 验证

三条 widget 测试分别钉住三种表现，突变 `busy` 的判定会被单元测试抓到。

### 涉及文件

`plugin_provider.dart`、`plugin_panes.dart`、`plugin_command_actions.dart`、插件 `plugin.lua`

---

## BUG-249：翻译途中关闭窗口报 `Cannot use ref after the widget was disposed`

### 现象

翻译进行中把翻译窗口关掉，弹出 `Bad state: Cannot use "ref" after the widget was disposed.`

### 根因分析

`_run` 拿的是 `WidgetRef`，而**一次运行比启动它的那个 widget 活得久**。读者关掉窗格或标签页，widget 被 dispose，之后任何 `ref.read` 都会抛——包括 `finally` 里的那两个，而 `finally` 一定会执行，所以这个崩溃几乎必现。

`textFor` 有同样的毛病：`await getApplicationSupportDirectory()` 之后才去 `ref.read`。

### 修复方案

改用 `ProviderScope.containerOf(context, listen: false)`，在**同步阶段**（还确定有 widget 时）取到 container，之后全程用它。container 属于整个应用，不随任何 widget 消亡。

### 验证

一条 widget 测试：先取 container，再把提供它的 widget 移出树，然后照常读写 provider——若换成 `WidgetRef` 会抛。

### 涉及文件

`plugin_command_actions.dart`、`plugin_cancel_test.dart`

---

## BUG-250：关掉窗格不算取消

### 现象

全文翻译过程中关掉窗格，它会被下一段译文顶回来，一段一段地回来，关不掉。

### 根因分析

`append` 在目标槽位不存在时会退化成 `show`，等于把读者刚关掉的东西重新建起来。运行本身也没有任何地方检查读者是否已经叫停。

### 修复方案

追加前先看槽位还在不在，不在就结束这次运行。悬浮窗同理：模型返回后若提示已被读者关掉，就不再把答案弹回来——否则关闭按钮只是个建议。

### 验证

`plugin_cancel_test` 断言关闭后槽位确实消失、提示确实为 null，即运行所依据的那个判断成立。

### 涉及文件

`plugin_command_actions.dart`、`plugin_cancel_test.dart`

---

## BUG-251：分屏下从源码半边翻译，译文按预览渲染

### 现象

分屏模式里在**源码**那半边右键「翻译全文」，翻译窗格却渲染成预览。

### 根因分析

宿主把 `ctx.view` 填成全局 `editMode.name`，分屏时就是 `"split"`。

插件写的是 `ctx.view == "source" and "source" or "preview"`——它没错，是宿主给了一个**回答不了这个问题的答案**。分屏时「读者在看什么」确实没有单一答案，但**菜单有**：它是在某一半上打开的。

### 修复方案

`menuItems` 增加必填的 `half` 参数，源码编辑器传 `source`，预览渲染器传 `preview`。`viewFor(half, mode)` 一处决定：有半边就用半边（更具体的事实），只有菜单栏、命令面板这类没有半边的入口才回落到模式。

### 验证

`plugin_view_reported_test` 断言分屏下两半各自报告自己；突变回 `mode.name` 后第一条失败，`Actual: 'split'`。

### 涉及文件

`plugin_command_actions.dart`、`source_editor.dart`、`markdown_renderer.dart`、`plugin_view_reported_test.dart`

---

## BUG-252：「四宫格」不是四宫格

### 现象

全文翻译打开的窗格是右侧一条 360px 的窄条；加上下方窗格后是一条 240px 的横带。四个格子四种尺寸，完全不对称，也不能拖。

### 根因分析

实现是「装饰条」而不是「网格」：右列写死 `SizedBox(width: 360)`，底行写死 `SizedBox(height: 240)`。一篇文档的译文只配得到一条窄缝。

另一处理解偏差：布局按**槽位名**决定位置，于是只填 `corner` 会留下两个空格子。

### 修复方案

形状由**填了几个**决定，每一步都对称：

| 填了几个 | 布局 |
|---|---|
| 零 | 文档占满 |
| 一 | 文档与窗格左右各半 |
| 二 | 上半左右对分，第二个窗格占满下半 |
| 三 | 上下都对分，四格等大 |

分隔条可拖动，手感与源码/预览之间那根一致（同样的 8px 宽度、拖动高亮、resize 光标）。槽位名退回它本来的职责：**标识是哪一个窗格**（用于追加和替换），不决定落点。

### 验证

`plugin_grid_test` 七条按四种形态断言几何。三次突变分别被精确抓到：改回固定 360 杀 5 条；两个窗格时也把下半分成两列，只杀「三格：上半分开下半整行」；单窗格时也开第二行，杀 3 条。

### 涉及文件

`plugin_panes.dart`、`plugin_grid_test.dart`、`plugin_panes_layout_test.dart`

---

## BUG-253：悬浮提示被渲染成 32×32

### 现象

没有用户报告——是给悬浮窗写「它应该在右上角」的断言时发现的：卡片实际是 `Rect.fromLTRB(117, 24, 149, 56)`，32×32，紧贴正文第一行，关闭按钮点不中。

### 根因分析

`Stack` 的尺寸由**非定位子**决定。非定位子是文档内容，在测试里就是一行文字，于是整个 Stack 只有那么大，`right: 12` 成了「距那行字右边 12 像素」。

真实应用里文档通常撑满，所以肉眼不一定看得出来——但欢迎页那种居中的小内容就会露馅。**依赖子组件恰好撑满是脆弱的。**

### 修复方案

`fit: StackFit.expand`。

### 验证

断言卡片距右边 12、距顶 12，且宽度大于 200（「被压成自身内边距的卡片既读不了也点不中」）。去掉 `expand` 后这三条连同两条关闭测试一起失败。

顺带把卡片从 `_TipCard` 改成公开的 `PluginTipCard`：原先用 `find.byType(Material).last` 定位，抓到的是树里另一个 Material，量出来差 10 像素——**finder 猜的是树里第几个，不是要测的那个东西**。

### 涉及文件

`plugin_tip.dart`、`plugin_progress_widget_test.dart`

---

## BUG-254：只翻译了一半的语言，其余键直接消失

### 现象

一个插件的中文表里有名称没有简介，中文界面下简介位置显示的是 `plugin.description` 这个键本身。

### 根因分析

`stringsFor` 返回的是**最匹配的那一张表**，不做逐键合并。作者只要漏了一个键，读者看到的就是键名——比作者已经写好的英文更差，而且作者只有切到那个语言去读才能发现。

### 修复方案

改成逐键回退：默认语言在下、语种在中、完整 locale 在上，依次覆盖。优先级顺序不变（`zh_CN` → `zh` → 默认），只是粒度从整张表变成单个键。

### 验证

「只翻译了部分键的语言，其余仍在」这条在修复前失败（`Actual: <null>`）。

**但这条修复让另一条守卫失效了**：AI 翻译插件的多语言测试原先用 `stringsFor` 断言每种语言都有译文——逐键回退之后，缺失的键会被英文补上，于是**删掉韩文的一条译文，测试照样全绿**。改为直接遍历 `manifest.locales` 的每一张原始表，突变才被抓到（`ko 少了该有的翻译`）。

这是「断言通过的原因和以为的不是同一个」的又一例，而且是**自己的修复把自己的守卫弄哑了**。

### 涉及文件

`plugin_manifest.dart`、`plugin_listing_test.dart`、`ai_translate_plugin_test.dart`

---

## BUG-255：装完插件，社区列表还是下载按钮

### 现象

在线安装完插件，「发现社区插件」里那一条毫无变化，下载按钮还能按。BUG-245 号称修过这个。

### 根因分析

**两套 id 从来就不是一回事。**

- 市场条目的 id 由仓库名派生：`'github.$fullName'.toLowerCase().replaceAll('/', '.')`，即 `github.marktext-plus-plugins.marktext-plus-ai-translate-plugin`
- 已安装插件的 id 是它自己在 manifest 里声明的：`com.marktextplus.ai-translate`

`PluginInstallState.of` 拿这两者比对，永远不相等。所以每一个搜索到的插件都显示为「未安装」，装多少次都一样。

**而 BUG-245 的测试是绿的**——因为它两边用了同一个 id，测的是一个不存在的世界。这是「断言要能区分假设」的反例：测试通过的原因，和以为的不是同一个。

### 修复方案

改按**仓库**匹配：条目有 `repositoryUrl`，manifest 有 `repository`。规范化后比较（去掉结尾的 `/`、去掉 `.git`、统一小写），因为 manifest 是手写的，同一个仓库会有好几种写法。声明了仓库才参与匹配——两个都没写仓库的插件不是同一个。id 相同仍然算匹配，那对同体系的目录有效。

### 验证

测试改用真实的 id 差异：条目是 `github.example.a`，manifest 是 `com.example.demo`，靠仓库相认。突变回按 id 匹配，5 条失败；去掉 `.git` 规范化，「同一个仓库的三种写法」那条失败。

### 涉及文件

`plugin_catalog_entry.dart`、`plugin_install_state_test.dart`

---

## BUG-256：插件列表显示包名

### 现象

已安装列表里每条都跟着 `com.marktextplus.ai-translate · 0.1.3`。扫列表的人不关心插件内部叫什么。

### 根因分析

`Text('${plugin.id} · ${plugin.version}')`——把「这是哪个构建」的答案摆在了「这是干什么的」的位置上。

### 修复方案

只显示版本号，以及**读者拿到的是不是预发布**。

后者 manifest 答不上来：那是 release 的属性，不是插件的属性，而 release 不在磁盘上。按版本号有没有前导零去猜是猜——0.x 的成品软件很多，1.0.0 的预发布也存在。所以安装时把它记下来：`sources.json` 存 `{插件 id: {prerelease, tag}}`，卸载时一并忘掉。

这之前装的插件、以及用 ZIP 手工装的插件，没有这条记录，就只显示版本号——它们背后本来也没有一个 release 可供回答。

### 验证

`plugin_source_test` 六条：没记录时为 null、记了能取回、互不覆盖、重装会替换（装了正式版之后不该还说是预发布）、卸载会忘、文件损坏时当作没有记录而不是崩溃。

### 涉及文件

`plugin_manager.dart`、`plugin_catalog_service.dart`、`plugin_panel.dart`、`plugin_detail_view.dart`、12 份 ARB

---

## BUG-257：结果有第三个容器

### 现象

分屏模式下点「翻译全文」，最右侧多出一个独立窗口，既不在宫格里，也不像侧边栏。

### 根因分析

`PluginResultPanel`：`Container(width: 380)`，是 `PluginPanes` 的**兄弟**，贴在整个编辑区最右边。它是 `panel` 动作的容器。

于是编辑器有三个地方可以放一个结果——宫格、这条固定带、右侧边栏抽屉——而读者无从知道某个插件会用哪一个。三选一的容器就是没有容器。

### 修复方案

删掉它。`panel` 动作改为进宫格（`slot: right`）——它和 `pane` 本来就是同一件事：插件主动把内容放到文档旁边。

右侧边栏**保留**，它是另一回事：和左侧边栏一样是独立能力，图标栏加抽屉，内容由「点图标运行同名命令」产生，是 pull 而不是 push。

动作本身没有删，所以插件契约测试仍然通过——`panel` 还在，只是换了容器。

### 涉及文件

删除 `plugin_result_panel.dart`；`plugin_command_actions.dart`、`home_screen.dart`、`plugin_provider.dart`

---

## BUG-258：悬浮窗不能拖动

### 修复方案

抓标题栏拖动，鼠标指针变成移动样式。位置**限制在窗格内，且算上卡片自身宽度**——只按窗格边界限制的话，卡片会整个宽度地走出左边缘，那时就没有东西可以抓它回来了。最大宽度在 `PluginTipCard.maxWidth` 一处定义，布局层和卡片共用，两边不会各说各话。

### 验证

拖动断言的是方向和幅度而不是精确像素：pan 手势的前一段消耗在 touch slop 上，那是框架的事，不是这个组件的性质。另有一条把卡片往左上猛拖 4000 像素，断言它仍在窗格内；把限位改成不算卡片宽度，那条就失败。

---

## BUG-259：关闭悬浮窗时整个窗口闪一下

### 根因分析

`PluginTipLayer` 在没有提示时 `return child`，有提示时 `return Stack(...)`。**widget 树的结构变了**，`child` 的 Element 从「直接子」变成「Stack 的子」，Flutter 于是拆掉整棵文档子树重建——读者看到的就是闪。

### 修复方案

Stack 恒在，只是没有提示时不放第二个子。

另外 `LayoutBuilder` 必须放在 Stack **外面**：`Positioned` 只有作为 Stack 的直接子才起定位作用，中间夹一层就变成普通子，被 `StackFit.expand` 拉满整个窗格。这个错我犯了一次，卡片撑成了 800 宽。

### 验证

用一个计数的 `StatefulBuilder` 当文档，断言提示来去之后重建次数不变。突变回旧写法，计数从 1 变成 3。

---

## BUG-260：目标语言弹窗是个独立大对话框

### 现象

问「目标语言」用的是全屏遮罩的 `AlertDialog`，比它通向的那个答案窗口大好几倍。

### 根因分析

答案已经改成了贴边的小卡片，问题却还留在原来的大对话框里——同一次交互的两半用了两种容器，而大的那半只装一行输入。

### 修复方案

在**答案将要出现的那张卡片里**提问：卡片带上问题、选项 chips、输入框和确定按钮。插件记住的上次答案排在选项第一位，一按即用，不用重打。

关掉卡片等于「不回答」：等待中的 `Completer` 以 null 完成，而不是让运行永远挂在一个不会完成的 future 上——那会同时漏掉一个没有 dispose 的服务。

`dismissIfWaiting`（收尾时清掉「进行中」）不会动一个正在提问的卡片：那是在等读者，替他关掉就等于替他回答了。

### 涉及文件

`plugin_provider.dart`、`plugin_tip.dart`、`plugin_command_actions.dart`

---

## BUG-261：全文翻译一段一个请求

### 现象

全文翻译很慢。

### 根因分析

按空行切段之后，**每段一个请求**。一篇几十段的文档就是几十次往返，每次都付一遍网络和排队的延迟，而这些文字合起来往往一两次就发完了。

### 修复方案

切段照旧（它解决的问题仍然成立：失败只损失一批而不是整篇，读者能先看到开头），在它之上加一层批次：相邻段落合并到约 1500 字符为止。

三条例外：
- 围栏代码块不切开
- 单段超过预算就自己走一批——再小就得把段落切两半，那正是切段要避免的
- **标题不单独成批**：「## Results」自己一条，模型无从判断语域和主题

### 验证

三次突变：预算设为 1（回到一段一请求）杀 3 条；预算设为无穷（整篇一次）杀 3 条；去掉标题特判杀 1 条。

第三次突变**第一次没杀掉**——那条测试用的文档太短，无论标题规则如何都会合并成一批，所以它什么也没测。改成让标题正好落在预算边界上（前面一段填满预算、标题在末尾）才真正验证了规则。

而修好这条测试之后，**正确代码也失败了**：批次在「装满后立刻收尾」，于是标题到来时上一批已经关了，它只能自己开一批——正是标题规则要防的情况。收尾的判断必须发生在**下一块到来时**，不能在加入之后。

### 涉及文件

插件 `lib/blocks.lua`、`plugin.lua`；`ai_translate_plugin_test.dart`
