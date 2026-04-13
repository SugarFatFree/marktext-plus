[English](../../code/README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

# MarkText Plus

Un editor Markdown ligero y multiplataforma construido con Flutter, reimaginado del [MarkText](https://github.com/marktext/marktext) original.

## Características

- **Soporte multiidioma**: 12 idiomas incluyendo inglés, chino, japonés, coreano, alemán, francés, italiano, ruso, español, portugués, árabe y portugués brasileño
- **Ligero y rápido**: Analizador y renderizador Markdown propios para un rendimiento óptimo
- **Configuración persistente**: Almacenamiento de configuración basado en JSON con guardado automático
- **Edición de doble panel**: Modos de código fuente, vista previa y vista dividida
- **Multiplataforma**: Funciona en Windows, macOS y Linux
- **Interfaz moderna**: Interfaz limpia con 5 temas integrados
- **Resaltado de sintaxis**: Resaltado de sintaxis Markdown en tiempo real en modo fuente

## Instalación

### Requisitos previos

- Flutter 3.x o superior
- Dart 3.x o superior

### Compilar desde el código fuente

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get
flutter run
```

### Compilaciones de lanzamiento

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## Desarrollo

### Estructura del proyecto

```
code/
├── lib/
│   ├── main.dart              # Punto de entrada de la aplicación
│   ├── app.dart               # Configuración de MaterialApp
│   ├── core/                  # Configuración principal y temas
│   ├── models/                # Modelos de datos
│   ├── services/              # Servicios de lógica de negocio
│   ├── providers/             # Gestión de estado Riverpod
│   └── ui/                    # Componentes UI
└── test/                      # Pruebas unitarias y de widgets
```

### Arquitectura

Arquitectura de cuatro capas:
- **Capa UI**: Widgets y pantallas Flutter
- **Capa de estado**: Proveedores Riverpod para gestión de estado
- **Capa de servicio**: Lógica de negocio y procesamiento de datos
- **Capa de plataforma**: E/S de archivos e integración del sistema

### Ejecutar pruebas

```bash
flutter test
```

## Contribuir

¡Las contribuciones son bienvenidas! No dudes en enviar un Pull Request.

## Licencia

Este proyecto está licenciado bajo la Licencia MIT — consulta el archivo [LICENSE](../../code/LICENSE) para más detalles.

Basado en el proyecto [MarkText](https://github.com/marktext/marktext) de Luo Ran y colaboradores.

## Agradecimientos

- El proyecto MarkText original y sus colaboradores
- Los equipos de Flutter y Dart
- Todas las bibliotecas de código abierto utilizadas en este proyecto
