# v1.6.2 Bug 修复记录

总览表里是这一版的缺陷，每一条在下面有一节同编号的记录。文件末尾还有几节**没有编号**的：一次开到一半掉头的改动、一次扫描的收尾、一次没找到问题的审计。它们不是缺陷，不进总览表——但它们记录了「为什么没有那样做」和「查过哪里」，那是下一个人最容易重走的路。

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
| BUG-278 | 2026-09-05 | 装了却读不进来的插件静默消失，写好的原因从没送达 | P1 | 已修复 |
| BUG-279 | 2026-09-05 | 磁盘冲突时选「覆盖」，写失败却看起来成功了 | P0 | 已修复 |
| BUG-280 | 2026-09-05 | 同一个对话框的「重新加载」，BUG-279 只修了一半 | P1 | 已修复 |
| BUG-281 | 2026-09-05 | 行内公式与脚注引用在源码窗格不染色，BUG-271 漏掉的两个 | P2 | 已修复 |
| BUG-282 | 2026-09-06 | `maxRecentFiles` 常量说 20，实际是别处硬编码的 10，而且从没被读过 | P2 | 已修复 |
| BUG-283 | 2026-09-06 | `AppConstants` 18 个常量里 14 个没人读，其中一个已经和实际分家 | P2 | 已修复 |
| BUG-284 | 2026-09-06 | 关闭看门狗从来没被撤下，正常退出会被 600ms 的 `exit(0)` 抢先 | P1 | 已修复 |
| BUG-285 | 2026-09-06 | SDK 示例逐行标注权限，五个里标了四个——漏的正是 BUG-263 那个 | P2 | 已修复 |
| BUG-286 | 2026-09-06 | SDK 的动作表没说哪些动作需要权限，而那是作者被拒时唯一要查的 | P2 | 已修复 |

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

---

## BUG-278：装上了却不在列表里，没人说为什么

### 现象

装一个 manifest 有问题的插件——键写错、runtime 拼错、`entrypoints` 里把 `windows` 打成 `windwos`——它**根本不出现在插件列表里**。没有错误，没有提示。

对读者来说，「装了但看不到」和「根本没装上」长得一模一样。于是重装一遍，还是没有。

### 根因分析

```dart
} catch (_) {
  // A broken plugin is ignored and cannot stop the editor from starting.
}
```

**忽略是对的**——一个坏插件不该让编辑器起不来，它也确实没有。**默默忽略不对**。

而且原因**早就写好了**。`PluginManifest.fromJson` 拒绝一个 manifest 时给的是一句能照着改的话：

> `unknown operating system in "entrypoints": windwos. Expected one of windows, macos, linux`

写这句话的人显然设想过它会被谁读到。它进了 `catch (_)`，**一次也没有送达过任何人**。

这和 BUG-265 是同一个形状：编辑器替读者做了判断，判断的依据读者看不到。

### 修复方案

`loadInstalled` 和新的 `problems()` 共用一次目录遍历（`_scan()`），各取一半——没有重复扫描的代码，也没有两份规则。

插件设置页在已安装列表下方多一段「Installed but unreadable」，一行一个：目录名 + 那句本来就写好的话。

两个判断值得说明：

- **没有 `manifest.json` 的目录不算坏插件。** 插件的工作文件就放在它们旁边，把那些叫做「坏插件」是一句关于无事的警告
- **`FormatException` 只取 message。** 它默认打印成 `FormatException: ...`，而类名对一个正在看「插件为什么没出现」的人是噪音

### 验证

三次变异，各杀 1–2 条：不再收集问题；把没有 manifest 的普通目录也算成坏插件；把具体原因换成一句「broken」。

### 发布之后要做的一件事

**SDK 文档要补一节「装上了却不出现怎么办」。** 它的「Trying a plugin before you ship it」讲了发布前怎么试，没讲装上之后读不进来去哪看原因——而那正是这条修复给出的答案，也正是插件作者最需要知道的。

**现在不加**，因为这个能力还在 dev 上等人工测试。在它发布之前往 SDK 文档里写「去插件页看错误」，就是 BUG-266 那个毛病的翻版：文档承诺一件还没兑现的事。

`marktext-plus-plugin-sdk` 的 README 和 11 份翻译，等 v1.6.2 出去之后。

### 涉及文件

