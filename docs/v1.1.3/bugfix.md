# MarkText Plus v1.1.3 — Bug 修复记录

## 总览

| 编号 | 日期 | 标题 | 紧急程度 | 优先级 | 难易度 | 状态 |
|------|------|------|----------|--------|--------|------|
| BUG-001 | 2026-04-28 | Windows 换行符 \r\n 导致 Markdown 语法不渲染 | P1-紧急 | 高 | 中等 | 已修复 |
| BUG-002 | 2026-04-28 | 表格单元格内的 Markdown 内联语法不渲染 | P2-一般 | 中 | 简单 | 已修复 |

## 详细记录

### BUG-001 — Windows 换行符 \r\n 导致 Markdown 语法不渲染

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-28 |
| 修复日期 | 2026-04-28 |
| 紧急程度 | P1-紧急 |
| 优先级 | 高 |
| 难易度 | 中等 |
| 现象 | 将大段文本从外部复制粘贴到编辑器后，`#` 标题、代码块、列表、引用等 Markdown 语法均不渲染；源码视图中可见换行符为 `\r\n`；手动将 `\r\n` 替换为 `\n` 后恢复正常 |
| 根因 | 整个代码库的文本处理均假设换行符为 `\n`：1) `MarkdownParser.parse()` 使用 `markdown.split('\n')` 分割行，导致 `\r` 残留在每行末尾；2) 所有 14 个 Markdown 语法正则（标题、代码块、列表、引用、表格、分隔线等）使用 `$` 锚点匹配行尾，但 `$` 无法匹配 `\r` 之前的位置，导致所有语法检测失败；3) `SyntaxHighlighter` 同样使用 `split('\n')` 和 `startsWith` 检测，源码高亮也受影响；4) 侧边栏 TOC 面板的标题提取使用相同的正则，目录也无法生成；5) `FileService.readFile()` 和编辑器均未对输入文本做换行符归一化 |
| 修复方案 | 在文本进入编辑器的两个入口统一归一化换行符：1) `FileService.readFile()` 读取文件后执行 `replaceAll('\r\n', '\n').replaceAll('\r', '\n')`；2) `HighlightingController` 重写构造函数、`set text` 和 `set value`，对所有进入编辑器的文本（包括粘贴、拖拽、程序赋值）统一归一化，同时修正光标偏移量以避免光标跳位 |
| 涉及文件 | `services/file_service.dart`、`ui/editor/highlighting_controller.dart` |

### BUG-002 — 表格单元格内的 Markdown 内联语法不渲染

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-28 |
| 修复日期 | 2026-04-28 |
| 紧急程度 | P2-一般 |
| 优先级 | 中 |
| 难易度 | 简单 |
| 现象 | 预览模式下，表格单元格中的 Markdown 内联语法（加粗 `**text**`、链接 `[text](url)`、斜体、代码等）不渲染，直接显示原始 Markdown 源码 |
| 根因 | `_buildTable` 方法中表头和数据行均使用纯 `Text` widget 直接显示原始字符串，未调用 `parseInline` + `_buildInlineSpans` 解析内联语法 |
| 修复方案 | 将表头和数据行的 `Text` 替换为 `Text.rich(_buildInlineSpans(...))`，通过 `_inlineParser.parseInline()` 先解析单元格文本为 `InlineSpan` 列表，再由 `_buildInlineSpans` 渲染为富文本 |
| 涉及文件 | `ui/editor/markdown_renderer.dart` |
