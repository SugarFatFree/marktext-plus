# 多语言 README 功能表同步实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将英文 README 的四组最新功能表翻译并同步到 11 份多语言 README，同时完成 v1.5.7 文档记录与验证。

**Architecture:** 以 `README.md` 的 Editing、Rendering、Files & Output、Built to stay light 四组表为事实源，逐文件替换翻译 README 中旧的单一功能表。文档状态和发行说明随后与实际同步结果对齐，不修改 Flutter 运行时代码。

**Tech Stack:** Markdown、Dart `MarkdownParser`/`ExportService`、Flutter test、`dart analyze`。

---

### Task 1: 建立翻译内容基线

**Files:**
- Read: `README.md:40-89`
- Read: `docs/i18n/README_*.md:36-48`
- Create: `code/tool/validate_readmes.dart`

- [ ] **Step 1: 确认主 README 四组表的事实条目**

  固定以下条目不能遗漏：

  - Editing：三种模式、预览内编辑、命令面板与 `/` 菜单、表格编辑、块移动、查找替换、粘贴链接、表格整理、图片。
  - Rendering：22 种 Mermaid、数学公式、CommonMark + GFM、8 个主题、12 种语言。
  - Files & Output：HTML/PDF/Word、编码识别、文件树、外部变更、原子保存、自定义快捷键。
  - Built to stay light：无内嵌浏览器、22 个直接依赖、大文件性能、测试数量。

- [ ] **Step 2: 检查旧表边界和损坏字符**

  Run: `rg -n "^## |^### |�|�" README.md docs/i18n/README_*.md`

  Expected: 只有各语言旧的功能表待替换；没有新增 `�` 字符。

### Task 2: 替换 11 份翻译 README 功能表

**Files:**
- Modify: `docs/i18n/README_ar-SA.md:36-47`
- Modify: `docs/i18n/README_de-DE.md:36-47`
- Modify: `docs/i18n/README_es-ES.md:36-47`
- Modify: `docs/i18n/README_fr-FR.md:36-47`
- Modify: `docs/i18n/README_it-IT.md:36-47`
- Modify: `docs/i18n/README_ja-JP.md:36-47`
- Modify: `docs/i18n/README_ko-KR.md:36-47`
- Modify: `docs/i18n/README_pt-BR.md:36-47`
- Modify: `docs/i18n/README_pt-PT.md:36-47`
- Modify: `docs/i18n/README_ru-RU.md:36-47`
- Modify: `docs/i18n/README_zh-CN.md:41-52`

- [ ] **Step 1: 将每个旧单表替换为四组本地化 Markdown 表**

  每份文件必须保留本地语言的功能标题和表头；技术名词 `Mermaid`、`KaTeX`、`CommonMark`、`GFM`、`HTML`、`PDF`、`Word`、`WebView`、`GBK`、`UTF-8`、`UTF-16`、`Ctrl+Shift+P` 原样保留。阿拉伯语文件保留现有 RTL 文本方向，不改变 HTML 或图片结构。

- [ ] **Step 2: 检查结构等价性**

  Run: `for f in docs/i18n/README_*.md; do printf '%s: ' "$f"; sed -n '/^## .*功能\|^## .*Fonction\|^## .*Features\|^## .*Funz\|^## .*Funk\|^## .*Características\|^## .*Recursos\|^## .*Funcionalidades\|^## .*الميزات\|^## .*機能\|^## .*기능\|^## .*Возможности/,/^## /p' "$f" | rg -c '^### '; done`

  Expected: 每份翻译 README 的功能区包含 4 个三级标题，且紧随其后的表格均为合法 Markdown 表格。

### Task 3: 完成 v1.5.7 发布文档

**Files:**
- Modify: `docs/v1.5.7/PRD_需求文档.md:12,423-462`
- Create: `docs/v1.5.7/release-notes.md`
- Modify: `CHANGELOG.md` only if the existing v1.5.7 document lacks a concise documentation-sync entry

- [ ] **Step 1: 将 FEAT-084 标为已完成**

  将总览表状态从 `部分完成` 改为 `已完成`，并把正文改为：11 份翻译 README 已补齐四组功能表与横向对比表；12 份 README 均通过解析器和 HTML 导出验证；检查结果包含无 `�` 字符、功能区四个三级标题、关键功能条目存在。

- [ ] **Step 2: 创建分组发行说明**

  `release-notes.md` 必须包含 `Added`、`Performance`、`Markdown`、`Documentation` 四组；只写用户可感知的 v1.5.7 内容，README 同步归入 Documentation，不复制整段 CHANGELOG。

### Task 4: 解析器和导出验证

**Files:**
- Create: `code/tool/validate_readmes.dart`
- Test: `code/test/services/html_export_offline_test.dart`

- [ ] **Step 1: 运行 12 份 README 结构探针**

  新建 `code/tool/validate_readmes.dart`，使用 `MarkdownParser().parse` 读取仓库根目录的 `README.md` 和 `docs/i18n/README_*.md`；对每个文件断言：解析节点数大于 0、文本不含 `\uFFFD`、功能区包含四个三级标题、存在“MarkText Plus”横向对比表。脚本遇到任一失败立即抛出异常，并打印文件名和失败条件。

  Run from `code/`: `dart run tool/validate_readmes.dart`

  Expected: 输出 12 个文件的成功校验结果并以退出码 0 结束。

- [ ] **Step 2: 运行测试和静态分析**

  Run from `code/`: `flutter test`

  Expected: 全部测试通过。

  Run from `code/`: `dart analyze --fatal-infos lib test`

  Expected: 0 errors、0 warnings。

### Task 5: 审核、提交并推送

**Files:**
- Verify: all modified README and v1.5.7 documentation files

- [ ] **Step 1: 检查差异与版本规则**

  Run: `git diff --check && git status --short && git diff --stat`

  Expected: 只有本计划列出的文档文件发生变化；没有版本号、tag 或构建产物改动。

- [ ] **Step 2: 提交文档同步**

  ```bash
  git add docs/i18n/README_*.md docs/v1.5.7/PRD_需求文档.md docs/v1.5.7/release-notes.md CHANGELOG.md
  git commit -m "docs: sync translated README feature tables"
  ```

- [ ] **Step 3: 推送 dev，不发布 v1.5.7**

  Run: `git push origin dev`

  Expected: `dev` 推送成功；本轮不执行 `flutter build`、不创建 tag、不合并 `main`，因为当天已发布 v1.5.6。
