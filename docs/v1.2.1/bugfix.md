# V1.2.1 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-001 | 2026-04-30 | 预览模式使用 Roboto 字体而非系统默认字体 | P1 | 已修复 |
| BUG-002 | 2026-04-30 | 预览模式选中文字背景高度不一致 | P1 | 已修复 |
| BUG-003 | 2026-04-30 | PDF 代码块中文字符乱码 | P0 | 已修复 |
| BUG-004 | 2026-04-30 | PDF/Word 导出 Mermaid 图表显示为源码 | P1 | 已修复 |
| BUG-005 | 2026-04-30 | PDF/Word 导出样式简陋不专业 | P2 | 已修复 |

---

## BUG-001 — 预览模式使用 Roboto 字体而非系统默认字体

| 字段 | 内容 |
|------|------|
| 日期 | 2026-04-30 |
| 优先级 | P1 |
| 状态 | 已修复 |

### 现象

预览模式的字体和其他软件（原版 MarkText、系统记事本等）明显不同，中英文混排时风格不统一。

### 根因分析

1. Flutter Material 3 默认使用 **Roboto** 字体，不是系统默认字体
2. 预览模式硬编码了 `Open Sans` 字体，系统上未安装时 fallback 到 Helvetica Neue → Arial
3. Roboto 对中文没有覆盖，中文字符 fallback 到宋体，导致中英文字体风格差异大
4. `ThemeData` 没有指定 `fontFamily`，所有 UI 组件（菜单、设置、对话框）都用 Roboto

### 修复方案

1. 在 `AppTheme.getTheme()` 中设置 `fontFamily` 和 `fontFamilyFallback`，按平台使用原生字体：
   - Windows：Microsoft YaHei UI → Malgun Gothic → Yu Gothic UI → Segoe UI → Arial
   - macOS：.AppleSystemUIFont → PingFang SC → Hiragino Sans → Apple SD Gothic Neo → Arial
   - Linux：Noto Sans → Noto Sans CJK SC/JP/KR → Noto Sans Arabic → DejaVu Sans
2. 移除预览模式的 `Open Sans` 硬编码
3. `textTheme` 所有级别都带 `fontFamilyFallback`

### 涉及文件

- `lib/core/theme/app_theme.dart`
- `lib/ui/editor/markdown_renderer.dart`

---

## BUG-002 — 预览模式选中文字背景高度不一致

| 字段 | 内容 |
|------|------|
| 日期 | 2026-04-30 |
| 优先级 | P1 |
| 状态 | 已修复 |

### 现象

在预览模式用鼠标选中文字时，选中背景色有的字高有的字低。例如"编辑器"三个字中，"器"字的背景比另外两个高。

### 根因分析

1. 行内代码使用 `monospace` 字体，和系统默认字体的 ascent/descent 比例不同
2. 不同字符的字形边界框（glyph bounding box）不同，Flutter 按字形边界绘制选中背景
3. 缺少统一的行高约束

### 修复方案

1. 给所有 `Text.rich` 添加 `StrutStyle(forceStrutHeight: true)`，强制统一行高
2. 设置 `TextLeadingDistribution.even`，均匀分配行距到文字上下两侧
3. 行内代码的 `copyWith` 显式保留 `height` 参数

### 涉及文件

- `lib/ui/editor/markdown_renderer.dart`

---

## BUG-003 — PDF 代码块中文字符乱码

| 字段 | 内容 |
|------|------|
| 日期 | 2026-04-30 |
| 优先级 | P0 |
| 状态 | 已修复 |

### 现象

导出 PDF 时，代码块中的中文注释显示为乱码或方框。

### 根因分析

代码块使用 `pw.Font.courier()` 作为主字体，这是 PDF 内置字体，不支持 CJK 字符。虽然设置了 `fontFallback`，但 `font` 参数优先级高于 fallback，Courier 无法渲染的字符直接显示为方框。

### 修复方案

将代码块的 `font` 改为 `primaryFont`（系统字体），`Courier` 放到 `fontFallback` 链中。这样中文字符用系统字体渲染，英文/代码字符优先用 Courier。

### 涉及文件

- `lib/services/export_service.dart`

---

## BUG-004 — PDF/Word 导出 Mermaid 图表显示为源码

| 字段 | 内容 |
|------|------|
| 日期 | 2026-04-30 |
| 优先级 | P1 |
| 状态 | 已修复 |

### 现象

导出 PDF 和 Word 时，Mermaid 代码块只显示源码文本，没有渲染为流程图。

### 根因分析

1. `_nodeToPdfWidgets` 和 `_addNodeToDocx` 中，`CodeBlockNode` 没有区分 Mermaid 和普通代码
2. Mermaid 渲染器是 Flutter widget（`MermaidDiagram`），需要在 UI 上下文中才能渲染
3. `ExportService` 是纯 Dart 代码，无法直接使用 widget

### 修复方案

1. `exportToPdf` 和 `exportToDocx` 添加 `mermaidImages` 参数（`Map<String, Uint8List>`）
2. 在菜单栏导出时，先用 `OverlayEntry` + `Positioned(left: -9999)` 将 `MermaidDiagram` 渲染到屏幕外
3. 用 `RepaintBoundary.toImage()` 截图为 PNG
4. 将图片传递给导出服务，嵌入 PDF（`pw.Image`）或 Word（`DocxImage`）
5. 如果渲染失败，回退到显示源码 + "Mermaid Diagram" 标题

### 涉及文件

- `lib/services/export_service.dart`
- `lib/ui/widgets/app_menu_bar.dart`

---

## BUG-005 — PDF/Word 导出样式简陋不专业

| 字段 | 内容 |
|------|------|
| 日期 | 2026-04-30 |
| 优先级 | P2 |
| 状态 | 已修复 |

### 现象

导出的 PDF 和 Word 文档样式"太丑了"——文本拥挤、视觉层级弱、代码块不专业、表格简陋。

### 根因分析

1. PDF：12pt 字体 + 默认 1.0 行高，标题只靠字号区分，代码块 10pt 太小，表格无样式
2. Word：无页边距、无段落间距、无行距、代码块无背景色、表格无格式

### 修复方案

参考 GitHub Markdown CSS 重新设计导出样式：

**PDF**：
- 标题：H1 24pt → H6 12pt，H1/H2 有底部分隔线，上方 16pt 下方 8pt 间距
- 段落：12pt，1.5 行高，12pt 段后间距
- 代码块：11pt，`#f6f8fa` 背景 + `#e1e4e8` 边框 + 4pt 圆角 + 12pt 内边距
- 引用：3pt `#dfe2e5` 左边框 + `#f9f9f9` 背景 + 斜体灰色文字
- 表格：表头背景 + 交替行色 + 1pt 边框 + 8pt 单元格内边距

**Word**：
- 页面：A4，1 inch 页边距
- 段落：12pt 段后间距，1.5 倍行距
- 代码块：Courier New 10pt + `#f6f8fa` 背景 + 左右缩进
- 引用：0.5 inch 左缩进 + 左边框 + 背景色 + 斜体灰色文字

### 涉及文件

- `lib/services/export_service.dart`
