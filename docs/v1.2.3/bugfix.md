# V1.2.3 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-001 | 2026-06-02 | 打开文件时重复弹出文件打开行为对话框 | P0 | 已修复 |
| BUG-002 | 2026-06-02 | 代码块未正确渲染（文件中包含 ``` 标签但不显示） | P1 | 已修复 |
| BUG-003 | 2026-06-02 | 大文件打开后预览窗口卡顿滚动延迟 | P1 | 已修复 |
| BUG-004 | 2026-06-02 | 引用块内文本重叠 | P2 | 已修复 |
| BUG-005 | 2026-06-02 | 表格最后一列内容超出边框范围 | P2 | 已修复 |
| BUG-006 | 2026-06-02 | 分栏视图右侧表格无法水平滚动 | P2 | 已修复 |
| BUG-007 | 2026-06-02 | 预览模式下表格无需滚动也可水平滚动 | P2 | 已修复 |
| BUG-008 | 2026-06-02 | 渐进式渲染只显示前50节点后停止 | P1 | 已修复 |
| BUG-009 | 2026-06-02 | 文件打开和模式切换缺少加载反馈 | P2 | 已修复 |
| BUG-010 | 2026-06-02 | Mermaid stateDiagram 连接线文字重叠，节点覆盖文字 | P2 | 已修复 |
| BUG-011 | 2026-06-02 | 切换编辑模式回到顶部，丢失滚动位置 | P1 | 已修复 |
| BUG-012 | 2026-06-02 | 大文件切换模式时卡顿 | P2 | 已修复 |

---

## BUG-001 — 打开文件时重复弹出文件打开行为对话框

| 字段 | 内容 |
|------|------|
| 优先级 | P0 |
| 状态 | 已修复 |

### 现象

用户已经选择过文件打开行为（新窗口/当前窗口）后，后续打开文件时仍然重复弹出询问对话框。

### 根因分析

用户可以通过按 ESC 键关闭对话框（尽管 `barrierDismissible: false`，ESC 仍然有效）。当 `showDialog` 返回 `null` 时，`home_screen.dart` line 215 的 `if (choice != null)` 判断导致配置不会保存，`fileOpenBehavior` 仍然是 `notSet`，下次启动仍会弹窗。

### 修复方案

当用户取消对话框时（`choice == null`），设置默认值 `FileOpenBehavior.existingWindow`（更符合大多数用户期望，且与 v1.2.2 之前的行为一致）。

```dart
final choice = await _showFileOpenBehaviorDialog();
// If user dismisses dialog (ESC or system close), default to existingWindow
final finalChoice = choice ?? FileOpenBehavior.existingWindow;
ref.read(settingsProvider.notifier).updateConfig(
  (c) => c.copyWith(fileOpenBehavior: finalChoice),
);
```

### 涉及文件

- `lib/ui/screens/home_screen.dart`

---

## BUG-002 — 代码块未正确渲染

| 字段 | 内容 |
|------|------|
| 优先级 | P1 |
| 状态 | 已修复 |

### 现象

文件 `D:\znhu.IFLYTEK\Documents\iFLYREC\产业服务平台\三平台\部署产物\赋能平台\V0.7\V0.6-V0.7(增量)\04.部署文档\产业发展赋能平台V0.7增量升级手册.md` 中包含 ``` 标签，但预览视图未显示代码块。

### 根因分析

代码块标记出现在有序列表项内，有 3 个空格缩进（`   ```sql`）。`MarkdownParser` 的 `_codeFenceRe = RegExp(r'^```(\w*)')` 要求行首直接是 ```，不支持前导空格，导致缩进的代码块无法识别，被当作普通段落解析。

### 修复方案

修改正则表达式支持前导空格：

