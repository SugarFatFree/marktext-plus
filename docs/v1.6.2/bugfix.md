# v1.6.2 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-262 | 2026-09-05 | 17 项权限只强制了 4 项，`document.read` 形同虚设 | P0 | 已修复 |
| BUG-263 | 2026-09-05 | SDK 三个示例返回 `panel` 却不声明 `ui.sidebar` | P1 | 已修复 |
| BUG-264 | 2026-09-05 | 打包测试写死插件版本号，每次发版要手改一遍 | P2 | 已修复 |
| BUG-265 | 2026-09-05 | 权限被强制执行，读者却没有任何地方能看到它是什么 | P1 | 已修复 |
| BUG-266 | 2026-09-05 | README 用 12 种语言承诺「安装前给你看权限」，从未成立 | P1 | 已修复 |
| BUG-267 | 2026-09-05 | 围栏闭合规则有五份实现，其中两份漂移，大纲每条都会错位 | P1 | 已修复 |
| BUG-268 | 2026-09-05 | 插件的第五份同样漂移；改写时又踩中 lua_dardo 的模式库差异 | P1 | 已修复 |
| BUG-269 | 2026-09-05 | 缩进四列的 `>` 被染成引用色，预览并不画引用 | P2 | 已修复 |
| BUG-270 | 2026-09-05 | 用 `_` 写的强调，预览画了，源码窗格一片灰 | P1 | 已修复 |
| BUG-271 | 2026-09-05 | `==高亮==` 与 `++下划线++` 同样只有预览认，showcase 一行里就能看到 | P2 | 已修复 |
| BUG-272 | 2026-09-05 | 段落里有公式或图片，复制到 Word 就丢掉全部格式 | P1 | 已修复 |
| BUG-273 | 2026-09-05 | 行内代码的两个「留白」空格是内容，搜索一开就消失 | P1 | 已修复 |
| BUG-274 | 2026-09-05 | 从源码窗格复制时无视 HTML 开关，同一段源码两个窗格结果不同 | P2 | 已修复 |
| BUG-275 | 2026-09-05 | `==高亮==` 导出到 Word 完全没有底色，上游库漏判 | P1 | 已修复 |
| BUG-276 | 2026-09-05 | 从网页粘贴时 `<mark>` `<u>` `<sup>` `<sub>` 的语义全部丢失 | P1 | 已修复 |
| BUG-277 | 2026-09-05 | 配置里一个字段类型写错，全部设置静默恢复默认 | P1 | 已修复 |

---

## BUG-262：17 项权限只强制了 4 项

### 现象

看不见——这正是问题所在。一个 manifest 里 `permissions` 写成空数组的插件，装上之后照样能在文档旁边开窗格、在侧边栏开面板、弹通知，**并且读到文档全文和选中内容**。

### 根因分析

README 承诺权限「不是只展示，而是强制执行」，理由写得很明白：这里没有任何人审核，所以由编辑器来查。FEAT-103 的验收标准也只举了 `ai.chat` 和 `document.write` 两例——**验收标准本身就是实现的镜子**，写它的时候只想到了这两条。

`PluginCommandService._guard` 的 switch 只有两个分支：

```dart
PluginAiAction() => PluginPermission.aiChat,
PluginReplaceAction() => PluginPermission.documentWrite,
```

其余动作走 `_ => null`，一律放行。

更要紧的是 `document.read`。它是读者最会掂量的那一项，而它**在任何地方都没有被读过**：`PluginScriptContext` 带着文档全文和选区，原样交给每一个插件的 `runCommand`。声明与否不改变任何行为。

### 修复方案

两处。

`_guard` 覆盖每一种**会到达读者**的动作，而不只是当初觉得重要的那两种：窗格占掉文档一半的地方，通知打断阅读，面板占据侧边栏——这些都不是插件不吭声就该拿到的。检查留在 `_guard` 这一个地方，新增的调用方不会漏掉。

`document.read` 用**扣留**而不是拒绝：没声明的插件拿到的是空文档和空选区。空文档本来就是插件必须能处理的状态（新建标签页就是），所以扣留不会把它推进一条没走过的路径；而拒绝会。

### 验证

先写 `plugin_permission_guard_test`（7 条）证明缺口存在，再修。

修完有 5 条既有测试转红，全部是测试插件没声明自己用的权限——**这正是守卫起作用的证据**，不是回归。给那些测试插件补上它们实际用到的声明。

两次突变：`_guard` 改回只查两种动作，杀 4 条；`_seen` 改成原样返回 context，杀 1 条。

### 涉及文件

`lib/services/plugin_command_service.dart`；`test/services/plugin_permission_guard_test.dart`（新增）；`plugin_modules_test`、`plugin_command_service_test`、`plugin_compatibility_test`、`plugin_apply_action_test`

---

## BUG-263：SDK 示例教了错的写法

