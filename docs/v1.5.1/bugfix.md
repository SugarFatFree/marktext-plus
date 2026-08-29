# V1.5.1 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-106 | 2026-08-29 | 发布清单列了两个从没被产出的 macOS x64 文件，且通用二进制被命名为 arm64 | P2 | 已修复 |
| BUG-107 | 2026-08-29 | 菜单里的"重命名"绕开了守卫，会静默覆盖同名文件 | P1 | 已修复 |
| BUG-108 | 2026-08-29 | 文件树列出所有文件，点开二进制会当文本打开并可能被写坏 | P1 | 已修复 |
| BUG-109 | 2026-08-29 | 快捷键文件非原子写，损坏时自定义快捷键被无声重置且原文件被覆盖 | P2 | 已修复 |
| BUG-110 | 2026-08-29 | 大文档打字时窗口冻结数秒：整篇解析与整篇大纲都在 UI isolate 上跑 | P1 | 已修复 |
| BUG-111 | 2026-08-29 | 大文档每次移动光标都全文扫描两遍，只为算行号列号 | P2 | 已修复 |
| BUG-112 | 2026-08-29 | 大文档开着查找栏时每次击键全文重扫，且为十万处命中铺高亮 | P2 | 已修复 |
| BUG-113 | 2026-08-29 | 支持类型清单漏了四种写法，应用对外宣称不支持自己已支持的图 | P2 | 已修复 |
| BUG-114 | 2026-08-29 | 流程图双圆节点标签带括号、隐形连线被整条丢弃 | P2 | 已修复 |
| BUG-115 | 2026-08-29 | 预览模式完全不读字号与行高设置，缩放对预览无效（issue #4） | P1 | 已修复 |

---

## BUG-106：发布清单列了两个从没被产出的 macOS x64 文件，且通用二进制被命名为 arm64

### 现象

v1.5.0 发行版页面上的 macOS 产物只有 `macos-arm64.zip` 和 `macos-arm64.dmg`。
一个用 Intel Mac 的读者看到这个页面，合理的结论是**这个项目没有给他的构建**。

而 `release.yml` 的发布步骤里**明明列着** `macos-x64.zip` 与 `macos-x64.dmg`
两行——它们从来没有被任何 job 产出过。

### 根因分析

两个独立的问题叠在一起：

1. **幻影清单**。`softprops/action-gh-release` 找不到某个文件时**跳过它并继续
   报成功**。所以这两行在构建期不花任何代价，代价全在下载期：发行版页面上根本
   没有这个资产，而工作流一路绿灯。这已经这样发了好几个版本。

2. **命名把通用二进制说成了单架构**。`macos/Runner.xcodeproj` 的 Release 配置
   **没有设 `ONLY_ACTIVE_ARCH`**（只有 Debug 设了 `YES`），所以 Xcode 产出的
   `.app` 同时含 x86_64 与 arm64。

   这不是推断——把 v1.5.0 已发布的那个 zip 下下来，读 `Contents/MacOS/` 里
   可执行文件的 Mach-O 头：`0xcafebabe` 开头的 fat 二进制，两个架构分别是
   `x86_64` 和 `arm64`。**Intel Mac 一直是被覆盖的，只是名字没这么说。**

### 修复方案

- 三处产物名 `macos-arm64` 改为 `macos-universal`（zip、dmg、artifact 名）；
- 删掉发布清单里的两行幻影 x64。

新增 `test/utils/release_assets_test.dart` 三条：

- **发布清单里的每个文件都必须有 job 真的产出它**。Linux 的产物名是用
  `${{ matrix.arch }}` 之类拼的，所以测试先把占位符归一化成 `<arch>`
  再按 matrix 声明的值展开——否则字面比较会把每一个 Linux 产物都误判成幻影。
- 三个平台都必须有产物；
- macOS 产物不得用单个架构名命名。

**反向验证过**：把 `macos-x64.zip` 那行注回去，这两条测试立刻变红。

### 涉及文件

- `.github/workflows/release.yml`
- `code/test/utils/release_assets_test.dart`（新增，3 条）


---

## BUG-107：菜单里的"重命名"绕开了守卫，会静默覆盖同名文件

