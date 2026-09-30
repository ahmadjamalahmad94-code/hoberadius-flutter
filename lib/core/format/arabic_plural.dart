/// ONE Arabic count phrase for the whole app — «5 بطاقة», «منذ دقيقتان»,
/// «90 مشترك» and «3 مشترك» were each built by hand (f07 N-C7, f08).
///
/// Arabic number–noun agreement (by the last two digits):
/// - 0            → «0 بطاقة» (Latin digit + singular)
/// - 1            → the singular alone («بطاقة»)
/// - 2            → the dual («بطاقتان» / after a preposition «بطاقتين»)
/// - 3–10         → «3 بطاقات» (plural)
/// - 11–99        → «11 بطاقة» / «11 مشتركًا» (singular accusative, tamyīz)
/// - 100, 101, 102… → «100 بطاقة» (singular genitive)
/// Digits stay Latin (the app's number style).
library;

/// A countable Arabic noun.
class ArNoun {
  const ArNoun({
    required this.singular,
    required this.dual,
    required this.dualGenitive,
    required this.plural,
    String? tamyiz,
  }) : _tamyiz = tamyiz;

  final String singular;
  final String dual;

  /// The dual after a preposition / «منذ» («منذ دقيقتين»).
  final String dualGenitive;
  final String plural;
  final String? _tamyiz;

  /// Singular accusative after 11–99 («11 مشتركًا»); feminine nouns in «ة»
  /// do not change.
  String get tamyiz => _tamyiz ?? singular;
}

const arCard = ArNoun(
  singular: 'بطاقة',
  dual: 'بطاقتان',
  dualGenitive: 'بطاقتين',
  plural: 'بطاقات',
);
const arVoucherCard = ArNoun(
  singular: 'كرت',
  dual: 'كرتان',
  dualGenitive: 'كرتين',
  plural: 'كروت',
  tamyiz: 'كرتًا',
);
const arBatch = ArNoun(
  singular: 'حزمة',
  dual: 'حزمتان',
  dualGenitive: 'حزمتين',
  plural: 'حزم',
);
const arSubscriber = ArNoun(
  singular: 'مشترك',
  dual: 'مشتركان',
  dualGenitive: 'مشتركَين',
  plural: 'مشتركين',
  tamyiz: 'مشتركًا',
);
const arSession = ArNoun(
  singular: 'جلسة',
  dual: 'جلستان',
  dualGenitive: 'جلستين',
  plural: 'جلسات',
);
const arDevice = ArNoun(
  singular: 'جهاز',
  dual: 'جهازان',
  dualGenitive: 'جهازين',
  plural: 'أجهزة',
  tamyiz: 'جهازًا',
);
const arNotification = ArNoun(
  singular: 'إشعار',
  dual: 'إشعاران',
  dualGenitive: 'إشعارين',
  plural: 'إشعارات',
  tamyiz: 'إشعارًا',
);
const arItem = ArNoun(
  singular: 'عنصر',
  dual: 'عنصران',
  dualGenitive: 'عنصرين',
  plural: 'عناصر',
  tamyiz: 'عنصرًا',
);
const arRecord = ArNoun(
  singular: 'سجل',
  dual: 'سجلان',
  dualGenitive: 'سجلين',
  plural: 'سجلات',
  tamyiz: 'سجلًا',
);
const arRow = ArNoun(
  singular: 'صف',
  dual: 'صفّان',
  dualGenitive: 'صفّين',
  plural: 'صفوف',
  tamyiz: 'صفًّا',
);
const arMessage = ArNoun(
  singular: 'رسالة',
  dual: 'رسالتان',
  dualGenitive: 'رسالتين',
  plural: 'رسائل',
);
const arOperation = ArNoun(
  singular: 'عملية',
  dual: 'عمليتان',
  dualGenitive: 'عمليتين',
  plural: 'عمليات',
);
const arEntry = ArNoun(
  singular: 'قيد',
  dual: 'قيدان',
  dualGenitive: 'قيدين',
  plural: 'قيود',
  tamyiz: 'قيدًا',
);
const arCopy = ArNoun(
  singular: 'نسخة',
  dual: 'نسختان',
  dualGenitive: 'نسختين',
  plural: 'نسخ',
);
const arRule = ArNoun(
  singular: 'قاعدة',
  dual: 'قاعدتان',
  dualGenitive: 'قاعدتين',
  plural: 'قواعد',
);
const arSetting = ArNoun(
  singular: 'إعداد',
  dual: 'إعدادان',
  dualGenitive: 'إعدادين',
  plural: 'إعدادات',
  tamyiz: 'إعدادًا',
);
const arMinute = ArNoun(
  singular: 'دقيقة',
  dual: 'دقيقتان',
  dualGenitive: 'دقيقتين',
  plural: 'دقائق',
);
const arHour = ArNoun(
  singular: 'ساعة',
  dual: 'ساعتان',
  dualGenitive: 'ساعتين',
  plural: 'ساعات',
);
const arDay = ArNoun(
  singular: 'يوم',
  dual: 'يومان',
  dualGenitive: 'يومين',
  plural: 'أيام',
  tamyiz: 'يومًا',
);
const arMonth = ArNoun(
  singular: 'شهر',
  dual: 'شهران',
  dualGenitive: 'شهرين',
  plural: 'أشهر',
  tamyiz: 'شهرًا',
);
const arYear = ArNoun(
  singular: 'سنة',
  dual: 'سنتان',
  dualGenitive: 'سنتين',
  plural: 'سنوات',
);

