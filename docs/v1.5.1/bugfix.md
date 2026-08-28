# V1.5.1 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-106 | 2026-08-29 | 发布清单列了两个从没被产出的 macOS x64 文件，且通用二进制被命名为 arm64 | P2 | 已修复 |

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
