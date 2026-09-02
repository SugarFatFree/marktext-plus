# v1.6.0 外部仓库规划

## 插件 SDK

建议仓库：`marktext-plus-plugins/marktext-plus-plugin-sdk`

首版内容：

- `manifest.json` schema
- JSON-RPC/stdio 协议说明
- TypeScript、Python 和 Dart 客户端示例
- 主题 token schema
- 插件日志和超时处理示例
- ZIP 打包与 SHA-256 发布流程

## AI 翻译插件

建议仓库：`marktext-plus-plugins/marktext-plus-ai-translate-plugin`

首版内容：

- 读取 MarkText Plus 的 provider、endpoint、model 和 secret reference
- 通过主应用 secret bridge 获取 API key，不读取 `config.json` 中的明文密钥
- 支持 OpenAI 和 Anthropic 的 provider-neutral 翻译请求
- 以 JSON-RPC/stdio 返回翻译结果
- 对超时、限流、无效响应和取消操作写入独立插件日志

## 仓库创建状态

两个仓库已创建并推送到 `SugarFatFree` 账号：

- https://github.com/marktext-plus-plugins/marktext-plus-plugin-sdk (v0.1.0)
- https://github.com/marktext-plus-plugins/marktext-plus-ai-translate-plugin (v0.1.0)

两个仓库均已添加 Topic `marktext-plus-plugin`。当前不要求创建 Organization；第三方开发者可以在自己的公开仓库添加同一 Topic，由应用自动发现并标记为 Community/Unverified。
