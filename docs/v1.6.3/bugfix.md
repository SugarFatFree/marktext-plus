# v1.6.3 Bug 修复记录

总览表里是这一版的缺陷，每一条在下面有一节同编号的记录。文件末尾还有**没有编号**的小节：
那不是缺陷，是改动守卫本身时留下的理由。

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-421 | 2026-09-11 | 发给 GitHub 的 user-agent 写死 1.6.0，守卫照着旧形状写所以看不见 | P2 | 已修复 |
| BUG-422 | 2026-09-11 | 「关于框」的那段教训挂在了撤销/重做上 | P3 | 已修复 |
| BUG-423 | 2026-09-11 | 「每个请求都要能结束」的守卫，看不见 package:http，也就看不见它自己引用的那个好例子 | P1 | 已修复 |
| BUG-424 | 2026-09-11 | 「每个图标按钮都要说出自己做什么」的守卫，认不得 Material 3 的三个命名构造 | P2 | 已修复 |
| BUG-425 | 2026-09-11 | 更新插件会把读者填的设置删掉 | P1 | 已修复 |
| BUG-426 | 2026-09-11 | 折叠高亮的规则被前一行抽掉了匹配依据，CommonMark 得分被低估 | P2 | 已修复 |
| BUG-427 | 2026-09-11 | 缩进四列的围栏，预览当代码块、源码区当普通文字 | P1 | 已修复 |
| BUG-428 | 2026-09-11 | 一行 `` ``` aa ``` `` 开启代码块，吞掉文档后面全部内容 | P1 | 已修复 |
| BUG-429 | 2026-09-11 | 换行后以「数字.」开头的句子被变成有序列表 | P1 | 已修复 |
| BUG-430 | 2026-09-11 | 代码跨度里的反斜杠被当成转义吃掉（正则、Windows 路径） | P1 | 已修复 |
| BUG-432 | 2026-09-12 | 插件市场出错时 12 种语言的读者一律看到英文 | P1 | 已修复 |
| BUG-433 | 2026-09-12 | 引用块的竖线在阿拉伯语下站错了边 | P2 | 已修复 |
| BUG-434 | 2026-09-12 | `set_view_mode` 在模式还没切完时就答「已经切好了」；`unawaited_futures` 未启用 | P1 | 已修复 |
| BUG-436 | 2026-09-12 | 大文档抢先渲染会把 `<pre>` 块切成两半 | P1 | 已修复 |
| BUG-437 | 2026-09-12 | 给粗体加斜体会把粗体删掉；下标作用于删除线会写出代码围栏 | P1 | 已修复 |

---

## BUG-421：发给 GitHub 的 user-agent 写死 1.6.0，守卫照着旧形状写所以看不见

**现象**

插件市场每次搜索都会向 GitHub 发请求，请求头里的 user-agent 是
`MarkTextPlus/1.6.0`。应用当时已经是 1.6.2。这个字符串是对外说自己是谁——
GitHub 的限流统计、将来要按版本排查问题，看到的都是一个永远停在 1.6.0 的客户端。

**根因分析**

版本号有三处，而发布流程只盯着两处。

| 处 | 谁维护 |
|----|--------|
| `code/pubspec.yaml` 的 `version:` | 发布流程第 2 步 |
| `code/lib/core/constants.dart` 的 `appVersion` | 发布流程第 2 步 |
| `plugin_catalog_service.dart` 的 user-agent | **没有人** |

更值得记的是第二层：**这个缺陷已经有守卫了，而守卫没拦住。**

`test/core/app_version_test.dart` 的第三条「nothing else in the app writes a
version out by hand」正是为此而写——它的注释里写着「关于框曾经用字面量
`'v1.0.1'`，连着五个小版本」（BUG 见 v1.6.2 的 d3a606e）。但它的正则是
`'v?[0-9]+\.[0-9]+\.[0-9]+'`，**要求引号紧贴版本号**。那是当年坏掉的那一处的
形状，不是规则。`'MarkTextPlus/1.6.0'` 版本号前面有字，引号就不贴了，扫描读了
过去。

这是「改一个分支就读完它的兄弟」的守卫版：**守卫按现象写，下一个兄弟换个写法
就照样漏过去**。

**修复方案**

两步，顺序不能反：

1. 先把守卫从「形状」改成「规则」——在**任意引号字符串内部**找三段式版本号。
   唯一要排除的是看起来像版本号但不是的东西：`127.0.0.1` 里含有 `0.0.1`，
   所以要求匹配的前后都不能再接数字或点（`(?<![0-9.])` / `(?![0-9.])`）。
   放宽后先跑，确认它**只**点名了 `plugin_catalog_service.dart:77` 这一条，
   MCP 设置页里的 `http://127.0.0.1:$port/mcp` 没有被误伤。
2. 再把 user-agent 改成 `'MarkTextPlus/${AppConstants.appVersion}'`。

**验证**

改守卫后先看到红，失败信息正是那一行；改源码后转绿。全库放宽扫描此后命中 0 条。

**涉及文件**

- `code/test/core/app_version_test.dart`（守卫改为按规则匹配）
- `code/lib/services/plugin_catalog_service.dart`（user-agent 读常量）

---

## BUG-422：「关于框」的那段教训挂在了撤销/重做上

**现象**

`app_menu_bar.dart` 里，解释「关于框的版本号为什么曾经写死」的六行文档注释，
贴在 `stepHistory`（撤销/重做）上面，和它自己的说明混成一段；而 `showAbout`
本身一行注释都没有。

**根因分析**

d3a606e 那次修复用脚本插入注释，锚点打偏了一个方法。后果不是功能问题，是
**下一个改「关于框」的人读不到那段教训**——而那段教训的全部价值就在于此。

**修复方案**

把六行挪到 `showAbout` 上方，`stepHistory` 的注释恢复成它原本的第一句。

**涉及文件**

- `code/lib/ui/widgets/app_menu_bar.dart`

---

## BUG-423：「每个请求都要能结束」的守卫，看不见 package:http

**现象**

`test/network_calls_can_end_test.dart` 是 BUG-404（AI 流等了十五分钟）之后立的
规矩：数一数每个文件发出多少请求、限住多少次等待，少了就红。

在 `update_service.dart` 里再加一个**完全没有上限**的 `http.get`，全部测试**依然
全绿**。

**根因分析**

两层，都是同一个毛病——按当年坏掉的那个形状写，而不是按规则写。

第一层，**门槛**：

```dart
final _opensAConnection = RegExp(r'(?<![A-Za-z])HttpClient\s*\(');
...
if (!_opensAConnection.hasMatch(code)) continue;   // 整份文件被跳过
```

`update_service.dart` 用的是 `package:http`，它的客户端开在 `IOClient` 内部，
**这个文件里根本没有 `HttpClient(` 三个字**。于是它从第一天起就在守卫视野之外。

这里有个刺眼的地方：守卫自己的文档注释写着「`update_service` 限住了它的等待，
后面写的三个没有」——**它把这个文件当作正面例子引用，而它从来没读过这个文件。**

第二层，**请求计数**：

```dart
final _sendsARequest = RegExp(r'\.(?:get|post|put|delete|head|patch|open)Url\s*\(');
```

