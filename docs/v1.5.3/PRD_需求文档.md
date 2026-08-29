# v1.5.3 功能需求文档

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-054 | 2026-08-30 | 拼写检查：结论为当前条件下无法实现 | P3 | — | 不实现 |

---

## FEAT-054：拼写检查

| 字段 | 内容 |
|------|------|
| 日期 | 2026-08-30 |
| 状态 | **不实现**，并附证据，避免每轮重新讨论 |
| 对标来源 | 上游 MarkText 的 `options/spellcheck.spec.ts` |

### 上游其实做了什么

只有两条断言：`spellcheckEnabled: true` 时编辑器根节点带 `spellcheck="true"`，
false 时带 `"false"`。实现也只有一行——`domNode.setAttribute('spellcheck', ...)`。

**上游自己既不带词典也不做任何检查**，完全委托给 Chromium 内置的拼写检查器。

### 为什么本项目做不了

逐条查证，不是印象：

1. **Flutter 桌面端没有平台拼写检查服务。**
   `DefaultSpellCheckService` 走 `SpellCheck.initiateSpellCheck` 这个 channel。
   在 Flutter 引擎源码里搜这个方法名，实现只存在于
   `shell/platform/darwin/ios/.../FlutterSpellCheckPlugin.mm` 与
   `shell/platform/android/.../SpellCheckPlugin.java` ——
   **Linux / Windows / macOS 桌面 embedder 都没有。**
   所以"打开平台检查器"这条路在桌面 Flutter 上不存在。

2. **没有可用的系统词典。**
   `/usr/share/hunspell/`、`/usr/share/myspell/dicts/`、`/usr/share/dict/`、
   `/usr/lib/aspell/` 全部为空或不存在。Windows 也不自带。

3. **自带词典拿不到。** 开发环境离线，无法下载任何词库。

### 结论

差的不是工作量，是**拿不到词典**、也**没有可委托的平台能力**。做一个只在
装了 hunspell 的部分 Linux 上生效、Windows 上完全无效的半成品，比不做更糟。

一旦具备条件（能打包一份 MIT/LGPL 词库，或 Flutter 桌面端补上该 channel），
再回来做。**这是对照上游功能清单里唯一仍然缺失的一项。**
