# v1.6.3 Bug 修复记录

总览表里是这一版的缺陷，每一条在下面有一节同编号的记录。文件末尾还有**没有编号**的小节：
那不是缺陷，是改动守卫本身时留下的理由。

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-421 | 2026-09-11 | 发给 GitHub 的 user-agent 写死 1.6.0，守卫照着旧形状写所以看不见 | P2 | 已修复 |
| BUG-422 | 2026-09-11 | 「关于框」的那段教训挂在了撤销/重做上 | P3 | 已修复 |
| BUG-423 | 2026-09-11 | 「每个请求都要能结束」的守卫，看不见 package:http，也就看不见它自己引用的那个好例子 | P1 | 已修复 |
| BUG-424 | 2026-09-11 | 「每个图标按钮都要说出自己做什么」的守卫，认不得 Material 3 的三个命名构造 | P2 | 已修复 |

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
