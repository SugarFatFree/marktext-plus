# MarkText Plus v1.2.1 — 功能需求文档

## 总览

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-001 | 2026-04-30 | 自动检测更新（GitHub Releases） | 高 | 中等 | 已实现 |
| FEAT-002 | 2026-04-30 | 平台原生字体系统 | 高 | 简单 | 已实现 |
| FEAT-003 | 2026-04-30 | PDF/Word 导出样式优化 | 中 | 中等 | 已实现 |
| FEAT-004 | 2026-04-30 | Mermaid 图表导出为图片 | 中 | 困难 | 已实现 |

## 详细需求

### FEAT-001 — 自动检测更新（GitHub Releases）

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-04-30 |
| 优先级 | 高 |
| 难易度 | 中等 |
| 需求描述 | 借助 GitHub Releases API 实现自动检测更新，每天检测一次，有新版本时在状态栏右下角显示醒目提示（不强制弹窗） |
| 用户场景 | 1. 用户日常使用时，无需手动检查是否有新版本<br>2. 有新版本时，用户在状态栏看到提示，点击即可跳转下载页 |
| 当前实现 | 无自动更新检测功能，用户需要手动访问 GitHub 查看 |
| 实现方案 | 1. 添加 `http` 包，调用 `https://api.github.com/repos/marktext-plus/marktext-plus/releases/latest`<br>2. 创建 `UpdateService` 比较语义化版本号，10 秒超时，网络错误静默失败<br>3. 创建 `UpdateNotifier` 管理更新状态<br>4. 在 `HomeScreen.build()` 中触发检测（24 小时内最多一次）<br>5. 状态栏右侧显示更新提示（主题色背景 + 图标 + 版本号），点击打开 GitHub Releases<br>6. `AppConfig` 添加 `lastUpdateCheck` 和 `skipVersion` 字段持久化 |
| 涉及文件 | `pubspec.yaml`<br>`lib/core/constants.dart`<br>`lib/core/config/app_config.dart`<br>`lib/services/update_service.dart`（新增）<br>`lib/providers/update_provider.dart`（新增）<br>`lib/ui/widgets/status_bar.dart`<br>`lib/ui/screens/home_screen.dart`<br>`lib/core/i18n/l10n/app_en.arb`、`app_zh.arb` |
| 验收标准 | 1. 启动应用后，如果 GitHub 有更新版本，状态栏右侧出现蓝色提示<br>2. 点击提示打开 GitHub Releases 页面<br>3. 24 小时内不重复检测<br>4. 网络不可用时不报错，静默失败<br>5. 提示不强制弹窗，不打断用户工作 |

---

### FEAT-002 — 平台原生字体系统

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-04-30 |
| 优先级 | 高 |
| 难易度 | 简单 |
| 需求描述 | 全局使用平台原生字体替代 Flutter 默认的 Roboto，确保中英文混排风格统一，与其他系统软件一致 |
| 用户场景 | 1. 用户打开文件后，字体应和系统其他软件一致<br>2. 中英文混排时不应出现字体风格差异<br>3. 菜单、设置、对话框等 UI 组件字体也应统一 |
| 当前实现 | Flutter 默认 Roboto，预览模式硬编码 Open Sans，中文 fallback 到宋体 |
| 实现方案 | 1. `AppTheme` 添加 `platformFontFallback` getter，按平台返回字体 fallback 链<br>2. `ThemeData` 设置 `fontFamily` + `fontFamilyFallback`，全局生效<br>3. `textTheme` 所有级别带 `fontFamilyFallback`<br>4. 预览模式 `_defaultTextStyle` 和 `_defaultStrutStyle` 也带 fallback<br>5. 移除预览模式的 `Open Sans` 硬编码 |
| 涉及文件 | `lib/core/theme/app_theme.dart`<br>`lib/ui/editor/markdown_renderer.dart` |
| 验收标准 | 1. Windows 上字体为微软雅黑 UI，和系统设置一致<br>2. macOS 上字体为 San Francisco + 苹方<br>3. 中英文混排无风格差异<br>4. 菜单、设置、对话框字体统一<br>5. 日文、韩文、阿拉伯文等多语言正确显示 |

