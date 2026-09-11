# v1.6.3 功能需求文档

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-148 | 2026-09-11 | 通过 MCP 安装/更新插件，让「改完就能测」不必等人按按钮 | P1 | 中 | 已完成 |
| FEAT-149 | 2026-09-11 | 通过 MCP 更新应用本体：CI 构建 → 校验 → 装上 → 自己回来 | P1 | 高 | 已完成 |
| FEAT-150 | 2026-09-11 | Windows 安装包改为按用户安装，更新不再需要点 UAC | P1 | 低 | 已完成 |

---

## FEAT-148：通过 MCP 安装/更新插件

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-11 |
| 需求描述 | `control` 新增动作 `install_plugin`：按插件名从插件市场装一个新插件，或把已装的更新到最新发布。 |
| 用户场景 | 插件改完、CI 出了新的 release 之后，要验证它，得有人打开插件面板、找到它、点安装、再回来跑命令。这一步没有任何判断，只是挡在自动验证前面的一个人手动作。有了这个动作，「装上 → `run_plugin_command` → 看结果」可以一口气走完。 |
| 实现方案 | 走的是**读者点「安装」那一条完全相同的路**：`PluginCatalogService.install` —— HTTPS、比对 release 自己的 SHA-256、解包时的大小上限与拒绝爬出目录的条目，一样不少。新增的只是「不必有人按按钮」。<br>动作枚举加一个值即编译不过，直到 switch 答复它（`McpAction` 的既有设计）。<br>选哪一个插件抽成纯函数 `McpController.chooseForInstall`，不联网就能测。 |
| 涉及文件 | `lib/services/mcp_tools.dart`（枚举 + schema）、`lib/providers/mcp_provider.dart`（`installPlugin` 与 `chooseForInstall`）、`lib/models/plugin_catalog_entry.dart`（`namedBy`） |

**名字怎么对上**——这是整个功能里唯一会出错的地方，也是最值得说的地方：

自动化知道的是插件的 **manifest id**（`run_plugin_command` 只认这个），而插件市场
的条目**从来没见过 manifest**——一条搜索结果是 GitHub 上的一个 release，manifest
在还没人下载的那个压缩包里。三种名字都接受：

| 写法 | 怎么对上 |
|------|---------|
| `com.marktext.ai-assistant`（manifest id） | 绕道已安装插件声明的 `repository`，再和条目的仓库比 |
| `marktext-plus-plugins/ai-assistant` | 直接比仓库 |
| `github.marktext-plus-plugins.ai-assistant` | 目录条目自己的 id |

仓库按**仓库**比而不是按字符串比：`…/x`、`…/x/`、`…/x.git`、`git@github.com:…/x.git`
指的是同一个地方，按字符串比会说它们是四个。大小写忽略，GitHub 就是这么处理的。

**验收标准**

1. 一个名字只对上一个条目 → 装它，答复里带上「装了什么版本、原来是什么版本、从哪个仓库来」。
2. 一个名字对上两个 → **拒绝，不猜**。装错插件是这里唯一会发生而下载校验抓不到的失败
   （到手的包是真的，digest 也对，只是不是你要的那个）。
3. 一个名字谁都不对 → 拒绝，并把目录里实际有什么列出来。只说「没这个插件」分不清
   是打错字还是列表本身就取短了。
4. 名字为空 → 在**碰网络之前**就拒绝。否则一个调用方的笔误会挂到超时，然后归咎于网络。
5. 目录取不到（限流、断网）→ 说清楚是目录读不到，而不是「插件不存在」。

**已知边界**

- 只装**最新**的那个 release，不能指定版本。目录里本来也只有最新的一条。
- 装完会让插件列表失效重载；正在运行的插件进程不受影响，下次运行才用新代码。

---

## FEAT-149：通过 MCP 更新应用本体

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-11 |
| 需求描述 | `control` 新增动作 `update_app`：解析出一个可安装的构建、下载、比对 SHA-256、交给安装器装上，应用关闭再自行回来。 |
| 用户场景 | 改完缺陷之后要验证它，必须有人到那台机器上下载安装包、点完向导、再把应用打开。**而我在这边没有那台机器的 shell**——这正是这件事必须做进应用里的原因。做完之后：推 dev → CI 出包 → `update_app` → 应用重启 → MCP 自己回来（端口和 token 都在配置文件里，`home_screen` 启动时就 `apply`）→ 接着测。 |
| 实现方案 | 见下面三节。 |
| 涉及文件 | `lib/services/self_update_service.dart`（新增）、`lib/services/mcp_tools.dart`、`lib/providers/mcp_provider.dart` |

**构建从哪里来——两个来源**

| `source` | `ref` | 要 token | 用途 |
|----------|-------|---------|------|
| `release` | 版本标签，空＝最新 | 否 | 读者拿到的那个 |
| `ci` | 提交的 sha | **是** | 每次推 dev，CI 已经打好了 `windows-x64-setup-<sha>` |

