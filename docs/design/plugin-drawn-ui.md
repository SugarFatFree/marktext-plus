# 插件自绘界面：方案

**状态：已定方向，未实现。** 2026-09-07 由人工测试提出（反馈第 8 条），方向与取舍已经与用户确认。

---

## 问题

插件现在能往五种容器里放东西：悬浮卡片、左侧边栏、右侧边栏抽屉、标签页内宫格、设置页。但**放进去的只能是文本**——插件返回一个字符串，编辑器画出来。

插件想画自己的界面（一个表单、一组按钮、一张图表）就没有办法。

## 别人怎么做的

| | 机制 | 代价 |
|---|---|---|
| **VS Code** | Webview：插件给 HTML/CSS/JS，跑在隔离的 iframe 里，与宿主用 `postMessage` 通信，碰不到宿主 DOM | 每个 webview 是一份浏览器上下文 |
| **IDEA** | 原生 Swing 组件；复杂界面用 JCEF（内嵌 Chromium）加载 HTML | 同上，JCEF 更重 |

共同点：**插件画的东西在一个受控容器里**，宿主决定它能占多大、能拿到什么。

## 方案：两条路，默认那条不花钱

### 一、声明式组件树（默认）

插件返回一棵描述 UI 的表，编辑器解析成 Flutter widget：

```lua
return sdk.ui({
  { column = {
    { text = sdk.t("ask.instruction") },
    { input = { id = "brief", multiline = true, placeholder = "…" } },
    { chips = { id = "idea", options = prompts.writing_ideas(sdk.t) } },
    { row = {
      { button = { id = "go", label = sdk.t("action.write"), primary = true } },
      { button = { id = "cancel", label = sdk.t("action.cancel") } },
    }},
  }}
})
```

交互回传到插件的 `on_event(id, value)`，和现有的 `on_command` / `on_result` 一样是同步的一步。

**为什么它是默认**：

- **零启动代价、零额外内存**——它就是 Flutter widget，和编辑器自己的界面同一套
- 三种运行时（lua/js/process）表达一致
- 样式由宿主掌控，**自动跟主题走**，插件不会画出一个跟编辑器格格不入的框
- 沙箱天然：插件只能用宿主给的组件，没有"逃出容器"这回事
- 五种容器通吃：设置页、抽屉、宫格、卡片、侧边栏都是同一棵树

代价是表达力限于组件集。对上面那五种场景够用；画图表、画时间线就不够。

**第一个用例已经有了**：右侧边栏抽屉需要输入框（BUG-302）。这一轮先用「问题走悬浮卡片」把它接通了，组件树落地后可以让抽屉自己画。

### 二、WebView（可选逃生舱）

插件声明 `"ui": "webview"` 并申请 `ui.webview` 权限，就能在容器里加载自己的 HTML。

**懒加载**：编辑器启动时不碰 WebView，插件第一次打开自己的页面时才初始化。启动速度和常驻内存都不受影响——这是采纳 WebView 的前提。

**平台现实（必须写进 SDK 文档）**：

| 平台 | 用什么 | 情况 |
|---|---|---|
| macOS | WKWebView | 系统自带 |
| Windows | WebView2 | Win11 与较新 Win10 预装；老机器需装 Runtime |
| Linux | WebKitGTK | **不一定有**，需要 `libwebkit2gtk-4.1` |

Linux 这条是真的风险：插件作者在 Mac 上写好，Linux 用户打开是白屏。**所以初始化失败时必须说清楚是什么、怎么装**，而不是留一片空白——空白会被当成编辑器坏了。

## 网络：开放，但可观测

插件在 WebView 里可以自己联网（`fetch`、`XMLHttpRequest`），不必绕道宿主。这是用户明确要求的。

代价是权限系统被绕过——所以补三件事：

### 1. 权限列表说实话

声明 `ui.webview` 的插件，安装时**同时显示 `network.request`**。能力开放，但读者看到的清单要与真实能力一致，不能让人以为"只是打开个页面"。

### 2. 所有流量走宿主的本地代理

编辑器起一个只监听 `127.0.0.1` 的本地代理，WebView 配置为使用它；宿主再把请求转发到**系统代理**。

这一步同时解决三件事：

- **走系统代理** ✓ 由宿主转发，与编辑器自己的请求同一条路
- **可监听** ✓ 每个请求都经过宿主
- **跨平台一致** ✓ 不依赖各 WebView 拦截 API 的差异——那三家的拦截接口互不相同，而本地代理三家都支持

### 3. 抓得到日志

每个插件一份，写进现有的 `PluginLogger`（已有大小上限与轮转）：

```
[时间] [INFO] webview → api.example.com POST /v1/chat 2.1 KB ↑ 8.4 KB ↓ 340 ms
```

**能记到什么程度**：HTTPS 走 CONNECT 隧道，宿主看得到**域名、方法、时间、字节数**，看不到内容。要看内容得做 MITM（自签根证书），那既重又是一个真实的安全风险，不做。

域名和时间对「这个插件在往哪里发东西」这个问题已经够用。真要看内容的插件可以走 `network.request`——那条路本来就是宿主代发，全程可见。

## 分期

| 阶段 | 内容 |
|---|---|
| 1 | 组件树的最小集：`text` / `input` / `chips` / `button` / `row` / `column` / `spacer`，加 `on_event` 回传 |
| 2 | 抽屉与设置页改用组件树；补 `select` / `checkbox` / `markdown` / `image` |
| 3 | WebView：`ui.webview` 权限 ✅、本地代理与日志 ✅、懒加载与失败提示（待 WebView 包选型） |
| 4 | SDK 文档与三份实现（lua / js / dart）跟上，十二种语言 |

