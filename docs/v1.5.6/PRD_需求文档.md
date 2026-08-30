# v1.5.6 功能需求文档

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-065 | 2026-08-31 | 支持 `<ruby>` 注音（日文振假名、中文拼音） | P2 | 中 | 已完成 |
| FEAT-066 | 2026-08-31 | `/` 菜单补齐标题与 Mermaid 图表 | P2 | 低 | 已完成 |

## FEAT-065：支持 `<ruby>` 注音

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-31 |
| 需求描述 | 内联 HTML 支持 `<ruby>漢<rt>hàn</rt></ruby>`，把读音画在文字上方 |
| 用户场景 | 日文振假名（`<ruby>東京<rt>とうきょう</rt></ruby>`）与中文拼音标注都靠它。本项目支持 12 种语言、用户以中文为主，这是实打实的缺口。此前它被转义成尖括号显示，一篇注音文档读起来就是它自己的源码 |
| 如何发现的 | 拿上游 MarkText 的 e2e 当规格核对。`blocks/html-inline.spec.ts` 明确写着"`<ruby>` 是特例，有自己的 `htmlRuby.ts` 渲染器"。逐条比对我们支持的内联标签白名单——`<u> <mark> <sup> <sub> <kbd>` 等都在，唯独没有 `ruby` |
| 实现方案 | 上游是把 `<ruby>` 原样塞进 DOM 交给浏览器画，我们得自己画：① 新增 `InlineType.ruby`，正文存 `text`、读音存 `title`——**两者必须是同一个 span**，拆成两个会在换行处断开、也会被朗读成两个词；② 内联 HTML 正则新增 ruby 分支，并吃掉 `<rp>` 回退括号（那是给画不出 ruby 的阅读器看的，我们画得出）；③ 四个消费方各按能力实现——预览用 `WidgetSpan` 叠一个 `Column`（读音在上、字号减半、基线居中），HTML 直接输出 `<ruby>` 并补 `<rp>` 括号，Word 与 PDF 无注音能力，退化成 `漢(hàn)` 这种词典式写法而不是丢掉 |
| 涉及文件 | `code/lib/services/markdown_parser.dart`、`code/lib/services/export_service.dart`、`code/lib/ui/editor/markdown_renderer.dart`、`code/test/services/ruby_annotation_test.dart`（新增，7 条）、`code/test/ui/editor/nested_link_gesture_test.dart`（+1 条） |
| 验收标准 | 解析成单个 span；句中位置正确；整词振假名；`<rp>` 被吃掉；**关闭内联 HTML 时仍保持字面**（护栏）；HTML 输出带 `<rp>`；读音里的 `&` 被转义。预览那条断言的是**几何**——读音的底边不低于正文顶边、且字号更小；把读音移到下方后确认报警，不是"有两个 Text 就算过" |

新增枚举值时故意先不改任何 switch，让编译器把四处消费方全列出来——比自己回忆可靠。
---

## FEAT-066：`/` 菜单补齐标题与 Mermaid 图表

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-31 |
| 需求描述 | 斜杠快捷插入菜单只有 9 条，上游有 22 条；补上标题 1–6 与 Mermaid 图表 |
| 用户场景 | Mermaid 是本项目的招牌功能，却**没有任何插入入口**——要自己敲 ```` ```mermaid ````、再敲图型首行。标题则是可发现性问题：`##` 只要两键，但刚发现 `/` 的人没理由知道 |
| 如何发现的 | 对照上游 `ui/paragraphQuickInsertMenu/config.ts` 的 22 个条目逐条比对。本项目这份列表的注释原本就写着"顺序与上游一致"，所以补齐是它本来的意图 |
| 实现方案 | 标题复用现成的 `FormatAction.heading1..6` 与带占位符的 `formatHeading(level)`，零新增管线；Mermaid 新增 `FormatAction.mermaidBlock`，插入 ```` ```mermaid / graph TD / A --> B ```` ——**插入即能渲染出图**，且节点名用字母，12 种语言下读起来一样。新增一个 ARB 键，12 个语言文件同步 |
| 涉及文件 | `code/lib/providers/editor_provider.dart`、`code/lib/ui/editor/source_editor.dart`、`code/lib/ui/widgets/slash_menu.dart`、`code/lib/ui/screens/home_screen.dart`、12 个 `.arb`、`code/test/ui/editor/slash_menu_test.dart`（+3 条） |
| 验收标准 | 六个标题都在列表里；Mermaid 可从菜单插入且插入的是能渲染的图（正则取出围栏内容断言非空，不是"有 ```mermaid 就算过"）；`/mermaid`、`/流程图`、`/图表`、`/diagram` 四种输入都能筛到它 |

### 两处判断

**没有照搬上游的顺序。** 上游把六个标题放在最前——它是 WYSIWYG，标题没有别的输入方式。
本项目是源码编辑器，`##` 只要两键。菜单高度 280px，**不滚动只能看到约 5 条**，
六个标题放最前会把表格、代码围栏、图表这些真正难敲的挤出视野。所以标题放末尾，
Mermaid 紧挨代码围栏。这处偏离在代码注释里写明了理由。

**先写错了一句注释。** 我给 Mermaid 那条写的是"高到不用滚动就能看见"，
组件测试点不到它才发现只有约 5 条可见——第 6 条要滚动。注释已改成实话：
靠滚动，或者更快地输入关键词。并补了一条"输入关键词能筛到它"的测试，
那才是真实使用路径。

### 顺带被护栏拦住一次

新增 `FormatAction.mermaidBlock` 后，`command_palette_coverage_test.dart` 立刻报错——
**每个 FormatAction 都必须能从命令面板到达**。这条护栏本身是早先"十七个动作在菜单里
有、在面板里没有"那次留下的，这次正好拦住了同一类遗漏。
