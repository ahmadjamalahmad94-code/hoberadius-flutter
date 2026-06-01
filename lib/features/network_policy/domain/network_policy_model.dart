class NetworkPolicyKind {
  const NetworkPolicyKind({
    required this.slug,
    required this.serviceKey,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.childPath,
    required this.childSingular,
  });

  final String slug;
  final String serviceKey;
  final String label;
  final String shortLabel;
  final String description;
  final String childPath;
  final String childSingular;

  bool get hasChildren => childPath.isNotEmpty;
  bool get isRemoteAccess => slug == 'remote-access';
  bool get isWebBlock => slug == 'web-block';
  bool get isWalledGarden => slug == 'walled-garden';
}

const networkPolicyKinds = <NetworkPolicyKind>[
  NetworkPolicyKind(
    slug: 'remote-access',
    serviceKey: 'remote_access',
    label: 'الوصول البعيد',
    shortLabel: 'وصول بعيد',
    description: 'فتح خدمات إدارة الراوتر لمصادر موثوقة وبمدة واضحة.',
    childPath: '',
    childSingular: '',
  ),
  NetworkPolicyKind(
    slug: 'web-block',
    serviceKey: 'web_block',
    label: 'حظر المواقع',
    shortLabel: 'حظر',
    description: 'حجب نطاقات أو عناوين محددة عن المشتركين.',
    childPath: 'targets',
    childSingular: 'هدف حظر',
  ),
  NetworkPolicyKind(
    slug: 'walled-garden',
    serviceKey: 'walled_garden',
    label: 'المواقع المسموحة',
    shortLabel: 'سماح',
    description: 'السماح بمواقع الدفع أو الدعم قبل تسجيل الدخول للبوابة.',
    childPath: 'entries',
    childSingular: 'عنصر سماح',
  ),
];

NetworkPolicyKind networkPolicyKindBySlug(String slug) {
  return networkPolicyKinds.firstWhere(
    (kind) => kind.slug == slug,
    orElse: () => networkPolicyKinds.first,
  );
}

class NetworkPolicyPage {
  const NetworkPolicyPage({required this.items, required this.count});

  final List<NetworkPolicy> items;
  final int count;

  factory NetworkPolicyPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final items = _list(data['items'])
        .map((item) => NetworkPolicy.fromJson(_map(item)))
        .toList();
    return NetworkPolicyPage(items: items, count: _int(data['count']));
  }
}

class NetworkPolicy {
  const NetworkPolicy({
    required this.id,
    required this.routerId,
    required this.name,
    required this.slug,
    required this.enabled,
    required this.fields,
  });

  final int id;
  final int routerId;
  final String name;
  final String slug;
  final bool enabled;
  final Map<String, dynamic> fields;

  factory NetworkPolicy.fromJson(Map<String, dynamic> json) {
    return NetworkPolicy(
      id: _int(json['id']),
      routerId: _int(json['router_id']),
      name: _string(json['name']),
      slug: _string(json['slug']),
      enabled: _bool(json['enabled'], fallback: true),
      fields: json,
    );
  }

  String value(String key) => _string(fields[key]);

  bool flag(String key) => _bool(fields[key]);
}

class NetworkPolicyChildrenPage {
  const NetworkPolicyChildrenPage({
    required this.items,
    required this.count,
    required this.counts,
  });

  final List<NetworkPolicyChild> items;
  final int count;
  final Map<String, int> counts;

  factory NetworkPolicyChildrenPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return NetworkPolicyChildrenPage(
      items: _list(data['items'])
          .map((item) => NetworkPolicyChild.fromJson(_map(item)))
          .toList(),
      count: _int(data['count']),
      counts: _map(data['counts']).map(
        (key, value) => MapEntry(key, _int(value)),
      ),
    );
  }
}

class NetworkPolicyChild {
  const NetworkPolicyChild({
    required this.id,
    required this.policyId,
    required this.value,
    required this.normalizedValue,
    required this.kind,
    required this.category,
    required this.status,
    required this.notes,
    required this.dstPort,
    required this.protocol,
  });

  final int id;
  final int policyId;
  final String value;
  final String normalizedValue;
  final String kind;
  final String category;
  final String status;
  final String notes;
  final String dstPort;
  final String protocol;

