import 'package:hoberadius_app/core/api/paging.dart';
import 'package:hoberadius_app/core/format/currency.dart';
import 'package:hoberadius_app/core/format/server_time.dart';

class RevenuePage {
  const RevenuePage({
    required this.items,
    required this.count,
    this.serverCollected,
    this.collectedByCurrency = const [],
    this.mixedCurrency = false,
    this.hasMore = false,
  });

  /// `has_more` (fix2 servers); older servers never page.
  final bool hasMore;

  /// Stable row key across pages (payments and batch rows share ids).
  static String rowKey(RevenueRecord r) => '${r.sourceType}:${r.id}';

  /// This page with [more] rows appended (duplicates dropped).
  RevenuePage withMore(List<RevenueRecord> more, {required bool hasMore}) {
    final (merged, _) = mergeUniqueBy(items, more, rowKey);
    return RevenuePage(
      items: merged,
      count: merged.length,
      serverCollected: serverCollected,
      collectedByCurrency: collectedByCurrency,
      mixedCurrency: mixedCurrency,
      hasMore: hasMore,
    );
  }

  /// `totals.by_currency` (updated servers): payments per currency.
  final List<CurrencyAmount> collectedByCurrency;
  final bool mixedCurrency;

  final List<RevenueRecord> items;
  final int count;

  /// `totals.collected` of the updated server: net subscriber payments of
  /// the whole ledger (not only the loaded rows).
  final double? serverCollected;

  factory RevenuePage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final rawItems = data['items'];
    final totals = data['totals'];
    final collected = totals is Map ? totals['collected'] : null;
    return RevenuePage(
      collectedByCurrency:
          totals is Map ? parseByCurrency(totals['by_currency']) : const [],
      mixedCurrency: totals is Map && totals['mixed_currency'] == true,
      hasMore: data['has_more'] == true,
      serverCollected: collected is num
          ? collected.toDouble()
          : double.tryParse('${collected ?? ''}'),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => RevenueRecord.fromJson(_map(item)))
              .toList()
          : const [],
      count: _int(data['count']),
    );
  }

  /// Loaded rows that are NOT subscriber payments (card batches…) and not
  /// voided — the part the server has no total for.
  Iterable<RevenueRecord> get _otherLive => items.where(
        (i) => i.sourceType != 'subscriber_payment' && !i.isVoided,
      );

  /// Subscriber-payment money per currency: the SERVER's totals over the
  /// whole ledger (payments − voids); null on servers without totals.
  List<CurrencyAmount>? get _serverPayments {
    if (collectedByCurrency.isNotEmpty) return collectedByCurrency;
    final server = serverCollected;
    if (server == null) return null;
    final cur = items
        .where((i) => i.sourceType == 'subscriber_payment')
        .map((i) => i.currency)
        .firstWhere((c) => c.isNotEmpty, orElse: () => '');
    return [CurrencyAmount(cur, server)];
  }

  List<CurrencyAmount> _perCurrency(double Function(RevenueRecord r) field) {
    final server = _serverPayments;
    final rows = server == null
        ? items.where((i) => !i.isVoided)
        : _otherLive;
    final out = <String, double>{};
    for (final c in server ?? const <CurrencyAmount>[]) {
      out[c.currency] = (out[c.currency] ?? 0) + c.amount;
    }
    for (final r in rows) {
      out[r.currency] = (out[r.currency] ?? 0) + field(r);
    }
    return [
      for (final e in out.entries)
        CurrencyAmount(e.key, (e.value * 100).round() / 100),
    ];
  }

  /// «إجمالي المحصل» per currency (never one mixed sum, never voided rows).
  List<CurrencyAmount> get collectedPerCurrency =>
      _perCurrency((r) => r.collectedAmount);

  /// «الربح الصافي» per currency. A subscriber payment's profit is its
  /// amount (server rule), so the server's payment totals are used; voided
  /// rows (their net_profit stays = amount) are excluded (r09 N7 / r11 M-2).
  List<CurrencyAmount> get netProfitPerCurrency =>
      _perCurrency((r) => r.netProfit);

  /// «حصة الشركة» per currency, same rules.
  List<CurrencyAmount> get companySharePerCurrency =>
      _perCurrency((r) => r.companyShare);

  RevenueSummary get summary {
    final fromRows = RevenueSummary.fromItems(items);
    final server = serverCollected;
    if (server == null) return fromRows;
    // Server total covers ALL subscriber payments; other sources (card
    // batches…) are added from the loaded rows.
    final others = items
        .where((i) => i.sourceType != 'subscriber_payment' && !i.isVoided)
        .fold<double>(0, (sum, i) => sum + i.collectedAmount);
    return fromRows.withCollected(server + others);
  }
}

class RevenueSummary {
  const RevenueSummary({
    required this.totalCollected,
    required this.totalWholesaleCost,
    required this.totalNetProfit,
    required this.totalCompanyShare,
    required this.totalDistributorShare,
    required this.postedCount,
  });

