# MarkText Plus v1.1.0 — UI 重设计实施计划

## 实施顺序

按依赖关系从底层到上层：

1. Token 系统（基础，其他所有步骤依赖它）
2. 主题重写（依赖 token）
3. 各 UI 组件（依赖主题 token）
4. 设置页面（最后，依赖所有组件完成）

---

## Step 1 — 重写 Token 系统和主题

**文件：** `code/lib/core/theme/app_theme.dart`

新增 `AppThemeTokens` 类，包含 14 个 token 字段。`AppTheme` 改为基于 token 构建 `ThemeData`，同时暴露 token 供组件直接使用。

替换 5 个主题：`snow` / `latte` / `dusk` / `midnight` / `forest`，色值见设计文档 §1.3。

**文件：** `code/lib/core/config/app_config.dart`

更新 `theme` 字段的默认值和合法值列表（旧主题名 → 新主题名）。

**验证：** `flutter analyze` 通过，切换主题不报错。

---

## Step 2 — 标签栏（浏览器风格）

**文件：** `code/lib/ui/widgets/editor_tab_bar.dart`

- 高度 40px → 44px
- active 标签：圆角 8px（上方），背景 `colorBg`
- inactive 标签：透明背景，hover 时 `colorSurfaceHover`
- 修改指示器：改为 `●` 前缀（替换右侧小圆点）
- 字号 → 13px，active `colorText`，inactive `colorTextMuted`

---

## Step 3 — 侧边栏

**文件：** `code/lib/ui/widgets/side_bar.dart`

- 图标列宽 48px → 40px，图标尺寸 20px → 18px
- active 指示：左侧 2px 竖线（替换背景色高亮）
- 文件树节点高度固定 28px
- 文件名字号 → 13px
- 选中项背景 → `colorAccentMuted`，文字 → `colorAccent`

---

## Step 4 — 行号栏

**文件：** `code/lib/ui/editor/source_editor.dart`

- 背景 → `colorSurface`，右侧 1px `colorBorder` 分割线
- 行号颜色 → `colorTextMuted`，当前行 → `colorText`
- 宽度动态计算：`max(40, digits * 10 + 16)`

---

## Step 5 — 语法高亮跟随主题

**文件：** `code/lib/ui/editor/syntax_highlighter.dart`

将硬编码颜色（orange/blue/green/cyan）替换为从 `AppThemeTokens` 读取对应 syntax token。需要将 token 传入高亮器。

---

## Step 6 — 预览视图排版

**文件：** `code/lib/ui/editor/markdown_renderer.dart`

- 正文 16px → 17px，行高 1.5 → 1.7，段落间距 16px → 20px
- 外层加 `Center` + `ConstrainedBox(maxWidth: 720)`
- H1 下方加 `colorBorder` 分割线
- 代码块圆角 6px → 8px，加语言标签
- 引用块背景加 `colorAccentMuted` 4%

---

## Step 7 — 状态栏

**文件：** `code/lib/ui/widgets/status_bar.dart`

- 背景 → `colorSurface`
- 顶部阴影 → 1px `colorBorder` 上边框
- 文字颜色 → `colorTextMuted`

---

## Step 8 — 设置页面（卡片式）

**文件：** `code/lib/ui/screens/settings_screen.dart`

重写布局：
- 移除左右分栏，改为全屏单页
- 首页：2 列卡片网格（5 个分类）
- 点击卡片 → 进入详情页（Navigator.push 或 IndexedStack）
- 详情页顶部：返回按钮 + 分类名
- 卡片规范：圆角 12px，border 1px，hover 阴影

---

## 注意事项

- Step 1 完成前，其他步骤不能开始（token 是基础）
- Step 5（语法高亮）需要确认 token 如何传递给 `SyntaxHighlighter`（当前是静态方法，可能需要改为实例方法或接受 token 参数）
- 设置页面改动较大，需保留所有现有设置项，不能丢失功能
