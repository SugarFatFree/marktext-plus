# v1.6.2 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-262 | 2026-09-05 | 17 项权限只强制了 4 项，`document.read` 形同虚设 | P0 | 已修复 |
| BUG-263 | 2026-09-05 | SDK 三个示例返回 `panel` 却不声明 `ui.sidebar` | P1 | 已修复 |
| BUG-264 | 2026-09-05 | 打包测试写死插件版本号，每次发版要手改一遍 | P2 | 已修复 |
| BUG-265 | 2026-09-05 | 权限被强制执行，读者却没有任何地方能看到它是什么 | P1 | 已修复 |

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
