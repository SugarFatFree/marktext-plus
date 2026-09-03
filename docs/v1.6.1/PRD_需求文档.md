# v1.6.1 功能需求文档

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-092 | 2026-09-02 | 左侧边栏插件入口和社区插件面板 | P1 | 中 | 已完成 |
| FEAT-093 | 2026-09-02 | 插件开发 SDK 快速入口 | P2 | 低 | 已完成 |
| FEAT-094 | 2026-09-02 | 插件启用/禁用、卸载和 AI 翻译动作 | P1 | 中 | 已完成 |
| FEAT-095 | 2026-09-02 | 插件权限和菜单/工具栏贡献描述 | P1 | 高 | 已完成 |
| FEAT-096 | 2026-09-02 | 社区插件详情页签与安装流程 | P1 | 中 | 已完成 |
| FEAT-097 | 2026-09-02 | 单一 AI API key 配置与插件传递 | P1 | 中 | 已完成 |
| FEAT-098 | 2026-09-02 | 插件独立设置页和菜单贡献宿主渲染 | P1 | 高 | 已完成 |
| FEAT-099 | 2026-09-02 | 预览选区翻译与全文双视图预览 | P1 | 中 | 已完成 |
| FEAT-100 | 2026-09-02 | 预览底部留白适配 | P2 | 低 | 已完成 |
| FEAT-101 | 2026-09-03 | 插件脚本运行时：Lua 沙箱与 action 协议 | P0 | 高 | 已完成 |
| FEAT-102 | 2026-09-03 | JavaScript 运行时（QuickJS）双支持 | P1 | 高 | 已完成 |
| FEAT-103 | 2026-09-03 | 插件权限模型：17 项，声明并强制 | P1 | 中 | 已完成 |
| FEAT-104 | 2026-09-03 | 插件自有设置与宿主渲染的设置页 | P1 | 中 | 已完成 |
| FEAT-105 | 2026-09-03 | 插件自带多语言，按地区回退 | P2 | 低 | 已完成 |
| FEAT-106 | 2026-09-03 | 按平台的编译型插件（entrypoints） | P1 | 中 | 已完成 |
| FEAT-107 | 2026-09-03 | 右键打开插件目录 | P2 | 低 | 已完成 |
| FEAT-108 | 2026-09-03 | 插件进程登记与孤儿回收 | P1 | 中 | 已完成 |
| FEAT-109 | 2026-09-03 | 插件可占用文档周围的窗格（最多四宫格） | P1 | 高 | 已完成 |
| FEAT-110 | 2026-09-03 | 右侧边栏与抽屉，没有图标时整条隐藏 | P1 | 中 | 已完成 |
| FEAT-111 | 2026-09-03 | 全文翻译逐段喂给模型，边译边显示 | P0 | 高 | 已完成 |
| FEAT-112 | 2026-09-03 | 插件可由多个文件组成（受限 require） | P0 | 高 | 已完成 |
| FEAT-113 | 2026-09-03 | 菜单条件 when、侧栏面板、菜单栏贡献 | P1 | 中 | 已完成 |
| FEAT-114 | 2026-09-03 | 编译型插件的启动令牌：不是编辑器启动的就退出 | P1 | 中 | 已完成 |
| FEAT-115 | 2026-09-03 | 插件 API 契约测试：能加，不能悄悄减 | P1 | 中 | 已完成 |
| FEAT-116 | 2026-09-03 | 官方 SDK 与示例插件：三种语言、11 种语言的说明 | P1 | 高 | 已完成 |

---

## FEAT-092：左侧边栏插件入口和社区插件面板

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 将插件入口放到左侧文件、搜索、目录按钮下方，并展示已安装和社区插件 |
| 用户场景 | 用户在主要工作区即可打开插件面板，主动安装 ZIP 或发现 GitHub Topic 插件 |
| 实现方案 | 新增 `SideBarTab.plugins` 和 `PluginPanel`；异步加载插件目录，点击按钮才访问 GitHub |
| 验收标准 | 不增加启动网络请求，面板显示错误/空状态，社区插件标记为 Community/Unverified |
| 涉及文件 | `sidebar_provider.dart`、`side_bar.dart`、`plugin_panel.dart` |

