class RevenuePage {
  const RevenuePage({required this.items, required this.count});

  final List<RevenueRecord> items;
  final int count;

  factory RevenuePage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final rawItems = data['items'];
    return RevenuePage(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => RevenueRecord.fromJson(_map(item)))
              .toList()
          : const [],
      count: _int(data['count']),
    );
  }

  RevenueSummary get summary {
    return RevenueSummary.fromItems(items);
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

  factory RevenueSummary.fromItems(List<RevenueRecord> items) {
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
      currency: _string(json['currency'], fallback: 'JOD'),
      status: _string(json['status'], fallback: 'pending'),
      metadata: _map(json['metadata']),
      createdAt: _date(json['created_at']),
    );
  }

  String get statusLabel => revenueStatusLabel(status);

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
  return DateTime.tryParse(text.replaceAll('Z', ''));
}