### 现象

照 SDK 示例写的插件，面板打不开。

### 根因分析

BUG-262 修完之后浮出来的。`packages/{lua,js,dart}/manifest.json` 三份示例都返回 `panel`，`permissions` 里却没有 `ui.sidebar`。

在守卫收紧之前这不出错，所以没人发现。示例是给人照抄的——它们在教一种从今往后会被拒绝的写法。

### 修复方案

三份示例 manifest 都补上 `ui.sidebar`。

### 涉及文件

SDK 仓库 `packages/lua/manifest.json`、`packages/js/manifest.json`、`packages/dart/manifest.json`

---

## BUG-264：打包测试写死插件版本号

### 现象

`expect(manifest.version, '0.1.4')`。插件发新版，主应用测试红。

### 根因分析

一个版本号写在两个地方就会漂。这里的两处是插件仓库的 manifest 和主应用的测试。

### 修复方案

测试改成读插件仓库自己的 manifest（`_findPluginRepo()` 向上查找），比较两者一致，而不是比较一个手抄的常量。

### 验证

把插件仓库的 manifest 版本改成 `0.9.9`，测试失败——证明它读的确实是仓库而不是别处。

### 涉及文件

`test/services/packaged_plugin_test.dart`

---

## BUG-265：强制执行的权限，读者看不到

### 现象

BUG-262 让权限真的会拦人之后，一个插件的功能「没反应」时，读者**在应用里找不到任何地方**能看到这个插件声明了什么。

插件详情页有名称、版本、发布日期、是否预发布、「Community / Unverified」、简介、README、更新说明、仓库链接——唯独没有权限。已安装列表也没有。

### 根因分析

`PluginPermission.describe()` 早就写好了，17 条权限每条一句人话：

```dart
documentRead => 'Read the open document and your selection',
aiChat => 'Ask the AI model you configured (never sees your API key)',
networkRequest => 'Send requests to any server it chooses',
```

它**唯一的调用方是一个测试**。生产代码里没有任何地方展示过它。

那句 fallback——「Unrecognised permission — this version grants nothing for it」——更说明问题：它是专门写给读者看的，而它假设的那个界面从来没有存在过。

这让读者处在最糟的位置：编辑器正在替他们拒绝东西，依据的是一份他们看不见的清单。

### 修复方案

两处，都用同一个 `describe()`。

**详情页**：头部之下、README 之上，一段 Permissions。不放进 tab——一个插件被允许做什么，是决定要不要留着它的信息，不是补充材料。

只对**已安装**的插件显示。搜索结果是 GitHub 上的一个 release，manifest 在还没下载的包里；那里显示空列表会被读成「它什么都不要」，而这是编辑器没有资格给的承诺。宁可不说。

不认识的权限**照样显示**，用那句 fallback。静默丢掉这一行，会让作者和读者一起盯着一个什么都不做的插件，不知道原因是 manifest 里把 `document.read` 打成了 `documents.read`。

**拒绝通知**：原来只说标识符——`AI Assistant did not ask for the "ui.sidebar" permission`。`ui.sidebar` 是作者往 manifest 里敲的字符串，对读者没有意义。现在两样都给：句子给读者判断介不介意，标识符给要去补 manifest 的人。

### 验证

6 条新测试（`plugin_permissions_test`）+ 2 条（`plugin_permission_guard_test`）。

四次突变，每次只杀掉对应的那条：
- 不显示 → 杀 3 条
- 对未安装的也显示 → 只杀「搜索结果不显示权限段」1 条
- 过滤掉不认识的权限 → 只杀「未识别权限仍要显示」1 条
- 拒绝消息去掉人话 → 只杀「说人话」1 条

### 涉及文件

`lib/models/plugin_catalog_entry.dart`、`lib/ui/screens/plugin_detail_view.dart`、`lib/services/plugin_command_service.dart`；`test/ui/screens/plugin_permissions_test.dart`（新增）、`test/services/plugin_permission_guard_test.dart`

---

## BUG-266：README 承诺了一件从未做过的事

### 现象

README 第 100 行：

> **🔐 Permissions** | Declared in the manifest, **shown before you install**, and **enforced**.

装之前从来看不到。BUG-265 修完之后也仍然看不到——那一段只对已安装的插件显示。

### 根因分析

CLAUDE.md 列的第二条排查视角：「编辑器说了与事实不符的话」。这次说话的是 README，而且是关于**安全**的一句话——读者据此判断装一个 Community/Unverified 的插件有多大风险。

11 份翻译逐字照搬了这个承诺，所以它是 12 份文档里的 12 句不实。CHANGELOG 的 v1.6.1 条目里也有同一句。

顺带发现另一处漂移：12 份 README 都写着「2417 tests」，实际 2432。一个数字写在 12 个地方，每次加测试都会漂。

### 修复方案

