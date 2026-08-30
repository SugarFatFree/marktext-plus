# v1.5.6 功能需求文档

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-065 | 2026-08-31 | 支持 `<ruby>` 注音（日文振假名、中文拼音） | P2 | 中 | 已完成 |

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