## FEAT-093：插件开发 SDK 快速入口

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 在插件面板提供直接打开 SDK 仓库的入口 |
| 用户场景 | 想开发插件的用户无需离开应用菜单寻找 SDK 地址 |
| 实现方案 | 使用系统浏览器打开 `https://github.com/marktext-plus-plugins/marktext-plus-plugin-sdk` |
| 验收标准 | 点击后打开 SDK 页面，未配置浏览器时显示错误，不阻塞编辑器 |
| 涉及文件 | `code/lib/ui/widgets/plugin_panel.dart` |

## FEAT-094：插件启用/禁用、卸载和 AI 翻译动作

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 管理插件生命周期，并让 AI 翻译插件可以处理当前源码选区 |
| 用户场景 | 用户关闭有问题的插件、卸载插件，或在选中文字后直接翻译 |
| 实现方案 | `PluginManager` 持久化启用状态和卸载；`PluginPanel` 启动独立插件进程并调用 `initialize`/`translate` |
| 验收标准 | 开关状态跨重启保留，卸载移除插件目录，翻译结果替换选区且插件异常不阻塞编辑器 |
| 涉及文件 | `plugin_manager.dart`、`plugin_panel.dart`、`plugin_process_host.dart` |

## FEAT-095：插件权限和菜单/工具栏贡献描述

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 允许插件声明权限并贡献宿主控制的命令、菜单和工具栏按钮 |
| 用户场景 | 插件需要文档读取、网络或右键菜单动作，同时不直接注入任意 Flutter Widget |
| 实现方案 | manifest 增加 `permissions`、`commands`、`menus`、`toolbar`、`settings`；`PluginActionService` 通过独立进程执行，宿主只渲染固定菜单和工具栏槽位，禁止任意坐标和任意 Widget 注入 |
| 验收标准 | manifest 可解析，命令和 toolbar 已注册到宿主；菜单/设置 descriptor 已定义协议，固定槽位不改变主窗口布局稳定性 |
| 涉及文件 | `plugin_manifest.dart`、SDK schema；菜单/工具栏渲染仍在后续迭代 |

## FEAT-096：社区插件详情页签与安装流程

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 点击社区插件后查看详情，并提供明确的安装操作 |
| 用户场景 | 用户需要先查看作者仓库、版本、说明和未验证提示，再决定安装 |
| 实现方案 | `PluginCatalogEntry` 保存 repository URL；`PluginPanel` 用主内容区详情页签展示信息并调用带 SHA-256 校验的安装服务 |
| 验收标准 | 点击条目有反馈，详情可滚动，Install 能触发安装，网络/空列表状态可读 |
| 涉及文件 | `plugin_catalog_service.dart`、`plugin_panel.dart` |

## FEAT-097：单一 AI API key 配置与插件传递

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 允许用户通过单一字段输入真实 API key，并让插件使用它 |
| 用户场景 | 配置 OpenAI 或 Anthropic 后测试连接、使用 AI 翻译插件 |
| 实现方案 | 设置页单一明文字段写入 `AppConfig`；插件通过 JSON-RPC initialize 接收内存 key |
| 验收标准 | key 按用户选择保存在 config.json，且只通过 initialize 传给插件，测试连接可读取已保存 key，插件可获得正确 key |
| 涉及文件 | `plugin_secret_store.dart`、`settings_screen.dart`、`ai_connection_service.dart`、`plugin_panel.dart` |

