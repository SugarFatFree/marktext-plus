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
git clone https://github.com/marktext-plus/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

É só isso. O editor será iniciado com um documento de exemplo pronto para editar.

## ✨ Funcionalidades

### Edição

| Feature | Description |
|---------|-------------|
| **📝 Three edit modes** | Source with syntax highlighting, live preview and draggable split view |
| **✏️ Edit in preview** | Double-click a block to edit Markdown in place; `Esc` discards and task boxes toggle with one click |
| **⌨️ Command palette and `/` menu** | `Ctrl+Shift+P` runs commands and `/` inserts a block |
| **📊 Table editing** | Insert or delete rows and columns and align each column |
| **🔀 Move blocks** | Move paragraphs, lists or fences up and down with one shortcut |
| **🔍 Find and replace** | Whole-word and regular-expression search across the document |
| **🔗 Paste a link** | Select words and paste a web address to make a link |
| **📐 Tidy tables** | Realign table pipes without changing content; CJK characters count as two columns |
| **🖼️ Images** | Paste or drop a picture to store it beside the document and link it |

### Renderização

| Feature | Description |
|---------|-------------|
| **📈 Mermaid diagrams** | **22 types** drawn in pure Dart, **without WebView** |
| **∑ Math** | Inline and block LaTeX with KaTeX-compatible rendering |
| **📋 CommonMark + GFM** | Tables, task lists, strikethrough, autolinks, footnotes and `<ruby>` annotations |
| **🎨 8 themes** | Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight |
| **🌍 12 languages** | English, Chinese, Japanese, Korean, German, French, Italian, Russian, Spanish, Portuguese, Arabic and Brazilian Portuguese; Arabic uses RTL |

### Ficheiros e saída

| Feature | Description |
|---------|-------------|
| **📤 Export** | HTML, PDF and Word `.docx`; diagrams and highlighted code are embedded in HTML, while maths still uses KaTeX |
| **🔤 Encodings** | UTF-8, UTF-16 and GBK detected on open, with or without BOM, and written back as found |
| **📂 File tree** | Sidebar navigation with folder drag and drop |
| **👀 External changes** | Notices edits made by another program while the document is open |
| **💾 Safe saving** | Atomic writes prevent partial files after interruption |
| **⌨️ Custom shortcuts** | Fully configurable keyboard bindings |

### Feito para continuar leve

