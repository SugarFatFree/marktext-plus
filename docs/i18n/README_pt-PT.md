<div align="center">

# MarkText Plus

**Um editor Markdown leve e multiplataforma reconstruído com Flutter, redesenhado a partir do [MarkText](https://github.com/marktext/marktext) original.**

[English](../../README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

![MarkText Plus](../../docs/v1.1.2/picture/theme/red-graphite.png)

</div>

---

## 💡 O que é o MarkText Plus?

O MarkText Plus é um **editor Markdown moderno**, reimaginado a partir do [MarkText](https://github.com/marktext/marktext) original e reconstruído com Flutter para um verdadeiro suporte multiplataforma. Resolve vários problemas típicos dos editores Markdown tradicionais.

- ❌ Pesado e lento no arranque → ✅ **Muito rápido** com parser próprio
- ❌ Poucas opções de tema → ✅ **8 temas elegantes** (claros e escuros)
- ❌ Fraca experiência multiplataforma → ✅ **Desempenho nativo** em Windows, macOS e Linux
- ❌ Configuração complicada → ✅ **Pronto em 3 comandos**

## 🚀 Início rápido

Pronto em menos de 30 segundos.

```bash
git clone https://github.com/SugarFatFree/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

É só isso. O editor será iniciado com um documento de exemplo pronto para editar.

## ✨ Funcionalidades

| Feature | Description |
|---------|-------------|
| **📝 Três modos de edição** | Código-fonte com realce de sintaxe, pré-visualização em direto e vista dividida |
| **🎨 8 temas elegantes** | Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight |
| **🌍 12 idiomas** | Inglês, chinês, japonês, coreano, alemão, francês, italiano, russo, espanhol, português, árabe e português do Brasil |
| **⚡ Resposta rápida** | Parser e renderizador Markdown próprios, sem dependências pesadas |
| **🔍 Procurar e substituir** | Pesquisa completa com suporte para expressões regulares |
| **📂 Árvore de ficheiros** | Navegação lateral com suporte para arrastar e largar pastas |
| **⌨️ Atalhos personalizáveis** | Associações de teclado totalmente configuráveis |
| **💾 Gravação automática** | Configuração persistente em JSON para nunca perder o trabalho |

## 🎨 Temas

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

## 📦 Instalação

### Transferir binários pré-compilados

Transfira a versão mais recente para a sua plataforma em [Releases](https://github.com/SugarFatFree/marktext-plus/releases).

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### Compilar a partir do código-fonte

> **Pré-requisitos**: Flutter 3.x+, Dart 3.x+

```bash
git clone https://github.com/SugarFatFree/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

<details>
<summary><b>Comandos de build de lançamento</b></summary>

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
<summary><b>Utilizadores macOS: contornar aviso de app não assinada</b></summary>

> O macOS pode mostrar o aviso "A Apple não conseguiu verificar se o MarkText Plus está livre de software malicioso...". Depois de mover a app para a pasta "Aplicações", execute os comandos abaixo.
>
> ```bash
> xattr -cr /Applications/MarkText\ Plus.app
> sudo codesign --force --deep --sign - /Applications/MarkText\ Plus.app
> ```
</details>

## 🏗️ Arquitetura

```
code/lib/
├── main.dart           # Ponto de entrada da aplicação
├── app.dart            # MaterialApp com ligação de tema, locale e i18n
├── core/               # Tokens de tema, configuração, i18n (12 idiomas)
├── models/             # TabInfo, FileNode
├── services/           # Parser Markdown, I/O de ficheiros, atalhos de teclado
├── providers/          # Gestão de estado Riverpod
└── ui/
    ├── editor/         # Editor de origem, renderização da pré-visualização, vista dividida
    ├── screens/        # Início, Definições
    └── widgets/        # Barra de menus, barra lateral, barra de separadores, barra de estado
```

Arquitetura de quatro camadas: **UI** → **Estado** (Riverpod) → **Serviço** → **Plataforma**

### Executar testes

```bash
cd code && flutter test
```

## 🤝 Contribuir

As contribuições são bem-vindas. Envie um Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 Licença

Licença MIT — consulte [LICENSE](../../LICENSE) para mais detalhes.

Baseado em [MarkText](https://github.com/marktext/marktext) de Luo Ran e colaboradores.

## 🙏 Agradecimentos

- [MarkText](https://github.com/marktext/marktext) — o projeto original que inspirou este editor
- [Flutter](https://flutter.dev) — a framework multiplataforma
- Todas as bibliotecas open source utilizadas neste projeto
