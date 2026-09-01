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

### التحرير

| الميزة | الوصف |
|---------|-------------|
| **📝 ثلاثة أوضاع للتحرير** | المصدر مع تمييز البنية، والمعاينة المباشرة، ووضع تقسيم الشاشة القابل للسحب |
| **✏️ التحرير في المعاينة** | انقر مرتين على كتلة لتحرير Markdown في مكانها؛ ‏`Esc` يلغي، ومربعات المهام تُحدَّث بنقرة واحدة |
| **⌨️ لوحة الأوامر وقائمة `/`** | استخدم `Ctrl+Shift+P` لتشغيل أي أمر، أو `/` لإدراج كتلة |
| **📊 تحرير الجداول** | إدراج وحذف الصفوف والأعمدة وضبط محاذاة كل عمود |
| **🔀 نقل الكتل** | تحريك فقرة أو قائمة أو سياج إلى أعلى أو أسفل المستند باختصار واحد |
| **🔍 البحث والاستبدال** | البحث عن الكلمات الكاملة والتعبيرات النمطية والاستبدال في المستند كله |
| **🔗 لصق رابط** | حدّد كلمات ثم الصق عنوان ويب لتحويلها إلى رابط |
| **📐 تنسيق جدول** | محاذاة فواصل الجدول دون تغيير محتواه؛ الحرف الصيني يُحسب بعرض عمودين |
| **🖼️ الصور** | الصق صورة أو أسقطها لتُحفظ بجانب المستند وتُربط به |

### العرض

| الميزة | الوصف |
|---------|-------------|
| **📈 مخططات Mermaid** | **22 نوعًا** مرسومة بـ Dart الخالص، **من دون WebView** |
| **∑ الرياضيات** | صيغ LaTeX داخلية وكتلية بعرض متوافق مع KaTeX |
| **📋 CommonMark + GFM** | جداول وقوائم مهام وشطب وروابط تلقائية وحواشي وتعليقات `<ruby>` |
| **🎨 8 سمات** | Red Graphite وShibuya وPink Blossom وSky Blue وDark Graphite وDieci OLED وNord وMidnight |
| **🌍 12 لغة** | الإنجليزية والصينية واليابانية والكورية والألمانية والفرنسية والإيطالية والروسية والإسبانية والبرتغالية والعربية والبرتغالية البرازيلية، مع RTL للعربية |

### الملفات والإخراج

| الميزة | الوصف |
|---------|-------------|
| **📤 التصدير** | HTML وPDF وWord `.docx`؛ الرسوم والشفرة المميزة مضمّنة في HTML، بينما تستخدم الرياضيات KaTeX |
| **🔤 الترميزات** | اكتشاف UTF-8 وUTF-16 وGBK عند الفتح، مع أو بدون BOM، والكتابة بالترميز المكتشف |
| **📂 شجرة الملفات** | تنقل جانبي مع دعم سحب وإفلات المجلدات |
| **👀 التغييرات الخارجية** | يلاحظ تعديل المستند بواسطة برنامج آخر أثناء فتحه |
| **💾 الحفظ الآمن** | كتابة ذرية تمنع ترك ملف ناقص بعد انقطاع الحفظ |
| **⌨️ اختصارات قابلة للتخصيص** | إعداد روابط لوحة المفاتيح بالكامل |

### مصمم ليبقى خفيفًا

| | |
|---------|-------------|
| **⚡ بدء سريع** | بلا متصفح مضمّن أو إطار تحرير، و22 تبعية مباشرة |
| **📄 ملفات كبيرة** | تحليل وتمييز وبحث بمرور واحد، مع اختبارات أداء محددة |
| **🧪 مختبر جيد** | 2012 اختبارًا تغطي المحلل والمصدّرات والـ providers وواجهات المحرر |

## ⚖️ المقارنة

مقارنةً بالمحرِّر الذي أُعيد تصوُّره انطلاقًا منه، وبأشهر محرِّر في هذا المجال. كل ما في عمود MarkText قُرئ من شفرته المصدرية عند `v0.20.0-dev`؛ أما عمود Typora فمأخوذ من توثيقه المنشور، لأنه مغلق المصدر ولا يمكن التحقق منه بالطريقة نفسها.

