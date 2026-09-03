import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// What the editor's Lua does not do, written down because it does not say so.
///
/// Four of these were found by one plugin trying to split a document into
/// paragraphs, and every one failed silently: a pattern that matches nothing
/// looks exactly like a document with nothing in it. A plugin author has no
/// way to know in advance, so the SDK says, and this is what keeps the SDK
/// honest — if the interpreter is replaced or fixed, these fail and the
/// documentation gets corrected instead of quietly misleading people.
void main() {
  String run(String body) {
    final action = PluginScriptRuntime('function on_command(ctx) $body end')
        .runCommand(const PluginScriptContext(command: 'c'));
    return (action as PluginNotifyAction).message;
  }

  test('`#` on a string raises rather than measuring it', () {
    expect(
      () => run('return { notify = "" .. #"ab" }'),
      throwsA(isA<PluginScriptException>()),
      reason: 'string.len 是可用的那个',
    );
    expect(run('return { notify = "" .. string.len("ab") }'), '2');
  });

  test('`%s` and `%S` match nothing', () {
    expect(run('return { notify = tostring(("a"):match("%S")) }'), 'nil');
    // What works instead: comparing the characters.
    expect(run('return { notify = ("a"):sub(1, 1) }'), 'a');
  });

  test('a lazy gmatch returns nothing', () {
    expect(
      run(r'''
local n = 0
for _ in ("a\nb\n"):gmatch("(.-)\n") do n = n + 1 end
return { notify = "" .. n }
'''),
      '0',
    );
  });

  test('find and sub do work, and are what to use', () {
    expect(
      run(r'''
local s, pos, out = "a\nb", 1, {}
while true do
  local at = s:find("\n", pos, true)
  if at == nil then out[#out+1] = s:sub(pos) break end
  out[#out+1] = s:sub(pos, at - 1)
  pos = at + 1
end
return { notify = table.concat(out, ",") }
'''),
      'a,b',
    );
  });

  test('`#` on a table works, so the two cannot be told apart by feel', () {
    expect(run('local t = {1,2} return { notify = "" .. #t }'), '2');
  });
}
