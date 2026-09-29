/// One reader for every number the operator types (money, days, speeds…).
///
/// The stress re-test found fields that silently rewrote what was typed:
/// «1e9» became 19 (a real 19 ILS payment), «-1» became 1 (a 1.00 loan) and
/// the plan form saved 0 for «٩», «7.5» or «abc». The rule now is:
/// - Arabic-Indic («٠-٩») and Persian («۰-۹») digits are accepted;
/// - «.» and «٫» (U+066B) are the decimal separator;
/// - anything else is REJECTED with a visible Arabic message — never
///   stripped, never guessed. The text in the field is left as typed.
library;

import 'package:flutter/services.dart';

const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';
const _persianDigits = '۰۱۲۳۴۵۶۷۸۹';

/// Arabic-Indic / Persian digits → Latin and «٫» → «.». Nothing else is
/// changed (letters, «-», «e», «,» stay so the validator can name them).
String latinizeNumberText(String raw) {
  final b = StringBuffer();
  for (final rune in raw.runes) {
    final ch = String.fromCharCode(rune);
    final a = _arabicDigits.indexOf(ch);
    if (a >= 0) {
      b.write(a);
      continue;
    }
    final p = _persianDigits.indexOf(ch);
    if (p >= 0) {
      b.write(p);
      continue;
    }
    b.write(ch == '٫' ? '.' : ch);
  }
  return b.toString();
}

/// Only Latin/Arabic-Indic digits → Latin (search boxes, phone numbers).
String latinizeDigits(String raw) {
  final b = StringBuffer();
  for (final rune in raw.runes) {
    final ch = String.fromCharCode(rune);
    final a = _arabicDigits.indexOf(ch);
    final p = _persianDigits.indexOf(ch);
    b.write(a >= 0 ? '$a' : (p >= 0 ? '$p' : ch));
  }
  return b.toString();
}

/// The outcome of reading one typed number.
class NumberInput {
  const NumberInput._(this.value, this.error, this.isEmpty);

  /// The parsed value (null when empty or invalid).
  final num? value;

  /// Arabic reason the text is not a number of the requested kind.
  final String? error;

  /// The field is empty (or only spaces).
  final bool isEmpty;

  bool get isValid => error == null && value != null;
}

final RegExp _decimalRe = RegExp(r'^-?\d+(\.\d+)?$');
final RegExp _intRe = RegExp(r'^-?\d+$');

/// Reads [raw] strictly. [decimal] allows one fraction part; [allowNegative]
/// allows one leading «-». Returns the value or a precise Arabic error.
NumberInput readNumberInput(
  String? raw, {
  bool decimal = true,
  bool allowNegative = false,
}) {
  final text = latinizeNumberText((raw ?? '').trim()).replaceAll('−', '-');
  if (text.isEmpty) return const NumberInput._(null, null, true);
  String? error;
  if (!allowNegative && text.contains('-')) {
    error = 'القيم السالبة غير مسموحة.';
  } else if (text.contains(RegExp('[eE]'))) {
    error = 'اكتب الرقم كاملًا — صيغة «e» غير مقبولة.';
  } else if (text.contains(',') || text.contains('٬') || text.contains('،')) {
    error = decimal
        ? 'استخدم «.» أو «٫» للكسر العشري، بدون فواصل.'
        : 'أدخل عددًا صحيحًا بدون فواصل.';
  } else if (!decimal && text.contains('.')) {
    error = 'أدخل عددًا صحيحًا بدون كسور.';
  } else if (!(decimal ? _decimalRe : _intRe).hasMatch(text)) {
    error = 'أدخل رقمًا صحيحًا (أرقام فقط).';
  }
  if (error != null) return NumberInput._(null, error, false);
  final num? value = decimal ? double.tryParse(text) : int.tryParse(text);
  if (value == null || !value.isFinite) {
    return const NumberInput._(null, 'الرقم غير صالح.', false);
  }
  // «-0» is just 0 (the server used to store -0.0 debts).
  final normalised = value == 0 ? (decimal ? 0.0 : 0) : value;
  return NumberInput._(normalised, null, false);
}

/// The value of [raw], or null when it is empty or not a valid number.
num? parseNumberInput(String? raw, {bool decimal = true, bool allowNegative = false}) =>
    readNumberInput(raw, decimal: decimal, allowNegative: allowNegative).value;

/// Double convenience of [parseNumberInput].
double? parseDecimalInput(String? raw, {bool allowNegative = false}) =>
    parseNumberInput(raw, allowNegative: allowNegative)?.toDouble();

/// Int convenience of [parseNumberInput] (whole numbers only).
int? parseIntInput(String? raw, {bool allowNegative = false}) =>
    parseNumberInput(raw, decimal: false, allowNegative: allowNegative)?.toInt();

String _fmtBound(num v) {
  if (v == v.roundToDouble()) {
    final s = v.toInt().toString();
    // 100000 → 100,000 (Latin digits, grouped).
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0 && s[i - 1] != '-') b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
  return v.toString();
}

/// Form validator built on [readNumberInput].
///
/// [required]: empty is an error; [min]/[max] are inclusive unless
/// [minExclusive]; [emptyMessage] replaces the generic «مطلوب».
String? validateNumberInput(
  String? raw, {
  bool required = true,
  bool decimal = true,
  bool allowNegative = false,
  num? min,
  num? max,
  bool minExclusive = false,
  String? emptyMessage,
  String? maxMessage,
}) {
  final r = readNumberInput(raw, decimal: decimal, allowNegative: allowNegative);
  if (r.isEmpty) return required ? (emptyMessage ?? 'مطلوب') : null;
  if (r.error != null) return r.error;
  final v = r.value!;
  if (min != null) {
    if (minExclusive ? v <= min : v < min) {
      return minExclusive
          ? 'يجب أن تكون القيمة أكبر من ${_fmtBound(min)}.'
          : 'أقل قيمة مسموحة ${_fmtBound(min)}.';
    }
  }
  if (max != null && v > max) {
    return maxMessage ?? 'أعلى قيمة مسموحة ${_fmtBound(max)}.';
  }
  return null;
}

/// Shared input formatters for number fields. They never strip or rewrite
/// characters (that silently turned «1e9» into 19); they only stop absurdly
/// long input. Validation happens in [validateNumberInput].
final List<TextInputFormatter> numberFieldFormatters = <TextInputFormatter>[
  LengthLimitingTextInputFormatter(24),
];

/// Keyboard for decimal number fields.
const TextInputType decimalKeyboard =
    TextInputType.numberWithOptions(decimal: true);

/// Keyboard for whole-number fields.
const TextInputType integerKeyboard = TextInputType.number;

/// Groups a bound for messages (100000 → «100,000»).
String formatNumberBound(num v) => _fmtBound(v);