أزمنة الإقلاع مأخوذة من جهاز Windows واحد، والبرامج الثلاثة عليه. أرقام هذا البرنامج مُقاسة آليًّا — فهو يكتب ملف `startup-trace.log` خاصًّا به، والأرقام من أربع عمليات إقلاع — بينما قِيس الآخران يدويًّا، فاعتبرهما الزوج الأخشن. معظم زمن الإقلاع هنا ليس من شفرة البرنامج نفسه: من الـ 0.7 ثانية، نحو 0.5 ثانية لتحميل Windows للملف التنفيذي وبدء محرك Flutter، و0.15 ثانية لكل ما يفعله المحرِّر ذاته.

| | **MarkText Plus** | **MarkText** (الأصلي) | **Typora** |
|---|---|---|---|
| **بيئة التشغيل** | Flutter — مُصرَّف، بلا متصفح مُضمَّن | Electron 42 | Electron |
| **الإقلاع** (حتى ظهور المستند) | نحو 0.7 ث على الساخن، ونحو 1.4 ث على البارد | 2–3 ث | 2–3 ث |
| **الاعتماديات المباشرة** | 22 | 56 (حزمة desktop) | مغلق المصدر |
| **الرخصة** | MIT، مجاني | MIT، مجاني | مدفوع، مغلق المصدر |
| **التحرير** | المصدر والمعاينة وعرض منقسم يتبع نصفاه أحدهما الآخر؛ وتُحرَّر الكتل في مكانها داخل المعاينة | معاينة حيَّة (WYSIWYG)، مع وضع للمصدر | معاينة حيَّة (WYSIWYG)، مع وضع للمصدر |
| **المخططات** | 22 نوعًا من Mermaid، تُرسم بلغة Dart دون WebView | Mermaid وflowchart.js وVega-Lite وPlantUML — جميعها عبر JavaScript | Mermaid وflowchart.js وjs-sequence وPlantUML |
| **الرياضيات** | متوافق مع KaTeX | KaTeX | KaTeX |
| **التصدير** | HTML وPDF وWord — كلها مُضمَّنة | HTML وPDF وMarkdown؛ وصيغ أكثر إن كان pandoc مثبَّتًا | صيغ كثيرة، أغلبها عبر pandoc |
| **السمات** | 8 | 32 | كثيرة، ومعها مجموعة مجتمعية واسعة |
| **لغات الواجهة** | 12 | 10 | عدة لغات |
| **المنصات** | Windows وmacOS وLinux (x64 وarm64) | Windows وmacOS وLinux | Windows وmacOS وLinux |

### حيث يتفوق الآخران

يجدر قول ذلك صراحةً، فالمقارنة التي تمدح كاتبها وحده لا تستحق القراءة.

- **المعاينة الحيَّة.** يحرِّر كلٌّ من Typora وMarkText المستند المعروض مباشرةً، دون وضع يُبدَّل. أما هذا المحرِّر فيقدِّم ثلاثة أَجزاء ويتيح فتح كتلة في مكانها؛ وهذا شيء آخر، وهو أول فرق يلحظه من اعتاد Typora.
- **السمات.** اثنتان وثلاثون مقابل ثمانٍ، ووراء Typora سنوات من CSS المجتمعية.
- **اتساع المخططات.** لم يُنفَّذ هنا PlantUML ولا Vega-Lite.
- **السنوات.** صُقل Typora على مدى عقد. وهذا برنامج فتيّ، ويبدو كذلك في مواضع منه.

### وحيث يتفوق هذا

- **لا متصفح مُضمَّن.** المحلِّل والمُصيِّر وتلوين الصياغة ومحرك المخططات، كلها مكتوبة هنا ومُصرَّفة داخل البرنامج. هذا هو سبب وجود المشروع كله، وأزمنة الإقلاع أعلاه هي ما يشتريه.
- **مخططات بلا JavaScript.** اثنان وعشرون نوعًا من Mermaid يرسمها راسمٌ بلغة Dart، فتدخل ملف PDF وملف Word صورًا لا برنامجًا نصيًّا يتعيَّن على جهاز القارئ تشغيله.
- **تصدير Word دون pandoc.** لا برنامج ثانيًا يُثبَّت.
- **مجاني ومفتوح المصدر**، وهو ما لا ينطبق على Typora.

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
