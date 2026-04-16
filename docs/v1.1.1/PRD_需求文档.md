# MarkText Plus - 产品需求文档 (PRD)

**版本号**: V1.1.1  
**文档日期**: 2026-04-16  
**项目类型**: Flutter 桌面应用  
**更新类型**: Bug 修复版本

---

## 1. 版本概述

### 1.1 版本背景
V1.1.1 是 V1.0.1 的 Bug 修复版本，主要解决用户反馈的 3 个关键问题：快捷键失灵、深色模式显示混乱、UI 高度过高。

### 1.2 版本目标
- 修复快捷键系统，确保 Ctrl+F、Ctrl+H 等核心快捷键正常工作
- 重构主题系统，消除深色模式与主题选择的冲突
- 优化 UI 高度，提升桌面端的紧凑性和空间利用率
- 统一应用标题为 "MarkText Plus"，去除调试标识

### 1.3 影响范围
- 快捷键系统
- 主题配置系统
- UI 布局（菜单栏、右键菜单）
- 应用标题显示

---

## 2. 核心需求

### 2.1 快捷键修复 (P1)

#### 需求描述
用户反馈查找（Ctrl+F）、替换（Ctrl+H）等快捷键不工作，影响编辑效率。

#### 技术原因
Flutter 的 `MenuBar` 快捷键系统要求焦点在 MenuBar 的 widget 子树内才能触发。当用户在编辑器的 `TextField` 中输入时，焦点不在 MenuBar 内，导致快捷键无法响应。

#### 解决方案
在 `home_screen.dart` 的顶层 `Focus` widget 的 `onKeyEvent` 中添加关键快捷键的显式处理：
- Ctrl+F：触发查找/替换面板
- Ctrl+H：触发查找/替换面板
- 保持与 MenuBar 快捷键的一致性

#### 验收标准
- Ctrl+F 和 Ctrl+H 在编辑器获得焦点时正常工作
- 其他快捷键（Ctrl+N、Ctrl+S、Ctrl+P 等）正常工作
- 快捷键不与编辑器输入冲突

---

### 2.2 主题系统重构 (P1)

#### 需求描述
用户反馈选择白色主题后开启深色模式，显示混乱（部分区域仍为白色）。

#### 技术原因
当前设计存在逻辑缺陷：
- `app.dart` 中 `theme` 使用用户选择的主题（如 shibuya 浅色）
- `darkTheme` 硬编码为 darkGraphite
- `themeMode` 根据 `config.darkMode` 切换
- 当用户选择浅色主题 + 开启深色模式时，Flutter 使用 `darkTheme`（darkGraphite），但某些组件仍通过 `AppTheme.getTokens(config.themeName)` 引用 shibuya 的 tokens，导致颜色混乱

#### 解决方案
1. 移除 `AppConfig` 中的 `darkMode` 字段
2. 将 5 个主题分为两组：
   - 浅色主题：`redGraphite`, `shibuya`
   - 深色主题：`darkGraphite`, `dieciOLED`, `nord`
3. 根据选择的主题自动设置 `themeMode`（通过 `tokens.brightness` 判断）
4. 移除 `app.dart` 的 `darkTheme` 参数
5. 设置页面改为分组显示浅色/深色主题

#### 验收标准
- 选择任意主题后，所有 UI 元素颜色一致
- 主题切换后配置持久化
- 设置页面清晰展示浅色/深色主题分组

---

### 2.3 UI 高度优化 (P2)

#### 需求描述
用户反馈顶部菜单栏、二级菜单、标签页右键菜单占用高度过高，影响内容区域的可用空间。

#### 技术原因
Material 3 默认的 `MenuItemButton` 和 `PopupMenuItem` 高度约为 48px，对于桌面编辑器来说过高。

#### 解决方案
1. 在 `app_theme.dart` 的 `menuButtonTheme` 中添加：
   - `minimumSize: WidgetStatePropertyAll(Size(0, 36))`
   - `padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 8))`
2. 在 `editor_tab_bar.dart` 的所有 `PopupMenuItem` 中添加 `height: 36`
3. 保持标签页高度 44px（已经合理）

#### 验收标准
- 菜单项高度从 ~48px 减少到 36px
- 右键菜单项高度统一为 36px
- UI 更紧凑，不影响可读性和点击精度

---

### 2.4 应用标题统一 (P3)

#### 需求描述
统一应用标题为 "MarkText Plus"（带空格），去除 Debug 模式下的右上角标识。

#### 解决方案
1. `app.dart` 的 `title` 改为 "MarkText Plus"
2. `constants.dart` 的 `appName` 改为 "MarkText Plus"
3. `app_menu_bar.dart` 的 `applicationName` 改为 "MarkText Plus"
4. 所有 ARB 文件的 `appTitle` 改为 "MarkText Plus"
5. `app.dart` 添加 `debugShowCheckedModeBanner: false`

