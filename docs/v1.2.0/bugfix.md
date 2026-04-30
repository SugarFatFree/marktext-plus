# V1.2.0 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-001 | 2026-04-30 | 预览模式复制粘贴到 Word 格式丢失 | P0 | 已修复 |
| BUG-002 | 2026-04-30 | PDF 导出多语言字符乱码 | P0 | 已修复 |
| BUG-003 | 2026-04-30 | PDF 导出 TTC 字体解析崩溃 | P0 | 已修复 |
| BUG-004 | 2026-04-30 | PDF 导出 Emoji 显示为方框 | P1 | 已修复 |
| BUG-005 | 2026-04-30 | 预览模式渲染性能退化 | P1 | 已修复 |

---

## BUG-001 — 预览模式复制粘贴到 Word 格式丢失

| 字段 | 内容 |
|------|------|
| 日期 | 2026-04-30 |
| 优先级 | P0 |
| 状态 | 已修复 |

### 现象

在预览界面全选（Ctrl+A）→ 复制（Ctrl+C）→ 粘贴到 Microsoft Word，所有内容挤到一行，样式全部丢失。

### 根因分析

Flutter 的 `SelectionArea` 组件默认只复制纯文本到剪贴板（`text/plain`），不包含 HTML 格式。Word 粘贴时优先使用 HTML 格式，降级到纯文本时丢失所有段落和格式信息。

### 修复方案

1. 创建 `ClipboardService`（`lib/services/clipboard_service.dart`），通过 Windows FFI 调用 `user32.dll` 和 `kernel32.dll`，同时写入 `CF_UNICODETEXT`（纯文本）和 `HTML Format`（HTML 格式）到系统剪贴板
2. HTML Format 使用 UTF-8 编码，偏移量按字节计算（符合 Windows 规范）
3. 在 `MarkdownRenderer` 中用 `Focus.onKeyEvent` 监听 Ctrl+C，延迟 50ms 后用 `ClipboardService.copyWithHtml` 覆盖剪贴板
4. 非 Windows 平台降级为纯文本

### 涉及文件

- `lib/services/clipboard_service.dart`（新增）
- `lib/ui/editor/markdown_renderer.dart`
- `lib/services/export_service.dart`（`nodeToHtml` 改为 public）

---

## BUG-002 — PDF 导出多语言字符乱码

| 字段 | 内容 |
|------|------|
| 日期 | 2026-04-30 |
| 优先级 | P0 |
| 状态 | 已修复 |

### 现象

导出 PDF 时，中文、日文、韩文、俄文、阿拉伯语等非 Latin 字符显示为乱码或方框。

### 根因分析

`pdf` 包默认使用 Helvetica 字体，只包含 Latin-1 字符集，无法渲染 CJK、西里尔、阿拉伯等字符。

### 修复方案

添加 `_loadSystemFonts()` 方法，按平台加载系统 TTF 字体作为 fallback 链：
- Windows: simhei.ttf（CJK）、malgun.ttf（韩文）、arial.ttf（西里尔/阿拉伯）、tahoma.ttf
- macOS: Arial Unicode.ttf、Osaka.ttf
- Linux: NotoSans-Regular.ttf、DejaVuSans.ttf

所有 PDF 文本节点通过 `font` + `fontFallback` 参数应用多语言字体。

### 涉及文件

- `lib/services/export_service.dart`

---

## BUG-003 — PDF 导出 TTC 字体解析崩溃

| 字段 | 内容 |
|------|------|
| 日期 | 2026-04-30 |
| 优先级 | P0 |
| 状态 | 已修复 |

### 现象

导出 PDF 时报错：`FormatException: Unexpected extension byte (at offset 2)`，堆栈指向 `TtfParser` 构造函数。

### 根因分析

1. `.ttc`（TrueType Collection）文件包含多个字体集合，`pdf` 包的 `Font.ttf()` 只能解析单个 TTF 格式
2. `Font.ttf()` 构造函数只存储 ByteData，不立即解析。实际解析在 PDF 生成时（`pdf.save()`）才触发，导致 try-catch 无法在加载阶段捕获错误
3. TTC 文件的内部偏移是绝对地址，无法通过子视图提取单个字体

### 修复方案

1. 移除所有 `.ttc` 文件，只使用 `.ttf` 文件
2. 在 `exportToPdf` 中添加 try-catch 兜底：如果字体导致崩溃，自动回退到无自定义字体模式重试

### 涉及文件

- `lib/services/export_service.dart`

---

## BUG-004 — PDF 导出 Emoji 显示为方框

| 字段 | 内容 |
|------|------|
| 日期 | 2026-04-30 |
| 优先级 | P1 |
| 状态 | 已修复 |

### 现象

导出 PDF 后，Emoji 字符（✅、❌ 等）显示为空白或方框。

### 根因分析

常规字体（simhei.ttf、arial.ttf）不包含 Emoji 字形。`pdf` 包不支持彩色 Emoji 字体。

### 修复方案

双重策略：
1. 在字体 fallback 链末尾添加 Emoji 字体：Windows `seguiemj.ttf`（Segoe UI Emoji）
2. 添加 `_normalizeForPdf()` 方法，将常见 Emoji 映射为 Unicode 符号（✅→☑、❌→✗、✔️→✔、❤️→♥），作为字体不支持时的兜底

### 涉及文件

- `lib/services/export_service.dart`

---

## BUG-005 — 预览模式渲染性能退化

| 字段 | 内容 |
|------|------|
| 日期 | 2026-04-30 |
| 优先级 | P1 |
| 状态 | 已修复 |

### 现象

用户反馈打开文件速度对比上个版本变慢。

### 根因分析

1. `MarkdownRenderer.build()` 每次 rebuild 都创建新的 `MarkdownParser` 并重新解析整个 markdown，搜索高亮、光标移动等触发的 rebuild 都会重复解析
2. `_markdownToHtml()` 每次 Ctrl+C 都重新解析+转换
3. `_loadSystemFonts()` 对每个字体都生成完整 PDF 来验证（`testDoc.save()`），6 个字体 = 6 次 PDF 生成

### 修复方案

1. AST 缓存：添加 `_cachedMarkdown`、`_cachedNodes`、`_cachedHeadingLines` 字段，只在 `widget.markdown` 内容变化时重新解析
2. HTML 缓存：添加 `_cachedHtml` 字段，内容不变时直接返回缓存
3. 移除字体预验证：删除 `testDoc.save()` 步骤，改为 `exportToPdf` 中 try-catch 兜底

### 涉及文件

- `lib/ui/editor/markdown_renderer.dart`
- `lib/services/export_service.dart`
