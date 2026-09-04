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
git clone https://github.com/marktext-plus/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

Eso es todo. El editor se abrirá con un documento de ejemplo listo para editar.

## ✨ Características

### Edición

| Función | Descripción |
|---------|-------------|
| **📝 Tres modos de edición** | Código fuente con resaltado, vista previa en vivo y vista dividida arrastrable |
| **✏️ Editar en la vista previa** | Haz doble clic en un bloque para editar Markdown en su sitio; `Esc` descarta y las casillas se marcan con un clic |
| **⌨️ Paleta de comandos y menú `/`** | `Ctrl+Shift+P` ejecuta cualquier comando y `/` inserta un bloque |
| **📊 Edición de tablas** | Inserta y elimina filas y columnas y alinea cada columna |
| **🔀 Mover bloques** | Sube o baja un párrafo, lista o bloque cercado con un atajo |
| **🔍 Buscar y reemplazar** | Busca palabras completas y expresiones regulares y reemplaza todo el documento |
| **🔗 Pegar un enlace** | Selecciona palabras y pega una dirección web para convertirlas en enlace |
| **📐 Alinear tablas** | Recoloca las barras sin cambiar el contenido; los caracteres CJK cuentan como dos columnas |
| **🖼️ Imágenes** | Pega o arrastra una imagen; se guarda junto al documento y queda enlazada |

### Renderizado

| Función | Descripción |
|---------|-------------|
| **📈 Diagramas Mermaid** | **22 tipos** dibujados con Dart puro, **sin WebView** |
| **∑ Matemáticas** | Fórmulas LaTeX en línea y en bloque con renderizado compatible con KaTeX |
| **📋 CommonMark + GFM** | Tablas, tareas, tachado, autolinks, notas al pie y anotaciones `<ruby>` |
| **🎨 8 temas** | Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight |
| **🌍 12 idiomas** | Inglés, chino, japonés, coreano, alemán, francés, italiano, ruso, español, portugués, árabe y portugués brasileño; árabe en RTL |

### Archivos y salida

| Función | Descripción |
|---------|-------------|
| **📤 Exportación** | HTML, PDF y Word `.docx`; los diagramas y el código resaltado viajan dentro del HTML, mientras las matemáticas siguen usando KaTeX |
| **🔤 Codificaciones** | Detecta UTF-8, UTF-16 y GBK al abrir, con o sin BOM, y guarda usando la codificación encontrada |
| **📂 Árbol de archivos** | Navegación lateral con carpetas arrastrables |
| **👀 Cambios externos** | Detecta mientras está abierto si otro programa modifica el documento |
| **💾 Guardado seguro** | Escrituras atómicas para evitar archivos incompletos si se interrumpe el guardado |
| **⌨️ Atajos personalizables** | Asignaciones de teclado completamente configurables |

### Diseñado para seguir siendo ligero