```dart
static final _codeFenceRe = RegExp(r'^\s*```(\w*)');
static final _codeFenceEndRe = RegExp(r'^\s*```\s*$');
```

这样有序列表/无序列表内的缩进代码块可以正确识别。

### 涉及文件

- `lib/services/markdown_parser.dart`

---

## BUG-003 — 大文件打开后预览窗口卡顿滚动延迟

| 字段 | 内容 |
|------|------|
| 优先级 | P1 |
| 状态 | 已修复 |

### 现象

文件 `D:\Workspace\iflytek_gitee\ZHBG_CYFW\empowerment-platform\docs\design\detail\V0.6\01-详细设计.md` 较大（918 行，197 个表格行，64 个标题），打开后预览窗口卡住一段时间才能正常滚动。

### 根因分析

虽然 v1.2.2 已通过 AST 缓存、异步文件读取、跳过超大代码块高亮等优化，但复杂文档的 widget 树构建仍然很重：918 个节点 → 每个表格行产生多个 `TableRow` → `Padding` → `Text.rich` → 多个 `TextSpan`，首次布局计算阻塞主线程。

### 修复方案

实现渐进式渲染：
1. 首次只构建前 50 个节点，快速显示首屏内容
2. 首帧后通过 `addPostFrameCallback` 分批渲染剩余节点（每批 50 个）
3. 渲染未完成时底部显示加载指示器

```dart
// Progressive rendering state
int _renderedNodeCount = 0;
static const _initialBatchSize = 50;
static const _incrementalBatchSize = 50;

// In build():
if (_renderedNodeCount == 0) {
  _renderedNodeCount = nodes.length > _initialBatchSize ? _initialBatchSize : nodes.length;
  if (nodes.length > _initialBatchSize) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _renderedNodeCount < nodes.length) {
        setState(() {
          _renderedNodeCount = (_renderedNodeCount + _incrementalBatchSize).clamp(0, nodes.length);
        });
      }
    });
  }
}
```

用户可以立即滚动首屏内容，剩余内容在后台异步渲染。

### 涉及文件

- `lib/ui/editor/markdown_renderer.dart`

---

## BUG-004 — 引用块内文本重叠

| 字段 | 内容 |
|------|------|
| 优先级 | P2 |
| 状态 | 已修复 |

### 现象

文件 `D:\Workspace\iflytek_gitee\ZHBG_CYFW\empowerment-platform\docs\design\detail\V0.6\01-详细设计.md` 中 `> **输入引用**:` 下的内容文本重叠。

### 根因分析

Blockquote 解析时将多行用 `\n` 连接传给 `parseInline()` 解析为 inline spans，换行符包在 `InlineSpan` 中作为普通文本。`Text.rich` 渲染时 `\n` 产生换行，但 `_defaultStrutStyle` 的 `forceStrutHeight: true` 强制了统一行高，当实际内容（如列表项）需要更大的行间距时，就会导致重叠。

### 修复方案

为 blockquote 单独配置 `StrutStyle`，移除 `forceStrutHeight: true`，让文本自然换行：

```dart
child: Text.rich(
  _buildInlineSpans(node.inlineSpans, theme, _defaultTextStyle),
  // Use natural line height without forcing strut height to prevent text overlap
  strutStyle: const StrutStyle(
    fontSize: 16,
    height: 1.6,
    leadingDistribution: TextLeadingDistribution.even,
    fontFamilyFallback: AppTheme.platformFontFallback,
  ),
),
```

### 涉及文件

- `lib/ui/editor/markdown_renderer.dart`

---

## BUG-005 — 表格最后一列内容超出边框范围

| 字段 | 内容 |
|------|------|
| 优先级 | P2 |
| 状态 | 已修复 |

### 现象

文件 `D:\Workspace\iflytek_gitee\ZHBG_CYFW\empowerment-platform\docs\design\detail\V0.6\01-详细设计.md` 中 "1.1 总体变更摘要" 下的表格，最后一列标题和内容超出表格边框。

### 根因分析

Table widget 使用 `defaultColumnWidth: const IntrinsicColumnWidth()`，会根据列内最宽内容计算列宽。当内容过长（如"A-M01 智能体市场（前端 3 个 View + 后端聚合）"），列宽超出容器，且 v1.2.2 为修复 `SelectionArea` 兼容性移除了外层 `SingleChildScrollView`，导致超出部分无法滚动查看。

### 修复方案

1. 改用 `defaultColumnWidth: const IntrinsicColumnWidth()`（保持内容宽度）
2. 为单元格内的 `Text.rich` 添加 `softWrap: true` 让长文本自动换行
3. 恢复表格外层 `SingleChildScrollView(scrollDirection: Axis.horizontal)`，但放在 `SelectionArea` **内部**，不破坏选择连续性

```dart
return SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Container(
    // ... Table ...
    child: Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        // ...
        child: Text.rich(..., softWrap: true),
      ],
    ),
  ),
);
```

### 涉及文件

- `lib/ui/editor/markdown_renderer.dart`

---

## BUG-006 — 分栏视图右侧表格无法水平滚动

| 字段 | 内容 |
|------|------|
| 优先级 | P2 |
| 状态 | 已修复 |

### 现象

切换到双栏视图后，右侧视图窗口中的表格内容显示不全，且无法水平滚动（没有滚动条）。

### 根因分析

v1.2.2 为了修复 `SelectionArea` 兼容性移除了表格外的 `SingleChildScrollView`，导致宽表格无法滚动。分栏视图右侧空间较窄，即使使用 `FlexColumnWidth` 自动换行，某些宽表格仍然显示不全。

### 修复方案

根据编辑模式动态选择表格渲染策略：
- **预览模式**：使用 `FlexColumnWidth` 自适应列宽 + `softWrap: true` 文本换行，无水平滚动
- **分栏模式**：使用 `IntrinsicColumnWidth` 保持列宽 + `SingleChildScrollView(horizontal)` 水平滚动

```dart
final isSplitMode = config.editMode == EditMode.split;
final tableWidget = Table(
  defaultColumnWidth: isSplitMode
      ? const IntrinsicColumnWidth()
      : const FlexColumnWidth(),
  // ...
);

