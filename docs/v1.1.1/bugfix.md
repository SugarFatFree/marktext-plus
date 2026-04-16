# MarkText Plus v1.1.1 — Bug 修复记录

## 总览

| 编号 | 日期 | 标题 | 紧急程度 | 优先级 | 难易度 | 状态 |
|------|------|------|----------|--------|--------|------|
| BUG-001 | 2026-04-16 | 快捷键失灵（Ctrl+F/H 等） | P1-严重 | 高 | 中等 | 已修复 |
| BUG-002 | 2026-04-16 | 深色模式显示混乱 | P1-严重 | 高 | 中等 | 已修复 |
| BUG-003 | 2026-04-16 | UI 高度过高（菜单栏、二级菜单、右键菜单） | P2-一般 | 中 | 简单 | 已修复 |
| BUG-004 | 2026-04-16 | 预览模式表格溢出 | P2-一般 | 中 | 简单 | 已修复 |
| BUG-005 | 2026-04-16 | 隐藏侧边栏后正文宽度不变 | P2-一般 | 中 | 简单 | 已修复 |
| BUG-006 | 2026-04-16 | 预览模式字体异常 | P2-一般 | 中 | 简单 | 已修复 |
| BUG-007 | 2026-04-16 | 源代码视图行尾双击选区高亮溢出 | P2-一般 | 中 | 中等 | 已修复 |

## 详细记录

### BUG-001 — 快捷键失灵（Ctrl+F/H 等）

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-16 |
| 修复日期 | 2026-04-16 |
| 紧急程度 | P1-严重 |
| 优先级 | 高 |
| 难易度 | 中等 |
| 现象 | 查找（Ctrl+F）、替换（Ctrl+H）等快捷键不工作 |
| 根因 | Flutter 的 `MenuBar` 快捷键系统要求焦点在 MenuBar 的 widget 子树内才能触发。当用户在编辑器的 `TextField` 中输入时，焦点不在 MenuBar 内，导致快捷键无法响应 |
| 修复方案 | 在 `home_screen.dart` 的顶层 `Focus` widget 的 `onKeyEvent` 中添加 Ctrl+F 和 Ctrl+H 的显式处理，直接调用 `editorProvider.notifier.toggleFindReplace()` |
| 涉及文件 | `ui/screens/home_screen.dart` |

### BUG-002 — 深色模式显示混乱

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-16 |
| 修复日期 | 2026-04-16 |
| 紧急程度 | P1-严重 |
| 优先级 | 高 |
| 难易度 | 中等 |
| 现象 | 选择白色主题后开启深色模式，显示混乱（部分区域仍为白色） |
| 根因 | `app.dart` 的主题配置逻辑有缺陷：`theme` 使用用户选择的主题（如 shibuya 浅色），`darkTheme` 硬编码为 darkGraphite，`themeMode` 根据 `config.darkMode` 切换。当用户选择浅色主题 + 开启深色模式时，Flutter 使用 `darkTheme`（darkGraphite），但某些组件仍通过 `AppTheme.getTokens(config.themeName)` 引用 shibuya 的 tokens，导致颜色混乱 |
| 修复方案 | 移除独立的 `darkMode` 开关，将 5 个主题分为浅色组（redGraphite, shibuya）和深色组（darkGraphite, dieciOLED, nord），根据选择的主题自动设置 `themeMode`。移除 `app.dart` 的 `darkTheme` 参数，简化为单一主题逻辑。设置页面改为分组显示浅色/深色主题 |
| 涉及文件 | `core/config/app_config.dart`, `providers/settings_provider.dart`, `app.dart`, `ui/screens/settings_screen.dart`, `core/theme/app_theme.dart` |

### BUG-003 — UI 高度过高（菜单栏、二级菜单、右键菜单）

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-16 |
| 修复日期 | 2026-04-16 |
| 紧急程度 | P2-一般 |
| 优先级 | 中 |
| 难易度 | 简单 |
| 现象 | 顶部菜单栏、二级菜单（MenuItemButton）、标签页右键菜单（PopupMenuItem）占用高度过高 |
| 根因 | Material 3 默认的 `MenuItemButton` 和 `PopupMenuItem` 高度约为 48px，对于桌面编辑器来说过高 |
| 修复方案 | 在 `app_theme.dart` 的 `menuButtonTheme` 中添加 `minimumSize: WidgetStatePropertyAll(Size(0, 36))` 和 `padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 8))`；在 `editor_tab_bar.dart` 的所有 `PopupMenuItem` 中添加 `height: 36` |
| 涉及文件 | `core/theme/app_theme.dart`, `ui/widgets/editor_tab_bar.dart` |

