# MarkText Plus v1.1.0 — UI 重设计方案

## 设计原则

- **现代简约**：大留白、细线条、柔和色彩，减少视觉噪音
- **内容优先**：UI 元素退到背景，编辑内容突出
- **主题一致性**：所有颜色通过 token 系统统一管理，语法高亮随主题联动

---

## 一、设计 Token 系统

### 1.1 Token 定义

每个主题必须定义以下 token：

| Token | 类型 | 用途 |
|-------|------|------|
| `colorBg` | Color | 编辑区背景 |
| `colorSurface` | Color | 侧边栏、标签栏、行号栏背景 |
| `colorSurfaceHover` | Color | 悬停状态背景 |
| `colorBorder` | Color | 分割线、边框 |
| `colorText` | Color | 正文、活跃行号 |
| `colorTextMuted` | Color | 次要文字、非活跃行号、占位符 |
| `colorAccent` | Color | 主色调（链接、选中、活跃标签指示） |
| `colorAccentMuted` | Color | accent 的低透明度版本（背景装饰） |
| `syntaxHeading` | Color | 标题语法高亮 |
| `syntaxBold` | Color | 加粗语法高亮 |
| `syntaxCode` | Color | 行内代码 / 代码块语法高亮 |
| `syntaxLink` | Color | 链接语法高亮 |
| `syntaxQuote` | Color | 引用块语法高亮 |
| `syntaxComment` | Color | 注释类语法高亮 |

### 1.2 新主题方案

替换现有 5 个主题：

| 主题 ID | 名称 | 亮/暗 | 风格描述 |
|---------|------|-------|---------|
| `snow` | Snow | 亮 | 纯白背景，蓝色 accent，极简清爽 |
| `latte` | Latte | 亮 | 暖米色背景，棕橙 accent，温暖舒适 |
| `dusk` | Dusk | 暗 | 深蓝灰背景，柔和对比，护眼 |
| `midnight` | Midnight | 暗 | 纯黑背景，高对比，专注 |
| `forest` | Forest | 暗 | 深绿色调，自然感，沉浸 |

### 1.3 Token 色值参考

**Snow（亮）**
```
colorBg:           #FFFFFF
colorSurface:      #F7F7F8
colorSurfaceHover: #EFEFEF
colorBorder:       #E5E5E5
colorText:         #1A1A1A
colorTextMuted:    #9B9B9B
colorAccent:       #2563EB
colorAccentMuted:  #2563EB1A
syntaxHeading:     #1D4ED8
syntaxBold:        #1A1A1A
syntaxCode:        #D97706
syntaxLink:        #2563EB
syntaxQuote:       #6B7280
syntaxComment:     #9CA3AF
```

**Latte（亮）**
```
colorBg:           #FAF7F2
colorSurface:      #F0EBE3
colorSurfaceHover: #E8E0D5
colorBorder:       #DDD5C8
colorText:         #2C2416
colorTextMuted:    #9C8E7E
colorAccent:       #C2692A
colorAccentMuted:  #C2692A1A
syntaxHeading:     #A0522D
syntaxBold:        #2C2416
syntaxCode:        #6B8E23
syntaxLink:        #C2692A
syntaxQuote:       #8B7355
syntaxComment:     #A89880
```

**Dusk（暗）**
```
colorBg:           #1E2330
colorSurface:      #171C28
colorSurfaceHover: #252B3A
colorBorder:       #2E3548
colorText:         #CDD6F4
colorTextMuted:    #6C7086
colorAccent:       #89B4FA
colorAccentMuted:  #89B4FA1A
syntaxHeading:     #CBA6F7
syntaxBold:        #CDD6F4
syntaxCode:        #A6E3A1
syntaxLink:        #89B4FA
syntaxQuote:       #6C7086
syntaxComment:     #585B70
```

