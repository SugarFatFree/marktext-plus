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
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

이제 끝입니다. 편집기가 샘플 문서와 함께 실행되며 바로 편집을 시작할 수 있습니다.

## ✨ 기능

| Feature | Description |
|---------|-------------|
| **📝 3가지 편집 모드** | 소스 코드 구문 강조, 실시간 미리보기, 분할 보기 |
| **🎨 8가지 아름다운 테마** | Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight |
| **🌍 12개 언어 지원** | 영어, 중국어, 일본어, 한국어, 독일어, 프랑스어, 이탈리아어, 러시아어, 스페인어, 포르투갈어, 아랍어, 브라질 포르투갈어 |
| **⚡ 빠른 반응 속도** | 자체 Markdown 파서와 렌더러로 무거운 의존성 없음 |
| **🔍 찾기 및 바꾸기** | 정규식 지원 전체 검색 |
| **📂 파일 트리** | 사이드바 탐색, 폴더 드래그 앤 드롭 지원 |
| **⌨️ 사용자 지정 단축키** | 키보드 바인딩 완전 설정 가능 |
| **💾 자동 저장** | JSON 기반 영구 설정으로 작업 손실 방지 |

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

[Releases](https://github.com/yourusername/marktext-plus/releases)에서 플랫폼에 맞는 최신 버전을 다운로드하세요.

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### 소스에서 빌드

> **사전 요구 사항**: Flutter 3.x+, Dart 3.x+

```bash
git clone https://github.com/yourusername/marktext-plus.git
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