  factory NetworkPolicyChild.fromJson(Map<String, dynamic> json) {
    return NetworkPolicyChild(
      id: _int(json['id']),
      policyId: _int(json['policy_id']),
      value: _string(json['value']),
      normalizedValue: _string(json['normalized_value']),
      kind: _string(json['target_type'], fallback: _string(json['entry_type'])),
      category: _string(json['category']),
      status: _string(json['status'], fallback: 'active'),
      notes: _string(json['notes']),
      dstPort: _string(json['dst_port']),
      protocol: _string(json['protocol']),
    );
  }

  String get statusLabel => switch (status) {
        'active' => 'مفعّل',
        'disabled' => 'معطّل',
        'invalid' => 'غير صالح',
        'manual_review' => 'يحتاج مراجعة',
        _ => status.trim().isEmpty ? 'غير محدد' : 'حالة غير معروفة',
      };

  String get kindLabel => switch (kind) {
        'domain' => 'نطاق',
        'ip' => 'عنوان IP',
        'cidr' => 'شبكة CIDR',
        'dst_host' => 'اسم نطاق',
        'dst_address' => 'عنوان IP',
        'dst_address_list' => 'قائمة عناوين',
        _ => kind.trim().isEmpty ? 'غير محدد' : 'نوع غير معروف',
      };
}

class NetworkPolicyPreview {
  const NetworkPolicyPreview({
    required this.service,
    required this.policyId,
    required this.routerId,
    required this.canApply,
    required this.commandCount,
    required this.blockingErrors,
    required this.warnings,
    required this.scriptHash,
    required this.forwardScript,
    required this.rollbackScript,
    required this.healthScore,
    required this.explanation,
  });

  final String service;
  final int policyId;
  final int routerId;
  final bool canApply;
  final int commandCount;
  final List<String> blockingErrors;
  final List<String> warnings;
  final String scriptHash;
  final String forwardScript;
  final String rollbackScript;
  final int healthScore;
  final String explanation;

  factory NetworkPolicyPreview.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final summary = _map(data['summary']);
    final health = _map(data['health_score']);
    final beginner = _map(data['beginner_explanation']);
    return NetworkPolicyPreview(
      service: _string(data['service']),
      policyId: _int(data['policy_id']),
      routerId: _int(data['router_id']),
      canApply: _bool(data['can_apply']),
      commandCount: _int(summary['command_count']),
      blockingErrors: _strings(summary['blocking_errors']),
      warnings: _strings(summary['warnings']),
      scriptHash: _string(data['script_hash']),
      forwardScript: _string(data['forward_script']),
      rollbackScript: _string(data['rollback_script']),
      healthScore: _int(
        health['score'],
        fallback: _int(health['health_score']),
      ),
      explanation: _string(
        beginner['plain_text'],
        fallback: _string(beginner['summary']),
      ),
    );
  }
}

String networkPolicyFieldLabel(String key, Object? value) {
  final text = _string(value);
  if (text.isEmpty) return '';
  return switch (key) {
    'allow_winbox' => _bool(value) ? 'Winbox مسموح' : 'Winbox مغلق',
    'allow_ssh' => _bool(value) ? 'SSH مسموح' : 'SSH مغلق',
    'allow_api' => _bool(value) ? 'API مسموح' : 'API مغلق',
    'allow_api_ssl' => _bool(value) ? 'API-SSL مسموح' : 'API-SSL مغلق',
    'allow_webfig_http' =>
      _bool(value) ? 'WebFig HTTP مسموح' : 'WebFig HTTP مغلق',
    'allow_webfig_https' =>
      _bool(value) ? 'WebFig HTTPS مسموح' : 'WebFig HTTPS مغلق',
    'source_address_list' => 'مصدر موثوق: $text',
    'expires_at' => 'ينتهي: $text',
    'reason' => 'السبب: $text',
    'scope' => text == 'all_users' ? 'النطاق: كل المستخدمين' : 'النطاق: $text',
    'fail_open' => _bool(value) ? 'يفشل باتجاه السماح' : 'يفشل باتجاه الحظر',
    'hotspot_profile' => 'بروفايل الهوتسبوت: $text',
    _ => '',
  };
}

Map<String, dynamic> _data(Map<String, dynamic> json) {
  final data = json['data'];
  return data is Map<String, dynamic>
      ? data
      : _map(data).isEmpty
          ? json
          : _map(data);
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Object?> _list(Object? value) {
  if (value is List) return value;
  return const [];
}

List<String> _strings(Object? value) {
  if (value is List) {
    return value
        .map((item) => item.toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  final text = _string(value);
  return text.isEmpty ? const [] : [text];
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _bool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  if (text == null || text.isEmpty) return fallback;
  return text == 'true' || text == '1' || text == 'yes' || text == 'on';
}
