# MarkText Plus v1.6.0

> 开发中的版本说明，尚未创建 tag。

## Added

- 插件 manifest、ZIP 安装、路径穿越防护和原子安装。
- 独立进程 JSON-RPC/stdio 宿主，支持请求超时和插件日志。
- HTTPS 插件市场索引与 SHA-256 下载校验。
- 设置页增加 OpenAI 和 Anthropic provider、endpoint、model、secret reference 配置。

## Reliability

- 插件不进入主 Flutter isolate，插件崩溃或超时不会阻塞编辑器。
- API key 不写入普通 `config.json`。

## Notes

- SDK 和 AI 翻译插件将使用独立 GitHub 仓库；创建仓库需要 GitHub 写权限，当前尚未伪造为已完成。
- v1.6.0 发布前仍需接入插件管理 UI、系统 secret bridge，并完成目标平台实机验证。