`ci` 这条是关键：**不必为了测试去发一个版本**。本项目「未经人工测试不得发版」，
而要人工测试就得先装上——原本是个死结。CI 的 artifact 解开了它。
artifact 不是公开的（哪怕仓库是公开的），所以要 token；token 是这次调用的参数，
**不落盘、不进配置**。

**安全上的取舍（必须写下来）**

「下载一个东西并运行它」和「下载**这一个**东西并运行它」是两种不同的权力，只需要后者：

- 仓库是服务里的常量（`SugarFatFree/marktext-plus`），**调用方改不了**。不是任意 URL。
- 下载前先拿到 GitHub 公布的 `digest`，**没有 sha256 就直接拒绝**——不是「先下再说」。
  这是整个功能里唯一一道挡在「网络上来的字节」和「机器上运行的程序」之间的门，
  所以它有自己的测试（`digestOf`），删掉它别的测试全都照样绿。
- 比对不上 → 报出期望值与实得值，并明说「什么都没运行」。
- **拒绝降级**：比当前版本旧的 release 不装（几乎总是标签打错了）。CI 构建以 commit
  命名、不自称版本号，所以这条对它不适用——与其拿空字符串去比较然后把结果当成判断，
  不如明说这条规则在这里不成立。
- MCP 本身仍然是强制 token 的（空 token 直接抛错），这个动作不改变那一点。

**替换正在运行的程序，交给 Inno 而不是自己写**

Windows 上运行中的程序不能覆盖自己的文件。绕开它的那套动作——关掉应用、换文件、
再启动——正是 Inno Setup 已经做对的事。自己再写一份，代价是万一换到一半失败，
读者的编辑器就坏了，**而这台机器上没有任何人能给我一个 shell 去修**。
所以 `apply` 只做一件事：以
`/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS`
调起安装器。`/CLOSEAPPLICATIONS` 结束这个进程，`/RESTARTAPPLICATIONS` 把它带回来。

**验收标准**

1. `dryRun` 只说会装什么，不下载、不运行。
2. 架构要对：x64 机器不能拿到 arm64 的安装包。两个文件都以 `-setup.exe` 结尾，
   只按后缀匹配会挑到先出现的那个——而下载校验永远发现不了，包是真的、digest 也对。
3. 没有 sha256 → 拒绝。
4. `source: ci` 而没给 token → **在碰网络之前**拒绝，并说是缺 token。否则 GitHub 回
   404，报出来是「这个提交没被构建过」，看的人会去查 CI 而不是查 token。
5. 比当前旧的 release → 拒绝，并把两个版本号都说出来。
6. 非 Windows → 明说「只写了 Windows」，不是假装成功。

**已知边界**

- 只有 Windows 能真的装上。Linux 的 deb/rpm 要 root，macOS 要换 .app——都还没写。
- `ci` 来源只认 Windows 的 artifact（CI 也只打这一个安装包）。

---

## FEAT-150：Windows 安装包改为按用户安装

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-09-11 |
| 需求描述 | 安装器加 `PrivilegesRequired=lowest`，装到 `%LocalAppData%\Programs\MarkText Plus`。 |
| 用户场景 | 机器级安装（Program Files）要管理员权限，**静默更新时 Windows 会弹 UAC 等人点一下**——那 FEAT-149 就不算无人值守了，人不在电脑前时更新会停在那里。 |
| 实现方案 | `ci.yml` 与 `release.yml` 的 Inno 脚本各加三行：`AppId`（显式 GUID，原先靠 AppName 推导）、`PrivilegesRequired=lowest`、`PrivilegesRequiredOverridesAllowed=commandline`（`/ALLUSERS` 仍可做机器级安装）。`DefaultDirName={autopf}` 不用改——`{autopf}` 在低权限下自己解析成 `%LocalAppData%\Programs`，`HKA` 解析成 HKCU，`{group}` 和 `{autodesktop}` 也都跟着变成当前用户的。 |
| 涉及文件 | `.github/workflows/ci.yml`、`.github/workflows/release.yml` |

**对现有用户的影响（发布说明里必须写）**

已经装在 Program Files 的那一份，新安装器**看不见它**（安装范围不同，卸载信息一个在
HKLM 一个在 HKCU），会当作全新安装装到用户目录去，旧的那份留在原地。
所以升级到这一版的用户需要**手动卸载一次旧的**。这是一次性的代价，换来的是从此
所有更新都不弹 UAC——Chrome、VS Code 默认也是按用户安装，理由相同。

**验收标准**

1. 安装过程不出现 UAC。
2. 文件关联、开始菜单项、桌面快捷方式仍然建立（都落到当前用户下）。
3. `/ALLUSERS` 仍能做机器级安装。
