# v1.6.0 功能需求文档

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-085 | 2026-09-02 | 插件 manifest、ZIP 安装和独立进程协议 | P1 | 高 | 已完成 |
| FEAT-086 | 2026-09-02 | 插件日志隔离与轮转 | P1 | 中 | 已完成 |
| FEAT-087 | 2026-09-02 | 插件市场 HTTPS 索引和 SHA-256 校验 | P1 | 中 | 已完成 |
| FEAT-088 | 2026-09-02 | OpenAI/Anthropic AI 配置项 | P2 | 中 | 已完成 |
| FEAT-089 | 2026-09-02 | 插件 SDK 和 AI 翻译插件独立仓库 | P1 | 高 | 待 GitHub 授权 |

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
| 需求描述 | 从受信 registry 获取插件并校验下载内容 |
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

## FEAT-089：插件 SDK 和 AI 翻译插件独立仓库

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-02 |
| 需求描述 | 提供 SDK 和读取统一 AI 配置的翻译插件示例 |
| 实现方案 | 规划 `marktext-plus-plugin-sdk` 与 `marktext-plus-ai-translate-plugin` 两个公开仓库；当前无 GitHub 写授权 |
| 验收标准 | 仓库公开、SDK 含 manifest/JSON-RPC 示例、翻译插件具备日志和错误处理 |
| 涉及文件 | 待外部仓库创建 |
