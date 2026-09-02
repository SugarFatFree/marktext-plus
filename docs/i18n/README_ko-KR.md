<div align="center">

# MarkText Plus

**Flutter로 구축된 경량 크로스 플랫폼 Markdown 편집기, 원본 [MarkText](https://github.com/marktext/marktext)를 재설계했습니다.**

[English](../../README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

![MarkText Plus](../../docs/v1.1.2/picture/theme/red-graphite.png)

</div>

---

## 💡 MarkText Plus란?

MarkText Plus는 원본 [MarkText](https://github.com/marktext/marktext)를 바탕으로 Flutter로 다시 만든 **현대적인 Markdown 편집기**입니다. 진정한 크로스 플랫폼 경험을 제공하며 기존 Markdown 편집기의 문제를 해결합니다.

- ❌ 무겁고 시작이 느림 → ✅ **빠른 실행 속도**, 자체 Markdown 파서
- ❌ 제한적인 테마 선택 → ✅ **8가지 아름다운 테마** (라이트 & 다크)
- ❌ 부족한 크로스 플랫폼 경험 → ✅ **네이티브 성능**, Windows, macOS, Linux 지원
- ❌ 복잡한 설정 → ✅ **3개 명령어로 바로 시작**

## 🚀 빠른 시작

30초 안에 실행할 수 있습니다.

```bash
git clone https://github.com/marktext-plus/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

이제 끝입니다. 편집기가 샘플 문서와 함께 실행되며 바로 편집을 시작할 수 있습니다.

## ✨ 기능

### 편집

| 기능 | 설명 |
|---------|-------------|
| **📝 3가지 편집 모드** | 구문 강조 소스, 실시간 미리보기, 드래그 가능한 분할 보기 |
| **✏️ 미리보기에서 편집** | 블록을 두 번 클릭해 Markdown을 제자리에서 편집. `Esc`로 취소하고 작업 상자는 한 번 클릭해 전환 |
| **⌨️ 명령 팔레트와 `/` 메뉴** | `Ctrl+Shift+P`로 명령을 실행하고 `/`로 블록 삽입 |
| **📊 표 편집** | 행과 열을 추가·삭제하고 열별 정렬 설정 |
| **🔀 블록 이동** | 단축키 하나로 문단, 목록, 코드 펜스를 위아래로 이동 |
| **🔍 찾기 및 바꾸기** | 완전한 단어와 정규식 검색, 문서 전체 바꾸기 |
| **🔗 링크 붙여넣기** | 텍스트를 선택하고 웹 주소를 붙여 링크로 변환 |
| **📐 표 정리** | 내용을 바꾸지 않고 파이프 정렬. CJK 문자는 두 열로 계산 |
| **🖼️ 이미지** | 이미지를 붙여넣거나 놓으면 문서 옆에 저장하고 링크 |

### 렌더링

| 기능 | 설명 |
|---------|-------------|
| **📈 Mermaid 다이어그램** | **22가지 유형**을 순수 Dart로 그리며 **WebView가 필요 없음** |
| **∑ 수학** | KaTeX 호환 렌더링을 사용하는 인라인 및 블록 LaTeX |
| **📋 CommonMark + GFM** | 표, 작업 목록, 취소선, 자동 링크, 각주, `<ruby>` 주석 |
| **🎨 8가지 테마** | Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight |
| **🌍 12개 언어** | 영어, 중국어, 일본어, 한국어, 독일어, 프랑스어, 이탈리아어, 러시아어, 스페인어, 포르투갈어, 아랍어, 브라질 포르투갈어. 아랍어 RTL 지원 |

### 파일 및 출력

| 기능 | 설명 |
|---------|-------------|
| **📤 내보내기** | HTML, PDF, Word `.docx`; 다이어그램과 강조 코드를 HTML에 포함하고 수학은 KaTeX 사용 |
| **🔤 인코딩** | BOM 유무와 관계없이 UTF-8, UTF-16, GBK를 감지하고 발견한 인코딩으로 저장 |
| **📂 파일 트리** | 사이드바 탐색 및 폴더 드래그 앤 드롭 |
| **👀 외부 변경** | 문서가 열린 동안 다른 프로그램의 변경을 감지 |
| **💾 안전한 저장** | 원자적 쓰기로 중단 후 부분 파일 방지 |
| **⌨️ 사용자 지정 단축키** | 키보드 바인딩 완전 설정 가능 |

### 가볍게 유지

| | |
|---------|-------------|
| **🧩 Open plugins** | Discover public plugins through [GitHub Topic: `marktext-plus-plugin`](https://github.com/topics/marktext-plus-plugin); every plugin is labelled Community/Unverified and runs out of process |
| **⚡ 빠른 시작** | 내장 브라우저와 편집 프레임워크 없이 직접 의존성 22개 |
| **📄 대용량 파일** | 파싱·강조·검색을 단일 패스로 처리하고 테스트 예산으로 관리 |
| **🧪 테스트 완료** | 파서, 내보내기, provider, 편집기 위젯을 2028개 테스트로 검증 |
## ⚖️ 다른 편집기와 비교

이 프로젝트가 다시 만든 원본 편집기, 그리고 이 분야에서 가장 잘 알려진 편집기와 비교했습니다. MarkText 열의 모든 수치는 `v0.20.0-dev` 소스에서 직접 읽은 것입니다. Typora 는 비공개 소스라 같은 방식으로 확인할 수 없어, 공개된 문서에 적힌 내용만 실었습니다.

시작 시간은 같은 Windows 컴퓨터에서 세 프로그램을 모두 측정한 것입니다. 이 프로그램의 수치는 스스로 기록한 것이고(`startup-trace.log` 를 남기며, 여기서는 네 번의 실행), 나머지 둘은 손으로 잰 값이니 더 거친 쌍으로 보아 주십시오. 이 프로그램의 시작 시간 대부분은 자신의 코드가 아닙니다. 0.7 초 가운데 약 0.5 초는 Windows 가 실행 파일을 읽고 Flutter 엔진이 뜨는 시간이며, 편집기 자신이 하는 일은 약 0.15 초입니다.

| | **MarkText Plus** | **MarkText**(원본) | **Typora** |
|---|---|---|---|
| **런타임** | Flutter — 컴파일형, 내장 브라우저 없음 | Electron 42 | Electron |
| **시작 시간**(문서가 보일 때까지) | 따뜻할 때 약 0.7 초, 차가울 때 약 1.4 초 | 2~3 초 | 2~3 초 |
| **직접 의존성 수** | 22 | 56(desktop 패키지) | 비공개 소스 |
| **라이선스** | MIT, 무료 | MIT, 무료 | 유료, 비공개 소스 |
| **편집 방식** | 소스, 미리보기, 그리고 서로를 따라가는 분할 보기. 미리보기에서 블록을 그 자리에서 편집합니다 | 라이브 미리보기(WYSIWYG)와 소스 모드 | 라이브 미리보기(WYSIWYG)와 소스 모드 |
| **다이어그램** | 22 가지 Mermaid 도형을 Dart 로 그리며 WebView 를 쓰지 않음 | Mermaid, flowchart.js, Vega-Lite, PlantUML — 모두 JavaScript 를 거침 | Mermaid, flowchart.js, js-sequence, PlantUML |
| **수식** | KaTeX 호환 | KaTeX | KaTeX |
| **내보내기** | HTML, PDF, Word — 모두 내장 | HTML, PDF, Markdown. pandoc 이 있으면 더 많은 형식 | 여러 형식, 대부분 pandoc 을 거침 |
| **테마** | 8 | 32 | 많음, 그리고 큰 커뮤니티 모음 |
| **인터페이스 언어** | 12 | 10 | 여럿 |
| **플랫폼** | Windows, macOS, Linux(x64 및 arm64) | Windows, macOS, Linux | Windows, macOS, Linux |

### 상대가 앞선 점

분명히 적어 둡니다. 자기만 치켜세우는 비교표는 읽을 가치가 없기 때문입니다.

- **라이브 미리보기.** Typora 와 MarkText 는 렌더링된 문서를 바로 편집하며 모드 전환이 없습니다. 이 프로그램은 세 가지 보기와, 미리보기에서 블록을 여는 방식을 줍니다. **이것은 다른 것이며**, Typora 에 익숙한 사람이 가장 먼저 느낄 차이입니다.
- **테마.** 32 대 8, 게다가 Typora 에는 수년간 쌓인 커뮤니티 CSS 가 있습니다.
- **다이어그램의 폭.** PlantUML 과 Vega-Lite 는 여기에 없습니다.
- **세월.** Typora 는 10 년 동안 다듬어졌습니다. 이 프로그램은 젊고, 그렇게 보이는 곳도 있습니다.

### 이 프로그램이 앞선 점

- **내장 브라우저가 없음.** 파서, 렌더러, 문법 강조, 다이어그램 엔진이 모두 여기서 작성되어 컴파일됩니다. 그것이 이 프로젝트의 이유이며, 위의 시작 시간이 그 대가로 얻은 것입니다.
- **JavaScript 없는 다이어그램.** 22 가지 Mermaid 도형을 Dart 페인터가 그리므로, PDF 와 Word 에 읽는 사람이 실행해야 할 스크립트가 아니라 그림으로 들어갑니다.
- **pandoc 없이 Word 내보내기.** 프로그램을 하나 더 설치할 필요가 없습니다.
- **무료이고 공개 소스**입니다. Typora 는 그렇지 않습니다.

## 🎨 테마

<table>
  <tr>
    <th align="center">Light Themes</th>
    <th align="center">Dark Themes</th>
  </tr>
  <tr>
    <td align="center"><b>Red Graphite</b><br/><img src="../../docs/v1.1.2/picture/theme/red-graphite.png" alt="Red Graphite" width="400"/></td>
    <td align="center"><b>Dark Graphite</b><br/><img src="../../docs/v1.1.2/picture/theme/dark-graphite.png" alt="Dark Graphite" width="400"/></td>
  </tr>
  <tr>
    <td align="center"><b>Shibuya</b><br/><img src="../../docs/v1.1.2/picture/theme/shibuya.png" alt="Shibuya" width="400"/></td>
    <td align="center"><b>Dieci OLED</b><br/><img src="../../docs/v1.1.2/picture/theme/dieci-oled.png" alt="Dieci OLED" width="400"/></td>
  </tr>
  <tr>
    <td align="center"><b>Pink Blossom</b><br/><img src="../../docs/v1.1.2/picture/theme/pink-blossom.png" alt="Pink Blossom" width="400"/></td>
    <td align="center"><b>Nord</b><br/><img src="../../docs/v1.1.2/picture/theme/nord.png" alt="Nord" width="400"/></td>
  </tr>
  <tr>
    <td align="center"><b>Sky Blue</b><br/><img src="../../docs/v1.1.2/picture/theme/sky-blue.png" alt="Sky Blue" width="400"/></td>
    <td align="center"><b>Midnight</b><br/><img src="../../docs/v1.1.2/picture/theme/midnight.png" alt="Midnight" width="400"/></td>
  </tr>
</table>

## 📦 설치

### 사전 빌드 바이너리 다운로드

[Releases](https://github.com/marktext-plus/marktext-plus/releases)에서 플랫폼에 맞는 최신 버전을 다운로드하세요.

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### 소스에서 빌드

> **사전 요구 사항**: Flutter 3.x+, Dart 3.x+

```bash
git clone https://github.com/marktext-plus/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

<details>
<summary><b>릴리스 빌드 명령</b></summary>

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```
</details>

<details>
<summary><b>macOS 사용자: 서명되지 않은 앱 경고 우회</b></summary>

> macOS에서는 "Apple이 MarkText Plus에 악성 소프트웨어가 없는지 확인할 수 없습니다..." 경고가 표시될 수 있습니다. 앱을 "응용 프로그램" 폴더로 옮긴 뒤 다음을 실행하세요.
>
> ```bash
> xattr -cr /Applications/MarkText\ Plus.app
> sudo codesign --force --deep --sign - /Applications/MarkText\ Plus.app
> ```
</details>

## 🏗️ 아키텍처

```
code/lib/
├── main.dart           # 앱 진입점
├── app.dart            # 테마, 로케일, i18n 바인딩을 가진 MaterialApp
├── core/               # 테마 토큰, 설정, i18n (12개 언어)
├── models/             # TabInfo, FileNode
├── services/           # Markdown 파서, 파일 I/O, 키바인딩
├── providers/          # Riverpod 상태 관리
└── ui/
    ├── editor/         # 소스 편집기, 미리보기 렌더러, 분할 보기
    ├── screens/        # 홈, 설정
    └── widgets/        # 메뉴 바, 사이드바, 탭 바, 상태 바
```

4계층 아키텍처: **UI** → **상태 계층** (Riverpod) → **서비스 계층** → **플랫폼 계층**

### 테스트 실행

```bash
cd code && flutter test
```

## 🤝 기여

기여를 환영합니다. Pull Request를 보내 주세요.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 라이선스

MIT 라이선스 - 자세한 내용은 [LICENSE](../../LICENSE)를 참조하세요.

[MarkText](https://github.com/marktext/marktext)는 Luo Ran과 기여자들의 프로젝트입니다.

## 🙏 감사의 말

- [MarkText](https://github.com/marktext/marktext) — 이 편집기의 영감이 된 원본 프로젝트
- [Flutter](https://flutter.dev) — 크로스 플랫폼 프레임워크
- 이 프로젝트에서 사용하는 모든 오픈 소스 라이브러리
