# V1.5.0 功能需求文档

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-035 | 2026-08-29 | Mermaid packet-beta 图型渲染 | P2 | 中 | 已完成 |
| FEAT-036 | 2026-08-29 | Mermaid architecture-beta 图型渲染 | P2 | 高 | 已完成 |

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
| **已知未覆盖** | 无（`architecture-beta` 见 FEAT-036）。 |


---

## FEAT-036：Mermaid architecture-beta 图型渲染

| 字段 | 内容 |
|------|------|
| **实现日期** | 2026-08-29 |
| **需求描述** | 支持 mermaid 的 `architecture-beta` 图型：带图标的服务方块、虚线分组框、按方位连接的编排图。 |
| **用户场景** | 画系统架构、部署拓扑、服务依赖。这是 mermaid 11 里最后一个本项目不支持的常用图型（另两个 `zenuml`、`treemap-beta` 暂不做）。 |
| **实现方案** | 分四层，与其余图型同一套接线：<br>**模型** `models/architecture.dart`：`ArchNode`（service / junction）、`ArchGroup`、`ArchEdge`、`ArchSide`（L/R/T/B，自带网格步长）。<br>**解析** `parser/architecture_parser.dart`：`group id(icon)[Label] in parent`、`service ...`、`junction id in g`、`a:R --> L:b` 四种箭头（`--` `-->` `<--` `<-->`）、端点上的 `{group}` 后缀、`title`、`%%` 注释。图标与标签都可省略，省略标签时用 id 兜底（mermaid 的做法——无标签的方块比标签简陋更糟）。<br>**布局** `layout/architecture_layout.dart`：见下。<br>**画笔** `painter/architecture_painter.dart`：分组框画虚线圆角矩形并在左上写标题；服务方块画图标 + 标签；junction 只画一个小圆点（mermaid 的画法，它是路由拐点不是方块）；连线走**正交折线**而非直线对角线。 |
| **布局是这个图型唯一的难点** | mermaid 的排布**由边决定，而不是由书写顺序决定**：`db:L -- R:server` 不只是"连起来"，它还说了 server 在 db 的**左边**。按书写顺序摆会画出一张和自己的箭头互相矛盾的图。<br>算法：① 每个分组内部各自 BFS 排格子，边上的方位给出步长，目标格被占就**沿同方向继续走**而不是放弃这条约束；② 负坐标整体平移回非负（指向左/上的边会把节点摆到负格，否则画出左上角外）；③ 分组之间用跨组的边同样排一遍，列宽行高取该行列里最大的块，没有跨组边时退化成从左到右一排。<br>**为什么不一次性对整图排格子**：那样两个分组的成员会在网格上交错，画出来的框会互相重叠，读起来像源文件里从没描述过的嵌套关系。 |
| **图标** | mermaid 自带的五个（cloud / database / disk / server / internet）映射到 Material 图标，用 `TextPainter` 直接画字体字形。iconify 图标包不支持，遇到不认识的名字**退化成通用方块图标而不是不画**——不认识的图标该让图少一个字形，不该让它少一个节点。 |
| **涉及文件** | `code/lib/ui/editor/mermaid/models/architecture.dart`（新增）<br>`code/lib/ui/editor/mermaid/parser/architecture_parser.dart`（新增）<br>`code/lib/ui/editor/mermaid/layout/architecture_layout.dart`（新增）<br>`code/lib/ui/editor/mermaid/painter/architecture_painter.dart`（新增）<br>`code/lib/ui/editor/mermaid/models/diagram.dart`<br>`code/lib/ui/editor/mermaid/parser/mermaid_parser.dart`<br>`code/lib/ui/editor/mermaid/widgets/mermaid_diagram.dart`<br>`code/lib/ui/editor/mermaid/mermaid.dart`<br>`code/test/ui/editor/mermaid/architecture_test.dart`（新增，14 条）<br>`code/test/ui/editor/mermaid/mermaid_parser_test.dart`（夹具更新） |
| **验收标准** | ① mermaid 官方文档那个 API 样例渲染出四个服务 + 一个分组框；② `db:L -- R:server` 之后 server 确实在 db 左边、`disk1:T -- B:server` 之后 server 确实在 disk1 上方（**几何断言，不是"没崩"**）；③ 任意两个节点框不重叠；④ 分组框包住它全部成员；⑤ 两个分组的框不重叠；⑥ 无边的节点各占各的格；⑦ 上报的尺寸覆盖所有画出来的东西。 |
| **夹具连带更新** | 三条既有测试拿 `architecture-beta` 当"不支持的图型"的例子，现在它支持了，改用 `zenuml`。同时把 packet 和 architecture 补进"每种已实现的图型都能解析出东西"那张表——那张表也是一份会落后的清单，上一轮加 packet 时就漏了。 |
