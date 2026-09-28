import 'card_batch_requests.dart';

/// Preview of a generated card username — the same arithmetic as the web
/// generator (`cards_generate.html` / `cards_repo.generate_cards`): the
/// requested length is the WHOLE name, so the random part is
/// `length − (prefix + batch number + suffix)`, at least 1, all lower-case.
class UsernamePreview {
  const UsernamePreview({
    required this.prefix,
    required this.batchNumber,
    required this.generated,
    required this.suffix,
    required this.warning,
  });

  final String prefix;

  /// Digits of the batch id, or '' when «تضمين رقم الحزمة» is off.
  final String batchNumber;

  /// Sample random part ('1234567890…' cut to its length).
  final String generated;
  final String suffix;

  /// Arabic warning, or null.
  final String? warning;

  int get generatedLength => generated.length;
  String get full => '$prefix$batchNumber$generated$suffix';

  factory UsernamePreview.of({
    required String prefix,
    required String suffix,
    required int? totalLength,
    String batchNumber = '',
    int count = 0,
  }) {
    final pre = normalizeCardAffix(prefix);
    final suf = normalizeCardAffix(suffix);
    final total = (totalLength == null || totalLength <= 0) ? 8 : totalLength;
    final fixed = pre.length + batchNumber.length + suf.length;
    final genLen = (total - fixed) < 1 ? 1 : total - fixed;
    final sample = ('1234567890' * (genLen ~/ 10 + 1)).substring(0, genLen);
    String? warning;
    if (fixed >= total) {
      warning = 'البادئة ورقم الحزمة واللاحقة تملأ الطول المطلوب، فبقي رقمٌ '
          'عشوائيّ واحد فقط. زِد «طول الاسم» ليبقى للجزء المولَّد خانات كافية.';
    } else if (genLen < 10 && count > _pow10(genLen)) {
      warning = 'خانات الجزء المولَّد لا تكفي لعدد البطاقات المطلوب دون '
          'تكرار. زِد «طول الاسم».';
    }
    return UsernamePreview(
      prefix: pre,
      batchNumber: batchNumber,
      generated: sample,
      suffix: suf,
      warning: warning,
    );
  }
}

int _pow10(int n) {
  var v = 1;
  for (var i = 0; i < n; i++) {
    v *= 10;
  }
  return v;
}
