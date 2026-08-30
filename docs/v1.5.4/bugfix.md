# v1.5.4 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-146 | 2026-08-30 | 文件被外部修改后，自动保存会静默覆盖别人的改动 | P1 | 已修复 |
| BUG-147 | 2026-08-30 | 拖图片进编辑器：插入成功的同时弹出「未打开」错误 | P2 | 已修复 |
| BUG-148 | 2026-08-30 | 韩文字数统计约为实际的三倍（按字计数，但韩语有词间空格） | P2 | 已修复 |
| BUG-149 | 2026-08-30 | 没有磁盘戳的标签页永远保存不了（BUG-146 引入，CI 抓到） | P1 | 已修复 |
| BUG-150 | 2026-08-30 | 自定义快捷键撞键时，其中一个命令永远不触发 | P2 | 已修复 |
| BUG-151 | 2026-08-30 | 日文/韩文/全角标签伸出 mermaid 节点方框 | P2 | 已修复 |
| BUG-152 | 2026-08-30 | 测试用固定 sleep 等异步保存，CI 上偶发失败 | P2 | 已修复 |
| BUG-153 | 2026-08-30 | 五处按字符数估宽的地方中文全部偏窄；连线标签不计入画布 | P2 | 已修复 |
| BUG-154 | 2026-08-30 | 导出与打印失败时毫无提示（四个入口都无错误处理） | P1 | 已修复 |
| BUG-155 | 2026-08-30 | 打开文件与帮助菜单链接失败时毫无提示 | P2 | 已修复 |
| BUG-156 | 2026-08-30 | 窗口在已拔掉的显示器上打开，用户完全看不到 | P1 | 已修复 |
| BUG-157 | 2026-08-30 | 命令行/文件管理器打开的文档没有保存冲突保护 | P2 | 已修复 |
| BUG-158 | 2026-08-30 | 关闭标签页时选择保存会静默覆盖外部改动 | P1 | 已修复 |
| BUG-159 | 2026-08-30 | 保存刚完成时，下一次保存把自己的写入误判为外部改动 | P2 | 已修复 |
| BUG-160 | 2026-08-30 | 导出失败会毁掉被覆盖的旧文件（非原子写） | P2 | 已修复 |
| BUG-161 | 2026-08-30 | 退出时若有目录/文件正在读取会抛未捕获的异步错误 | P2 | 已修复 |
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

---

## BUG-152：等异步保存用固定 sleep，CI 上偶发失败

**优先级**：P2　**状态**：已修复　**日期**：2026-08-30

### 现象

`tab_reload_test` 的「a change landing right after our own save is still
noticed」在 CI 上**第二次失败**（本地从未失败）。BUG-149 修好之后它已经连续绿了
四次（`1f0eedf`、`0a1b4c0`、`04a828e`、`204f51b`），这次又红。

### 根因分析

**四绿一红是时序不稳，不是逻辑错。** 测试是这样等的：

```dart
saving.read(tabProvider.notifier).updateContent('tab-1', 'mine');
await Future<void>.delayed(const Duration(milliseconds: 300));
expect(file.readAsStringSync(), 'mine');
```

300ms 要装下：自动保存定时器（100ms）+ 取磁盘戳 + 比对 + 编码 + 写临时文件 +
rename。本机够，CI 负载高时不够。而 BUG-146 给保存前加了一次 stat，**正是我把
这条路径变慢、把原本就紧的预算推过了线**。

### 修复方案

新增 `test/support/wait_for.dart`：轮询到条件成立，超时上限 5 秒。
**固定 sleep 是在赌一串异步工作能在选定的毫秒数内跑完**；轮询是去问结果，
而不是猜答案——条件已经成立时它立刻返回，不会让通过的测试变慢。

改了三个文件的四处等待。其中 `save_conflict_test` 与 `session_restore_test`
**是我前几轮自己新写的，埋的是同一个坑**。

### 对照实验

- 人为把自动保存拖慢 700ms（远超原 300ms 预算）：**旧写法失败，新写法通过**
- 再拖慢到 900ms：两个文件仍全部通过
- `tab_provider.dart` 的临时改动已完全还原，`git diff` 无残留

