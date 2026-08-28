# V1.5.1 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-106 | 2026-08-29 | 发布清单列了两个从没被产出的 macOS x64 文件，且通用二进制被命名为 arm64 | P2 | 已修复 |
| BUG-107 | 2026-08-29 | 菜单里的"重命名"绕开了守卫，会静默覆盖同名文件 | P1 | 已修复 |

---

## BUG-106：发布清单列了两个从没被产出的 macOS x64 文件，且通用二进制被命名为 arm64

### 现象

v1.5.0 发行版页面上的 macOS 产物只有 `macos-arm64.zip` 和 `macos-arm64.dmg`。
一个用 Intel Mac 的读者看到这个页面，合理的结论是**这个项目没有给他的构建**。

而 `release.yml` 的发布步骤里**明明列着** `macos-x64.zip` 与 `macos-x64.dmg`
两行——它们从来没有被任何 job 产出过。

### 根因分析

两个独立的问题叠在一起：

1. **幻影清单**。`softprops/action-gh-release` 找不到某个文件时**跳过它并继续
   报成功**。所以这两行在构建期不花任何代价，代价全在下载期：发行版页面上根本
   没有这个资产，而工作流一路绿灯。这已经这样发了好几个版本。

2. **命名把通用二进制说成了单架构**。`macos/Runner.xcodeproj` 的 Release 配置
   **没有设 `ONLY_ACTIVE_ARCH`**（只有 Debug 设了 `YES`），所以 Xcode 产出的
   `.app` 同时含 x86_64 与 arm64。

   这不是推断——把 v1.5.0 已发布的那个 zip 下下来，读 `Contents/MacOS/` 里
   可执行文件的 Mach-O 头：`0xcafebabe` 开头的 fat 二进制，两个架构分别是
   `x86_64` 和 `arm64`。**Intel Mac 一直是被覆盖的，只是名字没这么说。**

### 修复方案

- 三处产物名 `macos-arm64` 改为 `macos-universal`（zip、dmg、artifact 名）；
- 删掉发布清单里的两行幻影 x64。

新增 `test/utils/release_assets_test.dart` 三条：

- **发布清单里的每个文件都必须有 job 真的产出它**。Linux 的产物名是用
  `${{ matrix.arch }}` 之类拼的，所以测试先把占位符归一化成 `<arch>`
  再按 matrix 声明的值展开——否则字面比较会把每一个 Linux 产物都误判成幻影。
- 三个平台都必须有产物；
- macOS 产物不得用单个架构名命名。

**反向验证过**：把 `macos-x64.zip` 那行注回去，这两条测试立刻变红。

### 涉及文件

- `.github/workflows/release.yml`
- `code/test/utils/release_assets_test.dart`（新增，3 条）


---

## BUG-107：菜单里的"重命名"绕开了守卫，会静默覆盖同名文件

### 现象

在**文件 → 重命名**里把当前文档改成一个已经存在的文件名，那个文件**被无声
销毁**——没有确认框、没有撤销、屏幕上没有任何提示。

同一个操作在**侧边栏右键重命名**里是安全的，会提示"文件名已被占用"。

### 根因分析

`FileService.renameFile` 早就长出了守卫，它自己的注释写得很清楚：

> `File.rename` replaces the destination without a word, so renaming a note to
> a name already in use destroyed the note that had it — no prompt, no undo,
> nothing on screen to say it had happened.

侧边栏走 `fileProvider.renameNode` → `FileService.renameFile`，拿到了守卫，
并且在 `_runFileOp` 里接住 `PathExistsException` 弹提示。

**菜单没有走这条路**。`app_menu_bar.dart:247` 自己写了一行
`await File(oldPath).rename(newPath);`——同一个操作的第二份实现，守卫加上去的
时候这一份没跟上。全项目直接调 `.rename(` 的地方一共六处，其余五处都在
service 与 config 内部，只有这一处在 UI 层。

### 修复方案

菜单改走 `fileProvider.renameNode`，并接住 `PathExistsException` 与其他异常
分别提示（复用侧边栏已有的 `fileNameTaken` / `fileOperationFailed` 文案）。

新增 `test/services/menu_rename_guard_test.dart`，其中一条**直接在源码里检查
四个 UI 文件都不再出现 `File(...).rename(`**——要保证的是"只有一份实现"，
而不是"两份实现今天恰好一致"。

### 涉及文件

- `code/lib/ui/widgets/app_menu_bar.dart`
- `code/test/services/menu_rename_guard_test.dart`（新增，3 条）
