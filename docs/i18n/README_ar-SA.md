<div align="center">

# MarkText Plus

**محرر Markdown خفيف ومتعدد المنصات مبني بـ Flutter، أُعيد تصميمه انطلاقاً من [MarkText](https://github.com/marktext/marktext) الأصلي.**

[English](../../README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [Português (Brasil)](README_pt-BR.md)

![MarkText Plus](../../docs/v1.1.2/picture/theme/red-graphite.png)

</div>

---

## 💡 ما هو MarkText Plus؟

MarkText Plus هو **محرر Markdown حديث** أُعيد تصوره من [MarkText](https://github.com/marktext/marktext) الأصلي، وأُعيد بناؤه باستخدام Flutter لتقديم دعم حقيقي متعدد المنصات. وهو يعالج أبرز مشاكل محررات Markdown التقليدية.

- ❌ ثقيل وبطيء عند التشغيل → ✅ **سريع جداً** مع محلل مطور داخلياً
- ❌ خيارات السمات محدودة → ✅ **8 سمات جميلة** (فاتحة وداكنة)
- ❌ تجربة متعددة المنصات ضعيفة → ✅ **أداء أصلي** على Windows وmacOS وLinux
- ❌ إعداد معقد → ✅ **البدء بثلاثة أوامر فقط**

## 🚀 البدء السريع

يمكنك تشغيله خلال أقل من 30 ثانية.

```bash
git clone https://github.com/SugarFatFree/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

هذا كل شيء. سيبدأ المحرر مع مستند نموذجي جاهز للتحرير.

## ✨ الميزات

| Feature | Description |
|---------|-------------|
| **📝 ثلاثة أوضاع تحرير** | كود مصدري مع تمييز البنية، ومعاينة مباشرة، ووضع تقسيم الشاشة |
| **🎨 8 سمات جميلة** | Red Graphite وShibuya وPink Blossom وSky Blue وDark Graphite وDieci OLED وNord وMidnight |
| **🌍 12 لغة** | الإنجليزية والصينية واليابانية والكورية والألمانية والفرنسية والإيطالية والروسية والإسبانية والبرتغالية والعربية والبرتغالية البرازيلية |
| **⚡ استجابة سريعة** | محلل وعارض Markdown مطوران داخلياً بدون تبعيات ثقيلة |
| **🔍 بحث واستبدال** | بحث كامل مع دعم التعبيرات النمطية |
| **📂 شجرة ملفات** | تنقل عبر الشريط الجانبي مع دعم سحب وإفلات المجلدات |
| **⌨️ اختصارات قابلة للتخصيص** | ربطات لوحة مفاتيح قابلة للتهيئة بالكامل |
| **💾 حفظ تلقائي** | إعدادات دائمة مبنية على JSON حتى لا تفقد عملك |

## 🎨 السمات

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

## 📦 التثبيت

### تنزيل النسخ الجاهزة

نزّل أحدث إصدار لمنصتك من [Releases](https://github.com/SugarFatFree/marktext-plus/releases).

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### البناء من المصدر

> **المتطلبات المسبقة**: Flutter 3.x+، Dart 3.x+

```bash
git clone https://github.com/SugarFatFree/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

<details>
<summary><b>أوامر بناء الإصدار</b></summary>

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
<summary><b>لمستخدمي macOS: تجاوز تحذير التطبيق غير الموقّع</b></summary>

> قد يعرض macOS التحذير "لم تتمكن Apple من التحقق من أن MarkText Plus خالٍ من البرامج الضارة...". بعد نقل التطبيق إلى مجلد "التطبيقات"، شغّل الأوامر التالية.
>
> ```bash
> xattr -cr /Applications/MarkText\ Plus.app
> sudo codesign --force --deep --sign - /Applications/MarkText\ Plus.app
> ```
</details>

## 🏗️ البنية المعمارية

```
code/lib/
├── main.dart           # نقطة دخول التطبيق
├── app.dart            # MaterialApp مع ربط السمة واللغة و i18n
├── core/               # رموز السمات، الإعدادات، i18n (12 لغة)
├── models/             # TabInfo و FileNode
├── services/           # محلل Markdown، ملفات I/O، اختصارات لوحة المفاتيح
├── providers/          # إدارة الحالة عبر Riverpod
└── ui/
    ├── editor/         # محرر المصدر، عارض المعاينة، العرض المقسم
    ├── screens/        # الرئيسية، الإعدادات
    └── widgets/        # شريط القوائم، الشريط الجانبي، شريط الألسنة، شريط الحالة
```

بنية من أربع طبقات: **الواجهة** → **الحالة** (Riverpod) → **الخدمة** → **المنصة**

### تشغيل الاختبارات

```bash
cd code && flutter test
```

## 🤝 المساهمة

نرحب بالمساهمات. أرسل Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 الترخيص

ترخيص MIT — راجع [LICENSE](../../LICENSE) للتفاصيل.

مبني على مشروع [MarkText](https://github.com/marktext/marktext) من Luo Ran والمساهمين.

## 🙏 شكر وتقدير

- [MarkText](https://github.com/marktext/marktext) — المشروع الأصلي الذي ألهم هذا المحرر
- [Flutter](https://flutter.dev) — إطار العمل متعدد المنصات
- جميع المكتبات مفتوحة المصدر المستخدمة في هذا المشروع
