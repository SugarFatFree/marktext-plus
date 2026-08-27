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

## Diagram syntax variants

These follow the shapes used in mermaid's own documentation, to check that the
parsers accept more than the one spelling each was first written against.

```mermaid
flowchart LR
  subgraph one[Group one]
    A[Square] --> B(Rounded)
    B --> C{{Hexagon}}
  end
  subgraph two[Group two]
    D[(Database)] --> E((Circle))
  end
  C -.->|dotted| D
  A ==>|thick| E
```

```mermaid
sequenceDiagram
  participant Alice
  participant Bob
  Alice->>Bob: Ask
  loop every minute
    Bob->>Bob: Check
  end
  alt is ok
    Bob-->>Alice: Yes
  else is not
    Bob-->>Alice: No
  end
  Note over Alice,Bob: Shared note
```

```mermaid
pie showData
  "Reading" : 40
  "Writing" : 35
  "Meetings" : 25
```

```mermaid
timeline
  title Product history
  2019 : Prototype
  2021 : Beta : Public launch
  2024 : Rewrite
```

```mermaid
gantt
  title Release plan
  dateFormat YYYY-MM-DD
  section Build
    Spec        :done, spec, 2026-01-01, 10d
    Implement   :active, impl, after spec, 20d
    Review      :crit, after impl, 5d
  section Ship
    Launch      :milestone, after impl, 0d
```

```mermaid
stateDiagram-v2
  [*] --> Active
  state Active {
    [*] --> Idle
    Idle --> Busy: work
    Busy --> Idle: done
  }
  Active --> [*]: shutdown
```

```mermaid
quadrantChart
  title Reach and engagement of campaigns
  x-axis Low Reach --> High Reach
  y-axis Low Engagement --> High Engagement
  quadrant-1 We should expand
  quadrant-2 Need to promote
  quadrant-3 Re-evaluate
  quadrant-4 May be improved
  Campaign A: [0.3, 0.6]
  Campaign B: [0.45, 0.23]
  Campaign C: [0.57, 0.69] radius: 10, color: #ff0000
  Campaign D: [0.78, 0.34]
```

```mermaid
requirementDiagram
  requirement test_req {
    id: 1
    text: the test text.
    risk: high
    verifymethod: test
  }
  functionalRequirement test_req2 {
    id: 1.1
    text: the second test text.
    risk: low
    verifymethod: inspection
  }
  element test_entity {
    type: simulation
    docref: reference
  }
  test_entity - satisfies -> test_req2
  test_req - traces -> test_req2
```

~~~python
# a tilde fence: the # above is a comment, not a heading
print("hello")
~~~

````markdown
```dart
void main() {}
```
````

> Quoted blocks keep their structure:
>
> - a quoted list item
> - another one
>
> ```dart
> void quoted() {}
> ```
>
> > and a quote inside a quote

1. A numbered step
   - with a bulleted sub-point
   - and another
2. The next step
   1. renumbered from one
   2. inside this step

[![build](https://img.shields.io/badge/build-passing-green.svg)](https://ci.example.com)

```mermaid
graph LR
  A["Start here"] -- yes --> B{Choice}
  B -. maybe .-> C[(Store)]
  B <--> D((Done))
  A --> E & F
```

```mermaid
graph TD
  开始 --> 判断{是否继续}
  判断 -- 是 --> 处理[执行任务]
  判断 -- 否 --> 结束
```

```mermaid
sequenceDiagram
  用户->>+系统: 登录
  Note over 用户,系统: 认证流程
  alt 凭证正确
    系统-->>-用户: 成功
  else 凭证错误
    系统-->>用户: 请重试
  end
```

```mermaid
---
title: Energy flow
---
sankey-beta
Coal,Electricity,100
Gas,Electricity,45
Electricity,Households,80
Electricity,"Industry, heavy",65
```

```mermaid
block-beta
  columns 3
  frontend["Web UI"] api("Gateway") db[("Storage")]
  space:2 cache{{"Cache"}}
  frontend --> api
  api -- "reads" --> db
```
