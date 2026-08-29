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
| BUG-116 | 2026-08-29 | 版本常量停在 1.3.0：关于页显示错版本，更新检查永远提示有新版（issue #1） | P1 | 已修复 |
| BUG-117 | 2026-08-29 | 列表/引用前缀只作用于光标那一行，忽略选区（issue #3 的实际诉求） | P2 | 已修复 |
| BUG-118 | 2026-08-29 | 时序图双向箭头 `A<<->>B` 造出名叫 `A<<` 的幽灵参与者 | P2 | 已修复 |
| BUG-119 | 2026-08-29 | 预览复制到 Word 丢失标题与加粗：拿渲染后的纯文本反推 markdown | P1 | 已修复 |
| BUG-120 | 2026-08-29 | 类图关系用手工清单匹配，71 种合法写法里 39 种被当成普通连线 | P2 | 已修复 |
| BUG-121 | 2026-08-29 | ER 图只认符号基数，用英文写的关系导致整张图解析失败 | P2 | 已修复 |
| BUG-122 | 2026-08-29 | gitGraph 的 cherry-pick 整行被静默丢弃 | P3 | 已修复 |
| BUG-123 | 2026-08-29 | 跨行的行内代码不被识别，反引号原样留在正文里 | P2 | 已修复 |
| BUG-124 | 2026-08-29 | `** 空格 **` 被误加粗；中文/俄文词内下划线被误强调 | P2 | 已修复 |

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


---

## BUG-116：版本常量停在 1.3.0（issue #1）

### 来源

仓库 issue #1（zhangbest5，2026-06-11，从未有人回复）：

> 1. 检查更新 应该 做版本校验 再跳网页
> 2. 现在这个我更新了，但我看不出来这能和github上的对应上

### 现状核实

第 1 条**已经修好了**（在这条 issue 之后的某个版本）：`UpdateService.checkForUpdate`
会调 GitHub API 取 `tag_name`，用 `_isNewer` 逐段比较三位版本号，并区分
"有新版 / 已是最新 / 联系不上服务器"三种结果，不再直接跳网页。

第 2 条仍然存在，而且比报告说的更严重。

### 根因分析

`AppConstants.appVersion` 是**手写常量**，停在 `'1.3.0'`，而 `pubspec.yaml`
已经是 `1.5.1`。同一个值写在两处，一处没跟上——本会话反复出现的同一个模式。

两层后果：

1. 「关于」里显示 1.3.0，**和 GitHub 上的发行版对不上**——这正是报告人说的；
2. **更新检查是拿最新发行版和 1.3.0 比的**。所以任何装了 1.4.0 或 1.5.0 的人，
   都会被**永远提示有新版本可用**，点进去下载的还是自己已经装着的那一版。
   报告人只看到了第一层。

### 修复方案

常量对齐到 1.5.1，并新增 `test/core/app_version_test.dart` 直接读 `pubspec.yaml`
比对——**这是唯一能防止它再次漂移的东西**，因为发布时改的是 pubspec，没人会
记得回来改常量。另一条测试断言它是纯三段式版本号，因为 `_isNewer` 按点分割解析
三个整数，`1.5.1-beta` 这样的后缀会被解析成 0 参与比较。

### 涉及文件

- `code/lib/core/constants.dart`
- `code/test/core/app_version_test.dart`（新增，2 条）


---

## BUG-117：列表/引用前缀只作用于光标那一行，忽略选区（issue #3）

### 来源

仓库 issue #3（zhangbest5，2026-06-29，从未有人回复）要的是 Alt+拖拽的列编辑，
但它给出的例子说明了真实诉求：

> 比如我要给多行 加 `-`
> ```
> 1111        - 1111
> 2222   →    - 2222
> 3333        - 3333
> ```

### 根因分析

`_applyLinePrefixAtCursor` 只用 `selection.baseOffset` 找到光标所在行，
**完全没有读 `extentOffset`**。所以选中三行按无序列表，只有一行加上了 `-`——
而"把几行变成列表"正是有人一次选中多行的普通理由。

### 修复方案

前缀作用于**选区触及的每一行**。加还是去由**整块统一决定**：只有每一行都已经
有前缀时才全部去掉，否则全部加上。逐行各自切换会把一个半标记的块变成它自己的
反面，永远不会变得整齐。