改成实话：「shown on the plugin's page」——插件页面上确实列出来了（BUG-265）。12 份全改，包括阿拉伯语的 RTL 那行。

CHANGELOG 的 v1.6.1 条目删掉「and you see the list before installing」这半句。已发布条目本不该重写，但一句从未成立的安全承诺留着比改掉更糟；「enforced」改成「meant to be enforced」，因为发布时它只做到 4/17，真正做到是在 v1.6.2。

**装前展示没有做。** 那要在下载并校验 ZIP 之后、启用之前插一道确认门——浏览器扩展的做法，也是唯一诚实的「装前」。那是产品决策不是缺陷修复，留给用户定夺（见 FEAT-125 末尾）。

### 涉及文件

`README.md`、`docs/i18n/README_*.md`（11 份）、`CHANGELOG.md`

---

## BUG-267：围栏闭合规则的五份实现，两份漂移

### 现象

一篇讲 Markdown 的文档——本项目自己的 README 就是——会在 ```` 块里展示 ```。大纲面板于是把块里的 `# 标题` 列了出来，而预览不画它。**从第一处分歧起，大纲里每一条都跳到错的位置**。

### 根因分析

CLAUDE.md 列的第一条排查视角：一条规则被抄了好几份，其中一份没跟上。这次是**五份**：

| 位置 | 实现 | 是否正确 |
|------|------|---------|
| `_closesFence`（`parse`） | 同字符 + 不短于 + 无 info string | ✅ |
| 链接定义扫描 | 内联重写，等价 | ✅ |
| `headingOutline` | **`inFence = !inFence`（toggle）** | ❌ |
| `safePrefix` | **只比字符，不比长度** | ❌ |
| 高亮器 `fenceStates` | 手写，三项全查 | ✅ |

`headingOutline` 的注释自己写着「必须和 `parse()` 看到同一份文档」，而它用的是 toggle。

`safePrefix` 那份更隐蔽：它的契约是「切点绝不落在围栏中间」，而 ```` 块里的 ``` 会让它以为块已结束，于是切在代码中间。它还在循环里**每行现场构造一个 RegExp**。

### 修复方案

两处都改用 `_closesFence`——规则收敛到解析器，其他地方来问它。

高亮器那份留着手写：它每次击键跑遍全文，注释记着 RegExp 在 1.4 MiB 上要 33ms、手写不到 2ms。它是正确的，但**没有任何东西把它和其他四份绑在一起**。新增 `fence_rule_agreement_test`（9 条）做这件事：同一批刁钻文档，源码窗格的围栏判断与大纲必须给出同一份标题清单。

### 验证

- `headingOutline` 回到 toggle → 杀 3 条
- `safePrefix` 只比字符 → 杀 1 条（正是 ```` 内嵌 ``` 那条）
- 高亮器去掉长度检查 → 杀 2；去掉字符检查 → 杀 2；去掉 bare 检查 → 杀 1

**三条既有的切点测试原本什么也没测。** 它们用 1490 组「段落 + 空行」做填充，把围栏推到第 2980 行——而切点门槛是 1500 行，围栏根本进不了前缀，数它的标记数的是零个，怎么改都通过。改成让围栏**跨越**切点之后，「任何一行都闭合围栏」的变异才杀掉全部三条。

### 性能

847 KB、12000 个标题、600 个嵌套围栏块：

| | 旧 | 新 |
|---|---|---|
| `headingOutline` | 88 / 96 / 57 ms | 70 / 85 / 52 ms |
| `safePrefix` | 10 / 8 / 7 ms | 9 / 8 / 6 ms |
| 标题数 | **12600**（多出 600 个假标题） | 12000 |

没有回退，略快——`safePrefix` 不再每行 new 一个 RegExp。

### 涉及文件

`lib/services/markdown_parser.dart`；`test/services/heading_outline_test.dart`、`test/services/safe_prefix_test.dart`、`test/services/fence_rule_agreement_test.dart`（新增）

---

## BUG-268：插件里的第五份，以及 lua_dardo 的模式库

### 现象

全文翻译把含嵌套围栏的代码块切成两半，分别发给模型——正是 `blocks.split` 存在的理由（「cutting there would hand the model half a program」）。

### 根因分析

