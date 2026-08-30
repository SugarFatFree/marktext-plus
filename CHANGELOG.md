# Changelog

All notable changes to MarkText Plus will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - v1.5.6

### Added
- A picture written as `<img src="…" width="400">` on a line of its own is drawn as the picture it describes, at the size it asks for. Markdown has no way to say how big a picture should be, so a document that needs to say it falls back to the tag — upstream MarkText's own documentation does so sixty times, and every one of them opened here as a line of angle brackets in a grey box. A tag inside a table cell or with text beside it is still part of the HTML around it
- The `/` menu offers a Mermaid diagram and the six heading levels. A diagram had no way in at all — the fence, the word and the first line had to be typed from memory — and it is the block this editor is built around; what the menu inserts draws something straight away. The headings go at the end rather than the top, where upstream puts them: `##` is two keystrokes here, and six of them above the table and the fence would push the blocks that are actually awkward to type out of sight
- `<ruby>漢<rt>hàn</rt></ruby>` draws the reading above the text, as Japanese furigana and Chinese pinyin are written. It was escaped and shown as angle brackets, so a document annotated this way read as its own source. The preview draws it; HTML emits real ruby with the `<rp>` brackets a reader that cannot draw it needs; Word and PDF, which have neither, print the reading after the text the way a dictionary does

### Fixed
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
