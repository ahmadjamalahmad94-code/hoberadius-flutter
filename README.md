# HobeRadius — Flutter admin UI

واجهة إدارة HobeRadius مكتوبة بـ Flutter، تستهدف الويب + الأندرويد/iOS + الـ Windows من نفس الـ codebase.

## التشغيل

### 1. تهيئة Flutter

ثبّت Flutter SDK (`>= 3.19`) ثم أضفه إلى PATH:
- Windows: <https://docs.flutter.dev/get-started/install/windows>
- تأكد: `flutter doctor`

### 2. إنشاء مجلدات المنصّات

المشروع لا يحتوي `windows/` / `android/` / `web/icons/` افتراضيًا. من جذر المشروع:

```powershell
flutter create . --platforms=web,android,ios,windows --org com.hobe
```

ثم نزّل التبعيات:

```powershell
flutter pub get
```

> ملاحظة مهمة: مجلدات المنصات مولّدة وموجودة في `.gitignore`. إذا أعدت توليد `android/` على جهاز ذاكرته محدودة، خفّض إعدادات Gradle حتى لا يطلب Java Heap كبيرًا جدًا:
>
> ```powershell
> $props = Get-Content android\gradle.properties
> $props = $props -replace '^org\.gradle\.jvmargs=.*$', 'org.gradle.jvmargs=-Xmx2G -XX:MaxMetaspaceSize=1G -XX:ReservedCodeCacheSize=256m -XX:+HeapDumpOnOutOfMemoryError'
> if ($props -notmatch '^org\.gradle\.workers\.max=') { $props += 'org.gradle.workers.max=2' }
> $props | Set-Content android\gradle.properties
> ```
>
> لبناء Windows يجب تفعيل Developer Mode في النظام لأن Flutter plugins تحتاج symlink support.

### 3. الـ backend

التطبيق يتكلّم مع `radius-module` Flask عبر `/api/v1/*`. من شاشة الدخول اكتب البروتوكول (`HTTP` أو `HTTPS`) ثم IP أو دومين الـ VPS، وبعدها اسم المستخدم وكلمة المرور. التطبيق يستدعي `/api/admin/login` ويحفظ عنوان الخادم والـ token على الجهاز.

عند التشغيل المحلي يمكن ترك العنوان الافتراضي، أو تحديده مسبقًا للتطوير:

```powershell
# للويب (Flask محلي)
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000

# للأندرويد على المحاكي (10.0.2.2 = الـ host)
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5000

# لـ Windows
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5000
```

> ⚠️ للويب: يحتاج Flask تفعيل CORS للـ origin بتاع Flutter (افتراضيًا `http://localhost:port`).

### 4. البناء للإنتاج

```powershell
flutter build web --dart-define=API_BASE_URL=https://radius.your-vps.com
flutter build apk --dart-define=API_BASE_URL=https://radius.your-vps.com
flutter build windows --dart-define=API_BASE_URL=https://radius.your-vps.com
```

ناتج الويب في `build/web/`، وملف Android في `build/app/outputs/flutter-apk/app-release.apk`، ونسخة Windows داخل `build/windows/`.

## البنية

```
lib/
├── main.dart                       # ProviderScope + HobeRadiusApp
├── app.dart                        # MaterialApp + theme + router + RTL
├── core/
│   ├── theme/                      # design tokens (navy/cyan/Cairo)
│   ├── router/                     # go_router config
│   ├── api/                        # dio client + interceptors
│   └── auth/                       # token storage + AuthController
├── features/
│   ├── auth/                       # شاشة دخول
│   ├── shell/                      # sidebar + topbar + layout
│   ├── dashboard/                  # H2 — metrics + system health
│   ├── subscribers/                # H1 — list + 40+ field form
│   ├── plans/                      # H3 — list + form
│   ├── cards/                      # H4 — generate + CSV
│   ├── nas/                        # H5 — list + form + test
│   └── admins/                     # H6 — admins + roles + RBAC
└── shared/widgets/                 # AppCard, CollapsibleSection, ...
```

## الحالة

| الميزة | الـ UI | الـ API |
|---|---|---|
| Login by VPS IP/domain + username/password | ✅ | `POST /api/admin/login`, `GET /api/admin/me` |
| Dashboard | ✅ | يقع back على endpoints منفصلة |
| Subscribers list/form | ✅ | `/api/v1/accounts` (CRUD كاملة) |
| Plans list/form + speed rules | ✅ | `/api/v1/profiles`, `/api/v1/bandwidth-schedules` |
| Cards generate + CSV + batch operations | ✅ | `/api/v1/cards/*` |
| Card checker operations console | ✅ | `/api/v1/cards/check` + card action endpoints |
| NAS list + test | ✅ | `/api/v1/nas` |
| Admins + Roles | ✅ | `/api/v1/admins`, `/api/v1/admins/roles` |
| Distributors | ✅ | `/api/v1/distributors` |
| Payments / Loans / Ledger | ✅ | `/api/v1/payments`, `/api/v1/loans`, `/api/v1/ledger` |
| Financial reports | ✅ | `/api/v1/reports/*` |
| Recycle bin | ✅ | `/api/v1/recycle-bin` |
| Backups | ✅ | `/api/v1/backups/*`، وGoogle Drive غير مفعل حتى OAuth حقيقي |
| Print templates | ✅ | `/api/v1/print-templates` مع معاينة بصرية، بدون PDF نهائي بعد |

أي endpoint يرجع `not_implemented` لا يظهر في الواجهة كأنه مكتمل. Google Drive وPDF النهائي لقوالب الطباعة ما زالا معطلين بوضوح حتى تتوفر تكاملات حقيقية.

## الخطوة التالية

- تفعيل Developer Mode على Windows ثم تشغيل `flutter build windows`.
- تحويل Google Drive من حالة معطلة إلى OAuth حقيقي عندما نقرر مزود الحسابات.
- إضافة PDF renderer حقيقي لقوالب الطباعة بدل الاكتفاء بالمعاينة البصرية.
