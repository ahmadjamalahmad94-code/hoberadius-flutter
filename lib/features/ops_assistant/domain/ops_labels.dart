// Operations assistant — Arabic texts, field labels and value labels.
//
// 1:1 with the web page's `#ops-config` (templates/radius/ops_assistant.html:
// `t`, `labels`, `values`) so a card reads the same on the web and in the app.

abstract final class OpsTexts {
  static const title = 'مساعد العمليّات';
  static const experimental = 'تجريبيّ';

  // ── the app's chat surface (the owner's mockup) ──
  /// The header title on the chat screen itself. The MENU entry keeps the
  /// canonical «مساعد العمليّات» (navigation_schema) — this is the greeting
  /// name the owner asked for on the screen.
  static const smartTitle = 'المساعد الذكي';
  static const smartSubtitle = 'اكتب طلبك بلغة بسيطة وأنا أنفذه لك.';
  static const botName = 'المساعد الذكي';
  static const notifications = 'الإشعارات';
  static const historyTitle = 'المحادثات السابقة';

  /// There is no server endpoint that LISTS an admin's past conversations
  /// (the web's /ops-assistant/history replays ONE conversation by its id,
  /// and the app's bearer API has no history route at all), so the button
  /// shows the conversation that is open now.
  static const historyOnlyCurrent =
      'الخادم لا يحفظ قائمة محادثات سابقة — هذه هي المحادثة المفتوحة الآن.';
  static const historyEmpty = 'لا رسائل في هذه المحادثة بعد.';
  static const tasksTitle = 'المهام المقترحة';
  static const tasksHint = 'اختر مهمّة وسأسألك عمّا ينقصني.';
  static const tasksMore = 'المزيد';
  static const resultReady = 'النتيجة جاهزة';
  static const showDetails = 'عرض التفاصيل';
  static const hideDetails = 'إخفاء التفاصيل';
  static const greetingLead = 'أهلًا! اكتب ما تريد، مثل:';
  static const greetingTail = 'سأجهّز الإجراء وأعرضه عليك للتأكيد.';
  static const exampleRenew = '«جدّد لأحمد شهر مدفوع»';
  static const exampleCards = '«اعمل 100 كرت من باقة الساعة»';
  static const micUnavailable =
      'الإدخال الصوتيّ غير متاح في هذه النسخة من التطبيق.';
  static const composerHint = 'اكتب رسالتك هنا…';
  static const typingLabel = 'المساعد الذكي…';