### 涉及文件

- `code/test/support/wait_for.dart`（新增）
- `code/test/providers/tab_reload_test.dart`、`code/test/services/save_conflict_test.dart`、
  `code/test/providers/session_restore_test.dart`

---

## BUG-153：按字符数估算标签宽度的地方共有五处，中文全部偏窄

**优先级**：P2　**状态**：已修复　**日期**：2026-08-30

### 现象

BUG-151 只修了节点方框那一处。顺着查下去，**同一个错误在图表代码里共有五处**，
比例还各不相同：

| 位置 | 原比例 | 决定什么 |
|---|---|---|
| `dagre_layout` 节点方框 | 0.6 / 1.0（仅基本汉字块） | 节点宽度（BUG-151 已修） |
| `dagre_layout` 连线标签 | 0.7（注释写着"中文更宽"却一刀切） | 连线标签留白与换行行数 |
| `sequence_layout` 消息标签 | 0.5 | 两个参与者之间的间距 |
| `gantt_painter` ×2 | 0.6 | 左侧任务名栏的宽度 |
| `pie_chart_painter` ×2 | 0.6 | 图例栏的宽度 |

中文按 0.5–0.7 计算而实际约 1.0，各处留白都不够：消息压到生命线上、
任务名压到甘特条上、图例挤出边界。

### 另一个独立问题：连线标签不计入画布

写测试时抓到的：`graph TD` 下 `A -->|长标签| B` 的画布宽度**只由节点右边界决定**，
`maxLabelWidth` 仅用于同层节点间距——而这条链每层只有一个节点，所以标签宽度
完全没进入画布。中文连线标签会**伸出图表自身的边界**被裁掉。

`totalWidth` / `totalHeight` 现在会取标签所需尺寸的最大值。

### 修复方案

五处全部改为调用 `estimatedTextWidth`，加上画布尺寸计入标签。

### 测试上的三次自我纠正

1. 第一版序列图/甘特图断言比的是**短英文 vs 长中文**，字符数不同，
   旧比例下也会变宽——**等于没测到比例本身**。改成**等长的拉丁文 vs 中文**。
2. 改成等长后甘特图那条**修复后仍然失败**。查明原因：甘特图左栏宽度是
   **在绘制器内部算的**，不经过 `computeLayout` 返回的尺寸，这一层观察不到。
   改为直接测共享辅助本身，并在测试文件里写明为什么甘特图和饼图不在这层断言。
3. 三处逐个退回旧实现验证：连线标签越界、时序图间距不足、共享测量一刀切，
   **各自被对应的断言抓到**。

### 一次操作失误

改甘特图和饼图时用 python 的 `'\n'.join` 写回，把**原本 CRLF 的文件整体转成了 LF**，
diff 从 18 行变成 1371 行。用 `newline=''` 保留原换行符重做后恢复正常。

### 涉及文件

- `code/lib/ui/editor/mermaid/layout/dagre_layout.dart`、`sequence_layout.dart`
- `code/lib/ui/editor/mermaid/painter/gantt_painter.dart`、`pie_chart_painter.dart`
- `code/test/ui/editor/mermaid/layout_geometry_test.dart`（+3 条，共 20 条）

---

## BUG-154：导出与打印失败时毫无提示

**优先级**：P1　**状态**：已修复　**日期**：2026-08-30

### 现象

选好文件名、按下"导出为 HTML / PDF / Word"或"打印"，**如果失败，什么都不会发生**：
没有文件、没有报错、没有提示。用户只能反复再点。

### 根因分析

四个入口 `_exportHtml` / `_exportPdf` / `_exportWord` / `_print` **都没有任何
错误处理**，而它们调用的东西确实会抛。实测（不是推断）：

| 场景 | HTML | PDF | Word |
|---|---|---|---|
| 目录不存在且不可创建 | PathNotFoundException | PathNotFoundException | DocxExportException |
| 只读位置 | PathNotFoundException | PathNotFoundException | DocxExportException |
| 路径指向一个目录 | FileSystemException | FileSystemException | DocxExportException |