**Midnight（暗）**
```
colorBg:           #0D0D0D
colorSurface:      #141414
colorSurfaceHover: #1F1F1F
colorBorder:       #2A2A2A
colorText:         #E8E8E8
colorTextMuted:    #555555
colorAccent:       #60A5FA
colorAccentMuted:  #60A5FA1A
syntaxHeading:     #A78BFA
syntaxBold:        #E8E8E8
syntaxCode:        #34D399
syntaxLink:        #60A5FA
syntaxQuote:       #555555
syntaxComment:     #404040
```

**Forest（暗）**
```
colorBg:           #1A2318
colorSurface:      #141C12
colorSurfaceHover: #1F2B1D
colorBorder:       #2A3828
colorText:         #D4E6D0
colorTextMuted:    #5A7055
colorAccent:       #6DBF67
colorAccentMuted:  #6DBF671A
syntaxHeading:     #A8D5A2
syntaxBold:        #D4E6D0
syntaxCode:        #F0C060
syntaxLink:        #6DBF67
syntaxQuote:       #5A7055
syntaxComment:     #3D5238
```

---

## 二、整体布局

```
┌─────────────────────────────────────────────────────────────┐
│  [系统原生菜单栏]                                              │
├────────────────────────────────────────────────────────────┤
│      │ ╭──────────────╮ ╭──────────────╮         │
│ 图标 │ │● untitled.md×│ │  README.md  ×│  +      │
│ 侧   ├─╯──────────────╰─╯──────────────╰─────────┤
│ 边   │                                            │
│ 栏   │              编辑区域                       │
│      │                                            │
├──────┴─────────────────────────────────────────────────────┤
│  状态栏                                                      │
└─────────────────────────────────────────────────────────────┘
```

**尺寸规范：**
- 侧边栏图标列宽：40px（原 48px）
- 侧边栏内容区宽：240px（原 280px，总宽 280px）
- 标签栏高度：44px（原 40px）
- 状态栏高度：24px（保持不变）

---

## 三、侧边栏

### 3.1 图标列
- 背景：`colorSurface`
- 宽度：40px
- 图标尺寸：18px（原 20px）
- 图标颜色：`colorTextMuted`，active 时 `colorAccent`
- active 指示：左侧 2px 竖线，颜色 `colorAccent`
- 图标间距：8px vertical padding

### 3.2 内容区
- 背景：`colorSurface`（与图标列同色）
- 与编辑区之间：1px 分割线，颜色 `colorBorder`
- 文件树节点高度：28px（原 ExpansionTile 默认高度）
- 文件名字号：13px
- hover 背景：`colorSurfaceHover`
- 选中背景：`colorAccentMuted`，文字 `colorAccent`

---

## 四、标签栏（浏览器风格）

### 4.1 视觉结构
```
colorSurface 背景
╭──────────────╮  ╭──────────────╮
│● untitled.md×│  │  README.md  ×│   +
╰──────────────╯  ╰──────────────╯
     ↑ colorBg 背景（与编辑区连通）
```

### 4.2 规范
- 标签圆角：8px 上方，0px 下方（视觉连通编辑区）
- active 标签背景：`colorBg`
- inactive 标签背景：透明，hover 时 `colorSurfaceHover`
- 修改指示器：`●` 前缀，颜色 `colorAccent`，已保存时隐藏
- 关闭按钮：16px，hover 时显示，`colorTextMuted`
- 标签最小宽度：100px，最大宽度：200px
- 字号：13px，active 时 `colorText`，inactive 时 `colorTextMuted`
- `+` 新建按钮：右侧，20px 图标，`colorTextMuted`

---

## 五、行号栏

### 5.1 规范
- 背景：`colorSurface`
- 右侧分割线：1px，颜色 `colorBorder`
- 行号颜色：`colorTextMuted`
- 当前行行号颜色：`colorText`
- 字号：与编辑器字号相同，但 opacity 降低
- 宽度：`max(40px, ceil(log10(lineCount + 1)) * 10px + 16px)`
  - 1-9 行：40px
  - 10-99 行：50px
  - 100-999 行：60px
  - 1000+ 行：70px