| | |
|---------|-------------|
| **🧩 Extensões abertas** | Um ficheiro Lua ou JavaScript, sem SDK e sem compilação, numa caixa de areia e limitado às permissões que declarou. Encontram-se em [GitHub Topic: `marktext-plus-plugin`](https://github.com/topics/marktext-plus-plugin); cada uma vem marcada como Comunidade/não verificada |
| **⚡ Arranque rápido** | Sem navegador embutido nem framework de editor: 23 dependências diretas |
| **📄 Ficheiros grandes** | Análise, realce e pesquisa numa só passagem, com orçamentos que fazem falhar os testes. Acima de 128 KB o realce para — é o último tamanho que abre em cerca de um segundo. Continua a poder editar, e as cores voltam se o ficheiro encolher |
| **🧪 Testado** | 2417 testes para o analisador, as exportações, os providers, os motores de extensões e os widgets do editor |

### Extensões

Escritas em Lua ou JavaScript — um ficheiro e um manifesto, sem compilação, e o mesmo ficheiro corre nas três plataformas. Uma extensão pode ter vários ficheiros, e o `require` só chega dentro do seu próprio diretório.

| Funcionalidade | Descrição |
|---------|-------------|
| **🔐 Permissões** | Declaradas no manifesto, mostradas antes de instalar e **impostas**. O VS Code e o IntelliJ mostram uma lista e depois confiam; aqui ninguém revê nada, por isso quem verifica é o editor. Uma extensão que pergunta ao modelo sem `ai.chat` recebe um não, e você fica a saber que ela tentou |
| **🪟 Quadros** | O editor já divide um separador entre código-fonte e pré-visualização; essa divisão é oferecida para fora. Até quatro células, separadores que se arrastam, e nada desenhado para uma célula que ninguém preencheu |
| **✍️ Escrever de volta** | Uma extensão pode reescrever o que você selecionou — depois de lho mostrar. O resultado vem com um botão Aplicar, e aplicar passa pelo histórico do editor: um desfazer traz tudo de volta |
| **⚙️ Definições próprias** | O editor desenha a página a partir do que a extensão declarou: um interruptor para um interruptor, um campo oculto para um segredo. As extensões dão dados, nunca componentes |
| **🌍 Idiomas próprios** | Uma extensão traz os idiomas que o seu autor quiser, independentemente dos doze que o editor fala |
| **🔑 Nunca as suas chaves** | O editor guarda as credenciais e faz o pedido. A extensão dá a instrução e recebe texto |

Comece pelo [SDK de extensões](https://github.com/marktext-plus-plugins/marktext-plus-plugin-sdk) — três exemplos completos para copiar e documentação em onze idiomas.

### Para agentes de IA

Um servidor MCP opcional, **desligado até você o ligar**: abre uma porta na sua máquina, e quem lá chegar poderá ler os seus documentos e comandar o seu editor. Por isso é você que o liga, e ele leva um token que pode voltar a gerar.

| Ferramenta | Descrição |
|---------|-------------|
| **`read_logs`** | O registo do editor e o das extensões, filtrável por extensão e por gravidade |
| **`screenshot`** | A janela tal como está |
| **`record_gif`** | Cinco segundos no máximo, para ver uma animação |
| **`get_state`** | O que está aberto: separadores, modo de vista, extensões instaladas, quadros preenchidos |
| **`control`** | Abrir e fechar separadores, mudar de modo, escrever conteúdo, fechar um quadro |

## ⚖️ Comparação

Face ao editor de que este é uma reinterpretação, e face ao mais conhecido da área. Tudo o que consta na coluna do MarkText foi lido do seu código-fonte na `v0.20.0-dev`; a coluna do Typora vem da sua documentação publicada, uma vez que é de código fechado e não pode ser verificado da mesma forma.

Os tempos de arranque vêm de uma só máquina com Windows, com os três programas nela. Os deste programa são instrumentados — escreve o seu próprio `startup-trace.log`, e os números são de quatro arranques — enquanto os outros dois foram cronometrados à mão: veja-os como o par mais grosseiro. A maior parte do arranque aqui não é código próprio: dos 0,7 s, cerca de 0,5 s cabem ao Windows a carregar o executável e ao motor Flutter a arrancar, e 0,15 s a tudo o que o editor faz.

| | **MarkText Plus** | **MarkText** (original) | **Typora** |
|---|---|---|---|
| **Ambiente de execução** | Flutter — compilado, sem navegador incorporado | Electron 42 | Electron |
| **Arranque** (até o documento aparecer) | ~0,7 s a quente, ~1,4 s a frio | 2–3 s | 2–3 s |
| **Dependências diretas** | 22 | 56 (pacote desktop) | código fechado |
| **Licença** | MIT, gratuito | MIT, gratuito | Pago, código fechado |
| **Edição** | Código, pré-visualização e uma vista dividida cujas metades se acompanham; os blocos editam-se no lugar dentro da pré-visualização | Pré-visualização ao vivo (WYSIWYG), mais um modo de código | Pré-visualização ao vivo (WYSIWYG), mais um modo de código |
| **Diagramas** | 22 tipos de Mermaid, desenhados em Dart sem WebView | Mermaid, flowchart.js, Vega-Lite, PlantUML — todos através de JavaScript | Mermaid, flowchart.js, js-sequence, PlantUML |
| **Matemática** | Compatível com KaTeX | KaTeX | KaTeX |
| **Exportação** | HTML, PDF, Word — tudo integrado | HTML, PDF, Markdown; mais formatos se o pandoc estiver instalado | Muitos formatos, a maioria através do pandoc |
| **Temas** | 8 | 32 | Muitos, e uma vasta coleção da comunidade |
| **Idiomas da interface** | 12 | 10 | Vários |
| **Plataformas** | Windows, macOS, Linux (x64 e arm64) | Windows, macOS, Linux | Windows, macOS, Linux |

### Onde os outros estão à frente

Vale a pena dizê-lo com clareza: uma comparação que só elogia quem a escreve não merece ser lida.

- **Pré-visualização ao vivo.** O Typora e o MarkText editam diretamente o documento já composto, sem modo a trocar. Este editor dá três painéis e permite abrir um bloco no lugar; é outra coisa, e para quem vem do Typora é a diferença que se nota primeiro.
- **Temas.** Trinta e dois contra oito, e o Typora tem anos de CSS da comunidade atrás de si.
- **Abrangência dos diagramas.** PlantUML e Vega-Lite não estão implementados aqui.
- **Anos.** O Typora é refinado há uma década. Este é um programa jovem e nota-se em alguns pontos.

### Onde este está à frente

- **Sem navegador incorporado.** O analisador, o renderizador, o realce de sintaxe e o motor de diagramas estão todos escritos aqui e compilados. É toda a razão do projeto, e os tempos de arranque acima são o que isso rende.
- **Diagramas sem JavaScript.** Vinte e dois tipos de Mermaid desenhados por um pintor Dart, pelo que entram no PDF e no ficheiro Word como imagens e não como um script que a máquina do leitor tenha de executar.
- **Exportação para Word sem pandoc.** Nenhum segundo programa para instalar.
- **Gratuito e de código aberto**, o que o Typora não é.

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

Transfira a versão mais recente para a sua plataforma em [Releases](https://github.com/marktext-plus/marktext-plus/releases).

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### Compilar a partir do código-fonte

> **Pré-requisitos**: Flutter 3.x+, Dart 3.x+

```bash
git clone https://github.com/marktext-plus/marktext-plus.git
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