`blocks.lua` 的 `is_fence` 只看前三个字符是不是 ``` 或 ~~~，然后 `fenced = not fenced`。和 BUG-267 里的大纲是同一个错误，第六份。

### 修复方案

同样的规则：记下开启的 run（字符 + 长度 + 是否裸），闭合要求三项都对。

**改写时踩中一个更糟的坑。** 判断「围栏后面没有内容」我写的是：

```lua
bare = line:sub(i + length):match("^%s*$") ~= nil
```

在标准 Lua 里，空字符串匹配 `^%s*$` 返回 `""`，`~= nil` 为真。**在 lua_dardo（纯 Dart 实现的 Lua）里它返回 nil**，于是 `bare` 恒为 false，**任何围栏都永远不闭合**——比原来的缺陷严重得多：代码块之后的整篇文档都不再切分。

改用文件里已有的 `is_blank`，它逐字符检查，不依赖模式库。

### 验证：三次无效的破坏

这条的教训不在修复，在验证。前后写了三版测试，**头两版的变异全部无效**：

1. 第一版断言 `first.nextPrompt` 含完整代码。批次层会把切开的两半合并回 1500 字符一批，所以切没切开都通过。
2. 第二版把每一半撑到超预算——但 fixture 的代码体是**连续的行，中间没有空行**，切分无处可切，规则怎么错都是一块。三次变异，三次全过。
3. 第三版不再隔着三层看：新增 `plugin_blocks_split_test`，用真实的 `blocks.lua` 配一个只报告块边界的三行脚本，直接问 `split` 切在哪。

第三版四次变异全部被杀，每次恰好一条。而且正是它抓出了 `match` 那个坑——前两版都是通过的。

隔着三层（split → batch → 提示词模板）去观察一条规则，每一层都在吞掉信号。`ai_translate_plugin_test` 里那三条已被证明无效，一并删掉：一个声称覆盖了某件事却什么也没测的测试，比没有更糟。

### 涉及文件

插件 `lib/blocks.lua`、`CHANGELOG.md`；`test/services/plugin_blocks_split_test.dart`（新增）、`test/services/ai_translate_plugin_test.dart`

---

## BUG-269：染成引用色的行，预览不画引用

### 现象

一行缩进四列以上、以 `>` 开头的文字，在源码窗格里是引用色，预览里是普通段落。

### 根因分析

BUG-267 的同一类，第二处。高亮器的行级判断里，标题早已收敛到 `MarkdownParser.headingLevelOf`（注释写明了理由：`startsWith('#')` 会把 `#标签` 染成标题），**引用却仍是手写的**：

```dart
final withoutIndent = line.trimLeft();
if (withoutIndent.startsWith('>')) {
```

`trimLeft()` 剥掉任意多的缩进；解析器的 `_blockquoteRe` 只允许 `[ \t]{0,3}`——四列起是缩进块。两边就此分歧。

### 修复方案

解析器新增 `blockquoteDepthOf(String line)`，与 `headingLevelOf` 同一形状、同一理由；高亮器改用它。

### 验证

新增 `highlight_agrees_with_parser_test`：一组行，源码窗格染不染引用色，必须和预览画不画引用节点一致。

三次变异：高亮器退回 `trimLeft` 杀 2 条；解析器放宽缩进杀 1 条；层数恒为 1 杀 1 条。

**第二次变异一开始杀不掉任何东西**——一致性测试的固有盲区：两边读同一份规则，放宽规则是两边一起放宽，比较自然还是相等。补了一组直接断言规则本身的测试（三列可以、四列不行、`> >` 是两层）才抓得住。

### 性能

24858 行、约 1.4 MB：184/186 ms → 稳定态无差别（RegExp 比 `trimLeft` 略贵，落在噪声里）。没有加快速路径——3% 的收益不值得引入一条要单独验证的分支，何况这个解析器上的快速路径已经证伪过两次。

### 涉及文件

`lib/services/markdown_parser.dart`、`lib/ui/editor/syntax_highlighter.dart`；`test/ui/editor/highlight_agrees_with_parser_test.dart`（新增）

---

## BUG-270：用 `_` 写的强调，源码窗格一片灰

### 现象

`_倾斜_` 和 `__加粗__` 在预览里是斜体和粗体，在源码窗格里没有任何颜色。

CommonMark 给 `_` 和 `*` 同等地位，解析器一直读两种；**只有高亮器的内联规则表里只有星号**。本项目自己的文档用 `*`，所以一直没人撞上——但外面用 `_` 的文档是多数。

### 修复方案

加两条规则。`__` 必须排在 `_` 前面：循环在同一起点取先遍历到的那条。

关键在于**为什么这是安全的**：`_Pattern.accepts` 早就在问解析器的 `emphasisFlanking`，并且把标记字符传了进去——而 `_` 的 flanking 规则比 `*` 严格，正是它拒绝 `read_me_now` 里的下划线。规则本来就在共享，缺的只是两条 pattern。

### 性能：加进去慢了 50%，最后比原来更快

44858 行、约 2.5 MB：

| | 稳定态 |
|---|---|
| 原来（只认 `*`） | 314 / 324 ms |
| 加 `_` 与 `__` | **473 / 476 ms** |
| 加预扫之后 | **298 / 302 ms** |

50% 的回退不能留。原因是每一行都要为 `_` 跑一遍正则，而下划线密集的行（`snake_case`）还会反复匹配、反复被 flanking 拒绝。

