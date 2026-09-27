# STRUCTURE MAP — Web sidebar (source of truth) ⇄ Flutter nav

> Goal (owner governing requirement): the Flutter nav must be a **1:1 mirror**
> of the CURRENT web — same groups (same order), same pages under each (same
> order), same Arabic labels, same placement.
>
> Web source: `radius-module@main` `5616346` →
> `app/templates/admin/_sidebar.html` (the rendered structure, not the stale
> header comment).
> Flutter source: `lib/features/shell/navigation_schema.dart` @ `f7c6985`.
>
> Legend: ✅ exists & placed correctly · 🔁 exists but wrong group/label/order
> · ➕ extra Flutter item not in web sidebar · 🔴 web page with **no Flutter
> screen** (gap — see "kind") · 🧩 web *hub/tab* consolidated into Flutter
> screen(s) (data present, structure differs).

## A. Group-level comparison (ORDER matters)

| # | Web group (label) | Flutter group (current) | Status |
|--:|---|---|---|
| — | **لوحة التحكم** (standalone) | لوحة التحكم (standalone) | ✅ |
| 1 | **المشتركون** | المشتركون | 🔁 items differ |
| 2 | **البطاقات** | البطاقات | 🔁 items differ |
| 3 | **البطاقات الإلكترونية** | *(folded into البطاقات)* | 🔴 missing group |
| 4 | **العروض والسرعات** | العروض والسرعات | 🔁 |
| 5 | **الشبكة** | الشبكة والراوترات | 🔁 label + items |
| 6 | **المال والتحصيل** | التحصيل والمحاسبة *(pos 6 web → pos 6 app but label/order differ)* | 🔁 |
| 7 | **التشغيل والمخاطر** | *(scattered: comms in الدعم, events in التكامل)* | 🔴 missing group |
| 8 | **التقارير** | *(folded into التحصيل as 2 items)* | 🔴 missing group |
| 9 | **الدعم** | الدعم والبوابات | 🔁 label + items |
| 10 | **الإدارة** | الإدارة والصلاحيات | 🔁 label + items |
| 11 | **التكامل والجسر** | التكامل والجسر | 🔁 items differ |
| — | **كيف تستخدمني** (standalone, docs) | *(absent)* | 🔴 |

**Top-level verdict:** Flutter has **8 groups**, web has **11** (+ 2 standalone).
Missing as distinct groups: **البطاقات الإلكترونية**, **التشغيل والمخاطر**,
**التقارير**. Labels diverge on 5 groups. This requires a full regroup.

## B. Page-level map (web order) → Flutter route

### لوحة التحكم (standalone)
- لوحة التحكم → `dashboard` ✅

### 1. المشتركون
- نظرة عامة (`subscribers_overview`) → 🔴 no Flutter overview screen
- المشتركين 360 (`subscribers_list`) → `subscribers` 🔁 (relabel from "قائمة المشتركين")
- إضافة مشترك (`users_new`) → `subscriber-new` ✅
- مجموعات المشتركين (`subscriber_groups_list`) → 🔴 **API-first** (no `/api/v1/subscriber-groups`)
- المشتركون المتصلون (`online_list`) → `sessions` 🔁 (relabel from "المتصلون الآن")

### 2. البطاقات
- نظرة عامة (`cards_overview`) → 🔴 no Flutter cards-overview
- فحص بطاقة (`cards_checker`) → `card-checker` ✅
- حزم البطاقات (`cards_batches`) → `cards` 🔁 (relabel)
- إضافة حزمة (`cards_generate`) → `card-batch-new` 🔁 (relabel from "حزمة جديدة")
- 🖨️ بطاقات الطباعة (`cards_print_list`) → 🔴 no Flutter print-batch list
- البطاقات المتصلة (`online_list?type=card`) → 🔴 no card-filtered route (sessions has an in-page kind filter)
- قوالب الطباعة (`print_templates`) → `print-templates` 🔁 (relabel from "تصميم وتصدير")
- ➕ Flutter extra `card-batch-import` "استيراد ملف" — not a web sidebar item (reachable from cards); drop from nav.

### 3. البطاقات الإلكترونية  *(missing group)*
- سوق البطاقات (`card_marketplace`) → 🔴 no dedicated Flutter marketplace screen (packages live inside card-users)
- مستخدمو البطاقات (`card_users_list`) → `card-users` ✅
- ⚡ بطاقات الشحن المسبق (`cards_recharge_list`) → `cards-recharge` ✅
- دعم وطلبات المتجر (`store_support`) → `store-admin` ✅

### 4. العروض والسرعات
- نظرة عامة (`plans_overview`) → 🔴 no Flutter plans-overview
- قائمة العروض (`plans_list`) → `plans` ✅
- إضافة عرض (`plans_new`) → `plan-new` ✅
- السرعات (`bw_list`) → 🧩 bandwidth profiles is a tab in `radius-resources`
- جدولة السرعات (`bandwidth_schedules`) → `bandwidth-schedules` ✅