两处边界：

- 选区正好结束在某行行首时，**不包含那一行**——向下拖到下一行开头不该把它也标记；
- 操作后**保持整块选中**，这样同一个键可以再按一次取消；光标折叠掉的话就得重新
  选一遍。

### 关于列编辑本身

Alt+拖拽的列选择是另一件事：Flutter 的 `TextField` 没有列选择模型，要做等于自己
实现一套多光标编辑器。已在 issue 里如实说明，未承诺。

### 涉及文件

- `code/lib/ui/editor/source_editor.dart`
- `code/test/ui/editor/multiline_prefix_test.dart`（新增，9 条）


---

## BUG-118：时序图双向箭头造出幽灵参与者

### 排查方式

延续 BUG-114 的做法：从 mermaid 11.16 源码取出**时序图的真实关键字集合**
（28 个：participant / actor / activate / deactivate / note / loop / alt /
else / opt / par / and / critical / option / break / rect / end / autonumber /
links / box / destroy / create / title …），再穷举它的 10 种箭头写法，
逐条过本项目的解析器。

21 个关键字全部能解析。问题出在箭头上。

### 现象

```
sequenceDiagram
  A<<->>B: msg
```

画出来有**三条生命线**：`A`、`B`，以及一条名叫 **`A<<`** 的。而且箭头退化成单向。

### 根因分析

消息正则里发送方的字符类是 `[^\s\->+:]+`——排除了空白、`-`、`>`、`+`、`:`，
**唯独没有排除 `<`**。于是 `A<<->>B` 里发送方贪婪地吃到了 `A<<`，
剩下 `->>B` 正好还能匹配成一条普通消息，所以它**不报错、不丢行**，
只是安静地画错。

`<<->>`（双向实线）与 `<<-->>`（双向虚线）是 mermaid 11 的语法，
在它的词法表里紧挨着 `->>` 与 `-->>`，对应 `BIDIRECTIONAL_SOLID_ARROW` 与
`BIDIRECTIONAL_DOTTED_ARROW`。

### 修复方案

发送方字符类加上 `<`——**这正是 mermaid 自己的 actor 词法所做的**
（`[^\+<\->\->:\n,;]+`）。正则加一个可选的 `(<<)` 分组，读出双向标记；
`MermaidEdge.bidirectional` 基类字段早就有，只是时序图这条路径从来没传过它。
画笔在近端也画一个箭头——只画远端的话，双向与单向看起来一模一样。

### 涉及文件

- `code/lib/ui/editor/mermaid/parser/sequence_parser.dart`
- `code/lib/ui/editor/mermaid/models/edge.dart`
- `code/lib/ui/editor/mermaid/painter/sequence_painter.dart`
- `code/test/ui/editor/mermaid/sequence_syntax_test.dart`（新增，6 条）

其中一条测试断言**任何关键字都不能变成参与者**——这一类失败是无声的：
没被识别的行会落到消息正则上，画出一条以关键字命名的生命线，
在读它之前看起来像一张正常的图。


---

## BUG-119：预览复制到 Word 丢失标题与加粗

### 来源

用户反馈：

> 如果我在 html 的 markdown 编辑器中复制了一个标题，然后把他粘贴到其他的富文本
> 编辑器或者 word 文档中，会保留标题或者加粗样式，复制到记事本中就是单纯的纯
> 文本；但是我们这个编辑器好像无法实现这个功能

### 根因分析

这个功能**是做过的**（v1.2.0 FEAT-001），Windows 上通过 FFI 往剪贴板写
`HTML Format`，通道本身没问题。**错的是 HTML 从哪来。**

原实现：

```dart
final data = await Clipboard.getData(Clipboard.kTextPlain);
final html = _selectedTextToHtml(data.text);   // 把它当 markdown 再解析一遍
```

预览渲染的是 markdown，所以**选区返回的是渲染后的文本**——选中一个标题，
拿到的是 `My Heading`，**没有 `#`**；选中加粗，拿到的是 `bold`，没有 `**`。
再把这段文本当 markdown 解析，只可能得到 `<p>My Heading</p>`。

**格式在转换开始之前就已经没了。** 所以粘进 Word 永远是纯段落——正是反馈说的现象。

### 修复方案

HTML 改为**从预览自己解析出的 AST 生成**，而不是从渲染文本反推：

