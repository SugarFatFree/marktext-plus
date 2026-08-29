# v1.5.3 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-144 | 2026-08-30 | 预览的块编辑器里所有格式命令都无效，且命令会滞留 | P1 | 已修复 |
| BUG-145 | 2026-08-30 | v1.5.2 发出去时关于页仍显示 1.5.1（守卫测试没跑在发布路径上） | P1 | 已修复 |
| BUG-146 | 2026-08-30 | 文件被外部修改后，自动保存会静默覆盖别人的改动 | P1 | 已修复 |
| BUG-147 | 2026-08-30 | 拖图片进编辑器：插入成功的同时弹出「未打开」错误 | P2 | 已修复 |
| BUG-148 | 2026-08-30 | 韩文字数统计约为实际的三倍（按字计数，但韩语有词间空格） | P2 | 已修复 |
| BUG-149 | 2026-08-30 | 没有磁盘戳的标签页永远保存不了（BUG-146 引入，CI 抓到） | P1 | 已修复 |
| BUG-150 | 2026-08-30 | 自定义快捷键撞键时，其中一个命令永远不触发 | P2 | 已修复 |
| BUG-151 | 2026-08-30 | 日文/韩文/全角标签伸出 mermaid 节点方框 | P2 | 已修复 |

---

## BUG-144：预览的块编辑器里格式命令全部无效，且命令会滞留

**优先级**：P1　**状态**：已修复　**日期**：2026-08-30

### 现象

在预览里双击打开一个块（这就是一个普通的文本框，里面是该块的 markdown），
选中几个字按 Ctrl+B —— **什么都不会发生**。格式菜单里的每一项同样无效。

更糟的是第二段：这个命令**并没有消失**，它一直挂在 `pendingFormat` 里。
等下一次源码面板出现时才被消费，于是加粗会**在读者没有放光标的地方突然生效**。

### 根因分析

`applyFormat` 只是把动作写进 `state.pendingFormat`，由 `SourceEditor.build`
取走并执行。**预览模式下根本没有 SourceEditor**，所以没人取，也没人清。

探针实测（不是读代码推断的）：

```
块编辑器打开了吗 = true
选中前文本 = "hello world"，选区 = (0, 5)
按了加粗之后文本 = "hello world"      ← 没变
pendingFormat = FormatAction.bold      ← 还挂着
```

### 修复方案

预览在 build 时消费 `pendingFormat`（仅当确有块处于编辑状态），把行内包裹类命令
作用到块编辑器的选区上，**复用 `SourceEditor.toggleWrap` 这个已有的静态纯函数**，
不写第二份实现。块无法执行的命令（插入表格、改标题级别等是关于文档而非这段文字的）
也一并清掉——**不能留着以后在别处放炮**。

**分屏模式下两个面板同时在场**，都会看到同一个 `pendingFormat`。新增
`EditorState.previewBlockEditing`：预览开着块编辑器时，源码面板让路。有一条测试
把两个面板同时挂上，断言只有预览一侧被加粗。

### 涉及文件

- `code/lib/providers/editor_provider.dart`（`previewBlockEditing`）
- `code/lib/ui/editor/markdown_renderer.dart`、`code/lib/ui/editor/source_editor.dart`
- `code/test/ui/editor/preview_block_format_test.dart`（新增，7 条）

---

## BUG-145：v1.5.2 发出去时关于页仍显示 1.5.1

**优先级**：P1　**状态**：已修复　**日期**：2026-08-30

### 现象

**这是一个已经发布出去的问题，我发的。** v1.5.2 的安装包里，关于页显示 1.5.1；
更新检查拿这个常量去比对，于是装了 v1.5.2 的用户会被**一直提示有新版本可用**
——正是 issue #1 报的那个现象重演。

### 根因分析

版本号写在两处：`pubspec.yaml` 的 `version:` 与 `AppConstants.appVersion`。
仓库里**已经有**一条测试守着两者一致（就是修 issue #1 时加的）。

