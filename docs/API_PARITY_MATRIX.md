# مصفوفة تغطية الريدياس Web / API / Flutter

هذا الملف هو سجل التنفيذ بين:

- الريدياس Web داخل `radius-module/app/templates/radius`.
- واجهات JSON داخل `radius-module/app/api/v1`.
- تطبيق Flutter داخل `radius-module-app/lib/features`.

القرار المعتمد: كل الويب ينتقل إلى Flutter أصلي للموبايل وWindows. أي صفحة لا تملك API حقيقي يتم بناء API لها أولًا، ثم شاشة Flutter. لا WebView ولا بيانات وهمية للميزات الإنتاجية.

## حالات التغطية

| الحالة | معناها |
|---|---|
| مكتمل | يوجد Web + API + Flutter route/screen فعلي |
| ناقص Flutter | يوجد Web + API، لكن شاشة Flutter غير موجودة أو غير مكتملة |
| ناقص API | يوجد Web، ولا يوجد API كاف للتطبيق |
| يحتاج تدقيق | موجود جزئيًا لكن يحتاج مقارنة حقول وأفعال مع الويب |

## أولوية التنفيذ الحالية

| الأولوية | المجموعة | الهدف |
|---|---|---|
| P0 | الأساس | الدخول، رابط API، اللغة العربية، حالات التحميل/الفارغ/الخطأ، والداشبورد |
| P1 | التشغيل اليومي | المشتركين، الكروت، الباقات، الجلسات، NAS، MikroTik |
| P2 | الترخيص والمزامنة | ملف الترخيص، حالة الربط، مزامنة العقد، النسخ الاحتياطي، عمليات النظام |
| P3 | المال والخدمات | التحصيل، المحافظ، الديون، السلف، الفواتير، طلبات الخدمات والتذاكر |
| P4 | التحكم المتقدم | Network Policy، Site Exit، الوصول عن بعد، الأحداث والمخاطر، الاتصالات |
| P5 | البوابات | بوابة المشترك، بوابة الكروت، مستخدمو الكروت والسوق |
| P6 | التقارير والإدارة | التقارير، التدقيق، الإعدادات، المفاتيح، المستأجرون، الأرشفة، سلة المحذوفات |

## مصفوفة المرحلة الأولى