1. 把文档按块拼成"读者看到的那段文本"，同时记下每个块占据的区间；
2. 在其中定位选中的文本，找出它覆盖的块；
3. **完整覆盖的块**交给 `ExportService.nodeToHtml`——它本来就会把标题写成
   `<hN>`、加粗写成 `<strong>`、链接带上 `href`；
4. **部分覆盖的块**，内联结构无法在不重建的情况下裁剪，所以取覆盖到的文本，
   但**仍然套上该块自己的元素**——半个标题依然是标题，这正是复制标题的意义。

定位不到时**什么都不写**，而不是写一段不描述所复制内容的 HTML：
纯文本已经在剪贴板上且是对的。

### 已知限制

`ClipboardService.copyWithHtml` 仍然只在 Windows 上写 `HTML Format`，
macOS / Linux 退化为纯文本。这两个平台需要各自的原生剪贴板接口，尚未实现。

### 涉及文件

- `code/lib/services/rich_copy_service.dart`（新增）
- `code/lib/ui/editor/markdown_renderer.dart`
- `code/test/services/rich_copy_test.dart`（新增，13 条）


---

## BUG-120：类图关系用手工清单匹配，39 种合法写法被当成普通连线

### 排查方式

延续前两轮：从 mermaid 11.16 源码取出类图的真实文法。它的产生式是

```
relation : [relationType] lineType [relationType]
```

`relationType ∈ {AGGREGATION o, EXTENSION <|, COMPOSITION *, DEPENDENCY >,
LOLLIPOP ()}`，`lineType ∈ {LINE --, DOTTED_LINE ..}`——**任意关系类型可以
出现在任意线型的任意一端**。据此做完整叉乘（71 种），逐个过本项目的解析器。

### 一次自我纠正

第一遍探针只打印了 `arrowType`，于是我以为 `<|--`、`*--`、`o--` 这些**前置**
写法全都丢了装饰。核实后发现不是：它们走的是 `startArrowType`，一路都在，
是我测错了。**把两端都打印出来之后**，真正的缺口才浮现。

### 现象与根因

`_relationPatterns` 是一张**手工穷举的清单**，写了 16 种拼法。71 种合法组合里
**39 种不在其中**：

- `..o`、`..*`、`..()`——虚线的聚合 / 组合 / 棒棒糖；
- 一切**两端都有装饰**的写法，如 `o--o`、`o--|>`、`*--o`；
- **棒棒糖 `()` 整个类型**，一种都没有。

失败是**无声的**：清单里没有的拼法，仍然会匹配到列表末尾的裸 `--`，
于是线画出来了、两端的装饰没了，**关系的含义悄悄消失**，图看上去仍然像一张图。

### 修复方案

改为按文法**组合解析**——一条正则表达三段结构，两端各查一次装饰表，
而不是维护一张永远会漏的清单。

一个例外保留了下来：`>` / `<` 的头取决于线型。UML 里依赖（虚线）画空心箭头、
关联（实线）画实心箭头，本项目原先就区分这两者，且有测试钉着。
**我第一版把它压平成同一种箭头，导致那条既有测试变红——那是我改坏了，
不是测试过时了**，已按原意恢复。

### 涉及文件

- `code/lib/ui/editor/mermaid/parser/class_diagram_parser.dart`
- `code/test/ui/editor/mermaid/class_relations_test.dart`（新增，6 条，
  其中一条就是这 71 种的完整叉乘）


---

## BUG-121：ER 图只认符号基数，英文写法导致整张图解析失败

### 排查方式

从 mermaid 11.16 的 ER 词法取出基数记号（左端 `|o` `}o` `}|` `||`，
右端 `o|` `o{` `|{` `||`）与线型（`--` 识别、`..` 非识别），
做 32 种完整叉乘——**全部正确**。

但词法里还有另一组记号：

```
one or zero   one or more   one or many
zero or one   zero or more  zero or many
one           only one      to            optionally to
```

也就是同一件事的**英文写法**：`PERSON one to zero or more ADDRESS : has`
与 `PERSON ||--o{ ADDRESS : has` 等价。

### 现象

`_relationRe` 只匹配符号形式。英文写法不匹配 → 该行不算关系 →
实体也没被声明 → **整张图返回 null**，退化成一段灰色代码块。

