# V1.5.1 功能需求文档

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-038 | 2026-08-29 | 文件菜单补上"移动到…" | P3 | 低 | 已完成 |
| FEAT-039 | 2026-08-29 | Mermaid treemap-beta 图型渲染 | P2 | 中 | 已完成 |

---

## FEAT-038：文件菜单补上"移动到…"

| 字段 | 内容 |
|------|------|
| **实现日期** | 2026-08-29 |
| **需求描述** | 文件菜单增加"移动到…"，把当前文档移到另一个文件夹。 |
| **背景** | 把源项目 `main/menu/templates/*.ts` 里的命令 id 全量拉出来与本项目菜单逐条对照：<br>· **file**：14 个命令，只差 `file.move-file` 一个；<br>· **paragraph**：20 个，全部覆盖；<br>· **format**：12 个，全部覆盖；<br>· **view**：10 个，`toggle-dev-tools` / `dev-reload` 是 Electron 专有不适用，`toggle-toc` 本项目做成了侧边栏面板（已有，只是没有独立的菜单开关）。<br>也就是说菜单层面的功能对齐只差这一项。 |
| **实现方案** | 目录选择用已有的 `FilePicker.platform.getDirectoryPath()`（与"打开文件夹"同一套），目标路径 = 所选目录 + 原文件名。<br>**移动与重命名走同一条调用**——两者都是"`File.rename` 到一个新路径"。`FileService.moveFile` 原本是 `renameFile` 的纯别名且**零调用者**；一个操作两个名字正是它们日后走岔的方式，所以是**删掉它**而不是把它接上。 |
| **涉及文件** | `code/lib/ui/widgets/app_menu_bar.dart`<br>`code/lib/services/file_service.dart`（删除别名）<br>`code/lib/core/i18n/l10n/app_*.arb`（12 个，新增 `fileMove`） |
| **验收标准** | ① 无打开文档时该项禁用；② 选中目标目录后文档移过去，标签页跟着指向新路径；③ 目标目录已有同名文件时提示"文件名已被占用"且**不覆盖**；④ 选择的就是当前目录时不做任何事。 |


---

## FEAT-039：Mermaid treemap-beta 图型渲染

| 字段 | 内容 |
|------|------|
| **实现日期** | 2026-08-29 |
| **需求描述** | 支持 mermaid 的 `treemap-beta`：以面积表示数值的嵌套矩形图。 |
| **背景** | 至此 mermaid 11 的常用图型只剩 `zenuml` 未实现（它是另一套独立的 DSL，mermaid 自身也是交给外部库渲染的）。 |
| **语法从哪来** | **不是凭印象猜的。** 本机另一个项目的 `node_modules` 里有 mermaid 11.16.0，直接从它的 `diagrams/treemap/types.d.ts` 与编译产物里取出了真实定义：<br>· `INDENTATION` = `[ \t]+`，**其长度**决定嵌套层级；<br>· `STRING2` = `"…"` 或 `'…'`；<br>· `NUMBER2` = `[0-9_.,]+`，**读取时去掉逗号**（所以 `1,024` 是一千零二十四）；<br>· `classDef` 正则 = `classDef\s+([A-Z_a-z]\w+)(?:\s+([^\n\r;]*))?;?`；<br>· 关键字集合 = `treemap`、`treemap-beta`、`:`、`:::`、`,`；<br>· 校验规则：**只允许一个根节点**。 |
| **实现方案** | 与其余 22 种图型同一套八处接线。<br>**布局用 squarified 算法**：按行/列交替切分是最容易写的做法，但会切出长条，而长条的面积**没法用眼睛比较**——那恰恰是这种图唯一的用途。squarified 让每个方块尽量接近正方形，这也是 mermaid、d3 的做法。<br>**节点面积取自其子节点之和**：给一个分组同时写了数值、下面又写了一组不同的数值时，若采信前者，画出来的图各部分填不满它们的整体。 |
| **对多根的处理** | mermaid 判为错误并拒绝。本项目**照画两个**——对"第二个根"来说，什么都不画比画出来更糟。这条差异写在模型注释里。 |
| **涉及文件** | `models/treemap.dart`、`parser/treemap_parser.dart`、`layout/treemap_layout.dart`、`painter/treemap_painter.dart`（均新增）<br>`models/diagram.dart`、`parser/mermaid_parser.dart`、`widgets/mermaid_diagram.dart`、`mermaid.dart`<br>`code/test/ui/editor/mermaid/treemap_test.dart`（新增，15 条） |
| **验收标准** | ① 缩进决定层级；② 分组面积 = 子节点之和；③ `1,024` 这种千分位能解析；④ `:::类名` 与 `classDef` 能读出；⑤ 单双引号都行；⑥ 只有表头时不谎称解析成功；⑦ **面积大的值方块也大**（这是这种图的全部意义）；⑧ 同级方块不重叠、子节点画在父节点内、都不出画布；⑨ **没有方块被压成 6:1 以上的细条**；⑩ 没写数值的节点仍然有方块而不是消失。 |
| **上一轮那条测试当场生效** | 加完枚举值后，BUG-113 新增的"每个 `DiagramType` 都必须在测试表里有样例"立刻变红并指名 `DiagramType.treemap`——它正是为了防止新增图型让后面几条默默少检查一项而写的。 |
