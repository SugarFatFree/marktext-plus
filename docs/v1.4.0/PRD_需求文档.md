# V1.4.0 功能需求文档

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-001 | 2026-08-28 | 邮箱地址自动变成可点链接 | 中 | 简单 | 已实现 |
| FEAT-002 | 2026-08-28 | 链接与图片的文字里允许成对方括号 | 中 | 简单 | 已实现 |
| FEAT-003 | 2026-08-28 | 文件在外部被改动时自动重载（仅限无未保存修改） | 高 | 中等 | 已实现 |
| FEAT-004 | 2026-08-28 | Mermaid 新增 block-beta（块图） | 中 | 中等 | 已实现 |
| FEAT-005 | 2026-08-28 | Mermaid 新增 C4 系列（C4Context 等五种） | 中 | 困难 | 已实现 |
| FEAT-006 | 2026-08-28 | 换行符可切换（状态栏点击） | 中 | 简单 | 已实现 |

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