修法是**一次扫描换九次正则**：先过一遍这一行，记下 `* _ \` [ ! < ~` 里哪些字符出现过；没出现的标记，对应的规则一次都不必跑。多数行一个都不含。

这不是为 `_` 打的补丁——它对原有的七条规则同样生效，所以净结果比改动前还快。

`marker` 参数**必填**而不是给默认值：一条忘了写 marker 的规则会在每一行都被跳过，而默认值和忘记传参在代码里长得一模一样。

### 验证

- 去掉 `__` 规则 → 杀 1；去掉 `_` 规则 → 杀 1
- `_` 不受 flanking 约束 → 杀 2（`read_me_now` 与 `_倾斜。_后面`），证明共享规则是必需的
- 预扫的七个字符**逐个**去掉 → 各杀 1（`_` 杀 3）

其中一条变异一开始没被抓住：预扫漏掉 `!` 时 `![alt](/img)` 仍然通过，因为链接规则会匹配它的 `[alt](/img)` 部分，而断言只问「有没有链接色的 span」。改成断言**第一个** span 是链接色才区分得开。

### 涉及文件

`lib/ui/editor/syntax_highlighter.dart`；`test/ui/editor/highlight_agrees_with_parser_test.dart`

---

## BUG-271：showcase 自己那一行，四种强调只染了一种

### 现象

`test/fixtures/showcase.md` 第 16 行：

```
~~strikethrough~~, ==highlight==, ^superscript^, ~subscript~, and a
```

源码窗格里，删除线有线，后面三个是普通文字。编辑器自带的展示文档，一行里四种强调只染了一种。

### 根因分析

BUG-270 的同一类，第三处。解析器读 `==`、`++`、`^`、`~`，渲染器六种都画；高亮器的规则表里没有它们。

### 修复方案

加 `==` 和 `++` 两条：前者用和预览一样的底色，后者用下划线。

**上下标不做，这是决定不是遗漏。** 预览把它们抬高/压低并缩小字号，用的是 `WidgetSpan`。源码窗格是 `TextField`：改一段文字的字号会带着行高和光标一起动。染成一种它不是的样子，比不染更糟。测试里有一条钉住这个决定，连理由一起。

顺带把那个底色收敛：`Colors.yellow.withValues(alpha: 0.4)` 原本在渲染器里硬编码，现在是 `HighlightColors.marked`，两个窗格读同一个值。

### 一个没有动的问题

**搜索命中的底色和 `==标记==` 的底色是同一个黄。** 在一篇有 `==标记==` 的文档里搜索，读者分不出哪个是文档里写的、哪个是刚找到的。

没有动，因为修它要挑一个新颜色——那是审美决策。而且真要做，更该做的是让这个底色跟着主题走：现在它硬编码成黄色，深色主题下配深色文字并不好读。两件事都留给用户定夺。

### 验证

四次变异，各杀 1 条：去掉 `==` 规则、去掉 `++` 规则、预扫漏掉 `=`、预扫漏掉 `+`。

### 性能

64858 行、约 3.5 MB，且刻意做成 `=`/`+` 密集（每三行一行代码）：303 ms → 312 ms，约 3%，落在噪声里。预扫（BUG-270）让新规则在不含标记的行上完全不跑。

### 涉及文件

`lib/ui/editor/syntax_highlighter.dart`、`lib/ui/editor/markdown_renderer.dart`；`test/ui/editor/highlight_agrees_with_parser_test.dart`

---

## BUG-272：段落里有一个公式，复制出去就只剩纯文本

### 现象

在预览里选中一段含行内公式（或图片、上下标、脚注引用、注音）的文字，复制，粘到 Word——**标题、粗体、链接全没了**，只有纯文字。同一段去掉公式再复制，一切正常。

### 根因分析

富文本复制的做法是：把选中的文字在「文档渲染后的文字」里定位，找到它覆盖了哪些块，再把那些块转成 HTML。

定位靠 `rendered.indexOf(selection)`。而 `plainTextOf` 构造的「渲染后的文字」和屏幕上真正的文字**不是同一串**：

预览把六种内联画成 widget——`mathInline`、`image`、`superscript`、`subscript`、`footnoteRef`、`ruby`。每个 widget 在文本里占**一个**位置，就是 U+FFFC（object replacement character），而喂给它的那些字母（LaTeX、alt 文字、指数的数字）**根本不在屏幕上，选不中**。

`plainTextOf` 返回的是那些字母。于是：

| | `Energy is $E = mc^2$ here.` |
|---|---|
| 屏幕上 / 选区里 | `Energy is ￼ here.` |
| `plainTextOf` | `Energy is E = mc^2 here.` |

`indexOf` 找不到，返回 null，复制静默退回纯文本。

showcase.md 第 21 行就有一个行内公式。

### 修复方案