但那条测试跑在 `flutter test` 里，而 `flutter test` 属于 **CI 工作流**，
触发条件是 push；**发布走的是 tag 触发的另一个工作流**，里面只有四个构建 job
和一个 release job，**没有测试这一步**。

发布 v1.5.2 时我改了 pubspec 却漏了常量，而发布路径上没有任何东西会发现。
**守卫存在，只是没装在要紧的那条路上。**

### 修复方案

1. 常量改为 1.5.2
2. `release.yml` 增加 `check-version` job，**四个构建 job 都 `needs` 它**：
   校验 **tag、pubspec、AppConstants 三者一致**，不一致直接让发布失败。
   放在构建之前，所以是拦下而不是事后报告
3. 本地正反两向验证过该脚本：当前三者一致会放行；把 tag 换成 `v9.9.9` 会拦下

### 涉及文件

- `code/lib/core/constants.dart`
- `.github/workflows/release.yml`

---

## BUG-146：文件被外部修改后，自动保存会静默覆盖别人的改动

**优先级**：P1　**状态**：已修复　**日期**：2026-08-30

### 现象

**这一条不需要用户做任何事**，因为**自动保存默认开启、延迟 5 秒**：

1. 打开 `a.md`，改了几个字（标签页进入"已修改"）
2. 别的东西重写了 `a.md`——`git checkout`、同步盘、另一个编辑器
3. 五秒后自动保存触发，**把对方的改动整个覆盖掉，一句话都不说**

### 根因分析

两处都缺检查：

- **文件监听器**只重载 `!isModified` 的标签页（这是对的，不能覆盖用户正在编辑
  的内容），但对已修改的标签页**什么都不做、也不记录**
- **保存路径从不比对磁盘**。`FileService.saveDocument` 直接写

于是"编辑中"这个状态成了一个盲区：监听器不管，保存不查。

### 修复方案

**服务层**：`stampOf(path)` 记录文件的修改时间与大小（比读回全文再哈希便宜得多，
是编辑器每次写前负担得起的检查）；`hasChangedSince(path, stamp)` 比对；
新增 `saveDocumentIfUnchanged(..., required expect)`，不一致就抛
`FileChangedOnDiskException` 而不写。

**为什么是两个入口而不是一个带开关的**：调用方传了 stamp 却忘了打开检查，
就会静默覆盖——正是这条 bug 本身。两个方法名不可能用错。

**标签页**：`TabInfo` 增加 `diskStamp` 与 `diskConflict`。自动保存改走带检查的
入口；**冲突时不写，只记下冲突并停掉该标签页的自动保存**——选哪个版本不是自动
保存能替用户做的决定。

**戳的记录收口在两处**：`addTab`（所有"从文件打开"的入口都经过它）和
`markSaved`/保存成功之后。**在各个调用点分别记，早晚有一处会漏——而没有戳的
标签页，它的保存就是不受检查的，外表看起来却完全正常。**

**界面**：Ctrl+S 遇到冲突弹出三选一——覆盖 / 丢弃我的编辑并重新载入 / 取消
（取消保持冲突状态，自动保存继续停着）。状态栏显示告警条，否则"自动保存停了"
用户无从得知。12 种语言文案齐备。

### 修复过程中我自己引入又修掉的两个问题

1. **`refreshDiskStamp` 是 `unawaited` 的**，`await` 回来时 notifier 可能已经
   dispose，触碰 `state` 会抛 `Bad state: Tried to use TabNotifier after dispose`
   ——而且没有 await，异常直接逃逸成未捕获的异步错误。关闭标签页或退出应用时
   就会发生。加了 `mounted` 守卫（三处）。**是既有测试抓到的。**

2. **`addTab` 一开始没记戳**，而 `expect: null` 的语义是"当时文件不存在"，
   于是判定为"文件出现了"→ 冲突 → **该标签页永远无法自动保存**。
   同样是既有测试抓到的（`a change landing right after our own save is still
   noticed` 里文件停在 `one` 没变成 `mine`）。收口到 `addTab` 后恢复。

### 测试上的一处刻意安排