这四个都是 `async void` 的事件处理器，**抛出的异常会逃逸成未捕获的异步错误**，
没有任何东西接住它。

保存路径**早就修过同样的问题**（`reportSaveFailure`，注释里写着"Ctrl+S 在只读
文件上什么都不做：没有消息，唯一的线索是那个一直不消失的修改点"）。
导出这一侧一直没有跟上。

### 修复方案

仿照 `reportSaveFailure` 新增 `reportExportFailure`，四个入口各包一层
try/catch。打印那处还会接住"本机没有打印服务"（没装 CUPS 的 Linux 就是这样答的）。
12 种语言文案齐备。

### 测试

6 条。其中一条是**结构断言**：直接读 `app_menu_bar.dart` 的源码，确认四个入口
的函数体里都出现了 `reportExportFailure`。这么写是因为真实行为需要文件选择器和
打印机才能触发，而**结构断言能覆盖将来新增的导出入口**——那正是这个 bug 会重演
的场景。

验证过它能失败：去掉 `_print` 的那一句，测试立刻点名 `_print`。

### 涉及文件

- `code/lib/app.dart`、`code/lib/ui/widgets/app_menu_bar.dart`
- `code/lib/core/i18n/l10n/*.arb`（12 种语言）
- `code/test/ui/widgets/export_failure_test.dart`（新增，6 条）

---

## BUG-155：打开文件与"帮助"里的链接失败时同样毫无提示

**优先级**：P2　**状态**：已修复　**日期**：2026-08-30

### 现象

BUG-154 的同类问题，把范围扩大后找到的：

- **文件 ▸ 打开**：选好文件后如果读不出来（权限、网络盘断开、刚被别的程序删掉），
  **没有标签页、没有提示**
- **最近打开**：存在性检查通过之后的读取同样没有兜底
- **帮助菜单里的链接**：`Uri.parse` 遇到畸形地址会抛，没有配置浏览器的机器上
  `launchUrl` 也会抛——点了没反应

### 根因分析

**侧边栏里的"打开文件"一直是有 try/catch 的**，失败时还会把加载中的标签页撤掉；
**预览里的 `_openLink` 也早就修过**同样的链接问题。菜单这一侧是没跟上的那份副本。

### 修复方案

新增 `reportOpenFailure`（12 种语言），三处各包一层。`_launchUrl` 还会区分
"地址无效"和"没有可用的处理程序"。

### 把它变成不会重来的守卫

新增一条**结构测试**：扫描四个 UI 文件里所有 `void ... async` 事件处理器，
若函数体做了文件/进程操作却没有 `catch`，测试失败。
**按形态扫描而不是列举方法名**，这样将来新增的处理器也在覆盖范围内——
这是唯一能让这类问题不再回来的办法。

### 探测器的两次自我纠正

1. **第一版正则有假阳性**：`await\s+(File|...)` 会匹配到 `await FilePicker`，
   于是 `_openFolder` 和 `_moveFile` 被误报。查证后发现 `_moveFile` 委托的
   `_relocate` 内部本就有 catch——**我差点去改两处不需要改的地方**。
   收紧为要求 `File(` / `File.` 这类真实调用形态后，两者不再报。
2. **验证守卫的鉴别力**：整段 try/catch 拿掉会被立刻点名；
   **只掏空 catch 体则抓不到**——因为一个吞掉异常的 `catch` 在它看来也是"处理过了"。
   这个边界写进了测试注释，并由另一条逐入口断言"确实调用了报告函数"来补上。

### 涉及文件

- `code/lib/app.dart`、`code/lib/ui/widgets/app_menu_bar.dart`
- `code/lib/core/i18n/l10n/*.arb`（12 种语言）
- `code/test/ui/widgets/export_failure_test.dart`（+1 条，共 7 条）

---

## BUG-156：窗口会在已拔掉的显示器上打开，用户完全看不到

**优先级**：P1　**状态**：已修复　**日期**：2026-08-30

### 现象

窗口的位置和大小在关闭时被记下、启动时原样恢复，**没有任何"是否还在屏幕内"的
检查**。于是：

