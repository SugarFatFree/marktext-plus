# V1.4.0 功能需求文档

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-001 | 2026-08-28 | 邮箱地址自动变成可点链接 | 中 | 简单 | 已实现 |
| FEAT-002 | 2026-08-28 | 链接与图片的文字里允许成对方括号 | 中 | 简单 | 已实现 |
| FEAT-003 | 2026-08-28 | 文件在外部被改动时自动重载（仅限无未保存修改） | 高 | 中等 | 已实现 |
| FEAT-004 | 2026-08-28 | Mermaid 新增 block-beta（块图） | 中 | 中等 | 已实现 |
| FEAT-005 | 2026-08-28 | Mermaid 新增 C4 系列（C4Context 等五种） | 中 | 困难 | 已实现 |
| FEAT-006 | 2026-08-28 | 换行符可切换（状态栏点击） | 中 | 简单 | 已实现 |
| FEAT-007 | 2026-08-28 | 设置里的「启用 HTML」开关真正生效（行内标签） | 中 | 中等 | 已实现 |
| FEAT-008 | 2026-08-28 | 前置元数据支持 TOML(`+++`) 与 JSON(`;;;`/`{}`) 三种格式 | 中 | 简单 | 已实现 |
| FEAT-009 | 2026-08-28 | Mermaid 时间线支持 `section` 分组带 | 中 | 中等 | 已实现 |
| FEAT-010 | 2026-08-28 | 预览里可以编辑 Mermaid 图表的源码 | 高 | 简单 | 已实现 |
| FEAT-011 | 2026-08-28 | 段落菜单补上「松散列表项」（对齐上游最后一项缺口） | 中 | 中等 | 已实现 |
| FEAT-012 | 2026-08-28 | 编辑菜单补上「在下方插入段落」与「删除当前段落」 | 中 | 中等 | 已实现 |
| FEAT-013 | 2026-08-28 | 设置里可以选编辑器正文字体 | 中 | 简单 | 已实现 |
| FEAT-014 | 2026-08-28 | 评估：Mermaid 渲染抽成独立开源包的可行性 | 低 | — | 已评估，待决策 |
| FEAT-015 | 2026-08-28 | 预览里的可编辑块给出光标与悬停提示 | 中 | 简单 | 已实现 |
| FEAT-016 | 2026-08-28 | 自动补全括号/引号/Markdown 语法可以分别关掉 | 中 | 简单 | 已实现 |
| FEAT-017 | 2026-08-28 | 主题可以跟随系统深浅色 | 高 | 中等 | 已实现 |
| FEAT-018 | 2026-08-28 | 大文件先出首屏再补全：5 MB 文档首屏从 4578 ms 降到 13 ms | **高** | 中等 | 已实现 |
| FEAT-019 | 2026-08-28 | 大文件里打字变快：1 MB 文档每次按键 28.4 → 18.9 ms | 中 | 中等 | 已实现 |
| FEAT-020 | 2026-08-28 | 导出的 HTML 里内嵌图表图片，断网/内网也能看 | **高** | 简单 | 已实现 |
| FEAT-021 | 2026-08-28 | 导出时就把代码着色，不再向 CDN 取 highlight.js | 中 | 简单 | 已实现 |
| FEAT-022 | 2026-08-28 | 没有公式的文档导出后零外部依赖 | 中 | 简单 | 已实现 |
| FEAT-023 | 2026-08-28 | 代码块内长行可以选择不换行（改为横向滚动） | 中 | 简单 | 已实现 |
| FEAT-024 | 2026-08-28 | 只注册常用语言的语法高亮，砍掉 80% 的定义体积 | **高** | 简单 | 已实现 |
| FEAT-025 | 2026-08-28 | 「编辑器最大宽度」现在也作用于源码编辑器 | 中 | 简单 | 已实现 |
| FEAT-026 | 2026-08-28 | 代码字号可单独设置（对齐上游 codeFontSize） | 中 | 简单 | 已实现 |
| FEAT-027 | 2026-08-28 | 「在文件中查找」进编辑菜单，搜索面板自动聚焦 | 中 | 简单 | 已实现 |
| FEAT-028 | 2026-08-28 | 打印（Ctrl+P，系统打印对话框） | **高** | 中等 | 已实现 |
| FEAT-029 | 2026-08-28 | Mermaid 的 YAML frontmatter 标题（所有图表类型） | 中 | 中等 | 已实现 |

## 详细需求

### FEAT-001 — 邮箱地址自动变成可点链接

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 优先级 | 中 |
| 难易度 | 简单 |
| 状态 | 已实现 |
| 需求描述 | `<foo@example.com>`（CommonMark 的尖括号自动链接）与散文里的裸地址 `foo@example.com`（GitHub 的扩展）都应渲染成 `mailto:` 链接。源项目用 markdown-it + linkify，两种都认；本项目两种都原样显示成文字 |
| 用户场景 | 笔记里写联系人、README 里留维护者邮箱 —— 写的人不会特意加 `[]()` |
| 实现方案 | 在行内总正则**末尾追加**两个分支（组 35 尖括号式、组 36 裸地址），追加而不是插入，是为了不动已有分支的组号 —— 本版本历史上已经因为组号平移把行内代码的反向引用打歪过一次 |
| 误报控制 | 裸地址要求域名**必须带点**（`a@b` 不算），前面加反向断言挡住已被别的分支吃掉的地址尾巴（`https://user@host/path` 由裸 URL 分支整体接管）；`@mention`、`5@2` 都不匹配；句尾标点不算地址的一部分，与裸 URL 的处理一致 |
| 已知误报 | `user@2x.png` 会被当成地址 —— GFM 规范本身就有这个已知误报，与源项目行为一致，不特殊处理 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`test/services/markdown_parser_test.dart` |
| 验证方式 | 61 条语料基线对拍**零差异**；14 种写法逐一探查（含中文夹杂、代码内、显式 mailto 链接、多个地址同行）；转义与 HTML 实体两条重建路径单独断言 href 未丢；五个历史断言脚本全部通过 |
| 导出 | HTML / PDF / Word 三条导出路径都是按 `InlineType.link` + `span.href` 统一处理的，`mailto:` 自动生效，无需改动 |

---

### FEAT-002 — 链接与图片的文字里允许成对方括号

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 优先级 | 中 |
| 难易度 | 简单 |
| 状态 | 已实现 |
| 需求描述 | `[见 [1] 此处](https://x.com)` 按 CommonMark 是一个链接，链接文字里的方括号只要成对就合法。本项目的 `[^\]]*` 在内层方括号处就停了，整段退化成普通文字 |
| 用户场景 | 引用编号（`[1]`）、快捷键（`[Ctrl]`）、占位符写进链接文字里，是很常见的写法 |
| 实现方案 | 链接文字改成 `(?:[^\[\]]\|\[[^\[\]]*\])*`，即「非方括号字符，或一整段成对方括号」。内层用非捕获组，**不新增捕获组**，所以既有分支的组号一个都没动 |
| 顺带修掉的回归 | 只改链接分支会**把图片弄坏**：`![alt [x]](img.png)` 图片分支仍在内层括号处失败，接着链接分支从 `[` 开始匹配，结果变成「一个多余的 `!` + 一个链接」—— 比原来更糟。图片分支同步改成一样的写法，它排在链接分支前面，于是优先接管 |
| 已知限制 | 只支持**一层**嵌套：`[a [b [c]] d](x)` 仍不是链接。CommonMark 允许任意层，但那需要真正的配对扫描而不是正则；现实文档里一层够用 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`test/services/markdown_parser_test.dart` |
| 验证方式 | 61 条语料基线对拍**零差异**；11 种写法逐一探查（含「有方括号但后面没有链接目标」「徽章 `[![img](a.png)](url)` 的 image + linkHref 双字段」）；五个历史断言脚本与徽章断言脚本全部通过 |

---