`lib/services/plugin_manager.dart`、`lib/providers/plugin_provider.dart`、`lib/ui/widgets/plugin_panel.dart`、`lib/ui/screens/plugin_detail_view.dart`；`test/services/plugin_problems_test.dart`（新增）

---

## BUG-279：选了「用我的覆盖」，写失败，横幅消失

### 现象

文档和磁盘上的版本分叉了，编辑器给出三个选择。读者选「用我的覆盖」——**如果这次写失败**（权限、磁盘满、路径变成了目录）：

- 没有任何提示
- **冲突横幅消失了**
- 磁盘上还是对方的版本

读者得到的信号是「解决了」。这是丢工作的形状。

### 根因分析

```dart
case 'overwrite':
  await notifier.overwriteOnDisk(tab.id);   // 返回值丢掉
```

而 `overwriteOnDisk` 的 `false` **有两种含义**：

| false | 含义 |
|---|---|
| `tab?.filePath == null` | 没有文件可写——不是失败 |
| `catch (_) { return false; }` | 写失败了 |

调用方分不开，于是两个都没看。这是记忆里那条「一个 null 两种含义」的同一个形状。

**同一个应用里已经有做对的地方**：`EditorTabBar.saveTab` 用 `reportSaveFailure(e)` 说出原因，注释写着「Closing on a failed write would lose the content the save was meant to protect」。机制齐全，这两处没接上。

`rereadAs`（状态栏点编码、选一个重读）同样：读失败返回 false，调用方 `await ... ;` 连返回值都不看——读者选了 GBK，标签没变，没有任何解释。

### 修复方案

把两种 false 拆开：**前置条件不满足仍返回 false，操作失败往外抛**，和 `saveTab` 的做法一致。

调用方接住：

- 覆盖失败 → `reportSaveFailure(error)` **并且 `markDiskConflict`**——横幅必须留着，它消失就等于说覆盖成功了
- 重读失败 → `reportOpenFailure(error)`

### 验证：一个 fixture 选错了

第一版用 `${root.path}/nowhere/note.md` 当「写不进去的路径」，断言它抛——**它没抛，写成功了**：`saveDocument` 会自己建目录。换成一个已存在的**目录**路径才真正写不进去。

两处 UI 调用藏在菜单对话框和状态栏弹窗后面，widget test 够不到，用源码守卫钉住：那个调用在 try 里、catch 里有报告、覆盖那条的 catch 里还要有 `markDiskConflict`。三次变异各杀 1 条。

守卫的第一版按「两个地标之间」取区间，而 catch 在地标之后——取到的段里根本没有 catch。改成直接匹配「这个调用位于 try 内，及其后的 catch 体」。

### 涉及文件

`lib/providers/tab_provider.dart`、`lib/ui/widgets/app_menu_bar.dart`、`lib/ui/widgets/status_bar.dart`；`test/providers/write_failure_reaches_the_reader_test.dart`、`test/ui/widgets/failure_reaches_the_reader_guard_test.dart`（均新增）

---

## BUG-280：同一个 switch 里的兄弟分支，上一条只修了一半

### 现象

磁盘冲突对话框给三个选择。BUG-279 修了「用我的覆盖」，**「用磁盘上的」原封不动**：

```dart
case 'overwrite':
  try { ... } catch (error) { reportSaveFailure(error); ... }   // 上一条修的
case 'reload':
  await notifier.reloadFromDisk(tab.id);                        // 没动
```

两个 case 在屏幕上挨着，我上一轮看着它们改了前一个。

### 根因分析

`reloadFromDisk` 和 `overwriteOnDisk` 是同一个形状：`false` 既是「没有文件可读」也是「读失败了」，调用方两个都不看。

**后果比 BUG-279 轻**：读失败时状态更新在 try 块里不执行，所以冲突横幅**自己留着**——读者能看出没成功。但横幅留着只说明「冲突还在」，不说明**为什么读不了**。读者点了「用磁盘上的」，什么都没发生，横幅还在。

### 修复方案

和另外两个一致：前置条件仍返回 false，读失败往外抛，调用方 `reportOpenFailure(error)`。

三个出口（覆盖、重新加载、换编码重读）现在是同一套规矩。

### 顺带查过、没有问题的

同一个视角扫了剩下返回 `Future<bool>` 的方法：

