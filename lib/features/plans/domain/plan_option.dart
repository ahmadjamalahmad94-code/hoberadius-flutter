/// A lightweight plan row for a picker on a create form — the fix3 lite
/// contract (`GET /api/v1/plans/options`, alias `/profiles/options`):
/// `{id, name, price, currency, duration_minutes, duration_value,
/// duration_unit, validity_days, period_minutes, plan_type}`.
///
/// This endpoint is readable by `plans.view` OR `users.create` OR
/// `cards.generate` (`anyweb:` guard), so a manager who can create
/// subscribers or generate cards but cannot see the plans page still gets a
/// real picker instead of a bare numeric field. Active plans only (enabled,
/// not archived) — same filter the full `/api/v1/profiles` list needs
/// `plans.view` to see.
class PlanOption {
  const PlanOption({
    required this.id,
    required this.name,
    this.price = 0,
    this.currency = '',
    this.durationMinutes = 0,
    this.durationValue = 0,
    this.durationUnit = '',
    this.validityDays = 0,
    this.periodMinutes = 0,
    this.planType = '',
  });

  final int id;
  final String name;
  final num price;
  final String currency;
  final int durationMinutes;
  final int durationValue;
  final String durationUnit;
  final int validityDays;
  final int periodMinutes;
  final String planType;

  factory PlanOption.fromJson(Map<String, dynamic> j) => PlanOption(
        id: _int(j['id']) ?? 0,
        name: (j['name'] ?? '').toString(),
        price: _num(j['price']) ?? 0,
        currency: (j['currency'] ?? '').toString().trim().toUpperCase(),
        durationMinutes: _int(j['duration_minutes']) ?? 0,
        durationValue: _int(j['duration_value']) ?? 0,
        durationUnit: (j['duration_unit'] ?? '').toString(),
        validityDays: _int(j['validity_days']) ?? 0,
        periodMinutes: _int(j['period_minutes']) ?? 0,
        planType: (j['plan_type'] ?? '').toString(),
      );

  static int? _int(Object? v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));
  static num? _num(Object? v) =>
      v == null ? null : (v is num ? v : num.tryParse(v.toString()));
}
