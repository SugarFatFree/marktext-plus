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
