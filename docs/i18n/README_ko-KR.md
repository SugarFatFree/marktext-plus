[English](../../README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

# MarkText Plus

Flutter로 구축된 경량 크로스 플랫폼 Markdown 편집기, 원본 [MarkText](https://github.com/marktext/marktext)를 재설계했습니다.

## 기능

- **다국어 지원**: 영어, 중국어, 일본어, 한국어, 독일어, 프랑스어, 이탈리아어, 러시아어, 스페인어, 포르투갈어, 아랍어, 브라질 포르투갈어를 포함한 12개 언어
- **경량 및 빠름**: 최적의 성능을 위한 자체 제작 Markdown 파서 및 렌더러
- **영구 구성**: JSON 기반 설정 저장 및 자동 저장
- **듀얼 패널 편집**: 소스 코드, 미리보기 및 분할 보기 모드
- **크로스 플랫폼**: Windows, macOS 및 Linux에서 실행
- **모던 UI**: 5가지 내장 테마가 있는 깔끔한 인터페이스
- **구문 강조**: 소스 모드에서 실시간 Markdown 구문 강조

## 설치

### 전제 조건

- Flutter 3.x 이상
- Dart 3.x 이상

### 소스에서 빌드

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get
flutter run
```

### 릴리스 빌드

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

### macOS 사용자 참고 사항

> **주의**
> Apple 공증이 없기 때문에 macOS 릴리스에서 "Apple이 MarkText Plus에 악성 소프트웨어가 없는지 확인할 수 없습니다..."라는 경고가 표시됩니다.
>
> MarkText Plus를 "응용 프로그램" 폴더로 드래그한 후 다음 명령을 실행하세요:
>
> ```bash
> xattr -cr /Applications/MarkText\ Plus.app
> sudo codesign --force --deep --sign - /Applications/MarkText\ Plus.app
> ```

## 개발

### 프로젝트 구조

```
code/
├── lib/
│   ├── main.dart              # 애플리케이션 진입점
│   ├── app.dart               # MaterialApp 구성
│   ├── core/                  # 핵심 구성 및 테마
│   ├── models/                # 데이터 모델
│   ├── services/              # 비즈니스 로직 서비스
│   ├── providers/             # Riverpod 상태 관리
│   └── ui/                    # UI 컴포넌트
└── test/                      # 단위 및 위젯 테스트
```

### 아키텍처

4계층 아키텍처:
- **UI 계층**: Flutter 위젯 및 화면
- **상태 계층**: Riverpod 상태 관리
- **서비스 계층**: 비즈니스 로직 및 데이터 처리
- **플랫폼 계층**: 파일 I/O 및 시스템 통합

### 테스트 실행

```bash
flutter test
```

## 기여

기여를 환영합니다! 언제든지 Pull Request를 제출해 주세요.

## 라이선스

이 프로젝트는 MIT 라이선스에 따라 라이선스가 부여됩니다 - 자세한 내용은 [LICENSE](../../LICENSE) 파일을 참조하세요.

Luo Ran 및 기여자의 [MarkText](https://github.com/marktext/marktext)를 기반으로 합니다.

## 감사의 말

- 원본 MarkText 프로젝트 및 기여자
- Flutter 및 Dart 팀
- 이 프로젝트에서 사용된 모든 오픈 소스 라이브러리
