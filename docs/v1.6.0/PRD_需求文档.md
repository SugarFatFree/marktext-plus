# v1.6.0 功能需求文档

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-085 | 2026-09-02 | 插件 manifest、ZIP 安装和独立进程协议 | P1 | 高 | 已完成 |
| FEAT-086 | 2026-09-02 | 插件日志隔离与轮转 | P1 | 中 | 已完成 |
| FEAT-087 | 2026-09-02 | 插件市场 HTTPS 索引和 SHA-256 校验 | P1 | 中 | 已完成 |
| FEAT-088 | 2026-09-02 | OpenAI/Anthropic AI 配置项 | P2 | 中 | 已完成 |
| FEAT-089 | 2026-09-02 | 插件 SDK 和 AI 翻译插件独立仓库 | P1 | 高 | 已完成 |
| FEAT-090 | 2026-09-02 | 插件管理 UI | P1 | 中 | 已完成 |
| FEAT-091 | 2026-09-02 | 系统密钥环 secret bridge | P1 | 中 | 已完成 |

---

## FEAT-085：插件 manifest、ZIP 安装和独立进程协议

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 支持可验证插件包，并让插件代码运行在独立子进程 |
| 用户场景 | 插件崩溃或卡死时编辑器仍可编辑文档 |
| 实现方案 | `PluginManifest`、`PluginManager`、`PluginProcessHost`；JSON-RPC/stdio、请求超时和进程终止 |
| 验收标准 | manifest 错误隔离、ZIP 路径穿越拒绝、插件请求超时不阻塞主应用 |
| 涉及文件 | `code/lib/services/plugin_manifest.dart`、`plugin_manager.dart`、`plugin_process_host.dart` |

## FEAT-086：插件日志隔离与轮转

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 每个插件拥有独立日志并限制日志增长 |
| 实现方案 | `PluginLogger` 按插件 ID 写文件，保留一个 `.1` 轮转文件，默认 512 KiB |
| 验收标准 | INFO/WARN/ERROR 可区分，超限自动轮转 |
| 涉及文件 | `code/lib/services/plugin_logger.dart` |

## FEAT-087：插件市场 HTTPS 索引和 SHA-256 校验

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 从公开 GitHub Topic 发现插件并校验下载内容 |
| 实现方案 | GitHub Topic `marktext-plus-plugin` 自动发现公开仓库，再读取最新 Release 的 HTTPS ZIP 和 SHA-256 |
| 验收标准 | 无 Topic、无可验证 Release、非 HTTPS 或摘要不匹配时不进入可安装列表 |
| 涉及文件 | `code/lib/services/plugin_catalog_service.dart` |

## FEAT-088：OpenAI/Anthropic AI 配置项

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 设置页提供 provider、endpoint、model 和 secret reference |
| 实现方案 | `AppConfig` 保存非敏感元数据；API key 不写入 `config.json` |
| 验收标准 | 配置可持久化，未知 provider 回退 OpenAI，JSON 不含 API key |
| 涉及文件 | `app_config.dart`、`settings_screen.dart`、本地化文件 |

## FEAT-090：插件管理 UI

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 在设置页提供异步插件列表、ZIP 安装和 GitHub Topic 发现入口 |
| 用户场景 | 用户主动打开设置页后安装或查看社区插件，启动阶段不产生网络和扫描开销 |
| 实现方案 | `FutureBuilder` 延迟加载 `PluginManager`；文件选择器安装 ZIP；按钮触发 `PluginCatalogService.searchGitHubTopic`；所有结果标记 Community/Unverified |
| 验收标准 | 设置页无溢出、插件列表异步加载、ZIP 安装成功后刷新、Topic 发现失败不影响编辑器 |
| 涉及文件 | `code/lib/ui/screens/settings_screen.dart`、插件本地化文件 |

## FEAT-091：系统密钥环 secret bridge

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 让 AI 插件按 reference 获取 API key，而不把密钥写入普通配置文件 |
| 用户场景 | 用户配置 OpenAI 或 Anthropic 后，插件需要调用模型但不能读取无关密钥 |
| 实现方案 | `PlatformSecretStore` 使用 flutter_secure_storage 对接 Windows Credential Manager、macOS Keychain 和 Linux secret service；`PluginSecretBridge` 只解析指定 reference |
| 验收标准 | secret 可读写删除，空 reference 不访问存储，`config.json` 不含 API key |
| 涉及文件 | `code/lib/services/plugin_secret_store.dart` |

## FEAT-089：插件 SDK 和 AI 翻译插件独立仓库

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 提供 SDK 和读取统一 AI 配置的翻译插件示例 |
| 实现方案 | 两个公开仓库已创建于 `marktext-plus-plugins` 组织，并添加 Topic `marktext-plus-plugin` |
| 验收标准 | 仓库公开、SDK 含 manifest/JSON-RPC 示例、翻译插件具备日志和错误处理 |
| 涉及文件 | `https://github.com/marktext-plus-plugins/marktext-plus-plugin-sdk`、`https://github.com/marktext-plus-plugins/marktext-plus-ai-translate-plugin` |