### 现象

在**文件 → 重命名**里把当前文档改成一个已经存在的文件名，那个文件**被无声
销毁**——没有确认框、没有撤销、屏幕上没有任何提示。

同一个操作在**侧边栏右键重命名**里是安全的，会提示"文件名已被占用"。

### 根因分析

`FileService.renameFile` 早就长出了守卫，它自己的注释写得很清楚：

> `File.rename` replaces the destination without a word, so renaming a note to
> a name already in use destroyed the note that had it — no prompt, no undo,
> nothing on screen to say it had happened.

侧边栏走 `fileProvider.renameNode` → `FileService.renameFile`，拿到了守卫，
并且在 `_runFileOp` 里接住 `PathExistsException` 弹提示。

**菜单没有走这条路**。`app_menu_bar.dart:247` 自己写了一行
`await File(oldPath).rename(newPath);`——同一个操作的第二份实现，守卫加上去的
时候这一份没跟上。全项目直接调 `.rename(` 的地方一共六处，其余五处都在
service 与 config 内部，只有这一处在 UI 层。

### 修复方案

菜单改走 `fileProvider.renameNode`，并接住 `PathExistsException` 与其他异常
分别提示（复用侧边栏已有的 `fileNameTaken` / `fileOperationFailed` 文案）。

新增 `test/services/menu_rename_guard_test.dart`，其中一条**直接在源码里检查
四个 UI 文件都不再出现 `File(...).rename(`**——要保证的是"只有一份实现"，
而不是"两份实现今天恰好一致"。

### 涉及文件

- `code/lib/ui/widgets/app_menu_bar.dart`
- `code/test/services/menu_rename_guard_test.dart`（新增，3 条）


---

## BUG-108：文件树列出所有文件，点开二进制会当文本打开并可能被写坏

### 现象

在侧边栏打开一个项目文件夹，树里列着 `.git`、`node_modules`、`build`、
`.DS_Store`、图片、PDF——本编辑器一个都打不开。

而且点其中任何一个，**它会被当作文本打开**：`_openFileInTab` 不检查扩展名，
文件内容经 `FileEncoding.decode` 变成一堆乱码填进标签页。到这一步只是难看，
但**再往前一步就是数据丢失**——只要有一次误触键盘，自动保存（默认开启的设置）
就会把这堆乱码写回原文件，图片或 PDF 就此损坏。

### 根因分析

`FileService.listDirectory` 把目录里的一切都变成 `FileNode`，只排除了
保存中的临时文件。没有扩展名过滤，也没有目录排除。

对照源项目 `main/filesystem/watcher.ts` 的 `ignored` 回调：

```ts
if (fileInfo.isDirectory()) { return false }
return !hasMarkdownExtension(pathname)
```

**目录和 markdown 文件，别的都不显示**，另外硬排除 `node_modules` 与 `.asar`。

同时这里还是一处"清单只有一份副本"的老问题：`side_bar.dart` 里有一份
`_skippedDirectories`（node_modules / vendor / build / dist / target）
**只用于搜索**。于是同一个文件夹，**搜索会正确跳过 `node_modules`，
而文件树把它整个列出来**。

### 修复方案

- `listDirectory` 只返回目录与 markdown 文件（走共享的
  `FileUtils.isMarkdownFile`，不是第 N 份扩展名清单）；
- 排除目录清单从 `side_bar.dart` 移到 `FileUtils.skippedDirectories`，
  加上 `isSkippedDirectory()`（含隐藏目录——单是 `.git` 就有上千个文件），
  文件树与搜索共用；
- **以点开头的 markdown 文件仍然显示**：隐藏点开头的*目录*是为了 `.git`，
  而某人自己命名的 `.todo.md` 仍然是他的笔记。

### 涉及文件

- `code/lib/services/file_service.dart`
- `code/lib/utils/file_utils.dart`
- `code/lib/ui/widgets/side_bar.dart`
- `code/test/services/file_tree_filter_test.dart`（新增，6 条）


---

## BUG-109：快捷键文件非原子写，损坏时自定义快捷键被无声重置且原文件被覆盖

### 现象

