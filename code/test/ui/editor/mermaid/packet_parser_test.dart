import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';

/// `packet-beta` is one of the diagram types mermaid 11 draws that this app
/// did not: a document using it fell back to a plain code block.
void main() {
  PacketDiagramData parse(String code) =>
      const MermaidParser().parseWithData(code)!.packetData!;

  test('an explicit bit range becomes a field', () {
    final packet = parse('packet-beta\n'
        '0-15: "Source Port"\n'
        '16-31: "Destination Port"\n');
    expect(packet.fields.length, 2);
    expect(packet.fields[0].label, 'Source Port');
    expect(packet.fields[0].start, 0);
    expect(packet.fields[0].end, 15);
    expect(packet.fields[0].width, 16);
    expect(packet.rowCount, 1);
  });

  test('a title is read, and the widget is told not to draw it twice', () {
    final result = const MermaidParser().parseWithData(
      'packet-beta\ntitle TCP header\n0-15: "Source Port"\n',
    )!;
    expect(result.packetData!.title, 'TCP header');
    expect(result.hasOwnTitle, isTrue);
  });

  test('a single bit is a one-bit field', () {
    final packet = parse('packet-beta\n0: "Flag"\n1-7: "Rest"\n');
    expect(packet.fields[0].width, 1);
    expect(packet.fields[1].start, 1);
  });

  test('a relative width continues from the last field', () {
    final packet = parse('packet-beta\n'
        '0-15: "First"\n'
        '+16: "Second"\n'
        '+8: "Third"\n');
    expect(packet.fields[1].start, 16);
    expect(packet.fields[1].end, 31);
    expect(packet.fields[2].start, 32);
    expect(packet.fields[2].end, 39);
  });

  test('rows are counted from the last bit, not the field count', () {
    final packet = parse('packet-beta\n0-31: "One row"\n32-95: "Two more"\n');
    expect(packet.fields.length, 2);
    expect(packet.rowCount, 3);
  });

  test('a backwards range is dropped rather than drawn inside out', () {
    // Taken at face value this is a field of negative width, which the
    // painter would draw as a rectangle running the wrong way.
    final packet = parse('packet-beta\n15-0: "Typo"\n0-7: "Real"\n');
    expect(packet.fields.length, 1);
    expect(packet.fields.single.label, 'Real');
  });

  test('a zero-width relative field is dropped', () {
    // `+0` leaves the cursor where it was, so every field after it would be
    // stacked on the same bits.
    final packet = parse('packet-beta\n0-7: "A"\n+0: "Nothing"\n+8: "B"\n');
    expect(packet.fields.length, 2);
    expect(packet.fields[1].start, 8);
  });

  test('labels may be unquoted, and comments are ignored', () {
    final packet = parse('packet-beta\n%% a comment\n0-3: Version\n');
    expect(packet.fields.single.label, 'Version');
  });

  test('the suffix-less spelling is recognised too', () {
    expect(parse('packet\n0-3: "Version"\n').fields.length, 1);
  });

  test('a header with no fields does not claim to have parsed', () {
    expect(const MermaidParser().parseWithData('packet-beta\n'), isNull);
  });
}