---

### FEAT-003 — PDF/Word 导出样式优化

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-04-30 |
| 优先级 | 中 |
| 难易度 | 中等 |
| 需求描述 | 参考 GitHub Markdown CSS 重新设计 PDF 和 Word 导出样式，使导出文档看起来专业、易读 |
| 用户场景 | 1. 用户导出 PDF 分享给同事，文档应看起来专业<br>2. 用户导出 Word 进一步编辑，格式应合理<br>3. 代码块、表格、引用等元素应有清晰的视觉区分 |
| 当前实现 | PDF：12pt 默认行高，无边框，灰色单调。Word：无页边距，无段落间距，无样式 |
| 实现方案 | **PDF**：添加样式常量，标题递减字号 + H1/H2 底部线，段落 1.5 行高 + 12pt 间距，代码块 `#f6f8fa` 背景 + 边框，表格交替行色 + 表头背景，引用 3pt 左边框 + 斜体<br>**Word**：A4 页面 + 1 inch 页边距，段落 1.5 行距 + 12pt 间距，代码块等宽字体 + 背景色 + 缩进，引用左边框 + 背景色 |
| 涉及文件 | `lib/services/export_service.dart` |
| 验收标准 | 1. PDF 标题有层级感（字号递减 + H1/H2 底部线）<br>2. PDF 段落间距合理，行高 1.5<br>3. PDF 代码块有背景色 + 边框 + 圆角<br>4. PDF 表格有表头背景 + 交替行色 + 边框<br>5. Word 页边距 1 inch<br>6. Word 段落间距 12pt，行距 1.5<br>7. Word 代码块有背景色 + 缩进 |

---

### FEAT-004 — Mermaid 图表导出为图片

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-04-30 |
| 优先级 | 中 |
| 难易度 | 困难 |
| 需求描述 | 导出 PDF/Word 时，Mermaid 代码块应渲染为流程图图片嵌入，而非显示源码 |
| 用户场景 | 1. 用户文档中包含 Mermaid 流程图，导出后应能看到图表<br>2. 导出的文档分享给不使用 Markdown 的人，他们应能看到完整的图表 |
| 当前实现 | Mermaid 代码块在 PDF/Word 中只显示源码文本 |
| 实现方案 | 1. `exportToPdf` 和 `exportToDocx` 添加 `mermaidImages` 参数<br>2. 在菜单栏导出时，先用 `OverlayEntry` + `Positioned(left: -9999)` 将 `MermaidDiagram` 渲染到屏幕外<br>3. 用 `RepaintBoundary.toImage(pixelRatio: 2.0)` 截图为 PNG<br>4. 等待 5 帧 × 200ms 确保 Mermaid 解析和布局完成<br>5. PDF 用 `pw.Image(pw.MemoryImage(bytes))` 嵌入<br>6. Word 用 `DocxImage(bytes: bytes, extension: 'png')` 嵌入<br>7. 渲染失败时回退到源码 + "Mermaid Diagram" 标题 |
| 涉及文件 | `lib/services/export_service.dart`<br>`lib/ui/widgets/app_menu_bar.dart` |
| 验收标准 | 1. 导出 PDF 时，Mermaid 代码块渲染为图片<br>2. 导出 Word 时，Mermaid 代码块渲染为图片<br>3. 图片清晰（2x 像素密度）<br>4. 渲染失败时不崩溃，显示源码作为降级方案<br>5. 支持所有 Mermaid 图表类型（flowchart、sequence、gantt 等） |
| 已知限制 | 1. 渲染需要约 1 秒/图表（等待 Mermaid 解析和布局）<br>2. 图片尺寸固定 800px 宽，可能不适合所有图表<br>3. 导出时有短暂延迟（渲染所有 Mermaid 图表） |