`dart:io` 的方法叫 `getUrl`，`package:http` 的叫 `get`。就算门槛放它进来，
`asked` 也会数成 0，而 `bounded` 数到那个已有的 `.timeout(` 得 1——
**0 个请求配 1 个上限，永远绿**。

**修复方案**

1. 门槛改成函数：构造了 `HttpClient` **或者**导入了 `package:http`，都算。
2. 请求计数：在导入了 `package:http` 的文件里，另外数
   `.(get|post|put|delete|head|patch|read|send)(`。
   只在这类文件里数，是因为 `.get(` 在别处太常见；`.send(` 放进来是为了流式
   那一种，出了这类文件它会和 `SendPort.send` 撞车。
3. 第二条自检测试的下限从 4 改到 5——多出来的正是 `update_service`。它同时是
   一条会说话的断言：门槛要是再缩回去，这条就红。

**验证**

变异法。修复后取备份，再往 `update_service.dart` 加一个无上限的 `http.get`：

```
Actual: ['lib/services/update_service.dart  发出 2 个请求，只限住 1 个']
```

修复前同样的变异是全绿的。还原后 `git diff` 与 HEAD 一致。

**涉及文件**

- `code/test/network_calls_can_end_test.dart`

**这一版三个缺陷是同一件事**

BUG-421 是守卫照着 `'v1.0.1'` 的形状写正则，BUG-423 是守卫照着 `HttpClient(`
和 `getUrl(` 的形状写门槛与计数。**写守卫的时候，手边只有一个坏掉的实例，
于是照着它写**；规则要靠另外问一句才写得出来——「换一种写法犯同样的错，
它还拦得住吗」。这一句现在值得对每一条扫源码的守卫都问一遍（`test/` 下有 22 条）。

已经问过、**确认防护完整**的（记下来免得重查）：

| 守卫 | 用什么变异问的 | 结果 |
|------|--------------|------|
| `every_permission_is_enforced_test` | 把 `document.read` 的门改成恒为真（字样留着） | 行为测试 `plugin_permission_guard_test` 抓住 |
| 同上 | 把「AI 动作需要 `ai.chat`」改成需要 `ui.notifications` | 三条测试同时红，含一条行为测试 |
| `sdk_schema_agrees_test` | —— | 解析 `fromJson` 自身构造体、两个方向都比，且带「读出字段少于 10 个就是取法变了」的防瞎检查 |
| SDK `check_sdk_parity` | —— | 明确防了「正则不匹配返回空集，两个空集完美一致」 |

---

## BUG-424：图标按钮守卫认不得 `IconButton.filled(`

**现象**

`icon_buttons_have_names_test` 保证每个只有图标、没有文字的按钮都带 `tooltip`
——否则读屏软件念不出它，鼠标悬停也没有提示。

往 `find_replace_bar.dart` 里塞一个**没有 tooltip** 的 `IconButton.filled(`，
测试全绿。

**根因分析**

同 BUG-421 / BUG-423，第三次：

```dart
RegExp(r'(?<![\w.])IconButton\(')
```

Material 3 里显眼一点的图标按钮写作 `IconButton.filled(`，还有
`.filledTonal(` 和 `.outlined(`。它们的 `IconButton` 后面跟的是点不是括号，
正则一个都不匹配。**守卫是照着它被写下来那天库里已有的按钮形状写的。**

今天库里还没有人用这三个构造函数，所以这是个**潜在**缺口而不是现存缺陷——
但下一个按 Material 3 惯例写的人不会收到任何提醒。

**修复方案**

`IconButton(?:\.(?:filled|filledTonal|outlined))?\(`。括号仍留在匹配末尾，
后面靠括号配对切出参数列表的那段代码不用动。

**验证**

放宽前注入变异 → 全绿；放宽后同样的变异 →
`Actual: ['lib/ui/widgets/find_replace_bar.dart:502']`。还原后工作区只剩测试文件被改。

**涉及文件**

- `code/test/ui/icon_buttons_have_names_test.dart`

---

## BUG-425：更新插件会把读者填的设置删掉

**现象**

插件的设置（AI 助手的端点、目标语言等）写在
`<插件安装目录>/<插件 id>/settings.json`——**就在插件自己的目录里**。
而覆盖安装是整目录替换：

```dart
if (await target.exists()) await target.delete(recursive: true);
await temporary.rename(target.path);
```

于是**每更新一次插件，读者填过的东西全没了**，插件回来时像是刚装上的一样。

**根因分析**

安装是原子的（解到 `.<id>.installing`、删旧、改名），这一点是对的——它保证的是
「装到一半断电不会留下半个插件」。但它把整个目录当成**插件的东西**，
而目录里有一份是**读者的东西**。

这个缺陷一直在，只是以前更新插件意味着有人专门去下一个 ZIP，一年也不见得一次。
FEAT-148 的 `install_plugin` 正是要让更新变成常规动作——**是它把这条从「能忍」
变成了「必须修」**。

**修复方案**

在删掉旧目录之前，把 `settings.json` 从旧目录复制进临时目录。

复制发生在**解包之后**，所以它会盖掉压缩包里可能带的那一份：作者打包的是默认值，
读者那份是同一个问题在更晚的时候、由这台机器的主人给出的答案。

更干净的做法是把设置搬到安装过程根本不碰的地方。那要迁移所有已存在的设置、
还要留个东西去找旧位置——比这大得多，而读者看不出任何区别。

**兄弟检查**：插件目录里还有没有别的读者状态？没有。
`state.json`（启用/禁用）、`sources.json`（来源）、`running.json`（进程）
都在**安装根目录**，不在任何一个插件的目录里。

**验证**

三条测试，两个变异都被抓住：

| 变异 | 结果 |
|------|------|
| 不再搬运 settings.json | 5 行失败（「更新插件把读者填的设置删掉了」） |
| 让压缩包里的设置优先 | 2 行失败 |

第一条测试里还断言了 `plugin.lua` 确实变成了新版本——否则「设置保住了」
可能只是因为压根没更新成功。

**涉及文件**

- `code/lib/services/plugin_manager.dart`
- `code/test/services/updating_a_plugin_keeps_its_settings_test.dart`（新增）

---

## BUG-426：折叠高亮的那条规则一直没生效，CommonMark 得分被低估

**现象**

`commonmark_spec_test` 跑官方 648 个例子，记录通过数（棘轮，只许上不许下）。
所有**带语法高亮的代码块**都算作失败——比如 ` ```ruby ` 那两例，期望
`<pre><code>def foo(x) …</code></pre>`，实得同样的文字但外面裹着一层层 `<span>`。

解析器是对的，是这份测试在说假话。

**根因分析**

`normalise()` 里两条规则的顺序反了：

```dart
out = out.replaceAll(RegExp(r' class="(?:hljs|language-)[^"]*"'), '');   // ① 删 class
final highlightSpan = RegExp(r'<span class="hljs-[^"]*">([^<]*)</span>'); // ② 按 class 匹配
```

①把 `class="hljs-keyword"` 删掉了（它以 `hljs` 开头），于是②**永远匹配不到任何东西**。
而②上方的注释写着「带颜色的 span 也会被去掉；它们的文字留着，所以代码内容真有差异
时仍然看得出来」——**这句话描述的是意图，不是发生的事**。

这是守卫失效的又一种形态：不是没写，是被它前面一行悄悄抽掉了匹配依据。
两条规则各自看都对，合起来第二条是死的。

**修复方案**

把②挪到①之前——趁 class 还在的时候拆 span。安全性：导出器只写两种 span
（`hljs-*` 与 `math-inline`，见 `export_service.dart:1004` 与 `:1274`），
②只匹配 `hljs-`，所以行内公式不受影响；这也正是注释里担心的那一种。

**得分从 495 升到 497**，而这不是解析器变好了——是它一直都对，这份测试此前没看出来。
下限随之抬到 497，并在注释里写明这一次抬的是测量而非能力。

**验证**

把两条规则的顺序换回去 → 「解析能力相比 497 例退步了」。

**涉及文件**

- `code/test/services/commonmark_spec_test.dart`

---

## BUG-427：缩进四列的围栏，预览当代码块、源码区当普通文字

**现象**

```
# 标题
    ```
# 这一行
    ```