| المجال | صفحات Web المرجعية | API الحالي | Flutter الحالي | الحالة | أولوية | الشريحة |
|---|---|---|---|---|---|---|
| الدخول | `login.html` | `/api/admin/login`, `/api/admin/me`, `/api/admin/logout` | `LoginScreen` | يحتاج تدقيق نصوص عربية وحالات فشل | P0 | F0 |
| الداشبورد | `dashboard.html` | `/api/v1/dashboard` | `DashboardScreen` | يحتاج مقارنة بصرية مع الويب بعد آخر تعديلات | P0 | F0 |
| المشتركين | `users_list.html`, `users_form.html`, `users_profile.html`, `subscriber_360.html` | `/api/v1/accounts/*` | `SubscribersListScreen`, `SubscriberFormScreen` | يحتاج تدقيق حقول 360 والأفعال السريعة | P1 | F1 |
| الكروت | `cards_*`, `cards_checker_v2.html`, `card_users.html`, `card_user_360.html` | `/api/v1/cards/*`, `/api/v1/hotspot-cards/*`, `/api/v1/card-users/*` | `CardsListScreen`, `CardCheckerScreen`, batch screens, `CardUsersScreen`, `CardUser360Screen` | موجود Flutter لمستخدمي الكروت، ويحتاج تدقيق سوق الكروت وكل أفعال الشراء والشحن | P1/P5 | F2/F9 |
| الباقات والسرعات | `plans_*`, `bandwidth_*`, `_speed_rules_panel.html` | `/api/v1/profiles`, `/api/v1/bandwidth-schedules`, `/api/v1/bandwidth-profiles` | `PlansListScreen`, `PlanFormScreen`, `BandwidthSchedulesScreen` | يحتاج تدقيق parity للحقول المتقدمة | P1 | F3 |
| الجلسات | `sessions_list.html`, تقارير الجلسات | `/api/v1/sessions/online`, `/api/v1/accounting/*` | `SessionsListScreen` | يحتاج توسيع تفاصيل المحاسبة والتاريخ | P1 | F4 |
| NAS وأجهزة الشبكة | `devices_*`, `network_devices_*` | `/api/v1/nas`, `/api/v1/devices`, `/api/v1/network-devices` | `NasListScreen`, `NasFormScreen`, `DeviceFingerprintsScreen`, `NetworkDevicesScreen` | مكتمل كشاشة تشغيلية لإدارة NAS وبصمات الأجهزة ومراقبة أجهزة الشبكة المتقدمة مع CRUD وفحص يدوي، ويحتاج لاحقًا ربط عمليات bypass/remote-access عند اعتمادها كواجهة JSON آمنة | P1/P4 | F5/F8 |
| MikroTik | `mt_*`, `setup_wizard*` | `/api/v1/mikrotik`, `/api/v1/mikrotik-control/*`, `/api/v1/setup-wizard/*` | `MikrotikScreen`, `RouterOperationsScreen`, `SetupWizardScreen` | موجودة شاشة اتصالات ميكروتك، شاشة قراءة حية لعمليات الراوتر، وشاشة معالج إعداد تقرأ الصحة والجاهزية وآخر التشغيلات وتبدأ تشغيلًا جديدًا. تطبيق أوامر الراوتر والخادم يبقى في الويب المحمي حتى يكتمل تحويل خطوات التنفيذ إلى JSON آمن | P1/P2 | F6 |
| ملف الترخيص والمزامنة | `license_file.html`, `admin_bridge.html`, `sync_list.html` | `/api/v1/system/license-file`, `/api/v1/system/admin-bridge/*`, `/api/v1/system/sync` | `LicenseFileScreen`, `SystemOperationsScreen` | مكتمل كمسار Flutter واضح لملف الترخيص والربط، مع فصل طابور المزامنة في عمليات النظام | P2 | F7 |
| النسخ الاحتياطي | `backups.html`, `mt_backups.html` | `/api/v1/backups/*` | `BackupsScreen` | يحتاج توسيع عرض جوجل درايف وحالة الخدمة | P2 | F7 |
| المال والتحصيل | `finance_*`, `payment_collection_*`, `users_finance.html` | `/api/v1/payments/*`, `/api/v1/ledger`, `/api/v1/loans`, `/api/v1/invoices` | `LedgerScreen`, `FinancialReportsScreen`, `SubscriberFinanceScreen`, `PaymentCollectionScreen` | موجود Flutter لمركز التحصيل، ويحتاج تدقيق قرارات القبول والرفض وتطبيق الخدمة | P3 | F10 |
| الخدمات والتذاكر | `services_*`, `tickets_*`, `ticket_view.html` | `/api/v1/services`, `/api/v1/tickets` | `TicketsListScreen`, `TicketDetailScreen`, `SaasModulesScreen` | موجود Flutter للتذاكر، ويحتاج تدقيق طلبات الخدمات من طرف العميل وربطها بالتحصيل | P3 | F11 |
| Network Policy | `network_policy_*`, `site_exit.html`, `remote_device_access.html` | `/api/v1/network-policy/*` | `NetworkPolicyScreen` | موجود Flutter، ويحتاج تدقيق preview والأهداف المتقدمة مقابل الويب | P4 | F12 |
| الأحداث والمخاطر | `events_*` | `/api/v1/events` | `EventsCenterScreen` | موجود Flutter للأحداث، ويحتاج تدقيق تصنيف المخاطر والفلاتر المتقدمة | P4 | F13 |
| الاتصالات | `communications_*`, `network_telegram_settings.html` | `/api/v1/communications/*` | `CommunicationsScreen` | موجود Flutter للرسائل والحملات، ويحتاج تدقيق إعدادات تيليجرام والقنوات | P4 | F14 |
| بوابة المشترك | `portal_subscriber*` | `/api/v1/customer-portals` إداريًا، ومسارات Web ذاتية للبوابة | `CustomerPortalsScreen` | موجودة شاشة إدارة روابط البوابات، وتجربة المشترك الذاتية المستقلة داخل Flutter ما زالت تحتاج API/session خاص | P5 | F15 |
| بوابة الكروت | `portal_card*`, `card_marketplace.html`, `card_pricing*` | `/api/v1/hotspot-cards/*`, `/api/v1/card-users/*` جزئيًا | `CardUsersScreen`, `CardUser360Screen` | موجودة إدارة مستخدمي الكروت، لكن تجربة بوابة الكرت المستقلة تحتاج فصل وتدقيق | P5 | F16 |
| التقارير | `reports_*`, `rep_*` | `/api/v1/reports/*`, `/api/v1/operational-reports/*` | `FinancialReportsScreen`, `OperationalReportsScreen` | يحتاج تغطية كل التقارير لا المختصر فقط | P6 | F17 |
| التدقيق | `audit_*` | `/api/v1/audit` | `AuditListScreen` | يحتاج تفاصيل السجل والفلاتر | P6 | F18 |
| الإعدادات والتحكم | `settings_page.html`, `tokens_list.html`, `tenants_*`, `wh_*` | `/api/v1/settings`, `/api/v1/tokens`, `/api/v1/tenants`, `/api/v1/webhooks/*` | `AdminControlScreen` | يحتاج تدقيق كل الأفعال والنصوص | P6 | F19 |
| الأرشفة وسلة المحذوفات | `lifecycle.html`, `recycle_bin.html` | `/api/v1/lifecycle/*`, `/api/v1/recycle-bin/*` | `LifecycleScreen`, `RecycleBinScreen` | يحتاج مقارنة وظائف كاملة | P6 | F20 |
| أدوات التشغيل | `tool_*`, `_status.html` | `/api/v1/tools/*`, `/api/v1/health`, `/api/v1/version` | `ToolsScreen` | يحتاج تدقيق وتحسين أمان الأفعال الخطرة | P6 | F21 |

