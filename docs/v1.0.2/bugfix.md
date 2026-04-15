# MarkText Plus v1.0.2 — Bug 修复记录

## 总览

| 编号 | 日期 | 标题 | 紧急程度 | 优先级 | 难易度 | 状态 |
|------|------|------|----------|--------|--------|------|
| BUG-009 | 2026-04-15 | Windows 右键打开方式无本应用 + 启动参数未处理 | P1-严重 | 高 | 中等 | 已修复 |
| BUG-010 | 2026-04-15 | StateProvider.overrideWithValue 方法不存在导致构建失败 | P0-致命 | 最高 | 简单 | 已修复 |

---

## 详细记录

### BUG-009 — Windows 右键打开方式无本应用 + 启动参数未处理

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-04-15 |
| 修复日期 | 2026-04-15 |
| 紧急程度 | P1-严重 |
| 优先级 | 高 |
| 难易度 | 中等 |
| 现象 | 1) Windows 右键 .md 文件的"打开方式"中无 MarkText Plus 选项；2) 手动选择本应用后启动显示空白，未打开所选文件 |
| 根因 | Inno Setup 脚本缺少 `[Registry]` 段，未注册 .md 文件关联；Dart 端 `main()` 忽略了 Windows runner 传递的命令行参数 |
| 修复方案 | 1) Inno Setup 添加 `ChangesAssociations=yes` 和 `[Registry]` 段注册 ProgID `MarkTextPlus.md`，关联 `.md/.markdown/.txt` 扩展名；2) `main.dart` 解析命令行参数筛选合法文件路径，通过 `startupFilesProvider` 传递；3) `home_screen.dart` 启动时读取文件内容并创建标签页 |
| 涉及文件 | `main.dart`, `providers/tab_provider.dart`, `ui/screens/home_screen.dart`, `.github/workflows/release.yml` |

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
