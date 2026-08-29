# v1.5.3 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-144 | 2026-08-30 | 预览的块编辑器里所有格式命令都无效，且命令会滞留 | P1 | 已修复 |
| BUG-145 | 2026-08-30 | v1.5.2 发出去时关于页仍显示 1.5.1（守卫测试没跑在发布路径上） | P1 | 已修复 |

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