阶段 1、2 不引入任何新依赖，也不改变启动路径。阶段 3 才引入 WebView 依赖，且只在插件用到时才初始化。

---

## 第三期的进展（2026-09-07）

**权限与网络这两半已经做完，WebView 本体还没有。**这个顺序是有意的：本地代理不依赖任何 WebView 包，而它正是「宿主能监听 + 走系统代理」这条要求的落点；WebView 包一旦选型有变，这块不用重做。

### 已完成

| | |
|---|---|
| `ui.webview` 权限 | 在权限列表里，**隐含 `network.request` 并一起显示**给读者 |
| 本地代理 `PluginProxy` | 只监听 `127.0.0.1`，转发时走系统代理，每个请求写进那个插件的日志 |
| 图片加载 `PluginImageLoader` | 组件树的 `image` 节点走它：data URI 就地解码，相对路径限插件目录内，`http(s)` 由宿主取并记日志 |

### 代理记得到什么

| 形式 | 日志里有 |
|---|---|
| `http` | 方法、主机、状态码、字节数、耗时 |
| `https`（CONNECT 隧道） | 主机、端口、上下行字节数、耗时——**内容看不到** |

看不到内容是 CONNECT 的性质：之后全是页面自己的 TLS。要看内容得做 MITM 自签证书，那既重又是真实的安全风险。**「这个插件跟哪台服务器说了话」才是读者真正会问的问题**，而想让宿主看全的插件可以走 `network.request`，那条路本来就是宿主代发。

### 写的时候撞到的两个真问题

**一个 Socket 只能被监听一次。** `_serve` 用 `await for` 读完请求头，`_tunnel` 再去 `client.forEach` —— 隧道于是能建立、能回「200 Connection established」，然后一个字节都不转发。改成把 `StreamSubscription` 交接下去。测试当场抓到。

**`transfer-encoding: chunked` 不能原样转发。** Dart 的 `HttpClient` 在交给我之前已经解码了分块，我把那个头照抄出去，客户端就拿未编码的数据当分块解析——`104 is expected to be a Hex digit`。逐跳的响应头（`transfer-encoding`、`content-length`、`connection`）现在都跳过，改用 `Connection: close` 标记结束。

**还有一条测试测不出东西**：我本来写「从 `0.0.0.0` 连不上代理端口」来证明只监听 loopback——但在同一台机器上 `0.0.0.0` 解析到的就是回环，**这条断言两种实现都会通过**。改成让代理暴露 `address`，直接断言它是 `127.0.0.1`。

### WebView 本体：选了 `desktop_webview_window`

三个候选，按这个编辑器的第一条自我描述来筛：

| 包 | 平台 | 形态 | 为什么不是它 |
|---|---|---|---|
| `webview_cef` | 三平台 | 嵌入式 | **打包 CEF**：安装包从几十 MB 变成几百 MB。正面撞上「轻量级」 |
| `flutter_inappwebview` | android/ios/macos/web/windows | 嵌入式 | **没有 Linux**——作者在 macOS 上写好，Linux 读者打开是空的 |
| **`desktop_webview_window`** | **linux/macos/windows** | **独立窗口** | 选它 |

选它的理由：用各平台自己的 WebView（WebView2 / WKWebView / WebKitGTK），**不打包任何运行时**，而且三平台行为一致，不制造「Linux 装了打不开」的生态分裂。代价是页面开在自己的窗口里而不是宫格里——对一个插件的完整页面来说，这未必是坏事。

实测：加进依赖后**没有引入任何新的传递依赖**。

### 一个必须记下来的发现：这个包不支持代理配置

三个平台一个都没暴露。所以「WebView 的流量走本地代理」在这个包上**做不到**。

但它有 `registerJavaScriptMessageHandler` 和 `addScriptToExecuteOnDocumentCreated`——JS 与 Dart 能双向通信。于是换成**桥**：

```js
const answer = await marktext.fetch(url, { method: 'POST', body: '…' });
```

请求过到 Dart 侧，由**编辑器自己的 HttpClient** 发出（读者的系统代理照旧生效），然后连**方法、完整 URL、状态码、大小、耗时**一起写进那个插件的日志。

**桥比隧道更满足「抓日志分析」这条要求**：

| | 本地代理（隧道） | 桥 |
|---|---|---|
| 宿主看得到 | 主机名、字节数 | **完整 URL、请求体、响应、状态** |
| https 内容 | 看不到（是页面自己的 TLS） | **看得到**（宿主自己发的） |

这也正是 VS Code 的模型：webview 不直接联网，通过 postMessage 找扩展要。

**本地代理没有作废**：它已实现、已测试，留给能被指向代理的 WebView（这个包将来支持，或者换包）。它现在不在 WebView 这条路上——写在这里，免得下一个人以为它接着。

### 页面是本地的

从插件自己的目录里加载，不是从 URL。**跑起来的是装进来的那一份**，而不是某台服务器今天决定发什么。绝对路径和逃出目录的路径都拒绝。

### 还需要真机验一次

单元测试盖住的是规则（哪个页面能开、哪些请求放行、日志记什么）。**盖不住的是「窗口真的出得来」**——那要一台真机，而且 Linux 上还取决于装没装 `libwebkit2gtk`。

失败时的提示按平台写好了：Linux 说缺哪个库、怎么装；Windows 说缺 WebView2 Runtime。**空白窗口会被当成编辑器坏了**，所以这条不能省。