# 那一行
```

预览把中间当成代码块（`# 这一行` 不是标题），源码区却照常把它染成标题。
**两个窗格对「代码块在哪里」的说法不一致**——这是本仓库最老的一类缺陷。

**根因分析**

围栏规则有五份实现，这里是其中两份对缩进的上限不一致：

| 实现 | 缩进上限 | 写法 |
|------|---------|------|
| 解析器 `_codeFenceRe` / `_codeFenceEndRe` | **任意空白** | `^\s*` |
| 高亮器 `_fenceRun` | **最多 3 个空格** | `while (i < 3 && … == _space)` |

CommonMark 站在高亮器这边：缩进四列是**缩进代码块**，那三个反引号属于代码内容，
不是分隔符。所以错的是解析器。

`fence_rule_agreement_test` 本来就是为「五份实现不许漂移」而写的，它没抓到，
是因为它那条「an indented fence」用的是**三个空格**——两边都接受的那个量。
**守卫照着当年出问题的那个形状写，换个量就漏过去**（与 BUG-421/423/424 同因）。

**修复方案**

`^\s*` → `^ {0,3}`，开闭两条正则都改。用空格而非 `\s` 是同一个理由：
一个制表符算四列，所以制表符缩进的围栏也不是围栏——高亮器一直就是这么做的
（它只认空格）。

**顺带的收益**：CommonMark 得分 497 → 499。

**验证**

在对账测试里补两条用例——「四列不是围栏」和「制表符不是三个空格」。
把解析器的正则改回 `^\s*`，前者立刻失败。

**涉及文件**

- `code/lib/services/markdown_parser.dart`
- `code/test/services/fence_rule_agreement_test.dart`
- `code/test/services/commonmark_spec_test.dart`（下限 497 → 499）

---

## BUG-428：一行 `` ``` aa ``` `` 会开启代码块，把文档后面全部吞掉

**现象**

在文档里写一行

```
``` aa ```
```

按 CommonMark 这是一个**代码跨度**（行内代码）。编辑器把它当作围栏的开头——
而这个围栏没有结尾，所以**它后面的整篇文档都变成了代码**。一行关于反引号的散文，
代价是整篇文档。

**根因分析**

规范里有一条：**反引号围栏的 info 串不许包含反引号**（波浪号围栏没有这个限制）。
解析器的 `_codeFenceRe` 只规定了 info 串的**第一个词**不含反引号
（`([^`\s]*)`），而正则没有锚定行尾，所以「运行长度之后整行都不许有反引号」
这条规定它表达不了。高亮器的 `_fenceRun` 同样没有这条。

两个窗格这次是**一起错的**，所以 `fence_rule_agreement_test` 不会报——
它管的是漂移，不是正确性。这一条是靠 CommonMark 规范测试挖出来的。

**修复方案**

- 解析器：新增 `_opensFence(line)`，先用 `_codeFenceRe` 判断形状，再补这条规则
  ——反引号围栏的运行长度之后整行不许再有反引号。七处「判断开围栏」的调用点
  全部改走它。**闭合不受影响**：闭合围栏后面什么都不许有，一个反引号本来就已经
  让它不成立。
- 高亮器：同一条规则，用 `indexOf(char, offset)` 而不是 `substring`
  ——它每次按键都要跑遍每一行，而只有已经带了三个反引号运行的行才会走到这里。

**顺带的收益**：CommonMark 得分 499 → 501。

**验证**（三个变异，全部被抓住）

| 变异 | 结果 |
|------|------|
| 解析器不再检查反引号 | 25 行失败 |
| 只让高亮器不检查（制造两窗格不一致） | 「backticks in the info string open nothing」失败 |
| 波浪号围栏也禁止带反引号（过度收紧） | 「a tilde fence may carry backticks」失败 |

第三条差点被我误判为「没抓住」——当时的 `grep … | head -3` 把失败行截掉了。
**过滤器会两个方向都骗人**：它既会漏报，也会让人以为没有。

**涉及文件**

- `code/lib/services/markdown_parser.dart`
- `code/lib/ui/editor/syntax_highlighter.dart`
- `code/test/services/fence_rule_agreement_test.dart`（三条新用例）
- `code/test/services/commonmark_spec_test.dart`（下限 499 → 501）

---

## BUG-429：换行后正好以「数字.」开头的句子，被变成有序列表

**现象**

```
The number of windows in my house is
14.  The number of doors is 6.
```

这是**一个句子**，只是在「14」前面换了行。编辑器把它拆成了：一个段落，
加一个 `<ol start="14">`——**段落在读者眼前被撕成两半，后半句成了从十四开始的列表项**。

散文是会换行的，所以这不是构造出来的例子。

**根因分析**

`_startsAnotherBlock`（「段落在哪里结束」的唯一决策点）里写着
`_olRe.hasMatch(lines[i])`——**任何数字加点，都能打断一个开着的段落**。

CommonMark 的规则是：**有序列表只有编号为 1 时才能打断段落**。理由正是上面那个：
以「1.」开头的行，几乎一定是有人在开一个列表；以「14.」开头的行，几乎一定是
一句话正好断在那里。GitHub 和 Typora 也都这么渲染，所以这同时也是读者在别处
见过同一份文档之后的预期。

项目符号不需要这条规则：`_ulRe` 要求标记后有内容，所以空标记本来也打断不了。

**修复方案**

新增 `_orderedInterrupts(line)`：`_olRe` 命中**且**编号为 1。只用在
`_startsAnotherBlock` 这一处。

**只管打断，且只管打断**：以数字开头的列表如果本身就是一个块的开头，
仍然想从几开始就从几开始——`10) foo` 独立成块仍是从十开始的列表，那里直接问的是
`_olRe`。

**顺带的收益**：CommonMark 得分 501 → 502。

**验证**（三个变异，全部被抓住）

| 变异 | 失败行数 |
|------|---------|
| 改回「任何数字都能打断」 | 6 |
| 连 `1.` 也不许打断（过度收紧） | 5 |
| 把规则里的 1 写成 0 | 5 |

指名的测试在 `a_wrapped_sentence_is_not_a_list_test`，五条：换行的句子不被拆、
`1.` 仍能打断、项目符号仍能打断、独立成块的 `10)` 仍从十开始、空行之后任何数字都行。

**涉及文件**

- `code/lib/services/markdown_parser.dart`
- `code/test/services/a_wrapped_sentence_is_not_a_list_test.dart`（新增）
- `code/test/services/commonmark_spec_test.dart`（下限 501 → 502）

---

## BUG-430：代码跨度里的反斜杠被当成转义吃掉

**现象**

| 写的 | 应当显示 | 实际显示 |
|------|---------|---------|
| `` `\.` ``（正则） | `\.` | `.` |
| `` `C:\temp\*.md} ``（Windows 路径） | `C:\temp\*.md` | `C:\temp*.md` |
| `` `a\_b` `` | `a\_b` | `a_b` |

