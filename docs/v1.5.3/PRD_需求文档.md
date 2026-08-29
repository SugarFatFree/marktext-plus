# v1.5.3 功能需求文档

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-054 | 2026-08-30 | 拼写检查：结论为当前条件下无法实现 | P3 | — | 不实现 |
| FEAT-055 | 2026-08-30 | 删除走系统回收站，确认框区分四种情形 | P1 | 中 | 已完成 |
| FEAT-056 | 2026-08-30 | 重开应用时恢复上次打开的文档 | P1 | 中 | 已完成 |
| FEAT-057 | 2026-08-30 | 导出完整性回归测试（22 种构件） | P2 | 低 | 已完成 |
| FEAT-058 | 2026-08-30 | 图片存取往返的回归测试（三种存储模式） | P2 | 低 | 已完成 |

---

## FEAT-054：拼写检查

| 字段 | 内容 |
|------|------|
| 日期 | 2026-08-30 |
| 状态 | **不实现**，并附证据，避免每轮重新讨论 |
| 对标来源 | 上游 MarkText 的 `options/spellcheck.spec.ts` |

### 上游其实做了什么

只有两条断言：`spellcheckEnabled: true` 时编辑器根节点带 `spellcheck="true"`，
false 时带 `"false"`。实现也只有一行——`domNode.setAttribute('spellcheck', ...)`。

**上游自己既不带词典也不做任何检查**，完全委托给 Chromium 内置的拼写检查器。

### 为什么本项目做不了

逐条查证，不是印象：

1. **Flutter 桌面端没有平台拼写检查服务。**
   `DefaultSpellCheckService` 走 `SpellCheck.initiateSpellCheck` 这个 channel。
   在 Flutter 引擎源码里搜这个方法名，实现只存在于
   `shell/platform/darwin/ios/.../FlutterSpellCheckPlugin.mm` 与
   `shell/platform/android/.../SpellCheckPlugin.java` ——
   **Linux / Windows / macOS 桌面 embedder 都没有。**
   所以"打开平台检查器"这条路在桌面 Flutter 上不存在。

2. **没有可用的系统词典。**
   `/usr/share/hunspell/`、`/usr/share/myspell/dicts/`、`/usr/share/dict/`、
   `/usr/lib/aspell/` 全部为空或不存在。Windows 也不自带。

3. **自带词典拿不到。** 开发环境离线，无法下载任何词库。

### 结论

差的不是工作量，是**拿不到词典**、也**没有可委托的平台能力**。做一个只在
装了 hunspell 的部分 Linux 上生效、Windows 上完全无效的半成品，比不做更糟。

一旦具备条件（能打包一份 MIT/LGPL 词库，或 Flutter 桌面端补上该 channel），
再回来做。**这是对照上游功能清单里唯一仍然缺失的一项。**

---

## FEAT-055：删除走系统回收站，并把确认框说清楚

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-30 |
| 需求描述 | 侧边栏删除文件/文件夹时移到系统回收站而非永久删除；确认框按"是否文件夹"和"能否撤销"分成四种措辞 |
| 对标来源 | 上游 MarkText 走 Electron 的 `shell.trashItem`（`packages/desktop/src/main/app/index.ts:848`），删错了可以还原 |

### 原先的问题

- `FileService.deleteEntity` 是**永久删除**，文件夹还是 `delete(recursive: true)`
  ——整个子树，没有任何找回的余地
- 确认框四种情况**共用一句话**："确定要删除 X 吗？"。一个装着五百篇笔记的文件夹
  即将被彻底销毁时，这句话不足以让人知道自己同意了什么

### 实现方案

`lib/services/trash_service.dart`（新增），按 freedesktop.org 回收站规范实现 Linux：

- 文件移入 `$XDG_DATA_HOME/Trash/files/`，同时在 `info/` 写一份 `.trashinfo`
  记录原路径与删除时间，桌面才能"还原"