---

## 六、编辑区域

### 6.1 源码视图
- 背景：`colorBg`
- 内边距：16px 水平，12px 垂直
- 光标颜色：`colorAccent`
- 选中背景：`colorAccentMuted`（透明度 30%）
- 语法高亮颜色：使用主题 syntax token

### 6.2 预览视图排版

| 元素 | 规范 |
|------|------|
| 正文字号 | 17px（原 16px） |
| 行高 | 1.7（原 1.5） |
| 段落间距 | 20px（原 16px） |
| 最大内容宽度 | 720px，居中显示 |
| 水平内边距 | 32px |
| H1 | 32px，weight 700，下方 8px `colorBorder` 分割线 |
| H2 | 26px，weight 600 |
| H3 | 21px，weight 600 |
| H4-H6 | 17px，weight 600，`colorTextMuted` |
| 代码块 | 圆角 8px，背景 `colorSurface`，右上角语言标签 |
| 引用块 | 左边框 4px `colorAccent`，背景 `colorAccentMuted` 4% |
| 列表缩进 | 24px |
| 图片 | 圆角 6px，最大宽度 100% |

---

## 七、设置页面（卡片式）

### 7.1 布局
- 改为全屏页面（替换当前左右分栏）
- 顶部：标题 "设置" + 关闭按钮
- 内容区：2 列卡片网格，间距 16px，内边距 24px

### 7.2 卡片规范
- 圆角：12px
- 背景：`colorSurface`
- 边框：1px `colorBorder`
- hover：`box-shadow: 0 4px 12px rgba(0,0,0,0.08)`，轻微上浮
- 卡片内：图标（24px）+ 分类名（16px bold）+ 描述（13px `colorTextMuted`）

### 7.3 分类
| 图标 | 分类 | 描述 |
|------|------|------|
| 🌐 | 通用 | 语言、启动行为、最近文件 |
| ✏️ | 编辑器 | 字体、字号、行高、Tab 宽度 |
| 🎨 | 主题 | 外观主题、深色模式 |
| ⌨️ | 快捷键 | 自定义键位绑定 |
| 📄 | Markdown | 渲染选项、扩展语法 |

### 7.4 详情页
- 顶部：`← 返回` 按钮 + 分类名
- 内容：单列表单，每项 label + 控件，间距 16px
- 底部：`重置为默认值` 按钮

---

## 八、状态栏

保持现有功能，优化视觉：
- 背景：`colorSurface`
- 顶部边框：1px `colorBorder`（原为阴影）
- 字号：12px（原 12px，保持）
- 文字颜色：`colorTextMuted`
- hover 项目：`colorSurfaceHover` 背景，`colorText` 文字

---

## 九、动效规范

| 场景 | 时长 | 曲线 |
|------|------|------|
| 标签切换 | 150ms | easeInOut |
| 侧边栏展开/收起 | 200ms | easeInOut |
| 主题切换 | 0ms（禁用动画） | — |
| 卡片 hover | 120ms | easeOut |
| 命令面板出现 | 150ms | easeOut |

---

## 十、涉及文件清单

| 文件 | 改动内容 |
|------|---------|
| `core/theme/app_theme.dart` | 重写：引入 token 系统，替换 5 个主题 |
| `core/config/app_config.dart` | 更新主题名枚举 |
| `ui/widgets/editor_tab_bar.dart` | 浏览器风格圆角标签 |
| `ui/widgets/side_bar.dart` | 图标列 40px，文件树样式优化 |
| `ui/widgets/status_bar.dart` | 顶部边框替换阴影，颜色 token 化 |
| `ui/editor/source_editor.dart` | 行号栏动态宽度，颜色 token 化 |
| `ui/editor/syntax_highlighter.dart` | 语法高亮颜色从主题 token 读取 |
| `ui/editor/markdown_renderer.dart` | 预览排版优化，内容居中限宽 |
| `ui/screens/settings_screen.dart` | 重写为卡片式布局 |