**代码跨度本该是字面的**。而这个编辑器的读者写正则、写 Windows 路径，两者通常都写在
行内代码里——所以这是天天会撞上的，而且它在预览、导出的 HTML、导出的 Word 里
**一致地、安静地**丢掉那个反斜杠。

**根因分析**

解析器在跑行内正则之前，把每个 `\x` 换成一个私有区哨兵字符（这是 `\*literal\*`
不会被读成强调的原因），最后 `_restoreEscapes` 把字符还原**并去掉反斜杠**。
对散文这是对的，对代码跨度不对。

**这条规则的兄弟本来就在那儿**：`_finishSpan` 里写着「行内代码里的实体是字面的，
按 CommonMark」，并且直接返回不做实体解码。**转义是同一句规范的另一半，被漏掉了。**
又一次「改一个分支要读完它的兄弟」。

**修复方案**

`_restoreEscapes` 里按 span 自己的类型判断：代码跨度还原成 `\x`，其余还原成 `x`。
`_finishSpan` 是逐个 span 递归的，每个 span 用自己的类型，所以嵌在链接里的
代码跨度也照样是字面的。

**顺带的收益**：CommonMark 得分 502 → 503。

**验证**（两个变异，都被抓住）

| 变异 | 失败行数 |
|------|---------|
| 去掉代码跨度的例外 | 8 |
| 所有 span 都保留反斜杠（过度） | 4 |

指名测试在 `a_code_span_is_literal_test`，五条：正则保留转义、Windows 路径保留每个
分隔符、**代码跨度之外转义仍然生效**（另一半，否则「修复」会变成另一个缺陷）、
嵌在链接里的代码跨度同样字面、围栏块从来不受影响（写下来，以免以后改转义处理时
悄悄波及它）。

**涉及文件**

- `code/lib/services/markdown_parser.dart`
- `code/test/services/a_code_span_is_literal_test.dart`（新增）
- `code/test/services/commonmark_spec_test.dart`（下限 502 → 503）

---

## 无编号：文档语料里混进了第三方包，而它自称读「本仓库自己的 markdown」

**现象**

`repository_documents_test` 的开头写着「本仓库自己的 markdown……一兆字节的、
不是为解析器而写的文档」。它递归扫 `..`，于是把
`code/*/flutter/ephemeral/.plugin_symlinks/` 下的**依赖包 README** 也读了进来。

两个后果：

1. **语料不确定**。那些符号链接是 `flutter pub get` 建的，有哪些取决于配置/构建过
   哪些平台——**每台机器上读到的文档集合都不一样**，而防瞎检查
   `greaterThan(20)` 两种情况都通过。
2. **拿本项目的规矩去要求别人的文档**。其中一份 `flutter_js/example/README.md`
   有 95% 是一整块代码示例——对一个示例的 README 完全合理，而它随时可能撞上
   这个文件里的某条形状检查，让 CI 因为不是我们的东西而变红。

**修复方案**

语料排除 `ephemeral`。排除之后是 87 份**我们自己的**文档（≥500 字节），
下限从 20 抬到 50——一百多份里 20 已经发现不了取法出错了。

**顺带加了一条检查：没有代码块吞掉它所在的文档**

这是围栏规则出错时的形状，而今天的 BUG-427 和 BUG-428 都属于这一类：
前者缩进四列在预览里开了个代码块，后者一行 `` ``` aa ``` `` 开了个永不闭合的围栏。
**这类损坏在任何一条精心构造的输入里都看不出来**，在真实文档上却一目了然：
一篇文档是夹着代码的散文，不是一整块代码。

阈值有据：本仓库自己的文档里，最大的单个代码块占 **28.5%**
（`docs/v1.0.1/设计规格文档.md`）。取一半，既远高于真实最大值，又远低于「被吞掉」。

**验证**（三个变异）

| 变异 | 结果 |
|------|------|
| 把第三方文档放回语料 | 新检查立刻红（95%/65%/63% 三份） |
| 让围栏永不闭合 | 「99% of it is one code block」，多份文档同时红 |
| 撤掉 BUG-428 的修复 | **绿** —— 今天的语料里没有那种写法。如实记下来：这条检查守的是这一类，不是那一个 |

**涉及文件**

- `code/test/services/repository_documents_test.dart`

---

## BUG-432：插件市场出错时，12 种语言的读者一律看到英文

**现象**

插件市场列不出插件时，面板上显示的是：

```
could not reach GitHub; check the network or a proxy
GitHub is rate-limiting searches from this machine; try again in 819 seconds.
```

**不管读者选的是哪种语言。** 红色、无外壳、原样印出。

**根因分析**

`reader_facing_text_is_translated_test` 的开篇就写着这件事的教训：
「读者在成功时得到自己的语言，失败时得到英文，而那正是他最需要看懂的时刻」
——那条说的是 AI 配置测试失败的对话框。**同一个形状在插件市场里又出现了一次，
而守卫看不见**：它只扫 `lib/ui`，而这些句子产在 `lib/services`，经 provider
以 `String` 穿过，最后被印出来——**全程没有一个英文字面量出现在 `lib/ui` 里**。

**修复方案**

照搬本项目已有的做法：Mermaid 的失败早就是「kind 而非散文」
（`MermaidFailureKind` + 渲染器按 kind 取翻译）。**这次是把学过一次的东西
用到它的兄弟上。**

- `PluginCatalogFailureKind`：`unreachable`（连不上）、`rateLimited`（被限流，
  带 `retryAfter` 秒数）、`other`（技术细节，原样）
- `PluginCatalogException` 让 kind **穿过 throw**——秒数是从响应头算出来的，
  一旦变成英文句子就再也读不回来
- `describeFailure` / `describeError` 改为「同一份失败渲染成英文」，
  所以自动化接口读到的句子和面板翻译用的 kind **不可能各说各话**
- 三个 l10n 键 × 12 种语言。只翻译读者**能据以行动**的两类；
  第三类是技术细节（状态码、摘要不匹配），保持原样

**为什么只翻两类**：告诉读者「连不上，查网络或代理」和「等 47 秒」是他能照做的；
把「GitHub topic search returned 500」翻译成十二种语言，对谁都没有帮助。

**守卫也扩了**：扫描范围从 `lib/ui` 加上 `lib/providers`——provider 持有的正是
界面要显示的东西。今天扩过去**一条都不点名**，正是重点：代价为零，堵住了这条路。

**验证**（三个变异）

| 变异 | 结果 |
|------|------|
| 限流丢掉秒数 | 9 行失败 |
| `SocketException` 归为 `other`（翻译失效） | 9 行失败 |
| 面板改回直接印 `describe()` | **第一次没被抓住**——编译通过、全绿 |