自定义过的快捷键会在某次启动后**全部变回默认值**，没有任何提示，
而且**存着它们的那个文件也找不回来了**——下一次改任何一个快捷键就把它覆盖掉。

### 根因分析

排查方式是扫全项目所有绕开 `FileService` 的写盘调用。十二处里十一处都合理
（导出走用户选定的路径、图片有 `_unusedPath` 守卫、诊断日志），只有
`keybinding_service.dart` 这一处是问题：

1. **非原子写**。`file.writeAsString(...)` 直接就地写。进程在写到一半时被杀
   （关机、崩溃、任务管理器），留下的是一个被截断的文件。

2. **截断的文件解析不了，于是被无声吞掉**：

   ```dart
   } catch (_) {
     _keybindings = Map.from(defaultKeybindings);
   }
   ```

   不提示、不保留原文件。下一次 `_save()` 直接覆盖，用户自定义的东西**彻底
   消失**。

而 `ConfigService`（设置文件）**早就修过同样的两个问题**：写临时文件再
`rename`（原子），读不动就 `rename` 成 `.corrupt` 留着。同一套行为的两份实现，
一份跟上了，一份没有。

### 修复方案

抽出 `lib/core/config/json_store.dart`，把"读、原子写、损坏隔离"做成**一份**
实现，`ConfigService` 与 `KeybindingService` 都改用它——**不是把配置那份复制
到快捷键这边**，那样只是把两份变两份新的。下一次这类修复落到哪一边，另一边
自动都有。

`ConfigService` 保留了一个自己的分支：JSON 能解析但 `AppConfig.fromJson` 抛错
（字段形状不对）。这种情况文件仍然在原地，注释里写明了。

### 涉及文件

- `code/lib/core/config/json_store.dart`（新增）
- `code/lib/core/config/config_service.dart`
- `code/lib/services/keybinding_service.dart`
- `code/test/core/config/json_store_test.dart`（新增，7 条）


---

## BUG-110：大文档打字时窗口冻结数秒：整篇解析与整篇大纲都在 UI isolate 上跑

### 现象

打开一个几 MB 的 markdown 文档，**打字停顿一下窗口就卡住好几秒**。文档越大越明显。

### 实测数据

先量再改。生成结构均匀的文档，在本机测各环节耗时：

| 文档大小 | `countWords` | `parse` | `headingOutline` | `safePrefix` |
|---|---|---|---|---|
| 1 MB | 18 ms | 909 ms | 90 ms | 12 ms |
| 5 MB | 64 ms | **3537 ms** | **402 ms** | 33 ms |

字数统计已有 300 ms 防抖，64 ms 可以接受。问题在另外两处。

### 根因分析

**其一：整篇解析在 UI isolate 上。** 预览对大文档采用两段式——先用
`safePrefix` 解析开头保证首帧，再在下一帧 `_finishParse()` 解析整篇。但这第二
次解析是**同步**的，5 MB 就是 3.5 秒的窗口无响应。而且它由内容变化触发：
打字时 `_finishParse` 会因为文本已变而提前退出（便宜），**一旦停下来，
那 3.5 秒就来了**。这正是"打字停顿一下就卡住"的由来。

**其二：目录面板在 `build()` 里算整篇大纲。** `_buildTocPanel` 直接调
`MarkdownParser.headingOutline(content)`，而它 `watch` 的是 activeTab。
于是**每一次击键**都要付 402 ms——面板甚至不需要展开，只要被 build 到。

**其三（顺带）：预览为了标题行号又把全文扫了第二遍。** `_findHeadingLines`
再调一次 `headingOutline`，同样 402 ms，同样在 build 里。

### 修复方案

**整篇解析挪到另一个 isolate。** 这可行是因为 `markdown_parser.dart` 只依赖
`dart:convert` 与 `dart:math`，AST 全是普通对象。

值不值先量过了——把"解析但不回传 AST"和"解析并回传"分开测：

| 文档 | 解析（不回传） | 解析+回传 | **回传本身** |
|---|---|---|---|
| 1 MB | 841 ms | 808 ms | ~0 |
| 5 MB | 3432 ms | 3572 ms | **约 140 ms** |