### FEAT-003 — 文件在外部被改动时自动重载（仅限没有未保存修改的文档）

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 优先级 | 高 |
| 难易度 | 中等 |
| 状态 | 已实现 |
| 需求描述 | 打开着的文档**完全不监视外部改动**：`git pull`、`git checkout`、别的编辑器保存、格式化工具跑一遍 —— 编辑器里仍是旧内容，接着一保存就把新版本盖回去 |
| 为什么算高优先级 | 这不只是「显示不同步」，而是**会丢别人的改动**。侧边栏的目录树有监视器，打开的文件反而没有 |
| 用户场景 | 一边在编辑器里读 README 一边 `git pull`；用命令行工具批量替换后回到编辑器；两台设备同步同一个笔记目录 |
| 实现方案 | 新增 `OpenDocumentWatcher`：监视的是**所在目录**而不是文件本身 —— 大量工具（编辑器、`git checkout`、格式化器）保存时是「写临时文件再改名覆盖」，盯着文件的监视会就此失聪。事件按文件路径过滤并按 300ms 去抖（一次保存会来一串 truncate/write/close 事件，中间读会读到写了一半的内容） |
| 重载策略 | **只重载没有未保存修改的文档**。有未保存修改时原样不动 —— 悄悄替换掉别人正在写的东西，是两种失败里明显更糟的那一种。`await` 读文件回来后会**再查一次状态**，因为这段时间用户可能已经开始打字 |
| 编辑器如何采纳 | `TabInfo` 新增 `externalRevision`，`loadTabContent` 时递增。源码编辑器故意忽略「分不清是不是自己打的」的内容变化（正是它保证打字不被吞掉的机制），修订号就是用来区分的。分栏编辑器把自己的修订号与外部修订号相加后传给源码面板，于是「磁盘重载」和「在预览里改了一处」两条路都通 |
| 监视集合如何同步 | 重写 `set state`，状态一变就同步一次监视集合 —— 而不是在八个增删标签页的地方各写一遍。本版已经为「同一件事写在多处后各自漂移」记过六次账 |
| 尚未做 | 有未保存修改时不提示「磁盘上的版本变了，要重新加载吗」。提示需要 12 种语言的文案，本次不扩大范围；当前行为是安全的（保留用户的内容） |
| 涉及文件 | `lib/services/open_document_watcher.dart`（新增）、`lib/models/tab_info.dart`、`lib/providers/tab_provider.dart`、`lib/ui/editor/split_editor.dart`、`lib/ui/screens/home_screen.dart`、`test/services/open_document_watcher_test.dart`（新增）、`test/providers/tab_reload_test.dart`（新增） |
| 验证方式 | 监视器 5 个单元测试（普通改动、同目录未打开的文件不报、**改名覆盖式保存**、连写五次只报一次、取消监视）；provider 5 个测试（干净文档重载、修订号递增、**有未保存修改时不动**、关掉的文档不再监视、内容相同不触发）。另用纯 Dart 复刻 `state_notifier` 的受保护设置器形状，确认「只重写设置器」这一写法成立 |

---

### FEAT-004 — Mermaid 新增 block-beta（块图）

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 优先级 | 中 |
| 难易度 | 中等 |
| 状态 | 已实现 |
| 需求描述 | 支持 mermaid 的 `block-beta`：用网格摆放若干带标签的方块，方块之间可以连箭头。常用于画系统组成、分层架构 |
| 语法特点 | 它是**网格**而不是图：`columns n` 定宽，之后每一行列出这一行的方块，排满自动换行。`space` 占位不画，`:n` 跨列 |
| 实现方案 | 四件套 `models/block_diagram.dart`（数据 + 布局）、`parser/block_parser.dart`、`painter/block_painter.dart`、`layout_engine.dart` 的 `BlockDiagramLayout`。布局仍是**一个纯 Dart 函数**，算尺寸和画图都调它 |
| 形状 | `[方]`、`(圆角)`、`((圆))`、`{菱形}`、`{{六边}}`、`[[子程序]]`、`([体育场])`、`[(圆柱)]`、`>斜边]`（mermaid 称之为 asymmetric，本项目按平行四边形画，形状可辨但不完全一致）。两字符括号在正则里**排在单字符前面** —— 交替取第一个匹配的分支，`[[` 写在 `[` 后面就永远轮不到，`f[["x"]]` 会剩一个括号 |
| 分行 | 一行不能按空格粗暴切分：`a["两 个 词"] b` 是两个方块。按括号深度与引号切分 |
| 箭头 | `a --> b`、`a -- "标签" --> b`、`a -->|标签| b` 三种写法。线从**方块边缘**出发而不是中心，否则箭头会被方块盖住；箭头标签底下垫一层背景色，否则线会从字中间穿过 |
| 已知限制 | 嵌套的 `block:组 … end` 尚未做成子网格 —— 组内的方块会被摆进外层网格，而不是被丢弃。`style` / `classDef` 行忽略 |
| 涉及文件 | `lib/ui/editor/mermaid/models/block_diagram.dart`、`parser/block_parser.dart`、`painter/block_painter.dart`、`parser/mermaid_parser.dart`、`models/diagram.dart`、`layout/layout_engine.dart`、`widgets/mermaid_diagram.dart`、`mermaid.dart`、`test/ui/editor/mermaid/mermaid_parser_test.dart`、`test/fixtures/showcase.md` |
| 验证方式 | 12 种写法本地探查（换行、形状、跨列、空位、三种箭头写法、无 `columns`、含空格标签、中文 id、嵌套组、只有表头）；画布用手写桩类型完整编译并跑通（含自环箭头、指向不存在方块的箭头、空图）；showcase 夹具 27 个 mermaid 块全部解析成功 |
| 过程记录 | 新建的 `models/block_diagram.dart` 被上一个提交的 `git add -A` 顺带带了出去 —— 当时它还没人引用，编译无碍，但一个半成品文件混进了不相干的提交。**提交前该看一眼 `git status`** |

---

### FEAT-005 — Mermaid 新增 C4 系列（C4Context / C4Container / C4Component / C4Dynamic / C4Deployment）

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 优先级 | 中 |
| 难易度 | 困难 |
| 状态 | 已实现 |
| 需求描述 | 支持 mermaid 的 C4 模型图：人、系统、容器、组件画成方块，用虚线边界框把它们分组，之间连关系箭头。架构文档里的常用图 |
| 意义 | 这是 v1.3.0 FEAT-008 列出的**最后一类**未实现类型 —— 至此该条需求全部完成 |
| 语法特点 | 与其他图都不同：正文是一串**函数调用**（`Person(alias, "名字", "描述")`、`Rel(a, b, "使用")`），边界用花括号包住内容 |
| 实现方案 | 四件套 `models/c4_diagram.dart`（数据 + 布局）、`parser/c4_parser.dart`、`painter/c4_painter.dart`、`layout_engine.dart` 的 `C4DiagramLayout`。布局仍是**一个纯 Dart 函数**，算尺寸和画图都调它 |
| 参数顺序的坑 | `Person` / `System` 是 `(别名, 名字, 描述)`，而 `Container` / `Component` / `Node` 是 `(别名, 名字, 技术, 描述)`。一视同仁地读会把**技术栈塞进描述里** —— 已按类型分开处理，并有测试盯着 |
| 参数切分 | 不能按逗号粗暴切分：描述里经常有逗号（`"有两个账户, 都是活期"`）。按引号与括号深度切分 |
| 边界布局 | 递归：边界独占一行，内容用同一个函数下沉一层排布；边界的宽高由**递归返回后新增的那一段切片**算出（不去列表里回头查找），并**插在自己的索引位**上，保证外层先画、内层后画 |
| 已支持 | `Person(_Ext)`、`System(Db/Queue)(_Ext)`、`Container(Db/Queue)`、`Component`、`Node`、`Enterprise_/System_/Container_Boundary`、`Rel` / `BiRel` / `Rel_U/D/L/R`、`title`、`UpdateLayoutConfig($c4ShapeInRow)`。`UpdateRelStyle` / `UpdateElementStyle` 识别但忽略（只影响配色微调） |
| 已知限制 | `Rel_U/D/L/R` 的方向记录下来了但布局尚未据此摆放（仍按文档顺序流式排布）；`C4Dynamic` 的序号未画 |
| 涉及文件 | `lib/ui/editor/mermaid/models/c4_diagram.dart`、`parser/c4_parser.dart`、`painter/c4_painter.dart`、`parser/mermaid_parser.dart`、`models/diagram.dart`、`layout/layout_engine.dart`、`widgets/mermaid_diagram.dart`、`mermaid.dart`、`test/ui/editor/mermaid/mermaid_parser_test.dart`、`test/fixtures/showcase.md` |
| 验证方式 | 官方示例、嵌套边界、描述含逗号、`c4ShapeInRow`、缺右花括号、只有表头六种情况本地探查；画布用手写桩类型完整编译并跑通（含自环关系、指向不存在别名的关系、双向箭头、空图）；showcase 夹具 28 个 mermaid 块全部解析成功 |

---

