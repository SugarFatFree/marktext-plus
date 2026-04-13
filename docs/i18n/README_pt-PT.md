[English](../../code/README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

# MarkText Plus

Um editor Markdown leve e multiplataforma construído com Flutter, redesenhado a partir do original [MarkText](https://github.com/marktext/marktext).

## Funcionalidades

- **Suporte multilingue**: 12 idiomas incluindo inglês, chinês, japonês, coreano, alemão, francês, italiano, russo, espanhol, português, árabe e português brasileiro
- **Leve e rápido**: Analisador e renderizador Markdown desenvolvidos internamente para desempenho ótimo
- **Configuração persistente**: Armazenamento de configurações baseado em JSON com gravação automática
- **Edição em painel duplo**: Modos de código-fonte, pré-visualização e vista dividida
- **Multiplataforma**: Funciona no Windows, macOS e Linux
- **Interface moderna**: Interface limpa com 5 temas integrados
- **Realce de sintaxe**: Realce de sintaxe Markdown em tempo real no modo fonte

## Instalação

### Pré-requisitos

- Flutter 3.x ou superior
- Dart 3.x ou superior

### Compilar a partir do código-fonte

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get
flutter run
```

### Versões de lançamento

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## Desenvolvimento

### Estrutura do projeto

```
code/
├── lib/
│   ├── main.dart              # Ponto de entrada da aplicação
│   ├── app.dart               # Configuração MaterialApp
│   ├── core/                  # Configuração principal e temas
│   ├── models/                # Modelos de dados
│   ├── services/              # Serviços de lógica de negócio
│   ├── providers/             # Gestão de estado Riverpod
│   └── ui/                    # Componentes UI
└── test/                      # Testes unitários e de widgets
```

### Arquitetura

Arquitetura de quatro camadas:
- **Camada UI**: Widgets e ecrãs Flutter
- **Camada de estado**: Provedores Riverpod para gestão de estado
- **Camada de serviço**: Lógica de negócio e processamento de dados
- **Camada de plataforma**: E/S de ficheiros e integração do sistema

### Executar testes

```bash
flutter test
```

## Contribuir

Contribuições são bem-vindas! Sinta-se à vontade para enviar um Pull Request.

## Licença

Este projeto está licenciado sob a Licença MIT — consulte o ficheiro [LICENSE](../../code/LICENSE) para mais detalhes.

Baseado no projeto [MarkText](https://github.com/marktext/marktext) de Luo Ran e colaboradores.

## Agradecimentos

- O projeto MarkText original e os seus colaboradores
- As equipas Flutter e Dart
- Todas as bibliotecas de código aberto utilizadas neste projeto