## FEAT-098：插件独立设置页和菜单贡献宿主渲染

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 让插件提供设置 descriptor 和菜单 descriptor，由主应用在受控页面和菜单中渲染 |
| 用户场景 | 插件拥有自己的 JSON 设置，或在插件菜单中提供动作，而不直接修改 Flutter UI 树 |
| 实现方案 | `PluginSettingsScreen` 通过 `getSettings`/`setSettings` JSON-RPC 工作；`AppMenuBar` 渲染 commands/menus；工具栏使用固定槽位 |
| 验收标准 | 设置页可读写 JSON，菜单动作通过独立进程执行，插件不能注入任意坐标或 Widget |
| 涉及文件 | `plugin_settings_screen.dart`、`app_menu_bar.dart`、`plugin_action_service.dart` |

## FEAT-099：预览选区翻译与全文双视图预览

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 支持预览选区翻译，全文翻译以双视图只读结果展示且不修改原文 |
| 用户场景 | 用户在预览或源码中选择内容，或查看整篇译文并决定是否手工采用 |
| 实现方案 | `EditorState.selectedText` 统一选区；插件返回结果后用左右 `SelectableText` 展示原文和译文 |
| 验收标准 | 预览选区可识别，全文翻译不改写 tab 内容，结果可复制 |
| 涉及文件 | `editor_provider.dart`、`markdown_renderer.dart`、`plugin_panel.dart` |

## FEAT-100：预览底部留白适配

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 将预览底部滚动余量从 60% 调整为 25% 视口高度 |
| 用户场景 | 短文档滚动到底部时仍保留舒适余量，但不出现半屏空白 |
| 实现方案 | `MarkdownRenderer.bottomRoomForHeight` 使用 25% 比例和 500px 上限 |
| 验收标准 | 800px 视口余量为 200px，长视口不无限增长 |
| 涉及文件 | `markdown_renderer.dart`、`preview_bottom_room_test.dart` |

## FEAT-101：插件脚本运行时——Lua 沙箱与 action 协议

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 插件必须能在只装了编辑器的机器上运行，不依赖任何 SDK |
| 用户场景 | 用户装一个社区插件就能用，作者写一个文件就能发布，三平台通用 |
| 实现方案 | 内嵌 `lua_dardo`（纯 Dart，424KB）。因为解释器是同步的、没有协程，凡是耗时的事（问用户、调模型）都由脚本**返回一个 action**、宿主执行、再回调脚本——`on_command` / `on_result`。沙箱把 `os`、`package`、`require`、`dofile`、`loadfile` 全部置 nil（`openLibs` 会带进 `os.execute`/`os.remove`），只留 `string`/`table`/`math`，外加 `storage` 和 `t()` |
| 验收标准 | 一个 `.lua` 文件在三平台通用；脚本无法读写文件、无法发起网络请求、无法执行命令；语法错误在加载时报给作者而不是抛出解释器内部异常；单次运行步数上限 8 |
| 涉及文件 | `plugin_script_runtime.dart`、`plugin_command_service.dart`、`plugin_script_runtime_test.dart` |

## FEAT-102：JavaScript 运行时（QuickJS）

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 让插件作者可以选择 JavaScript 而不是只能写 Lua |
| 用户场景 | 前端背景的作者不必为写一个插件先学 Lua |
| 实现方案 | `flutter_js` 的 QuickJS。实测体积：Linux 941KB `.so`、Windows 662KB `.dll`、macOS 从源码编译。能力以普通全局变量注入并用 JSON 往返，绕开较少验证的 channel 桥。两种运行时实现同一个 `PluginRuntimeHost` 接口，编辑器不关心插件用哪种语言 |
| 验收标准 | 与 Lua 完全相同的 action 协议和能力；`parseAction` 抽成静态函数以便在没有原生库的测试环境里验证 |
| 涉及文件 | `plugin_js_runtime.dart`、`plugin_js_runtime_test.dart` |
| 已知限制 | QuickJS 原生库只存在于构建产物里，`flutter test` 加载不到，因此引擎本身的行为**测试套件无法验证**，只能由 CI 的真实构建证明。Linux 与 Windows 已在 CI 通过，macOS 待 release 构建确认 |

