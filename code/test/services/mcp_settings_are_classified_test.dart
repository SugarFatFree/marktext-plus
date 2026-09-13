import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/services/mcp_tools.dart';

/// Every setting is either settable over the wire or refused for a reason.
///
/// `set_setting` writes a name into [AppConfig]'s own JSON, so every field is
/// reachable by construction — which is what keeps it from falling behind the
/// config the way a hand-written list of settable names would. The price is
/// that [McpSettings.notOverTheWire] is a list of *refusals*, and a list of
/// refusals fails open: a credential added next month would be settable until
/// somebody remembered to add it.
///
/// So the field list is pinned here. Adding a setting turns this red, and the
/// person adding it has to say which side it is on — which is the decision that
/// would otherwise be made by forgetting.
void main() {
  /// Every field [AppConfig] writes, as of the last person to read this list.
  const known = <String>{
    'sideBarVisible',
    'tabBarVisible',
    'editMode',
    'splitRatio',
    'fontFamily',
    'fontSize',
    'lineHeight',
    'autoSave',
    'autoSaveDelay',
    'themeName',
    'followSystemTheme',
    'lightModeTheme',
    'darkModeTheme',
    'locale',
    'bulletListMarker',
    'tabSize',
    'enableHtml',
    'wrapCodeBlocks',
    'codeBlockLineNumbers',
    'autoPairBracket',
    'autoPairQuote',
    'autoPairMarkdownSyntax',
    'windowWidth',
    'windowHeight',
    'windowX',
    'windowY',
    'isMaximized',
    'recentFiles',
    'focusMode',
    'typewriterMode',
    'codeFontFamily',
    'previewFontFamily',
    'codeFontSize',
    'editorMaxWidth',
    'textDirection',
    'imageStorageMode',
    'imageFolder',
    'fileOpenBehavior',
    'checkForUpdates',
    'lastUpdateCheck',
    'skipVersion',
    'sideBarDirectory',
    'sideBarOpenedFiles',
    'sessionTabs',
    'sessionActiveTab',
    'aiEnabled',
    'aiApiKey',
    'aiProvider',
    'aiEndpoint',
    'mcpEnabled',
    'mcpPort',
    'mcpToken',
    'aiModel',
  };

  test('the pinned field list is still the whole of AppConfig', () {
    expect(
      AppConfig().toJson().keys.toSet(),
      known,
      reason: '设置变了。把新增的每一个放进 McpSettings.notOverTheWire（写明为什么）'
          '或者确认它可以经由自动化接口修改，然后把它加进这里的清单',
    );
  });

  test('every refusal names a setting that exists', () {
    final fields = AppConfig().toJson().keys.toSet();
    final ghosts =
        McpSettings.notOverTheWire.keys.where((k) => !fields.contains(k));
    expect(ghosts, isEmpty,
        reason: '这些设置已经不存在了，拒绝名单里的条目是死的：${ghosts.toList()}');
  });

  test('every refusal says why', () {
    for (final entry in McpSettings.notOverTheWire.entries) {
      expect(entry.value.trim(), isNotEmpty,
          reason: '${entry.key} 被拒绝但没写理由');
    }
  });

  test('the things that must never go over the wire are refused', () {
    // Named one by one rather than by prefix: a prefix is a rule about
    // spelling, and what matters here is what each of these does. A credential,
    // where a credential is sent, and the connection this very request arrived
    // on.
    for (final name in [
      'aiApiKey',
      'aiEndpoint',
      'aiProvider',
      'mcpToken',
      'mcpPort',
      'mcpEnabled',
    ]) {
      expect(McpSettings.notOverTheWire.keys, contains(name),
          reason: '$name 可以被远端改写');
    }
  });

  test('the appearance settings a check needs are not refused', () {
    // The reason this action exists: an appearance can only be verified by
    // putting the editor into the state and looking. If these were refused the
    // action would be decorative.
    for (final name in [
      'previewFontFamily',
      'fontFamily',
      'codeFontFamily',
      'fontSize',
      'lineHeight',
      'themeName',
      'editorMaxWidth',
      'wrapCodeBlocks',
      'codeBlockLineNumbers',
      'textDirection',
      'locale',
    ]) {
      expect(AppConfig().toJson().keys, contains(name),
          reason: '$name 不是一个设置了，这条测试的名单要跟着改');
      expect(McpSettings.notOverTheWire.keys, isNot(contains(name)),
          reason: '$name 被拒绝了，那这个动作就验不了外观');
    }
  });
}