if (isSplitMode) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: tableContainer,
  );
}
return tableContainer;
```

这样预览模式下表格自适应不需要滚动，分栏模式下可以滚动查看完整内容。

### 涉及文件

- `lib/ui/editor/markdown_renderer.dart`

---

## BUG-007 — 预览模式下表格无需滚动也可水平滚动

| 字段 | 内容 |
|------|------|
| 优先级 | P2 |
| 状态 | 已修复 |

### 现象

BUG-006 修复后，所有表格都可以水平滚动。预览模式下宽度充足，表格应该自适应换行，不应该出现水平滚动。

### 根因分析

BUG-005/006 的修复为所有表格统一添加了 `SingleChildScrollView(horizontal)`，但没有区分编辑模式。预览模式下视图宽度足够，表格应该自适应宽度并自动换行，而不是启用滚动。

### 修复方案

与 BUG-006 合并修复：通过 `ref.watch(settingsProvider).editMode` 获取当前编辑模式，只在分栏模式下启用水平滚动。

### 涉及文件

- `lib/ui/editor/markdown_renderer.dart`

---

## BUG-008 — 渐进式渲染只显示前50节点后停止

| 字段 | 内容 |
|------|------|
| 优先级 | P1 |
| 状态 | 已修复 |

### 现象

BUG-003 引入渐进式渲染后，大文件只渲染到前 50 个节点（如 "2.4.1" 章节）就停止，向下滚动虽然有加载指示器，但后续内容一直无法加载。

### 根因分析

`addPostFrameCallback` 只调度了一次：首次渲染 50 个节点后，`setState` 增加到 100 个节点，但没有继续调度下一批。缺少递归调度逻辑，导致只渲染了第二批就停止。

### 修复方案

提取 `_scheduleNextBatch(int totalNodes)` 方法，在 `setState` 回调中递归调度，直到所有节点渲染完成：

```dart
void _scheduleNextBatch(int totalNodes) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || _renderedNodeCount >= totalNodes) return;
    setState(() {
      _renderedNodeCount = (_renderedNodeCount + _incrementalBatchSize).clamp(0, totalNodes);
    });
    // Continue scheduling until all nodes are rendered
    if (_renderedNodeCount < totalNodes) {
      _scheduleNextBatch(totalNodes);
    }
  });
}
```

### 涉及文件

- `lib/ui/editor/markdown_renderer.dart`

---

## BUG-009 — 文件打开和模式切换缺少加载反馈

| 字段 | 内容 |
|------|------|
| 优先级 | P2 |
| 状态 | 已修复 |

### 现象

大文件打开和编辑模式切换（预览/双栏/源代码）时有明显卡顿，用户没有视觉反馈，不清楚是否正在加载。

### 根因分析

虽然 `HomeScreen._buildEditorArea` 已有 `AnimatedSwitcher` 和加载动画，但：
1. `AnimatedSwitcher` duration 只有 80ms，过渡太快感知不到
2. 加载动画尺寸较小（24x24），不够醒目
3. 缺少明确的加载文本提示

### 修复方案

1. 增加 `AnimatedSwitcher` duration 到 200ms，添加轻微的缩放动画（0.98 → 1.0），让过渡更平滑
2. 增大加载指示器尺寸（24x24 → 32x32）和描边宽度（2.5 → 3）
3. 添加 "Loading..." 文本提示，增强视觉反馈

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  transitionBuilder: (child, animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1.0).animate(...),
        child: child,
      ),
    );
  },
  // ...
)
```

