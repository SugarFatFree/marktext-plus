import 'dart:convert';
import 'dart:io';
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
  };

  Map<String, String> _keybindings = Map.from(defaultKeybindings);
  String? _configDir;

  Map<String, String> get keybindings => Map.unmodifiable(_keybindings);

  String getKeybinding(String action) {
    return _keybindings[action] ?? '';
  }

  void setKeybinding(String action, String keys) {
    _keybindings[action] = keys;
    _save();
  }

  void resetToDefaults() {
    _keybindings = Map.from(defaultKeybindings);
    _save();
  }

  Future<void> load() async {
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

  Future<void> _save() async {
    final file = await _getFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(_keybindings));
  }

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