## شرائح التنفيذ المقفلة

| الشريحة | التعديل المطلوب | شرط القبول |
|---|---|---|
| F0 | تثبيت الأساس: نصوص عربية، أخطاء login، route coverage، حالات loading/empty/error، مقارنة dashboard | `flutter analyze`, `flutter test`, وعدم وجود نصوص إنجليزية ظاهرة إلا التقنية |
| F1 | مشتركين 360: كل حقول Web، الإجراءات السريعة، التمويل، الحالة، التفاصيل | إنشاء/تعديل/تعطيل/تمديد/عرض 360 من Flutter يطابق الويب |
| F2 | الكروت التشغيلية: batches، detail، import/export، checker، actions | كل أفعال الكروت الأساسية تعمل عبر API |
| F3 | الباقات والسرعات: profile CRUD، speed rules، schedules | حفظ كل قيود السرعة والزمن من Flutter بدون فقدان حقول |
| F4 | الجلسات والمحاسبة: online، disconnect، usage history | عرض الجلسات الحالية والتاريخ وقطع الجلسة |
| F5 | NAS وأجهزة الشبكة | CRUD، test، fingerprints، وحالة الجهاز |
| F6 | MikroTik وsetup wizard | شاشة Flutter للاتصالات والعمليات ومعالج الإعداد الآمن. المتبقي هو تحويل خطوات التنفيذ الفعلية للمعالج إلى API آمن عند اعتمادها |
| F7 | ملف الترخيص والمزامنة والنسخ | صفحة Flutter واضحة لحالة الترخيص والربط والمزامنة والنسخ |
| F8-F14 | التحكم المتقدم والاتصالات والأحداث | API أولًا ثم شاشات Flutter أصلية |
| F15-F16 | بوابات العميل والكروت | تجربة مستخدم مستقلة وآمنة داخل Flutter |
| F17-F21 | التقارير والإدارة والأدوات | تغطية كل الصفحات المتبقية |

## قواعد التنفيذ

1. لا يتم اعتبار أي شاشة مكتملة إذا كانت تعرض بيانات ثابتة أو رسالة “قريبًا”.
2. كل API جديد يستخدم نفس خدمات الويب الحالية حتى تبقى validation وaudit واحدة.
3. كل شاشة Flutter يجب أن تدعم الموبايل وWindows من نفس الكود.
4. أي تغيير ينتهي بفحص ثم commit صغير ثم push مباشر.
5. لا يتم لمس الملفات غير المتتبعة الموجودة حاليًا إلا بطلب صريح.

## تحديثات منجزة

- تنبيهات الراوترات الذكية: تم توفير API حقيقي عبر `/api/v1/router-alerts/settings`، وربطه بشاشة Flutter أصلية `RouterAlertsScreen` لإدارة التفعيل، حد الانقطاع، حد السرعة، حد الاستهلاك، ونافذة الاستهلاك لكل راوتر.
- تتبّع اللوب: تم توسيع عقد `/api/v1/router-alerts/settings` ليعيد `loop_probes` وعدادات الحلقات، وتم عرض حالة المجسّات داخل Flutter بدون WebView أو بيانات وهمية.