- `moveToTrash` —— 调用方**检查了**返回值，trash 不可用时退回直接删除，而确认对话框已经说明过这一点 ✓
- `_runFileOp`（侧边栏所有文件操作的统一包装）—— `PathExistsException` 有专门的、读者能照做的消息，其余带原因显示 ✓
- `hasChangedSince` / `isEnabled` —— 查询，不是操作

### 验证

两次变异各杀 1 条：`reloadFromDisk` 退回静默 false；调用方不再接住。守卫测试也补了这一半。

### 涉及文件

`lib/providers/tab_provider.dart`、`lib/ui/widgets/app_menu_bar.dart`；`test/providers/write_failure_reaches_the_reader_test.dart`、`test/ui/widgets/failure_reaches_the_reader_guard_test.dart`

---

## BUG-281：BUG-271 漏掉的两个内联类型

### 现象

把「改一个分支就读完它的兄弟」这条用在自己当天的改动上，逐条对了一遍解析器产出的 13 种内联类型和高亮器认识的 8 种：

| 解析器 | 源码窗格 |
|---|---|
| bold / italic / code / link / image / strikethrough / highlight / underline | ✓ |
| **mathInline** | **无** |
| **footnoteRef** | **无** |
| superscript / subscript | 无——**有意**（BUG-273 的注释写了理由） |

`$E = mc^2$` 预览画成公式，源码窗格一片灰。`[^1]` 预览画成主色的上标 `[1]`，源码窗格也是灰的。

BUG-271 那轮我只补了 `==` 和 `++`。

### 修复方案

- **公式**染成 code 色。不是审美创造，是归类：在一个显示 markdown 的窗格里，公式和代码是同一类东西——一段不按普通文字读的源码。正则照抄解析器的，包括那两个前后瞻：`$` 后跟空白不开始，`$` 前是空白不结束，所以 `it cost $5 and $10` 仍然是一句关于钱的话
- **脚注引用**染成 link 色，因为预览就是用主色画它的，而主色正是链接的颜色。它不会和链接规则打架：那条要求方括号后面跟一对圆括号

### 性能：两种测量，结论相反

| fixture | 旧 | 新 |
|---|---|---|
| 刻意构造的 `$` 密集文本（每三行两个） | 335 ms | **366 ms（+9%）** |
| 真实 markdown（showcase.md ×400，0.7% 的行含 `$`） | 180 ms | **173 ms（噪声内）** |

第一个数字看着吓人，但它描述的是一份不存在的文档。真实 markdown 里含 `$` 的行不到 1%，预扫（BUG-270）让其余的行一次都不跑那条正则。

**两个都记下来**，因为只记第一个会让人以为不该加，只记第二个会让人以为没有代价。

### 验证

四次变异各杀 1 条：去掉公式规则；去掉脚注规则；公式不再要求无空白边界（`$5 and $10` 会被吃成公式）；预扫漏掉 `$`。

### 涉及文件

`lib/ui/editor/syntax_highlighter.dart`；`test/ui/editor/highlight_agrees_with_parser_test.dart`

---

## 一次开到一半掉头的改动：`show` / `ask` / `diff` 要不要权限

**不是 bug 记录，是一次判断的记录。**

上一轮我留了个问题给用户：插件动作有 8 种，权限守卫只查 4 种，`show`（悬浮卡片）、`ask`（问读者）、`diff`（展示改动）没查。留着的理由是「收紧会影响已发布的第三方插件」。

这一轮先去查影响面——GitHub topic `marktext-plus-plugin` 下**只有两个仓库，都是官方的**。第三方生态是空的，收紧的实际代价为零。于是动手了：写测试、改守卫、修被正确破坏的几个测试插件。

**然后撞上这个：**

```dart
test('showing a result needs no permission at all', () {
```

测试的**名字**就是一条明确的主张。有人特意写下过这个决定，而我推翻它的理由只是「一致性」。

### 掉头的理由

查明影响面为零，只回答了「能不能」，没回答「该不该」。而后者本来就是我留给用户的那一半。

想清楚之后，当初那个决定站得住：

**`show` 是命令回答提出命令的人。** 一个不能回答的插件什么也做不了，所以要求这个权限等于要求**每个插件**都声明它——而一个人人都持有的权限，对读者不传递任何信息。`notify` 不同：它是不必被问就能说话的那一个。

反方也是真的：卡片盖在文档上、不关不走，比一条通知占更多屏幕。

### 做了什么