/// «[n] [noun]» with Arabic agreement. [genitive]: after a preposition or
/// «منذ» (the dual becomes «دقيقتين»). [showOne]: «1 بطاقة» instead of the
/// bare singular (tables / counters where the digit matters).
String arCount(
  num n,
  ArNoun noun, {
  bool genitive = false,
  bool showOne = false,
}) {
  final v = n.round();
  final abs = v.abs();
  final lastTwo = abs % 100;
  if (abs == 1) return showOne ? '$v ${noun.singular}' : noun.singular;
  if (abs == 2) return genitive ? noun.dualGenitive : noun.dual;
  if (abs == 0) return '$v ${noun.singular}';
  if (lastTwo >= 3 && lastTwo <= 10) return '$v ${noun.plural}';
  if (lastTwo >= 11 && lastTwo <= 99) return '$v ${noun.tamyiz}';
  // 100, 101, 102, 200… → singular genitive
  return '$v ${noun.singular}';
}

/// «منذ دقيقتين» / «منذ 5 دقائق» — the relative-time phrase.
String arSince(num n, ArNoun unit) => 'منذ ${arCount(n, unit, genitive: true)}';

/// Server uptime («2d 3h 5m», «23m» — Latin unit letters) in Arabic:
/// «يومان و3 ساعات», «23 دقيقة». Unknown text is returned unchanged.
String formatUptime(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return text;
  final matches = RegExp(r'(\d+)\s*([dhms])\b').allMatches(text).toList();
  if (matches.isEmpty) return text;
  var d = 0, h = 0, m = 0, sec = 0;
  for (final x in matches) {
    final v = int.parse(x.group(1)!);
    switch (x.group(2)) {
      case 'd':
        d += v;
      case 'h':
        h += v;
      case 'm':
        m += v;
      case 's':
        sec += v;
    }
  }
  final parts = <String>[
    if (d > 0) arCount(d, arDay),
    if (h > 0) arCount(h, arHour),
    // minutes only below a day (days + hours are precise enough)
    if (m > 0 && d == 0) arCount(m, arMinute),
  ];
  if (parts.isEmpty) {
    return sec > 0 ? 'أقل من دقيقة' : arCount(0, arMinute);
  }
  return parts.join(' و');
}
