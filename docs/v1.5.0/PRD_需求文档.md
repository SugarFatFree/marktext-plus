# V1.5.0 功能需求文档

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-035 | 2026-08-29 | Mermaid packet-beta 图型渲染 | P2 | 中 | 已完成 |

---

## FEAT-035：Mermaid packet-beta 图型渲染

| 字段 | 内容 |
|------|------|
| **实现日期** | 2026-08-29 |
| **需求描述** | 支持 mermaid 的 `packet-beta` 图型：按位划分的报文结构图。 |
| **用户场景** | 写协议、帧格式、寄存器位域的文档时，用 packet 图画出每个字段占哪几个 bit。此前这类文档在本应用里只能看到一段灰色的代码块。 |
| **背景** | 源项目 `../marktext` 依赖 `mermaid: ^11.15.0`，`packet-beta` 在其中。用 22 个官方文档样例逐个探测本项目的解析器，20 个通过，只有 `packet-beta` 和 `architecture-beta` 返回 null——也就是退化成纯代码块。 |
| **实现方案** | 纯 Dart，不引 WebView，与其余 20 种图型同一套接线：<br>① `models/packet.dart`：`PacketField {start, end, label}` + `PacketDiagramData`，`rowCount` 由**最后一个 bit** 推出而非字段数（一个字段可以跨行）；<br>② `parser/packet_parser.dart`：支持 `0-15: "Label"`（显式区间）、`0: "Flag"`（单 bit）、`+16: "Label"`（mermaid 11.5 起的相对宽度，从上一字段末尾接着数）、`title`、`%%` 注释、带引号与不带引号的标签；<br>③ `painter/packet_painter.dart`：每行 32 bit 的网格，字段跨行时**按行拆成多个矩形**（mermaid 的画法；画成一个横穿出界的长条会丢掉位对齐，而位对齐正是这种图的全部意义），行上方标出首尾 bit 号；<br>④ `DiagramType.packet`、`MermaidParseResult.packetData`、`_detectDiagramType`、`_typeLabel`、组件的尺寸分支与画笔分支。 |
| **健壮性** | 两处畸形输入不按字面执行：`15-0`（区间写反）会得到负宽度矩形，`+0`（零宽）会让游标停在原地、后面每个字段叠在同一批 bit 上——两者都直接丢弃该行。 |
| **顺带修复** | `mermaid.dart` 这个 barrel 只导出了 20 种图型里的 11 种（radar / xy / class / er / journey / gitgraph / mindmap / quadrant / requirement / state 的 model、parser、painter 都不在其中）。补全为全部导出，否则从 barrel 引入的代码根本叫不出这些类型的名字。 |
| **涉及文件** | `code/lib/ui/editor/mermaid/models/packet.dart`（新增）<br>`code/lib/ui/editor/mermaid/parser/packet_parser.dart`（新增）<br>`code/lib/ui/editor/mermaid/painter/packet_painter.dart`（新增）<br>`code/lib/ui/editor/mermaid/models/diagram.dart`<br>`code/lib/ui/editor/mermaid/parser/mermaid_parser.dart`<br>`code/lib/ui/editor/mermaid/widgets/mermaid_diagram.dart`<br>`code/lib/ui/editor/mermaid/mermaid.dart`<br>`code/test/ui/editor/mermaid/packet_parser_test.dart`（新增，10 条）<br>`code/test/ui/editor/mermaid/packet_render_test.dart`（新增，3 条） |
| **验收标准** | ① 官方 TCP header 样例渲染成两行位域网格；② 跨行字段按行拆开且位对齐；③ `+N` 相对宽度接续正确；④ 标题只画一次（画笔画了组件就不画）；⑤ 只有表头没有字段时不谎称解析成功，退回代码块。 |
| **已知未覆盖** | `architecture-beta` 仍未实现（需要图标集与分组嵌套布局），留待后续版本。 |