  final double totalCollected;
  final double totalWholesaleCost;
  final double totalNetProfit;
  final double totalCompanyShare;
  final double totalDistributorShare;
  final int postedCount;

  /// Sums of the given rows; voided rows carry no money.
  factory RevenueSummary.fromItems(List<RevenueRecord> all) {
    final items = all.where((i) => !i.isVoided).toList();
    return RevenueSummary(
      totalCollected: items.fold(0, (sum, item) => sum + item.collectedAmount),
      totalWholesaleCost:
          items.fold(0, (sum, item) => sum + item.wholesaleCost),
      totalNetProfit: items.fold(0, (sum, item) => sum + item.netProfit),
      totalCompanyShare: items.fold(0, (sum, item) => sum + item.companyShare),
      totalDistributorShare:
          items.fold(0, (sum, item) => sum + item.distributorShare),
      postedCount: items.where((item) => item.status == 'posted').length,
    );
  }

  RevenueSummary withCollected(double collected) => RevenueSummary(
        totalCollected: collected,
        totalWholesaleCost: totalWholesaleCost,
        totalNetProfit: totalNetProfit,
        totalCompanyShare: totalCompanyShare,
        totalDistributorShare: totalDistributorShare,
        postedCount: postedCount,
      );
}

class RevenueRecord {
  const RevenueRecord({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.priceSnapshotId,
    required this.originalPrice,
    required this.retailPrice,
    required this.wholesaleCost,
    required this.collectedAmount,
    required this.debtAmount,
    required this.discountAmount,
    required this.netProfit,
    required this.companyShare,
    required this.distributorShare,
    required this.managerShare,
    required this.currency,
    required this.status,
    required this.metadata,
    required this.createdAt,
  });

  final int id;
  final String sourceType;
  final int? sourceId;
  final int? priceSnapshotId;
  final double originalPrice;
  final double retailPrice;
  final double wholesaleCost;
  final double collectedAmount;
  final double debtAmount;
  final double discountAmount;
  final double netProfit;
  final double companyShare;
  final double distributorShare;
  final double managerShare;
  final String currency;
  final String status;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  factory RevenueRecord.fromJson(Map<String, dynamic> json) {
    return RevenueRecord(
      id: _int(json['id']),
      sourceType: _string(json['source_type']),
      sourceId: _nullableInt(json['source_id']),
      priceSnapshotId: _nullableInt(json['price_snapshot_id']),
      originalPrice: _moneyField(json, 'original_price'),
      retailPrice: _moneyField(json, 'retail_price'),
      wholesaleCost: _moneyField(json, 'wholesale_cost'),
      collectedAmount:
          _moneyField(json, 'collected_amount', aliases: const ['collected']),
      debtAmount: _moneyField(json, 'debt_amount'),
      discountAmount: _moneyField(json, 'discount_amount'),
      netProfit: _moneyField(json, 'net_profit'),
      companyShare: _moneyField(json, 'company_share'),
      distributorShare: _moneyField(json, 'distributor_share'),
      managerShare: _moneyField(json, 'manager_share'),
      currency: _string(json['currency']),
      status: _string(json['status'], fallback: 'pending'),
      metadata: _map(json['metadata']),
      createdAt: _date(json['created_at']),
    );
  }

  String get statusLabel => revenueStatusLabel(status);

  /// A reversed row: shown, but never summed.
  bool get isVoided {
    final v = status.trim().toLowerCase();
    return v == 'voided' || v == 'reversed' || v == 'cancelled';
  }

  String get sourceLabel {
    final base = revenueSourceLabel(sourceType);
    return sourceId == null ? base : '$base #$sourceId';
  }
}

String revenueStatusLabel(String value) {
  return switch (value) {
    'posted' => 'مرحلة',
    'pending' => 'بانتظار الترحيل',
    'voided' => 'ملغاة',
    'refunded' => 'مسترجعة',
    _ => value.trim().isEmpty ? 'غير محددة' : value,
  };
}

String revenueSourceLabel(String value) {
  return switch (value) {
    'card_batch' => 'دفعة كروت',
    'card_sale' => 'بيع كروت',
    'card_user_purchase' => 'شراء مستخدم كروت',
    'subscriber_payment' => 'دفعة مشترك',
    'invoice' => 'فاتورة',
    'subscription' => 'اشتراك',
    'wallet_transaction' => 'حركة محفظة',
    _ => value.trim().isEmpty ? 'غير محدد' : value,
  };
}

Map<String, dynamic> _data(Map<String, dynamic> json) {
  return _map(json['data']);
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const {};
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(Object? value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _double(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double _moneyField(
  Map<String, dynamic> json,
  String key, {
  List<String> aliases = const [],
}) {
  final candidates = [
    key,
    ...aliases,
    '${key}_minor',
  ];
  for (final candidate in candidates) {
    if (json.containsKey(candidate)) {
      final value = json[candidate];
      if (candidate.endsWith('_minor')) {
        return _double(value) / 100;
      }
      return _double(value);
    }
  }
  return 0;
}

DateTime? _date(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return parseServerDateTime(text);
}
