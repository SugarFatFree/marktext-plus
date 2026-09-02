# MarkText Plus v1.6.0

> Released on 2026-09-02. English is the default language; the Chinese translation follows each section.
>
> 发布日期：2026-09-02。默认语言为英文，中文翻译紧随各章节之后。

## Added

- **Plugin foundation:** manifest validation, secure ZIP installation, path traversal protection, atomic replacement, and an isolated JSON-RPC/stdio process host.

  **插件基础设施：** manifest 校验、安全 ZIP 安装、路径穿越防护、原子替换，以及独立进程 JSON-RPC/stdio 宿主。
- **Open plugin discovery:** discover public repositories through the GitHub Topic [`marktext-plus-plugin`](https://github.com/topics/marktext-plus-plugin). Results are labelled Community / Unverified and are not manually reviewed by MarkText Plus.

  **开放插件发现：** 通过 GitHub Topic [`marktext-plus-plugin`](https://github.com/topics/marktext-plus-plugin) 发现公开仓库。结果标记为“社区 / 未验证”，MarkText Plus 不进行人工审核或官方背书。
- **Plugin management:** asynchronously list installed plugins, install local ZIP packages, and discover community plugins from the settings page.

  **插件管理：** 在设置页异步列出已安装插件、安装本地 ZIP 包并发现社区插件。
- **AI settings:** configure OpenAI or Anthropic, endpoint, model, and a secret reference for plugins.

  **AI 配置：** 支持配置 OpenAI 或 Anthropic、API endpoint、model 和供插件使用的密钥引用。

## Reliability

- Plugins run outside the main Flutter isolate. A crash or timed-out request stops the plugin process without blocking the editor.

  插件运行在主 Flutter isolate 之外。插件崩溃或请求超时只会停止插件进程，不会阻塞编辑器。
- Plugin logs are written per plugin and rotated at a bounded size.

  每个插件使用独立日志文件，并在达到大小上限后自动轮转。
- ZIP downloads are checked with HTTPS and SHA-256 before installation.

  ZIP 下载内容在安装前进行 HTTPS 和 SHA-256 校验。
- API keys are kept in the desktop system secret store and are not written to `config.json`.

  API key 保存在桌面系统密钥存储中，不会写入 `config.json`。

## Official plugin repositories

- [Plugin SDK v0.1.0](https://github.com/marktext-plus-plugins/marktext-plus-plugin-sdk/releases/tag/v0.1.0)
- [AI Translate Plugin v0.1.0](https://github.com/marktext-plus-plugins/marktext-plus-ai-translate-plugin/releases/tag/v0.1.0)

## 官方插件仓库

- [插件 SDK v0.1.0](https://github.com/marktext-plus-plugins/marktext-plus-plugin-sdk/releases/tag/v0.1.0)
- [AI 翻译插件 v0.1.0](https://github.com/marktext-plus-plugins/marktext-plus-ai-translate-plugin/releases/tag/v0.1.0)