## FEAT-103：插件权限模型

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 参考 VS Code / IntelliJ 的贡献点范围，尽量开放，但要能约束 |
| 用户场景 | 用户在安装前看到插件要什么；插件越权时被拒绝而不是得逞 |
| 实现方案 | 17 项权限：`document.*`、`ui.*`（9 项槽位）、`ai.chat`、`storage.local`、`clipboard.*`、`workspace.*`、`network.request`。与 VS Code/IntelliJ 的关键差别是**强制执行**——那两者展示后即信任，这里没有任何人审核，所以由编辑器检查。检查放在 `PluginCommandService._guard`，而不是各个执行点，新增调用方不会漏掉 |
| 验收标准 | 未声明 `ai.chat` 的插件返回 `{ai=...}` 不会调用模型，而是告诉用户它没申请这项权限；未声明 `document.write` 无法替换选区 |
| 涉及文件 | `plugin_manifest.dart`、`plugin_command_service.dart` |

## FEAT-104：插件自有设置与宿主渲染的设置页

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 允许插件保存自己的设置文件，并自行定义设置页的条目 |
| 用户场景 | 插件记住用户的偏好；用户在真实控件上修改，而不是手写 JSON |
| 实现方案 | manifest 的 `settings` 声明字段（`key`/`title`/`type`/`default`），编辑器据此画控件：`boolean` 给开关、`password` 遮蔽、`number` 给数字键盘。插件提供**数据而不是 Widget**，所以插件无法改动编辑器的布局树。值存在插件自己目录下的 `settings.json` |
| 验收标准 | 每个插件只能读写自己的设置；保存后已加载的脚本被丢弃重载，下一条命令即读到新值，无需重启 |
| 涉及文件 | `plugin_settings_screen.dart`、`plugin_command_service.dart`、`plugin_settings_screen_test.dart` |

## FEAT-105：插件自带多语言

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 允许插件自制更多国家的语言翻译，不受编辑器支持的 12 种语言限制 |
| 用户场景 | 插件作者想支持编辑器还没支持的语言 |
| 实现方案 | manifest 的 `locales` 是作者自己的字符串表，`defaultLocale` 是兜底。解析顺序为地区→语言→默认（`zh_CN` → `zh` → `en`）。脚本里用 `t(key)` 取，查不到时返回 key 本身，这样漏翻的条目显示成键名而不是空白菜单项 |
| 验收标准 | 菜单标题、提问文案、设置项标题都能被翻译；插件可以只带一种语言 |
| 涉及文件 | `plugin_manifest.dart`（`stringsFor`）、`plugin_command_service.dart` |

## FEAT-106：按平台的编译型插件

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 支持编译成原生可执行文件的插件，在 manifest 里声明支持的平台种类并指定各平台入口 |
| 用户场景 | 插件需要真正的工具链、第三方库或长时间运行的工作，脚本运行时不够用 |
| 实现方案 | `runtime: "process"` 配 `entrypoints`：**先按操作系统，架构在其下且可省**。一个路径覆盖该系统的所有架构（macOS 通用二进制就是一个文件装两种架构，本应用自己发的就是这种），也可以用 `default` 加某个架构的专门构建，专门的优先。编辑器用 `PluginManager.currentPlatform` 认自己。选进程而非 `.so`/`.dll` FFI：FFI 在进程内运行，插件一崩就带走编辑器，与"插件不能拖垮宿主"这条相矛盾；而 `dart compile exe` 是官方支持的路径 |
| 验收标准 | 没有当前平台构建时明说"没有 linux-arm64 的构建，它带了 macos-x64、macos-arm64、windows-x64"——报的是**具体平台**而不是"支持 macOS"，否则用户还得自己推自己这台算不算；`runtime: "process"` 却没有 `entrypoints`、或声明了某个系统却在下面留空，都在解析阶段被拒；系统名或架构名拼错**报错而不是跳过**（跳过会变成"你的平台不支持"，无从解释）；任何 `.dart` 入口被拒 |
| 涉及文件 | `plugin_manifest.dart`、`plugin_manager.dart`、`plugin_platform_test.dart` |
| 为什么不是 .so/.dll | 两条独立理由。**一、线程给的是并发不是隔离**：`.so` 与编辑器共享地址空间，段错误、栈溢出、`abort()` 会连同用户未保存的文档一起带走进程，且没有堆栈可上报；死循环冻结窗口且无法打断；`dlclose` 不可靠，"禁用插件"其实没卸载。独立进程把这三样都拿回来了——可以崩、可以超时杀、编辑器活着并说清是哪个插件。**二、对 Dart 而言没有取舍**：`dart compile` 的子命令只有 js / jit-snapshot / kernel / exe / aot-snapshot / wasm，官方文档和 `dart-lang/sdk` 主干源码（`pkg/dartdev/lib/src/commands/compile.dart`）都没有 `dynamic-library`，全仓库搜该字符串 0 结果。`aot-snapshot` 也不是 dlopen 得到的 C 库，它需要 `dartaotruntime` 或自建嵌入器 |
| 双击防护 | 编译型插件是文件夹里的真实可执行文件，早晚会被双击。编辑器启动时传 `--marktext-plus-plugin-host`，SDK 要求插件收不到就打印说明并退出，而不是干等 stdin 像卡死。**只能让插件有能力说清自己是什么，强制不了**——作者不写这段检查，双击照样干等，这与"stdin 收到 EOF 要退出"是同一类约定 |