第三条是重点：**映射测了，调用点没人钉**。补了一条组件测试，用 `zh` 语言环境
把面板搭起来，断言屏幕上出现的是中文那句、且**不出现**英文那句；再跑同一个变异，
它红了。另有一条断言限流的秒数确实到了屏幕上。

**涉及文件**

- `code/lib/services/plugin_catalog_service.dart`（kind、异常、一份来源）
- `code/lib/providers/plugin_provider.dart`（失败带类型而非字符串）
- `code/lib/ui/widgets/plugin_panel.dart`（按 kind 取翻译）
- `code/lib/core/i18n/l10n/app_*.arb`（3 键 × 12 语言）
- `code/test/services/a_failed_search_speaks_the_readers_language_test.dart`（新增）
- `code/test/ui/widgets/a_failed_search_is_shown_translated_test.dart`（新增）
- `code/test/ui/reader_facing_text_is_translated_test.dart`（扫描范围扩到 providers）

---

## BUG-433：引用块的竖线在阿拉伯语下站错了边

**现象**

引用块左侧有一条 3px 强调色竖线。阿拉伯语（以及任何在设置里选了从右往左的读者）
文字从右侧开始，**而竖线还在左边**——它落在引用块的另一头，离它标记的文字最远。
这是 RTL 布局最一眼能看出来的那种错。

同一处还有第二个：源码窗格行号栏与代码之间的 1px 分隔线固定在 `right`。
行号栏在 RTL 下会翻到右边（`rtl_keeps_code_readable_test` 量过），
**而那条边线没跟着翻**。

**根因分析**

`layout_follows_the_reading_direction_test` 正是为这件事写的，它的正则点名了
`Alignment.centerLeft`、`EdgeInsets.only(left:)`、`TextAlign.left`、
`Positioned(left:)`——**但没有点名 `Border(left:)`**。

又一次「守卫照着当年坏掉的那个形状写」。它的注释里列了十三处当初的问题，
全是对齐与内边距；边框不在那份名单上，于是这两处一直在。

**修复方案**

- 引用块：`Border(left:)` → `BorderDirectional(start:)`
- 行号分隔线：`Border(right:)` → `BorderDirectional(end:)`（它属于「行号栏靠代码
  那一侧」，不是「右侧」）
- 守卫补上 `Border(\s*(left|right)\s*:` 与 `BorderRadius.only(topLeft|…)`。
  圆角今天一处都没有——**正是最便宜的时候补**

**验证**（两个变异）

| 变异 | 结果 |
|------|------|
| 竖线改回 `Border(left:)` | 源码守卫点名到行号 |
| 同上 | 新的组件测试也红：「引用块的竖线还是固定在某一侧」 |

新测试从**真实构建的组件树**读那个边框而不是 grep 源码——旁边那条文件守卫只能说
「没写 `Border(left:`」，换个方式拼出来的装饰它看不见。Flutter 自己怎么翻
`BorderDirectional` 不由这条测试复验，那是 Flutter 的测试该管的。

**同时查过、判为不值得改的**：`EdgeInsets.fromLTRB` 在 `lib/ui` 有 10 处，
其中 4 处左右不对称，差值 2–8 px。RTL 下这些会镜像错，但**肉眼几乎看不出**，
而把它们全改成 `EdgeInsetsDirectional.fromSTEB` 要动 10 处、收益是几个像素。
记在这里，以免下次重新发现。

**涉及文件**

- `code/lib/ui/editor/markdown_renderer.dart`
- `code/lib/ui/editor/source_editor.dart`
- `code/test/ui/layout_follows_the_reading_direction_test.dart`
- `code/test/ui/editor/rtl_keeps_code_readable_test.dart`

---

## BUG-434：`set_view_mode` 在模式还没切完时就答「已经切好了」

**现象**

MCP 的 `set_view_mode` 不等 `setEditMode` 完成就返回
`view mode is now split`。代理设完模式立刻 `get_state`，可能读到**旧模式**。

**这是「编辑器说了与事实不符的话」的又一例**——本项目排查缺陷的第二条视角。

**根因分析**

`setEditMode` 返回 `Future<void>`（它要写配置文件），而调用处既没 `await`
也没 `unawaited()`。**而 `unawaited_futures` 这条 lint 没有启用**，所以分析器
一声不响。

`unawaited_guard_test` 的标题是「启动了工作却不等它」，两次被证明是缺陷而不是选择
（BUG-149、BUG-159）。但它只认 `unawaited(` **这一种拼法**——最常见的那种
（裸调用一个返回 Future 的函数）它看不见，因为没有 lint 把裸调用逼成那两种写法之一。
**守卫照着当年出问题的那个形状写，而规则是「不等就要说清楚」。**

**修复方案**

1. `set_view_mode` 改为 `await`——答复说它已经发生了，那它就得已经发生。
2. **启用 `unawaited_futures`**。启用时 `lib` 里有 13 处、`test` 里 2 处裸调用。
3. 逐处判断：12 处是有意的（对话框、启动时的窗口管理器往返、写最近文件列表、
   写设置），包成 `unawaited()` 并在上方写明理由——**理由是 `unawaited_guard_test`
   要求的，于是这条守卫从此覆盖它们**。
4. 顺手修了守卫自己的一个毛病：它对 `not awaited` **大小写敏感**，
   而句首大写的「Not awaited」是任何人都会这么写的——一条正确的理由被判成缺失。

**为什么全部包成 `unawaited()` 而不是改成 `await`**：包裹**不改变运行时行为**，
加 `await` 会改变时序。除了 `set_view_mode` 那一处（答复的诚实性取决于它），
其余都保持原样行为，只是把隐形的决定变成了写下来的决定。

**过程中踩的坑**：第一次我写脚本批量包裹，用「语句结束于第一个以 `);` 结尾的行」
判断边界——对嵌套调用是错的，弄坏了五个文件（97 个分析错误）。全部还原、改为手工
逐处处理。**这正是「脚本生成 Dart 后必须验证」那条记忆。**

**验证**

`dart analyze --fatal-infos lib test` 干净（开着新 lint），全量 3181 条测试绿。
`unawaited_guard_test` 现在覆盖全部 14 处 `unawaited(`，每一处都有理由。

**涉及文件**

- `code/analysis_options.yaml`（启用 lint）
- `code/lib/providers/mcp_provider.dart`（`await`）
- `code/lib/app.dart`、`main.dart`、`providers/file_provider.dart`、
  `ui/screens/home_screen.dart`、`ui/widgets/{app_menu_bar,editor_tab_bar,side_bar}.dart`
- `code/test/services/unawaited_guard_test.dart`（不分大小写）
- `code/test/ui/screens/settings_fields_test.dart`

---

## 无编号：裸 `return` 的守卫只认两种写法中的两种

`lua_bare_return_test` 拦的是「`lua_dardo` 里嵌套函数中的裸 `return` 是空操作」
——守卫写不守，`while true` 里就是死循环，**读者看到的是编辑器不再响应**。

它的正则是 `\breturn\s*(end\b|$)`：只认「单独一行的 return」和「return end」。
Lua 允许的其余写法它都看不见：

| 写法 | 旧正则 | 现在 |
|------|--------|------|
| `return` 独占一行 | ✓ | ✓ |
| `then return end` | ✓ | ✓ |
| `then return; end` | ✗ | ✓ |
| `then return else …` | ✗ | ✓ |
| `return  -- nothing to do` | ✗ | ✓ |

