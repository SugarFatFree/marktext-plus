# Changelog

All notable changes to MarkText Plus will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - v1.6.1

### Changed
- Plugin settings and menu contributions are rendered by the host through the isolated plugin protocol.
- AI translation now uses selections from source or preview and shows full-document results in a non-destructive split view.
- Plugin entry, Topic discovery feedback, toolbar alignment, plugin lifecycle controls and isolated plugin actions are refined for the next release.
- AI model settings now save while typing, accept a real API key into the system secret store, and can test provider configuration; the translation plugin receives that key only in memory.

## [v1.6.0] - 2026-09-02

### Added
- In split view the two halves follow each other's scrolling, in both directions. It had no synchronisation at all: the editing pane moved and the preview stayed where it was, which is most of what a split view is for. It anchors on the headings and interpolates between them rather than matching a fraction of the way down — the two panes have nothing like the same height, since a comment is forty lines of source and no height at all on the other side
- A PDF is laid out away from the window, so exporting one no longer stops everything until it is done — three seconds for a hundred kilobyte document, longer for a large one. It is not a trade: measured on the same document it is faster there too
- An export says that it is running, and says where the file went when it is done. Choosing a filename used to be followed by a still window for as long as the export took — three seconds for a hundred kilobyte document as a PDF — and then by nothing at all, so there was no way to tell a finished export from one that had never started. Only failure spoke. The PDF layout has since moved off the window's thread as well, so the spinner turns

### Fixed
- The Edit menu's Copy and Cut commands now use the same rich clipboard path as Ctrl+C, so Word keeps headings, emphasis, lists and links there too
- Copying a full selection from the source pane now keeps both flavours: Word receives headings, emphasis and lists as formatted HTML, while Notepad receives the original Markdown with Windows-safe line endings
- Pasting from a browser keeps what the page said. A task list arrived with every box unticked, a code block arrived without the language it was written in, and everything from a web word processor arrived as plain text — Google Docs and its like mark up with styles rather than with tags, and only tags were being read. A Google Docs fragment also came out entirely in bold, because it wraps what it copies in a `<b>` that says in its own style that it is not bold
- A quotation earlier in the document no longer stops every reference link below it from working. A quote's contents, and the blocks a list item carries, are parsed by asking the parser to parse again — and it began each parse by forgetting the addresses it had collected for the document, which it does so that one document's labels cannot resolve in the next. So a single `>` near the top left `[手册][doc]` on the page as those characters, with the address below it never used
- A list whose bullets drift by a space is still one list. Depth was the rank of an item's indentation among all the indentations the document happened to use, so four bullets each indented one space further than the last drew four lists inside one another. An item is inside another only when it is indented to where that item's text begins — two columns for `- `, three for `1. `, four for `10. ` — which is what `marked` does and what the specification says
- Content indented with a tab under a list item keeps all of its text. The width of an indent is counted with a tab as four columns, and that many *characters* were then removed from the front of the line — but a tab is four columns and one character, so the reader's own writing made up the difference and was deleted. A paragraph indented with one tab under a bullet lost its first character, under a numbered step it lost two, and a fenced code block written that way was not recognised as one at all. Nothing said so, in the preview or in any export
- A link reference definition written across more than one line is read as one. Keeping addresses at the bottom of a document is what reference links are for, and wrapping a long one is ordinary — but only the single-line form was recognised, so a wrapped definition stopped being metadata: its title was lost, and its remainder, along with every definition under it, was drawn in the document as a paragraph for the reader to see. CommonMark conformance 486 → 491

## [v1.5.6] - 2026-09-01

### Added
- "Tidy Table Source" lays a table's pipes out again without changing what the table says. Every other table command already reformats it as a side effect; editing a cell's text by hand has no such side effect, so from the first typo fixed onward the columns never line up again. A CJK character counts as two columns, so a table of Chinese lines up in the source the way it does on screen
- Selecting some words and pasting a web address over them writes a link, the way it does in every other editor. It used to replace the words with the address, so they had to be typed again. A scheme is required — `www.example.com` in a sentence is prose, not a link waiting to happen — and pasting anything else, or pasting with nothing selected, is the ordinary paste it always was
- A picture written as `<img src="…" width="400">` on a line of its own is drawn as the picture it describes, at the size it asks for. Markdown has no way to say how big a picture should be, so a document that needs to say it falls back to the tag — upstream MarkText's own documentation does so sixty times, and every one of them opened here as a line of angle brackets in a grey box. A tag inside a table cell or with text beside it is still part of the HTML around it
- The `/` menu offers a Mermaid diagram and the six heading levels. A diagram had no way in at all — the fence, the word and the first line had to be typed from memory — and it is the block this editor is built around; what the menu inserts draws something straight away. The headings go at the end rather than the top, where upstream puts them: `##` is two keystrokes here, and six of them above the table and the fence would push the blocks that are actually awkward to type out of sight
- `<ruby>漢<rt>hàn</rt></ruby>` draws the reading above the text, as Japanese furigana and Chinese pinyin are written. It was escaped and shown as angle brackets, so a document annotated this way read as its own source. The preview draws it; HTML emits real ruby with the `<rp>` brackets a reader that cannot draw it needs; Word and PDF, which have neither, print the reading after the text the way a dictionary does