## FEAT-107：右键打开插件目录

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 在已安装插件列表上右键，用系统文件管理器打开该插件的安装目录 |
| 用户场景 | 插件目录在系统应用支持目录下，用户不可能猜到路径，而配置文件就在那里 |
| 实现方案 | `FileReveal.openDirectory(manager.directoryOf(plugin))`。顺带把项目里抄了两份且已漂移的"在文件管理器中显示"收敛成一份（见 BUG-233） |
| 验收标准 | 12 种语言的菜单文案；打开的是插件目录本身而不是它的上一级 |
| 涉及文件 | `file_reveal.dart`、`plugin_panel.dart`、`plugin_manager.dart` |

## FEAT-108：插件进程登记与孤儿回收

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 主程序崩溃后不留下无人认领的插件进程 |
| 用户场景 | 用户强杀编辑器或系统断电后，插件进程不该继续占着资源 |
| 实现方案 | 见 BUG-232。正常关闭先关 stdin 再杀；启动过的进程记入 `plugins/running.json`，下次启动前（且在任何插件被启动之前）回收，回收前用 `/proc`（Linux）、`ps -o comm=`（macOS）、`tasklist`（Windows）确认 pid 还是同一个程序 |
| 验收标准 | 无残留时启动只多一次"文件是否存在"的判断，不写盘，不影响秒启动；pid 被复用时不误杀 |
| 涉及文件 | `plugin_process_registry.dart`、`plugin_process_host.dart`、`main.dart` |
| 已知限制 | 只能回收编辑器直接启动的进程。插件自己 fork 的孙子进程不在登记表里，由插件作者负责——SDK 文档已写明 |

## FEAT-109：插件可占用文档周围的窗格

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 编辑器本来就能把标签页分成源码/预览双栏，把这个能力开放给插件，最多四宫格 |
| 用户场景 | 全文翻译要把译文放在原文旁边长时间对照，弹窗和抽屉都不合适——它们是「看一眼就关」的容器 |
| 实现方案 | 脚本返回 `pane` 动作，带 `slot`（`right`/`bottom`/`corner`）与 `render`（`text`/`source`/`preview`）。文档固定占 2×2 网格的第一格，其余三格按需出现。`PluginPaneSlot` 与 `PluginPaneRender` 两个枚举在 Lua 与 JS 两个运行时保持一致 |
| 验收标准 | 没有插件填的格子不画，只填 `corner` 不会留下两条空白带；未知的 slot 名在安装时拒绝而不是猜一个——「出现在没要的位置且无从得知为什么」比拒绝更糟；`panes.isEmpty` 时直接返回原文档 widget，不引入任何额外层级 |
| 涉及文件 | `plugin_panes.dart`、`plugin_script_runtime.dart`、`plugin_js_runtime.dart`、`plugin_panes_test.dart`、`plugin_panes_layout_test.dart` |

