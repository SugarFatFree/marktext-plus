# MarkText Plus v1.1.2 — Bug 修复记录

## 总览

| 编号 | 日期 | 标题 | 紧急程度 | 优先级 | 难易度 | 状态 |
|------|------|------|----------|--------|--------|------|
| BUG-001 | 2026-04-17 | 预览视图混合文本选中高亮异常 | P2-一般 | 高 | 困难 | 已修复 |
| BUG-002 | 2026-04-17 | 标签页标题字体粗细不一致 | P3-轻微 | 低 | 简单 | 已修复 |

## 详细记录

### BUG-001 — 预览视图混合文本选中高亮异常

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-17 |
| 修复日期 | 2026-04-17 |
| 紧急程度 | P2-一般 |
| 优先级 | 高 |
| 难易度 | 困难 |
| 现象 | 预览视图中，括号内的英文路径/链接（如 `console/billing/index.vue`）鼠标选中时背景不高亮，或仅高亮链接下划线部分；inline code 等自带背景色的文本选中时只显示原背景色，看不到选区高亮；跨内容块拖选经过表格时会漏掉一行；按住 Ctrl 键时选区闪烁或消失；列表项选择时内容丢失且按 Ctrl 后选区取消 |
| 根因 | 五个独立问题叠加：1) 链接文本始终带 `TextDecoration.underline`，选区高亮被下划线遮挡；2) inline code 的 `TextSpan.backgroundColor` 绘制在选区高亮之上（Flutter 已知 bug [#79168](https://github.com/flutter/flutter/issues/79168)），完全覆盖选区颜色；3) 表格外层的横向 `SingleChildScrollView` 打断 `SelectionArea` 的选区连续性（Flutter 已知 bug [#111497](https://github.com/flutter/flutter/issues/111497)），导致表格下方内容选区丢失；4) `_handleKeyEvent` 中调用 `setState` 更新 `_isModifierPressed` 触发 widget 重建，销毁 `SelectionArea` 内部选区状态；5) 列表项使用 `TextSpan.backgroundColor` 和嵌套 `SelectableText.rich`，导致选区高亮被覆盖且无法跨列表项选择 |
| 修复方案 | 1) 恢复外层 `SelectionArea` + 内层 `Text.rich` 架构，实现跨内容块统一选区管理；2) 链接移除条件下划线，改为在点击时检查 `HardwareKeyboard.instance.isControlPressed`，避免 `setState` 触发重建；3) inline code 改用 `WidgetSpan` + `Container` 渲染背景色，不再使用 `TextSpan.backgroundColor`，避免覆盖选区高亮；4) 移除表格的横向 `SingleChildScrollView`，改用 `IntrinsicColumnWidth` 自适应列宽，避免打断选区连续性；5) 移除 `_isModifierPressed` 字段和 `_handleKeyEvent` 方法，清理键盘事件监听器注册代码 |
| 涉及文件 | `ui/editor/markdown_renderer.dart` |

### BUG-002 — 标签页标题字体粗细不一致

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-17 |
| 修复日期 | 2026-04-17 |
| 紧急程度 | P3-轻微 |
| 优先级 | 低 |
| 难易度 | 简单 |
| 现象 | 标签页标题字体不统一，活动标签页字体较粗，非活动标签页字体较细 |
| 根因 | `editor_tab_bar.dart` 中活动标签页使用 `FontWeight.w500`，非活动标签页使用 `FontWeight.normal`（w400） |
| 修复方案 | 统一所有标签页标题为 `FontWeight.normal` |
| 涉及文件 | `ui/widgets/editor_tab_bar.dart` |