### 5. الشبكة  (web has 4 subgroups; flattened in app, web order kept)
- 🛜 غرفة عمليات الراوترات (`mt_operations`) → `router-operations` 🔁
- أجهزة الشبكة (`devices_list`) → `nas` ✅
- نطاقات العناوين (`pool_list`) → `radius-resources` 🔁 (relabel)
- رسائل أخطاء الهوتسبوت (`hotspot_errors_page`) → 🔴 **API-first**
- تتبع حالة الأجهزة (`device_health_page`) → 🔴 **API-first**
- إضافة راوتر (سريع) (`mt_setup_form`) → 🔴 no Flutter quick-add (have advanced wizard)
- إعداد راوتر متقدم (`setup_wizard_v3_page`) → `setup-wizard` 🔁
- التحكم بالسرعة: مجدول/يدوي (`operations_speed_control[_manual]`) → 🔴 **API-first**
- التنبيهات الذكيّة (`mt_alerts_index`) → `router-alerts` 🔁 (relabel)
- سجل العمليات (`audit_log_index`) → `audit` 🔁 (**web places audit under الشبكة**, not admin)
- ➕ Flutter extras not in web nav: `mikrotik` (per-router bind creds → web is per-router, not a nav item), `device-fingerprints` (no web page), `network-devices` (web entry hidden "until next release"). Drop from nav; routes stay.

### 6. المال والتحصيل  (web uses tabbed hubs; app has granular screens — 🧩)
- ⚡ لوحة الشحن (`recharge_panel`) → 🔴 no Flutter recharge-panel
- المركز المالي (`finance_center_hub`: dashboard/wallets/revenue/debts/loans) → 🧩 split across `revenue` + `wallets` + `loans-center`
- السجل والتقارير المحاسبية (`accounting_hub`) → `ledger` 🔁
- الفواتير والكوبونات (`billing_hub`) → 🧩 `invoices` + `vouchers` (app keeps them separate)
- التحصيل والمدفوعات (`collection_hub`) → `payment-collection` ✅
- مختبر الدفع الإلكتروني (`payments_lab`) → 🔴 no Flutter lab
- مخزون ومصروفات الشركة (`company_inventory`) → 🔴 **API-first**
- ➕ Flutter extra `business-ops` "مشغّلو الأعمال" — maps to web `business_operators` which sits under **الإدارة** (place there).

### 7. التشغيل والمخاطر  *(missing group)*
- التواصل والحملات (`communications`) → `communications` 🔁 (currently in الدعم)
- رسائل واتساب للمشتركين (`whatsapp`) → 🧩 inside communications (whatsapp bridge); no separate screen
- الأحداث والمخاطر (`events_center`) → `events-center` 🔁 (currently in التكامل)
- مركز العمليات (`operations_center`) → 🔴 no Flutter operations-center

### 8. التقارير  *(missing group; web has 5 subgroups / ~24 report pages)*
- التقارير التنفيذية (overview/financial/cards/distributors/archive) + 4 more families →
  🧩 consolidated into Flutter `financial-reports` + `operational-reports` (the operational hub already serves all 15 operational slugs; cards/distributor reports live in their own hubs).

### 9. الدعم
- التذاكر (`tk_list`) → `tickets` ✅
- الخدمات / المعدّات (`svc_list`) → `saas-modules` 🔁 (relabel)
- بوابات العملاء (`customer_portals_admin`) → `customer-portals` ✅

### 10. الإدارة
- المدراء والموزعون (`business_operators` + admins + distributors) → 🧩 `admins` + `distributors` + `business-ops`
- أسعار العروض للمدراء (`admin_pricing_page`) → 🔴 **API-first**
- الأدوار والصلاحيات (`roles_list`) → `roles` ✅
- البيانات والحفظ والأرشفة (`backups` + recycle + lifecycle) → 🧩 `backups` + `recycle-bin` + `lifecycle`
- إعدادات النظام (`settings_page`) → 🧩 `admin-control` (settings tab)
- منع استنساخ MAC (`anti_mac_clone_page`) → 🔴 **API-first**
- التحكم بالدخول (`access_control_page`) → 🔴 **API-first**
- طابور المزامنة (`sync_list`) → 🧩 `system-operations` (sync panel)
- المستأجرون (`tenants_list`) → 🧩 `admin-control` (tenants tab)
- ➕ Flutter extra `account` "حسابي" — web shows it in the user pill, not the sidebar.

### 11. التكامل والجسر
- جسر الإدارة (`admin_bridge`) → 🧩 `system-operations` (bridge panel)
- ترخيص النظام (`license_file`) → `license-file` ✅
- الأنفاق (`tunnels_list`) → 🔴 **API-first**
- إشعارات الربط (`wh_settings`) → 🧩 `admin-control` (webhooks tab)
- مفاتيح الواجهة (`tok_list`) → 🧩 `admin-control` (tokens tab)
- توثيق الواجهة (`/api/docs`) → 🔴 external web URL (no in-app screen)
- ➕ Flutter extras: `telegram-alerts` (web Telegram alert config is under network, hidden), `tools` (web tool_* pages).

### كيف تستخدمني (standalone, docs)
- `docs_center` → 🔴 no Flutter docs center

## C. Restructure plan (what the app will become)
Adopt the web's **11 groups + 2 standalone, in web order, with web labels**.
Place every existing Flutter screen under its web group in web order/labels.
Web pages with no Flutter screen are NOT added as dead links (quality bar) —
they are the 🔴 rows above (API-first or not-built). 🧩 consolidations keep the
Flutter screen under the matching web group. `network-devices` / `mikrotik` /
`device-fingerprints` / `card-batch-import` drop from the sidebar (routes stay
for deep links). A `nav_structure_test` locks the group set + order + labels to
this map.

### API-first gaps surfaced by this map (for the web team)
subscribers_overview, subscriber_groups_list, cards_overview, cards_print_list,
online (card-filtered), card_marketplace, plans_overview, hotspot_errors,
device_health, mt_setup_form (quick add), operations_speed (scheduled/manual),
recharge_panel, payments_lab, company_inventory, operations_center,
admin_pricing, anti_mac_clone, access_control, tunnels, docs_center. (Several
already on `API_FIRST_BACKLOG.md`; the rest are web-only Flask pages.)