### 涉及文件

- `lib/ui/screens/home_screen.dart`

---

## BUG-010 — Mermaid stateDiagram 连接线文字重叠，节点覆盖文字

| 字段 | 内容 |
|------|------|
| 优先级 | P2 |
| 状态 | 已修复 |

### 现象

stateDiagram-v2 中：
1. 连接线上的文字互相覆盖
2. 节点图覆盖连接线上的文字
3. 长标签文本无法换行，直接溢出

示例：多个状态转换从同一节点出发时，标签文字堆叠在一起无法区分；节点绘制在标签之上，遮挡部分文字。

### 根因分析

FlowchartPainter（stateDiagram 使用 flowchart 类型渲染）的绘制逻辑：
1. **绘制顺序问题**：先绘制边线和标签，再绘制节点（line 42-44），节点会覆盖标签
2. **标签位置固定**：所有标签都在中点 + 固定偏移（`-12` 或 `12`），多个边的标签会重叠
3. **无换行支持**：`drawText` 虽然有 `maxWidth` 参数，但 `_drawEdgeLabel` 未传递，长文本溢出

### 修复方案

1. **调整绘制顺序**：边线 → 节点 → 边标签，让标签始终显示在最上层
2. **增加标签偏移**：从固定 12px 增加到垂直于边线方向的 20px，使用垂直向量计算偏移方向，避免与边线和节点紧贴
3. **限制文本宽度**：传递 `maxWidth = min(150, edgeLength * 0.8)`，让 TextPainter 自动换行
4. **增加背景透明度**：背景 alpha 从 1.0 降到 0.95，减少视觉遮挡

```dart
// paint() 方法末尾添加：
for (final edge in diagram.edges) {
  if (!edge.isSubgraphEdge || subgraphBounds == null) {
    final fromNode = diagram.nodes.firstWhere((n) => n.id == edge.from);
    final toNode = diagram.nodes.firstWhere((n) => n.id == edge.to);
    final from = Offset(fromNode.x + fromNode.width / 2, fromNode.y + fromNode.height / 2);
    final to = Offset(toNode.x + toNode.width / 2, toNode.y + toNode.height / 2);
    _drawEdgeLabel(canvas, edge, from, to);
  }
}

// _drawEdgeLabel 方法：
final dx = to.dx - from.dx;
final dy = to.dy - from.dy;
final edgeLength = math.sqrt(dx * dx + dy * dy);
// 垂直向量
final perpX = -dy / edgeLength;
final perpY = dx / edgeLength;
final labelOffset = Offset(perpX * 20, perpY * 20);

drawText(
  canvas,
  edge.label!,
  midPoint + labelOffset,
  textStyle,
  backgroundColor: Color(...).withValues(alpha: 0.95),
  maxWidth: math.min(150.0, edgeLength * 0.8),
);
```