- **先写记录再移动**：`files/` 里有文件而没有记录，是桌面既无法还原也无法正确
  命名的孤儿；反过来则无害，移动失败时顺手清掉
- 重名自动让位（`note.md` → `note.1.md`），两次删掉同名文件不会互相覆盖
- **跨文件系统时返回 false 而不是"复制再删原件"**——那是永久删除换了身打扮

回收站根目录做成可注入参数（默认读 `$XDG_DATA_HOME` / `~/.local/share`），
所以测试跑在临时目录上，不会碰到使用者真正的回收站。

### 确认文案

抽出 `deleteConfirmationFor(l10n, name, {isDirectory, canTrash})`，四种组合四句话：

| | 能进回收站 | 不能 |
|---|---|---|
| 文件 | 将"X"移到回收站？ | 确定要删除"X"吗？ |
| 文件夹 | 将"X"及其中所有内容移到回收站？ | 永久删除"X"及其中所有内容？此操作无法撤销。 |

有一条测试断言这四句**互不相同**——两种情况问同一句话，读者就分不出自己同意了什么；
另有一条遍历 12 种语言，确认每种都答得出全部四句且带得上文件名。

### macOS

同日补上：Swift 侧在既有的剪贴板通道上加一个 `moveToTrash`，调
`FileManager.trashItem`。**它的失败回退恰好就是补这个功能之前的行为**
（Dart 侧收到 false 就永久删除），所以最坏情况是"没有变化"，
而 Swift 能否编译由 tag 触发的 `build-macos` 把关。

Swift 那半在本机无法运行，但**Dart 这半的契约可以测**：方法名、路径作为参数
传过去、以及**拒绝时返回 false 而不是抛异常**——抛出去调用方连回退删除都做不了。

### 尚未覆盖：Windows

`TrashService.isAvailable` 在 Windows 上仍为 false，是永久删除——
**但确认框会如实说"无法撤销"**，不会拿回收站的措辞骗人。
后续可补：FFI 调 `SHFileOperationW` 加 `FOF_ALLOWUNDO`。它需要正确摆好
`SHFILEOPSTRUCT` 的内存布局和双 null 结尾的路径串，**摆错可能删掉别的东西**，
而本机无法运行验证——**会删文件的未经测试的代码，风险大于它解决的问题**。

### 涉及文件

- `code/lib/services/trash_service.dart`（新增）
- `code/lib/providers/file_provider.dart`、`code/lib/ui/widgets/side_bar.dart`
- `code/lib/core/i18n/l10n/*.arb`（12 种语言 × 3 个键）
- `code/macos/Runner/AppDelegate.swift`（`moveToTrash`）
- `code/test/services/trash_service_test.dart`（新增，7 条）
- `code/test/ui/widgets/delete_confirmation_test.dart`（新增，5 条）

---

## FEAT-056：重开应用时恢复上次打开的文档

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-30 |
| 需求描述 | 关闭应用时记住打开着的文档和当前页，下次启动自动恢复 |
| 用户场景 | 开着五个文档关掉应用，再打开是一个空窗口——文件都在侧边栏列表里，要一个个点开 |
| 对标来源 | 上游 MarkText 恢复会话（`packages/desktop/src/main/windows/editor.ts` 有 session buffer persistence） |

### 原先的行为

标签页**只**由命令行参数和用户操作创建，没有任何会话恢复。
`sideBarOpenedFiles` 看起来像会话，其实是侧边栏里由使用者自己增删的一份列表——
关闭标签页并不会把它从中移除。

### 实现方案

配置新增 `sessionTabs` 与 `sessionActiveTab`，在**标签页增删和切换时**写入，
而不是退出时写：`dispose` 在退出路径上根本不会执行（窗口被销毁、进程直接结束），
只在关闭时保存的东西等于从来不保存。