"自动保存不覆盖"那条测试单独看是可能空跑的——**定时器根本没触发的话，文件不变
是错误的原因**。所以配了一条对照测试：完全相同的设置下、没有冲突时，自动保存
**应该**写入。对照通过，才能说明前一条测的是守卫而不是巧合。

### 涉及文件

- `code/lib/services/file_service.dart`（`stampOf` / `hasChangedSince` /
  `saveDocumentIfUnchanged` / `FileChangedOnDiskException`）
- `code/lib/models/tab_info.dart`、`code/lib/providers/tab_provider.dart`
- `code/lib/ui/widgets/app_menu_bar.dart`（冲突对话框）、`code/lib/ui/widgets/status_bar.dart`（告警条）
- `code/lib/core/i18n/l10n/*.arb`（12 种语言 × 6 个键）
- `code/test/services/save_conflict_test.dart`（新增，12 条）

---

## BUG-147：拖图片进编辑器会同时插入成功并报错

**优先级**：P2　**状态**：已修复　**日期**：2026-08-30

### 现象

把一张图片拖进编辑器正文区：图片链接正确插入了文档，**同时**屏幕下方弹出
「1 个文件未打开：不是 markdown 文档」。

动作成功了，应用却说它失败了。

### 根因分析

窗口和编辑器各挂了一个 `DropTarget`，编辑器那个嵌套在窗口那个里面。
读 `desktop_drop` 0.4.4 的源码确认（不是猜的）：

```dart
for (final listener in _listeners) { listener(event); }
```

它把每次拖放**广播给所有** target，各自用自己的矩形判断 `inBounds`，
**没有命中消费机制**。所以拖到正文区时两个处理器都会跑：

- 编辑器的 `_handleImageDrop`：识别为图片，存好并插入 `![image](...)` ✓
- 窗口的 `_handleDrop`：扩展名不在 markdown 清单里 → `refused++` → 弹提示 ✗

### 顺带查证但**不是**问题的一点

同时怀疑「把 .md 文件拖进正文区不会打开」。**不成立**——正因为是广播，
窗口级处理器照样收得到并打开它。查了包的实现才敢下结论。

### 修复方案

抽出 `HomeScreen.dropIsUnhandled(path, {required editorPresent})`：
markdown 文档不算被拒；图片**在有编辑器接手时**不算被拒。

`editorPresent` 这个参数是必要的：一个标签页都没开时没有正文区、也就没有那个
drop target，图片确实没人接。**那种情况下静默忽略，等于把这条 bug 换个地方
重演**——所以此时仍然提示。

### 涉及文件

- `code/lib/ui/screens/home_screen.dart`
- `code/test/ui/screens/drop_handling_test.dart`（新增，5 条）

---

## BUG-148：韩文字数统计约为实际的三倍

**优先级**：P2　**状态**：已修复　**日期**：2026-08-30

### 现象

状态栏对韩文文档报出的词数远大于实际。`이것은 한국어 테스트입니다` 这句实际是
**3 个词**，报的是 **12 个**。

### 根因分析

`WordCountService._isCjk` 把韩文音节（`0xAC00–0xD7AF`）和韩文字母
（`0x1100–0x11FF`）归入"按字计数"的范围。

按字计数对中文和日文是对的——它们**不在词间加空格**。但**现代韩语是加空格的**
（띄어쓰기），`한국어` 是一个词（意为"韩语"），Word、Google Docs 以及韩国本地的
字处理软件都按어절（空格分隔单位）计数。

读代码里那条注释可以看出这不是有意为之：

> Japanese and Korean used to count as zero: only the basic Han block was
> recognised, and kana and Hangul matched no other rule either.

当初修的是"日韩被算成 0 词"，顺手把韩文塞进了 CJK 规则；**按字计数是那次修法的
副作用，不是对韩语正字法的判断**。

### 修复方案

把两段韩文范围移出 `_isCjk`。移出后它们落到 `_isWordCharacter`（返回 true），
于是像拉丁字母一样按空格成词。中文、日文假名不受影响。

