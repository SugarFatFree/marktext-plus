# MarkText Plus v1.6.1

> Release notes. English is the default language; the Chinese section follows.

## English

The plugin system, which did not previously work on anyone's machine but the
developer's.

### Added

- A plugin is one Lua or JavaScript file that runs inside the editor. No SDK to
  install, no build step, and the same file works on Windows, macOS and Linux.
  Both languages speak the same protocol, so the editor does not care which one
  an author picked.
- Plugins declare what they may do — read your document, change it, the
  clipboard, your workspace, the network, ask the model you configured — and
  you see that list before installing. Unlike the editors this borrows the idea
  from, it is enforced rather than merely displayed: nothing here is reviewed by
  anybody, so a plugin doing what it did not ask for is refused.
- Each plugin keeps its own settings, in its own directory, on a page the editor
  draws from what the plugin declared: a switch for a switch, a hidden box for a
  secret. Plugins supply data, never widgets.
- Plugins ship their own translations, for whichever languages their author
  wants, independent of the twelve the editor speaks.
- A plugin needing a real toolchain can ship compiled executables instead,
  named by operating system and, only where it matters, by architecture. A
  platform it was not built for is named to you rather than guessed at.
- Right-clicking an installed plugin opens its folder — where its settings file
  lives, under the system application-support directory.
- Moved the plugin entry into the left sidebar below Files, Search and Table of
  Contents, with a direct link to the plugin SDK.
- Windows on ARM builds, native rather than emulated. This was recorded as
  impossible because Flutter publishes no arm64 Windows SDK — still true — but
  the arm64 Dart and engine binaries have been published separately since
  3.44.0, and an arm64 runner will fetch them. What the build produces is
  checked by reading the machine type out of the executable rather than by
  trusting that a build which succeeded built the right thing.

### Fixed

- Selecting text and right-clicking now offers what a plugin contributed, in
  both the editing pane and the preview. The plugin's own menu entries had never
  been read, and the AI translation action sat as an icon in the plugins panel's
  title bar — where it was easiest to put, not where anyone translating a
  paragraph is looking.
- "Bad state: plugin process exited". The editor started `.dart` plugins with
  `Platform.resolvedExecutable`, which in a release build is the editor's own
  binary: it launched a second editor and waited for it to speak JSON-RPC. A
  plugin cannot be shipped as Dart source at all, since your machine has no Dart
  SDK, so that is refused at install time with the alternative named.
- Plugin processes no longer outlive the editor. A child is not killed when its
  parent dies, so a crash left every plugin still running with nothing that knew
  about them.
- The AI translation plugin owns its prompt again, and shows the translation
  beside the original rather than replacing your selection.
- GitHub Topic discovery uses the system proxy environment when configured and
  reports network or empty-release states.
- Tightened the top-right toolbar layout and changed zoom controls to
  magnifying-glass icons.

### Changed

- AI model settings save while typing, take a single visible API key field, and
  can test the provider. A plugin never receives the key: the editor makes the
  request.

## 中文

这一版是插件系统本身——此前它在开发者以外的任何机器上都跑不起来。

### 新增

- 一个插件就是一个 Lua 或 JavaScript 文件，在编辑器内运行。不需要装 SDK，不需要编译，同一个文件在
  Windows、macOS、Linux 上通用。两种语言走同一套协议，编辑器不关心作者选了哪种。
- 插件声明它能做什么——读文档、改文档、剪贴板、工作区、网络、调用你配置的模型——你在安装前就看得到。
  与借鉴对象不同的是，这份清单是**强制执行**的：这里没有任何人做审核，所以插件做了没申请的事会被拒绝。
- 每个插件在自己的目录里保存自己的设置，设置页由编辑器按插件声明的字段绘制：开关就给开关，密码就遮起来。
  插件提供数据，不提供控件。
- 插件自带翻译，作者想支持哪些语言就支持哪些，不受编辑器那 12 种语言限制。
- 确实需要真正工具链的插件可以改为分发编译好的可执行文件，按操作系统指定，架构只在需要区分时才写。
  没有为某个平台构建时会明说是哪个平台，而不是瞎猜一个去跑。
- 右键已安装插件可以打开它的目录——配置文件就在那里，位于系统应用支持目录下。
- 插件入口移到左侧边栏，位于文件、搜索、目录之下，并提供插件 SDK 的直达链接。
- Windows on ARM 原生构建，不再靠模拟运行 x64 版本。此前记为"做不到"，理由是 Flutter 不发布 arm64 的
  Windows SDK——这句话至今成立——但 arm64 的 Dart 和引擎产物从 3.44.0 起就单独发布了，arm64 的构建机
  能拉到它们。产出的架构是从可执行文件的 PE 头读出来校验的，而不是靠"构建成功"这四个字。

### 修复

- 选中文本右键，现在会出现插件贡献的菜单项，源码区和预览区都有。此前插件自己声明的菜单从未被读取，
  AI 翻译动作被挂在插件面板标题栏的图标上——那是开发时最好加按钮的地方，不是用户翻译一段话时会看的地方。
- "Bad state: plugin process exited"。编辑器用 `Platform.resolvedExecutable` 去启动 `.dart` 插件，
  而在 release 构建里那就是编辑器自己的二进制：它启动了第二个编辑器，然后等它说 JSON-RPC。插件根本不能
  以 Dart 源码分发——你的机器上没有 Dart SDK——所以这种入口现在在安装时就被拒绝，并告诉作者该怎么办。
- 插件进程不再比编辑器活得久。子进程不会随父进程死亡，所以崩溃会留下一堆还在运行、却无人知晓的插件进程。
- AI 翻译插件重新拥有自己的提示词，并把译文放在原文旁边显示，而不是替换掉你的选区。
- GitHub Topic 发现会使用系统代理环境，并明确显示网络错误或没有可安装 Release。
- 收紧右上角工具栏布局，缩放按钮改为放大镜图标。

### 变更

- AI 模型设置边打字边保存，只有一个明文 API key 字段，并可测试服务商配置。插件永远拿不到这个 key：
  请求由编辑器发出。
