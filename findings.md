# v1.6.0 调研发现

- 当前项目是 Dart/Flutter，暂无官方 Anthropic SDK；若 AI 插件实际调用 Anthropic API，应通过受控 raw HTTPS 客户端，不引入 OpenAI-compatible shim。
- `AppConfig` 目前所有配置直接序列化到 JSON；API key 不应沿用该路径明文持久化。
- Flutter 桌面应用不能把任意 ZIP 中的 Dart 代码安全地动态加载进已发布进程；插件必须是外部可执行进程或受限数据包。
- 完全开放市场采用 GitHub Topic `marktext-plus-plugin` 自动发现；不做人工审核，应用必须标记 Community/Unverified，并保留 manifest、兼容版本和 SHA-256 校验。
- 远程市场索引必须异步、延迟到应用窗口可交互后加载，失败不影响编辑器启动。
- 当前仓库没有 `gh` CLI；GitHub 新仓库创建不可在没有授权的情况下假设完成。

- GitHub CLI 已确认可用，两个公开仓库已创建在 `SugarFatFree` 账号下；当前不需要 Organization。