## FEAT-110：右侧边栏与抽屉

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 左侧已有边栏与抽屉，增加右侧的；没有图标时整条隐藏 |
| 用户场景 | 插件想常驻一个入口，但左侧是文件树、搜索、目录这些编辑器自己的东西，不该被插件挤占 |
| 实现方案 | manifest 的 `panels` 贡献一个图标，点击打开抽屉，抽屉内容由「跑一遍同名命令」得到。需要 `ui.sidebar` 权限，且 `icon` 为必填 |
| 验收标准 | 没有任何插件贡献面板时 `contributions.isEmpty` 直接 `SizedBox.shrink()`——一条没有图标的图标栏是白占文档宽度；抽屉里的命令若返回 `ask` 或 `ai`，以文本形式说明而不是停下来发问（抽屉不是对话框） |
| 涉及文件 | `right_side_bar.dart`、`plugin_manifest.dart`、`right_sidebar_test.dart`、`plugin_contribution_test.dart` |

## FEAT-111：全文翻译逐段进行

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 全文翻译不要把整篇文档一次性喂给大模型，按最小段落逐段翻译，视图也逐段显示 |
| 用户场景 | 一篇几万字的文档整篇送出去，要么超上下文，要么等几十秒白屏；用户看不到进度，也不知道是不是卡死了 |
| 实现方案 | 脚本返回的 `pane` 动作增加 `append`（把这一段追加到已有内容后面，而不是整体替换）和 `nextPrompt`（这一段完了接着译哪一段）。插件侧 `lib/blocks.lua` 负责切段 |
| 验收标准 | 每段译完立即出现在窗格里；窗格的视图模式跟随用户发起翻译时所处的模式（源码视图译出源码视图，预览视图译出预览视图），由 `ctx.view` 传给脚本 |
| 实现要点 | 运行时读字段的顺序至关重要：`pane` 必须在 `ai` **之前**读。一个同时带两者的返回值意思是「先把这段显示出来，再去问下一段」，先读 `ai` 会把刚译完的那段吞掉 |
| 涉及文件 | `plugin_script_runtime.dart`、`plugin_js_runtime.dart`、`plugin_streaming_test.dart`、AI 翻译插件 `plugin.lua` 与 `lib/blocks.lua` |

## FEAT-112：插件可由多个文件组成

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 脚本插件不能只是单文件——复杂插件需要拆分，第三方也需要能封装出可复用的库 |
| 用户场景 | AI 翻译插件本身就需要切段逻辑与 SDK 封装两个模块；官方 SDK 的 `lib/marktext-plus.lua` 就是靠这个机制被插件加载的 |
| 实现方案 | 在 Dart 的 `__load(name)` 之上用 Lua 实现 `require`（JS 侧是 CommonJS 形态的 `require`，走 `sendMessage('__load', ...)`）。同一模块只加载一次 |
| 验收标准 | 名字是名字不是路径：带分隔符、带 `..`、以点开头的一律在读盘之前拒绝；解析出的文件还要再验证一次「确实在插件目录内」——这一步是用来抓指向外部的软链接的。**因此拆分插件或分发第三方库，不会换来任何额外的磁盘访问权限** |
| 涉及文件 | `plugin_script_runtime.dart`、`plugin_js_runtime.dart`、`plugin_command_service.dart`、`plugin_modules_test.dart` |

## FEAT-113：菜单条件、侧栏面板、菜单栏贡献

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 三件插件菜单一直缺的东西：按有无选区决定是否出现、贡献侧栏面板、贡献顶部菜单栏条目 |
| 用户场景 | 没有 `when` 的时候，「翻译选中」和「翻译全文」永远同时出现——用户没选中任何东西时也在劝他翻译选区 |
| 实现方案 | `PluginMenuCondition {always, selection, noSelection}` 加 `appliesTo`；顶部菜单栏条目只取 `commands`，且必须声明 `ui.menuBar`，标题走翻译 |
| 验收标准 | 编辑器不认识的 `when` 值在安装时拒绝，而不是静默当成 `always`；菜单栏条目的标题按用户语言显示 |
| 涉及文件 | `plugin_manifest.dart`、`plugin_menu_bar_entries.dart`、`plugin_menu_bar_test.dart`、`plugin_contribution_test.dart` |

