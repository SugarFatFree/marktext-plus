# V1.1.4 Bug 修复记录

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-001 | 2026-04-28 | 文件打开行为配置每次启动都弹窗询问 | P0 | 已修复 |

---

## BUG-001 — 文件打开行为配置每次启动都弹窗询问

### 现象

用户每次双击 `.md` 文件打开应用时，都会弹出"如何打开文件？"对话框，即使之前已经选择过"在新窗口打开"或"在当前窗口打开"。

### 复现步骤

1. 双击 `.md` 文件启动应用
2. 弹出对话框，选择"在当前窗口打开"
3. 关闭应用
4. 再次双击 `.md` 文件
5. **预期**：不再弹出对话框
6. **实际**：对话框再次弹出

### 根因分析

**问题 1：配置加载竞态条件**

`SettingsNotifier` 的初始化流程存在竞态条件：

```dart
// settings_provider.dart (旧代码)
SettingsNotifier(this._configService) : super(AppConfig()) {
  _loadConfig();  // 异步加载
}

Future<void> _loadConfig() async {
  state = await _configService.load();
}
```

1. `SettingsNotifier` 构造函数用 `super(AppConfig())` 初始化默认配置（`fileOpenBehavior = notSet`）
2. 构造函数立即返回
3. `_loadConfig()` 异步执行，从磁盘加载配置
4. `HomeScreen.build()` 中调用 `_openStartupFiles()`
5. `_openStartupFiles()` 同步读取 `ref.read(settingsProvider)`
6. **此时 `_loadConfig()` 还未完成**，读到的是默认配置
7. `fileOpenBehavior == notSet` 条件成立，弹出对话框

**问题 2：配置文件路径不明确**

用户在应用安装目录下找不到配置文件，因为配置存储在系统应用支持目录：

- Windows: `C:\Users\<用户名>\AppData\Roaming\com.example\marktext_plus\config.json`
- macOS: `~/Library/Application Support/com.example.marktext_plus/config.json`
- Linux: `~/.local/share/com.example.marktext_plus/config.json`

### 修复方案

**修复 1：预加载配置并传递给 SettingsNotifier**

在 `main()` 中已经加载了配置，但只用于提取 `initialLocale`。现在将完整配置传给 `SettingsNotifier` 作为初始状态：

```dart
// settings_provider.dart (新代码)
SettingsNotifier(this._configService, AppConfig initialConfig) : super(initialConfig);
```

```dart
// main.dart (新代码)
final config = await configService.load();
final initialLocale = LocaleNotifier.parseLocale(config.locale);

final container = ProviderContainer(
  overrides: [
    settingsProvider.overrideWith((ref) => SettingsNotifier(configService, config)),
    // ...
  ],
);
```

这样 `SettingsNotifier` 从一开始就有正确的配置状态，避免了竞态条件。

**修复 2：（后续优化）添加配置路径显示**

可以在设置页面显示配置文件路径，方便用户查找和备份。

### 涉及文件

- `lib/providers/settings_provider.dart` — 修改 `SettingsNotifier` 构造函数，接受初始配置
- `lib/main.dart` — 将预加载的配置传给 `SettingsNotifier`

### 测试验证

1. 删除配置文件（如果存在）
2. 双击 `.md` 文件启动应用
3. 弹出对话框，选择"在当前窗口打开"
4. 关闭应用
5. 再次双击 `.md` 文件
6. **验证**：不再弹出对话框，文件直接在当前窗口打开

### 相关问题

- 单实例模式目前是无条件启用的（Windows 平台），即使用户选择"在新窗口打开"也无法创建新窗口。这是一个独立的问题，需要在后续版本中修复：单实例检测应该在加载配置后，根据 `fileOpenBehavior` 决定是否启用。
