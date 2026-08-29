# v1.5.2 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-142 | 2026-08-29 | 预览里在第一个块按 ↑ 会把编辑器关掉 | P2 | 已修复 |
| BUG-143 | 2026-08-30 | 预览里相对路径的图片全部显示不出来 | P1 | 已修复 |

---

## BUG-142：预览里在第一个块按 ↑ 会把编辑器关掉

**优先级**：P2　**状态**：已修复　**日期**：2026-08-29

### 现象

（随 FEAT-053 的块间方向键导航一起引入，写测试时当场发现。）
在文档**第一个**块里编辑，光标在首行按 ↑，本意只是移动光标，结果编辑器被关掉，
焦点落空。

### 根因分析

`_moveEditing` 先 `_commitEdit()`（这会把 `_editingNode` 置空、收起编辑器），
再去找邻居块。第一个块上面没有块，于是找不到目标，编辑器就那样关着了。
**顺序错了**：提交是有副作用的，不该在确认"确实有地方可去"之前做。

### 修复方案

新增 `_hasNeighbourBlock(node, down:, wasAppend:)`，在提交**之前**问。
没有邻居就什么都不做，编辑器和光标原地不动。

### 涉及文件

- `code/lib/ui/editor/markdown_renderer.dart`
- `code/test/ui/editor/markdown_renderer_edit_test.dart`

---

## BUG-143：预览里相对路径的图片全部显示不出来

**优先级**：P1　**状态**：已修复　**日期**：2026-08-30

### 现象

`![图](./img/x.png)` —— markdown 里写图片最常见的写法 —— 在预览里显示为红色的
`[图]`，图片根本出不来。写成绝对路径就正常。

### 根因分析

`_buildImageSpan` 把地址原样交给 `File(href)`。Dart 的 `File` 对相对路径是
**相对进程的工作目录**解析的，也就是应用被启动的那个目录，跟文档在哪毫无关系。

而同一件事在本项目里已经有两处做对了：

- `ExportService._resolveImagePath` —— 导出时按文档所在目录解析
- `markdown_renderer._followLink` —— 点击相对**链接**时按文档所在目录解析

**唯独图片这第三处没有跟上。** 后果是导出的 HTML 里图片好好的，预览里却一张都
看不到，这个割裂本身就是线索。

### 修复方案

新增 `_resolveAgainstDocument(href)`：绝对路径原样返回；否则取当前标签页的
`filePath`，用它的目录 `p.join` 后 `normalize`。未保存的文档没有目录可依据，
保持原样（至少绝对路径仍然可用）。

### 顺带查证但**不是**问题的一点

同时怀疑"超宽图片会撑破预览"。实测否定：`WidgetSpan` 的子组件是用段落自身的
约束布局的（2000 宽的子组件放进 400 宽的父级，量出来就是 400），而 `RenderImage`
用 `constrainSizeAndAttemptToPreserveAspectRatio`，所以大图是等比缩小而不是溢出
或压扁。**没有加那个什么都不做的"防御性约束"。**

（第一版为此写的测试是空跑：`Image.file` 在 widget test 里根本不解码，量出来
0x0，断言必然通过。发现后删掉了，并在测试文件里写明了为什么这里没有测试。）

### 涉及文件

- `code/lib/ui/editor/markdown_renderer.dart`
- `code/test/ui/editor/preview_image_path_test.dart`（新增，4 条）