## FEAT-114：编译型插件的启动令牌

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 防呆：用户直接双击或从命令行运行插件的可执行文件时，不要真的起进程干活。要求是**轻验证**，不做过强的防护 |
| 用户场景 | 用户在插件目录里看到一个可执行文件，好奇点了一下——它不该坐在 stdin 上装成一个卡死的程序 |
| 实现方案 | 编辑器每次启动生成一个令牌，经**环境变量** `MARKTEXT_PLUS_PLUGIN_TOKEN` 传给子进程；SDK 的 `serve()` 在没有它时打印一行说明自己是什么，然后以 1 退出 |
| 验收标准 | 令牌走环境变量而不是 argv——argv 任何会用 `ps` 的东西都读得到；脚本插件天然免疫（`.lua`/`.js` 由编辑器解释，双击最多打开一个文本编辑器） |
| 边界说明 | 没有任何程序能阻止用户执行自己磁盘上的文件。令牌让**「是不是编辑器启动的我」这个回答无法伪造**，进程于是「起来、说明自己是什么、退出」。验证写在 SDK 的 `serve()` 里而不是只写在文档里——写在文档里的防呆等于没有 |
| 涉及文件 | `plugin_manager.dart`（`launchTokenVariable`、`newLaunchToken()`）、`plugin_launch_token_test.dart`、SDK `examples/dart/lib` |

## FEAT-115：插件 API 契约测试

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 插件是别人机器上的文件。弄坏它不是这边能看见的编译错误，而是用户那边突然不能用了 |
| 用户场景 | 插件作者需要知道自己今天能写的东西明天还能不能写 |
| 实现方案 | `plugin_contract_test` 钉住：17 个权限名、每个 `runtime` 值、脚本能返回的每种动作、`ctx` 的每个字段，以及 `storage`/`t`/`require` 三个全局 |
| 验收标准 | **往这些清单里加东西是自由的；删掉或改名会让这条测试失败**，因此不会因为疏忽而发生。0.x 期间仍允许有意的不兼容变更，但必须写进变更记录 |
| 涉及文件 | `test/services/plugin_contract_test.dart`、SDK README 的「Compatibility」一节 |

## FEAT-116：官方 SDK 与示例插件

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-03 |
| 需求描述 | 应用要往插件生态方向走，需要一份能直接照抄的官方 SDK |
| 用户场景 | 第三方开发者打开仓库，应该能立刻判断「我该用哪个运行时」并复制一个能跑的插件 |
| 实现方案 | `examples/{lua,js,dart}/` 三个目录各是一个完整插件，按**语言**命名（`runtime` 在 manifest 里说明怎么跑）。每个目录都有 `lib/` 存放真正可被 `require` 的 API 模块——因为它是随插件分发的文件，不是可以指过去的依赖。另有 `schema/`（manifest JSON Schema）、`tool/`（`run-js-plugin.mjs` 按编辑器的方式跑 JS 插件、`check-translations.mjs` 校验译文）、`docs/i18n/`（11 种语言，与主应用一致） |
| 验收标准 | README 说明「Dart 只是示例用的语言，任何能编译成可执行文件的语言都可以」，并附 20 行 Python 示例证明协议只有四条规则；`lua` 与 `js` 是**同一个插件写两遍**，便于对照，并提示正式开发时只保留一个 |
| 涉及文件 | 独立仓库 `marktext-plus-plugins/marktext-plus-plugin-sdk`；主应用侧 `sdk_examples_test.dart`、`sdk_definitions_test.dart` 校验示例与编辑器实际行为一致 |