今天已发布的 Lua 里三种漏网写法都不存在——**潜在而非现存**。补它的理由和
Material 3 图标按钮那次一样：代价是三个正则分支，而症状是「编辑器卡死」。

**同时把这条检查放进了 SDK 自己的 `check.py`。** 原先唯一检查它的是主应用仓库的
测试，而那条测试只在**主应用**推送时跑——改坏 SDK 示例要等到下一次主应用推送
才会被发现。守卫应当在能破坏它的那个仓库里。

**验证**：三种写法逐个注入到已发布插件的 `blocks.lua`，每次都被点名（2 行失败）；
SDK 侧注入到 `packages/lua/plugin.lua`，报「packages/lua/plugin.lua:59 的 return
不会真的返回」。两边都还原干净。

**涉及文件**

- `code/test/services/lua_bare_return_test.dart`
- SDK 仓库 `scripts/check.py`（新增 `check_no_bare_return`）

---

## BUG-436：大文档的抢先渲染会把 `<pre>` 块切成两半

**现象**

超过 1500 行或 200 KB 的文档，解析器先解析一个**前缀**并立即上屏，整篇随后替换
（这是「加载快、支持大文件」的实现）。前缀必须在「什么块都不在里面」的空行处切断。

围栏代码块和 front matter 都被跟踪着，**而 `<pre>` / `<script>` / `<style>` /
`<textarea>` 没有**。这四种标签的规则是「内容一直到闭合标签，多远都算」
（解析器自己在 `_rawTextHtmlTags` 旁边这么写的），所以：

1. 切点落进 `<pre>` 内部 → 前缀里有 `<pre>` 没有 `</pre>`
2. 那个未闭合的块**吞掉它后面的全部前缀内容**
3. 读者看到自己文档的顶部有一大块被当成原始文本渲染，直到整篇解析到达
4. 那个窗口里最后一个块的**源范围是错的**——而「在预览里编辑一个块」正是靠源范围

**块内的空行是这条路能走通的前提**：切点找的是「在一切之外的空行」，
而块内部的空行并不在一切之外。

**根因分析**

又一次「守卫照着形状写」。`safe_prefix_test` 有 11 条用例，其中三条专门讲
「切点永不落在围栏内」（含嵌套围栏、波浪号围栏），一条讲 front matter——
**它把「不能被切开的块」当成了「围栏和 front matter」这两个具体的东西，
而规则是「任何延续到闭合标记的块」**。

**修复方案**

`safePrefix` 里像跟踪围栏那样跟踪原始文本 HTML 块：遇到 `<pre` 之类的开标签
（且同一行没有闭标签）就记下要等的闭标签，在那之前一律不切。

**探测过程值得记**：我第一次构造的测试文档里，块**内部没有空行**——三种块都
完整落在前缀里，看起来「没问题」。是想到「切点取在空行处」才把空行放进块里，
`<pre>` 立刻被切开了。**构造不出来的条件等于没测**。
数学块 `$$…$$` 在同样的构造下没有被切开，所以只修了确认有问题的这一类。

**验证**

四种标签各构造一次；撤掉跟踪后报「`<pre>` 被切成两半，前缀里没有它的闭合标签」。


### 第一次修得不全，数学块也在被切（同日追记）

上面那次只修了 `<pre>` 一族。我当时用一个探测脚本判断「数学块有没有被切开」，
它报「没有」——**而它是这么判断闭合的**：

```dart
prefix.contains('\n$$\n')
```

`$$` 的**开标签本身就是 `\n$$\n`**，所以探测器找到开标签、当成了闭标签。
**探测器骗了我**，而我据此写下了「只修确认有问题的那一类」。

真正看出来的是另一件事：`safe_prefix_test` 里那条对所有真实文档跑的用例
（「every fixture either stays whole or splits cleanly」）**只比较每个块的
`sourceStart`**。而被切坏的**恰恰是前缀里最后一个块，它的起点必然是对的**——
所以那条用例对这一整类缺陷是瞎的。

把它加强成同时比较 **`type` 与 `sourceEnd`**（正确切断时前缀里每个块都完整，
三个字段都该一致），并补了一份合成文档：七种「延续到闭合标记」的块，
每种内部都带空行，尺寸越过阈值。加强后**立刻报出数学块**：

```
maths 第 740 块的结束行对不上——切点把它截断了，而它的起始行看起来完全正常
```

**三个变异，第三个是关键证据**：

| 变异 | 结果 |
|------|------|
| 撤掉数学块跟踪 | 点名 maths |
| 撤掉原始文本 HTML 跟踪 | 点名 pre |
| **断言退回只比 `sourceStart`（缺陷仍在）** | **全部通过** |

最后一条证明了旧断言确实看不见它——不是「碰巧没有这样的文档」，是**问错了问题**。

**涉及文件**

- `code/lib/services/markdown_parser.dart`
- `code/test/services/safe_prefix_test.dart`

---

## 无编号：被测的那个压缩包，不是发出去的那个压缩包

`packaged_plugin_test` 的开篇写着「**即将被上传、安装、运行的那个 zip**」，
四条用例把它解开、装上、真的跑一遍。它存在的理由也写在那里：
「插件被『安装』成只有入口文件，也就是半个插件——这已经发生过两次」。

**而它测的不是发出去的那个包。**

| | 由谁产生 | 内容 |
|---|---------|------|
| 被测的 | `ci.yml` 里一行 `zip -qr . -x '.git/*' -x '.github/*'` | 整棵树，**含 `docs/`** |
| 发出去的 | **人手工挑路径**（插件仓库没有打包脚本，我发 v0.1.5 时照着 v0.1.4 的样子拼） | 8 个文件，不含 `docs/` |

两者不同，而且方向最糟：被测的是**超集**。发布包里少了 `lib/prompts.lua`，
CI 照样全绿——**而「人按先例手工挑路径」恰恰就是那两次事故的形状**。

**修复方案**

打包只留一份定义：插件仓库新增 `scripts/pack.py`，**列出要装什么而不是排除什么**
（排除清单每加一个目录就长一个洞，而这个文件回答的是「一个插件是什么」）。
`ci.yml` 改为调用它，于是被测的包与发出去的包是同一个东西。

**验证**

脚本产物与已发布的 v0.1.5 逐条比对，八个文件一致。两个变异：
清单里去掉 `lib` → 四条里红两条；去掉 `manifest.json` → 在 `setUpAll` 就红。

**涉及文件**

- `.github/workflows/ci.yml`
- 插件仓库 `scripts/pack.py`（新增）

---

## 无编号：那条「守卫不跑比没有更糟」的元守卫，自己能被一句注释满足

`a_gated_test_is_a_test_that_runs_test` 的存在理由写得很清楚：
`packaged_plugin_test` 等一个 `PLUGIN_ZIP`，而**没有任何地方设置它**，
四条用例从写下那天起从未运行过——「而这比没写更糟：套件把它报成 skipped，
读起来像『此处不适用』而不是『到处都没跑过』，于是那份『我们检查了什么』的清单
说压缩包是被覆盖的」。

**它自己有两个同样的洞。**

**洞一：只要名字在文件里出现就算数。** 它用的是
`workflow.contains(gate.key)`——而 ci.yml 的**注释里**就写着 `PLUGIN_ZIP`
（正是解释这条测试为什么存在的那段）。变异验证：删掉真正设置它的那一行、
注释留着，**守卫依然全绿**。

