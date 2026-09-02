# v1.6.0 插件与 AI 基础设施计划

## 目标

为 MarkText Plus 增加可隔离的插件基础设施、ZIP 安装和受信市场索引、主题扩展能力，以及 OpenAI/Anthropic 配置基础，同时保持启动和大文档性能。

## 阶段

- [complete] Phase 1: 确认架构边界与现有配置/发布流程
- [complete] Phase 2: 应用内插件 manifest、目录、日志、生命周期和协议骨架
- [complete] Phase 3: ZIP 安装与校验、GitHub Topic 异步发现和安装接口
- [complete] Phase 4: AI provider 配置与设置 UI
- [complete] Phase 5: SDK 与 AI 翻译插件本地骨架及仓库文档
- [in_progress] Phase 6: 测试、版本文档、v1.6.0 发布准备
- [complete] Phase 7: GitHub 仓库创建/推送

## 约束

- 插件不加载进主 Dart isolate；插件功能进程通过 JSON-RPC/stdio 通信。
- 启动阶段只读取插件 manifest，不启动插件进程、不下载市场索引。
- 插件日志按插件 ID 分文件并轮转，异常只导致插件失败或熔断。
- 主题插件首版只允许数据型 token，不执行任意 Dart/UI 代码。
- API key 不写入普通 `config.json`；先抽象 secret bridge，系统密钥环接入前不宣称 AI 插件可直接调用。
- 本机不执行完整构建和打包；只执行测试、分析和必要的轻量脚本。
- v1.6.0 完成并通过 CI 后，才执行发布流程；当天是否允许发布由版本日期和严重性规则决定。

## 方案更新

- 插件市场改为无审核 GitHub Topic 发现：公开仓库添加 `marktext-plus-plugin` 即可被搜索，应用标记为 Community/Unverified。
- 专用组织不是前置条件；官方 SDK 和示例插件先放在个人账号仓库。

## 错误记录

| 错误 | 处理 |
|---|---|
| `dart run` 不能导入 Flutter `dart:ui` | README 验证工具改为 Flutter test；本计划中的插件测试也使用 Flutter test 或纯 Dart 独立包分开执行 |
| 当前工作区没有 `gh` CLI | 已使用指定 `/iflytek/workspace/znhu/github/gh_2.93.0_linux_amd64/bin/gh` 完成仓库创建和推送 |