- 在外接显示器上关掉应用 → 拔掉显示器 → 再打开：**应用启动了、抢到了焦点、
  却不在任何一块屏幕上**
- 调低分辨率之后同理
- 记录的窗口尺寸大于当前屏幕时，标题栏和窗口控件会跑到边界外

**这种情况用户是无法自救的**——没有东西可以拖回来，只能手工去改配置文件或删掉它。

### 根因分析

`main.dart` 直接把 `config.windowX/Y` 交给 `setPosition`，`windowWidth/Height`
交给 `WindowOptions`，中间没有任何校验。

### 修复方案

新增 `lib/services/window_placement.dart`，`fit(position, size, screens)`
是一个**不依赖任何插件的纯函数**：

- 窗口与任意一块屏幕的重叠若达到 120×40（够抓住标题栏），就原样保留——
  **有意推到屏幕边缘外一点的窗口应当回到原处**，不能一律居中
- 否则在主屏居中
- 尺寸夹在 480×320 与主屏尺寸之间
- **取不到屏幕信息时（无头会话、插件缺失）什么都不动**——凭猜测挪窗口比不挪更糟

启动路径调 `screenRetriever` 取全部屏幕，失败则回退到"按记录原样打开"。

`screen_retriever` **不是新增依赖**，它本就是 `window_manager` 的传递依赖；
只是从传递依赖改为显式声明（`pubspec.lock` 零变化，版本仍是 0.2.2）。

### 为什么做成纯函数

**本机只有一块屏幕，而这个故障需要两块才能复现。** 做成纯函数后，
可以直接构造"1920 的笔记本 + 右侧 2560 的外接屏"这类排布来测，
包括多屏排布里合法的负坐标（屏幕在主屏上方时 y 为负，不能当作越界）。

11 条测试。验证过能失败：让 `fit` 直接原样返回（即修复前的行为），6 条立刻变红。

### 涉及文件

- `code/lib/services/window_placement.dart`（新增）
- `code/lib/main.dart`、`code/pubspec.yaml`
- `code/test/services/window_placement_test.dart`（新增，11 条）

---

## BUG-157：命令行/文件管理器打开的文档没有保存冲突保护

**优先级**：P2　**状态**：已修复　**日期**：2026-08-30

### 现象

双击一个 `.md`（或从命令行传参）打开的文档，**BUG-146 加的保存冲突检测对它完全不生效**：
外部程序改写了这个文件，自动保存仍会直接覆盖，且不会有任何提示。
从菜单、侧边栏、最近文件打开的同一个文件则受保护。

### 根因分析

BUG-149 修复时，我把"磁盘戳跟着内容一起产生"落实到了各个构造点——
**但漏了 `openFilesFromSecondInstance` 这一处**。它是 Windows 单实例回调、
平台通道的 `openFiles`、以及启动时 `drainPendingFiles` 三条路径的共同终点，
也就是所有"从外部打开文件"的入口。

它当场读完内容就构造 `TabInfo`，却没有传 `diskStamp`。
按 BUG-149 定下的语义，没有戳＝没有基准＝不判冲突，所以保护静默失效了——
**而这个标签页看上去和别的完全一样**。

### 排查方式

不是碰巧看到的。逐个列出所有 `TabInfo(` 构造点并检查是否带戳：九处里五处"缺戳"，
但其中四处是 `copyWith` 或"加载中占位"（内容随后由 `loadTabContent` 连戳一起填），
**只有第二实例这一处是真漏**。

### 修复方案

补上 `diskStamp: opened.stamp`，并新增一条**结构守卫测试**：扫描五个文件里所有
把真实内容交给构造器的 `TabInfo(`，若没有 `diskStamp` 就失败。
"先建空壳、稍后填内容"的用法被排除在外，因为那条路径上戳是跟着内容走的。

验证过它能失败：把刚补的那行去掉，测试精确点名 `tab_provider.dart:772`。

### 涉及文件

- `code/lib/providers/tab_provider.dart`
- `code/test/services/save_conflict_test.dart`（+1 条，共 15 条）