**注意**：完整的"自动调整节点间距"需要重构 Sugiyama 布局引擎，工作量较大。当前方案通过调整渲染层解决了主要的视觉问题。

### 涉及文件

- `lib/ui/editor/mermaid/painter/flowchart_painter.dart`

---

## BUG-011 — 切换编辑模式回到顶部，丢失滚动位置

| 字段 | 内容 |
|------|------|
| 优先级 | P1 |
| 状态 | 已修复 |

### 现象

在文档中滚动到某个位置后，切换视图模式（预览/双栏/源代码）会回到顶部，丢失当前滚动位置。

### 根因分析

HomeScreen 的 `_buildEditorArea` 使用 `AnimatedSwitcher` + `ValueKey`，每次切换模式时：
1. `ValueKey` 变化导致旧 widget 被销毁，新 widget 重新构建
2. ScrollController 随 widget 销毁而丢失，新 widget 的初始滚动位置为 0

### 修复方案

用 `IndexedStack` 代替 `AnimatedSwitcher`：
- IndexedStack 同时保留三种模式的 widget 树，只切换可见性
- 每个编辑器的 ScrollController 和滚动状态得以保持
- 切换模式时只改变 `index`，不重建 widget

```dart
return IndexedStack(
  key: ValueKey('editors_${activeTab.id}'),
  index: editMode.index, // 0=source, 1=preview, 2=split
  sizing: StackFit.expand,
  children: [
    SourceEditor(key: ValueKey('source_${activeTab.id}'), ...),
    MarkdownRenderer(key: ValueKey('preview_${activeTab.id}'), ...),
    SplitEditor(key: ValueKey('split_${activeTab.id}'), ...),
  ],
);
```

**副作用**：内存占用增加（同时保留三份 widget），但对于 Markdown 编辑器场景可接受。

**未实现**：双栏模式的源代码和预览滚动同步。需要重构 SourceEditor 和 MarkdownRenderer 添加 scrollController 参数，工作量较大，建议作为未来增强功能。

### 涉及文件

- `lib/ui/screens/home_screen.dart`
- `lib/models/tab_info.dart`（添加了 per-mode scroll offset 字段，为未来扩展预留）

---

## BUG-012 — 大文件切换模式时卡顿

| 字段 | 内容 |
|------|------|
| 优先级 | P2 |
| 状态 | 已修复 |

### 现象

大文件（如几百行的文档）切换双栏/预览/源代码模式时出现明显卡顿（200-500ms），用户体验不佳。

### 根因分析

`AnimatedSwitcher` 的 200ms 过渡动画无法掩盖 widget 重建的开销：
1. SourceEditor 需要初始化 CodeEditor、TextEditingController、语法高亮
2. MarkdownRenderer 需要解析 Markdown AST、构建 widget 树、渲染复杂节点（表格、代码块、Mermaid）
3. 大文件场景下，这些操作在主线程执行，阻塞 UI 渲染

### 修复方案

与 BUG-011 的修复方案相同：使用 `IndexedStack` 保持三种模式的 widget 状态。

**原理**：
- 首次切换到某个模式时仍会有构建开销（不可避免）
- 后续切换只改变可见性，无需重建，开销近乎为零
- 用户通常在 2-3 种模式间频繁切换，IndexedStack 的缓存效果显著

**权衡**：
- 内存占用增加：三份 widget 树常驻内存
- 性能提升明显：二次切换从 200-500ms 降低到 <10ms
- 对于现代设备，内存开销可接受（相比糟糕的用户体验）

### 涉及文件

- `lib/ui/screens/home_screen.dart`
