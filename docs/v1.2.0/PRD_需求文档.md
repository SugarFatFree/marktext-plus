# MarkText Plus v1.2.0 — 功能需求文档

## 总览

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-001 | 2026-04-30 | 预览模式富文本复制（HTML 剪贴板） | 高 | 困难 | 已实现 |
| FEAT-002 | 2026-04-30 | 导出为 Word (.docx) | 高 | 中等 | 已实现 |

## 详细需求

### FEAT-001 — 预览模式富文本复制（HTML 剪贴板）

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-04-30 |
| 优先级 | 高 |
| 难易度 | 困难 |
| 需求描述 | 用户在预览模式下全选内容并复制后，粘贴到 Word/WPS/Outlook 等应用时，应保留标题、段落、列表、表格、代码块等格式，而非纯文本 |
| 用户场景 | 1. 用户编写技术文档后，需要将内容粘贴到 Word 中进一步编辑<br>2. 用户编写邮件内容后，需要粘贴到 Outlook 中发送<br>3. 用户需要将 Markdown 内容快速转移到其他富文本编辑器 |
| 当前实现 | Flutter `SelectionArea` 默认只复制纯文本到剪贴板，Word 粘贴时丢失所有格式 |
| 实现方案 | 1. 创建 `ClipboardService`，通过 Windows FFI 调用 `user32.dll`/`kernel32.dll`，同时写入 `CF_UNICODETEXT` 和 `HTML Format` 到系统剪贴板<br>2. HTML Format 使用 UTF-8 编码，偏移量按字节计算（符合 Windows CF_HTML 规范）<br>3. 在 `MarkdownRenderer` 中用 `Focus.onKeyEvent` 监听 Ctrl+C/Cmd+C，延迟 50ms 后覆盖剪贴板<br>4. 复用 `ExportService.nodeToHtml()` 将 Markdown AST 转换为 HTML<br>5. 非 Windows 平台降级为纯文本（macOS/Linux 后续可扩展） |
| 涉及文件 | `lib/services/clipboard_service.dart`（新增）<br>`lib/ui/editor/markdown_renderer.dart`<br>`lib/services/export_service.dart`（`nodeToHtml` 改为 public） |
| 验收标准 | 1. 预览模式下 Ctrl+A → Ctrl+C → 粘贴到 Word，标题/段落/列表/表格/代码块格式保留<br>2. 无需点击额外按钮，Ctrl+C 自动写入 HTML 格式<br>3. 不影响源码模式和分屏模式的正常复制行为<br>4. 非 Windows 平台降级为纯文本，不报错 |

---

### FEAT-002 — 导出为 Word (.docx)

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-04-30 |
| 优先级 | 高 |
| 难易度 | 中等 |
| 需求描述 | 在现有 HTML/PDF 导出基础上，新增导出为 Word (.docx) 格式的功能，将 Markdown 内容转换为可编辑的 Word 文档 |
| 用户场景 | 1. 用户编写技术文档后，需要提交 Word 格式给不使用 Markdown 的同事<br>2. 用户编写报告后，需要在 Word 中进一步排版和打印<br>3. 用户需要将 Markdown 笔记转换为正式文档格式 |
| 当前实现 | 仅支持导出 HTML 和 PDF，不支持 Word 格式 |
| 实现方案 | 1. 添加 `docx_creator` 包（v1.2.3）作为依赖<br>2. 在 `ExportService` 中添加 `exportToDocx()` 方法，复用现有 Markdown AST 遍历模式<br>3. 使用 `DocxDocumentBuilder` 流畅 API 构建文档：`docx().h1().p().bullet().table().build()`<br>4. 在菜单栏 File → Export 子菜单中添加 "Word (.docx)" 选项<br>5. 添加 12 种语言的国际化字符串 `fileExportWord` |
| 涉及文件 | `pubspec.yaml`（添加 `docx_creator` 依赖）<br>`lib/services/export_service.dart`（添加 `exportToDocx`、`_addNodeToDocx`、`_inlineSpansToDocxTexts`）<br>`lib/ui/widgets/app_menu_bar.dart`（添加菜单项和 `_exportWord` 处理器）<br>`lib/core/i18n/l10n/app_*.arb`（12 个语言文件添加 `fileExportWord`） |
| 验收标准 | 1. File → Export → Word (.docx) 菜单项可用<br>2. 导出的 .docx 文件可在 Word/WPS/LibreOffice 中正常打开<br>3. 标题层级（H1-H6）正确映射为 Word 标题样式<br>4. 粗体、斜体、下划线、删除线、行内代码等内联格式正确<br>5. 有序/无序列表格式正确<br>6. 表格结构完整（表头+数据行）<br>7. 代码块使用等宽字体<br>8. 引用块有缩进样式<br>9. 链接保留 href 属性<br>10. 任务列表转换为 Unicode 复选框文本（☑/☐） |
| 支持的格式 | 标题、段落、粗体、斜体、下划线、删除线、行内代码、链接、上标、下标、有序列表、无序列表、任务列表、引用、水平线、代码块、表格 |
| 已知限制 | 1. 嵌套列表暂不支持<br>2. 图片嵌入暂不支持<br>3. 数学公式降级为代码块<br>4. Mermaid 图表降级为代码块<br>5. HTML 块降级为纯文本段落 |