---

## BUG-158：关闭标签页时选择"保存"，会静默覆盖外部改动

**优先级**：P1　**状态**：已修复　**日期**：2026-08-30

### 现象

同一个文档，**按 Ctrl+S 会被拦下并询问，关闭标签页时点"保存"却直接覆盖**——
别的程序在此期间对该文件的改动无声消失。

三个入口都受影响：关闭单个标签页、批量关闭、以及**退出应用时保存全部**。

### 根因分析

BUG-146 给保存加冲突检测时，改的是"菜单里的保存"和"自动保存"两条路径。
`EditorTabBar.saveTab` 是第三条，它走的还是无检查的 `saveDocument`。

而它恰恰是**关闭前那句"要保存吗"点"是"之后走的路径**——用户以为自己在保护工作，
实际上是在覆盖别人的。

### 排查方式

延续上一轮的做法：把 `saveDocument` / `saveDocumentIfUnchanged` 的**全部五个
调用点列出来逐个核实**，而不是等着撞见。其中两个无检查是正当的——
"另存为"到刚选的路径（没有基准可比，且选择器已经问过是否替换）、
以及用户被告知冲突后主动选择的"覆盖"。剩下那个不是。

### 修复方案

已有路径走带检查的版本；冲突时**标签页保持打开且保持已修改状态**——
关闭它会丢掉用户的编辑，换成一个他们从没见过的版本。状态栏挂上与自动保存
同一条告警，Ctrl+S 提供覆盖/重载/稍后再说三个出口。

### 守卫

新增结构测试：扫描三个文件里所有 `FileService.saveDocument(` 调用，
**上方注释未说明"为何有意无条件写"的一律判为不合格**。

这条守卫第一次跑就报了我自己保留的 `else` 分支——它是正当的，
但注释里没写清楚。**我选择把注释补清楚，而不是放宽守卫**。
之后验证：把关闭时的检查退回原样，守卫准确点名那一行。

### 涉及文件

- `code/lib/ui/widgets/editor_tab_bar.dart`、`code/lib/app.dart`
- `code/test/services/save_conflict_test.dart`（+1 条，共 16 条）

---

## BUG-159：保存刚完成的一瞬间，下一次保存会把自己的写入当成别人改的

**优先级**：P2　**状态**：已修复　**日期**：2026-08-30

### 现象

按 Ctrl+S 保存之后**立刻**再触发一次保存，会被判为"文件已被外部修改"：
保存被拒绝、状态栏挂起告警、自动保存对该文件停摆——
**而实际上改动这个文件的正是本应用自己**。

### 根因分析

`markSaved` 用 `unawaited(refreshDiskStamp(id))` 事后异步刷新磁盘戳。
写盘已经改变了文件的修改时间，而标签页手上还是写盘**之前**的戳，
落在这段窗口里的下一次保存就会比对失败。

**这正是 BUG-149 里我自己判定过的坏模式**——"事后异步补记会造出时序窗口"。
当时把自动保存那条改成了 `await _markSavedWithStamp(...)`，
**`markSaved` 这条漏了**：同一件事在两处实现，有一处没跟上。

### 实测（不是推断）

```
markSaved 之后立刻: 戳是否已过期 = true
等 120ms 之后:      戳是否已过期 = false
```

### 修复方案

`markSaved` 改为 `Future<void>`，**取戳在发布状态之前完成**，
三个调用方（关闭标签页保存、菜单保存、另存为）一并补上 `await`。
**只改函数不补 await 等于窗口还在**，所以改完专门 grep 过全部调用点。

修复后复测：紧接着检查戳已不过期，随后那次保存也能正常写入。

### 验证测试有效

把 `markSaved` 退回"沿用旧戳 + 事后异步补"的写法，该测试立刻变红。

### 涉及文件

- `code/lib/providers/tab_provider.dart`
- `code/lib/ui/widgets/editor_tab_bar.dart`、`code/lib/ui/widgets/app_menu_bar.dart`
- `code/test/services/save_conflict_test.dart`（+1 条，共 17 条）

---