### 关于改动既有测试

原有测试里 `expect(service.countWords('한국어').words, 3)` 是明确断言了当前行为的。
这次是**有意改掉它**，不是测试过时——理由如上，并写进了新测试的注释里，
免得以后有人把它"改回去"。

### 涉及文件

- `code/lib/services/word_count_service.dart`
- `code/test/services/word_count_service_test.dart`

---

## BUG-149：没有磁盘戳的标签页永远保存不了（BUG-146 引入）

**优先级**：P1　**状态**：已修复　**日期**：2026-08-30

### 现象

CI 上 `tab_reload_test` 的「a change landing right after our own save is still
noticed」失败：自动保存没有写入文件。**本地当时是通过的。**

### 根因分析

BUG-146 加冲突检测时，我把两件不同的事都表示成了 `null`：

- **文件在读取时不存在**（一个合法的戳值）
- **我们从来没看过这个文件**（没有基准）

而 `hasChangedSince(path, null)` 返回 `now != null` —— 也就是说，"没看过"
被解释成了"文件出现了"，判定为冲突，于是**这个标签页永远保存不了**，
还会告诉用户"文件被别的程序改了"，而实际上什么都没发生过。

戳原本由 `addTab` 里一个 `unawaited(refreshDiskStamp(...))` 事后补记。
**这就是本地过、CI 挂的原因**：那是个异步窗口，本机够快而 CI 不够。

### 修复方案（两处，缺一不可）

**一、消掉窗口**：戳改为**跟着内容一起产生**。`readFileWithLineEnding` 现在
连戳一起返回（在读之后取，所以两者之间发生的写入会被下一次保存发现，
而不是被当成基准固化下来），所有构造标签页的地方直接带上它。
`addTab` / `loadTabContent` 里的事后补记删掉了。

**二、修正语义**：`hasChangedSince(path, null)` 现在返回 **false**。
"没有基准"这个问题的诚实答案是"不知道"，不是"变了"。
放弃的是"读取与保存之间别人新建了这个文件"这一种情形——**很罕见，
而且比"文档永远存不下去"轻得多**。

### 教训

第一次修（给 `addTab` 加异步补记）**只是把不确定性换了个位置**，没有消除它，
所以本地五次全过、CI 五次全挂。改完之后我在本地把那条测试**连跑五次**才确认，
一次通过说明不了任何事情。

### 涉及文件

- `code/lib/services/file_service.dart`、`code/lib/providers/tab_provider.dart`
- `code/lib/models/tab_info.dart` 的使用方：`home_screen.dart`、`side_bar.dart`、
  `app_menu_bar.dart`、`markdown_renderer.dart`
- `code/test/services/save_conflict_test.dart`（+2 条）

---

## BUG-150：自定义快捷键撞键时，其中一个命令会永远不触发

**优先级**：P2　**状态**：已修复　**日期**：2026-08-30

### 现象

在设置里把某个命令的快捷键改成一个**已被占用**的组合（比如把"上移块"改成
`Ctrl+B`），对话框照常显示"确定"，改完之后：**两个命令里有一个再也不响应了**。
设置页上两个都显示着绑定，没有任何地方说哪个失效了、为什么。

### 根因分析

`KeybindingService._reverseIndex` 建反查表时用的是
`built.putIfAbsent(combo, () => entry.key)`，注释写着"首个绑定优先，重复的不会
遮住前面的动作"——**这句话保护的是查表本身不出错，不是使用者**。
落到使用者身上就是：撞键的两个动作里，Map 迭代顺序靠后的那个永远不会被查到。

而 `setKeybinding` 只是 `_keybindings[action] = keys`，**完全不检查冲突**；
设置页的按键捕获对话框也直接调它。

### 修复方案

**服务层**：新增 `actionUsing(keys, {excluding})`，返回当前占用该组合的动作。
比较的是**解析后的组合而不是字符串**，所以 `Ctrl+Shift+K` 和 `Shift+Ctrl+k`
会被认作同一个键。`setKeybinding` 现在会把该组合从原主人那里摘掉
（置为空绑定）——**不是共用，共用正是让其中一个静默失灵的原因**。

