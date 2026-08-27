---
title: MarkText Plus Showcase
author: regression fixture
---

# Showcase

This document exercises every block and inline construct the parser handles,
plus every mermaid diagram type the renderer draws. It doubles as a manual
check: open it in the app and everything below should render, not appear as
raw syntax.

## Inline formatting

Plain text, **bold**, *italic*, ***bold italic***, `inline code`,
~~strikethrough~~, ==highlight==, ^superscript^, ~subscript~, and a
[link](https://example.com "with a title").

An image: ![alt text](assets/example.png)

Inline math $E = mc^2$ sits in a sentence. A footnote reference[^note] too.

[^note]: The footnote definition itself.

Characters that must survive escaping: a < b, x & y, "quoted", 'single'.

## Headings

# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6

## Lists

- bullet one
- bullet two
  - nested bullet

1. ordered one
2. ordered two

- [ ] unchecked task
- [x] checked task

## Blockquote

> A quote with **bold** and a [link](https://example.com) inside, to check that
> exports render the formatting rather than printing the markers.

## Code

```dart
void main() {
  print('hello');
}
```

```
plain fence, no language
```

## Table

| Left | Centre | Right |
|:-----|:------:|------:|
| a    | b      | c     |
| 1    | 2      | 3     |

## Math block

$$
\int_0^1 x^2 \, dx = \frac{1}{3}
$$

## Horizontal rule

---

## HTML block

<div class="note">Raw HTML passes through.</div>

## Diagrams

```mermaid
flowchart TD
  A[Start] --> B{Decision}
  B -->|yes| C[Done]
  B -->|no| A
```

```mermaid
sequenceDiagram
  Alice->>Bob: Hello
  Bob-->>Alice: Hi
```

```mermaid
classDiagram
  class Animal {
    +int age
    -String name
    +isMammal() bool
  }
  class Duck {
    +String beakColor
    +quack()
  }
  Animal <|-- Duck
  Animal *-- Habitat
  Owner "1" --> "0..*" Animal : keeps
```

```mermaid
stateDiagram-v2
  [*] --> Idle
  Idle --> Running: start
  Running --> [*]: stop
```

```mermaid
erDiagram
  CUSTOMER["Client record"] ||--o{ ORDER : places
  ORDER ||--|{ LINE_ITEM : contains
  CUSTOMER {
    string name
    string custNumber PK
    int age
  }
```

```mermaid
journey
  title My working day
  section Go to work
    Make tea: 5: Me
    Do work: 1: Me, Cat
  section Go home
    Go downstairs: 5: Me
```

```mermaid
gitGraph
  commit
  commit id: "Alpha"
  branch develop
  commit
  checkout main
  merge develop
  commit tag: "v1.0"
```

```mermaid
mindmap
  root((Origins))
    Research
      Effectiveness
    History
      Long history
```

```mermaid
pie title Languages
  "Dart" : 70
  "C++" : 20
  "Other" : 10
```

```mermaid
gantt
  title Schedule
  dateFormat YYYY-MM-DD
  section Phase
    Design :a1, 2026-01-01, 30d
    Build  :after a1, 45d
```

```mermaid
timeline
  title History
  2002 : First release
  2010 : Rewrite
```

```mermaid
kanban
  Todo
    Write docs
  Doing
    Fix bugs
  Done
    Ship it
```

```mermaid
radar-beta
  axis a["Speed"], b["Power"], c["Range"]
  curve alpha{80, 60, 90}
```

```mermaid
xychart-beta
  title "Revenue"
  x-axis [jan, feb, mar]
  y-axis "Amount" 0 --> 100
  bar [30, 60, 90]
```
