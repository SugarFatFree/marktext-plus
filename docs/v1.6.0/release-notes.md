# MarkText Plus v1.6.0

> 开发中的版本说明，尚未创建 tag。

## Added

- 插件 manifest、ZIP 安装、路径穿越防护和原子安装。
- 独立进程 JSON-RPC/stdio 宿主，支持请求超时和插件日志。
- GitHub Topic `marktext-plus-plugin` 的开放插件发现，以及 Release ZIP 的 SHA-256 下载校验。
- 设置页增加 OpenAI 和 Anthropic provider、endpoint、model、secret reference 配置。

## Reliability

- 插件不进入主 Flutter isolate，插件崩溃或超时不会阻塞编辑器。
- API key 不写入普通 `config.json`。

## Notes

- SDK 和 AI 翻译插件已发布到 `marktext-plus-plugins` 组织，并分别维护独立版本号 `v0.1.0`。
- v1.6.0 发布前只剩远程 CI 目标平台构建验证。