### FEAT-006 — 换行符可切换（状态栏点击）

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 优先级 | 中 |
| 难易度 | 简单 |
| 状态 | 已实现 |
| 需求背景 | 拿本项目的菜单与上游 `../marktext` 的菜单模板逐项对照（`packages/desktop/src/main/menu/templates/*.ts`，菜单是功能清单最可靠的来源），上游「编辑」菜单里有 **Line Ending → CRLF / LF** 的切换，本项目只能检测并保留、不能改 |
| 实现方案 | 把状态栏那个换行符标签做成**可点击**，点一下在 LF / CRLF 之间切换 —— VS Code 就是这么做的，而且**零新增文案**：标签本身是 `LF` / `CRLF`，在任何语言里都不翻译。避开了「加一个菜单项要改 12 份 arb + 13 份生成代码」的代价 |
| 为什么切换后标记为「已修改」 | 文本一个字没变，但**将要写到磁盘上的字节变了**。不标记的话，用户切完直接关标签页，这个选择就无声地丢了 |
| 涉及文件 | `lib/providers/tab_provider.dart`、`lib/ui/widgets/status_bar.dart`、`test/providers/tab_reload_test.dart` |
| 验证方式 | 2 个 provider 测试：切换后换行符生效且标记为已修改；设置成它已经是的那个值时不产生虚假的「已修改」 |

---

#### 与上游菜单的逐项差距（本次对照结果，供后续排期）

| 菜单 | 上游有而本项目没有 | 备注 |
|------|--------------------|------|
| 文件 | `moveTo`（移动文件）、`import`（导入）、`print`（打印）、菜单内的 `autoSave` 开关 | 打印需要引 `printing` 包，Linux 侧依赖 CUPS，对 CI 构建有风险；导入依赖 pandoc |
| 编辑 | `pasteAsPlainText`、`createParagraph` / `deleteParagraph`、`findInFolder`（功能在侧边栏已有，缺菜单入口）、`screenshot`、~~`lineEnding`~~ | lineEnding 本次已补 |
| 段落 | `looseListItem` | 已在 v1.3.0 记为已知未实现 |
| 格式 | —— | **全部已实现** |
| 视图 | `reloadImages` | 其余（命令面板、源码模式、打字机模式、专注模式、侧边栏/标签栏开关）均已实现 |

### FEAT-007 — 设置里的「启用 HTML」开关真正生效（行内标签）

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 优先级 | 中 |
| 难易度 | 中等 |
| 状态 | 已实现（行内部分） |
| 怎么发现的 | 系统检查「每个设置项是否真的被读取」：把 `AppConfig` 的 30 个字段逐个在配置代码之外 grep 了一遍。**29 个都真实生效，只有 `enableHtml` 从来没被读过** —— 也就是说设置页里那个开关，用户拨了什么也不会发生 |
| 需求描述 | 打开后，文档里常见的行内 HTML 标签按格式渲染而不是显示成尖括号原文：`<b>` `<strong>` `<i>` `<em>` `<u>` `<mark>` `<code>` `<kbd>` `<del>` `<s>` `<strike>` `<sub>` `<sup>`，以及 `<br>` / `<br/>` |
| 实现方案 | **不动那条巨大的行内交替正则** —— 本项目已经因为「新增分支导致捕获组编号平移」把行内代码的反向引用打歪过一次。改为在 `parseInline` 收尾处对**文本类型的 span 做一遍后处理**，把成对标签换成既有的 `InlineType`。这样风险被限制在一个独立函数里 |
| 时机很关键 | 后处理放在**转义还原与实体解码之前**，于是 `\<b>` 和 `&lt;b&gt;` 都保持字面 —— 这正是文档表达「我不想让这个标签被解释」的两种写法 |
| 边界（都有测试） | 未闭合标签、不支持的标签（`<div>`）、散文里的 `5 < 6`、大写标签 `<B>`、**标签里再套 markdown**（`<b>a *b* c</b>`）—— 前四类保持原样，最后一类原样输出并注明：那需要真正的 HTML 解析器，猜不如不猜 |
| 预览与导出一致 | 三个导出入口（HTML / PDF / Word）都加了同名开关，菜单里从设置读同一个值传进去。**两处各自解读同一份文件，正是它们会分叉的原因** |
| 设置变更即时生效 | 预览的 AST 缓存以正文为键，开关一变正文没变、缓存不会失效 —— 已在开关变化时主动清缓存，否则要等下一次敲键才更新 |
| 未做 | 块级 HTML（`<div>`、`<table>` 等）仍显示原文；带属性的标签（`<span class=…>`）不解释 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`lib/services/export_service.dart`、`lib/ui/editor/markdown_renderer.dart`、`lib/ui/widgets/app_menu_bar.dart`、`test/services/markdown_parser_test.dart` |
| 验证方式 | **默认关闭时 61 条语料基线对拍零差异**；19 种写法本地探查（开关两种状态各一轮）；6 组仓库测试；十个历史断言脚本全部通过 |

---

### FEAT-008 — 前置元数据支持 TOML(`+++`) 与 JSON(`;;;` / `{}`) 三种格式

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 优先级 | 中 |
| 难易度 | 简单 |
| 状态 | 已实现 |
| 需求来源 | 对齐上游。上游 muya 的 `FRONT_REG` 认四种开分隔符（`---` YAML、`+++` TOML、`;;;` JSON、`{` JSON），我们只认 `---` |
| 需求描述 | 四种写法都识别为前置元数据块，并记住用的是哪种语言 |
| 用户场景 | Hugo 站点的 `.md` 普遍用 `+++` 写 TOML 元数据。在此之前打开这类文件，元数据会渲染成一段字面的 `+++ / title = "x" / +++` 正文 |
| 实现方案 | 把单条 `^---\s*$` 正则换成开分隔符→(闭分隔符, 语言) 的常量表。`{` 用 `}` 收尾，所以开闭分开存而不是假定相同。`FrontMatterNode` 增加 `lang` 字段（`yaml`/`toml`/`json`） |
| 连带修正 | 编辑器的「插入前置元数据」命令原先只检查首行是不是 `---`，文档若以 `+++` 开头会再插一个 `---` 块、变成两个。改为调用新增的 `MarkdownParser.isFrontMatterOpener`；光标落点也从写死的 4 改成按分隔符实际长度算（`{` 只有 1 个字符） |
| 上游对齐 | HTML 导出的 `<pre class="front-matter">` 补上 `data-lang`，与上游 `frontMatterRender` 一致 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`lib/ui/editor/source_editor.dart`、`lib/services/export_service.dart`、`test/services/markdown_parser_test.dart` |
| 验收标准 | 四种开分隔符都产出 `frontMatter` 节点且 `lang` 正确；未闭合时整体降级为正文而不吞内容；`+++` 出现在文档中间不触发；`---` 的既有行为一字不变 |
| 验证方式 | 61 条语料基线对拍**零差异**；10 种写法逐一对照期望；行覆盖不变式（61 条语料 + 8 份真实文档 2194 行）零丢失；块级往返字节一致；新增 5 条测试，断言先用真实源码跑通再落库 |
| 暂未做（明确记录） | 上游还有一个 `frontmatterType` 偏好项，决定「插入前置元数据」命令写出哪种分隔符。加它要动 AppConfig、设置页和 12 种语言的文案，收益有限，本版**不做**；插入仍固定用 `---` |

---

### FEAT-009 — Mermaid 时间线支持 `section` 分组带

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 优先级 | 中 |
| 难易度 | 中等 |
| 状态 | 已实现 |
| 需求来源 | 对齐上游 mermaid。这是解析器源码注释里自己写明的既知缺口：「`section` grouping is not supported」 |
| 这其实还是个 bug | `section 阶段名` 这一行不含冒号，会掉进「无冒号行 → 当作上一个事件的描述」那个分支。也就是说分组名不是被忽略，而是被**当成文字画进了上一个事件框里**。实测 `section 第二阶段` 出现在「成长」这个事件的 description 上 |
| 需求描述 | `section` 行开启一条分组带，其后的时间点归入该带；带子画在时间点标题上方，同带的列共用一种颜色 |
| 实现方案 | `TimelineSection` 增加 `group`（可空）—— 这个类模型的是一个**时间点列**，mermaid 的 `section` 是它上面一层的带子。解析器遇到 `section` 行时先收尾当前时间点、再记下带名。画笔把连续同名的列合成一条带，画圆角底 + 描边 + 居中带名（过长省略号），并把整体下移一条带高。布局引擎同步预留高度 |
| 关键设计取舍 | **只有文档里真的写了 `section` 时才多出这条带**。没写 `section` 的时间线，布局和绘制与改动前逐字节一致 —— 这样这次改动对既有文档零风险 |
| 消除重复 | 带高 34.0 一开始在画笔和布局引擎里各写了一遍。已抽成 `models/timeline.dart` 里的 `timelineGroupBandHeight`，两边共用 |
| 涉及文件 | `lib/ui/editor/mermaid/models/timeline.dart`、`parser/timeline_parser.dart`、`painter/timeline_painter.dart`、`layout/layout_engine.dart`、`test/ui/editor/mermaid/mermaid_parser_test.dart` |
| 验收标准 | `section` 后的时间点带上组名；第一个 `section` 之前的时间点不属于任何带；`section` 行不再污染上一个事件的描述；无 `section` 的时间线行为不变 |
| 验证方式 | 7 种解析形态对照期望（含大小写 `Section`、空段、先有周期后 `section`）；**用桩类型跑真实画笔源码**，把 Canvas 的每条绘制指令录下来，与改动前的画笔逐行对拍 —— 无分组路径 **零差异**；分组路径核对带子几何（3 列 800 宽：第一条带覆盖前两列 x∈[18,526]，第二条覆盖第三列 x∈[530,782]，均在时间点标题 y=70 之上、不重叠）；2065 个截断用例重跑仍零异常；新增 5 条测试 |