撤销全部改动，把这段推理写进 `_guard`（它**看起来**就像个遗漏，所以注释首先说明「这是有意的」）和那条测试的文档注释里。正反两方都写，因为将来定这件事的人需要两边。

净改动：21 行注释，0 行行为。

### 为什么记下来

这个缺口会再被发现一次——它形状太像 bug 了。下一个人应该看到它被想过，以及想到了哪里。

---

## BUG-282：一个从来没人读过的常量

### 现象

```dart
static const int maxRecentFiles = 20;
```

`grep` 整个代码库，这个常量出现**一次**——就是它自己这行定义。真正的裁剪在另一个文件里：

```dart
if (files.length > 10) {
  files.removeRange(10, files.length);
}
```

**常量说 20，实际是 10。** 而写着"这是规则"的那一份，是死的。

### 根因分析

「一条规则抄了两份，其中一份没跟上」的极端形态：其中一份**从未生效过**。

功能上没有问题——10 的上限确实在起作用。坏的是别的：

- 任何读 `constants.dart` 的人会以为上限是 20
- 想改上限的人多半会去改常量，然后**什么也不会发生**

### 修复方案

常量改成 **10**，`addRecentFile` 引用它。

为什么是 10 不是 20：**10 是一直以来的实际行为**，是使用者见过的唯一一个数。20 从未生效过，改成它就是行为改变，而没有任何依据说 20 是当初想要的——只知道有人写下过它。不确定时不动既有行为。

上限存在的理由也写进注释了：这个列表进配置文件，而配置文件每次启动都要读。

### 验证

测试**通过常量断言**，不是写死数字——这才让常量成为规则，而不是关于规则的一句描述。

两次变异各杀 1 条：让常量和实现重新分家（常量 20、实现 10）；完全去掉上限。

### 顺带查过、没有问题的

同一个视角扫了别的阈值：`maxHighlightedLength`（128 KB）的测试用常量构造 fixture、真的跨过了阈值，还断言「不上色也要一个字都不少」；`_maxHistory` 是私有常量、两处引用一致。

### 涉及文件

`lib/core/constants.dart`、`lib/providers/settings_provider.dart`；`test/providers/recent_files_limit_test.dart`（新增）

---

## BUG-283：一个事实上已经废弃的常量文件

### 现象

BUG-282 修完一个死常量之后，把整个 `AppConstants` 数了一遍：**18 个里 14 个从来没人读**。

清点结果分三类：

| 类别 | 数量 | 例子 |
|---|---|---|
| **说了假话** | 1 | `minWindowWidth = 800`，而窗口实际最小 480（`WindowPlacement.minimumSize`） |
| **过时的遗留** | 1 | `configDirName = 'marktext-plus'`——V1.1.3 配置目录就从 `~/.marktext-plus/` 迁到系统应用目录了 |
| **和别处重复** | 12 | `defaultFontSize = 16.0` 对 `AppConfig` 的默认参数；`minFontSize/maxFontSize` 对 `app_menu_bar` 里两处 `clamp(12.0, 32.0)` |

**一个没人读的值，是一个没有任何东西负责让它保持为真的值。** 这就是它为什么会变成假话——`minWindowWidth` 和 `maxRecentFiles` 都不是一开始就错的。

### 修复方案

按「权威在哪」分开处理：

- **权威在别处的，删掉**（10 个）。`AppConfig` 的默认参数就是默认值的定义，`WindowPlacement.minimumSize` 就是最小尺寸的定义，配置路径来自 `getApplicationSupportDirectory()`。在这里再抄一份，只是多一个可以改的地方，和一个不必被改的地方
- **确实有多处读同一个值的，让它们真的去读**（8 个使用点）：应用名 2 处、字号上下限 2 处、分屏比例 2 处、防抖 300ms 4 处

剩 8 个常量，每一个都至少被两处读。

### 关键：把规矩变成能失败的东西

文件顶部本来就该有一条规矩——「**一个值放在这里，前提是至少两处从这里读它**」。写成注释，它就只是一句描述。

`constants_are_read_test` 让它成为规则：读 `constants.dart` 提取每个常量名，扫 `lib/` 下所有 `.dart`，任何一个没有 `AppConstants.<名字>` 就红，并且直接告诉你是哪几个、两条出路是什么。

### 验证

两次变异各杀 1 条：加一个没人读的常量；把某个使用点退回硬编码。

