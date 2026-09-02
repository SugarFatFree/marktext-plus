# v1.6.0 外部仓库规划

## 插件 SDK

建议仓库：`marktext-plus/marktext-plus-plugin-sdk`

首版内容：

- `manifest.json` schema
- JSON-RPC/stdio 协议说明
- TypeScript、Python 和 Dart 客户端示例
- 主题 token schema
- 插件日志和超时处理示例
- ZIP 打包与 SHA-256 发布流程

## AI 翻译插件

建议仓库：`marktext-plus/marktext-plus-ai-translate-plugin`

首版内容：

- 读取 MarkText Plus 的 provider、endpoint、model 和 secret reference
- 通过主应用 secret bridge 获取 API key，不读取 `config.json` 中的明文密钥
- 支持 OpenAI 和 Anthropic 的 provider-neutral 翻译请求
- 以 JSON-RPC/stdio 返回翻译结果
- 对超时、限流、无效响应和取消操作写入独立插件日志

## 仓库创建状态

当前工作区没有 GitHub CLI，也没有 GitHub API 写权限；只能完成本地应用代码和协议文档，不能安全地替用户创建远程仓库或推送代码。仓库名和 registry 约定已固定，获得授权后按文档直接创建即可。
