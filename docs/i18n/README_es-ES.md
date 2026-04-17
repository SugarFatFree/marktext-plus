<div align="center">

# MarkText Plus

**Un editor Markdown ligero y multiplataforma reconstruido con Flutter, reinventado a partir del [MarkText](https://github.com/marktext/marktext) original.**

[English](../../README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

![MarkText Plus](../../docs/v1.1.2/picture/theme/red-graphite.png)

</div>

---

## 💡 ¿Qué es MarkText Plus?

MarkText Plus es un **editor Markdown moderno**, reimaginado a partir del [MarkText](https://github.com/marktext/marktext) original y reconstruido con Flutter para ofrecer una experiencia multiplataforma real. Resuelve varios problemas habituales de los editores Markdown tradicionales.

- ❌ Pesado y lento al iniciar → ✅ **Muy rápido** con un parser propio
- ❌ Pocas opciones de tema → ✅ **8 temas hermosos** (claros y oscuros)
- ❌ Mala experiencia multiplataforma → ✅ **Rendimiento nativo** en Windows, macOS y Linux
- ❌ Configuración compleja → ✅ **Listo en 3 comandos**

## 🚀 Inicio rápido

Listo en menos de 30 segundos.

```bash
git clone https://github.com/SugarFatFree/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

Eso es todo. El editor se abrirá con un documento de ejemplo listo para editar.

## ✨ Características

| Feature | Description |
|---------|-------------|
| **📝 Tres modos de edición** | Código fuente con resaltado de sintaxis, vista previa en vivo y vista dividida |
| **🎨 8 temas hermosos** | Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight |
| **🌍 12 idiomas** | Inglés, chino, japonés, coreano, alemán, francés, italiano, ruso, español, portugués, árabe y portugués brasileño |
| **⚡ Respuesta rápida** | Parser y renderizador Markdown propios, sin dependencias pesadas |
| **🔍 Buscar y reemplazar** | Búsqueda completa con soporte para expresiones regulares |
| **📂 Árbol de archivos** | Navegación lateral con soporte para arrastrar y soltar carpetas |
| **⌨️ Atajos personalizables** | Asignaciones de teclado totalmente configurables |
| **💾 Guardado automático** | Configuración persistente basada en JSON para no perder tu trabajo |

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

## 📦 Instalación

### Descargar binarios precompilados

Descarga la última versión para tu plataforma desde [Releases](https://github.com/SugarFatFree/marktext-plus/releases).

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### Compilar desde el código fuente

> **Requisitos previos**: Flutter 3.x+, Dart 3.x+

```bash
git clone https://github.com/SugarFatFree/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

<details>
<summary><b>Comandos de compilación de lanzamiento</b></summary>

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
<summary><b>Usuarios de macOS: omitir la advertencia de app sin firmar</b></summary>

> macOS puede mostrar la advertencia "Apple no pudo verificar que MarkText Plus esté libre de software malicioso...". Después de mover la app a la carpeta "Aplicaciones", ejecuta lo siguiente.
>
> ```bash
> xattr -cr /Applications/MarkText\ Plus.app
> sudo codesign --force --deep --sign - /Applications/MarkText\ Plus.app
> ```
</details>

## 🏗️ Arquitectura

```
code/lib/
├── main.dart           # Punto de entrada de la aplicación
├── app.dart            # MaterialApp con enlace de tema, locale e i18n
├── core/               # Tokens de tema, configuración, i18n (12 idiomas)
├── models/             # TabInfo, FileNode
├── services/           # Parser Markdown, archivo I/O, atajos de teclado
├── providers/          # Gestión de estado Riverpod
└── ui/
    ├── editor/         # Editor fuente, render de vista previa, vista dividida
    ├── screens/        # Inicio, Ajustes
    └── widgets/        # Barra de menú, barra lateral, barra de pestañas, barra de estado
```

Arquitectura de cuatro capas: **UI** → **Estado** (Riverpod) → **Servicio** → **Plataforma**

### Ejecutar pruebas

```bash
cd code && flutter test
```

## 🤝 Contribuir

Las contribuciones son bienvenidas. Envía tu Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 Licencia

Licencia MIT — consulta [LICENSE](../../LICENSE) para más detalles.

Basado en [MarkText](https://github.com/marktext/marktext) de Luo Ran y colaboradores.

## 🙏 Agradecimientos

- [MarkText](https://github.com/marktext/marktext) — el proyecto original que inspiró este editor
- [Flutter](https://flutter.dev) — el framework multiplataforma
- Todas las bibliotecas de código abierto utilizadas en este proyecto