**还有一次自己造成的：** 变异 `split_editor.dart` 之后我用 `git checkout` 还原——它把这一轮**尚未提交**的改动一起抹掉了，「还原后」当场变红。和昨天 BUG-275 那次一模一样（记忆里那条「变异测试的备份取在修复之后」说的正是这个）。重新应用了。

### 涉及文件

`lib/core/constants.dart`、`lib/main.dart`、`lib/app.dart`、`lib/ui/widgets/app_menu_bar.dart`、`lib/ui/editor/split_editor.dart`、`lib/ui/editor/source_editor.dart`、`lib/ui/screens/settings_screen.dart`、`lib/services/open_document_watcher.dart`；`test/core/constants_are_read_test.dart`（新增）

---

## BUG-284：一个装上了就没人撤的看门狗

### 现象

关窗口时，`onWindowClose` 会先装一个看门狗再调用 `destroy()`：

```dart
StartupTrace.armShutdownWatchdog();   // 每 100ms 记一条，600ms 后 exit(0)
await windowManager.destroy();
StartupTrace.mark('window destroyed');
StartupTrace.flush();
```

装它的理由写在注释里，是对的：「Armed before `destroy()` rather than after, so that a `destroy()` which never returns is covered too」——关闭卡死时不能让人干等。

**问题是它再也没被撤下。** `destroy()` 返回之后（下一行 `mark('window destroyed')` 就说明它可能返回），看门狗还在跑：

- 每 100 毫秒往 trace 里写一条 `still running Nms after close began`
- 600 毫秒时 **`exit(0)`，抢在已经在进行的正常退出前面**

### 根因分析

`StartupTrace.shutdownFinished()` 就是为这件事写的——注释写着「Called when shutdown completed on its own; stops the watchdog」——而**它没有任何调用者**。

和 `PluginPermission.describe`（BUG-265）、`maxRecentFiles`（BUG-282）、整个常量文件（BUG-283）是同一个模式的第四例：**写好了、有明确用途、没接上**。

这次是接线，不是逻辑：函数本身完全正常，单元测试一写就过。

**两条关闭路径都是这样**——有未保存文件和没有的两个分支，同样的四行代码，同样都没撤。昨天记下的「改一个分支就读完它的兄弟」在这里直接派上用场，两处一起改。

### 验证

`shutdownFinished` 的行为好测（装上、等一会、撤下、确认不再有新行）；缺的是**接线**，而关闭路径藏在窗口事件后面，widget test 够不到，所以用源码守卫：每一处 `windowManager.destroy()` 之后的代码行里必须有 `shutdownFinished`。

三次变异各杀 1 条：两条路径分别去掉；把 `shutdownFinished` 变成空壳。

**守卫的第一版被自己的注释绊倒**：它取 `destroy()` 之后 300 个字符，而我给修复写的解释性注释把那行调用推到了窗口外面。改成「跳过注释行、取之后 4 行代码」——**一个源码守卫不该由注释的长度决定成败**。

### 涉及文件

`lib/ui/screens/home_screen.dart`；`test/core/diagnostics/shutdown_watchdog_test.dart`（新增）

---

## 收尾：上一轮那次扫描的剩余两项

BUG-284 是扫描「没人调用的公开静态方法」时找到的。当时列出三个真死的，修了最要紧的那个（看门狗），这里了结另外两个——**分量很小，记下来是为了那次扫描有个交代**。

- **`FileUtils.getFileName`** 是 `p.basename` 的一行转发，零调用者，而项目里到处直接用 `p.basename`。删掉：留着一个没人用的别名，只会让下一个人犹豫该用哪个
- **`CodeHighlighting.clearCache`** 不是死的——高亮缓存测试的 `setUp` 用它做测试隔离（缓存是静态的，一个测试的条目会留给下一个）。标上 `@visibleForTesting`，让「只给测试用」显式，而不是看起来像一个没有入口的功能

`getExtension` 一度也进了嫌疑名单，实际有内部调用者（`isMarkdownFile` 用它）——**扫描时同类内的调用不带 `.` 前缀**，这是第二次被它绊到。

### 顺带查过、干净的

`pubspec.yaml` 的 **27 个 dependencies，每一个在 `lib/` 里都至少被 import 一次**。没有白白打进包里的东西。

### 涉及文件

`lib/utils/file_utils.dart`、`lib/ui/editor/code_highlighting.dart`

---

## BUG-285：教人写 manifest 的文件自己漏了一个

### 现象