改法：先剥掉注释行，再要求名字以**赋值**形式出现（`NAME=` 或 `NAME:`）。
前者对应 `echo "NAME=…" >> $GITHUB_ENV`，后者对应 `env:` 块；
光秃秃的名字是有人在谈论它。

**洞二：只认一种拼法。** 它找的是 `Platform.environment['NAME']`，
而 `plugin_js_runtime_test` 用的是 `Platform.environment.containsKey('NAME')`。
于是——

### 由此暴露的真实缺口：JavaScript 引擎没有任何端到端测试跑过 —— **已修复**

`the engine runs a plugin end to end` 是**唯一**真正启动 QuickJS、跑一个 JS 插件
的测试。它的开关 `MARKTEXT_QUICKJS_AVAILABLE` 在 ci.yml 里**一处都没有**，
所以它从来没跑过。

**我第一次写这一节时的结论是错的。** 我当时写「它在 `flutter test` 下确实跑不了，
所以只能记成一条豁免」——理由是测试注释上那句「`flutter test` 没有 QuickJS 库」。
**那是一句断言，我把它当成了测量。**

**实际情况**：那个库是 `flutter_js` 包里**预编译随包分发**的
（`~/.pub-cache/.../flutter_js-*/linux/shared/libquickjs_c_bridge_plugin.so`，
940 KB，就在磁盘上）。Linux 上绑定用 `DynamicLibrary.process()` 查符号——
也就是说符号只需要**在进程里**，而 `DynamicLibrary.open(那个文件)` 正好把它放进去。

试出来的过程：先用 `LD_PRELOAD` 跑，报错从「库不在」变成「Binding 尚未初始化」
——**错误换了一个，说明第一个问题已经不成立**；补上
`TestWidgetsFlutterBinding.ensureInitialized()`，8 条全过。再改成测试自己
`DynamicLibrary.open`，连环境变量都不需要了。

**结果**：环境变量开关删除，端到端用例**每次 CI 都真的运行**。
全量跳过数从 5 降到 4，少的那一条就是它。

Windows 走的是另一条路（按插件注册名加载 DLL，测试没有应用外壳去做这件事），
那里仍然跳过——这一点是实测的：把库路径改成找不到，用例优雅跳过而不是失败。

**这一整晚我都在对守卫问「这是它见过的现象，还是它要守的规则」。这一次，
我对一句代码注释犯了同样的错。**

**验证**（两个变异，结构互补）

| 变异 | 结果 | 说明 |
|------|------|------|
| 删掉 ci.yml 里 `PLUGIN_ZIP` 的赋值、注释留着 | 点名 `PLUGIN_ZIP` | 证明「名字出现即算数」的洞已堵上 |
| 让 QuickJS 库找不到 | 端到端用例优雅跳过，不是失败 | 证明它对别的平台仍然温和 |

**顺带修的第三个洞**：堵上前两个之后，我自己新写的「在 pub cache 里找库」的代码
读了 `HOME` 和 `PUB_CACHE`，**被这条守卫当成了新的开关**。但它们是用来**找文件**的，
不是「没有就不跑」。区别在于**有没有兜底**：带 `??` 的读取是测试在说「我不等谁」。
守卫现在先剔除带兜底的读取——同一个形状问题的镜像，它把「读了环境变量」
当成了「等着环境变量」。

**涉及文件**

- `code/test/a_gated_test_is_a_test_that_runs_test.dart`

---

## 无编号：「没有东西被定义了却无人使用」只看类型，不看方法

`nothing_is_written_and_left_unused_test` 的开篇说得很清楚：
「**写好了却没接上**，是这个仓库反复产出的一种形状；而当死代码还在描述编辑器
如何工作时，它比单纯浪费更糟——`DiagramWidget` 的文档注释说 Mermaid 在导出的
HTML 里由 CDN 脚本渲染、预览里只显示图表源码，两件事都早已不成立，
于是任何打开那个文件的人学到了两条假的架构知识。」

**它实现的是「类型」，而规则是「任何被定义却无人使用的东西」。**

**能不能扩到方法？不能——而这一条也是结论。** 方法用量靠正则判断不可靠：
`PluginCatalogService.fetch` 和图片缓存的 `_loadedPictures.fetch` 同名，
没有类型解析分不清谁在被调用。**误报的守卫比没有更糟**（本项目自己的原则：
一条会自己变红的性能测试比没有还糟，因为它教所有人无视红色）。

**所以：不扩守卫，但把找到的那段死代码删掉。**

`PluginCatalogService.fetch(Uri registryUrl)`——25 行，`lib` 与 `test` 里**零调用**。
它是这个市场原本打算做的「有人审核的注册表」，后来改成了按 GitHub Topic 的开放发现。

而它正是上面那段话描述的情形：类的文档注释写着
「**读取签名的 / 传输层安全的插件注册表**」——那句话描述的就是这个方法，
于是任何打开这个类的人都会以为编辑器在读一个注册表，**而它很久没有那么做了**。

删掉方法，并把类注释改成描述它实际做的事，同时把这段历史留在注释里
（下一个人不必重新考古「为什么这里曾经有个 registryUrl」）。

**涉及文件**

- `code/lib/services/plugin_catalog_service.dart`

---

## 无编号：README「大文件」那一行有三个数字，守卫只核对两个

`readme_counts_test` 是「对外宣称的清单 vs 实现的清单」这条视角用在最外层的一次，
覆盖得很全：测试总数、功能表行数、图表类型数、主题数、界面语言数、主题截图、
图表名，以及成本预算的两个数字。

它读的正是 README 的「Large files」那一行，并核对其中的 **4 倍**与 **8 倍**
（那条注释还记着教训：「英文那行原本写着六倍，而测试的上限是八倍——限制被提高过，
而读者据以判断这个项目的那句话留在原地」）。

**同一行还有第三个数字，它读了过去**：

> Highlighting … **stops above 128 KB** … and **a test holds that limit where it is**.

一条测试确实守着那个阈值（`highlight_threshold_test`），**而没有任何东西把那句话
和那条测试绑在一起**。README 承诺「有测试守着」这件事本身，恰恰没有被守。

**修复方案**：在同一条用例里加上第三个比较，数字取自
`IncrementalMarkdownHighlighter.maxHighlightedLength`。

**验证**（双向变异）：把 README 改成 512 KB → 报「高亮的上限是 128 KB，
README 说的是别的」；把代码常量改成 512 KB → 报「高亮的上限是 512 KB，
README 说的是别的」。

**涉及文件**

- `code/test/services/readme_counts_test.dart`

---

## 无编号：发布说明的两半区，中文段落落到了英文半区

**现象**

`docs/v1.6.3/release-notes.md` 分「English」「中文」两半。给它补三条改动时，
中文段落被插在了 `## 中文` 这一行**之前**——于是它们排在英文半区的末尾，
而中文半区一条都没拿到。

**没有任何东西发现它**：文件存在、长度够、两种语言都在文件里的某处。
`version_docs_test` 当时只问「release-notes.md 在不在、够不够长」。

**修复方案**

先把内容改对（两半区各 6 节、顺序一致），再加一条守卫：

