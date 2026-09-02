# v1.6.0 工作进度

## 2026-09-02

- 已确认专用 GitHub 插件索引仓库方案。
- 已确认插件采用独立进程 + JSON-RPC/stdio，避免插件故障卡死主应用。
- 已确认主题插件首版采用数据型主题包。
- 已确认 AI 配置需要 provider-neutral 模型和受控 secret bridge。
- 已发现当前 `AppConfig`、设置页和发布文档入口。
- 尚未修改应用代码，等待 Phase 1 架构文件完成后开始 TDD 实现。
- 已实现 AI provider 配置模型与设置页（OpenAI/Anthropic、endpoint、model、secret reference）。
- 已实现插件 manifest、日志轮转、ZIP 安全安装、HTTPS catalog 和 SHA-256 校验。
- 已实现独立插件进程宿主、请求超时和日志转发。
- v1.6.0 文档已创建；SDK/AI 翻译插件 GitHub 仓库已创建并推送。
- 版本元数据已切换到 `1.6.0+1` / `appVersion 1.6.0`，CHANGELOG 开始 v1.6.0 开发段。
- 已补充外部 SDK 与 AI 翻译插件仓库规划；两个仓库已创建、推送并添加 Topic。
- 两个仓库已添加 Topic `marktext-plus-plugin`，采用无审核社区插件发现模式。主应用已增加 GitHub Topic 搜索和 Release digest 读取。
- 插件管理 UI 已接入设置页：异步已安装列表、ZIP 安装和 GitHub Topic 发现。
- v1.6.0 全量测试已达 2021 项通过，静态分析无问题。
- 组织迁移后的 Linux CI 首次失败原因是缺少 libsecret-1-dev，已修正 CI 安装依赖并通过远程构建。
- v1.6.0 已完成 main 合并、tag 和远程 Release，生成 Windows/macOS/Linux 全部目标资产。