### BUG-004 — 预览模式表格溢出

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-16 |
| 修复日期 | 2026-04-16 |
| 紧急程度 | P2-一般 |
| 优先级 | 中 |
| 难易度 | 简单 |
| 现象 | 预览模式下，表格内容过长时溢出容器边界，导致布局错乱 |
| 根因 | `_buildTable()` 使用 `IntrinsicColumnWidth()` 作为列宽策略，当表格内容超出容器宽度时没有滚动机制，导致溢出 |
| 修复方案 | 将 `Table` 包裹在 `SingleChildScrollView(scrollDirection: Axis.horizontal)` 中，并添加 `ConstrainedBox(minWidth: 200)` 确保最小宽度，超宽表格可水平滚动 |
| 涉及文件 | `ui/editor/markdown_renderer.dart` |

### BUG-005 — 隐藏侧边栏后正文宽度不变

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-16 |
| 修复日期 | 2026-04-16 |
| 紧急程度 | P2-一般 |
| 优先级 | 中 |
| 难易度 | 简单 |
| 现象 | 隐藏侧边栏后，预览区域正文宽度不变，仅增大了两侧边距 |
| 根因 | `markdown_renderer.dart` 的 `build()` 方法中 `ConstrainedBox` 使用硬编码 `maxWidth: 680`，未使用 `AppConfig.editorMaxWidth` 配置值 |
| 修复方案 | 将 `const BoxConstraints(maxWidth: 680)` 改为 `BoxConstraints(maxWidth: config.editorMaxWidth.toDouble())`，使用 `ref.watch(settingsProvider)` 获取配置值（默认 800） |
| 涉及文件 | `ui/editor/markdown_renderer.dart` |

### BUG-006 — 预览模式字体异常

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-16 |
| 修复日期 | 2026-04-16 |
| 紧急程度 | P2-一般 |
| 优先级 | 中 |
| 难易度 | 简单 |
| 现象 | 预览模式正文使用 Flutter 默认系统字体，阅读体验差 |
| 根因 | `_buildParagraph()`、`_buildHeading()`、`_buildBlockquote()` 等方法的 `TextStyle` 未指定 `fontFamily`，使用了 Flutter 默认字体 |
| 修复方案 | 参考原版 MarkText 项目字体配置，添加 `static const _previewFontFamily = 'Open Sans, Helvetica Neue, Arial, sans-serif'`，应用到段落（16px, 1.6行高）、标题、引用块、表格文本。字号从 17px 调整为 16px，行高从 1.7 调整为 1.6，与原版一致 |
| 涉及文件 | `ui/editor/markdown_renderer.dart` |

### BUG-007 — 源代码视图行尾双击选区高亮溢出

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-16 |
| 修复日期 | 2026-04-16 |
| 紧急程度 | P2-一般 |
| 优先级 | 中 |
| 难易度 | 中等 |
| 现象 | 源代码视图中双击选中行尾单词（如 `Linux`）时，粉色选区高亮条从单词一直延伸到该行后的大片空白区域 |
| 根因 | `syntax_highlighter.dart` 的 `highlight()` 方法将每个 `\n` 换行符作为独立的无样式 `TextSpan(text: '\n')` 输出。当 Flutter 的 `EditableText` / `RenderEditable` 绘制选区时，行尾有样式的 TextSpan 与紧随其后的无样式 `\n` TextSpan 之间的样式边界导致选区矩形计算异常，使高亮延伸到行尾空白区域 |
| 修复方案 | 重写 `highlight()` 方法，改用 `text.split('\n')` 按行处理，将 `\n` 附加到每行最后一个 TextSpan 的末尾（共享同一 TextStyle），而非作为独立 span。空行的 `\n` 也赋予 `defaultColor` 样式。在 `highlighting_controller.dart` 的 `buildTextSpan()` 中增加 span 文本总长度校验，不匹配时回退为单一 TextSpan 防止异常 |
| 涉及文件 | `ui/editor/syntax_highlighter.dart`, `ui/editor/highlighting_controller.dart` |
