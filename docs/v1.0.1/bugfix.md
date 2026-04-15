# MarkText Plus v1.0.1 — Bug 修复记录

## 总览

| 编号 | 日期 | 标题 | 紧急程度 | 优先级 | 难易度 | 状态 |
|------|------|------|----------|--------|--------|------|
| BUG-001 | 2026-04-14 | 无系统级窗口标题栏 | P0-致命 | 最高 | 困难 | 已修复 |
| BUG-002 | 2026-04-15 | 切换主题时深色模式覆盖导致不生效 | P2-一般 | 中 | 简单 | 已修复 |
| BUG-003 | 2026-04-15 | 源码视图滚动掉帧 + 行号消失 | P1-严重 | 高 | 中等 | 已修复 |
| BUG-004 | 2026-04-15 | 菜单栏缺少快捷键显示 | P2-一般 | 中 | 简单 | 已修复 |
| BUG-005 | 2026-04-15 | 切换主题过渡动画掉帧 | P2-一般 | 中 | 简单 | 已修复 |
| BUG-006 | 2026-04-15 | 行号区域滚动弹跳 | P1-严重 | 高 | 中等 | 已修复 |
| BUG-007 | 2026-04-15 | 源码视图中链接语法消失 | P1-严重 | 高 | 中等 | 已修复 |
| BUG-008 | 2026-04-15 | 预览视图中链接不可点击 | P2-一般 | 中 | 中等 | 已修复 |
| BUG-009 | 2026-04-15 | Windows 右键打开方式无本应用 + 启动参数未处理 | P1-严重 | 高 | 中等 | 已修复 |

## 详细记录

### BUG-001 — 无系统级窗口标题栏

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-14 |
| 修复日期 | 2026-04-14 |
| 紧急程度 | P0-致命 |
| 优先级 | 最高 |
| 难易度 | 困难 |
| 现象 | Windows 端完全没有标题栏（无最小化/最大化/关闭按钮，无法拖动窗口） |
| 根因 | `window_manager` 包的 C++ 层 `HandleTopLevelWindowProc` 拦截了 `WM_NCCALCSIZE` 消息，导致系统原生标题栏被移除 |
| 修复方案 | 完全移除 `window_manager` 依赖，改用 `WidgetsBindingObserver` 处理窗口生命周期事件 |
| 涉及文件 | `main.dart`, `pubspec.yaml`, `app_menu_bar.dart` |

### BUG-002 — 切换主题时深色模式覆盖导致不生效

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-15 |
| 修复日期 | 2026-04-15 |
| 紧急程度 | P2-一般 |
| 优先级 | 中 |
| 难易度 | 简单 |
| 现象 | 开启深色模式后，切换主题无效果，误导用户 |
| 根因 | `app.dart` 中 `themeMode: config.darkMode ? ThemeMode.dark : ThemeMode.light`，深色模式优先级高于主题选择 |
| 修复方案 | `setTheme()` 方法中同时设置 `darkMode: false`，切换主题时自动关闭深色模式 |
| 涉及文件 | `providers/settings_provider.dart` |

### BUG-003 — 源码视图滚动掉帧 + 行号消失

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-15 |
| 修复日期 | 2026-04-15 |
| 紧急程度 | P1-严重 |
| 优先级 | 高 |
| 难易度 | 中等 |
| 现象 | 打开超过 100 行的 markdown 文件后，滚动时行号区域出现消失再重现的动画，大幅度滚动掉帧 |
| 根因 | 行号 `ListView.builder` 未设置 `itemExtent`，导致每次滚动需重新计算布局；行号栏宽度固定 50px 不足以容纳 3+ 位数行号 |
| 修复方案 | 添加 `itemExtent` 固定行高；行号栏宽度根据行数动态调整（50/58/66px） |
| 涉及文件 | `ui/editor/source_editor.dart` |

### BUG-004 — 菜单栏缺少快捷键显示

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-15 |
| 修复日期 | 2026-04-15 |
| 紧急程度 | P2-一般 |
| 优先级 | 中 |
| 难易度 | 简单 |
| 现象 | 顶部菜单栏的 Format 菜单和 View 菜单项没有显示对应的快捷键组合 |
| 根因 | `MenuItemButton` 未设置 `shortcut` 参数 |
| 修复方案 | 通过 `KeybindingService` 解析快捷键配置，为 Format 菜单项添加 `shortcut`；为 View 菜单项添加标准快捷键 |
| 涉及文件 | `ui/widgets/app_menu_bar.dart` |