### Fixed
- The line numbers beside the source line up with the lines they number. The gutter was a list of equal-height rows, one per line of source, which is right only while no line wraps — and a paragraph in Markdown is normally one long line, so it wraps as a matter of course. A single wrapped paragraph put every number below it 153 pixels out of step, and there is no setting to turn the gutter off. Each number is now placed where the editor actually drew its line, and only the numbers on screen are drawn at all
- Clicking a heading near the end of a long document's outline goes there. The preview draws a long document a batch at a time and parses only its beginning at first, so a heading further down had nothing to scroll to yet — and the lookup answers with the nearest heading above rather than with nothing, so the request was taken as satisfied by whatever had been drawn so far and thrown away. The preview now draws down to the line before looking, waits for the rest of the document when the line is past what has been read, and keeps the request until it can honour it
- A long document's preview redraws two and a half to three times faster. The blocks live in a Column rather than a lazy list, so every block was rebuilt on every frame — 686 ms a redraw for a 4800-block document, and a redraw is a great many things. Each block's widget is now kept and handed back while nothing about how the document is drawn has changed; anything that could change it throws the lot away, because a stale block on screen would be worse than the time saved
- Pasting formatted content over selected text no longer leaves a piece of the raw paste behind and writes over the words after it. The editor lets the plain flavour land and then replaces it with markdown built from the HTML flavour, and it worked out which characters to replace by subtracting the two document lengths — which is the pasted length only when nothing was selected. Pasting twenty characters over five looked like fifteen
- Moving the pointer over a link no longer rebuilds the whole document. The bar along the bottom that names the link under the pointer went through the renderer's own state, so drawing it rebuilt every block: on a long document that is 279 ms of the window standing still each time the pointer crosses a link, and again when it leaves. It is now 31 ms. The tap recognizers behind links are kept between rebuilds too, rather than being thrown away and made again each time
- Colouring a code block happens once, not on every rebuild. The preview builds every block of the document each time it rebuilds — and a rebuild is a caret move, a theme change, a keystroke in the find bar — so twenty ordinary code blocks cost 28 ms of syntax highlighting each time, past the frame budget, to produce an answer that had not changed. It is now 0.12 ms, from a cache bounded at 128 KB of source so a long document cannot grow it without limit
- A table cell is parsed once, with the rest of the document. Cells were the one thing kept as source, so everyone who read them parsed them again — and the three exporters shared a parser built with the default settings, so a line break written `<br>` inside a cell appeared in the preview and not in the exported file. The preview re-parsed every cell on every rebuild, which is every caret move: 23 ms for a five hundred row table, against 5 ms to parse the whole document. It is now 0.11 ms
- An HTML comment is invisible, the way a comment is meant to be. `<!-- TODO -->` was drawn in the preview as a paragraph of escaped angle brackets and carried into the PDF and the Word file with it. An HTML export still passes it through, which is what keeps it a comment. A comment that has not been closed yet is left alone rather than hiding the rest of the page, because that is a state every comment passes through while it is typed
- A collapsible section written with `<details>` closes. The opening tags and the markdown inside them were read correctly and then `</details>` was left as a line of escaped angle brackets underneath, so the section never ended. CommonMark conformance 478 → 486, counting the comments above
- A code block written under a list item is a code block. Install steps are written this way everywhere — the step, then the fence indented under it, with no blank line between them — and the fence was being folded into the step's own sentence and read as inline markup, so what came out was a code *span* holding the language name with the code flattened onto one line. A quote written the same way lost its `>`, and a heading was not a heading. Leaving a blank line always worked, which is what made this look like a formatting preference rather than a bug. CommonMark conformance 476 → 478
- A link whose address is kept at the bottom of the document draws its text the way every other link does. Markdown has four ways to write a link and each is parsed separately; three of them knew that a link's text can hold emphasis — a download button is written `[**Download**]` — and the fourth did not, so exactly those words came out with their asterisks showing. The same shape of mistake had already been fixed once, in the branch beside it. CommonMark conformance 473 → 476
- Setting a heading level on a heading written with a little indentation changes its level, rather than leaving the old marker in the text. Markdown allows up to three columns in front of a `#`, and the preview drew such a line as the heading it is — but the heading actions carried a narrower rule of their own, read the line as a paragraph, and put a second marker in front of it, so `   ## Title` became an H3 whose text was `## Title`. Asking for a paragraph left the line untouched, and the toolbar showed no level at all
- The status bar names the encoding a document was actually saved in. When a note holds a character its encoding cannot carry, the file is written as UTF-8 — and the editor went on calling it GBK until the document was closed and opened again, which is the editor saying something about the file that is not so
- Typing an emoji into an old GBK note and saving no longer ruins the file. What GBK cannot hold was meant to be written as UTF-8 instead, keeping the character — but that relied on the encoder refusing, and it does not refuse: it returns bytes GBK itself cannot read. The file was written, and the next time it was opened the whole document came back as nonsense. Whether the encoding can hold the text is now decided by reading the bytes back, and a note GBK can hold is still saved as GBK
- A UTF-16 file that arrived without a byte order mark is saved without one. Reading those was added a moment ago; writing them back put a mark on the front, so opening a file and saving it changed two bytes nobody asked to change. Files with a mark keep theirs, and the status bar now says which of the two a document is
- A UTF-16 file written without a byte order mark opens as what it is. Notepad writes the mark and plenty of tools do not, and without it the file was read as Latin-1: every Chinese character arrived as two pieces of nonsense, and saving from that state would have made it permanent. A text encoding has no zero bytes and UTF-16 is full of them, always on the same side of each pair, so there is something to recognise it by
- A document full of quotations parses about a third faster, and a deeply nested one no longer takes seconds. Every quote parsed its own text a second time, though that text belongs to the blocks inside it and every reader of a document walks into those; nested, each level parsed everything below it again. A single line quoted two thousand deep took 2.6 seconds and now takes 0.28
- The metadata block at the top of a document, notes left in HTML comments, and the line that says where a reference label points are no longer counted as words. A title, an author and a few tags added fourteen words to a document that has five, and a comment is written for whoever is editing rather than whoever is reading. A `---` that never closes is not a metadata block, so one line cannot swallow a document's word count
- A link's destination is no longer counted as words. `见[链接](https://example.com/very/long/path)这里` reads as five characters and was counted as eleven words, so a document with references in it reported a length its prose does not have — and the word count is the number a writer works to. What is displayed is counted: the label of a link, the alt text of an image, and an autolink, which is displayed as itself. The character count still measures the document
- Pressing Enter at the end of a line beginning with a long number no longer numbers it. `13800138000. 联系人` — a phone number, an order reference — was continued as `13800138001. `, as though it were the first step of a list. The parser stopped reading those as lists a few fixes ago; the Enter key had not been told
- A link whose text holds two levels of brackets is coloured as a link in the source pane, as the preview already drew it. One pattern had been widened and the one beside it had not
- The source pane agrees with the preview about what a heading is. `#标签` — a tag in a note — was coloured as a heading the preview would not draw, seven hashes were taken for a heading when six is the most there is, and a heading written with the three columns of indentation the format allows was not coloured at all. The tint asks the parser now, as it already does for emphasis
- The pane being typed in no longer colours emphasis the pane beside it will not draw. `**加粗。**后面` was tinted bold in the source and shown as asterisks in the preview, so the editor contradicted itself with no way to tell which half was right. The tint asks the parser's own flanking rule now instead of guessing from a pattern — and keeps following this parser where it is deliberately more forgiving than GitHub, since what matters is agreeing with the pane beside it
- A diagram that will not draw says something useful about why. `grahp TD` — `graph` misspelled — was reported as "unrecognised diagram type: grahp td", quoting the direction back as though it were part of the mistake; a block holding only front matter was reported as "unrecognised diagram type: """, a quotation with nothing in it. The word to correct is quoted now, and a block that names no type at all is called empty
- A quotation carried on without repeating the `>` stays in the quote. Writing the marker on the first line and letting the rest of the sentence follow is how anyone quotes more than a line, and the remainder used to fall out and stand beside the box — half the quotation inside it, half outside. A blank line, a heading, a list, a fence or an empty `>` line still ends it
- A file name with a space in it exports as a valid address. `[文档](</我的 文件.md>)` — the angle brackets exist for exactly this — put a bare space inside the `href`, which the attribute does not allow. Only the spaces are encoded, so an address already carrying `%20` is left alone, and the address kept in the document is untouched, since the preview opens the file it names
- A link text may hold two levels of brackets: `[见 [附录 [A]]](/url)` is a link. One level already worked and the second turned the whole thing back into characters
- Bolding a selection that covers more than one block marks each block instead of wrapping the lot. Dragging across two paragraphs and pressing Ctrl+B put the markers around the blank line between them, which is not emphasis anywhere; across a list it put them around the bullets; across a heading it put two asterisks in front of the `#` and the line stopped being a heading. Each paragraph, item, step and quoted line is marked on its own now, and two lines of one paragraph still take a single pair
- Striking through a Chinese sentence writes markup that works elsewhere too. `~~文字。~~后面` renders here but not in marked or on GitHub, which judge strikethrough by the same rule as emphasis — so the punctuation is moved outside the markers, as it already was for bold and italic. The parser stays forgiving about what it reads: a document should not stop rendering because it was opened here
- Bolding a Chinese sentence works. Selecting one and pressing Ctrl+B put the markers around its final `。`, and `**这样。**后面` is not bold — not here, not in marked, not on GitHub, because a marker between a full stop and a letter can neither open nor close. The punctuation is moved outside the markers now, where it reads the same and the emphasis holds. A Chinese sentence ends in punctuation far more often than an English one, so this was a daily occurrence
- A blank line inside `<pre>`, `<script>`, `<style>` or `<textarea>` belongs to what they hold. An HTML block ends at the first blank line — which is what lets the markdown inside a `<details>` be read as markdown — but these four hold text, not markdown, and ending there cut a preformatted sample or an embedded script in half: the asterisks in it became italics and the closing tag arrived as `&lt;/pre&gt;`
- Emphasis whose markers run together is read correctly: `*outer **inner***` is an italic holding a bold, `***bold** rest*` is the same two the other way round, `_foo _bar_ baz_` nests, and `foo***bar***baz` is no longer inside out. What emphasis means cannot be decided where it starts — it depends on every run of markers in the paragraph — so the pattern that used to guess has been replaced by the algorithm the format describes. Checked case by case against marked, the parser upstream MarkText itself uses. A paragraph of ordinary prose parses in the same time as before
- A code sample indented under a list item stays code. Removing the item's indentation removed whatever the lines happened to share, which took away the four columns that make code code — so the sample came out as an ordinary paragraph, its alignment and its monospace gone. Only the item's own indentation comes off now
- A line beginning with a long number is a line, not a list. `13800138000. 联系人` — a phone number, an order reference — became an ordered list numbered from thirteen billion. The format allows nine digits at most
- An address in angle brackets works whatever its scheme: `<tel:…>` to dial a number, `<file:///…>` to point at a file on disk, `<vscode://…>`, an intranet `<localhost:5001/…>`. Four schemes were listed by name and every other one was shown as angle brackets. An uppercase `<MAILTO:…>` matched none of the four, fell through to the address branch and was given a second `mailto:` in front of it, which linked nowhere
- Emphasis works when the paragraph wraps between its two markers. `*emphasis across\na line*` was shown as asterisks, so the same sentence emphasised or did not depending on where the line happened to break — which is the part that made no sense. A blank line, a list item and a code span still stop it, because each is parsed on its own
- A link reference definition shown inside a code fence stays an example. Definitions are gathered in a pass over the whole document, made before anything is parsed because a reference may be written above its definition — and that pass could not see a code fence, so a document explaining markdown defined every label it demonstrated, and the prose afterwards quietly grew links nobody wrote. A label defined twice now resolves to the first definition, as the format says, rather than letting the mistake win
- A reference link's text can be marked up, as an inline link's already could: `[**Download**][dl]` was an anchor reading `**Download**` with the asterisks showing. There are two link branches in the parser and only one of them had been taught to read its text
- An image describes itself in words. `![a **important** picture](/img.png)` carried the asterisks into the alt attribute — and alt text earns its keep exactly when the picture does not appear, which is no place for markdown. A link inside alt text becomes its label