只有回传那 140 ms 会阻塞 UI。**3.5 秒的冻结变成 0.14 秒。** 小文档根本走不到
这里（`safePrefix` 对小文档返回 null，一次解析到底）。isolate 起不来时退回本
isolate 解析——起不了 isolate 不是让文档永远只显示一半的理由。

**标题行号改为直接从 AST 取**（`HeadingNode.sourceStart + 1`），不再扫第二遍。
这不只是省掉 402 ms：那第二遍本身就是"什么算标题"的第二份实现，
**它和第一份已经不一致过两次**（front matter 里的 `#`、setext 标题），
每次都让第一处分歧之后的每个滚动目标都跳错行。取自实际画出来的节点，
两者不可能不一致。

**目录面板改用 `outlineProvider`**，与字数统计同一个形状：300 ms 防抖，
算一次给所有人用。

### 涉及文件

- `code/lib/ui/editor/markdown_renderer.dart`
- `code/lib/providers/outline_provider.dart`（新增）
- `code/lib/ui/widgets/side_bar.dart`
- `code/test/services/large_document_cost_test.dart`（新增，6 条）


---

## BUG-111：大文档每次移动光标都全文扫描两遍，只为算行号列号

### 现象

BUG-110 解决了"停顿一下冻结几秒"。剩下的是持续的手感问题：大文档里
**光标每移动一格**都要卡一下，按住方向键尤其明显。

### 实测数据（5 MB 文档，29 万行）

| 操作 | 耗时 | 触发频率 |
|---|---|---|
| `text.substring(0, offset).split('\n')`（算光标行列） | **61 ms** | 每次光标移动、每次击键 |
| `'\n'.allMatches(text).length`（行号栏取行数） | **33 ms** | 每次 build——而 build 会 watch 光标行 |

也就是**每移动一格光标约 94 ms**，还外加一个 29 万个字符串的列表分配——
只为读出两个数字。

### 根因分析

`_onSelectionChanged` 里：

```dart
final textBefore = text.substring(0, offset);   // 复制至多 5 MB
final lines = textBefore.split('\n');           // 分配 29 万个字符串
final line = lines.length - 1;
final col = lines.last.length;
```

而 `_getLineCount()` 在 `build()` 里数一遍换行符；`build()` 又
`watch` 了 `cursorLine`——于是光标一动就再扫一遍。两处各自全文扫描，
且都是**每次光标移动**都做。

### 修复方案

建一份**行首偏移索引**，每次编辑建一次，之后二分查找：

| 做法 | 耗时 |
|---|---|
| 建索引（每次编辑一次） | 46 ms |
| 二分查找一次 | **0.42 µs** |

行数直接取索引长度，行号栏那一遍也没了。**移动光标的代价从 94 ms 变成基本为零。**

缓存用 `identical` 而不是 `==` 判断是否失效：对两个 5 MB 字符串做相等比较，
本身就会把省下的时间还回去一大半。控制器在文本未变时返回同一个实例；
万一是内容相同的另一个实例，代价也只是多建一次索引。

### 涉及文件

- `code/lib/ui/editor/source_editor.dart`
- `code/test/ui/editor/cursor_position_test.dart`（新增，5 条）

其中一条测试**逐个 offset 把新算法与被它替换掉的朴素算法对照**——
包括空行、文档末尾、换行符正后方这些边界。


---

## BUG-112：大文档开着查找栏时每次击键全文重扫，且为十万处命中铺高亮

### 实测数据（5 MB 文档）

**其一，重扫**：

| 查询 | 命中 | 耗时 |
|---|---|---|
| `zzz-not-present` | 0 | 44 ms |
| `Section` | 97 502 | 48 ms |
| 正则 `Section \d+` | 97 502 | 66 ms |

**只要查找栏开着**，每一次击键都付这 40–66 ms。

**其二，高亮**：

| 命中数 | `buildTextSpan` | 生成的 span 子节点 |
|---|---|---|
| 0（挂起高亮） | 2 ms | — |
| 1 111 | 13 ms | 2 223 |
| 97 502 | **133 ms** | **195 005** |