### BUG-005 — 切换主题过渡动画掉帧

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-15 |
| 修复日期 | 2026-04-15 |
| 紧急程度 | P2-一般 |
| 优先级 | 中 |
| 难易度 | 简单 |
| 现象 | 切换主题时 Flutter 默认的主题过渡动画导致掉帧 |
| 根因 | `MaterialApp` 默认的 `themeAnimationDuration` 触发全局重绘动画 |
| 修复方案 | 设置 `themeAnimationDuration: Duration.zero` 禁用主题切换动画 |
| 涉及文件 | `app.dart` |

### BUG-006 — 行号区域滚动弹跳

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-15 |
| 修复日期 | 2026-04-15 |
| 紧急程度 | P1-严重 |
| 优先级 | 高 |
| 难易度 | 中等 |
| 现象 | 源码视图中大幅度滚动时，左侧行号区域出现弹跳动画 |
| 根因 | 行号 `ListView` 使用默认滚动物理效果，且 `jumpTo` 未限制在有效范围内 |
| 修复方案 | 设置 `ClampingScrollPhysics` 禁用弹跳；`jumpTo` 时将偏移量 clamp 到有效滚动范围 |
| 涉及文件 | `ui/editor/source_editor.dart` |

### BUG-007 — 源码视图中链接语法消失

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-15 |
| 修复日期 | 2026-04-15 |
| 紧急程度 | P1-严重 |
| 优先级 | 高 |
| 难易度 | 中等 |
| 现象 | 源码视图中 `[text](url)` 格式的链接只显示 `text` 部分，URL 部分消失 |
| 根因 | 语法高亮器 `_highlightInline` 对链接模式使用 `group(1)` 只取链接文本，丢弃了完整的 markdown 语法 |
| 修复方案 | 为链接/图片模式添加 `useFullMatch` 标志，使用 `group(0)` 显示完整语法 |
| 涉及文件 | `ui/editor/syntax_highlighter.dart` |

### BUG-008 — 预览视图中链接不可点击

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-15 |
| 修复日期 | 2026-04-15 |
| 紧急程度 | P2-一般 |
| 优先级 | 中 |
| 难易度 | 中等 |
| 现象 | 预览视图中的链接仅有样式但无法点击；本地 markdown 文件链接无法在应用内打开 |
| 根因 | 链接 `TextSpan` 未设置 `recognizer`，无点击事件处理 |
| 修复方案 | 添加 `TapGestureRecognizer`；外部 URL 用 `url_launcher` 打开；本地 `.md/.markdown/.txt` 文件解析相对路径后在应用内新标签页打开 |
| 涉及文件 | `ui/editor/markdown_renderer.dart` |

### BUG-009 — Windows 右键打开方式无本应用 + 启动参数未处理

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-15 |
| 修复日期 | 2026-04-15 |
| 紧急程度 | P1-严重 |
| 优先级 | 高 |
| 难易度 | 中等 |
| 现象 | 1) Windows 右键 .md 文件的"打开方式"中无 MarkText Plus 选项；2) 手动选择本应用后启动显示空白，未打开所选文件 |
| 根因 | Inno Setup 脚本缺少 `[Registry]` 段，未注册 .md 文件关联；Dart 端 `main()` 忽略了 Windows runner 传递的命令行参数 |
| 修复方案 | 1) Inno Setup 添加 `ChangesAssociations=yes` 和 `[Registry]` 段注册 ProgID `MarkTextPlus.md`，关联 `.md/.markdown/.txt` 扩展名；2) `main.dart` 解析命令行参数筛选合法文件路径，通过 `startupFilesProvider` 传递；3) `home_screen.dart` 启动时读取文件内容并创建标签页 |
| 涉及文件 | `main.dart`, `providers/tab_provider.dart`, `ui/screens/home_screen.dart`, `.github/workflows/release.yml` |