## BUG-160：导出失败会毁掉被覆盖的那份旧文件

**优先级**：P2　**状态**：已修复　**日期**：2026-08-30

### 现象

导出为 HTML / PDF / Word 时，如果选的是一个**已经存在的文件**（选择器会问"是否替换"），
而导出中途失败（磁盘满、进程被杀、断电）——**旧的那份没了，新的也不完整**。
保存图表 PNG 同理。

### 根因分析

`writeAsString` / `writeAsBytes` **在打开文件的瞬间就把内容清空了**。实测：

```
写前 1000 字节
打开写句柄后 0 字节  <<< 已被截断
```

保存文档那侧早就解决了这个问题——用临时文件 + flush + rename，
注释写得很清楚："A plain writeAsBytes truncates the file and then writes
into it. Killed process, full disk, lost power…"。
**导出这侧是没跟上的那份副本。**

### 修复方案

把那段原子写抽成 `FileService.writeBytesAtomically`，
导出（HTML / PDF / Word）与图表 PNG 保存三处复用。
配置文件（`json_store`）此前已是原子写，无需改动。

图片存储与回收站记录**保持原样**：前者写的是一个刚生成的新路径（没有旧内容可毁），
后者的孤儿记录已在 BUG 记录里说明是无害的。

### 测试上的一次自我纠正

第一版测试把**文件**设成只读来制造失败，结果测试报"原文件被毁了"，
一度以为修复没生效。查证后发现是**测试设计错了**：原子写是在**目录**里建临时文件
再 rename，而 rename 覆盖一个只读文件是会成功的——
**那恰恰说明原子写在工作，不是失败**。改成把**目录**设为不可写才是真正的失败场景。

改对之后验证：退回非原子写，测试立刻报"之前那份导出被毁了"。

### 涉及文件

- `code/lib/services/file_service.dart`（抽出 `writeBytesAtomically`）
- `code/lib/services/export_service.dart`、`code/lib/ui/widgets/mermaid_renderer.dart`
- `code/test/ui/widgets/export_failure_test.dart`（+3 条，共 10 条）

---

## BUG-161：退出应用时若有目录或文件正在读取，会抛未捕获的异步错误

**优先级**：P2　**状态**：已修复　**日期**：2026-08-30

### 现象

- 打开一个较大的文件夹，读取还没完成就退出应用
- 或双击一批 `.md` 文件，还没全部打开就退出

两种情况都会抛 `Bad state: Tried to use FileNotifier / TabNotifier after
'dispose' was called`。因为这些调用**没有人 await**，异常直接逃逸成
**未捕获的异步错误**——不会被任何东西接住，也不会显示给用户。

### 实测（不是凭形态推断）

构造 40 个子目录 × 20 个文件的树、以及 30 个各 20KB 的文件，
发起读取后立刻 `dispose`：

```
loadDirectory:                 抛出 StateError — Tried to use FileNotifier after dispose
openFilesFromSecondInstance:   抛出 StateError — Tried to use TabNotifier after dispose
```

### 根因分析

`await` 之后直接写 `state`，中间没有检查 notifier 是否还活着。
**这与 BUG-149 是同一形态**——那次是标签页关闭后磁盘戳仍在异步刷新。
当时只修了撞见的那一处，没有回头把同类找全。

`_refreshTree` 也在此列：它有一个"目录已切换"的守卫，但那不是 mounted 检查，
而它是由文件系统监听器触发的——**退出流程不会等它**。

### 修复方案

三处在写 `state` 之前加 `if (!mounted) return;`。

### 守卫

新增结构测试：扫描 `lib/providers` 下所有 `StateNotifier` 子类的 async 方法，
**若在第一个 `await` 之后写 `state` 而中间没有 `mounted` 检查，即判为不合格**。
这样明天新写的方法也在覆盖内。

验证过：去掉刚加的守卫，它精确点名 `file_provider.dart:28` 与
`tab_provider.dart:768`。

### 涉及文件

- `code/lib/providers/file_provider.dart`、`code/lib/providers/tab_provider.dart`
- `code/test/providers/dispose_race_test.dart`（新增，3 条）
