import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
// SingleActivator lives in widgets, not services, alongside LogicalKeyboardKey.
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class KeybindingService {
  static final KeybindingService _instance = KeybindingService._();
  factory KeybindingService() => _instance;
  KeybindingService._();

  static const Map<String, String> defaultKeybindings = {
    'bold': 'Ctrl+B',
    'italic': 'Ctrl+I',
    'underline': 'Ctrl+U',
    'strikethrough': 'Ctrl+Shift+S',
    'heading1': 'Ctrl+1',
    'heading2': 'Ctrl+2',
    'heading3': 'Ctrl+3',
    'codeBlock': 'Ctrl+Shift+K',
    'inlineCode': 'Ctrl+`',
    'link': 'Ctrl+K',
    'image': 'Ctrl+Shift+I',
    'orderedList': 'Ctrl+Shift+O',
    'unorderedList': 'Ctrl+Shift+U',
    'taskList': 'Ctrl+Shift+T',
    'quoteBlock': 'Ctrl+Shift+Q',
    'table': 'Ctrl+T',
    'find': 'Ctrl+F',
    'replace': 'Ctrl+H',
    'save': 'Ctrl+S',
    'open': 'Ctrl+O',
    'undo': 'Ctrl+Z',
    'redo': 'Ctrl+Shift+Z',
    'selectAll': 'Ctrl+A',
    'duplicateLine': 'Ctrl+D',
    'highlight': 'Ctrl+Shift+H',
    'promoteHeading': 'Ctrl+=',
    'demoteHeading': 'Ctrl+-',
    // These four were offered in the settings list with no default, so they
    // showed as blank and nothing could trigger them.
    'heading4': 'Ctrl+4',
    'heading5': 'Ctrl+5',
    'heading6': 'Ctrl+6',
    'inlineMath': 'Ctrl+M',
    'mathBlock': 'Ctrl+Shift+M',
    'closeTab': 'Ctrl+W',
    // Upstream uses F3 on Linux and Windows for these.
    'findNext': 'F3',
    'findPrevious': 'Shift+F3',

    // These eleven were hard-coded as SingleActivators on their menu items,
    // which meant they fired but did not exist as far as this service was
    // concerned: they never appeared in the settings list, so nobody could see
    // what they were or change them. Worse, two of them silently competed with
    // bindings that *were* in this map — zoom in and zoom out sat on Ctrl+=
    // and Ctrl+-, the same two keys as promote and demote heading — and
    // nothing in the app could have shown that.
    //
    // The keys are kept exactly as they were, so nobody's habits change, with
    // the single exception of the two that collided.
    'sourceMode': 'Ctrl+Alt+1',
    'previewMode': 'Ctrl+Alt+2',
    'splitMode': 'Ctrl+Alt+3',
    'toggleSidebar': 'Ctrl+Shift+B',
    'toggleTabBar': 'Ctrl+Alt+T',
    // Ctrl+P prints, here as everywhere else; the palette takes
    // Ctrl+Shift+P, which is what upstream and VS Code both use.
    'commandPalette': 'Ctrl+Shift+P',
    'focusMode': 'Ctrl+Shift+F',
    'typewriterMode': 'Ctrl+Shift+W',
    // Moved off Ctrl+= and Ctrl+-, which promote and demote heading already
    // held. Upstream resolves the same clash by giving zoom no default at all
    // and letting the headings keep the keys; writing a document is what the
    // program is for, and the zoom commands are still in the View menu.
    'zoomIn': 'Ctrl+Shift+=',
    'zoomOut': 'Ctrl+Shift+-',
    'resetZoom': 'Ctrl+0',

    // Matching upstream MarkText's Windows defaults, and only where the key is
    // not already spoken for here. Upstream binds nineteen more that would
    // collide — Ctrl+T is a new tab there and a table here, Ctrl+Shift+S is
    // Save As there and strikethrough here — and taking those would break the
    // habits of whoever already uses this app, which is its users' decision
    // rather than a parity exercise.
    'newWindow': 'Ctrl+N',
    'settings': 'Ctrl+,',
    'quit': 'Ctrl+Q',
    'print': 'Ctrl+P',
    'exportPdf': 'Ctrl+Alt+E',
    'reloadImages': 'F5',
    'fullScreen': 'F11',
    'clearFormatting': 'Ctrl+Shift+R',
    'createParagraph': 'Ctrl+Shift+N',
    'deleteParagraph': 'Ctrl+Shift+D',
    'toParagraph': 'Ctrl+Shift+0',
    'looseList': 'Ctrl+Alt+L',
    'frontMatter': 'Ctrl+Alt+Y',
    'htmlBlock': 'Ctrl+Alt+H',
  };

  Map<String, String> _keybindings = Map.from(defaultKeybindings);
  String? _configDir;

  Map<String, String> get keybindings => Map.unmodifiable(_keybindings);

  String getKeybinding(String action) {
    return _keybindings[action] ?? '';
  }

  void setKeybinding(String action, String keys) {
    _keybindings[action] = keys;
    _index = null;
    _pendingWrite = _save();
  }

  void resetToDefaults() {
    _keybindings = Map.from(defaultKeybindings);
    _index = null;
    _pendingWrite = _save();
  }

  Future<void>? _pendingWrite;

  /// Completes once the last change has finished being written.
  ///
  /// Callers do not wait for the write, which is right for the app but leaves
  /// a test unable to tell when the file has settled.
  @visibleForTesting
  Future<void> get pendingWrite => _pendingWrite ?? Future<void>.value();

  /// Key combination to action, built from [keybindings] on demand.
  ///
  /// Every keystroke asks which action it triggers, so parsing all thirty-odd
  /// bindings each time would be wasteful. Rebuilt whenever they change.
  Map<_Combo, String>? _index;

  /// The platform the cached index was built for. "Ctrl" resolves to a
  /// different modifier on macOS, so the cache is only valid for one of them.
  bool? _indexIsMacOS;

  Map<_Combo, String> _reverseIndex(bool isMacOS) {
    final cached = _index;
    if (cached != null && _indexIsMacOS == isMacOS) return cached;

    final built = <_Combo, String>{};
    for (final entry in _keybindings.entries) {
      final combo = _Combo.parse(entry.value, isMacOS: isMacOS);
      // First binding wins, so a duplicate cannot shadow an earlier action.
      if (combo != null) built.putIfAbsent(combo, () => entry.key);
    }
    _index = built;
    _indexIsMacOS = isMacOS;
    return built;
  }

  /// The shortcut for [action], for display in a menu.
  ///
  /// Null when the action has no binding, which leaves the menu item without a
  /// shortcut label rather than showing a wrong one.
  SingleActivator? activatorFor(String action, {required bool isMacOS}) {
    final combo = _Combo.parse(getKeybinding(action), isMacOS: isMacOS);
    if (combo == null) return null;
    return SingleActivator(
      combo.key,
      control: combo.control,
      shift: combo.shift,
      alt: combo.alt,
      meta: combo.meta,
    );
  }

  /// The action [event] triggers, or null.
  ///
  /// Modifiers must match exactly: Ctrl+S and Ctrl+Shift+S are different
  /// actions, and so are Ctrl+Z and Ctrl+Shift+Z.
  String? actionForEvent(KeyEvent event, {required bool isMacOS}) {
    if (event is! KeyDownEvent) return null;
    final keyboard = HardwareKeyboard.instance;
    final combo = _Combo(
      key: event.logicalKey,
      control: keyboard.isControlPressed,
      shift: keyboard.isShiftPressed,
      alt: keyboard.isAltPressed,
      meta: keyboard.isMetaPressed,
    );
    // Ordinary typing must not be searched against the table, and it is the
    // overwhelmingly common case. Function keys are the exception: F3 types
    // nothing, so it is a shortcut on its own.
    if (!combo.control &&
        !combo.meta &&
        !combo.alt &&
        !_isFunctionKey(combo.key)) {
      return null;
    }
    return _reverseIndex(isMacOS)[combo];
  }

  /// Not const: LogicalKeyboardKey overrides ==, so it has no primitive
  /// equality and cannot be an element of a constant set.
  static final Set<LogicalKeyboardKey> _functionKeys = {
    LogicalKeyboardKey.f1, LogicalKeyboardKey.f2, LogicalKeyboardKey.f3,
    LogicalKeyboardKey.f4, LogicalKeyboardKey.f5, LogicalKeyboardKey.f6,
    LogicalKeyboardKey.f7, LogicalKeyboardKey.f8, LogicalKeyboardKey.f9,
    LogicalKeyboardKey.f10, LogicalKeyboardKey.f11, LogicalKeyboardKey.f12,
  };

  static bool _isFunctionKey(LogicalKeyboardKey key) =>
      _functionKeys.contains(key);

  /// Maps the key names used in bindings to logical keys.
  static LogicalKeyboardKey? keyForLabel(String label) {
    return switch (label) {
      'A' => LogicalKeyboardKey.keyA,
      'B' => LogicalKeyboardKey.keyB,
      'C' => LogicalKeyboardKey.keyC,
      'D' => LogicalKeyboardKey.keyD,
      'E' => LogicalKeyboardKey.keyE,
      'F' => LogicalKeyboardKey.keyF,
      'G' => LogicalKeyboardKey.keyG,
      'H' => LogicalKeyboardKey.keyH,
      'I' => LogicalKeyboardKey.keyI,
      'J' => LogicalKeyboardKey.keyJ,
      'K' => LogicalKeyboardKey.keyK,
      'L' => LogicalKeyboardKey.keyL,
      'M' => LogicalKeyboardKey.keyM,
      'N' => LogicalKeyboardKey.keyN,
      'O' => LogicalKeyboardKey.keyO,
      'P' => LogicalKeyboardKey.keyP,
      'Q' => LogicalKeyboardKey.keyQ,
      'R' => LogicalKeyboardKey.keyR,
      'S' => LogicalKeyboardKey.keyS,
      'T' => LogicalKeyboardKey.keyT,
      'U' => LogicalKeyboardKey.keyU,
      'V' => LogicalKeyboardKey.keyV,
      'W' => LogicalKeyboardKey.keyW,
      'X' => LogicalKeyboardKey.keyX,
      'Y' => LogicalKeyboardKey.keyY,
      'Z' => LogicalKeyboardKey.keyZ,
      '1' => LogicalKeyboardKey.digit1,
      '2' => LogicalKeyboardKey.digit2,
      '3' => LogicalKeyboardKey.digit3,
      '4' => LogicalKeyboardKey.digit4,
      '5' => LogicalKeyboardKey.digit5,
      '6' => LogicalKeyboardKey.digit6,
      '7' => LogicalKeyboardKey.digit7,
      '8' => LogicalKeyboardKey.digit8,
      '9' => LogicalKeyboardKey.digit9,
      '0' => LogicalKeyboardKey.digit0,
      ',' => LogicalKeyboardKey.comma,
      '.' => LogicalKeyboardKey.period,
      '`' => LogicalKeyboardKey.backquote,
      '=' => LogicalKeyboardKey.equal,
      '-' => LogicalKeyboardKey.minus,
      'F1' => LogicalKeyboardKey.f1,
      'F2' => LogicalKeyboardKey.f2,
      'F3' => LogicalKeyboardKey.f3,
      'F4' => LogicalKeyboardKey.f4,
      'F5' => LogicalKeyboardKey.f5,
      'F6' => LogicalKeyboardKey.f6,
      'F7' => LogicalKeyboardKey.f7,
      'F8' => LogicalKeyboardKey.f8,
      'F9' => LogicalKeyboardKey.f9,
      'F10' => LogicalKeyboardKey.f10,
      'F11' => LogicalKeyboardKey.f11,
      'F12' => LogicalKeyboardKey.f12,
      _ => null,
    };
  }

  Future<void> load() async {
    _index = null;
    final file = await _getFile();
    if (await file.exists()) {
      try {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _keybindings = Map.from(defaultKeybindings);
        for (final entry in json.entries) {
          if (entry.value is String) {
            _keybindings[entry.key] = entry.value as String;
          }
        }
      } catch (_) {
        _keybindings = Map.from(defaultKeybindings);
      }
    }
  }

  /// Persists the bindings.
  ///
  /// Callers do not await this, so an exception here would surface as an
  /// unhandled asynchronous error rather than at any useful place. The
  /// bindings stay correct in memory for this session either way.
  Future<void> _save() async {
    try {
      final file = await _getFile();
      await file.parent.create(recursive: true);
      await file
          .writeAsString(const JsonEncoder.withIndent('  ').convert(_keybindings));
    } catch (_) {
      // Nothing useful to do: the user's choice still applies until they quit.
    }
  }

  /// Points persistence at [directory] instead of the application support
  /// directory, so a test does not write into the developer's real config.
  @visibleForTesting
  set configDirectory(String directory) => _configDir = directory;

  Future<String> _getConfigDir() async {
    if (_configDir != null) return _configDir!;
    final dir = await getApplicationSupportDirectory();
    _configDir = dir.path;
    return _configDir!;
  }

  Future<File> _getFile() async {
    final dir = await _getConfigDir();
    return File(p.join(dir, 'keybindings.json'));
  }
}