不是画错一条关系，而是**整张图都出不来**。

### 修复方案

**把英文写法规范化成符号形式**，再走原来那条路径——而不是写第二套解析。
符号那条路径已经验证过 32 种组合全部正确，同一份文法的第二份实现正是它们
日后走岔的方式（本会话已经因此修过好几处）。

一处顺序要求：`zero or one` 必须在 `one` 之前尝试，否则前面的 `zero or`
会被当成实体名的一部分留下来。这是单独一条测试钉住的。

### 一处自我纠正

第一版探针写的是 `A one or more to B : has`——**漏了右端的基数**，
这在 mermaid 里本来就不合法。于是探针显示"所有英文写法都失败"，
证据是错的。查清文法后改用 `A one to zero or more B` 重测，
**结论不变**（原解析器确实只认符号），但记录在此，因为错误的证据
比没有证据更危险。

### 涉及文件

- `code/lib/ui/editor/mermaid/parser/er_diagram_parser.dart`
- `code/test/ui/editor/mermaid/er_relations_test.dart`（新增，8 条）


---

## BUG-122：gitGraph 的 cherry-pick 整行被静默丢弃

### 排查方式

状态图按 mermaid 文法逐条过完——**是干净的**（复合状态、嵌套复合、并发分隔、
choice / fork / join、两种 note 写法、direction、v1 表头、`hide empty
description`、`classDef` 全部正确）。

于是改做广度扫描：其余 14 种图型各用一个**特性密集**的样例（不是最小样例，
最小样例已被既有测试覆盖），并**逐个检查旁路载荷的内容**而不只看"能否解析"。

甘特图正确（done / active / crit / milestone 状态、`after des2` 依赖、
日期推算）。时间线正确。只有 gitGraph 有问题。

### 现象

```
gitGraph
  commit id: "one"
  branch dev
  checkout dev
  cherry-pick id: "one"
```

产出**两个提交里只有一个**：`cherry-pick` 这一行不匹配任何分支，
被 `continue` 掉了——**历史少了一个提交，而且没有任何提示**。

### 修复方案

加 `cherry-pick` 的解析：记录它摘自哪个提交（`mergedFrom`），
新增 `GitCommitType.cherryPick`，画笔按 mermaid 的画法画成**带叉的实心圆**
——这正是它与被摘的那个提交的区别所在。

没有 `id` 时不产生提交：mermaid 要求必须带 id，凭空造一个提交等于在图上
多画一个圆却什么都不代表。

### 三次自我纠正

本轮探针连续三次给出错误的"发现"，都在核实后撤销：

1. 以为嵌套复合状态里 `A`、`B` 消失了——它们是作为 **subgraph** 上报的，
   探针只打印了 nodes；
2. 以为 timeline 忽略了 `section`——它记在 `TimelineSection.group` 上，
   探针只打印了 `title`；
3.（上一轮）以为类图前置关系丢了装饰——它们走 `startArrowType`。

**同一个错误犯了三次：只打印模型的一部分，就断言另一部分不存在。**

### 涉及文件

- `code/lib/ui/editor/mermaid/parser/git_graph_parser.dart`
- `code/lib/ui/editor/mermaid/models/git_graph.dart`
- `code/lib/ui/editor/mermaid/painter/git_graph_painter.dart`
- `code/test/ui/editor/mermaid/git_graph_test.dart`（新增，9 条）


---

## BUG-123：跨行的行内代码不被识别

### 排查方式

mermaid 的 23 种图型已按真实文法过完，于是转向**这个应用的主体**：自研的
markdown 解析器。本机 `marktext-light/node_modules` 里有
`commonmark-spec@0.31.2` 的官方 `spec.txt`，从中抽出 **648 个官方示例**
逐个跑本项目的解析器。

### 关于那个通过率数字

第一次跑出来是 202/648，但**这个数字不可信**——`ExportService.nodeToHtml`
是导出用的渲染器，不是 CommonMark 参考实现，HTML 形状不同就算失败。
`Fenced code blocks 0/29` 全错，一看就是系统性格式差异而非 29 个解析 bug。

逐条看过差异后，把**已知且有意**的分歧归一化掉（每条都要说得出理由）：