- 英文半区的 `###` 标题里**不许出现中日韩文字**。只看标题——中文段落里出现英文
  标识符是完全正常的，反过来查会满篇误报；而英文半区里一个中文标题是没有歧义的。
- 两半区的小节数必须相等。少一节意味着**有一半读者少看到一条**。

**验证**（两个变异，都被抓住）：

| 变异 | 报出 |
|------|------|
| 把一节中文挪回英文半区（复现我犯的错） | 「这些中文小节落在了英文半区——多半是插到了「## 中文」上面」 |
| 中文半区删掉一节 | 「两半区的小节数对不上（英文 6，中文 5）——有一半读者会少看到一条」 |

**涉及文件**

- `docs/v1.6.3/release-notes.md`（内容重排，并补上 BUG-424、BUG-425、FEAT-151）
- `code/test/services/version_docs_test.dart`（守卫）

---

## BUG-437：给粗体加斜体会把粗体删掉（三处同一个根因）

**现象**（都是「选中文字、按一下格式键」这一个动作）：

| 文档 | 选中 | 按下 | 得到 | 应得 |
|------|------|------|------|------|
| `**bold**` | `bold` | 斜体 | `*bold*`（**粗体没了**） | `***bold***` |
| `~~struck~~` | `struck` | 下标 | `~struck~`（删除线没了） | 下标，删除线本来就写不出来 |
| `***both***` | 整段 | 斜体 | `****both****` | `**both**` |
| `**一段**`＋`**另一段**` | 两段一起 | 斜体 | 两段的粗体**一起**没了 | 两段都变成粗+斜 |

**根因**：「这些标记是不是我这次要取消的那一个」这个判断有**三份**实现，各自的
成熟度不同：

| 在哪 | 守卫 | 后果 |
|------|------|------|
| 标记在选区**里面** | `selected.startsWith(before + before)` | `***both***` 被读成「两个」，又加一倍 |
| 标记在选区**外面** | **没有** | 看见 `bold` 两侧各一个 `*` 就拿走，粗体消失 |
| 多块选区 `_wrapEach` | **连那份糙的都没有** | 两段的粗体一起消失 |

第二份是用户最常撞上的那条路径——**选词而不是选语法**，这是大多数人加粗的方式。
代码里那句注释本来就把正确行为写明了（"applying italic to bold text should nest,
giving `***bold***`"），只是它挂在第一份上。这是记忆里「改一个分支就读完它的兄弟」
的第五例。

**修复中途发现自己的修法是错的**。第一版把规则写成「同一个字符在 `wrapMarkers`
里出现两种长度，就按运行长度判断」，于是下标作用于删除线得到 `~~~struck~~~`。
拿解析器一验：

```
~~~struck~~~      =>  <pre><code class="hljs language-struck~~~"></code></pre>
~~~struck~~~ x    =>  （后面的 x 也进了代码块）
```

**行首三个波浪号是代码围栏**，它会把这一段连同后文一起吞掉——比原缺陷严重得多。
`*` 的运行会叠（`***bold***` 确实是粗里套斜，解析器读回 `<em><strong>`），
`~` 的不会。所以正确的区分不是「同字符两种长度」，而是**这个字符的运行会不会叠**。

**修复方案**：三份合成一份，规则表述成「按下之后这个运行应该有多长」：

```dart
static int _pressedRun(String marker, int run, {required bool composes}) {
  if (run == 0) return marker.length;
  if (composes) {
    return _runCarries(marker, run)
        ? run - marker.length
        : run + marker.length;
  }
  return run == marker.length ? 0 : marker.length;
}
```

- 会叠的（只有 `*`）：运行长度决定语法在不在——单个 `*` 是强调当运行为**奇数**
  （两个是加粗，三个是加粗套强调），`**` 只要运行到二就是加粗。于是斜体作用于
  `**bold**` 加一步、作用于 `***both***` 减一步。
- 不会叠的（`~`、`` ` ``、`$`、`=`、`+`、`^`）：长度正好等于自己就是第二次按下，
  归零；长度不等就是另一种语法，**取而代之**，绝不加长。

**写成「长度」而不是「去掉几个／加上几个」是关键**。测试里那条直接验证产出物的守卫
逮到了中间版本的一个漏洞：选区边界**骑在**标记运行中间时（文档 `~~struck~~`、
选中 `~struck~`），「去掉选区内那一半再补上」会让总运行变长，正好又是 `~~~`。
改成读**整个**运行（无论它怎样跨越选区边界）、直接算出应有长度，这类情况自然消失。

**涉及文件**：

- `code/lib/ui/editor/source_editor.dart`（`toggleWrap`、`_wrapEach` 统一到
  `_pressedRun`／`_runCarries`／`_runFrom`／`_composingRuns`）
- `code/test/ui/editor/nesting_emphasis_keeps_the_outer_one_test.dart`（新增 24 条）

**验证**（三次变异，都被抓住，失败形状与预测一致）：

| 变异 | 红了几条 | 形状 |
|------|---------|------|
| 把 `~` 也算作会叠 | 5 | 围栏那几条，含「产出物不得开代码块」 |
| 不向选区外扩展运行 | 13 | 「选词不选语法」整组 + 往返 |
| 奇偶改成「只要有就算有」 | 3 | 三处嵌套全部退化成删掉外层 |

**两条断言曾经太宽，收紧过**：

- 最初验「围栏没吞掉后文」写的是 `contains('after')`——`after` 落进围栏**里面**
  也 contains，照样绿。改成 `isNot(contains('<pre><code'))`。
- 那个「哪些字符需要判断」的族判断一开始没有任何断言盖住（去掉它两条测试仍绿），
  补了 `` ``code`` `` 与 `$$x$$` 两条能区分的用例，并加一条**对账**测试：
  `wrapMarkers` 里出现两种长度的字符集合必须正好是 `{*, ~}`，将来有人加 `^^`
  就会红在「先决定它是哪一类」。

---

## 无编号：`version_docs_test` 把「表格空了」和「这一版还没有功能」当成了一件事

改这条守卫不是因为它错报，是因为它**没有能力说出真话**。

它对总览表格的要求是 `expect(tabled, isNotEmpty)`，失败理由写着「取法要跟着改」
——也就是说，它把空表一律当成「解析坏了」。但空表有两种：

| 空的原因 | 该不该红 |
|---------|---------|
| 正则不再匹配表格，这条测试已经瞎了 | 该红 |
| 这一版到现在只修了缺陷，确实一个 FEAT 都没有 | 不该红 |

第二种是合法状态——纯修缺陷的版本、以及任何版本的第一天，都是它。守卫没法表达，
于是逼着人要么造一个假 FEAT，要么把守卫整条删掉。

**改法**：用一行显式声明区分两者。文档里写 `<!-- 本版暂无 FEAT -->` 才允许空表；
一个不再匹配的正则永远不会顺手带上这行。并且声明了「暂无」就不许正文里有 FEAT
小节，否则同样红。

**验证**（两次变异，都被抓住）：

- 删掉那行标记 → 「总览表格读不出条目。真的一条都没有，就写一行 …」
- 留着标记但正文加一节 `## FEAT-148` → 「说本版暂无 FEAT，正文里却写了：{FEAT-148}」

两条原有的对账断言（表格有正文没有／正文有表格没有）原样保留，没有放松。