  /// The composer's one-line form of [noPasswordsHint] — the long web
  /// sentence ate three lines of a phone screen.
  static const noPasswordsShort =
      'لا تكتب كلمات مرور — النظام يولّدها ويعرضها مرّة واحدة.';
  static const subtitle =
      'اكتب طلبك بلغتك — المساعد يجهّز الإجراء وأنت تؤكّده. لا يُنفَّذ شيء بدون تأكيدك.';
  static const greeting =
      'أهلًا! اكتب ما تريد، مثل: «جدّد لأحمد شهر مدفوع» أو «اعمل 100 كرت من '
      'باقة الساعة». سأجهّز الإجراء وأعرضه عليك للتأكيد.';
  static const chatTitle = 'المحادثة';
  static const chatMeta = 'لا يُنفَّذ شيء قبل ضغطك «تأكيد»';
  static const inputHint = 'اكتب طلبك هنا…';
  static const inputLabel = 'رسالتك';
  static const send = 'إرسال';
  static const newChat = 'محادثة جديدة';
  static const noPasswordsHint =
      'لا تكتب كلمات مرور في المحادثة — النظام يولّدها بنفسه ويعرضها لك مرّة واحدة.';
  static const thinking = 'المساعد يفكّر…';
  static const network = 'تعذّر الاتصال بالخادم. حاول مرّة أخرى.';
  static const confirm = 'تأكيد';
  static const cancel = 'إلغاء';
  static const cancelled = 'أُلغي المقترح — لم يُنفَّذ شيء.';
  static const proposalTitle = 'مقترح بانتظار تأكيدك';
  static const planTitle = 'خطّة من عدّة خطوات — تأكيد واحد';
  static const step = 'الخطوة';
  static const danger = 'تأثير مباشر على المشترك (فصل/تغيير فوريّ).';
  static const passwordNote =
      'كلمة مرور المشترك تُولَّد تلقائيًّا وتُعرض لك مرّة واحدة بعد التنفيذ.';
  static const notExec =
      'هذه الخطوة غير قابلة للتنفيذ من المساعد في هذه النسخة — نفّذها من صفحتها.';
  static const fromStep = 'من نتيجة الخطوة';
  static const resultTitle = 'نتيجة التنفيذ';
  static const stDone = 'تمّ';
  static const stFailed = 'فشل';
  static const stNotRun = 'لم يُنفَّذ';
  static const rsExecuted = 'نُفّذ كاملًا';
  static const rsFailed = 'لم يُنفَّذ';
  static const rsPartial = 'نُفّذ جزئيًّا — راجع الخطوات';
  static const replayed = 'هذا المقترح نُفّذ سابقًا — هذه نتيجته المحفوظة.';
  static const choicesTitle = 'قائمة من النظام';
  static const choicesMore =
      'القائمة مختصرة — حدّد الاسم بدقّة أكثر إن لم تجد ما تريد.';
  static const choicesEmpty = 'لا توجد نتائج.';
  static const infoTitle = 'معلومة من النظام';
  static const infoMore = 'القائمة مختصرة — العدد الكلّيّ أعلاه.';
  static const eventsTitle = 'اقتراحات';
  static const eventsMeta = 'من نظام المراقبة';
  static const eventsEmpty = 'لا اقتراحات الآن.';
  static const eventsError = 'تعذّر جلب الاقتراحات.';
  static const start = 'ابدأ محادثة';
  static const eventStarted = 'بدأت محادثة من اقتراح النظام.';
  static const copy = 'نسخ';
  static const copied = 'نُسخ';
  static const empty = 'اكتب رسالة أوّلًا.';
  static const noExpiry = 'بلا انتهاء';
  static const serverDefault = 'حسب إعداد الخادم';

  // one-time password dialog
  static const secretTitle = 'كلمة مرور تُعرض مرّة واحدة';
  static const secretWarning =
      'انسخها الآن وسلّمها للمشترك. لن تظهر مرّة أخرى، ولا تُحفظ في السجلّات، ولا يراها المساعد.';
  static const secretClose = 'نسختها — إغلاق';

  // unavailable states
  static const unavailableTitle = 'المساعد غير متاح الآن';
  static const disabled =
      'مساعد العمليّات غير مفعّل لهذه الشبكة. الميزة تجريبيّة ومطفأة افتراضيًّا.';
  static const disabledOwnerHint =
      'يفعّلها مالك الشبكة بعد التحقّق من أنّ كل المدراء يستخدمون كلمات مرور قويّة.';
  static const disabledAskOwner = 'اطلب من مالك الشبكة تفعيلها.';
  static const weakPasswords =
      'المساعد متوقّف لحماية الشبكة: لا يعمل ما دام أيّ مدير يستخدم كلمة مرور افتراضيّة أو مؤقّتة.';
  static const defaultPasswordAdmins = 'مدراء بكلمة مرور افتراضيّة:';
  static const mustChangeAdmins = 'مدراء بكلمة مرور مؤقّتة لم تُغيَّر:';
  static const weakPasswordsHint =
      'بعد تغيير هذه الكلمات يعمل المساعد تلقائيًّا.';
  static const notSupported =
      'هذا الخادم لم يُحدَّث بعد لمساعد العمليّات من التطبيق.';
  static const statusError = 'تعذّر التحقّق من حالة المساعد.';

  static String infoTitleFor(String source) => switch (source) {
        'card_batch_status' => 'وضع حزمة البطاقات',
        'subscriber_info' => 'معلومات المشترك',
        'online_sessions' => 'المتّصلون الآن',
        _ => infoTitle,
      };

  static String infoError(String code) => switch (code) {
        'not_found' => 'غير موجود.',
        'out_of_scope' => 'هذا السجلّ ليس ضمن نطاقك.',
        'missing_permission' => 'لا تملك صلاحية عرض هذه المعلومة.',
        _ => 'تعذّر جلب المعلومة الآن.',
      };