**界面**：捕获到已占用的组合时，对话框**在按下按钮之前**就用警示色说明
"已被『粗体』占用。设到这里会让那个命令没有快捷键"，并且确定按钮改名为
"夺过来"——从别的命令手里拿走一个快捷键，和给一个空闲组合赋值，是两件不同的事，
按钮应当说清自己会做哪一件。12 种语言文案齐备。

### 测试

9 条，其中一条断言的是**整张表的性质**而不是这次改动的那一对：
连做三次重新赋值之后，遍历全表确认没有任何两个动作共用同一组合。

### 顺带查证、结论为干净的两项

- **41 个配置项逐个 grep**，确认每一项在设置页之外都有真实读取处，没有"死开关"
- **62 条默认快捷键**两两比对，没有撞键

### 涉及文件

- `code/lib/services/keybinding_service.dart`
- `code/lib/ui/screens/settings_screen.dart`
- `code/lib/core/i18n/l10n/*.arb`（12 种语言 × 2 个键）
- `code/test/services/keybinding_conflict_test.dart`（新增，9 条）

---

## BUG-151：日文、韩文、全角符号的图表标签会伸出方框

**优先级**：P2　**状态**：已修复　**日期**：2026-08-30

### 现象

mermaid 节点里写较长的日文或韩文标签，文字会**从方框两侧伸出去**，压在边框和
连线上。中文和英文正常。

### 根因分析

真正决定方框宽度的是 `DagreLayout._measureTextWidth`：

```dart
if (char > 0x4E00 && char < 0x9FFF) { width += fontSize; }
else { width += fontSize * 0.6; }
```

它**只认基本汉字块**。落在外面按 0.6 em 计算的有：

- 日文假名（0x3040–0x30FF）
- 韩文谚文（0xAC00–0xD7A3）
- 全角标点（0xFF00–0xFF60）
- CJK 扩展 A（0x3400–0x4DBF）与兼容汉字（0xF900–0xFAFF）
- 以及边界本身：`>` 和 `<` 把「一」和「龿」也漏了

而这些字形实际约 1.0 em 宽，被少算了近一半。绘制端 `drawText` 调用时**没有传
`maxWidth`**，所以文字按自然宽度画在节点中心——既不换行也不裁切，**直接溢出边框**。

短标签被内边距兜住了，所以 `A[中文]` 看不出问题，一写成句子就露出来。

### 修复方案

新增 `lib/utils/text_width.dart`，把"宽字符"的判定收到一处：
`isWideCharacter` / `displayWidth` / `estimatedTextWidth`。
`DagreLayout._measureTextWidth` 与 `LayoutEngine.measureNode`（`SimpleLayoutEngine`
用的备用引擎）都改为调它；`TableEditService` 里原本自带的一份也换成共享实现。

### 排查过程中的一次自我纠正

我最先改的是 `LayoutEngine.measureNode`，并准备以"流程图标签装不下"提交。
**实测发现改前改后 `node.width` 都是 134.4** —— 说明流程图根本不走那个函数。
差一点提交一个故事讲不通的修复。

另外第一版测试用的是**短标签**，退回旧实现后照样通过，等于什么都没测；
换成句子长度的标签后，旧实现下四条立刻失败（假名、韩文、全角、扩展汉字分别
溢出 40–70px），中文英文仍通过——旧实现对这两种本来就是对的。

### 涉及文件

- `code/lib/utils/text_width.dart`（新增）
- `code/lib/ui/editor/mermaid/layout/dagre_layout.dart`、`layout_engine.dart`
- `code/lib/services/table_edit_service.dart`（改用共享实现）
- `code/test/ui/editor/mermaid/layout_geometry_test.dart`（新增，17 条）

### 顺带查证、结论为干净的部分

同一份测试还审查了 10 种流程图的布局几何：**没有方框重叠、没有负坐标、
没有越出画布、每条连线的两端都是真实存在的节点**。