---

### FEAT-010 — 预览里可以编辑 Mermaid 图表的源码

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 优先级 | 高 |
| 难易度 | 简单 |
| 状态 | 已实现 |
| 需求来源 | 复核用户点名的第一个问题「无法实现预览页面编辑」时发现的漏网之鱼 |
| 怎么发现的 | 逐个核对 11 种块类型是否都被 `_wrapEditable` 包住 —— 都包了。但接着注意到 Mermaid 图表自己在 `mermaid_renderer.dart` 里也注册了 `onDoubleTap`（打开全屏），**它在手势竞技场里更深、会先胜出**，于是外层的「双击编辑」对图表永远不触发 |
| 现象 | 图表是唯一一种在预览里改不了的块。而它恰恰是最想直接改的那种 |
| 实现方案 | 不动双击（全屏是个有用且好发现的手势），改为在图表工具栏加一个**「编辑源码」**按钮，与已有的全屏 / 另存为 / 复制源码并列。按钮只在预览可编辑时出现（`onSourceChanged != null`），只读预览里不显示 |
| 为什么不改成双击编辑 | 那要把全屏挪到别处，是**用已有习惯换新习惯**；加一个按钮则是纯增量。任务列表那种块此前也是同样的取舍（其复选框要抢双击，代码里已有注释说明），这次的处理与之一致 |
| 新增文案 | `mermaidEditSource`，12 种语言全部给译文（pt_BR 与 pt 相同，走继承不覆写） |
| 涉及文件 | `lib/ui/widgets/mermaid_renderer.dart`、`lib/ui/editor/markdown_renderer.dart`、12 份 `app_*.arb`、11 份 `app_localizations*.dart`、`test/ui/editor/markdown_renderer_edit_test.dart` |
| 验收标准 | 可编辑预览里图表工具栏出现「编辑源码」；点它把图表换成含围栏的源码编辑框；只读预览里不出现该按钮，其余按钮不受影响 |
| 验证方式 | 3 条 widget 测试；`sourceOfBlock` 对围栏块的取源结果实测确认**包含 ```` ``` ```` 两行且往返一致**；l10n 五项一致性检查通过（就是本版新加的那个测试） |
| 顺带修的测试脚手架 | 该测试文件原来的 `MaterialApp` 没有装本地化 delegate，渲染任何读 `AppLocalizations` 的组件都会抛。已补上 |
| 顺带修的溢出风险 | 工具栏原来是 `Spacer` + 一排按钮的 `Row`，加到 4 个按钮后窄预览会 **RenderFlex 溢出**（Row 不会自动换行）。改成 `Expanded` + `Wrap`（右对齐），放不下就换行而不是裁切。既有三按钮的排布不变 |

---

### FEAT-011 — 段落菜单补上「松散列表项」

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 优先级 | 中 |
| 难易度 | 中等 |
| 状态 | 已实现 |
| 需求来源 | 逐项对照上游 `main/menu/templates/paragraph.ts` 的 15 个菜单项。其余 14 项我们都有（`upgradeHeading`/`degradeHeading` 对应 `promoteHeading`/`demoteHeading`，`paragraph` 对应 `toParagraph`），**只差 `looseListItem`** |
| 需求描述 | 把光标所在的列表在「紧凑」与「松散」之间切换。松散列表的项之间有空行，渲染时项与项拉开距离 |
| 用户场景 | 写完一串紧凑的要点后想让它们松开（或反过来），此前只能手工逐行加/删空行 |
| 实现方案 | 纯文本变换 `SourceEditor.toggleLooseList(source, line)`：用解析器定位光标所在的 `ListNode`，取它的行区间，按**首项缩进**找出顶层项的起始行，然后成对地插入/删除空行。方向由已有的 `ListNode.isLoose` 决定 |
| 两个关键判据 | ① **只有与首项同缩进的行才算顶层项** —— 嵌套子项属于它上面那一项，不该被拉开；② 变紧凑时，只丢弃「下一处非空行正好是下一个顶层项」的空行 —— 项内部用来分段的空行要保留 |
| 光标处理 | 切换会在光标行**上方**增删空行，行号会漂。改为按「第几个非空行」定位 —— 变换只增删空行，非空行序列前后不变，所以这个序号能精确指回同一行，列内偏移也保留 |
| 与上游的差异 | 上游是个 checkbox（能显示当前列表是松是紧）。我们的菜单没有随光标更新的状态，所以做成普通菜单项，文案按「执行的动作」写。已在代码注释中说明 |
| 新增文案 | `paragraphLooseList`，12 种语言全部给译文（pt_BR 与 pt 相同走继承） |
| 涉及文件 | `lib/providers/editor_provider.dart`、`lib/ui/editor/source_editor.dart`、`lib/ui/widgets/app_menu_bar.dart`、12 份 `app_*.arb`、11 份 `app_localizations*.dart`、`test/ui/editor/source_editor_prefix_test.dart` |
| 验收标准 | 紧凑列表切换后项间有一个空行、再切回完全复原；有序/无序/任务列表都成立；嵌套子项不被拉开；项内分段的空行不被吃掉；光标不在列表内或列表只有一项时文档不变；无末尾换行的文档切换后仍然没有 |
| 验证方式 | **把仓库里的真实实现抽出来在纯 Dart 下跑**，16 条断言全过（含 7 种形态的「切两次回到原样」）；用解析器复核切换结果：`isLoose` 正确翻转、项数不变、块数不变；l10n 五项一致性检查通过；新增 8 条仓库测试 |

---

### FEAT-012 — 编辑菜单补上「在下方插入段落」与「删除当前段落」

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 优先级 | 中 |
| 难易度 | 中等 |
| 状态 | 已实现 |
| 需求来源 | 上游 `main/menu/actions/edit.ts` 的 `editorCreateParagraph` / `editorDeleteParagraph` |
| 上游语义（读 muya 源码与其单元测试确认） | `insertParagraph` 锚定在**最外层块**上 —— 光标在引用块里时，新段落插在整个引用块之后、位于文档根层，而不是引用块内部；`deleteParagraph` 删掉最外层块，删光时留一个空段落 |
| 实现方案 | 两个纯文本变换，返回「新文本 + 光标应落的行」：<br>`createParagraphBelow` 在块尾后插入空行，**两侧各留一个空行**（否则打进去的字会和上下块连成一段）；<br>`deleteParagraphAt` 连同其后的一个空行一起删（块在文末时改删它前面的空行），删空则返回空文档 |
| 一处按语义调整的行为 | 光标已经停在空行上时，`createParagraphBelow` **原样不动** —— 那里本来就能直接写。第一版没做这个判断，会在两个块之间堆出 4 个空行 |
| 涉及文件 | `lib/providers/editor_provider.dart`、`lib/ui/editor/source_editor.dart`、`lib/ui/widgets/app_menu_bar.dart`、12 份 `app_*.arb`、11 份 `app_localizations*.dart`、`test/ui/editor/source_editor_prefix_test.dart` |
| 验收标准 | 插入后光标落在新的空行上；引用块/列表等多行块整体处理；删除后不留多余空行；删掉唯一的块得到空文档；光标在空行上时两个动作都不改动文档 |
| 验证方式 | 沙盘原型 13 组形态；**本机 `dart analyze --fatal-infos` 通过**；**本机 `flutter test` 跑该文件 30 条全过**；l10n 五项一致性检查通过；新增 9 条测试 |

---

### FEAT-013 — 设置里可以选编辑器正文字体

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 优先级 | 中 |
| 难易度 | 简单 |
| 状态 | 已实现 |
| 需求来源 | 扫描「每个设置项是否有界面入口」时发现的缺口，上游 MarkText 也有字体设置 |
| 现象 | `AppConfig.fontFamily` 一直被读取并应用到编辑器正文（`source_editor.dart` 两处），但设置页只有「代码字体」一行 —— 正文字体永远停在默认的 `monospace`，用户无从更改 |
| 实现方案 | 设置页加一行「正文字体」，与已有的「代码字体」并列，留空则回到 `monospace` |
| 新增文案 | `settingsEditorFontFamily`，12 种语言全部给译文 |
| 涉及文件 | `lib/ui/screens/settings_screen.dart`、12 份 `app_*.arb`、11 份 `app_localizations*.dart` |
| 验证方式 | 本机 `dart analyze --fatal-infos lib` 通过；12 份 arb 逐份复验键集与原有条目未被改动 |

---

### FEAT-014 — 评估：Mermaid 渲染抽成独立开源包的可行性

| 字段 | 内容 |
|------|------|
| 评估日期 | 2026-08-28 |
| 状态 | **已评估，等用户决定是否执行** |
| 需求来源 | 用户原始要求：「mermaid 渲染你看看有没有什么 flutter 开放的组件，如果没有你就仿照 mermaid 的 js 库自己使用 flutter 完全实现一个新的开源项目」 |
| 「完全实现」这部分已完成 | `lib/ui/editor/mermaid/` 共 **73 个文件、21261 行**纯 Dart/Flutter 实现（2026-08-28 删掉 629 行死代码后），覆盖 19 种图表类型（流程图、时序、类、状态、ER、旅程、gitGraph、脑图、饼图、甘特、时间线、看板、雷达、xy、象限、需求、桑基、块图、C4 五种），不依赖 WebView |
| 耦合度实测 | **对外部零依赖** —— 该目录下所有文件只 import 自身与 `package:flutter` / `dart:*`，没有一处引用应用的其它部分 |
| 反向接口面 | 应用只用到 5 个文件：`parser/mermaid_parser.dart`、`widgets/mermaid_diagram.dart`、`models/{node,edge,style}.dart`；符号只有 `MermaidParser.handlesLanguage` / `.parseWithData` / `.supportedTypes` 与 `MermaidDiagram` 组件 |
| 因此抽包需要做的 | ① 新建 `packages/flutter_mermaid/`，把该目录整体 `git mv` 过去；② 写 `pubspec.yaml` 与一个 barrel 导出文件（把上述 5 个文件的公开符号 re-export）；③ 应用改为 path 依赖，导入语句从相对路径换成 `package:flutter_mermaid/...`。**应用逻辑一行不用改** |
| 为什么没有直接做 | 这是一次 72 个文件的结构性移动，会让 git 历史变难追，而对编辑器本身**没有任何功能收益**；用户那句要求的落点是「要有一个能用的 mermaid 渲染」，这一点已经满足。**是否要独立发包是产品决策，留给用户定** |
| 真要做时的验证方式 | 本机 `dart analyze --fatal-infos lib test` + `flutter test` 全量（686 条，27 秒）即可确认没改坏，再推 CI 出三平台构建 |

---

### FEAT-015 — 预览里的可编辑块给出光标与悬停提示

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 需求来源 | 用户反复点名的第一个问题：「无法实现预览页面编辑」 |
| 排查结论 | **功能本身是好的，问题在发现不了。** 本轮把预览编辑从头验了一遍：11 种块级节点全部包了双击编辑；任务列表和 mermaid 图两处刻意排除，都有注释说明（各自有自己的点击目标，套上双击识别器会让它们在手势竞技场里被压死 300ms）；块的源码定位也没问题 —— 拿仓库里 45 篇真实 markdown、2960 个块跑不变量，**类型不符 0、区间重叠 0、空区间 0** |
| 那问题在哪 | 预览里鼠标移过去**没有任何反应**：指针还是箭头，块看起来和印刷品一样死。一个本来可以编辑的预览，读起来就像只能看 |
| 实现方案 | 新增 `PreviewEditableBlock` 包装：`MouseRegion` 给出文本光标（`SystemMouseCursors.text`），悬停时铺一层 `colorSurfaceHover` 的淡色底。悬停状态放在这个组件自己身上，不上提到渲染器 —— 上面一个 setState 会重建整批块，正是 BUG-046 刚修掉的那种浪费 |
| 为什么只加 MouseRegion | 这个文件已经在手势竞技场上栽过两次（双击识别器让图表工具栏和每个任务列表复选框都死了一个双击超时）。**MouseRegion 根本不进竞技场**，所以没有再犯的余地。曾考虑加 Tooltip 说「双击编辑」，但 Tooltip 内部会挂 GestureDetector，风险正是同一类，放弃 |
| 涉及文件 | `code/lib/ui/editor/markdown_renderer.dart`、`code/test/ui/editor/markdown_renderer_edit_test.dart` |
| 验收标准 | 预览模式下鼠标移到段落/标题/表格等块上，指针变成文本光标并出现淡色底；任务列表和 mermaid 图不出现（它们不接受双击编辑）；只读预览（没有 `onSourceChanged`）不出现 |
| 测试上的一个坑 | 第一版断言写的是「找得到文本光标的 MouseRegion」，三条负向测试全挂 —— 预览外面套着 `SelectionArea`，它自己就到处装文本光标的 MouseRegion，那条断言在哪都成立，**什么都没在验证**。改成把包装组件公开出来用 `find.byType` 精确定位才有意义 |

---

### FEAT-016 — 自动补全括号 / 引号 / Markdown 语法可以分别关掉

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 需求来源 | 与上游设置项逐项对照时发现：上游有 71 个设置项，本项目 32 个，其中一部分差异属于「行为已经存在、但被写死、用户无法更改」 |
| 问题 | `source_editor.dart` 里有一张 `_autoPairs` 映射表，把三类东西**无条件**混在一起：括号 `(` `[` `{`、引号 `"` `'`、Markdown 语法 `` ` `` `*` `~`。上游把它们分成 `autoPairBracket` / `autoPairQuote` / `autoPairMarkdownSyntax` 三个开关，**本项目一个都关不掉** |
| 为什么 Markdown 那一类最要紧 | 打 `*` 想开始强调、结果被塞回 `**` 且光标停在中间 —— 这件事有人觉得帮忙、有人觉得打断句子。它不是「对不对」的问题，是偏好问题，所以必须能关 |
| 实现方案 | 一张表拆成三张常量表，加一个按设置拼装的 getter；`AppConfig` 增加三个布尔字段，**默认全部为 true**，也就是保持现有行为不变；设置页加三个开关 |
| 涉及文件 | `code/lib/core/config/app_config.dart`、`code/lib/ui/editor/source_editor.dart`、`code/lib/ui/screens/settings_screen.dart`、`code/lib/core/i18n/l10n/app_*.arb`（12 个文件各 3 键） |
| 验收标准 | 三个开关默认打开，关掉后对应字符不再自动补全；关掉 Markdown 那一项后 `` ` `` `*` `~` 仍可正常输入；旧版本写的配置文件读进来后三项都是打开的 |
| 测试 | `code/test/core/config/auto_pair_config_test.dart`，4 条。其中一条专门守**旧配置**：`AppConfig.fromJson` 缺这三个键时必须回到 true —— 否则老用户升级后行为会突变；另一条守**往返**：能写进去读不回来的设置，会在每次启动后复原，用户就得反复关它 |

---

### FEAT-017 — 主题可以跟随系统深浅色

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 需求来源 | 与上游设置项对照时发现的四个"完全没有实现"之一（另三个是代码块行号、保存时处理末尾换行、侧边栏排序方式）。上游有 `followSystemTheme` + `lightModeTheme` + `darkModeTheme` |
| 问题 | Windows 切到深色模式，编辑器还是浅色，只能进设置手动换。这是日常使用中最容易被注意到的一处缺失 |
| 实现方案 | ① `AppConfig` 增加 `followSystemTheme`（默认 **false**）、`lightModeTheme`、`darkModeTheme`；② `AppTheme.resolveThemeName(...)` 做成**纯函数**；③ `app.dart` 里读 `MediaQuery.platformBrightnessOf(context)` —— 读它本身就建立了依赖，系统切换时这个组件会自动重建，不需要手动监听；④ 设置页顶部加开关 |
| 默认为什么是关的 | 给已有用户打开它，会在下一次启动时无缘无故改变编辑器的样子。这应该是一次主动的选择 |
| 界面上的一个设计 | 主题区本来就分「浅色主题」「深色主题」两组卡片。开了跟随之后，**同一批卡片的含义变了**：点浅色卡是在选"系统浅色时用哪个"，点深色卡是在选"系统深色时用哪个"。所以选中标记也必须跟着变 —— 否则会在一个当前根本没在用的主题上打勾 |
| 关于 `select` 的一个细节 | 主题现在依赖四个字段。`select` 用 `==` 比较，Dart 3 的记录是按值比较的，所以 `(themeName, followSystemTheme, lightModeTheme, darkModeTheme)` 这样一个记录仍然只在真正变化时触发重建 —— 换成 `Set` 或 `List` 就会每次都不相等（这个坑在 BUG-046/047 踩过） |
| 涉及文件 | `code/lib/core/config/app_config.dart`、`code/lib/core/theme/app_theme.dart`、`code/lib/app.dart`、`code/lib/ui/screens/settings_screen.dart`、`code/lib/core/i18n/l10n/app_*.arb`（12 个文件各 2 键） |
| 测试 | `code/test/core/theme/follow_system_theme_test.dart`，5 条。做成纯函数正是为了能测 —— **"系统切到深色"不是靠看屏幕能安排出来的事**。其中两条针对特定失效方式：默认的一对必须真的是一浅一深（系统深色时给个浅色主题反而更刺眼）；旧配置读进来后不能自己开始跟随系统 |

---

### FEAT-018 — 大文件先出首屏再补全

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 需求来源 | 用户反复强调的要求：「轻量级、秒启动、占用低、加载快、**支持大文件**」。这一条此前从没被真正验证过 |
| 实测的问题 | 解析耗时线性于文档大小，约 **600 ms/MB**：0.5 MB → 472 ms，1 MB → 730 ms，2 MB → 1260 ms，5 MB → **3075~4578 ms**。而**渲染是分批的（首批 50 块），解析不是** —— 整篇解析完才画第一帧。打开一个 5 MB 文档，屏幕空白三到四秒 |
| 先确认没有便宜的优化 | 按结构类型分别测 512 KB：引用 895 ms、无序列表 482、纯段落 438、标题 405、内联标记 344、表格 181、图片 128、代码块 96。**没有单点热点** —— 耗时基本正比于块数（0.02~0.04 ms/块），是内联解析和 span 构造的固有成本。所以出路不是优化解析，而是别一次解析整篇 |
| 另一个先排除的猜测 | 源码模式下预览是否也在白解析？不会 —— `_DeferredEditorBuilder` 的 `shouldBuild` 已经保证只构建当前模式的组件 |
| 实现方案 | `MarkdownParser.safePrefix(source)`：文档超过 1500 行时，切出一个**安全前缀**（切点必须是空行，且不在代码围栏或 front matter 内部）。渲染器先解析前缀出首屏，在 post-frame 回调里再解析整篇替换 |
| 为什么是「前缀」而不是「分块」 | **前缀的行号和整篇完全一致**，所以它产出的块自带正确的 `sourceStart`/`sourceEnd`，不需要任何偏移换算 —— 而那两个行号正是预览里双击编辑块所依赖的东西（见 FEAT-015）。改成分块就要处理偏移，一旦算错就会改到错误的行 |
| 实测收益 | 5 MB 文档：整篇解析 4578 ms → **首屏前缀 13 ms**（644 块，占全文 0.2%） |
| 涉及文件 | `code/lib/services/markdown_parser.dart`、`code/lib/ui/editor/markdown_renderer.dart` |
| 测试 | `code/test/services/safe_prefix_test.dart`，5 条。核心那条是**行号一致性**：逐块比对前缀解析与整篇解析的类型和 `sourceStart`/`sourceEnd`，不一致就意味着块编辑会改错行。另有两条守切点（不得切在代码围栏中间、不得切开 front matter），最后一条拿仓库里 45 篇真实文档跑同一个不变量 |

---

### FEAT-019 — 大文件里打字变快

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 需求来源 | FEAT-018 解决的是「打开大文件」，这条是它的另一半：**打开之后能不能编辑** |
| 实测的问题 | 源码模式下每次按键都要重建整棵 TextSpan。按行的增量缓存本来就有，但最后一步是把**所有行的所有 span 逐个 `addAll` 拼成一个扁平列表** —— 1 MB 文档约 3 万行、50 万个 span，每次按键都要重建这个 50 万元素的列表 |
| 实现方案 | `build()` 改为返回**每行一个 `TextSpan`**（其 children 是该行的各段），并把行节点本身也缓存起来。输出列表从 50 万降到 3 万，未改动的行直接复用同一个对象 |
| 配套改动 | 控制器有两处依赖扁平结构，必须一起改，否则高亮会**静默失效**：① 长度校验原来只累加 `child.text`，行节点的 `text` 是 null，累加结果为 0，会触发「回退到无样式」的兜底；② 搜索高亮叠加需要端到端的扁平视图 —— 改成只在有搜索匹配时才调用 `flatten()`，打字路径不付这个代价 |
| 实测收益（21 次采样取中位数） | 256 KB：5.6 → **3.3 ms**；1 MB：28.4 → **18.9 ms** |
| 测量方法上的一次自我纠正 | 最初拿单次采样对比，得出「47.2 → 30 ms」，还一度以为 256 KB 反而变慢了 3 倍。重复三次后发现**基线自己就在 6.4~19.9 之间摆动 3 倍** —— 单次采样的结论全是噪声。改用 21 次采样取中位数才得到上面这组稳定数字。**那个 47 ms 是虚高的，真实基线中位数是 28.4 ms** |
| 已有测试抓到的一个真 bug | 「上一次是最后一行的那行，这次不再是最后一行」—— 它文本没变，被 head 复用，但缓存的节点是按「最后一行」构建的、不带换行符，于是文档里少一个换行。我为此写了注释，却只处理了「新的最后一行」，漏了「旧的最后一行」。**是既有测试抓出来的**，因为它们比对的是「增量结果 vs 全量重算」而不是自己比自己 |
| 涉及文件 | `code/lib/ui/editor/syntax_highlighter.dart`、`code/lib/ui/editor/highlighting_controller.dart`、`code/test/ui/editor/syntax_highlighter_test.dart` |

---

### FEAT-020 — 导出的 HTML 里内嵌图表图片

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 需求来源 | 沿着上游测试对照时发现：上游的静态 HTML 渲染把图表变成惰性占位并用 DOMPurify 清理，我们则是**丢给 CDN 脚本在浏览器里现渲染** |
| 问题 | 导出的 HTML 依赖 **6 个 CDN 资源**（mermaid、KaTeX×3、highlight.js×2）。断网时、或者网络到不了 jsdelivr 时（**大多数公司内网都是这样**），导出件里的图表和公式都是空的。而 **PDF 和 Word 导出一直是把图表画成 PNG 嵌进去的** —— 只有 HTML 没用上这套已有的机制 |
| 为什么这条重要 | 用户点名的问题之一就是「mermaid 渲染有问题」，而他用的是公司机器。**导出的 HTML 打开看不到图，和渲染器本身有没有 bug 是两回事，但用户看到的是同一件事** |
| 实现方案 | ① `exportToHtml` 接收 `mermaidImages`（PDF/Word 一直在传，只有 HTML 没传）；② 有图的图表输出 `<img src="data:image/png;base64,…">`，没画出来的仍然回退到 `<pre class="mermaid">`；③ **只有确实存在画不出来的图表时才引入 mermaid 的 CDN 脚本** —— 全部内嵌了还去连一次网，是白连 |
| 序号对齐 | 图片是按「第几个图表块」编号的，导出侧必须用**同样的数法**：画不出来的图表**仍然占用它的编号**，否则它后面的图表会拿到错的图片。这一点在 PDF 那条路径上早就有注释警告过 |
| 涉及文件 | `code/lib/services/export_service.dart`、`code/lib/ui/widgets/app_menu_bar.dart` |
| 测试 | `code/test/services/html_export_diagram_test.dart`，5 条。其中一条专门用「三个图表、第 2 个画不出来」验证序号不错位；另一条验证没有图表的文档不会白白引入脚本 |
| 仍然依赖 CDN 的部分 | KaTeX（公式）和 highlight.js（代码着色）**没有解决**。公式需要一整套字体和 CSS，代码着色需要语言定义，两者都无法像 PNG 那样简单内嵌。记在这里，不是漏了 |

---

### FEAT-021 — 导出时就把代码着色

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 需求来源 | FEAT-020 把图表内嵌进了导出文件，但当时留了一句「KaTeX 和 highlight.js 没有解决」。这一条解决其中一个 |
| 问题 | 导出的 HTML 只写 `<pre><code>`，靠从 jsdelivr 取 highlight.js 在读者浏览器里现着色。断网或公司内网到不了 CDN 时，代码是没有颜色的；而**文件的 6 个外部依赖里有 2 个只为这件事存在** |
| 关键的一点 | **`package:highlight` 本来就编译进应用了** —— 预览就是用它着色的，而且带着全部 190 种语言（这一点之前一直被当作「体积负担」记着）。在导出时用它，不多花任何已付出的代价，还能让导出文件自带颜色 |
| 实现方案 | ① `highlightCodeToHtml` 用同一个 highlighter 解析代码，把节点树转成 `<span class="hljs-…">`；② `highlightCss` 从**预览用的同一份主题表**生成样式表写进文件 —— 而不是另抄一份颜色出来，那样迟早会和预览不一致；③ 删掉 highlight.js 的脚本与样式表两处 CDN 引用 |
| 外部依赖变化 | **6 → 3**（FEAT-020 去掉 mermaid 的 1 个，这一条再去掉 2 个）。剩下的 3 个都是 KaTeX 的 |
| 涉及文件 | `code/lib/services/export_service.dart` |
| 测试 | `code/test/services/html_export_highlight_test.dart`，6 条。其中两条针对具体的失效方式：**未知语言不能把代码弄丢**（着色失败要退回原文，而不是输出空块）；**代码必须转义而不是注入** —— 着色器走一遍源码、再由我们重建标记，那正是一个没转义的 `<` 会变成标签的地方。最后一条检查生成的是真 CSS 而不是 Dart 的 `Color(0xff…)` |
| 仍未解决 | KaTeX（公式）。它需要一整套字体文件和 CSS，无法像颜色表那样几行生成。要做只能走「把公式也渲染成图片」，那是另一件事 |

---

### FEAT-022 — 没有公式的文档导出后零外部依赖

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 背景 | 导出的 HTML 原本要从 jsdelivr 取 **6 个资源**。FEAT-020 内嵌图表去掉 1 个，FEAT-021 自带代码着色去掉 2 个，剩下 3 个都是 KaTeX 的 |
| 为什么不把公式也画成图片 | 那是能做到「彻底零依赖」的唯一办法，但**行内公式变成位图会糊、放大失真、不能选中**。代价不小，而收益只对「文档里真的有公式」的人成立 |
| 采取的办法 | **只有文档里确实有公式时才引入 KaTeX。**没有公式的文档 —— 也就是大多数文档 —— 导出后**一个外部资源都不取** |
| 检测要覆盖的地方 | 公式块 `$$…$$`，以及段落、标题、引用、**列表项**、**表格单元格**里的行内 `$…$`。表格单元格是最容易漏的一处：它在解析后仍是原始字符串，导出时才交给 `_cellParser` 解析 —— 所以检测**也走同一个解析器**，否则「判断用一种读法、渲染用另一种读法」，迟早对不上 |
| 涉及文件 | `code/lib/services/export_service.dart` |
| 测试 | `code/test/services/html_export_offline_test.dart`，4 条。第一条直接断言「一份带标题、加粗、链接、列表、代码块的普通文档，导出后不向 jsdelivr 取任何东西」；其余三条分别守行内公式、表格单元格里的公式、列表项与标题里的公式 —— 每一处都是「只看公式块就会漏掉」的地方 |
| 现状小结 | 普通文档：**0 个外部依赖**；含图表的文档：0 个（图片已内嵌，除非某张图画不出来）；含公式的文档：3 个（KaTeX） |

---

### FEAT-023 — 代码块内长行可以选择不换行

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 需求来源 | 查「宽内容会不会被裁」时顺带发现的。表格用 Flutter 的 `Table` 会自动换行、代码块用 `Text` 也默认换行，**两者都不会被裁** —— 但代码块的换行是写死的 |
| 问题 | 上游有 `wrapCodeBlocks` 设置（默认 true，和我们一致），**允许关掉**；关掉后代码块横向滚动。我们写死了换行，用户改不了 |
| 为什么对代码尤其要紧 | 换行会让一行代码**丢掉缩进、在标识符中间断开** —— 对散文是对的，对代码恰好相反。这不是「哪个更好」，是看的人当时想要哪个 |
| 实现方案 | `AppConfig.wrapCodeBlocks`（默认 **true**，即现有行为不变）；关掉时 `softWrap: false` 并把代码块包进横向 `SingleChildScrollView` |
| 涉及文件 | `code/lib/core/config/app_config.dart`、`code/lib/ui/editor/markdown_renderer.dart`、`code/lib/ui/screens/settings_screen.dart`、`code/lib/core/i18n/l10n/app_*.arb` |
| 测试 | 3 条，与 FEAT-016 同一套路：默认为开、关掉后能存回来、**旧配置读进来仍然是开的**（否则老用户升级后代码块的样子会突变） |
| 同时发现、尚未实现 | 上游的 `codeBlockLineNumbers` 默认也是 **true**，也就是说**上游预览里的代码块是带行号的，我们完全没有**。没有一并做，是因为行号要和换行后的软换行对齐（一行折成三行时不能出现三个行号），那是独立的一件事 |

---

### FEAT-024 — 只注册常用语言的语法高亮

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 需求来源 | 用户明确要求：「还是把那个 190 种语言优化下吧」 |
| 问题 | `package:highlight/highlight.dart` 的入口第一行就是 `import 'languages/all.dart'` 并 `registerLanguages(allLanguages)` —— **只要 import 它，189 种语言定义全部进包**，AOT 摇树优化不掉，因为那张映射表引用了每一个。我们从来没做过这个选择 |
| 为什么现在做（有了数据） | 上一个构建加了 `--split-debug-info`，把 app.so 从 **13.6 MB 降到 11.4 MB**，而日志里「创建视图」那一段从平均约 2700 ms 降到约 2250 ms。**减 2.2 MB 换来约 450 ms，约 200 ms/MB** —— 快照体积确实是主因，而且新日志证明那 2 秒**全部在 `window.Create()` 内**（插件注册 0 ms、视图建好到第一行 Dart 只有 3~7 ms） |
| 砍掉的是什么 | 体积最大的几个：`isbl` 244 KB（俄罗斯某文档管理系统的内部脚本）、`solidity` 196 KB、`mathematica` 96 KB、`1c` 60 KB、`gml`（GameMaker）、`sqf`（Arma 游戏脚本）、`mel`（Maya 建模）…… 没有一个会出现在 Markdown 的代码围栏里 |
| 保留了什么 | 54 种：Dart、JS/TS、Python、Java、Kotlin、Swift、Objective-C、C++/C#、Go、Rust、Ruby、PHP、Scala、Perl、Lua、R、Shell/Bash、PowerShell、SQL/PgSQL、JSON/YAML/XML、Markdown、CSS/SCSS/Less、HTTP、Dockerfile、Makefile、INI、Nginx、Apache、diff、GraphQL、Groovy、Vim、plaintext、properties、protobuf、Haskell、Elixir、Erlang、Clojure、CoffeeScript、MATLAB、Julia、Fortran、VB.NET、Delphi、Lisp |
| 体积 | 语言定义源码 **1496 KB → 286 KB，去掉 80%** |
| 降级方式 | 未注册的语言**不会报错**：`package:highlight` 内部是 `_getLanguage(language) ?? plaintext`，退回纯文本 —— 代码照样显示，只是没有颜色，和这套机制存在之前对所有语言的表现一样 |
| 一处刻意的设计 | 注册表**只有一份**，预览和 HTML 导出共用（`CodeHighlighting.instance`）。写成两份就会出现「预览有颜色、导出没有」这类差异 —— 本会话已经反复见过同一份清单散在多处的后果 |
| 涉及文件 | `code/lib/ui/editor/code_highlighting.dart`（新增）、`code/lib/ui/editor/markdown_renderer.dart`、`code/lib/services/export_service.dart` |
| 测试 | 3 条。其中一条专门验证**未注册语言不会把代码弄丢**（那才是砍语言唯一可能造成的真实损害）；另一条给列表长度设了上下界 —— 太长就失去意义，太短会让常见语言失去高亮 |

---

### FEAT-025 — 「编辑器最大宽度」现在也作用于源码编辑器

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-28 |
| 需求来源 | 逐项核对「每个设置是否真的被读取」时发现的。39 个配置字段没有一个是死开关，但 `editorMaxWidth` **只被预览读取** |
| 问题 | 设置页里这一项叫「编辑器最大宽度」，设成 800 之后：预览被约束到 800，**源码模式仍然铺满整个窗口**；分屏时左右两半宽度对不上。上游对同一设置的描述是「the maximum **editor area** width」—— 指的是编辑区，不只是预览 |
| 实现方案 | 源码编辑器的整体（行号栏 + 文本区）一起包进 `Center` + `ConstrainedBox`，和预览用同一个值。行号栏必须一起包，否则它会和文本分离 |
| 涉及文件 | `code/lib/ui/editor/source_editor.dart` |

---

## FEAT-026：代码字号可单独设置

| 字段 | 内容 |
|---|---|
| **实现日期** | 2026-08-28 |
| **需求描述** | 代码的字号独立于正文字号，可在设置里调整。对齐上游 `codeFontSize`（默认 14）。 |
| **用户场景** | 把正文调到 20 号看着舒服，代码块却一直停在写死的 14 号——放大了字反而只放大了一半。上游把这两个当成两个愿望分开处理，本项目此前只有「代码字体」没有「代码字号」。 |
| **实现方案** | `AppConfig` 增加 `codeFontSize`（默认 14.0，用既有的 `_parseDouble` 容错解析）；上一条修复刚建的 `_codeStyle()` 入口把字号参数化，围栏代码块、front matter 块、HTML 块三处不再写死 14/13，统一取设置值；设置页新增一行数字输入，写入时 `clamp(8, 48)`——键盘上手滑打出 0 或 400 会让文档没法看且没有明显退路。12 种语言各补一条 `settingsCodeFontSize` 词条。 |
| **涉及文件** | `code/lib/core/config/app_config.dart`、`code/lib/ui/editor/markdown_renderer.dart`、`code/lib/ui/screens/settings_screen.dart`、`code/lib/core/i18n/l10n/app_*.arb`（12 个）、`code/test/ui/editor/code_font_test.dart`、`code/test/core/config/app_config_test.dart` |
| **验收标准** | ① 设为 22 后围栏块、front matter、HTML 块都按 22 绘制，且不再出现写死的 14/13；② 配置能往返序列化，缺键回落 14、脏值（字符串）也回落 14 而不是抛异常；③ 行内代码仍随正文字号按 0.9 缩放——它要坐在一行散文里，也会出现在标题里，跟着周围文字走才对，不跟代码字号。 |

---

## FEAT-027：「在文件中查找」进编辑菜单，搜索面板自动聚焦

| 字段 | 内容 |
|---|---|
| **实现日期** | 2026-08-28 |
| **需求描述** | 全文件夹搜索出现在编辑菜单里（上游 MarkText 放在同一位置），并且打开搜索面板时输入框自动获得焦点。 |
| **用户场景** | 这个功能一直**有**——侧边栏的放大镜逐行搜整个文件夹的内容——但只能靠发现那个图标才用得到，菜单里找不着。而 `editFindInFiles` 这条标签**十二种语言都已经翻译好了，却没有任何代码引用它**：翻译做了，接线没做。 |
| **实现方案** | 编辑菜单在「替换」之后加一项，复用视图菜单里「目录」那一项已有的写法：侧边栏若隐藏则先展开，再把 `sideBarTabProvider` 置为 `SideBarTab.search`。搜索框加 `autofocus: true`——面板由 `AnimatedSwitcher` 按 `ValueKey(selectedTab)` 键控，每次切过去都是新建的子树，所以从图标进和从菜单进都会聚焦。 |
| **涉及文件** | `code/lib/ui/widgets/app_menu_bar.dart`、`code/lib/ui/widgets/side_bar.dart` |
| **验收标准** | ① 编辑 ▸ 在文件中查找 → 侧边栏展开并停在搜索面板，光标已在输入框里；② 点侧边栏放大镜同样自动聚焦。**未写组件测试**：仓库里没有挂载 `AppMenuBar` 或 `SideBar` 的测试脚手架，为一个菜单项搭一套（MenuAnchor + 全套 provider + l10n）代价不成比例，此处如实记录而不是假装覆盖到了。 |

---

## FEAT-028：打印

| 字段 | 内容 |
|---|---|
| **实现日期** | 2026-08-28 |
| **需求描述** | 文件 ▸ 打印，Ctrl+P 唤起系统打印对话框，排版与导出 PDF 完全一致。对齐上游 `file.print`。 |
| **用户场景** | 上游有打印，我们没有——一份写好的文档想打出来，只能先导出 PDF、再去文件管理器里找到它、再用别的程序打开来打印。Ctrl+P 是所有桌面程序都有的动作。 |
| **实现方案** | 加 `printing: ^5.14.3` 依赖（**不是最新的 5.15.0**：它要 `pdf >=3.13`，而 `pdf 3.13` 要 `xml ^7`，与 Word 导出用的 `docx_creator` 锁定的 `xml ^6.6.1` 冲突）。`ExportService.exportToPdf` 里负责排版的部分抽成 `pdfBytes()`，导出与打印共用——走"先写临时 PDF 再打开"那条路会丢掉对话框自己的纸张/范围/份数设置。菜单项放在「导出」旁边（上游的位置）。 |
| **快捷键调整** | `print` 取 **Ctrl+P**，命令面板从 Ctrl+P 改为 **Ctrl+Shift+P**。这与上游一致（`file.print`=Ctrl+P、`view.command-palette`=Ctrl+Shift+P），也与 VS Code 一致——原先把 Ctrl+P 给命令面板是这两者里的异类。 |
| **涉及文件** | `code/pubspec.yaml`、`code/lib/services/export_service.dart`、`code/lib/ui/widgets/app_menu_bar.dart`、`code/lib/services/keybinding_service.dart`、`code/lib/ui/screens/settings_screen.dart`、`code/lib/core/i18n/l10n/app_*.arb`（12 个）、`code/test/services/pdf_bytes_test.dart` —— 新增 |
| **验收标准** | ① Ctrl+P 弹出系统打印对话框，预览内容与导出的 PDF 一致（含 Mermaid 图与本地图片）；② `pdfBytes` 产出以 `%PDF-` 开头、与 `exportToPdf` 写出的文件同等长度（不逐字节比：pdf 包会盖创建时间戳）；③ 空文档也出文件而不是抛异常；④ 设置里的快捷键列表能显示「打印」而不是原始动作名 `print`（仓库里已有测试强制这一点，我一开始正是漏了这步被它抓到）。 |

---

## FEAT-029：Mermaid 的 YAML frontmatter 标题

| 字段 | 内容 |
|---|---|
| **实现日期** | 2026-08-28 |
| **需求描述** | `---\ntitle: 标题\n---` 给任意类型的图表加标题，并真正画出来。 |
| **用户场景** | 这是 mermaid 文档里给图表加标题的通用写法，**流程图更是只能这样加**。此前 frontmatter 只被用来"跳过去找表头行"，标题读都没读，所有类型都丢。而且类图和 ER 图的 `title` 行一直解析进了 `diagram.title`，却**没有任何画笔会画它**。 |
| **实现方案** | ① `MermaidParser` 读 frontmatter 的 `title:`（支持引号、走 `cleanLabel` 所以 `<br/>` 同样有效）；② **解析前把 frontmatter 块剥掉再交给各类型解析器**——此前整块 YAML 会一路传下去，各解析器得自己绕开它，而且 `pie title X` 这种表头行内标题因为"第一行是 `---`"根本找不到；③ 图表自身语法已给标题时不覆盖（`hasOwnTitle`）；④ 组件层绘制 `diagram.title`，但当 payload 自带标题时跳过，避免画笔和组件各画一遍。 |
| **顺带收敛的重复** | 桑基图**自己**也读了一遍 frontmatter（因此它是唯一能这样加标题的类型，且与新实现在引号和 `<br/>` 上处理不同）。现已删除，统一由上游读一次。`_firstContentLine` 改为复用 `_withoutFrontMatter`——此前两者对"未闭合的 `---`"看法不一致：一个当 frontmatter、一个当普通行。 |
| **涉及文件** | `code/lib/ui/editor/mermaid/parser/mermaid_parser.dart`、`sankey_parser.dart`、`code/lib/ui/editor/mermaid/widgets/mermaid_diagram.dart`、`code/test/ui/editor/mermaid/title_test.dart` —— 新增 |
| **验收标准** | ① 流程图/时序图加 frontmatter 标题后显示在图上方；② 引号与 `<br/>` 正确处理；③ 有 `config:` 而无 `title:` 的块不产生标题；④ 饼图自带 `pie title X` 时以它为准且只画一遍；⑤ 未闭合的 `---` 返回 null（与 mermaid 一致，渲染成可诊断的错误）而不是抛异常或画半张图——**这条我起初断言反了，以为该忽略并照常渲染，查了上游语义才改过来**。 |

---
