[English](../../README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

# MarkText Plus

Un editeur Markdown leger et multiplateforme construit avec Flutter, repense a partir de l'original [MarkText](https://github.com/marktext/marktext).

## Fonctionnalites

- **Support multilingue** : 12 langues dont l'anglais, le chinois, le japonais, le coreen, l'allemand, le francais, l'italien, le russe, l'espagnol, le portugais, l'arabe et le portugais bresilien
- **Leger et rapide** : Analyseur et moteur de rendu Markdown developpes en interne pour des performances optimales
- **Configuration persistante** : Stockage des parametres base sur JSON avec sauvegarde automatique
- **Edition double panneau** : Modes code source, apercu et vue partagee
- **Multiplateforme** : Fonctionne sur Windows, macOS et Linux
- **Interface moderne** : Interface epuree avec 5 themes integres
- **Coloration syntaxique** : Coloration syntaxique Markdown en temps reel en mode source

## Installation

### Prerequis

- Flutter 3.x ou superieur
- Dart 3.x ou superieur

### Compiler depuis les sources

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get
flutter run
```

### Builds de publication

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## Développement

### Structure du projet

```
code/
├── lib/
│   ├── main.dart              # Point d'entrée de l'application
│   ├── app.dart               # Configuration MaterialApp
│   ├── core/                  # Configuration de base et thèmes
│   ├── models/                # Modèles de données
│   ├── services/              # Services de logique métier
│   ├── providers/             # Gestion d'état Riverpod
│   └── ui/                    # Composants UI
└── test/                      # Tests unitaires et de widgets
```

### Architecture

Architecture à quatre couches :
- **Couche UI** : Widgets et écrans Flutter
- **Couche État** : Providers Riverpod pour la gestion d'état
- **Couche Service** : Logique métier et traitement des données
- **Couche Plateforme** : E/S fichiers et intégration système

### Exécuter les tests

```bash
flutter test
```

## Contribuer

Les contributions sont les bienvenues ! N'hesitez pas a soumettre une Pull Request.

## Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](../../LICENSE) pour plus de details.

Basé sur [MarkText](https://github.com/marktext/marktext) par Luo Ran et les contributeurs.

## Remerciements

- Le projet original MarkText et ses contributeurs
- Les équipes Flutter et Dart
- Toutes les bibliothèques open source utilisées dans ce projet