`plainTextOf` 对这六种放一个 U+FFFC。图片有例外：没有 href 的图片画成 `[alt]`，是字母不是 widget，所以按 href 分支。

这份清单放在 rich copy 这边而不是解析器里——解析器不该知道任何东西是怎么画的。

### 关键：清单必须被钉住

「哪些内联是 widget」现在写在两个地方：渲染器自己的 switch，和这份清单。**又一份抄写。**

新增 `preview_placeholder_test`：真的渲染一遍，取 `RichText` 的 `toPlainText()`，和 `plainTextOf` **逐字符**比较。渲染器改了画法而清单没跟上，它立刻红。

### 验证

四次变异：`_isWidget` 恒 false 杀 7 条；清单里去掉 `mathInline` 杀 3；去掉 `image` 杀 1；去掉 `superscript` 杀 2。

### 涉及文件

`lib/services/rich_copy_service.dart`；`test/services/rich_copy_test.dart`、`test/ui/editor/preview_placeholder_test.dart`（新增）

---

## BUG-273：行内代码的两个空格是内容，不是样式

### 现象

绑定测试（BUG-272）写完当场抓到的第二条，而且比公式常见得多。

`Call \`doThing()\` when ready` 在屏幕上是 `Call  doThing()  when ready`——**代码前后各多一个空格**。

### 根因分析

```dart
children.add(TextSpan(text: ' ${span.text} ', style: s));
```

加空格是为了让背景色不紧贴字母。但**空格是内容**：它跟着被选中、被复制、被算进每一个偏移。

三个后果：

1. 富文本复制对**含行内代码的段落**同样失败——和 BUG-272 一样的原因，而行内代码到处都是
2. 复制出去多两个空格
3. **紧挨着的搜索分支从来不加空格**——所以打开查找框，同一段文字的长度就变了，行内代码的留白当场消失

### 修复方案

不加。

不是在 `plainTextOf` 里把这两个空格补上——那只修了三条里的一条，而且等于承认「文字里有一段只为了好看而存在的内容」。

**搜索打开时本来就是紧贴的**，所以「紧贴」不是新样子，只是让它一直如此。Flutter 的 `TextSpan` 给不了不引入内容的内边距；能给的只有 `WidgetSpan`，而那会让代码变得选不中、搜不到，比留白重要得多。

**如果你觉得紧贴太挤**，这条可以回退，但那要连带接受上面三个后果——或者改成 `WidgetSpan` 并放弃代码文字的可选中性。留给你定。

### 验证

恢复那两个空格 → 杀 1 条。整个测试套件里没有任何一条依赖它们。

### 涉及文件

`lib/ui/editor/markdown_renderer.dart`

---

## BUG-274：从哪个窗格复制，决定了标签是不是格式

### 现象

设置里的「行内 HTML」是关着的（默认）。源码里写 `a <b>tagged</b> word`：

- 预览里：`<b>` 是**字面文字**
- 从预览选中复制到 Word：字面文字 ✓
- **从源码窗格选中复制到 Word：变成了粗体** ✗

同一段源码，读者在哪个窗格里选的，决定了它是文字还是格式。而两个答案里没有一个是读者要的——他们关掉了那个开关。

### 根因分析

两条复制路径：

| 路径 | 节点从哪来 |
|------|-----------|
| 预览 | 渲染器的 `_cachedNodes`——跟着 `config.enableHtml` ✓ |
| 源码窗格 | `MarkdownParser(enableHtml: true)`——**写死** |

写死那处没有注释说明理由，从提交历史看也不像是刻意的。

### 修复方案

`htmlForMarkdownSelection` 把 `enableHtml` 收为**必填**参数，三个调用点（编辑菜单的复制、剪切，源码窗格的 Ctrl-C）传读者的设置。必填而不是给默认值：默认值和忘记传参在代码里长得一样。

### 顺带修好一条测试

`menu_copy_rich_guard_test` 用**精确字符串**匹配 `RichCopyService.htmlForMarkdownSelection(selected)`。参数列表一换行它就红——而换行说明不了复制有没有坏。

改成用正则取出「调用连同它的参数」，然后断言：两处都在；每一处都带 `enableHtml:`；**并且不是字面量**。

最后那条是加上去的：第一版只断言「含 `enableHtml:`」，而 `enableHtml: true` 正是要防的那个 bug，它也含这个词——变异（把一处写死回 true）没被杀掉。

### 一次自己造成的返工

改三个调用点时对 `app_menu_bar.dart` 和 `source_editor.dart` 跑了 `dart format`，重排 700 多行、真实改动只有 3 处，还踩出一条既有的 lint 错误。这正是「只对新建文件跑 dart format」这条规矩要防的事。`git checkout` 撤回后重做。

### 验证

- 忽略设置恒为 true / 恒为 false → 各杀 1 条
- 一处写死 true → 杀守卫 1 条
- 删掉一处调用 → 杀守卫 1 条

