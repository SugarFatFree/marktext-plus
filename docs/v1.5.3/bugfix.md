# v1.5.3 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-144 | 2026-08-30 | 预览的块编辑器里所有格式命令都无效，且命令会滞留 | P1 | 已修复 |
| BUG-145 | 2026-08-30 | v1.5.2 发出去时关于页仍显示 1.5.1（守卫测试没跑在发布路径上） | P1 | 已修复 |
| BUG-146 | 2026-08-30 | 文件被外部修改后，自动保存会静默覆盖别人的改动 | P1 | 已修复 |

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