SDK 的两个脚本示例（Lua / JS）用行尾注释教权限：

```lua
return sdk.notify(sdk.t("error.empty"))            -- needs ui.notifications
default = sdk.storage.get("language") or "English", -- needs storage.local
    and ctx.document                                -- needs document.read
)                                                   -- needs ai.chat
```

**五个需要权限的调用，标了四个。** `sdk.panel(...)` 需要 `ui.sidebar`，什么也没说。

### 根因分析

而 `ui.sidebar` **正是 BUG-263 里三个示例 manifest 漏声明的那一个**。当时修好了 manifest——**没修教人写 manifest 的那个文件**。

修一处症状而不修产生它的地方，下一个照着抄的人会犯同样的错。

两个示例都漏（它们是同一个插件的两种写法），这次一起改——BUG-280 的教训。

### 顺带写下的一件事

示例里现在也说明了 **`show` 和 `ask` 为什么没有 `needs` 注释**：它们不需要权限，因为回答刚运行了命令的读者是插件的本分，而一个人人都要声明的权限对读者不传递任何信息。

这是昨晚那次「开到一半掉头」想清楚的结论（记在 `_guard` 和那条测试里）。放到示例里，是因为插件作者会在那里遇到这个问题。

### 验证

`sdk_examples_test` 新增一条，规则从 manifest 读而不是写死清单：

- 两个示例的 `needs` 集合必须相同（抓「改一个没改另一个」）
- 必须含 `ui.sidebar`（钉住这次）
- **注释里提到的每个权限，manifest 都得声明**（抓「注释说了 manifest 没声明」）

三次变异各杀 1–3 条：Lua 漏掉、JS 漏掉、manifest 漏声明。

### 涉及文件

SDK 仓库 `packages/lua/plugin.lua`、`packages/js/plugin.js`；`test/services/sdk_examples_test.dart`

---

## BUG-286：动作表说了每个动作做什么，没说哪个要先申请

### 现象

SDK README 的「The actions」表列了 8 种返回值、各自的效果、之后会发生什么。**没有一列说「这个需要什么权限」。**

而这恰恰是作者收到「did not ask for the ui.sidebar permission」时唯一要查的东西。

这是 BUG-285 那条线的最后一层：示例脚本的行尾注释修了（那只覆盖示例用到的几种），**系统性说明这件事的地方仍然没有**。

### 修复方案

动作表后面加四行，12 种语言各一份：

| 返回 | 需要 |
|---|---|
| `ai` | `ai.chat` |
| `replace` | `document.write` |
| `notify` | `ui.notifications` |
| `pane`、`panel` | `ui.sidebar` |

以及那句容易被当成疏漏的话：**`ask`、`show`、`diff` 不需要任何权限**，理由和昨晚写在 `_guard` 里的一样。

### 验证：一个守卫，改了三次才真正钉住

守卫的意图是「编辑器要求什么，文档就得说什么」。三版：

1. **第一版**从 `_guard` 读出「动作 → 权限常量」的映射，再拿一张**手写的**常量名→字符串表去查 README。变异「`replace` 改成要 `workspace.write`」直接走过——因为 `workspaceWrite` 不在那张手写表里，那条断言被跳过了
2. **第二版**把常量映射也从 `plugin_manifest.dart` 源码读出来。同一个变异**还是**走过——因为它在**整个 README** 里搜 `workspace.write`，而下方的权限总表列了全部 17 个，怎么改都「提到过」
3. **第三版**只在「动作 → 权限」那张表里搜

三次变异各杀 1–2 条：三种动作分别指向别的权限。

**每一版都比上一版更接近真正要钉的东西**，而每一次都是变异走过去才暴露的——一个断言查得太宽，和查错地方一样通不过检验。

### 涉及文件

SDK 仓库 `README.md` + `docs/i18n/README_*.md`（11 份）；`test/services/sdk_examples_test.dart`

---

## 审官方插件：三次扫描全是误报，一条规则值得留下

用今天的视角把 AI 助手插件审了一遍。**没有找到需要修的东西**，三次「发现」全是我的扫描太窄：

| 我以为 | 实际 |
|---|---|
| 6 个设置项一个都没被读 | `setting(key, ...)` 用**变量**取，正则只认字面量 |
| 翻译键有死的 | 都在用 |
| 权限可能多声明 | 8 个声明、8 个用到，不多不少 |