/// A key plus the modifiers held with it.
class _Combo {
  const _Combo({
    required this.key,
    required this.control,
    required this.shift,
    required this.alt,
    required this.meta,
  });

  final LogicalKeyboardKey key;
  final bool control;
  final bool shift;
  final bool alt;
  final bool meta;

  /// Parses `Ctrl+Shift+S`.
  ///
  /// "Ctrl" means Command on macOS, which is what users of both platforms
  /// expect from a binding written that way.
  static _Combo? parse(String binding, {required bool isMacOS}) {
    if (binding.trim().isEmpty) return null;

    var control = false;
    var shift = false;
    var alt = false;
    var meta = false;
    String? label;

    for (final raw in binding.split('+')) {
      final part = raw.trim();
      switch (part) {
        case 'Ctrl':
          if (isMacOS) {
            meta = true;
          } else {
            control = true;
          }
        case 'Shift':
          shift = true;
        case 'Alt':
          alt = true;
        case 'Meta':
          meta = true;
        default:
          label = part;
      }
    }

    if (label == null) return null;
    final key = KeybindingService.keyForLabel(label);
    if (key == null) return null;

    return _Combo(
      key: key,
      control: control,
      shift: shift,
      alt: alt,
      meta: meta,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _Combo &&
      other.key == key &&
      other.control == control &&
      other.shift == shift &&
      other.alt == alt &&
      other.meta == meta;

  @override
  int get hashCode => Object.hash(key, control, shift, alt, meta);
}