### 涉及文件

`lib/services/rich_copy_service.dart`、`lib/ui/widgets/app_menu_bar.dart`、`lib/ui/editor/source_editor.dart`；`test/services/rich_copy_test.dart`、`test/ui/widgets/menu_copy_rich_guard_test.dart`、`test/ui/editor/preview_placeholder_test.dart`

---

## BUG-275：`==高亮==` 到了 Word 就是普通文字

### 现象

`==标出来==` 导出 Word，底色完全没有。上标、下标、下划线、删除线、行内代码都正常，只有它。

### 根因分析

**上游 `docx_creator` 的判断漏了一项。** 一个 run 要不要写 `<w:rPr>`（属性块），由 `_hasFormatting` 决定：

```dart
bool get _hasFormatting =>
    isBold || isItalic || decorations.isNotEmpty || ...
    themeFill != null ||
    themeFillTint != null ||
    themeFillShade != null;      // ← 三个 themeFill 都在
                                 // ← shadingFill 不在
```

于是**只设了 `shadingFill` 的 run，整个属性块都不写**，底色随之消失。写出逻辑本身是对的（`writeShading` 检查 fill 非空就写 `w:shd`），错的是它压根没被调用。

这解释了为什么嵌套的情况反而正常：`==标出来的 **重点** 在此==` 里的「重点」还带着 bold，`_hasFormatting` 因为 bold 为真，属性块写了出来，底色跟着一起写了。**格式越多越正常，孤零零的高亮反而丢**。

### 为什么一直没被发现

Word 导出的测试只断言了两件事：文件以 `PK` 开头、字节数大于 2000。

`export_survives_new_constructs_test` 的开头注释早就点破过这件事——「现有的导出测试断言文件开头的魔数，而一个没有任何有用内容的文件也能通过」——那句话是写给旧测试的，而这个文件自己的 Word 测试仍然只做了这两件事。

变异验证时抓到的：把 Word 的上标属性去掉，全部测试照过。

### 修复方案

改用 **Word 自己的荧光笔**（`<w:highlight w:val="yellow"/>`）而不是背景填充。两个理由：

1. 那才是 `==marked==` 的意思——Word 用户认得那支笔
2. 它在 `_hasFormatting` 的列表里，能被写出来

两处都改：`_docxTextFor`（独立的高亮）与 `_withEmphasis`（折进内层 run 的高亮）。

**没有改上游。** 值得给 `docx_creator` 报一个 issue（`_hasFormatting` 漏了 `shadingFill`），但那是往别人仓库里提东西，等你点头。

### 顺带补上的覆盖

- **导出 fixture** 加进 `==高亮==`、`^上标^`、`~下标~`、`++下划线++`、`~~删除线~~`、行内公式、脚注，以及两种嵌套。HTML 侧逐个断言 `<mark>` `<sup>` `<sub>` `<u>` `<del>`。这个 fixture 的注释写着「grown rather than replaced」，而 v1.6.2 新认的那几种从没进来过
- **Word 侧第一次有了内容断言**：六种内联各自的 XML 属性

### 一条基于错误假设的测试，写完就删了

原本还写了「上标里的加粗要同时保留两者」。探针一看：`^**2**^` 的内容**根本不再解析内联**，`**` 原样留在文字里——预览也是这样。所以 `_withEmphasis` 的 `_ => run` 对上下标不是缺口，它们永远不带 children。

那条删掉了，理由写进注释：省得下次有人（包括我）又去修一个不存在的洞。

### 验证

Word 侧逐个变异，各杀 1–2 条：去掉 superscript / subscript / underline / strikethrough / highlight 的属性；`_withEmphasis` 退回 `shadingFill`。

### 涉及文件

`lib/services/export_service.dart`；`test/services/docx_nesting_test.dart`、`test/services/export_survives_new_constructs_test.dart`

---

## BUG-276：粘进来的标记，粘完就没了

### 现象

从网页复制一段带 `<mark>`、`<u>`、`<sup>`、`<sub>` 的文字粘进编辑器，格式全没，只剩words。维基百科的脚注引用（`<sup>`）、任何页面的荧光标记，都是如此。

**编辑器自己导出的 HTML 也读不回来**——它写 `<mark>`，然后不认识 `<mark>`。

### 根因分析

又是一条规则两份表，而且这两份是**互逆**的：

| | 导出写出去 | 粘贴读回来 |
|---|---|---|
| `<strong> <em> <del> <code> <a> <img> <br>` | ✓ | ✓ |
| **`<mark> <u> <sup> <sub>`** | ✓ | **✗** |

编辑器**四种全都有对应的 Markdown 语法**（`==x==`、`++x++`、`^x^`、`~x~`），只是粘贴那侧的 switch 没有这几个 case，落进 `default: index++`——标签跳过，文字留下。

