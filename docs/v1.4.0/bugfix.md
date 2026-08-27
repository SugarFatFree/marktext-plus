# V1.4.0 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-001 | 2026-08-28 | 时序图的 `box` 分组与 `autonumber` 被丢弃，且 `box` 的 `end` 会错关控制框 | P1 | 已修复 |
| BUG-002 | 2026-08-28 | 点击文件夹搜索结果只打开文件，不跳到命中行 | P1 | 已修复 |
| BUG-003 | 2026-08-28 | 源码编辑器销毁时抛异常，清理逻辑其实从未执行 | **P0** | 已修复 |

## 详细记录

### BUG-001 时序图的 box 分组与 autonumber 被丢弃

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-28 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | `box Purple 前端团队 … end` 在源项目里把括起来的参与者画进一个带色方框，本项目里整段被忽略；`autonumber` 自动编号同样没有效果 |
| 为何是 P1 而不是「小功能缺失」 | v1.3.0 的 BUG-086 刚让 `end` 变得有意义（收控制框）。`box` 也用 `end` 收尾，**不认识 box 就会让它的 `end` 去关掉别的框**——原本只是「少画一个盒子」，现在会变成「loop 框范围错乱」。这是上一处修复顺带引入的风险，必须一并补上 |
| 修复方案 | `box` 作为开启关键字纳入同一套栈；`end` 的规则是「有控制框先关控制框，否则关盒子」—— 盒子只可能出现在参与者声明阶段、任何框之前，两种顺序下这条规则都对。盒里声明的参与者按序记入该盒 |
| 颜色解析 | `box <颜色> <名字>` 两部分都可省略，唯一的区分办法就是**拿第一个词去试颜色**（mermaid 自己也是这么做的）。支持 `rgb()` / `rgba()` / `#hex` 与 24 个常用 CSS 颜色名；试不出来就整串当名字 |
| autonumber | 支持 `autonumber`、`autonumber <起点> <步长>`、`autonumber off`；编号写在消息文本前面，与 mermaid 的画法一致 |
| 关键字边界 | 与 BUG-086 同一条规矩：关键字后面必须是空白或行尾，所以 `boxes->>B` 和 `autonumbers->>B` 仍是普通消息 |
| 涉及文件 | `lib/ui/editor/mermaid/models/sequence.dart`、`parser/sequence_parser.dart`、`painter/sequence_painter.dart`、`test/ui/editor/mermaid/mermaid_parser_test.dart` |
| 验证方式 | 命名颜色 / rgb / 无颜色 / 无标签 / 盒与框共用 end / 盒缺 end / `boxes` 前缀 七种情况本地跑通；autonumber 六种情况跑通；画布用桩类型完整编译并跑通含分组（含成员缺席的分组）的绘制 |

---

### BUG-002 点击文件夹搜索结果只打开文件，不跳到命中行

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-28 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 侧边栏搜索出一堆结果，点进去只是把文件打开在**第一行**。文件几百行时，等于让用户自己再找一遍 |
| 根因分析 | 两半都已经有了，中间断了一节：`_SearchResult` 记着 `lineNumber`，编辑器也早有 `scrollToLine`（目录面板就在用），可是 `onTap` 调的是 `_openFileInTab(result.filePath)` —— 行号在这一步被丢掉 |
| 隐藏的第二个问题 | 光把行号传下去还不够。新开标签页时，`scrollToLine` 发生在**这个文件的编辑器还没建出来**之前，而编辑器用的是 `listenManual`，只在值**变化**时触发 —— 它错过了这次请求，滚动依然不会发生 |
| 修复方案 | 编辑器初始化（post-frame）注册监听之后，**再主动读一次当前挂起的目标**并认领。滚动逻辑抽成 `_scrollToTargetLine`，监听回调和初始认领共用一份 |
| 已开标签页的情况 | 走 `setActiveTab` 后直接 `scrollToLine`，编辑器已存在，监听正常触发 |
| 预览模式 | 预览同样有「监听注册得太晚」的问题，一并按同样办法认领挂起目标。另外预览只对**标题行**建了 key，命中普通正文行时原本什么都不做 —— 改成回落到**该行上方最近的标题**。没有给每个块都建 key：那等于每个节点一个 GlobalKey，正是渐进渲染要避免的逐节点开销，而「滚到上一个标题」已经足够读者接上下文，且不花一分钱 |
| 涉及文件 | `lib/ui/widgets/side_bar.dart`、`lib/ui/editor/source_editor.dart`、`lib/ui/editor/markdown_renderer.dart`、`test/ui/editor/source_editor_scroll_test.dart`（新增）、`test/ui/editor/markdown_renderer_scroll_test.dart`（新增） |
| 验证方式 | 源码编辑器三个 widget 测试：目标在编辑器建出来之前就挂起、目标在之后才发出、完全没有目标；预览三个：提前挂起、普通正文行回落、比所有标题都靠前的行。判据都是「目标被清空」—— 清空只在处理函数内部发生，所以它就是「确实执行了滚动」的证据 |

---

### BUG-003 源码编辑器销毁时抛异常，清理逻辑其实从未执行

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-28 |
| 优先级 | **P0** |
| 状态 | 已修复 |
| 现象 | 每次销毁一个 `SourceEditor`（关标签页、切编辑模式、关窗口）都会抛 `Bad state: Cannot use "ref" after the widget was disposed`。异常被 Flutter 框架接住，界面不崩，所以**一直没人发现** |
| 后果 | `dispose()` 里那段「把 controller 的注册交还给 provider」在抛异常的那一行就中断了 —— 也就是说这段清理**一次都没跑成功过**。provider 里一直留着已销毁的 controller，而查找栏正是靠它判断「当前有没有源码编辑器」 |
| 根因分析 | `dispose()` 里写了 `ref.read(editorProvider.notifier)`。riverpod 的 `ConsumerStatefulElement.unmount` 会**先**把元素标记为已释放，**再**调用 `State.dispose()`，所以到 dispose 时 `ref` 已经不能用了 |
| 修复方案 | 在 `initState` 里就把 notifier 取出来存成字段，`dispose` 用字段而不碰 `ref` |
| 怎么发现的 | 为 BUG-002 写的 widget 测试在拆树时把它暴露了出来 —— 真实运行中异常被框架吞掉，只有测试会把「finalizing the widget tree 时抛异常」判为失败。全仓扫了一遍 `dispose()` 里用 `ref` 的地方，只有这一处 |
| 涉及文件 | `lib/ui/editor/source_editor.dart` |
| 验证方式 | 三个源码编辑器滚动 widget 测试从「拆树抛异常」变为通过 |

---