  static String reportStatus(String s) => switch (s) {
        'executed' => rsExecuted,
        'failed' => rsFailed,
        'partial' => rsPartial,
        _ => s,
      };

  static String stepStatus(String s) => switch (s) {
        'done' => stDone,
        'failed' => stFailed,
        'not_run' => stNotRun,
        _ => s,
      };
}

/// Field labels (web `labels`).
const kOpsFieldLabels = <String, String>{
  'username': 'اسم المستخدم',
  'plan_id': 'الباقة',
  'offer_id': 'العرض',
  'mobile': 'الجوال',
  'full_name': 'الاسم الكامل',
  'email': 'البريد',
  'expire_at': 'ينتهي (UTC)',
  'expire_local': 'ينتهي',
  'new_expire_local': 'الانتهاء الجديد',
  'charge_mode': 'طريقة الحساب',
  'amount': 'المبلغ',
  'mode': 'النوع',
  'minutes': 'المدّة (دقائق)',
  'notes': 'ملاحظات',
  'remark': 'ملاحظة',
  'policy': 'سياسة التغيير',
  'down_kbps': 'التنزيل (kbps)',
  'up_kbps': 'الرفع (kbps)',
  'duration_minutes': 'المدّة (دقائق)',
  'down': 'التنزيل',
  'up': 'الرفع',
  'name': 'الاسم',
  'price': 'السعر',
  'speed_down_kbps': 'سرعة التنزيل (kbps)',
  'speed_up_kbps': 'سرعة الرفع (kbps)',
  'speed_unlimited': 'بلا حدّ للسرعة',
  'validity_days': 'الصلاحيّة (أيّام)',
  'quota_total_mb': 'الحصّة (MB)',
  'quota': 'الحصّة',
  'plan_type': 'نوع الباقة',
  'wholesale': 'سعر الجملة',
  'selling': 'سعر البيع',
  'count': 'عدد الكروت',
  'package_name': 'اسم الحزمة',
  'username_length': 'طول اسم المستخدم',
  'password_length': 'طول كلمة السر',
  'login_without_password': 'دخول بلا كلمة سر',
  'device_count': 'عدد الأجهزة',
  'device_limit_mode': 'عند تجاوز الأجهزة',
  'concurrent_sessions': 'الجلسات المتزامنة',
  'allowed_devices_count': 'الأجهزة المسموحة',
  'description': 'الوصف',
  'enabled': 'مفعّلة',
  'national_id': 'رقم الهويّة',
  'address': 'العنوان',
  'city': 'المدينة',
  'mac_lock': 'قفل الماك',
  'time_value': 'المدّة',
  'time_unit': 'وحدة المدّة',
  'price_per_card': 'سعر الكرت',
  'total_price': 'السعر الكلّيّ',
  'custom_price': 'سعر خاصّ',
  'static_ip': 'IP ثابت',
  'batch_id': 'رقم الحزمة',
  'code': 'كود الحزمة',
  'status': 'الحالة',
  'created_local': 'تاريخ الإنشاء',
  'total_cards': 'كل الكروت',
  'available_count': 'متاحة (غير مستعملة)',
  'active_count': 'قيد الاستعمال',
  'expired_count': 'منتهية',
  'revoked_count': 'ملغاة',
  'archived_count': 'مؤرشفة',
  'plan_name': 'الباقة',
  'plan': 'الباقة',
  'expires_local': 'ينتهي',
  'no_expiry': 'بلا انتهاء',
  'online': 'متّصل الآن',
  'online_sessions': 'جلسات حيّة',
  'last_seen_local': 'آخر ظهور',
  'balance': 'الرصيد',
  'balance_hidden': 'الرصيد مخفيّ',
  'open_debt': 'الدين المفتوح',
  'currency': 'العملة',
  'total': 'العدد الكلّيّ',
  'subscribers': 'مشتركون',
  'cards': 'كروت',
};

