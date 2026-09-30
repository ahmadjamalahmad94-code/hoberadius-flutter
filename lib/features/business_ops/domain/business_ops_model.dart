import 'package:hoberadius_app/core/format/currency.dart';
import 'package:hoberadius_app/core/format/server_time.dart';

/// Business OS console models — finance ledger corrections, pricing snapshots,
/// and the operator summary. Mirrors the `/api/v1/business/*`, `/finance/*`,
/// and `/pricing/*` contracts (admin-authed via `require_api_token`).
///
/// Money fields arrive as strings (`minor_to_money` formats them server-side),
/// so they are kept verbatim to preserve the exact decimal rendering.
class BusinessSummary {
  const BusinessSummary({
    required this.wallets,
    required this.walletBalance,
    required this.ledgerEntries,
    required this.ledgerTotal,
    required this.events,
    required this.priceSnapshots,
    required this.revenueRecords,
  });

  final int wallets;
  final String walletBalance;
  final int ledgerEntries;
  final String ledgerTotal;
  final int events;
  final int priceSnapshots;
  final int revenueRecords;

  factory BusinessSummary.fromJson(Map<String, dynamic> j) {
    return BusinessSummary(
      wallets: _int(j['wallets']) ?? 0,
      walletBalance: _money(j['wallet_balance']),
      ledgerEntries: _int(j['ledger_entries']) ?? 0,
      ledgerTotal: _money(j['ledger_total']),
      events: _int(j['events']) ?? 0,
      priceSnapshots: _int(j['price_snapshots']) ?? 0,
      revenueRecords: _int(j['revenue_records']) ?? 0,
    );
  }

  static const empty = BusinessSummary(
    wallets: 0,
    walletBalance: '0.00',
    ledgerEntries: 0,
    ledgerTotal: '0.00',
    events: 0,
    priceSnapshots: 0,
    revenueRecords: 0,
  );
}

/// A single Business-OS ledger entry. The list is append-only; "corrections"
/// are themselves entries of type `correction` that offset a prior record.
class BusinessLedgerEntry {
  const BusinessLedgerEntry({
    required this.id,
    required this.entryType,
    required this.debitAccount,
    required this.creditAccount,
    required this.amount,
    required this.currency,
    required this.actorType,
    required this.targetType,
    required this.referenceType,
    required this.referenceId,
    required this.createdAt,
    this.actorId,
    this.targetId,
    this.debitAccountLabel = '',
    this.creditAccountLabel = '',
    this.targetLabel = '',
  });

  final int id;
  final String entryType;
  final String debitAccount;
  final String creditAccount;
  final String amount;
  final String currency;
  final String actorType;
  final int? actorId;
  final String targetType;
  final int? targetId;
  final String referenceType;
  final int? referenceId;
  final DateTime? createdAt;

  /// Server Arabic labels (FIX2 network contract, optional: older servers
  /// omit them and the app maps the raw codes itself).
  final String debitAccountLabel;
  final String creditAccountLabel;
  final String targetLabel;

  bool get isCorrection => entryType == 'correction';

  factory BusinessLedgerEntry.fromJson(Map<String, dynamic> j) {
    return BusinessLedgerEntry(
      id: _int(j['id']) ?? 0,
      entryType: _string(j['entry_type']),
      debitAccount: _string(j['debit_account']),
      creditAccount: _string(j['credit_account']),
      amount: _money(j['amount']),
      currency: _string(j['currency']),
      actorType: _string(j['actor_type']),
      actorId: _int(j['actor_id']),
      targetType: _string(j['target_type']),
      targetId: _int(j['target_id']),
      referenceType: _string(j['reference_type']),
      referenceId: _int(j['reference_id']),
      createdAt: _date(j['created_at']),
      debitAccountLabel: _string(j['debit_account_label']).trim(),
      creditAccountLabel: _string(j['credit_account_label']).trim(),
      targetLabel: _string(j['target_label']).trim(),
    );
  }
}

/// An immutable pricing snapshot captured for a future revenue action.
class PriceSnapshot {
  const PriceSnapshot({
    required this.id,
    required this.referenceType,
    required this.referenceId,
    required this.packageId,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.effectivePrice,
    required this.discountAmount,
    required this.currency,
    required this.capturedAt,
    required this.capturedByType,
    this.capturedById,
  });

  final int id;
  final String referenceType;
  final int? referenceId;
  final int? packageId;
  final String retailPrice;
  final String wholesalePrice;
  final String effectivePrice;
  final String discountAmount;
  final String currency;
  final DateTime? capturedAt;
  final String capturedByType;
  final int? capturedById;

  factory PriceSnapshot.fromJson(Map<String, dynamic> j) {
    return PriceSnapshot(
      id: _int(j['id']) ?? 0,
      referenceType: _string(j['reference_type']),
      referenceId: _int(j['reference_id']),
      packageId: _int(j['package_id']),
      retailPrice: _money(j['retail_price']),
      wholesalePrice: _money(j['wholesale_price']),
      effectivePrice: _money(j['effective_price']),
      discountAmount: _money(j['discount_amount']),
      currency: _string(j['currency']),
      capturedAt: _date(j['captured_at']),
      capturedByType: _string(j['captured_by_type']),
      capturedById: _int(j['captured_by_id']),
    );
  }
}

/// Ledger entry types accepted by the Business-OS service. Used to label the
/// debit/credit pair on existing records. (Corrections themselves are posted
/// as `correction`; the API forces that type.)
String businessLedgerTypeLabel(String value) {
  return switch (value.trim().toLowerCase()) {
    'payment' => 'دفعة',
    'renewal' => 'تجديد',
    'debt' => 'دين',
    'loan' => 'سلفة',
    'discount' => 'خصم',
    'wallet_recharge' => 'شحن محفظة',
    'card_sale' => 'بيع بطاقة',
    'batch_creation' => 'إنشاء حزمة',
    'profit_share' => 'حصة ربح',
    'reversal' => 'قيد عكسي',
    'correction' => 'تصحيح',
    '' => 'غير محدد',
    _ => value,
  };
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _money(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return '0';
  final n = num.tryParse(text);
  return n == null ? text : formatMoneyAmount(n);
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _date(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return parseServerDateTime(text);
}