## [v1.5.5] - 2026-08-31

### Fixed
- A checkbox below an empty list item can be ticked again. An empty marker had just become an item of the list, but the preview still found an item's line by asking which lines *open* an item — and an empty marker does not open one, so the count fell short and the tick did nothing at all: no change, no error, no sign the click had been seen
- A bullet written over two lines stays one bullet. Letting a long item wrap in the source, with no indentation on the second line, ended the list and left the rest of the sentence as a paragraph underneath it
- An empty item no longer breaks a list in two. Pressing Enter in the middle of a list, or clearing an item's text, left a marker with nothing after it, and the list came apart into two lists with a line reading `-` between them — visible while typing, in the pane beside the one being typed in. A marker on its own in prose is still not a list
- Copying a selection that covers emphasis holding a link keeps its formatting when pasted into Word. A selection is matched against the text the preview draws, and that text had just changed — `**bold [link](/url)**` now reads "bold link" on screen — while the matching still used the source, so nothing matched and the copy quietly fell back to plain text
- A link written inside another link's text no longer produces an anchor inside an anchor, which is not valid HTML and which a browser takes apart on its own terms. The inner destination is dropped and its text kept, the way the format says: a link may not contain a link at any depth
- A link whose text is marked up shows the formatting, not the markers. `[**Download**](/url)` — how a README writes a button — was a link reading `**Download**` with the asterisks in it. The link keeps its click and its hover hint: a gesture on a span does not reach that span's children, so the target is put on each piece of the text rather than around it, and the same care is taken in Word, where a run cannot hold another run, and in PDF, where the children would otherwise be drawn in the surrounding style with nothing to show a link is there
- Emphasis containing markup of its own now renders it. `**bold with a [link](/url)**` was a bold run showing the square brackets, with nothing to click; `*italic with **bold** in it*` showed the asterisks. The span model was flat — a bold span could not hold a link span — so the loss was the same in the preview, in HTML, in Word and in PDF, all four being handed the same list. Ordinary emphasis takes the same path it always did, and is not parsed a second time: a document whose emphasis holds no markup parses in the time it did before
- `* * *` and `- - -` draw a horizontal rule. They are the commonest way of writing one by hand, and both came out as a bullet list holding `* *` — the rule pattern demanded the marks be written with nothing between them, while the list pattern was happy to match. A rule may also be indented up to three columns now, as every other block already could, and one written in the middle of a list ends the list instead of being collected as another item
- A title written over two lines and underlined with `---` or `===` is one heading, not a paragraph with a rule drawn under it. The underline closes the whole paragraph above it; only the line touching it was taken, and `===` was not even recognised as an underline there — it was read as more of the sentence. The outline was built from the same rule and had fallen behind in the same way: a wrapped title showed only its last line, and clicking it scrolled to the end of the heading instead of its start. An indented code block followed by `---` is also left alone now, where it used to be swallowed into a heading
- A Gantt task whose name contains a colon — `阶段一: 设计` — keeps all of it, and keeps the id other tasks depend on by name. The line was split at its first colon, which took half the name away and made the id something no `after` clause could match. The separator is now found by what follows it, so a time in the date format does not confuse it either
- A flowchart node whose label contains an arrow — `A["流程 --> 结束"]`, which is an ordinary way to describe a flow — no longer disappears from the diagram. Arrows were searched for across the whole line without regard for labels, so the line was split inside one and the node was lost along with its edges
- Quitting while a folder is still being read, or while a batch of files is still being opened, no longer raises an unhandled error. Both wrote their result without checking the application was still there to receive it
- An export that fails no longer destroys the file it was replacing. Writing truncates a file the instant it opens it, so exporting over an earlier export — which the picker invites — left nothing at all if the write did not finish. Saving a document has written through a scratch file and a rename for a long time; the exports and the diagram PNG now do too
- Saving twice in quick succession no longer reports the second one as a conflict. The stamp recording what the file looks like was refreshed by an unawaited call after the write, so for as long as that took the tab held a stamp older than the application's own write — and a save landing in that window was told the file had changed underneath it, when the only thing that had changed it was this editor
- Answering "save" to the prompt that appears when a tab is closed no longer writes over a change made on disk. Ctrl+S on the same document was stopped and asked; this path was not, and it is the one taken when quitting with unsaved work. The tab now stays open and stays modified, because closing it would discard the reader's edits in favour of a version they were never shown
- A document opened by double-clicking it, or from the command line, is protected against being saved over somebody else's change like any other. That path builds its tab straight from the read and was the one place missed when the disk stamp was introduced, so the check simply never fired for it — while the tab looked exactly like any other

## [v1.5.4] - 2026-08-30

### Added
- The documents that were open when the application closed are opened again when it starts. Tabs came only from the command line or from something the reader did, so closing with five documents open and reopening gave an empty window. The tabs appear at once and their contents arrive after the first frame, so startup is not spent reading files; a document opened by double-clicking it still takes precedence over the session
- Deleting from the sidebar moves the file or folder to the desktop's trash on Linux and macOS, as upstream MarkText does, so a note removed by mistake can be put back. It was removed outright, and a folder took everything under it with no way back at all. Windows still deletes outright — and its confirmation says so: the four cases (file or folder, recoverable or not) now ask four different questions instead of one that covered them all

