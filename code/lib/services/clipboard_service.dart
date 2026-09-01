import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ClipboardService {
  /// Matches kClipboardChannel in linux/runner/my_application.cc and
  /// AppDelegate.clipboardChannelName in macos/Runner/AppDelegate.swift.
  static const _clipboardChannel = MethodChannel('com.marktextplus/clipboard');

  /// Puts [plainText] on the clipboard with [html] beside it.
  ///
  /// A word processor takes the HTML and keeps the headings and the bold; a
  /// text editor takes the text. Windows goes through the FFI below because
  /// its `HTML Format` flavour needs a header no channel would write for us;
  /// the other two hand the pair to their own native clipboard.
  ///
  /// The plain text is written whatever happens: if the rich flavour cannot
  /// be attached, a copy that pastes as text is the right outcome, and a copy
  /// that does nothing at all is not.
  static Future<void> copyWithHtml(String plainText, String html) async {
    if (Platform.isWindows) {
      await _copyWithHtmlWindows(plainText, html);
      return;
    }

    if (Platform.isMacOS || Platform.isLinux) {
      try {
        final ok = await _clipboardChannel.invokeMethod<bool>(
          'copyWithHtml',
          {'text': plainText, 'html': html},
        );
        if (ok == true) return;
      } catch (_) {
        // An older build of the runner has no such channel.
      }
    }

    await Clipboard.setData(ClipboardData(text: plainText));
  }

  /// Converts line feeds to the CRLF form expected by Windows text
  /// consumers such as classic Notepad.
  @visibleForTesting
  static String windowsPlainText(String text) =>
      text.replaceAll('\r\n', '\n').replaceAll('\n', '\r\n');

  /// The HTML flavour of whatever is on the clipboard, if it has one.
  ///
  /// Null when there is none — which is the ordinary case for text copied
  /// from a text editor — and the caller then pastes the plain flavour.
  static Future<String?> readHtml() async {
    if (Platform.isWindows) return _readHtmlWindows();

    if (Platform.isMacOS || Platform.isLinux) {
      try {
        return await _clipboardChannel.invokeMethod<String>('readHtml');
      } catch (_) {
        // An older build of the runner has no such method.
        return null;
      }
    }
    return null;
  }

  /// Reads the `HTML Format` flavour through Win32.
  ///
  /// The same pair of libraries the write side uses, in the other direction:
  /// open the clipboard, ask for the registered format, lock the handle long
  /// enough to copy the bytes out.
  static Future<String?> _readHtmlWindows() async {
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      final kernel32 = DynamicLibrary.open('kernel32.dll');

      final openClipboard = user32.lookupFunction<
          Int32 Function(IntPtr hWndNewOwner),
          int Function(int hWndNewOwner)>('OpenClipboard');
      final closeClipboard = user32
          .lookupFunction<Int32 Function(), int Function()>('CloseClipboard');
      final getClipboardData = user32.lookupFunction<
          IntPtr Function(Uint32 uFormat),
          int Function(int uFormat)>('GetClipboardData');
      final isFormatAvailable = user32.lookupFunction<
          Int32 Function(Uint32 format),
          int Function(int format)>('IsClipboardFormatAvailable');
      final registerClipboardFormat = user32.lookupFunction<
          Uint32 Function(Pointer<Utf16> lpszFormat),
          int Function(Pointer<Utf16> lpszFormat)>('RegisterClipboardFormatW');
      final globalLock = kernel32.lookupFunction<Pointer<Uint8> Function(IntPtr),
          Pointer<Uint8> Function(int)>('GlobalLock');
      final globalUnlock = kernel32
          .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
              'GlobalUnlock');
      final globalSize = kernel32
          .lookupFunction<IntPtr Function(IntPtr), int Function(int)>(
              'GlobalSize');

      final name = 'HTML Format'.toNativeUtf16();
      final format = registerClipboardFormat(name);
      calloc.free(name);
      if (format == 0 || isFormatAvailable(format) == 0) return null;

      if (openClipboard(0) == 0) return null;
      try {
        final handle = getClipboardData(format);
        if (handle == 0) return null;
        final pointer = globalLock(handle);
        if (pointer == nullptr) return null;
        try {
          final size = globalSize(handle);
          if (size <= 0) return null;
          // `HTML Format` is UTF-8, and its own header names the byte offsets
          // of the fragment; the converter reads that header itself, so the
          // whole payload goes across as it stands.
          final bytes = pointer.asTypedList(size);
          final end = bytes.indexOf(0);
          return utf8.decode(
            end < 0 ? bytes : bytes.sublist(0, end),
            allowMalformed: true,
          );
        } finally {
          globalUnlock(handle);
        }
      } finally {
        closeClipboard();
      }
    } catch (_) {
      // Never let reading the rich flavour be the reason a paste fails.
      return null;
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
    final units = windowsPlainText(text).codeUnits;
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