import 'card_batch_requests.dart';

/// The server's longest card username (`services/cards.USERNAME_LENGTH_MAX`,
/// fix3 cardsnet: 32 — the app said 16).
const int kCardUsernameLengthMax = 32;

/// The server's own refusal of a username length (the 422 text of
/// `_validate_generation_numbers` / `_check_username_length_fits`, word for
/// word), or null when the server accepts it. [batchNumber] is the batch
/// id's digits when «تضمين رقم الحزمة» is on.
String? cardUsernameLengthRefusal({
  required String prefix,
  required String suffix,
  required int? totalLength,
  String batchNumber = '',
}) {
  final total = totalLength;
  if (total == null || total < 1 || total > kCardUsernameLengthMax) {
    return 'طول اسم المستخدم يجب أن يكون بين 1 و$kCardUsernameLengthMax.';
  }
  final pre = normalizeCardAffix(prefix);
  final suf = normalizeCardAffix(suffix);
  final fixed = pre.length + batchNumber.length + suf.length;
  if (fixed < total) return null;
  final parts = [
    'البادئة ${pre.length}',
    if (batchNumber.isNotEmpty) 'رقم الحزمة ${batchNumber.length}',
    'اللاحقة ${suf.length}',
  ];
  return 'طول اسم المستخدم المختار $total محارف لا يتّسع: الأجزاء الثابتة '
      '(${parts.join(' + ')} = $fixed) لا تترك خانةً للأرقام العشوائيّة. '
      'اجعل الطول ${fixed + 1} على الأقلّ (والحدّ $kCardUsernameLengthMax)، '
      'أو قصّر البادئة/اللاحقة.';
}

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
    this.refusal,
  });

  /// The server would REFUSE this length (its exact 422 text): no sample
  /// name is shown — the preview never promises a name the server refuses.
  final String? refusal;

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
    final refusal = cardUsernameLengthRefusal(
      prefix: prefix,
      suffix: suffix,
      totalLength: totalLength,
      batchNumber: batchNumber,
    );
    if (refusal != null) {
      return UsernamePreview(
        prefix: pre,
        batchNumber: batchNumber,
        generated: '',
        suffix: suf,
        warning: null,
        refusal: refusal,
      );
    }
    final total = totalLength!;
    final fixed = pre.length + batchNumber.length + suf.length;
    final genLen = total - fixed;
    final sample = ('1234567890' * (genLen ~/ 10 + 1)).substring(0, genLen);
    String? warning;
    if (genLen < 10 && count > _pow10(genLen)) {
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