**还有一层**：块级那层维护着另一份「哪些标签算内联」的清单，里面同样没有这四个，**连 `<code>` 都没有**。所以一个没有 `<p>` 包裹的片段——选中一个词复制，剪贴板里常常就是这样——顶层的 `<mark>词</mark>` 会被整个跳过。

### 修复方案

两处都补。四种转成各自的 Markdown 语法，块级清单加上这四个和 `code`。

**`^x^` 与 `~x~` 有个条件**：它们的语法定义就是「一段不含空白的文字」（解析器的 `[^\s^]+`）。把一个短语包进去，会产出一份**编辑器自己读回来是字面尖括号**的文档——那比留下纯文字更糟。所以含空白时不包。

（中文短语没有空白，照包不误，也读得回来。这一点我第一版测试搞错了：用「上面那条」断言它该保持纯文本，而那是一句关于错误对象的断言。）

### 关键：把两个方向绑在一起

新增 `html_round_trip_test`：一段 Markdown → `nodeToHtml` → `HtmlToMarkdown.convert` → **必须一字不差地回到原样**。10 种构造，从粗体到下标。

这是两张表之间第一次有东西连着。导出学会一个新标签而粘贴没跟上，它立刻红。

### 验证

- 逐个去掉 `mark` / `sup` / `sub` 的转换 → 各杀 2–3 条
- 空格检查失效 → 杀 1 条
- 块级清单退回原样 → 杀 1 条；只漏掉 `code` → 也杀 1 条

其中「块级清单」那次**第一遍没杀掉**：我的测试全用 `<p>` 包着，走的是内联路径，够不到块级那张表。补了一条顶层片段的测试才抓住。

### 顺带查过、没有做的：PDF 的内容断言

BUG-275 给 Word 补了内容断言之后，PDF 那侧同样只有 `%PDF-` 和「字节数大于 2000」。

试过了：`pdf` 包的输出用 FlateDecode 压缩，解压之后文字是**嵌入字体子集的 glyph 索引**（`[<0001>]TJ`），不是明文。要读回文字得解析字体的 cmap 反查——代价远超收益。

能确定的是每个 `InlineType` 分支都被 fixture 走到过（BUG-275 补的），所以「新类型让 PDF 导出抛异常」这一类还是抓得住的；抓不住的是静默画错。记在这里，省得下次再试一遍。

### 涉及文件

`lib/services/html_to_markdown.dart`；`test/services/html_to_markdown_test.dart`、`test/services/html_round_trip_test.dart`（新增）

---

## BUG-277：配置里错一个字段，全部设置一起没

### 现象

配置文件是 JSON，存在系统应用目录里，读者打得开也改得动。里面**任何一个** bool / 整数 / 字符串字段类型写错——比如把 `"sideBarVisible": true` 手抖写成 `"yes"`——**主题、字体、快捷键、最近文件、会话标签页全部回到默认值**，而且一声不吭。

### 根因分析

`AppConfig.fromJson` 读每个字段用的是 `json['x'] as bool? ?? 默认值`。

Dart 的 `as bool?` 对**错误类型**是抛 `TypeError`，不是返回 null——`?? 默认值` 根本轮不到。一个字段抛，整个 `fromJson` 抛；`ConfigService` 用 try/catch 兜住，回退到一份全新的默认配置。

作者**已经知道**要宽容：`fontSize`、`splitRatio` 走 `_parseDouble`，`editMode`、`aiProvider` 走各自的解析函数，坏值各自回默认。只是 37 个 bool / int / String 字段没做。

**列表更隐蔽。** `(json['sessionTabs'] as List?)?.cast<String>()`——`cast` 是**惰性**的，一个混进数字的列表在 `fromJson` 这里顺利通过，等到某处遍历它时才抛，而那时已经和配置文件没有任何看得出的联系。

### 修复方案

补上 `_parseBool` / `_parseInt` / `_parseString` / `_parseStringList`，和已有的 `_parseDouble` 一个风格。语义与原来完全一致，只是**不再抛**：错的那个字段回到自己的默认值，别的字段留下。

`_parseInt` 多接受一种：JSON 只有一个数字类型，`8000` 存下来可能读回 `8000.0`，而 `as int?` 对它同样抛。

`_parseStringList` 跳过列表里不是字符串的项，而不是让它潜伏到以后。

### 验证：一次不能区分假设的断言

四次变异，三次立刻被杀。**「int 不再接受小数」那次没有**——我的测试用的是 `{'autoSaveDelay': 5000.0}`，而 5000 **正好是这个字段的默认值**：读对了是 5000，读错了回退也是 5000，断言两种情况都满足。

换成 8000.0 才真正区分开。

### 涉及文件

`lib/core/config/app_config.dart`；`test/core/config/app_config_test.dart`
