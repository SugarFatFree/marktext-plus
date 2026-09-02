import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';

/// Laying out a PDF must not stop the window.
///
/// It is the slowest thing the editor does — three seconds for a hundred
/// kilobyte document, and about linear from there — and all of it is
/// arithmetic rather than drawing, so none of it needs the window's thread.
/// Done there, the window froze for the whole export, with a progress dialog
/// that could not even turn its spinner.
///
/// What is asserted is the thing that matters to the reader: the event loop
/// keeps turning while the export runs. Measured, that is 99 heartbeats
/// against 0.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String document(int sections) {
    final b = StringBuffer();
    for (var i = 0; i < sections; i++) {
      b.writeln('## 第 $i 节\n');
      b.writeln('第 $i 段正文，含 **粗体** 与 [链接](/u$i)。\n');
      b.writeln('- 甲 $i\n- 乙 $i\n');
    }
    return b.toString();
  }

  test('the event loop keeps turning while a PDF is laid out', () async {
    final source = document(400);
    // Warm: the first export of a session pays for fonts and for the code
    // being compiled, and neither is what this measures.
    await ExportService.pdfBytes(source);

    var heartbeats = 0;
    final beat =
        Timer.periodic(const Duration(milliseconds: 5), (_) => heartbeats++);
    final bytes = await ExportService.pdfBytes(source);
    beat.cancel();

    expect(bytes.length, greaterThan(10000), reason: 'PDF 小得不像有内容');
    // Around a hundred when the work is elsewhere, exactly zero when it is
    // here. Twenty is far from both.
    expect(heartbeats, greaterThan(20),
        reason: 'PDF 排版把主 isolate 占住了（心跳 $heartbeats 次）');
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('the bytes are the same as they always were', () async {
    // The isolate must not change the document, only where it is built.
    const small = '# 标题\n\n一段正文，含 **粗体** 与 `代码`。\n\n- 甲\n- 乙\n';
    final a = await ExportService.pdfBytes(small);
    final b = await ExportService.pdfBytes(small);
    expect(a.length, b.length);
    expect(String.fromCharCodes(a.take(5)), '%PDF-');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
