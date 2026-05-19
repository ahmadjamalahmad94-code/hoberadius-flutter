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

### 3. الـ backend

التطبيق يتكلّم مع `radius-module` Flask عبر `/api/v1/*` بـ Bearer token. وَلِّد token من لوحة الإدارة، ثم الصقه في شاشة الدخول.

عند التشغيل، حدّد عنوان الـ API:

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
```

ناتج البناء في `build/web/` — انسخه إلى nginx على الـ VPS.

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
| Login (paste token) | ✅ | `GET /api/v1/health` |
| Dashboard | ✅ | يقع back على endpoints منفصلة |
| Subscribers list/form | ✅ | `/api/v1/accounts` (CRUD كاملة) |
| Plans list | ✅ | `/api/v1/profiles` (قراءة فقط — CUD معلَّق على Flask) |
| Cards generate + CSV | ✅ | `/api/v1/cards/generate` |
| NAS list + test | ✅ | `/api/v1/nas` (قراءة) — test endpoint معلَّق |
| Admins + Roles | ✅ | `/api/admin/*` — معلَّق على Flask |

تفاصيل الـ endpoints المعلَّقة موثَّقة كـ TODOs في كل ملف repository.

## الخطوة التالية

- إضافة admin JSON login على Flask (`POST /api/admin/login` يُرجِع token).
- توسيع `/api/v1/accounts` لقبول كامل الـ metadata في الـ patch (40+ field).
- إضافة CUD لـ `/api/v1/profiles` و `/api/v1/nas`.
- إضافة `/api/admin/admins` و `/api/admin/roles`.
