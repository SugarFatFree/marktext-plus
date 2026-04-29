# V1.2.0 Bug 修复记录

## BUG-001: 预览模式复制粘贴到 Word 格式丢失

**问题描述**：
在预览界面全选-复制-粘贴到 Microsoft Word，所有内容挤到了一行，样式全部丢失。

**根本原因**：
Flutter 的 `SelectionArea` 组件默认只复制纯文本到剪贴板，不包含任何格式信息（HTML/RTF）。当粘贴到 Word 时，Word 只能接收到纯文本，无法识别段落、标题、列表等结构。

**技术分析**：
1. `markdown_renderer.dart` 使用 `SelectionArea` 包裹所有预览内容
2. `SelectionArea` 的默认行为是调用 `Clipboard.setData(ClipboardData(text: selectedText))`
3. 剪贴板数据只包含 `text/plain` MIME 类型，缺少 `text/html` 或 `text/rtf`
4. Word 粘贴时优先使用 HTML 格式，降级到纯文本时会丢失所有格式

**解决方案**：
自定义 `SelectionArea` 的剪贴板处理，将 Markdown AST 转换为 HTML 并同时写入剪贴板：

1. 创建 `HtmlExportService` 将 Markdown AST 转换为 HTML
2. 重写 `SelectionArea` 的 `onSelectionChanged` 回调
3. 使用 `Clipboard.setData` 同时写入 `text/plain` 和 `text/html`

**实现步骤**：
- [ ] 创建 `lib/services/html_export_service.dart`
- [ ] 实现 AST → HTML 转换逻辑
- [ ] 修改 `markdown_renderer.dart` 添加自定义剪贴板处理
- [ ] 测试复制粘贴到 Word/WPS/Google Docs

**影响范围**：
- 文件：`lib/ui/editor/markdown_renderer.dart`, `lib/services/html_export_service.dart`
- 平台：Windows, macOS, Linux
- 用户体验：显著提升，支持富文本粘贴

**验证方法**：
1. 打开包含标题、列表、代码块、表格的 Markdown 文件
2. 切换到预览模式
3. 全选内容（Ctrl+A）
4. 复制（Ctrl+C）
5. 打开 Microsoft Word
6. 粘贴（Ctrl+V）
7. 验证标题、段落、列表、代码块、表格格式是否保留


## BUG-002: PDF 导出中文乱码

**问题描述**：
导出 PDF 时，中文字符显示为乱码或方框。

**根本原因**：
`pdf` 包默认使用 Helvetica 字体，不支持 CJK（中日韩）字符。

**技术分析**：
1. `export_service.dart` 中 `_nodeToPdfWidgets` 方法使用默认字体
2. 默认字体只包含 Latin-1 字符集，无法渲染中文
3. 需要加载系统中文字体（TTF/TTC 格式）

**解决方案**：
从系统字体目录加载中文字体并应用到所有 PDF 文本：

1. 添加 `_loadChineseFont()` 方法，按平台加载系统字体：
   - Windows: msyh.ttc（微软雅黑）、simhei.ttf（黑体）、simsun.ttc（宋体）
   - macOS: PingFang.ttc、STHeiti Light.ttc
   - Linux: NotoSansCJK-Regular.ttc、wqy-microhei.ttc

2. 修改 `exportToPdf()` 方法，加载字体并传递给 `_nodeToPdfWidgets`

3. 修改 `_nodeToPdfWidgets()` 方法，为所有文本节点应用中文字体：
   - 使用 `font` 参数指定主字体
   - 使用 `fontFallback` 参数提供备用字体列表

4. 字体缓存：使用静态变量缓存已加载的字体，避免重复加载

**实现步骤**：
- [x] 添加 `_loadChineseFont()` 方法
- [x] 修改 `exportToPdf()` 加载字体
- [x] 修改 `_nodeToPdfWidgets()` 应用字体到所有节点类型
- [x] 测试 Windows/macOS/Linux 平台字体加载

**影响范围**：
- 文件：`lib/services/export_service.dart`
- 平台：Windows, macOS, Linux
- 用户体验：显著提升，支持中文 PDF 导出

**验证方法**：
1. 打开包含中文的 Markdown 文件
2. 点击菜单 File → Export → PDF
3. 选择保存路径
4. 打开导出的 PDF 文件
5. 验证中文字符是否正确显示

**已知限制**：
- 如果系统没有安装中文字体，导出会失败并抛出异常
- 字体加载可能增加导出时间（首次加载约 100-200ms）
- TTC 字体文件可能包含多个字体，当前只使用第一个

