[English](../../README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [Português (Brasil)](README_pt-BR.md)

# MarkText Plus

محرر Markdown خفيف الوزن ومتعدد المنصات مبني بـ Flutter، معاد تصميمه من [MarkText](https://github.com/marktext/marktext) الأصلي.

## الميزات

- **دعم متعدد اللغات**: 12 لغة بما في ذلك الإنجليزية والصينية واليابانية والكورية والألمانية والفرنسية والإيطالية والروسية والإسبانية والبرتغالية والعربية والبرتغالية البرازيلية
- **خفيف وسريع**: محلل ومحرك عرض Markdown مطور داخلياً لأداء مثالي
- **تكوين دائم**: تخزين الإعدادات بتنسيق JSON مع الحفظ التلقائي
- **تحرير بلوحة مزدوجة**: أوضاع الكود المصدري والمعاينة والعرض المقسم
- **متعدد المنصات**: يعمل على Windows وmacOS وLinux
- **واجهة حديثة**: واجهة نظيفة مع 5 سمات مدمجة
- **تمييز بناء الجملة**: تمييز بناء جملة Markdown في الوقت الفعلي في وضع المصدر

## التثبيت

### المتطلبات المسبقة

- Flutter 3.x أو أعلى
- Dart 3.x أو أعلى

### البناء من المصدر

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get
flutter run
```

### إصدارات الإنتاج

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## التطوير

### هيكل المشروع

```
code/
├── lib/
│   ├── main.dart              # نقطة دخول التطبيق
│   ├── app.dart               # تكوين MaterialApp
│   ├── core/                  # التكوين الأساسي والسمات
│   ├── models/                # نماذج البيانات
│   ├── services/              # خدمات منطق الأعمال
│   ├── providers/             # إدارة الحالة Riverpod
│   └── ui/                    # مكونات واجهة المستخدم
└── test/                      # اختبارات الوحدات والويدجت
```

### البنية المعمارية

بنية معمارية من أربع طبقات:
- **طبقة واجهة المستخدم**: ويدجت وشاشات Flutter
- **طبقة الحالة**: مزودات Riverpod لإدارة الحالة
- **طبقة الخدمة**: منطق الأعمال ومعالجة البيانات
- **طبقة المنصة**: إدخال/إخراج الملفات وتكامل النظام

### تشغيل الاختبارات

```bash
flutter test
```

## المساهمة

المساهمات مرحب بها! لا تتردد في تقديم طلب سحب.

## الترخيص

هذا المشروع مرخص بموجب رخصة MIT — راجع ملف [LICENSE](../../LICENSE) للتفاصيل.

مبني على مشروع [MarkText](https://github.com/marktext/marktext) بواسطة Luo Ran والمساهمين.

## شكر وتقدير

- مشروع MarkText الأصلي والمساهمين فيه
- فريقا Flutter وDart
- جميع المكتبات مفتوحة المصدر المستخدمة في هذا المشروع
