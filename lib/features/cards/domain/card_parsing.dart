/// Shared JSON parsing helpers used by every Card-domain class.
///
/// Kept as top-level functions so each split file in this directory can
/// import only this thin utility without leaking the rest of the
/// domain. Public so the barrel `card_model.dart` does not have to
/// re-export them, but intended for in-feature use only.
library;

int? cardParseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

num? cardParseNum(Object? value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

bool cardParseBool(Object? value) =>
    value == true ||
    value == 1 ||
    value == '1' ||
    value == 'true' ||
    value == 'on';

DateTime? cardParseDate(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  if (text.isEmpty) return null;
  try {
    return DateTime.parse(text.replaceAll('Z', ''));
  } catch (_) {
    return null;
  }
}

String? cardParseStringOrNull(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

List<String> cardParseStringList(Object? value) {
  return (value as List? ?? const [])
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList();
}

/// Falls back to `count - used` (clamped ≥ 0) when the server didn't
/// include an explicit `available_count`. Mirrors the original behavior
/// from `CardBatch._availableFallback`.
int cardAvailableFallback(Map<String, dynamic> json) {
  final total = cardParseInt(json['count']) ?? 0;
  final consumed = cardParseInt(json['used']) ?? 0;
  return (total - consumed).clamp(0, total).toInt();
}