启动恢复分两步，为的是"秒启动"：
1. 标签页**立刻**出现（空的、标记加载中）
2. 内容在第一帧之后逐个读入

在窗口显示之前读五个文件，就是在使用者和编辑器之间插进五次文件读取。

### 几个判断

- **命令行打开的文档优先**：双击一个 .md 启动时不恢复会话——那个人是想看这个文件，
  不是想让上周的会话在周围铺开
- **已删除或移走的文件跳过**：给一个不存在的路径开标签页，得到的是读不出内容的
  文档，而它的下一次保存会把这个文件凭空写出来
- **当时在前台的那个若已不在，就用剩下的第一个**，而不是一个都不激活
- **从未保存过的文档不进会话**：它没有可供重开的路径

### 涉及文件

- `code/lib/core/config/app_config.dart`、`code/lib/providers/tab_provider.dart`
- `code/lib/ui/screens/home_screen.dart`
- `code/test/providers/session_restore_test.dart`（新增，7 条）

---

## FEAT-057：导出完整性回归测试

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-30 |
| 需求描述 | 一份包含全部构件的文档，导出为 HTML / PDF / Word，断言 22 种构件都还在 |

### 为什么需要它

这一轮排查导出时做的扫描：三种格式都能产出非空文件，HTML 里 22 种构件逐个核对
全部在场——**没有找到问题**。但这份核对本身值得留下来。

某个构件停止被导出时，产出的文件**仍然合法、仍然能打开**，只是悄悄少了一张表格。
这类损失要等到真正需要那份文档时才会被发现。

### 内容

`test/fixtures/export_everything.md`：front matter、标题、粗体/斜体/行内代码/
删除线/链接、脚注引用与定义、有序/无序/嵌套/任务列表、引用、带对齐的表格（含中文）、
代码块、数学块与行内数学、mermaid、原始 HTML、分隔线。

断言写成"若干候选写法任一命中"——**标记方式允许变，构件活着不允许变**。

### 这条测试不是空跑

写完后**故意把删除线的导出改成原样返回**，测试立刻报出 `['strikethrough']`；
还原后恢复通过。不做这一步，一条永远通过的测试和一条什么都不测的测试无法区分。

### 顺带澄清的一次误报

扫描时"嵌套列表"曾被报为缺失，实为我的匹配模式没考虑 `<li>` 与 `<ul>` 之间的换行。
核对了实际输出（`<li>项目二⏎<ul>⏎<li>嵌套甲</li>…`）才确认它是好的，**没有去修一个
不存在的问题**。测试里保留了三种候选写法。

### 涉及文件

- `code/test/fixtures/export_everything.md`（新增）
- `code/test/services/export_completeness_test.dart`（新增，2 条）

---

## FEAT-058：图片存取往返的回归测试

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-30 |
| 需求描述 | 三种图片存储模式各存一张图，把写出的 markdown 交回解析与解析路径，断言文件能被找到 |

### 为什么需要它

写入侧（决定文件放哪、写什么链接）和读取侧（把链接按文档目录解析回来）
是分别写的两半。**它们已经对不上过一次**——BUG-143：预览把相对路径按进程
工作目录解析，于是所有存在文档旁边的图片都显示成红色 alt 文字。

这轮的排查结论是**干净的**：三种模式（copy / folder / link）端到端都通，
含带空格的文件名（链接会被 `<...>` 包裹，解析器正确剥掉尖括号）；
边界也正常——文档未保存时退回绝对路径、共享目录为空时退回原路径、
同一毫秒连存五张不会互相覆盖。

但"现在是对的"和"以后不会错"是两回事，所以把它固化下来。

### 这条测试不是空跑

写完后**故意去掉 `markdownDestination` 给带空格路径加的尖括号**，
测试立刻报出「copy 写出的 markdown 没有被解析成图片」；还原后恢复通过。

### 涉及文件

- `code/test/services/image_round_trip_test.dart`（新增，5 条）
