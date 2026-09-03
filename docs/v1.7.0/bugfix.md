# v1.7.0 Bug 修复记录

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
| BUG-235 | 2026-09-03 | Windows arm64 被记为"做不到"，理由已不成立 | P2 | 验证中 |

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