第一条差点被我当成严重缺陷——「设置页写着能改提示词，改了没用」。**先证实再下结论**，`prompts.lua` 第 120–137 行六个 `setting("writingSystem", ...)` 一字不差地对上 manifest 的六项。

这是今天第三次因为间接调用误报（前两次：同类内调用不带 `.`、`.name(` 匹配不到 tear-off）。

### 留下来的东西

手工查一次，下次还得再写一遍正则。所以把它变成守卫 `plugin_declares_what_it_uses_test`，**规则从主应用的 `_guard` 和 `PluginPermission` 读**，两个方向都钉：

- **用到了没声明** → 功能会在读者用它的那一刻被拒
- **声明了没用到** → 多要一项，读者看到的整张清单就少一分意义

SDK README 写着「Ask for what you use」。这个项目自己发布的插件是每个作者最先读到的那一个，所以那句话对它该是真的——现在是可执行的。

两次变异各杀 1 条：多声明一个 `network.request`；少声明一个 `document.write`。

### 涉及文件

`test/services/plugin_declares_what_it_uses_test.dart`（新增）

---

## 加固：「构建成功不等于构建对了」这条教训只在一个平台上生效

审 `release.yml`（473 行，之前只看过 `ci.yml`）时发现的。

Windows 的构建后面跟着一步 **`Check the machine type of what was built`**：读 PE 头的 machine 字段，和 matrix 里要的架构比对，不符就让整个 job 失败。那是 BUG-235 学来的——当时 arm64 的 job 产出了 x64 的二进制，而构建本身是「成功」的。

**Linux 也有 x64 / arm64 两个 job，也有一步专门为 arm64 装 Flutter，却没有这个检查。** 特殊处理的地方最需要验证，因为它正是「可能悄悄没生效」的那种步骤。

补上了，读 ELF 头的 `e_machine`（偏移 0x12，x86-64 是 62，AArch64 是 183）而不是靠 `file` 的措辞——那不是承诺。

**macOS 没加**：它没有架构 matrix，构建的是 runner 的原生架构，没有「要的架构」可比对。要不要出 universal binary 是产品决策，不是补一个检查能解决的。

### 验证

`release.yml` 只在推 tag 时跑，本轮 CI 碰不到它。所以在本机把那段 shell 原样跑了三种情形：架构对得上→通过；对不上→拒绝并说清要的是什么、建出来的是什么；文件不存在→拒绝。YAML 也解析过一遍，确认步骤落在 `Build Linux` 和 `Package tar.gz` 之间。

### 涉及文件

`.github/workflows/release.yml`

---

## 加固：一个为防 CI 偶发红写的工具，只有三个地方在用

回头审自己昨天写的 `shutdown_watchdog_test`——它用真实 `Future.delayed`，那类测试最容易在慢机器上偶尔翻车。连跑十次全过，那条没问题（它等的是「不发生」，本来就该固定等待）。

但顺手扫了一遍全部测试，发现 `test/support/wait_for.dart` 的存在，以及它注释里那句话：

> `tab_reload_test` **在 CI 上失败过两次，本地从没失败**——所以有了这个。

**用真实延迟的有 13 个文件，用 `waitFor` 的只有 3 个。** 这是「写好了没用上」的第五例，而且这次的代价是具体的：CI 偶发红。

### 关键是分清两种等待

它们看起来一样，其实不能互换：

| 在等什么 | 该怎么等 |
|---|---|
| 某件事**发生**（事件到达、文件被写） | **轮询**。到了就走；慢机器上比固定睡等得更久 |
| 某件事**不发生**（不该收到事件） | **固定等待**。轮询一个一开始就为真的条件会立刻返回，什么也没证明 |

按这条把两个文件里的等待逐个分类：`file_watcher_service_test` 三处等发生（900ms 一次）改轮询、三处等不发生保留；`open_document_watcher_test` 三处改、两处保留。

### 顺带变快了

那六处固定睡眠总共约 4.8 秒，现在事件到了就继续。两个文件从 6 秒降到 4 秒。

### 其余的裸等不动

widget test 里的 `runAsync(() => Future.delayed(...))` 是从 FakeAsync 里逃出来跑真实异步的必要技巧，不是在赌时间。

### 验证

改后连跑 8 次全过；全量 2546 条通过。

### 涉及文件

`test/services/file_watcher_service_test.dart`、`test/services/open_document_watcher_test.dart`