### Fixed
- The window no longer reopens on a monitor that is no longer attached. Its place was written down at close and put back without checking, so closing on a second screen and unplugging it left the application running, focused, and nowhere on screen — with nothing to drag back and no way out but editing the configuration by hand. A window that is still reachable is left exactly where it was, including one deliberately pushed part way off the side
- Opening a file that cannot be read now says so, from the File menu and from Open Recent, as the sidebar's own open has always done. A file that stopped being readable between being picked and being read left no tab and no message. The Help menu's links report a failure too, instead of doing nothing on a machine with no browser configured
- An export or a print that fails says so. All four — HTML, PDF, Word and Print — call something that throws on an unwritable path or a folder where a file was expected, and none of them caught it; being `async void` handlers, the throw escaped with nothing to catch it, so choosing a filename and pressing Export did nothing at all. The save paths have reported their failures for a long time; these had not
- Chinese, Japanese and Korean text in a diagram is given the room it needs everywhere, not only in a node's box: an edge label, a sequence message, a Gantt task name and a pie chart legend were each measured by character count times a fixed ratio between 0.5 and 0.7, against a real width near 1.0. A Chinese sequence message ran across the lifeline beside it, and a Gantt task name across its own bar
- An edge label no longer hangs outside the diagram's own bounds. The canvas was measured from the nodes alone, so on a single chain — where the label is the widest thing in the picture — it was cut off by whatever the diagram is drawn inside
- A Japanese, Korean or fullwidth label in a mermaid node stays inside its box. The box was measured with a test for the basic Han block alone, so kana, Hangul, fullwidth punctuation and the CJK extension blocks were all counted at a little over half their real width — and labels are painted at their natural width, so they hung out over the border. Short labels were rescued by the padding, which is why this showed on a sentence and not on a word
- Giving a command a shortcut another command already has no longer leaves one of them silently dead. The lookup took whichever came first, so the other never fired, with the settings screen showing both as bound and nothing saying which had lost. The dialog now names the command holding those keys before the button is pressed, and the button says "Take it over" — which is what it does, leaving that command with no shortcut rather than sharing
- Korean documents report the word count they actually have. Hangul was counted a word per character, which is right for Chinese and Japanese because they are written without spaces between words — Korean is written with them, so a document read about three times its real length
- Dropping an image into the editor no longer inserts it and reports it as unopened at the same time. `desktop_drop` broadcasts each drop to every target and lets each decide by its own bounds, so a drop on the text area reaches both the editor, which writes the link, and the window, which counted the same file as refused. With no document open there is no text area for an image to land in, and that case is still reported
- A document rewritten on disk while it is open is no longer silently overwritten. Auto-save is on by default with a five second delay, so this needed nothing deliberate: edit a file, have a git checkout or a sync client rewrite it, and a few seconds later the editor wrote over that change without a word. Saving now compares the file against what it looked like when it was read; auto-save stops for that file and says so in the status bar, and Ctrl+S asks whether to overwrite, reload, or decide later

## [v1.5.3] - 2026-08-30

### Fixed
- About shows the version that was built. v1.5.2 shipped saying 1.5.1, so the update check — which compares against that same constant — told everyone on it that an update was waiting, the very thing issue #1 reported. A test has guarded the two version numbers since that issue, but it runs with the test suite on a push while releases run from a tag, so nothing on the release path ever looked. The release workflow now checks the tag, `pubspec.yaml` and `AppConstants` against each other before it builds anything
- Formatting commands work while a block is open for editing in the preview. Ctrl+B there did nothing — the command was recorded for a source pane to carry out and there is no source pane in preview mode — and it stayed recorded, to go off later at whatever caret a source pane next had. In split view only the pane being typed in acts on the command

## [v1.5.2] - 2026-08-30

### Added
- Editing in the preview carries on from block to block: down from the last line of a block opens the one below, up from the first line opens the one above, and down from the last block opens the blank space under the document. Editing one block then reaching for the mouse to start the next is not how anyone writes. Inside a block of several lines the arrows still move the caret
- Selecting text in the editor floats a small toolbar beside that line — bold, italic, strikethrough, inline code, highlight and link — as upstream MarkText does. It is placed by laying out the line's prefix in the editor's own font, so it lands beside the selection whatever the text is, and it follows the text when the editor scrolls. Only for a selection within one line: a strip over a whole block would cover the text it is about
- Move a block up or down with `Alt+↑` / `Alt+↓`, trading places with the block before or after it — upstream MarkText reorders paragraphs by dragging one over another. Boundaries come from the parser, so a fenced code block moves whole rather than being split at the blank line inside it, and the blank line between two blocks stays between them. With a selection, the lines it touches move instead
- Table editing: insert a row above or below, delete a row, insert a column left or right, delete a column, and set a column's alignment. Under Format ▸ Insert ▸ Edit Table, greyed out where a command does not apply — outside a table, on the header row for Delete Row, and on a single-column table for Delete Column. Any edit re-aligns the whole table, measuring CJK characters at the two columns they occupy

### Fixed
- An image written with a path relative to the document — `![](./img/x.png)`, which is how images are ordinarily written — now appears in the preview. The path went straight to `File()`, which resolves against the directory the application was started from, so the picture was never found. Exporting resolved these correctly all along, and so did following a relative link, which is why a document could export with its images and show none of them
- Pressing up in the document's first block while editing in the preview no longer closes the editor. It committed before looking for somewhere to go, and there was nowhere

## [v1.5.1] - 2026-08-29

