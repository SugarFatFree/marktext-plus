# v1.6.0 调研发现

- 当前项目是 Dart/Flutter，暂无官方 Anthropic SDK；若 AI 插件实际调用 Anthropic API，应通过受控 raw HTTPS 客户端，不引入 OpenAI-compatible shim。
- `AppConfig` 目前所有配置直接序列化到 JSON；API key 不应沿用该路径明文持久化。
- Flutter 桌面应用不能把任意 ZIP 中的 Dart 代码安全地动态加载进已发布进程；插件必须是外部可执行进程或受限数据包。
- 可信插件市场采用专用 GitHub 组织/索引仓库优于“搜索任意带 tag 的仓库”：可维护 manifest、兼容版本、SHA-256、撤下状态和审核元数据。
- 远程市场索引必须异步、延迟到应用窗口可交互后加载，失败不影响编辑器启动。
- 当前仓库没有 `gh` CLI；GitHub 新仓库创建不可在没有授权的情况下假设完成。