#### 验收标准
- 窗口标题显示 "MarkText Plus"
- About 对话框显示 "MarkText Plus"
- Debug 模式下无右上角 Debug 标识

---

### 2.5 预览模式表格溢出修复 (P2)

#### 需求描述
预览模式下，表格内容过长时溢出容器边界，导致布局错乱。

#### 技术原因
`_buildTable()` 使用 `IntrinsicColumnWidth()` 作为列宽策略，当表格内容超出容器宽度时没有滚动机制，导致溢出。

#### 解决方案
将 `Table` 包裹在 `SingleChildScrollView(scrollDirection: Axis.horizontal)` 中，并添加 `ConstrainedBox(minWidth: 200)` 确保最小宽度，超宽表格可水平滚动。

#### 验收标准
- 长内容表格可水平滚动
- 短内容表格正常显示
- 表格保持圆角边框和分割线

---

### 2.6 预览内容宽度自适应 (P2)

#### 需求描述
隐藏侧边栏后，预览区域正文宽度不变，仅增大两侧边距，浪费屏幕空间。

#### 技术原因
`markdown_renderer.dart` 的 `ConstrainedBox` 使用硬编码 `maxWidth: 680`，未使用 `AppConfig.editorMaxWidth` 配置值。

#### 解决方案
将硬编码 `const BoxConstraints(maxWidth: 680)` 替换为 `BoxConstraints(maxWidth: config.editorMaxWidth.toDouble())`，通过 `ref.watch(settingsProvider)` 读取用户配置（默认 800）。

#### 验收标准
- 预览内容宽度使用 `editorMaxWidth` 配置值
- 隐藏侧边栏后内容区域宽度增加
- 用户可在设置中调整最大宽度

---

### 2.7 预览模式字体优化 (P2)

#### 需求描述
预览模式正文使用 Flutter 默认系统字体，阅读体验差，与原版 MarkText 差距较大。

#### 技术原因
`_buildParagraph()`、`_buildHeading()`、`_buildBlockquote()` 等方法的 `TextStyle` 未指定 `fontFamily`，使用了 Flutter 默认字体。

#### 解决方案
参考原版 MarkText 项目字体配置（`Open Sans, Clear Sans, Helvetica Neue, Helvetica, Arial, sans-serif`），添加预览字体常量 `_previewFontFamily = 'Open Sans, Helvetica Neue, Arial, sans-serif'`，应用到段落、标题、引用块、表格文本。字号从 17px 调整为 16px，行高从 1.7 调整为 1.6。

#### 验收标准
- 预览模式使用 Open Sans 字体族
- 段落字号 16px，行高 1.6
- 标题、引用块、表格文本字体一致

---

## 3. 非功能需求

### 3.1 性能要求
- 主题切换无卡顿（已通过 `themeAnimationDuration: Duration.zero` 实现）
- 快捷键响应延迟 < 50ms

### 3.2 兼容性要求
- 保持与 V1.0.1 的配置文件兼容（自动迁移 `darkMode` 字段）
- 支持 Windows、macOS、Linux 三平台

### 3.3 代码质量要求
- `flutter analyze` 零 issue
- 所有修改需有对应的版本文档

---

## 4. 涉及文件

| 文件 | 改动类型 |
|------|---------|
| `lib/ui/screens/home_screen.dart` | 修改 - 添加快捷键处理 |
| `lib/core/config/app_config.dart` | 修改 - 移除 `darkMode` 字段 |
| `lib/providers/settings_provider.dart` | 修改 - 简化 `setTheme()` |
| `lib/app.dart` | 修改 - 简化主题逻辑，添加 `debugShowCheckedModeBanner` |
| `lib/ui/screens/settings_screen.dart` | 修改 - 重新设计主题选择 UI |
| `lib/core/theme/app_theme.dart` | 修改 - 添加主题分组，优化菜单高度 |
| `lib/ui/widgets/editor_tab_bar.dart` | 修改 - 右键菜单添加 `height: 36` |
| `lib/ui/widgets/app_menu_bar.dart` | 修改 - 更新 `applicationName` |
| `lib/core/constants.dart` | 修改 - 更新 `appName` |
| `lib/ui/editor/markdown_renderer.dart` | 修改 - 表格溢出修复、内容宽度自适应、字体优化 |
| `lib/core/i18n/l10n/app_*.arb` (12 个文件) | 修改 - 更新 `appTitle` |

---

## 5. 发布计划

### 5.1 版本号
V1.1.1

### 5.2 发布时间
2026-04-16

### 5.3 发布内容
- Bug 修复：快捷键、深色模式、UI 高度、表格溢出、内容宽度、预览字体
- 应用标题统一
- 完整的版本文档

### 5.4 升级说明
用户从 V1.0.1 升级到 V1.1.1 时：
- 配置文件自动迁移（移除 `darkMode` 字段）
- 如果之前开启了深色模式，会自动切换到 `darkGraphite` 主题
- 无需手动操作
