# V1.4.0 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-001 | 2026-08-28 | 时序图的 `box` 分组与 `autonumber` 被丢弃，且 `box` 的 `end` 会错关控制框 | P1 | 已修复 |

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