而 `buildTextSpan` 在**每次重建**时调用——**光标动一格就是一次重建**。
133 ms 还只是构造 span 树的时间，Flutter 之后还要把这 19.5 万个 span 排版一遍。

### 修复方案

**重扫改为 250 ms 防抖。** 这样做是安全的，因为**依赖匹配列表的地方本来就
不信任它**：两条替换路径都先比较 `text != _scannedText`，不一致就当场重扫并
返回。让列表落后于打字，代价只是高亮晚一步跟上。

**高亮改为围绕当前命中的窗口（最多 1000 处）。** 一屏只有几十行，十万处高亮
里能被看见的连千分之一都不到。窗口跟着读者步进移动，所以**正在看的那一处
必然在窗口内**——这是单独一条测试钉住的：跳到第 30000 处命中时它必须仍然
带高亮，否则读者会盯着一个没有高亮的命中。

**命中总数不做任何裁剪**——查找栏上显示的数字是读者的信息，不该被悄悄改小。
被限制的只有"画多少个"。

### 已知取舍

读者若不步进、直接把视图滚到离当前命中很远的地方（十万命中时约 3000 行以外），
那一段的命中不会带高亮。相对于每次光标移动 133 ms + 19.5 万 span 的排版，
这个代价是划算的。

### 涉及文件

- `code/lib/ui/editor/highlighting_controller.dart`
- `code/lib/ui/widgets/find_replace_bar.dart`
- `code/test/ui/editor/search_highlight_window_test.dart`（新增，4 条）


---

## BUG-113：支持类型清单漏了四种写法，应用对外宣称不支持自己已支持的图

### 现象

用图型名直接作为围栏标签时，下面四种**会被画成普通代码块而不是图**：

- ` ```packet-beta `
- ` ```architecture-beta `
- ` ```stateDiagram-v2 `（mermaid 官方文档里状态图几乎只用这个写法）
- ` ```xychart-beta `（官方写法同样带 `-beta`）

而且当某个图解析失败时，提示里那句"支持的类型：…"也会把这几种漏掉——
**应用在告诉读者它不支持自己已经支持的东西**。

### 根因分析

`MermaidParser.supportedTypes` 是一份清单，`handlesLanguage` 由它派生，
出错提示也直接把它 join 出来给用户看。它上面的注释写着：

> Derived from [supportedTypes] rather than kept as a second hard-coded list,
> so implementing a type cannot leave the two disagreeing.

**它能，而且已经这样了四次。** 前两次是本会话实现 packet-beta 与
architecture-beta 时我自己漏的（第八处需要同步的地方）；后两次是既有的——
`stateDiagram` 与 `xychart` 只登记了不带后缀的写法。

排查触发点：检查本会话新加的两种图在**导出**路径上是否覆盖到时，
发现导出对"哪些代码块是图"的判断走的正是 `handlesLanguage`。

### 修复方案

清单补齐为：`packet-beta`、`architecture-beta`、
`stateDiagram / stateDiagram-v2`、`xychart / xychart-beta`。

新增 `test/ui/editor/mermaid/supported_types_test.dart`，把**图型枚举**与
**这份清单**绑死：

1. `DiagramType` 的每个值（除 `unknown`）都必须在测试表里有样例——否则下面三条
   形同虚设；
2. 每个已实现的类型都必须出现在 `supportedTypes` 里；
3. 每个类型的裸名作围栏标签时 `handlesLanguage` 必须接受；
4. 每个类型的表头都必须真的解析得出来，且识别成它自己。

第 1 条是关键：没有它，将来新增图型只会让后三条**默默地少检查一项**。

### 顺带记录的设计事实

状态图**有意**以 `DiagramType.flowchart` 的形式返回——它复用流程图的布局与画笔。
第一版断言写死"类型必须等于自己"因此误报，已在测试里写明这条例外及其原因，
而不是把断言放宽了事。

### 涉及文件

- `code/lib/ui/editor/mermaid/parser/mermaid_parser.dart`
- `code/test/ui/editor/mermaid/supported_types_test.dart`（新增，4 条）


---

## BUG-114：流程图双圆节点标签带括号、隐形连线被整条丢弃

### 排查方式

