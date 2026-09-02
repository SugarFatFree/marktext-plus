Five things you can do that you could not before, and thirty-nine things that
were wrong. The theme of the release is long documents: opening one, moving
around in it, and trusting what the editor tells you about it.

### Added

- **Ruby annotations.** `<ruby>漢<rt>hàn</rt></ruby>` draws the reading above the
  text, as furigana and pinyin are written. HTML exports real ruby; Word and PDF,
  which have neither, print the reading after the text the way a dictionary does.
- **Pictures written as `<img>`** on a line of their own are drawn as pictures, at
  the size the tag asks for — Markdown has no way to say how big a picture should
  be, and upstream MarkText's own documentation falls back to the tag sixty times.
- **The `/` menu offers diagrams and headings.** A Mermaid diagram had no way in at
  all; the fence, the word and the first line had to be typed from memory.
- **Paste a web address over selected words** and they become a link, the way they
  do in every other editor. It used to replace the words with the address.
- **Tidy Table Source** lays a table's pipes out again without changing what it
  says. A CJK character counts as two columns, so a table of Chinese lines up in
  the source the way it does on screen.

### Long documents

The preview redraws two and a half to three times faster, and several things that
redrew it needlessly no longer do: moving the pointer over a link used to rebuild
every block of the document. Code blocks are coloured once instead of on every
frame, table cells are parsed once with the rest of the document instead of four
times over, and a document full of quotations parses about a third faster —
a deeply nested one no longer takes seconds.

Clicking a heading near the end of a long document's outline now goes there. It
used to land wherever the document had got to drawing, and stay there.

### The source pane and the preview now agree

The line numbers line up with the lines they number: the gutter assumed every line
was one row tall, which stops being true the moment a paragraph wraps — and in
Markdown a paragraph is normally one long line.

Several other places where the two panes disagreed are settled: what counts as a
heading, which emphasis will actually be drawn, a link whose text holds nested
brackets, and marking up a selection that covers more than one block.

### Files and encodings

Typing an emoji into an old GBK note no longer ruins the file. A UTF-16 file that
arrived without a byte order mark opens as UTF-16 and is saved without one. And
the status bar names the encoding the file was actually written in, rather than
the one that was asked for.

### Markdown

Conformance with the CommonMark specification goes from 388 to 486 of its 648
examples in this release — it was 353 two releases ago. The fixes people are most likely to notice:
a code block written under a list item is a code block; `<details>` sections close;
HTML comments are invisible; a link whose address is kept at the bottom of the
document draws its text like any other; and emphasis works when the paragraph
wraps between its two markers.

The full list is in
[CHANGELOG.md](https://github.com/marktext-plus/marktext-plus/blob/main/CHANGELOG.md),
and every fix is written up with its cause and its evidence in
[docs/v1.5.6/](https://github.com/marktext-plus/marktext-plus/tree/main/docs/v1.5.6).