/// Value labels (web `values`).
const kOpsValueLabels = <String, String>{
  'paid': 'مدفوع من الرصيد',
  'debt': 'دين على المشترك',
  'free': 'مجّانًا',
  'true': 'نعم',
  'false': 'لا',
  'duration': 'مدّة',
  'expire_at': 'حتّى تاريخ',
  'lower_compensate': 'تعويض بأيّام إضافيّة',
  'lower_keep_expiry': 'إبقاء تاريخ الانتهاء',
  'higher_debt': 'تسجيل الفرق دينًا',
  'higher_reduce_days': 'إنقاص الأيّام المتبقّية',
  'higher_keep_expiry': 'إبقاء تاريخ الانتهاء دون فرق',
  'neutral_keep_expiry': 'بلا فرق',
  'active': 'فعّال',
  'exhausted': 'نفدت كروتها',
  'expired': 'منتهٍ',
  'disabled': 'معطّل',
  'deleted': 'محذوفة',
  'archived': 'مؤرشفة',
  'cancelled': 'ملغاة',
  'revoked': 'ملغاة',
  'subscriber': 'مشترك',
  'card': 'كرت',
};

const _kValueKeys = {'charge_mode', 'policy', 'mode', 'status', 'user_type'};

String opsFieldLabel(String key) => kOpsFieldLabels[key] ?? key;

/// The web's `fmtValue(key, v)`.
String opsFormatValue(String key, Object? v) {
  if (v == null || v == '') return '-';
  if (v is bool) {
    return v ? kOpsValueLabels['true']! : kOpsValueLabels['false']!;
  }
  if (v is Map || v is List) return v.toString();
  final s = v.toString();
  if (key == 'expire_local' && s == 'no_expiry') return OpsTexts.noExpiry;
  if (key == 'expire_local' && s.startsWith('server_default:')) {
    return OpsTexts.serverDefault;
  }
  if (_kValueKeys.contains(key) && kOpsValueLabels.containsKey(s)) {
    return kOpsValueLabels[s]!;
  }
  return s;
}

/// The label/value rows of one confirmation step (web `stepBlock`).
List<(String, String)> opsStepRows({
  required Map<String, dynamic> values,
  required Map<String, dynamic> display,
  required Map<String, String> names,
  required Map<String, String> pendingRefs,
}) {
  final rows = <(String, String)>[];
  values.forEach((k, v) {
    // the local time is shown from `display` below
    if (k == 'expire_at' && display['expire_local'] != null) return;
    var shown = opsFormatValue(k, v);
    final name = names[k];
    if (name != null && name.isNotEmpty) shown = '$name (#$v)';
    rows.add((opsFieldLabel(k), shown));
  });
  display.forEach((k, v) => rows.add((opsFieldLabel(k), opsFormatValue(k, v))));
  pendingRefs.forEach((k, ref) {
    final m = RegExp(r'^\$step(\d+)\.').firstMatch(ref);
    rows.add((opsFieldLabel(k), '${OpsTexts.fromStep} ${m?.group(1) ?? ref}'));
  });
  return rows;
}

/// One line of a CHOICES item (web `choicesCard`).
String opsChoiceLine(Map<String, dynamic> it) {
  const keys = [
    'name',
    'username',
    'full_name',
    'plan_name',
    'plan',
    'label_ar',
    'status',
    'expires_local',
    'price',
    'currency',
  ];
  return [
    for (final k in keys)
      if (it[k] != null && '${it[k]}'.isNotEmpty) '${it[k]}',
  ].join(' · ');
}

/// The key/value rows of an INFO result (web `infoCard`).
List<(String, String)> opsInfoRows(Map<String, dynamic> data) => [
      for (final e in data.entries)
        if (!const {'items', 'query', 'truncated', 'batch_id'}.contains(e.key))
          (opsFieldLabel(e.key), opsFormatValue(e.key, e.value)),
    ];

/// One online-session line of an INFO result.
String opsOnlineLine(Map<String, dynamic> it) => [
      it['username'],
      opsFormatValue('user_type', it['user_type']),
      it['started_local'],
    ]
        .where((x) => x != null && '$x'.isNotEmpty && '$x' != '-')
        .map((x) => '$x')
        .join(' · ');

/// Bubble clock — «3:25 م». 12-hour with the Arabic ص/م marker and LATIN
/// digits, the app's convention everywhere else (DateFormat('HH:mm') style),
/// and locale-data free so it is identical in tests and on device.
String opsClock(DateTime t) {
  final l = t.toLocal();
  final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final m = l.minute.toString().padLeft(2, '0');
  return '$h:$m ${l.hour < 12 ? 'ص' : 'م'}';
}
