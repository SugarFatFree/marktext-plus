<div align="center">

# MarkText Plus

**Un editeur Markdown leger et multiplateforme reconstruit avec Flutter, inspire de l’original [MarkText](https://github.com/marktext/marktext).**

[English](../../README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

![MarkText Plus](../../docs/v1.1.2/picture/theme/red-graphite.png)

</div>

---

## 💡 Qu’est-ce que MarkText Plus ?

MarkText Plus est un **editeur Markdown moderne**, reinvente a partir de [MarkText](https://github.com/marktext/marktext) et reconstruit avec Flutter pour une vraie experience multiplateforme. Il corrige les points faibles habituels des editeurs Markdown traditionnels.

- ❌ Lourd et lent au demarrage → ✅ **Ultra rapide** avec un parseur maison
- ❌ Peu d’options de theme → ✅ **8 beaux themes** (clair & sombre)
- ❌ Experience multiplateforme mediocre → ✅ **Performances natives** sur Windows, macOS et Linux
- ❌ Configuration compliquee → ✅ **Demarrage en 3 commandes**

## 🚀 Demarrage rapide

Pret en moins de 30 secondes.

```bash
git clone https://github.com/marktext-plus/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

C’est tout. L’editeur se lance avec un document d’exemple pret a etre modifie.

## ✨ Fonctionnalites

### Édition

| Fonction | Description |
|---------|-------------|
| **📝 Trois modes d’édition** | Code source avec coloration, aperçu en direct et vue partagée déplaçable |
| **✏️ Modifier dans l’aperçu** | Double-cliquez sur un bloc pour ouvrir son Markdown sur place ; `Esc` annule et les cases se cochent en un clic |
| **⌨️ Palette de commandes et menu `/`** | `Ctrl+Shift+P` exécute une commande et `/` insère un bloc |
| **📊 Édition des tableaux** | Insérer ou supprimer lignes et colonnes, puis aligner chaque colonne |
| **🔀 Déplacer des blocs** | Monter ou descendre un paragraphe, une liste ou une clôture avec un raccourci |
| **🔍 Rechercher et remplacer** | Rechercher des mots entiers ou des expressions régulières dans le document |
| **🔗 Coller un lien** | Sélectionner des mots puis coller une adresse Web pour créer un lien |
| **📐 Aligner un tableau** | Réaligner les barres sans modifier le contenu ; un caractère CJK vaut deux colonnes |
| **🖼️ Images** | Coller ou déposer une image pour la ranger à côté du document et la lier |

### Rendu

| Fonction | Description |
|---------|-------------|
| **📈 Diagrammes Mermaid** | **22 types** dessinés en Dart pur, **sans WebView** |
| **∑ Mathématiques** | Formules LaTeX en ligne et en bloc avec un rendu compatible KaTeX |
| **📋 CommonMark + GFM** | Tableaux, tâches, barré, autoliens, notes de bas de page et annotations `<ruby>` |
| **🎨 8 thèmes** | Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight |
| **🌍 12 langues** | Anglais, chinois, japonais, coréen, allemand, français, italien, russe, espagnol, portugais, arabe et portugais brésilien ; arabe en RTL |

### Fichiers et sortie

| Fonction | Description |
|---------|-------------|
| **📤 Export** | HTML, PDF et Word `.docx` ; diagrammes et code sont intégrés au HTML, tandis que les mathématiques utilisent encore KaTeX |
| **🔤 Encodages** | UTF-8, UTF-16 et GBK détectés à l’ouverture, avec ou sans BOM, puis réécrits dans le même encodage |
| **📂 Arborescence** | Navigation latérale avec glisser-déposer de dossiers |
| **👀 Modifications externes** | Les modifications d’un autre programme sont détectées pendant l’ouverture |
| **💾 Enregistrement sûr** | Écritures atomiques pour éviter un fichier incomplet après interruption |
| **⌨️ Raccourcis personnalisables** | Raccourcis clavier entièrement configurables |

### Conçu pour rester léger

| | |
|---------|-------------|
| **🧩 Open plugins** | Discover public plugins through GitHub Topic `marktext-plus-plugin`; every plugin is labelled Community/Unverified and runs out of process |
| **⚡ Démarrage rapide** | Aucun navigateur intégré ni framework d’édition, 22 dépendances directes |
| **📄 Gros fichiers** | Analyse, coloration et recherche en un seul passage, avec des budgets testés |
| **🧪 Testé** | 2021 tests couvrant le parseur, les exporteurs, les providers et les widgets |

## ⚖️ Comparaison

Face à l'éditeur dont celui-ci est la refonte, et face au plus connu du domaine. Tout ce qui figure dans la colonne MarkText a été lu dans son code source en `v0.20.0-dev` ; la colonne Typora provient de sa documentation publiée, puisqu'il est propriétaire et ne peut être vérifié de la même façon.

Les temps de démarrage viennent d'une seule machine Windows, les trois programmes dessus. Ceux de ce programme sont instrumentés — il écrit son propre `startup-trace.log`, et les chiffres portent sur quatre lancements — tandis que les deux autres ont été chronométrés à la main : voyez-les comme la paire la plus grossière. L'essentiel du démarrage ici n'est pas son propre code : sur les 0,7 s, environ 0,5 s reviennent à Windows chargeant l'exécutable et au moteur Flutter qui démarre, et 0,15 s à tout ce que fait l'éditeur lui-même.

| | **MarkText Plus** | **MarkText** (original) | **Typora** |
|---|---|---|---|
| **Environnement d'exécution** | Flutter — compilé, sans navigateur embarqué | Electron 42 | Electron |
| **Démarrage** (jusqu'au document affiché) | ~0,7 s à chaud, ~1,4 s à froid | 2–3 s | 2–3 s |
| **Dépendances directes** | 22 | 56 (paquet desktop) | propriétaire |
| **Licence** | MIT, gratuit | MIT, gratuit | Payant, propriétaire |
| **Édition** | Source, aperçu, et une vue partagée dont les deux moitiés se suivent ; les blocs se modifient sur place dans l'aperçu | Aperçu en direct (WYSIWYG), plus un mode source | Aperçu en direct (WYSIWYG), plus un mode source |
| **Diagrammes** | 22 types Mermaid, dessinés en Dart sans WebView | Mermaid, flowchart.js, Vega-Lite, PlantUML — tous via JavaScript | Mermaid, flowchart.js, js-sequence, PlantUML |
| **Mathématiques** | Compatible KaTeX | KaTeX | KaTeX |
| **Export** | HTML, PDF, Word — tout est intégré | HTML, PDF, Markdown ; davantage de formats si pandoc est installé | De nombreux formats, la plupart via pandoc |
| **Thèmes** | 8 | 32 | Nombreux, avec une vaste collection communautaire |
| **Langues de l'interface** | 12 | 10 | Plusieurs |
| **Plateformes** | Windows, macOS, Linux (x64 et arm64) | Windows, macOS, Linux | Windows, macOS, Linux |

### Là où les autres sont devant

Cela mérite d'être dit clairement : une comparaison qui ne flatte que celui qui l'écrit ne vaut pas la lecture.

- **L'aperçu en direct.** Typora et MarkText modifient tous deux le document rendu, sans mode à changer. Cet éditeur propose trois volets et permet d'ouvrir un bloc sur place ; c'est autre chose, et pour qui a l'habitude de Typora, c'est la différence qui saute aux yeux en premier.
- **Les thèmes.** Trente-deux contre huit, et Typora dispose de années de CSS communautaire.
- **L'étendue des diagrammes.** PlantUML et Vega-Lite ne sont pas implémentés ici.
- **Les années.** Typora est affiné depuis une décennie. Celui-ci est un jeune programme et cela se voit par endroits.

### Là où celui-ci est devant

- **Aucun navigateur embarqué.** L'analyseur, le rendu, la coloration syntaxique et le moteur de diagrammes sont tous écrits ici et compilés. C'est toute la raison d'être du projet, et les temps de démarrage ci-dessus sont ce qu'elle rapporte.
- **Des diagrammes sans JavaScript.** Vingt-deux types Mermaid dessinés par un peintre Dart : ils entrent donc dans le PDF et le fichier Word comme des images, et non comme un script que la machine du lecteur doit exécuter.
- **Export Word sans pandoc.** Aucun second programme à installer.
- **Gratuit et libre**, ce que Typora n'est pas.

## 🎨 Themes

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

## 📦 Installation

### Telecharger les binaires precompiles

Telechargez la derniere version adaptee a votre plateforme depuis [Releases](https://github.com/marktext-plus/marktext-plus/releases).

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### Compiler depuis les sources

> **Prerequis** : Flutter 3.x+, Dart 3.x+

```bash
git clone https://github.com/marktext-plus/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

<details>
<summary><b>Commandes de build de release</b></summary>

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
<summary><b>Utilisateurs macOS : contourner l’avertissement d’application non signee</b></summary>

> macOS peut afficher l’avertissement "Apple n’a pas pu verifier que MarkText Plus ne contient pas de logiciel malveillant...". Apres avoir glisse l’application dans le dossier "Applications", executez les commandes suivantes.
>
> ```bash
> xattr -cr /Applications/MarkText\ Plus.app
> sudo codesign --force --deep --sign - /Applications/MarkText\ Plus.app
> ```
</details>

## 🏗️ Architecture

```
code/lib/
├── main.dart           # Point d’entree de l’application
├── app.dart            # MaterialApp avec liaison theme/locale/i18n
├── core/               # Jetons de theme, configuration, i18n (12 langues)
├── models/             # TabInfo, FileNode
├── services/           # Parseur Markdown, E/S fichiers, raccourcis clavier
├── providers/          # Gestion d’etat Riverpod
└── ui/
    ├── editor/         # Editeur source, rendu de l’aperçu, vue partagee
    ├── screens/        # Accueil, Parametres
    └── widgets/        # Barre de menus, barre laterale, barre d’onglets, barre d’etat
```

Architecture a quatre couches : **UI** → **Etat** (Riverpod) → **Service** → **Plateforme**

### Executer les tests

```bash
cd code && flutter test
```

## 🤝 Contribuer

Les contributions sont les bienvenues. Envoyez vos Pull Requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 Licence

Licence MIT - voir [LICENSE](../../LICENSE) pour les details.

Base sur [MarkText](https://github.com/marktext/marktext) de Luo Ran et des contributeurs.

## 🙏 Remerciements

- [MarkText](https://github.com/marktext/marktext) — le projet original qui a inspire cet editeur
- [Flutter](https://flutter.dev) — le framework multiplateforme
- Toutes les bibliotheques open source utilisees dans ce projet
