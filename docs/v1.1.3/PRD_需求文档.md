# MarkText Plus v1.1.3 — 功能需求文档

## 总览

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-001 | 2026-04-28 | 支持 Mermaid 流程图实时渲染 | 高 | 中等 | 已实现 |
| FEAT-002 | 2026-04-28 | 单实例模式与文件打开行为配置 | 高 | 困难 | 待验证 |

## 详细需求

### FEAT-001 — 支持 Mermaid 流程图实时渲染

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-04-28 |
| 优先级 | 高 |
| 难易度 | 中等 |
| 需求描述 | 当前编辑器在预览模式下，Mermaid 代码块（\`\`\`mermaid）只显示源码文本，无法渲染为可视化图表。用户希望能够像其他 Markdown 编辑器一样，实时预览 Mermaid 流程图、时序图、甘特图等图表类型 |
| 用户场景 | 1. 用户编写技术文档，需要插入流程图、架构图<br>2. 用户编写项目计划，需要插入甘特图<br>3. 用户编写 API 文档，需要插入时序图 |
| 当前实现 | `DiagramWidget` 只显示源码 + 语言标签，注释中提到"Mermaid diagrams are rendered in exported HTML via CDN script"，说明导出 HTML 时会渲染，但编辑器预览时不渲染 |
| 实现方案 | 采用方案 A（WebView + mermaid.js）：<br>1. 添加 `webview_all` 1.0.3 依赖，支持 Windows/macOS/Linux 三平台<br>2. 下载 mermaid.js 11.4.0 到 `assets/mermaid/` 作为离线资源<br>3. 创建 `MermaidRenderer` widget，使用 `WebViewController` 加载内联 HTML + mermaid.js CDN<br>4. HTML 模板中实现 `renderMermaid(code, theme)` JS 函数，支持动态更新<br>5. 集成到 `MarkdownRenderer._buildCodeBlock`，替换原有的 `DiagramWidget`<br>6. 升级导出服务 CDN 从 mermaid@10 到 @11 |
| 涉及文件 | `code/pubspec.yaml`<br>`code/assets/mermaid/mermaid.min.js`（新增）<br>`code/lib/ui/widgets/mermaid_renderer.dart`（新增）<br>`code/lib/ui/editor/markdown_renderer.dart`<br>`code/lib/services/export_service.dart` |
| 验收标准 | 1. 预览模式下，\`\`\`mermaid 代码块能正确渲染为图表<br>2. 支持至少 5 种图表类型：flowchart、sequence、gantt、class、state<br>3. 深色/浅色主题切换时，图表主题同步切换<br>4. 语法错误时显示友好的错误提示<br>5. 渲染性能：单个图表渲染时间 < 500ms |
