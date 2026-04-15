# MarkText Plus v1.0.2 — Bug 修复记录

## 总览

| 编号 | 日期 | 标题 | 紧急程度 | 优先级 | 难易度 | 状态 |
|------|------|------|----------|--------|--------|------|
| BUG-010 | 2026-04-15 | StateProvider.overrideWithValue 方法不存在导致构建失败 | P0-致命 | 最高 | 简单 | 已修复 |

---

## 详细记录

### BUG-010 — StateProvider.overrideWithValue 方法不存在导致构建失败

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-15 |
| 修复日期 | 2026-04-15 |
| 紧急程度 | P0-致命 |
| 优先级 | 最高 |
| 难易度 | 简单 |
| 现象 | Linux ARM64 和 macOS 构建失败，报错 "The method 'overrideWithValue' isn't defined for the type 'StateProvider<List<String>>'" |
| 根因 | `StateProvider` 没有 `overrideWithValue` 方法，应使用 `overrideWith` 并直接传入值 |
| 修复方案 | 将 `startupFilesProvider.overrideWithValue(startupFiles)` 改为 `startupFilesProvider.overrideWith((ref) => startupFiles)` |
| 涉及文件 | `main.dart` |