### Added
- A link in the preview shows a hand cursor, and hovering it names where it goes and that Ctrl/Cmd opens it. It opened only with the modifier held and said neither thing
- Pasting from a browser keeps its structure: headings, lists, tables, links and emphasis are converted to markdown instead of arriving as flattened text. `Ctrl+Shift+V` pastes the plain flavour, as before
- A language picker for code fences: type ```` ``` ```` and choose from the languages that can be highlighted, found by abbreviation as well as by name — `ts` finds `typescript`
- A quick-insert menu: type `/` at the start of an empty line to insert a list, a task list, a table, a code block, a quote, a math block, a rule or front matter. Searchable in Chinese as well as English, and the `/` is taken back out when an entry is chosen
- Enter inside a blockquote carries the quote on to the next line, and Enter on an empty quote line ends it — the two steps upstream MarkText specifies. Only lists did this before, so `> ` had to be retyped on every line
- Rich copy works on macOS and Linux, not only Windows: copying from the preview and pasting into a word processor keeps headings and bold there too
- Ctrl (or Cmd) and the mouse wheel change the text size, in both the source and the preview (#4)
- Room under the last line, so it can be scrolled up to where the eye is instead of sitting on the bottom edge (#2)
- Mermaid `treemap-beta` diagrams render: nested rectangles whose area stands for their value, laid out by the squarified algorithm so the boxes stay comparable by eye. The grammar was read out of mermaid 11.16's own definition — indentation length nests a row, and a value may carry thousands separators
- File ▸ Move To…, the one menu command upstream MarkText has that this one did not

### Fixed
- A footnote's body is markdown. A link, emphasis or code inside `[^a]: see [the paper](https://…)` reached the reader as those characters, in the preview and in every export — and a footnote is where a citation goes, so a link in one is the ordinary case
- A footnote definition can run over more than one line. An indented continuation broke out of the note and became a paragraph of the document
- A footnote whose identifier contains a space, `[^my note]`, produces an anchor that works. A space is not valid in an HTML id, so the reference pointed nowhere
- The preview writes a footnote definition as `[^a]:`, not `[a]:` — without the caret it is a link reference definition, a different construct that looks similar
- Typing a closing bracket over the one auto-pairing just inserted steps past it instead of adding a second. Finishing `(x` by typing `)` left `(x))`, because only symmetric characters like `"` were stepped over and `)` was not
- Auto-pairing no longer fires when the caret is right against a word. Typing `(` in front of `foo` gave `()foo`, and a quote gave `""foo`, so the spurious closing character had to be deleted straight away. As upstream does, a pair is inserted only at the end of a line, before whitespace, or before a closing bracket — wrapping a selection is unaffected
- A link whose address is `javascript:`, `vbscript:` or `data:text/html` no longer keeps that address when the document is exported to HTML. The export is a file other people open in a browser, and such a link runs code on whoever clicks it. The same check now covers an image's source and a badge's outer link; ordinary addresses, including inline `data:image/png` diagrams, are untouched
- Clicking a `mailto:` or `tel:` link in the preview does something. Neither is an http address, so both used to fall through to the open-a-neighbouring-file branch, find no such file, and silently do nothing
- An input method's candidate strings are no longer treated as typing. Undo after composing 你好 could hand back `hao,` — a string that only ever existed in the candidate window — and the insert menu could open over it. Nothing is recorded or triggered until the composition is committed
- Undo takes back a word, not everything typed since the last pause. Snapshots were driven by a 300 ms debounce alone, so a paragraph written without pausing was a single undo step and one press took all of it away. Chinese punctuation ends a step too, since a Chinese sentence has no spaces to end one
- A heading indented by one to three spaces is a heading, and `#` on its own — the state a heading passes through while it is being typed — no longer shows as a paragraph with a hash in it
- A diagram inside a quote or a list item answers its toolbar buttons at once. The exemption that keeps the double-tap recogniser away from blocks with controls of their own was written for a diagram at the top level only, so a nested one had all four of its buttons dead for the length of the double-tap timeout
- A checkbox in a task list inside a blockquote answers the first click. Two things stopped it: the line it had to rewrite was never found, because the quoted line still carries its `>` marker, and the whole quote sat behind the double-tap recogniser that top-level task lists are already exempt from
- A table written directly under a line of text, with no blank line between them, is drawn as a table. It used to be swallowed into the paragraph and disappear
- `[the docs]` with its definition at the bottom of the file is a link. Only the two-bracket reference forms were read, so the shortcut form — the ordinary way to use reference links — came out as literal text. Brackets with no definition behind them stay as prose
- A paragraph no longer keeps the spaces its lines were indented by. HTML collapses them so exports looked right, but the preview draws the text as written and a paragraph under a list item came out visibly shifted
- `[TODO]()` — a link with an empty destination — is a link rather than literal text
- Writing the next list with a different bullet character starts a second list, as it should, instead of running the two together
- `2 ** 3 ** 4` and `** note **` are left exactly as written. The rule that a delimiter with a space just inside it does not emphasise was applied to `*` alone; teaching it to `**` and friends then let the single-`*` branch pick up what they refused, so a delimiter that is part of a longer run is now left to that run
- An underscore inside a word no longer emphasises Chinese, Japanese or Cyrillic text. The word-boundary check recognised Latin letters only, so `中文_强调_文字` came out emphasised where `snake_case_name` correctly did not
- A code span written across two lines — a long command wrapped in the source — is read as code instead of leaving its backticks in the text
- `cherry-pick` in a gitGraph adds the commit it names instead of being skipped in silence, and is drawn the way mermaid draws it
- An ER relationship written in words — `PERSON one to zero or more ADDRESS` — is read. Only the symbolic form was, and a diagram written the other way did not lose one relationship: it failed to parse at all and fell back to a code block
- Class diagram relations are read the way mermaid's grammar defines them — any relation type at either end of either line — instead of being matched against a hand-written list of sixteen spellings. Thirty-nine legal combinations were missing from it, including `..o`, every two-ended form such as `o--o`, and the lollipop `()` entirely; each still matched the bare `--` at the end of the list, so the line was drawn with its meaning silently gone
- Copying from the preview and pasting into Word keeps headings, bold and links. The HTML was produced by re-parsing the copied text as markdown, but a selection in the preview returns the *rendered* text — a heading arrives as `My Heading` with no `#` — so the formatting was gone before the conversion started. It is now built from the blocks the preview drew
- A bidirectional sequence message `A<<->>B` draws two participants and a head at each end. The sender pattern did not exclude `<`, so it swallowed the `<<` and gave the diagram a third lifeline named `A<<` — silently, since what remained still parsed as an ordinary message
- Asking for a list or a quote marks every line the selection touches, not just the one under the caret (#3)
- About shows the version that was actually built, and the update check compares against it. The constant had drifted to 1.3.0 while the app shipped 1.5.0, so anyone on a current build was told forever that an update was waiting (#1)
- The preview honours the font size and line height that were chosen. Both were compile-time constants there, which is why zooming did nothing to it (#4)
- A flowchart node written `A(((Double)))` is drawn as a double circle labelled `Double`. The greedy double-circle pattern matched it too and drew a plain circle whose label included the inner parentheses — the shape existed in the model and the painter all along, and nothing ever produced it
- The invisible link `A ~~~ B` is read. It was dropped whole, and with it the layout constraint it exists for, so the diagram came out arranged differently from the one that was written
- A fence tagged `packet-beta`, `architecture-beta`, `stateDiagram-v2` or `xychart-beta` is drawn as a diagram. All four are types the app implements, and all four were missing from the list it derives fence handling from — and shows the reader when a diagram fails to parse, so it was disowning types it supports
- With the find bar open, a large document is rescanned when typing stops rather than on every keystroke (40–66 ms each on a five megabyte file), and a search matching tens of thousands of places paints a window of them around the one being read instead of all of them — painting 97 000 highlights took 133 ms per rebuild, and a caret move is a rebuild. The match count itself is untouched
- Moving the caret in a large document is no longer felt. The line and column readout copied everything before the caret and split it into one string per line — 61 ms per keypress on a five megabyte file — while the gutter counted newlines across the whole document again in `build`. A line-start index built once per edit answers both in under a microsecond
- A large document no longer freezes the window for seconds at a time when typing pauses. Parsing five megabytes takes about 3.5 s and ran on the UI isolate; it now runs on another one, of which only the ~140 ms of handing the blocks back is felt here
- The table of contents no longer reads the whole document's outline during build — 402 ms per keystroke on a five megabyte file, whether or not the panel was even open
- The preview takes heading positions from the blocks it parsed instead of scanning the text a second time. That second reading was a second definition of what counts as a heading, and it had already disagreed with the first twice
- Customised keyboard shortcuts survive a crash. The file was written in place, so a process killed mid-write left it truncated; a truncated file failed to parse and was silently replaced by the defaults, and the next save overwrote the only copy. It is now written and quarantined the way the settings file already was
- The sidebar tree shows folders and markdown documents, as upstream MarkText does, rather than everything a directory holds. Tapping a `.png` or a `.pdf` opened it as a text tab full of mojibake — one stray keystroke away from an auto-save writing that back over the original
- The tree and the folder search now skip the same directories; the search stepped over `node_modules` while the tree listed all of it
- Renaming from the File menu no longer destroys a file that already has the name. The service grew a guard against that and the sidebar adopted it; the menu kept its own `File.rename` call and so kept the bug
- The macOS download is named for what it is. The published app has always carried both x86_64 and arm64, but it was called `macos-arm64`, and the release listed two `macos-x64` files that no job ever built — the release action skips a file it cannot find and still reports success

## [v1.5.0] - 2026-08-29

### Added
- The preview takes new writing, not only edits to what is already there: the space under the last block starts a paragraph at the end of the document. An empty document rendered nothing at all, so there was no target to tap and not one character could be typed into it
- The five markdown extensions upstream MarkText accepts and this editor did not: `mkd`, `mkdn`, `mdwn`, `mdx`, `text`
- Mermaid `architecture-beta` diagrams render: icon-bearing service boxes, dashed group frames, and orthogonal connections. The arrangement is derived from the edges the way mermaid derives it — `db:L -- R:server` puts the server to the *left* of the db, not wherever source order would have put it
- Mermaid `packet-beta` diagrams render: rows of bit cells with the fields laid over them, explicit ranges (`0-15:`), single bits, and mermaid 11.5's relative widths (`+16:`). A field that straddles a row is drawn one box per row, the way mermaid draws it

### Fixed
- macOS registers as a handler for markdown documents, and opens the one that was double-clicked. It had neither half: no `CFBundleDocumentTypes` in the bundle, and nothing listening for the Apple event Finder sends instead of `argv`
- The Windows installer people actually download registers every type the app opens. It offered three of seven; the test that checks this was reading the CI workflow rather than the release one
- The Linux mime definition matches what the app opens — it both missed types the app accepts and claimed types the app then dropped, which opened the app on an empty window
- Editing a block that sits inside a quote or under a list item in the preview no longer writes the edit over the top of the document — nested blocks were numbered from line zero, so their reported source was the document's first lines
- Folder search no longer reads oversized files into memory whole; files over 2 MiB are skipped and the count of skipped files is shown rather than silently dropped
- Dropping a `.mmd`, `.mdown`, `.mdtxt` or `.mdtext` file on the window opens it — drag and drop kept a private list holding three of the seven extensions the rest of the program accepts
- Dropping an unsupported file now says so instead of the window silently swallowing the gesture

## [v1.4.0] - 2026-08-28

### Added
- Sequence diagrams honour `box … end` participant groupings and `autonumber`
- Mermaid `block-beta` diagrams render: a wrapping grid of shaped blocks with arrows between them
- Mermaid C4 diagrams render (`C4Context` and its four siblings), completing every diagram type the upstream editor draws
- State diagrams read described states, choice nodes, composite states, `direction`, and the concurrency separator, instead of dropping every line that is not a transition
- A Gantt chart written without any `section` line draws instead of coming out blank, several status keywords on one task are all read, and a task named in a non-Latin script keeps a usable id
- A timeline period written with several colon-separated events draws one box each, as mermaid does
- A kanban task written with an `@{ … }` metadata block appears on the board instead of vanishing
- Searching the preview for a repeating pattern no longer draws more characters than the document holds, and the preview and the find bar agree on the match count
- The word count keeps an apostrophe or a hyphen inside the word, so `don't` and `well-known` count as one each
- A file that is not UTF-8 opens instead of the tab vanishing, and its encoding — including a UTF-8 byte order mark — is written back on save
- The status bar shows the file's actual encoding, where it used to print the word "UTF-8" whatever the file was
- Clicking the line ending in the status bar switches the document between LF and CRLF
- A list written with blank lines between its items is drawn and exported with the spacing that asks for
- A numbered list followed by a bulleted one is two lists again, so the bullets no longer export inside an `<ol>` and render as numbers
- The "enable HTML" setting does something: inline tags such as `<kbd>`, `<u>` and `<br>` are rendered, in the preview and in every export
- Blockquote lines and single-line HTML comments are coloured in the source editor, using the theme colours that were already defined for them
- Twelve strings that ten of the twelve languages were missing — the file-opening preference among them — are translated instead of falling back to English
- The Save As and Export file dialogs are titled in the app's language
- Email addresses are linked, both `<foo@example.com>` and bare ones in prose
- An open document reloads when the file changes on disk, as long as it has no unsaved edits
- "Save as" rebinds the tab to the file it wrote, so the title updates and the next save no longer asks again
- A failed write leaves the document marked as modified instead of claiming it was saved
- Link and image text may contain a bracketed run, as in `[see [1] here](url)`
- Front matter written as TOML (`+++`) or JSON (`;;;`, `{ … }`) is recognised, not just YAML — a Hugo file no longer shows its metadata as a paragraph of plus signs
- A mermaid timeline groups its periods under `section` bands, drawn above the period titles and coloured per band
- A diagram can be edited from the preview: its toolbar has an "Edit Source" button, since its own double tap opens fullscreen
- The editor's body font can be chosen in Settings; the setting was read all along but had no row of its own
- Paragraph ▸ Loose List Item spaces a list's items apart, or runs them together again — the last entry the upstream paragraph menu had and this one did not
- Edit ▸ Create Paragraph Below and Delete Paragraph, anchored on the outermost block as upstream anchors them
- File ▸ Print, on Ctrl+P, opening the system print dialog with the document laid out by the same code the PDF export uses; the palette moves to Ctrl+Shift+P, which is where upstream and VS Code both put it
- A list item can carry blocks of its own — a code fence beneath a numbered step, a second paragraph, a quote, a table — instead of the list breaking in three around them and the fence landing at the document's left margin
- Pressing Enter in a list carries the list on: the same bullet, the next number, the indentation and spacing that were written, and an unticked box for a task. An item with nothing in it ends the list instead
- The size code is drawn at can be set, independently of the body text; raising the reading size used to enlarge the prose and leave code at a fixed 14
- Edit ▸ Find in Files, which searches every file in the open folder. The search itself was there all along, reachable only by finding the magnifying glass in the sidebar, and the label was already translated into all twelve languages
- A mermaid diagram can be titled with `---\ntitle: …\n---`, which is how mermaid documents it for every type and the only way a flowchart can be titled at all
- A fenced code block is drawn with a gutter of line numbers, as upstream draws one, and can be turned off in Settings. A line that wraps keeps its number level with it, and when the block scrolls sideways the numbers stay put
- A document written in GBK — which is what Chinese notes were written in before UTF-8 — opens as what it says instead of as two wrong characters for every real one, and is written back in the encoding it came in
- The encoding in the status bar can be clicked to read the file again as something else. Detection is a guess, and until now a document that opened as mojibake was a dead end

### Fixed
- Clicking a folder-search result now scrolls to the line that matched, instead of opening the file at the top
- Disposing a source editor no longer throws, so it hands its controller registration back as it was always meant to
- A line starting with an inline HTML tag, such as `<kbd>Ctrl</kbd>`, is a paragraph again instead of a grey code box
- An HTML block ends at the first blank line, so a distant closing tag no longer swallows the headings and prose in between — and markdown inside a `<details>` renders as markdown
- An ordered list written from `3.` is numbered from three, in the preview and in all three export formats
- A fenced code block indented under a list item no longer carries that indentation into every line of the snippet
- A footnote definition whose text has no spaces — `[^1]: 中文脚注`, `[^1]: https://…` — is no longer swallowed by the link-definition rule and dropped from the document
- A document that opens with a thematic break is no longer read as front matter reaching to the next `---`, which hid everything in between
- A kanban board indented with four spaces or with tabs draws instead of failing to render at all
- A pie chart written `pie title …`, the spelling mermaid's own documentation uses, keeps its title
- A timeline `section` line is no longer drawn as text inside whichever event came before it
- A Gantt task written `until <id>` gets a real length instead of a zero-width bar, and `after a1 a2` resolves against both tasks rather than neither
- A settings write that cannot reach the disk no longer surfaces as an unhandled error far from anything the user did
- A link in the preview that cannot be opened — a typo'd address, no handler registered for the scheme — says so instead of failing silently
- Markdown inside a fenced code block is no longer coloured as markdown in the source editor: `**bold**`, `[a](b)`, `# comment` and `> arrow` in a snippet stay code
- A very long single line — minified JSON, a CSV row, a pasted block — no longer freezes the source editor for tens of seconds; the worst case measured went from 45 seconds to 10 milliseconds
- The same kind of line no longer freezes the preview either: parsing 60,000 unmatched brackets went from 51 seconds to 55 milliseconds
- A long line inside a `pie` or `erDiagram` block no longer freezes the preview for fourteen and twenty-seven seconds respectively
- A whole-word search over a large document is twenty times faster
- Moving the caret no longer rebuilds the whole preview: in split view every arrow key used to rebuild every block that had been rendered
- Typing no longer rebuilds the whole file tree in the sidebar
- Dismissing the update badge remembers the version, instead of showing it again on the next launch
- Renaming or deleting a file from the sidebar takes its open tab with it — renaming used to leave the tab on the old path, where the next save wrote the old file back out; a folder does it to every file beneath it
- Saving a new document from the close prompt names the tab after the file it wrote and adds it to the recent files, as Save As from the menu already did
- Closing a file from the sidebar asks about unsaved work, as closing its tab already did — the cross on the row, the context menu, closing a file or a whole folder all used to discard it silently
- Save from the command palette offers Save As for a document that has no file yet, instead of doing nothing; New File from the palette names the tab in the app's language
- Quitting from the File menu asks about unsaved work and records the window's geometry, as closing from the title bar already did; it used to end the process outright
- Closing the window no longer leaves the process lingering: the directory watches are stopped before it goes
- Replace-all with a regular expression writes only the matches it counted and highlighted; a pattern that can match nothing — `x*`, `.*` — used to rewrite the document at every position
- Opening a document no longer starts an isolate to read it unless it is over half a megabyte; the first one in a process has to load the app snapshot, and that was happening while the user waited for their file
- The buttons on a diagram's toolbar answer immediately, where each used to sit dead for a third of a second
- A change another program makes just after the app saves — a formatter running on save, say — is picked up instead of silently dropped and then overwritten
- Typing in a large document is faster than before: a keystroke in a 1.4 MiB file costs 45 ms where it used to cost 57
- Launching is roughly ten times quicker on Windows: creating the engine's view took two to four seconds and now takes a third of one. The cost was Impeller, the renderer that became the Windows default after this program's last release; shipped builds ask for the other one. Everything the program does itself has always added up to about 150 ms
- `<br/>` inside a mermaid label is a line break rather than five characters on screen — in every diagram type, not only the flowchart — and `&amp;` and its siblings are decoded. An edge label written in quotes loses them, as a node label already did
- A mermaid state diagram's start and end are told apart: mermaid draws the end ringed, and both were drawn as the same plain circle
- The two spellings of a nested quote, `>> inner` and `> > inner`, are the same quote inside a quote. One nested and the other sat beside its parent
- A table's column alignment survives being exported: `:--`, `:-:` and `--:` were honoured on screen and dropped by HTML, PDF and Word alike. Word also gets real table cells, so `**bold**` in a cell is bold rather than asterisks
- An exported nested list nests the way HTML requires — the sub-list inside the item it hangs off, rather than beside it. Browsers forgive the old shape; validators, pandoc and anything pasted into Word do not
- The code font is used wherever code is drawn: inline `code`, front matter and html blocks kept the platform's generic face while fenced blocks changed, so one setting produced two fonts on one screen
- A task list's checkbox ticks the line it belongs to. Counting one line per item put it on a continuation line, on the blank line of a loose list, or inside a block carried by the step — where it silently did nothing
- Closing the find bar no longer throws, and the highlight it draws in the preview is cleared as it was meant to be
- The settings page keeps what is being typed into it: its text fields were rebuilt on every rebuild, so flipping any switch discarded whatever had not yet been submitted
- The window can be made narrow without the settings page, the menu bar or the status bar spilling over their right edge. There is no minimum window size, and the striping started at about a thousand pixels
- Renaming a file onto a name already in use no longer destroys the file that had it, and asking for a new file under a name already in use no longer empties it. Both wrote over what was there without a prompt, an undo, or anything on screen to say it had happened
- The sidebar's outline scrolls to the heading it names. It and the preview disagreed about which lines are headings — a `# comment` inside front matter was listed although nothing is drawn for it, and an underlined heading was drawn although nothing was listed — so from the first disagreement on, every entry went to the wrong place
- A diagram written under a numbered step is exported with its picture, and a formula written there is exported as a formula rather than as the dollar signs it was written with. A local picture written there is carried into the file too, instead of being left as a path that breaks anywhere else
- Clicking a recent file that has been moved or deleted says so and takes it off the list, instead of doing nothing at all
- Export and Print are greyed out with no document open, where they used to be offered and then do nothing
- A task list is written with the bullet chosen in Settings, as an ordinary list already was; choosing `*` gave one list written with stars and the next with dashes
- Print answers to Ctrl+P. The palette went on taking that key from a shortcut written into the window itself, so Print had none — and rebinding any of the view shortcuts left the old key working there too
- Closing several tabs at once lets go of what they were holding. Closing one dropped its undo history and cancelled its pending auto-save; closing the others, those to the right, or all of them did neither, and their histories stayed for the rest of the session

## [v1.3.0] - 2026-08-27

### Added
- Edit blocks directly in preview mode: double-tap a block to swap it for its markdown source, click away to commit, Esc to cancel
- Mermaid `classDiagram` rendering — three compartments, `<<stereotype>>` annotations, all eight relationship kinds, cardinality labels
- AST nodes carry their source line range, with `sourceOfBlock` / `replaceBlock` helpers that preserve line endings, BOM, and trailing newline
- CI workflow running analyze, test, and a Linux release build on every push and pull request
- `scripts/install-linux-desktop.sh` to register the app as the Markdown handler for a locally built binary

### Fixed
- Sequence diagram activation bars, notes and loop/alt/opt/par frames are drawn instead of being dropped
- A Sankey diagram (`sankey-beta`) renders instead of falling back to showing its source
- A kanban column written with a Chinese id no longer breaks the whole board
- The closing `##` of an ATX heading is no longer shown as part of the heading text
- The "how to open files" dialog no longer appears on launch; opening behaviour is a Settings preference, as it is upstream
- deb packages now ship a postinst that refreshes the desktop and MIME databases, without which a freshly installed app never became a registered handler
- deb and rpm packages now ship a shared-mime-info definition, without which `.md` never resolved to `text/markdown` on systems whose database lacked the glob
- `AppConstants.appVersion` was stuck at 1.2.2 while the app shipped as 1.2.3, so the update check offered users the version they already had
- Mermaid flowcharts written as `graph TD;`, a bare `graph`, or `flowchart-elk LR` rendered nothing
- The app widget test hung CI for over 20 minutes by calling `pumpAndSettle()` on a screen with an indeterminate progress indicator

### Changed
- Cleared the analyzer baseline: `withOpacity` → `withValues`, dangling library doc comments, `Matrix4.scale`, `Radio.groupValue`, `ReorderableListView.onReorder`

## [v1.2.3] - 2026-06-02

### Added
- Mermaid diagram export as PNG image (toolbar "另存为" button, 2x resolution capture via RepaintBoundary)
- Progressive rendering for large files (initial 50 nodes, recursively schedules more via postFrameCallback)
- File loading uses isolate (compute) for background reading, no longer blocks UI thread
- Loading skeleton screens during editor mode switches
- Per-mode scroll offset fields in TabInfo (foundation for future split-mode scroll sync)

### Fixed
- File-open behavior dialog repeatedly appearing (default to existingWindow when dismissed)
- Indented code blocks not rendering (regex now allows leading whitespace)
- Large files (>900 lines) freezing preview window (progressive rendering + isolate-based file read)
- Blockquote text overlapping inside multi-line quotes (removed forceStrutHeight)
- Table last column overflowing border (FlexColumnWidth in preview mode)
- Split-mode tables not horizontally scrollable (mode-aware scroll wrapper)
- Mode switching loses scroll position (IndexedStack keeps all editor states alive)
- Mode switching causing severe lag for large files (deferred build with skeleton screen)
- File loading animation appearing static (forced frame render before isolate work begins)
- Mermaid stateDiagram parallel edges overlapping each other and their labels (perpendicular line offset + label follows its line)
- Mermaid edge labels covered by nodes (draw order: edges → nodes → labels)
- Mermaid layout cramped (Dagre dynamic spacing based on max label size + parallel-edge count)

### Changed
- Mermaid edge label max wrap width tightened to 120px (better vertical layout)
- Mermaid base node spacing reduced to 60px (DagreLayout now adds dynamic extra spacing)
- Editor mode switching duration reduced to 150ms with smoother easing

## [v1.2.2] - 2026-05-22

### Added
- Sidebar directory persistence across app restarts (without auto-opening tabs)
- Sidebar opened-files list also persists (individual files appear after restart)
- Mermaid stateDiagram-v2 syntax support (with Dagre layout, stadium-shape states)
- Mermaid viewer dialog (double-click or button), zoom/pan/Esc to close, dialog sized to ~80% of screen
- Mermaid inline auto-fit (scales down when wider than container)

### Fixed
- Preview mode Ctrl+C copying entire document instead of selected text
- Markdown files with Windows line endings (\r\n) failing to parse
- Large file parsing slow due to repeated CRLF replaceAll (now uses LineSplitter)
- Mermaid diagrams clipped when wider than container
- stateDiagram-v2 layout chaos (now reuses Dagre flowchart layout)
- stateDiagram showing multiple end nodes (now unified) + long edge labels overlapping (dynamic spacing based on label length)
- First file open blocking UI thread due to synchronous readAsStringSync (now async)
- Large code blocks (>20KB) causing UI freeze during syntax highlighting (now skipped)
- UTF-8 BOM causing first-line heading to not render in preview mode
- Duplicate GlobalKey crash when opening files with certain heading structures
- Provider modification during widget build causing startup crash (moved to postFrameCallback)

## [v1.2.1] - 2026-04-30

### Added
- Auto-update check via GitHub Releases API (once per day, non-intrusive status bar indicator)
- Mermaid diagram rendering as images in PDF/Word export (using offscreen widget capture)
- Platform-native font system: Windows (Microsoft YaHei UI), macOS (San Francisco), Linux (Noto Sans)
- Multi-language font fallback chain for CJK, Korean, Japanese, Arabic, Cyrillic

### Fixed
- Preview mode font inconsistency — was using Roboto instead of system default font
- Selection highlight height variation in preview mode (StrutStyle + TextLeadingDistribution.even)
- PDF code block Chinese characters garbled (Courier font doesn't support CJK)
- PDF/Word export showing Mermaid source code instead of rendered diagrams

### Changed
- PDF export styling overhaul: GitHub-inspired typography, proper spacing, borders, alternating table rows
- Word export styling overhaul: page margins, paragraph spacing, line height, code block backgrounds
- Unified font rendering across all UI components (menus, settings, dialogs, preview, status bar)

## [v1.2.0] - 2026-04-29

### Added
- Word (.docx) export functionality with full formatting support (headings, lists, tables, inline styles)
- Automatic HTML clipboard format on Ctrl+C in preview mode for rich paste into Word/Outlook

### Fixed
- PDF export crash caused by TrueType Collection (.ttc) font parsing errors
- PDF emoji rendering - now displays emoji correctly using system emoji fonts (Segoe UI Emoji on Windows)
- Preview mode copy-paste losing line breaks when pasting into Word

### Changed
- Removed redundant "Copy as HTML" toolbar button in preview mode (now automatic on Ctrl+C)
- Optimized markdown parsing performance with AST caching - no longer re-parses on every rebuild
- Simplified PDF emoji normalization - only maps problematic variants (✅→☑, ❌→✗), lets fonts handle others
- Removed expensive font pre-validation in PDF export - now uses try-catch fallback for better startup performance

### Performance
- 3x faster preview mode rendering for large documents (AST caching eliminates redundant parsing)
- Eliminated 6+ PDF generation operations during font loading (removed testDoc.save() validation)
- HTML conversion now cached until content changes (faster Ctrl+C in preview)

## [v1.1.4] - 2026-04-28

### Fixed
- Fixed file open behavior dialog showing on every launch due to config loading race condition
- SettingsNotifier now receives pre-loaded config as initial state instead of async loading

## [v1.1.3] - 2026-04-28

### Added
- Mermaid diagram rendering in preview mode using pure Dart/Flutter (no WebView dependency)
- Copy source button on Mermaid diagram blocks
- Single-instance mode: configurable file opening behavior (new window vs existing window)
- First-launch dialog to choose file opening preference
- File opening behavior setting in Settings → General
- Table cells now render inline Markdown syntax (bold, links, code, etc.)

### Fixed
- Windows line endings (`\r\n`) causing all Markdown syntax to fail rendering
- Config directory `.marktext-plus` being created in the file's directory instead of user home
- Mermaid CDN version upgraded from v10 to v11 in HTML export

### Changed
- Config storage moved from `~/.marktext-plus/` to system application support directory
- Mermaid diagram rendering enlarged (font 16px, node spacing 80px)

## [v1.1.2] - 2026-04-17

### Added
- 3 new themes: Pink Blossom (light), Sky Blue (light), Midnight (dark)
- Preview mode link interaction: Ctrl+Click (Windows/Linux) or Cmd+Click (macOS) to open links in browser or new tab
- Theme names now fully localized in all 12 languages (simplified Chinese names for Chinese locale)

### Fixed
- Fixed preview mode text selection highlight issues with mixed CJK/Latin content, inline code, and links
- Fixed tab title font weight inconsistency (all tabs now use normal weight)

### Changed
- README theme section reorganized into light/dark two-column layout showing all 8 themes
- Link rendering in preview mode: removed default underline decoration to fix selection highlight visibility
- Table rendering in preview mode: removed horizontal scroll wrapper to fix selection continuity

## [v1.1.1] - 2026-04-16

### Fixed
- Fixed keyboard shortcuts (Ctrl+F, Ctrl+H) not working when focus is in editor TextField
- Fixed dark mode display issues — removed independent dark mode toggle, themes now auto-determine light/dark mode
- Fixed excessive UI heights for menu bar, submenu items, and tab context menu (48px → 36px)
- Fixed table overflow in preview mode — added horizontal scrolling for wide tables
- Fixed preview content width not expanding when sidebar is hidden — now uses configurable `editorMaxWidth`
- Fixed preview mode font rendering — applied Open Sans font family with 16px size and 1.6 line height
- Fixed source view selection highlight overflow at line endings — newline characters now share TextStyle with preceding text

### Changed
- Settings screen: split themes into "Light Themes" and "Dark Themes" sections with consistent font weight (w600)
- Theme names now fully internationalized in all 12 languages (e.g., "Dieci OLED" → "Dieci 纯黑" in Chinese)
- Removed `darkMode` boolean from AppConfig, replaced with automatic theme mode detection based on selected theme

## [v1.1.0] - 2026-04-16

### Added
- Token-based theme system (`AppThemeTokens`) with 14 color tokens for unified color management
- 5 new themes: Red Graphite, Shibuya, Dark Graphite, Dieci OLED, Nord
- 28 new i18n keys across all 12 languages for menus, commands, and UI labels
- Dynamic line number gutter width calculation based on digit count
- Browser-style tab bar with rounded active tabs and hover effects
- Tab context menu: close others, close to right, close all, copy name/path, reveal in explorer
- Sidebar active indicator with accent-colored left border
- File tree drag-and-drop folder support
- macOS unsigned app warning and workaround instructions in README

### Changed
- Redesigned all UI components with token-based styling (tab bar, sidebar, status bar, editor, settings)
- Status bar: replaced shadow with top border, token-based colors
- Markdown preview: max-width 720px centered layout, improved typography (17px, 1.7 line height)
- Settings screen: card-style layout with animated category navigation
- Editor syntax highlighting colors now follow theme tokens
- Replaced all hardcoded UI strings with l10n calls (command palette, settings, home screen commands)
- Tab bar height increased to 44px with improved spacing and close button hover states

### Removed
- Old theme set (Cadmium Light, One Dark, Material Dark, Graphite Light, Ulysses Light)

## [v1.0.2] - 2026-04-15

### Fixed
- Fixed StateProvider.overrideWithValue method not existing, causing build failures on Linux ARM64 and macOS
- Fixed Windows file association — .md files now appear in "Open with" context menu
- Fixed startup file handling — files selected via "Open with" now load correctly instead of showing blank window
- Fixed CI/CD ARM64 Linux builds by using manual Flutter installation
- Fixed CI/CD macOS builds by removing unsupported x64 architecture
- Fixed GITHUB_PATH environment variable not taking effect in same workflow step

### Added
- Windows Registry entries for .md, .markdown, and .txt file associations via Inno Setup
- Command-line argument parsing for startup files
- Startup file processing on app launch

## [v1.0.1] - 2026-04-14

### Added
- Initial release with cross-platform CI/CD workflow
- GitHub Actions workflow for Windows, macOS, and Linux builds
- Multi-architecture support (x64, ARM64)
- DEB and RPM package generation for Linux
- Inno Setup installer for Windows
- DMG packaging for macOS
