# V1.5.0 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-099 | 2026-08-29 | 文件夹搜索会把超大文件整个读进内存 | P2 | 已修复 |
| BUG-100 | 2026-08-29 | 拖放自带一份私有扩展名清单，且拖入不支持的文件毫无反应 | P2 | 已修复 |
| BUG-101 | 2026-08-29 | 引用/列表里的块行号从 0 开始，预览编辑会覆盖文档开头 | P0 | 已修复 |
| BUG-102 | 2026-08-29 | mermaid barrel 只导出 20 种图型里的 11 种 | P3 | 已修复 |

---

## BUG-099：文件夹搜索会把超大文件整个读进内存

### 现象

侧边栏的全文件夹搜索**对文件大小没有任何上限**：`readAsBytes` 读进整个文件，
再 `split('\n')` 切成行数组。可搜索的扩展名里包含 `.txt`，所以文件夹里只要有
一个大日志或导出文件，一次搜索就会吃掉与它同样大的内存，并在扫描它的整段时间
里卡住。

### 修复方案

超过 2 MiB 的文件不读——但**不静默跳过**。跳过的数量会显示在结果区，
与既有的"结果数封顶时加 `+`"并列。那行的注释写得很好："说 500 条却其实更多，
是对搜索范围的一次静悄悄的谎报"——**没被读过的文件，和读过但没匹配的文件，
不是一回事**，同样不该混为一谈。新增 `searchTooLarge` 词条，12 种语言。

### 同轮核实为正确的部分

这次搜索实现比预期结实，以下都已具备：跳过隐藏目录与 `node_modules`/`build`
等；只搜 markdown 系扩展名；异步列目录（注释记着 `listSync` 曾冻结窗口）；
结果封顶 500 并如实加 `+`；用 generation 取消上一次搜索；**走共享解码**——
这意味着 FEAT-033 之后 GBK 文档也能被搜到了。

与上游相比仍缺的是可配置项（`searchExclusions`、`searchMaxFileSize`、
`searchIncludeHidden`、`searchNoIgnore`），本次只把最要紧的上限做成固定值，
没有引入新设置。

### 涉及文件

- `code/lib/ui/widgets/side_bar.dart`
- `code/lib/core/i18n/l10n/app_*.arb`（12 个）


---

## BUG-100：拖放自带一份私有扩展名清单，且拖入不支持的文件毫无反应

### 现象

把 `.mmd`、`.mdown`、`.mdtxt`、`.mdtext` 文件拖到窗口上**什么都不会发生**——
而这四种扩展名在菜单打开、命令行参数、侧边栏里都是能正常打开的。

同时，拖入任何不支持的文件（`.pdf`、`.png` 等）同样毫无反应：窗口静静吞掉了
拖放动作，看上去像是程序卡住或者拖放功能坏了。

### 根因分析

`home_screen.dart` 的 `_handleDrop` **自带一份私有的扩展名清单**：

```dart
const allowedExtensions = {'.md', '.markdown', '.txt'};
```

项目里早就有统一的 `FileUtils.markdownExtensionsWithDot`（七种），
`main.dart` 的命令行参数处理和 `side_bar.dart` 的文件树都在用它。
之前有一次提交专门做过"扩展名清单从七处合成一处"，拖放是漏网的最后一处——
它只有七种里的三种。

第二个问题是不匹配时直接 `continue`，既不计数也不提示。

### 修复方案

1. 改用共享的 `FileUtils.markdownExtensionsWithDot`；
2. 被拒绝的文件**计数**，循环结束后用 SnackBar 提示
   （新增 12 语言的 `dropNotMarkdown` 文案）——静静吞掉拖放的窗口看起来就是坏的。

新增 `test/utils/drop_extensions_test.dart`，其中一条测试直接在源码里检查
三个入口文件都不再出现私有清单字面量：**要保证的是"只有一份清单"，
而不是"两份清单今天恰好一致"。**

### 涉及文件

- `code/lib/ui/screens/home_screen.dart`
- `code/lib/core/i18n/l10n/app_*.arb`（12 个）
- `code/test/utils/drop_extensions_test.dart`（新增）


---

## BUG-101：引用/列表里的块行号从 0 开始，预览编辑会覆盖文档开头

### 现象

文档里有这么一段：

```markdown
intro paragraph

> ```mermaid
> graph TD
> A-->B
> ```
```

引用里的 mermaid 图正常渲染，但图上的**"编辑源码"按钮打开的是文档开头的
`intro paragraph`**；改完提交，**改动写到文档的前四行上，原来的开头被覆盖掉**
——这是数据丢失。

（图表工具栏上的"复制源码"按钮取的是 `node.code`，也就是已经剥掉 `>` 的解析
结果，不走行号，一直是对的。）

列表项下带的块（编号步骤下面的代码围栏、第二段、引用）完全一样。

### 根因分析

`sourceStart` / `sourceEnd` 是**文档的绝对行号**，`sourceOfBlock` 和
`replaceBlock` 都按它取行、换行。

但嵌套内容是**从文档里抠出来另行解析**的：

- 引用：每行剥掉一个 `>` 后 `parse(content, quoteDepth: quoteDepth + 1)`
- 列表项：`parse(_dedent(block.skip(blank + 1)))`

这两次 `parse` 拿到的是一段独立文本，行号自然**从 0 开始数**。于是引用里第一个
块的 `sourceStart` 是 0——指向的是文档的第一行。

探针实测：上面那个文档里，mermaid 块拿到的是 `start=0 end=4`，
`sourceOfBlock` 返回 `intro paragraph |  | > ```mermaid | > graph TD`。

### 修复方案

嵌套解析完成后，把整棵子树的行号平移回文档坐标（`_shiftSpans`，沿用
`MarkdownParser.walk` 遍历，所以嵌套的嵌套也一并平移）：

- **引用**：偏移量 = 引用起始行 + `.trim()` 掉的前导空行数。
  `content` 是 `bqLines.join('\n').trim()`，前导空行被 trim 掉了，
  不补这几行会整体偏上。
- **列表项**：偏移量 = 该 item 块的起始行 + `blank + 1`。
  item 块的起始行**不能靠累加各块长度推出来**——两个 item 之间的空行
  不属于任何一块，所以 `_collectListItems` 改为额外返回每块的起始行。

### 涉及文件

- `code/lib/services/markdown_parser.dart`
- `code/test/services/nested_block_spans_test.dart`（新增，5 条）


---

## BUG-102：mermaid barrel 只导出 20 种图型里的 11 种

### 现象

`lib/ui/editor/mermaid/mermaid.dart` 是这个模块对外的入口文件，但它只
`export` 了 11 种图型的 model / parser / painter。radar、xy、class、er、
journey、gitGraph、mindmap、quadrant、requirement、state 一个都不在里面——
从这个 barrel 引入的代码**根本叫不出这些类型的名字**。

发现方式：给 packet 写测试时 `import 'mermaid.dart'` 之后 `PacketDiagramData`
报"isn't a type"，才注意到不是漏了 packet 一个，而是漏了九个。

### 根因分析

又是"一份清单没跟上"。每加一种图型要动的地方有七处（枚举、模型、解析器、
画笔、`_detectDiagramType`、`_typeLabel`、组件的尺寸与画笔分支），barrel 是
第八处，也是唯一一处**漏了不会报错**的——因为模块内部都用相对路径互相引用，
只有从外面按 barrel 引入时才会发现。

### 修复方案

改为按目录枚举全量导出（models / painter / parser 三个目录下的全部文件），
新增图型不再需要记得回来补一行。

### 涉及文件

- `code/lib/ui/editor/mermaid/mermaid.dart`