- 导出加的 `class="hljs"`——与解析无关；
- `<hr />` 与 `<hr>`——空元素的两种写法；
- **段落内单换行渲染成 `<br>`**——这是本项目**有意**的产品选择，
  代码注释里写明了"预览、Word、HTML 三者一致"，与 CommonMark 把它折成空格
  的做法不同。

归一化后是 250/648，剩下的才是真差异。

### 找到的真问题

```
md   : "`foo   bar \nbaz`"
期望 : "<p><code>foo bar baz</code></p>"
实得 : "<p>`foo bar baz`</p>"
```

行内代码的正则是 `` (`+)([^`]|[^`].*?[^`]|`+?)\17(?!`) ``，而这条总正则**不是
dotAll**，所以 `.` 匹配不了换行——**只要行内代码跨行，反引号就原样留在正文里**。
长命令换行写是很常见的：

```markdown
Use `flutter build
windows` to build.
```

### 修复方案

中间那一支改用显式的 `[\s\S]`（只影响代码这一支，不动整条正则的 dotAll 语义，
也不改变组编号——后向引用 `\17` 依赖它）。同时按 CommonMark 把行内代码里的
换行折成空格：无论源码里怎么折行，它都是一段连续的代码。

修完 250 → 255。

### 常驻回归

语料与比较逻辑固化为 `test/services/commonmark_spec_test.dart`，含四条：

1. 夹具确实是完整的 648 例；
2. **没有任何一例让解析器抛异常**——与得分分开断言：答案不同是与规范的分歧，
   抛异常是文档根本打不开；
3. **得分不得下降**（下限 255）。这是一个棘轮，不是合规声明：数字离 648 很远，
   且其中一部分差异是有意的，所以它断言的是"不许退步"。别处改坏了解析会在这里
   表现为掉分，那才是值得抓的；
4. 跨行行内代码这条本身。

### 涉及文件

- `code/lib/services/markdown_parser.dart`
- `code/test/fixtures/commonmark_spec.json`（新增，84 KB）
- `code/test/services/commonmark_spec_test.dart`（新增，4 条）


---

## BUG-124：强调的两条规则只对 ASCII 生效

沿着 CommonMark 语料（BUG-123 建立）继续推，从失败最多的"Emphasis and strong
emphasis"（48/132）里挑出**真实写法会踩到的**两条。

### 其一：`**` `***` `__` `___` 没有空白规则

单个 `*` 那一支**早就有**这条规则，注释也写着"没有它 `2 * 3 * 4` 会把 3 变斜体"。
但另外四种分隔符都没跟上：

| 输入 | 期望 | 实得 |
|---|---|---|
| `2 ** 3 ** 4` | 原样 | **3 被加粗** |
| `** foo bar**` | 原样 | 整段加粗 |
| `__ foo bar__` | 原样 | 整段加粗 |

一条规则加在一个分支上、另外四个分支没跟上——本会话反复出现的同一个形状。

### 其二：词内下划线的边界只认 ASCII

规则是"`_` 不能出现在词的内部，否则 `snake_case_name` 会被当成强调"，
但边界写的是 `[a-zA-Z0-9_]`。于是**非拉丁文字一律漏网**：

| 输入 | 期望 | 实得 |
|---|---|---|
| `snake_case_name` | 原样 | 原样 ✓ |
| `пристаням_стремятся_` | 原样 | **被强调** |
| `中文_强调_文字` | 原样 | **被强调** |
| `ファイル_名前_です` | 原样 | **被强调** |

对一个主要用中文写作的用户来说，这一条比第一条更常撞上。

### 修复方案

四个分隔符补上空白规则；边界从 `[a-zA-Z0-9_]` 改为 `[\p{L}\p{N}_]`，
整条内联正则加 `unicode: true` 让属性转义生效。

**保留的行为**：`_中文_` 单独出现时仍然强调——规则是"不在词内"，不是
"只对拉丁字母生效"。这是单独一条断言。

CommonMark 得分 255 → 259，下限已提到 259。

### 一处自己的错误

第一版测试用 python heredoc 写 Dart 字符串，`\$source` 没转义干净，
Dart 源码里成了字面量 `$source` —— **整个循环在空跑**，
而且"通过"了。是 `_中文_` 那条断言失败才暴露出来的。
修好插值后六条才是真的在跑。

### 涉及文件

- `code/lib/services/markdown_parser.dart`
- `code/test/services/commonmark_spec_test.dart`