| | |
|---------|-------------|
| **🧩 Complementos abiertos** | Un archivo Lua o JavaScript, sin SDK y sin compilar, en un espacio aislado y limitado a los permisos que declaró. Se encuentran en [GitHub Topic: `marktext-plus-plugin`](https://github.com/topics/marktext-plus-plugin); cada uno va marcado como Comunidad/sin verificar |
| **⚡ Arranque rápido** | Sin navegador incrustado ni framework de editor: 23 dependencias directas |
| **📄 Archivos grandes** | Análisis, resaltado y búsqueda en una sola pasada, con presupuestos que hacen fallar las pruebas. Por encima de 128 KB el resaltado se detiene: es el último tamaño que abre en torno a un segundo. Se sigue editando, y los colores vuelven si el archivo mengua |
| **🧪 Probado** | 2417 pruebas para el parser, los exportadores, los providers, los motores de complementos y los widgets del editor |

### Complementos

Escritos en Lua o JavaScript: un archivo y un manifiesto, sin compilar, y el mismo archivo funciona en las tres plataformas. Un complemento puede tener varios archivos, y `require` sólo llega dentro de su propio directorio.

| Función | Descripción |
|---------|-------------|
| **🔐 Permisos** | Declarados en el manifiesto, mostrados antes de instalar y **exigidos**. VS Code e IntelliJ muestran una lista y luego confían; aquí nadie revisa nada, así que comprueba el editor. A un complemento que consulta el modelo sin `ai.chat` se le dice que no, y a ti se te dice que lo intentó |
| **🪟 Cuadros** | El editor ya divide una pestaña entre fuente y vista previa; esa división se ofrece hacia fuera. Hasta cuatro celdas, divisores que se arrastran, y nada dibujado para una celda que nadie llenó |
| **✍️ Escribir de vuelta** | Un complemento puede reescribir lo que seleccionaste, después de enseñártelo. El resultado llega con un botón Aplicar, y aplicar pasa por el historial del editor: deshacer lo devuelve |
| **⚙️ Ajustes propios** | El editor dibuja la página a partir de lo que el complemento declaró: un interruptor para un interruptor, un campo oculto para un secreto. Los complementos aportan datos, nunca controles |
| **🌍 Idiomas propios** | Un complemento trae los idiomas que su autor quiera, al margen de los doce que habla el editor |
| **🔑 Nunca tus claves** | El editor guarda las credenciales y hace la petición. El complemento aporta la instrucción y recibe texto |

Empieza por el [SDK de complementos](https://github.com/marktext-plus-plugins/marktext-plus-plugin-sdk): tres ejemplos completos para copiar y documentación en once idiomas.

### Para agentes de IA

Un servidor MCP opcional, **apagado hasta que lo enciendas**: abre un puerto en tu máquina, y quien llegue a él podrá leer tus documentos y manejar tu editor. Por eso lo enciendes tú, y lleva un token que puedes regenerar.

| Herramienta | Descripción |
|---------|-------------|
| **`read_logs`** | El registro del editor y el de sus complementos, filtrable por complemento y por gravedad |
| **`screenshot`** | La ventana tal como está |
| **`record_gif`** | Cinco segundos como mucho, para mirar una animación |
| **`get_state`** | Qué hay abierto: pestañas, modo de vista, complementos instalados, cuadros llenos |
| **`control`** | Abrir y cerrar pestañas, cambiar de modo, escribir contenido, cerrar un cuadro |

## ⚖️ Comparativa

Frente al editor del que este es una reinterpretación, y frente al más conocido del sector. Todo lo de la columna de MarkText se leyó de su código fuente en `v0.20.0-dev`; la columna de Typora procede de su documentación publicada, ya que es de código cerrado y no puede comprobarse del mismo modo.

Los tiempos de arranque provienen de un único equipo con Windows, con los tres programas en él. Los de este programa están instrumentados —escribe su propio `startup-trace.log`, y las cifras son de cuatro arranques—, mientras que los otros dos se cronometraron a mano: tómelos como el par más tosco. La mayor parte del arranque aquí no es código propio: de los 0,7 s, unos 0,5 s corresponden a Windows cargando el ejecutable y al motor de Flutter iniciándose, y 0,15 s a todo lo que hace el editor.

| | **MarkText Plus** | **MarkText** (original) | **Typora** |
|---|---|---|---|
| **Entorno de ejecución** | Flutter — compilado, sin navegador incrustado | Electron 42 | Electron |
| **Arranque** (hasta ver el documento) | ~0,7 s en caliente, ~1,4 s en frío | 2–3 s | 2–3 s |
| **Dependencias directas** | 22 | 56 (paquete desktop) | código cerrado |
| **Licencia** | MIT, gratuito | MIT, gratuito | De pago, código cerrado |
| **Edición** | Fuente, vista previa y una vista dividida cuyas mitades se siguen; los bloques se editan en su sitio dentro de la vista previa | Vista previa en vivo (WYSIWYG), más un modo de código | Vista previa en vivo (WYSIWYG), más un modo de código |
| **Diagramas** | 22 tipos de Mermaid, dibujados en Dart sin WebView | Mermaid, flowchart.js, Vega-Lite, PlantUML — todos mediante JavaScript | Mermaid, flowchart.js, js-sequence, PlantUML |
| **Matemáticas** | Compatible con KaTeX | KaTeX | KaTeX |
| **Exportación** | HTML, PDF, Word — todo integrado | HTML, PDF, Markdown; más formatos si pandoc está instalado | Muchos formatos, la mayoría mediante pandoc |
| **Temas** | 8 | 32 | Muchos, y una amplia colección de la comunidad |
| **Idiomas de la interfaz** | 12 | 10 | Varios |
| **Plataformas** | Windows, macOS, Linux (x64 y arm64) | Windows, macOS, Linux | Windows, macOS, Linux |

### En qué van por delante los demás

Conviene decirlo con claridad, porque una comparativa que solo halaga a quien la escribe no merece leerse.

- **Vista previa en vivo.** Typora y MarkText editan directamente el documento ya compuesto, sin modo que cambiar. Este editor ofrece tres paneles y permite abrir un bloque en su sitio; es otra cosa, y para quien viene de Typora es la diferencia que nota primero.
- **Temas.** Treinta y dos frente a ocho, y Typora tiene años de CSS de la comunidad a su espalda.
- **Amplitud de diagramas.** PlantUML y Vega-Lite no están implementados aquí.
- **Años.** Typora lleva una década puliéndose. Este es un programa joven y en algunos puntos se nota.

### En qué va por delante este

- **Sin navegador incrustado.** El analizador, el renderizador, el resaltado de sintaxis y el motor de diagramas están escritos aquí y compilados. Esa es toda la razón del proyecto, y los tiempos de arranque de arriba son lo que compra.
- **Diagramas sin JavaScript.** Veintidós tipos de Mermaid dibujados por un pintor de Dart, de modo que entran en el PDF y en el archivo de Word como imágenes y no como un script que deba ejecutar la máquina del lector.
- **Exportación a Word sin pandoc.** Ningún segundo programa que instalar.
- **Gratuito y de código abierto**, cosa que Typora no es.

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

Descarga la última versión para tu plataforma desde [Releases](https://github.com/marktext-plus/marktext-plus/releases).

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### Compilar desde el código fuente

> **Requisitos previos**: Flutter 3.x+, Dart 3.x+

```bash
git clone https://github.com/marktext-plus/marktext-plus.git
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