本机另一个项目里有 mermaid 11.16.0 的完整源码，于是不再靠举例，而是**穷举**
mermaid 流程图文法定义的全部节点形状与连线写法，逐个过本项目的解析器。
14 种形状、18 种连线，查出两处。

### 其一：`A(((Double)))` 的标签是 `(Double)`

双圆的正则是 `\(\((.+)\)\)`，而 `.+` 是贪婪的，所以三重括号也会被它匹配上，
`group(2)` 拿到 `(Double)`——**那对括号被当成文字画进了节点里**，形状也退化
成普通圆。

有意思的是 `NodeShape.doubleCircle` **枚举里早就有，画笔也早就会画**，
只是解析器从来没产出过它。修法是在双圆之前先匹配三重括号。

顺带查了一遍：14 种形状现在没有一种是"定义了但没有写法能产生它"。

### 其二：`A ~~~ B` 整条被丢掉

箭头正则里没有 `~`，所以这行既不是连线也不是节点，直接被忽略。

mermaid 的 `destructLink` 原文：

```js
let l="normal", p=n.length-1;
n.startsWith("=") && (l="thick");
n.startsWith("~") && (l="invisible");
let c=this.countChar(".",n); c && (l="dotted", p=c);
```

`~` 前缀就是隐形连线。它存在的意义是**在不画任何东西的前提下，把两个节点约束
成布局上的关联**。所以丢掉它不只是少了一条线——**布局约束也跟着没了，画出来
的图和写下的图排布不同**。

修法：`~{3,}` 加进箭头正则（标签分支的排除字符集里也要加 `~`，否则标签会把它
吞掉），线型判定加 `LineType.invisible`（顺序照 mermaid 的 `destructLink`：
先看起始字符，点号数量覆盖它），画笔遇到 invisible 直接不画——**但边仍然存在
于图里，布局照样考虑它**，这是单独一条测试钉住的。

### 涉及文件

- `code/lib/ui/editor/mermaid/parser/flowchart_parser.dart`
- `code/lib/ui/editor/mermaid/models/edge.dart`
- `code/lib/ui/editor/mermaid/painter/flowchart_painter.dart`
- `code/test/ui/editor/mermaid/flowchart_syntax_test.dart`（新增，8 条）


---

## BUG-115：预览模式完全不读字号与行高设置，缩放对预览无效（issue #4）

### 来源

仓库 issue #4（zhangbest5，2026-06-29，从未有人回复）：

> 1. ctrl + = / ctrl + - 不好使（按后无反应），ctrl + 鼠标滚轮更通用
> 2. 预览不能放大缩小（哪怕操作时通知 只在 预览模式下可用放大缩小也ok，
>    现在太小了，单独展示时根本看不清，开会使用时的场景）

### 现象与根因

第 2 条属实，而且比报告说的更广。`markdown_renderer.dart` 里：

```dart
static final _defaultTextStyle = TextStyle(fontSize: 16, height: 1.6, ...);
```

正文样式是**编译期常量**，标题是写死的 28 / 24 / 21 / 17。所以受影响的不只是
缩放命令——**设置页里的字号和行高对预览模式根本不起作用**，缩放只是这个设置的
另一个入口。

第 1 条的 `Ctrl+=` / `Ctrl+-` 是**有意**改掉的：这两个键与"升级/降级标题"
冲突，缩放已移至 `Ctrl+Shift+=` / `Ctrl+Shift+-`（见 keybinding_service 里的
注释）。但报告人真正的诉求成立——**滚轮是大家会去试的手势，而且不占用按键**。

### 修复方案

- 正文与行高改为读 `config.fontSize` / `config.lineHeight`；
- 标题按**同一比例**从基准字号缩放（`_scaled(28)` 等），而不是各自写死——
  只放大正文不放大标题，版面会走形；
- 新增 **Ctrl/Cmd + 滚轮**缩放，包住整个编辑区，源码与预览两种模式都生效，
  范围与菜单命令共用同一对上下限。

### 涉及文件

- `code/lib/ui/editor/markdown_renderer.dart`
- `code/lib/ui/screens/home_screen.dart`
- `code/test/ui/editor/zoom_and_bottom_room_test.dart`（新增）
