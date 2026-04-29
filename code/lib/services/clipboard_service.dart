import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

class ClipboardService {
  static Future<void> copyWithHtml(String plainText, String html) async {
    if (Platform.isWindows) {
      await _copyWithHtmlWindows(plainText, html);
    } else {
      await Clipboard.setData(ClipboardData(text: plainText));
    }
  }

  static Future<void> _copyWithHtmlWindows(String plainText, String html) async {
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      final kernel32 = DynamicLibrary.open('kernel32.dll');

      final openClipboard = user32.lookupFunction<
          Int32 Function(IntPtr hWndNewOwner),
          int Function(int hWndNewOwner)>('OpenClipboard');
      final emptyClipboard = user32.lookupFunction<
          Int32 Function(), int Function()>('EmptyClipboard');
      final setClipboardData = user32.lookupFunction<
          IntPtr Function(Uint32 uFormat, IntPtr hMem),
          int Function(int uFormat, int hMem)>('SetClipboardData');
      final closeClipboard = user32.lookupFunction<
          Int32 Function(), int Function()>('CloseClipboard');
      final globalAlloc = kernel32.lookupFunction<
          IntPtr Function(Uint32 uFlags, IntPtr dwBytes),
          int Function(int uFlags, int dwBytes)>('GlobalAlloc');
      final globalLock = kernel32.lookupFunction<
          IntPtr Function(IntPtr hMem),
          int Function(int hMem)>('GlobalLock');
      final globalUnlock = kernel32.lookupFunction<
          Int32 Function(IntPtr hMem),
          int Function(int hMem)>('GlobalUnlock');
      final registerClipboardFormat = user32.lookupFunction<
          Uint32 Function(Pointer<Utf16> lpszFormat),
          int Function(Pointer<Utf16> lpszFormat)>('RegisterClipboardFormatW');

      final htmlFormatName = 'HTML Format'.toNativeUtf16();
      final htmlFormat = registerClipboardFormat(htmlFormatName);
      calloc.free(htmlFormatName);

      if (openClipboard(0) == 0) throw Exception('Failed to open clipboard');

      try {
        emptyClipboard();
        _setUnicodeText(plainText, globalAlloc, globalLock, globalUnlock, setClipboardData);
        _setHtmlFormat(html, htmlFormat, globalAlloc, globalLock, globalUnlock, setClipboardData);
      } finally {
        closeClipboard();
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: plainText));
    }
  }

  static void _setUnicodeText(
    String text,
    int Function(int, int) globalAlloc,
    int Function(int) globalLock,
    int Function(int) globalUnlock,
    int Function(int, int) setClipboardData,
  ) {
    final units = text.codeUnits;
    final hMem = globalAlloc(0x0002, (units.length + 1) * 2);
    if (hMem == 0) return;
    final ptr = globalLock(hMem);
    if (ptr == 0) return;
    final dst = Pointer<Uint16>.fromAddress(ptr);
    for (int i = 0; i < units.length; i++) {
      (dst + i).value = units[i];
    }
    (dst + units.length).value = 0;
    globalUnlock(hMem);
    setClipboardData(13, hMem);
  }

  static void _setHtmlFormat(
    String html,
    int htmlFormat,
    int Function(int, int) globalAlloc,
    int Function(int) globalLock,
    int Function(int) globalUnlock,
    int Function(int, int) setClipboardData,
  ) {
    final utf8Html = utf8.encode(html);
    const prefix = '<html><body>\r\n<!--StartFragment-->\r\n';
    const suffix = '\r\n<!--EndFragment-->\r\n</body></html>';
    final utf8Prefix = utf8.encode(prefix);
    final utf8Suffix = utf8.encode(suffix);

    const headerTemplate = 'Version:0.9\r\n'
        'StartHTML:XXXXXXXXXX\r\n'
        'EndHTML:XXXXXXXXXX\r\n'
        'StartFragment:XXXXXXXXXX\r\n'
        'EndFragment:XXXXXXXXXX\r\n';
    final headerLen = headerTemplate.length;

    final startHtml = headerLen;
    final startFragment = startHtml + utf8Prefix.length;
    final endFragment = startFragment + utf8Html.length;
    final endHtml = endFragment + utf8Suffix.length;

    String pad(int v) => v.toString().padLeft(10, '0');
    final header = 'Version:0.9\r\n'
        'StartHTML:${pad(startHtml)}\r\n'
        'EndHTML:${pad(endHtml)}\r\n'
        'StartFragment:${pad(startFragment)}\r\n'
        'EndFragment:${pad(endFragment)}\r\n';

    final utf8Header = utf8.encode(header);
    final total = utf8Header.length + utf8Prefix.length + utf8Html.length + utf8Suffix.length;

    final hMem = globalAlloc(0x0002, total + 1);
    if (hMem == 0) return;
    final ptr = globalLock(hMem);
    if (ptr == 0) return;
    final dst = Pointer<Uint8>.fromAddress(ptr);
    int off = 0;
    for (final b in utf8Header) { (dst + off).value = b; off++; }
    for (final b in utf8Prefix) { (dst + off).value = b; off++; }
    for (final b in utf8Html)   { (dst + off).value = b; off++; }
    for (final b in utf8Suffix) { (dst + off).value = b; off++; }
    (dst + off).value = 0;
    globalUnlock(hMem);
    setClipboardData(htmlFormat, hMem);
  }
}