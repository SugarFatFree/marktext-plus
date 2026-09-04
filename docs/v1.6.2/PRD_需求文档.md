# v1.6.2 功能需求文档

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-125 | 2026-09-05 | 插件详情页说明它被允许做什么 | P1 | 低 | 已完成 |

---

## FEAT-125：插件详情页说明它被允许做什么

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-05 |
| 需求描述 | 权限从 v1.6.2 起真的会拦人（BUG-262），读者需要一个地方看到被拦的依据是什么 |
| 用户场景 | 装了一个插件，某个功能点了没反应；或者装之前想知道这个「Community / Unverified」的东西要碰什么 |
| 实现方案 | `PluginCatalogEntry` 带上 `permissions`，`installed` 工厂从本地 manifest 填。详情页头部之下一段 Permissions，每条一行，用 `PluginPermission.describe()` 的人话而非标识符。拒绝通知同样两样都给：句子给读者，标识符给写 manifest 的人 |
| 验收标准 | 已安装插件的详情页列出它声明的每一项，说的是「Read the open document and your selection」而不是「document.read」；声明为空时明说「asks for nothing」；不认识的权限照样占一行并说明本版本不为它授予任何东西；**搜索结果不显示这一段**——包还没下载，编辑器没见过 manifest，说不出它要什么，空着比猜错好 |
| 涉及文件 | `lib/models/plugin_catalog_entry.dart`、`lib/ui/screens/plugin_detail_view.dart`、`lib/services/plugin_command_service.dart` |

### 一个没有做的决定

装之前展示权限，需要在下载并校验 ZIP 之后、启用之前插一个确认步骤——浏览器扩展就是这么做的，那才是真正的事前披露。

这一版没有做，因为它是产品决策而不是缺陷修复：它给安装流程加了一道门。展示是纯增益，加门不是。留给用户定夺。
