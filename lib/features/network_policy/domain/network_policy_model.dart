import '../../../core/l10n/arabic_labels.dart';

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

  String get deploymentStatus => _string(
        fields['deployment_status'],
        fallback:
            _string(_map(fields['deployment'])['status'], fallback: 'draft'),
      );

  String get deploymentStatusLabel => switch (deploymentStatus) {
        'draft' => 'مسودة',
        'previewed' => 'تمت المعاينة',
        'applied' => 'مطبقة',
        'failed' => 'فشل التنفيذ',
        'disabled' => 'معطلة',
        _ => unknownStatusLabel(
            deploymentStatus,
            emptyLabel: 'مسودة',
            unknownLabel: 'حالة نشر غير معروفة',
          ),
      };
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
    required this.healthGrade,
    required this.explanation,
    required this.recommendations,
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
  final String healthGrade;
  final String explanation;
  final List<PolicyRecommendation> recommendations;

  factory NetworkPolicyPreview.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final summary = _map(data['summary']);
    final health = _map(data['health_score']);
    final beginner = _map(data['beginner_explanation']);
    final smart = _map(data['smart_recommendations']);
    final recos = (smart['recommendations'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => PolicyRecommendation.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
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
      healthGrade: _string(
        health['grade_ar'],
        fallback: _string(health['grade']),
      ),
      explanation: _string(
        beginner['plain_text'],
        fallback: _string(beginner['summary']),
      ),
      recommendations: recos,
    );
  }
}

/// One smart recommendation from the network-policy preview intelligence
/// (`smart_recommendations.recommendations[]`).
class PolicyRecommendation {
  const PolicyRecommendation({
    required this.title,
    required this.explanation,
    required this.priority,
  });

  final String title;
  final String explanation;
  final int priority;

  factory PolicyRecommendation.fromJson(Map<String, dynamic> json) {
    return PolicyRecommendation(
      title: _string(json['title_ar'], fallback: _string(json['title'])),
      explanation: _string(
        json['explanation_ar'],
        fallback: _string(json['explanation']),
      ),
      priority: _int(json['priority']),
    );
  }
}

class NetworkPolicyScriptDownload {
  const NetworkPolicyScriptDownload({
    required this.filename,
    required this.script,
    required this.scriptHash,
  });

  final String filename;
  final String script;
  final String scriptHash;

  factory NetworkPolicyScriptDownload.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return NetworkPolicyScriptDownload(
      filename: _string(data['filename']),
      script: _string(data['script']),
      scriptHash: _string(data['script_hash']),
    );
  }
}

class NetworkPolicyActionResult {
  const NetworkPolicyActionResult({
    required this.ok,
    required this.changeSetId,
    required this.status,
    required this.reason,
    required this.blockers,
    required this.warnings,
  });

  final bool ok;
  final int changeSetId;
  final String status;
  final String reason;
  final List<String> blockers;
  final List<String> warnings;

  factory NetworkPolicyActionResult.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return NetworkPolicyActionResult(
      ok: _bool(data['ok']),
      changeSetId: _int(data['change_set_id']),
      status: _string(data['status']),
      reason: _string(data['reason_ar']),
      blockers: _issueMessages(data['blockers']),
      warnings: _issueMessages(data['warnings']),
    );
  }

  String get statusLabel => networkPolicyExecutionStatusLabel(status);
}

class NetworkPolicyChangeSetPage {
  const NetworkPolicyChangeSetPage({required this.items, required this.count});

  final List<NetworkPolicyChangeSet> items;
  final int count;

  factory NetworkPolicyChangeSetPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final items = _list(data['items'])
        .map((item) => NetworkPolicyChangeSet.fromJson(_map(item)))
        .toList();
    return NetworkPolicyChangeSetPage(
      items: items,
      count: _int(data['count'], fallback: items.length),
    );
  }
}

class NetworkPolicyChangeSet {
  const NetworkPolicyChangeSet({
    required this.id,
    required this.actionType,
    required this.status,
    required this.executionMode,
    required this.createdAt,
    required this.finishedAt,
    required this.rollbackEligible,
    required this.targets,
  });

  final int id;
  final String actionType;
  final String status;
  final String executionMode;
  final String createdAt;
  final String finishedAt;
  final bool rollbackEligible;
  final List<NetworkPolicyChangeTarget> targets;

  factory NetworkPolicyChangeSet.fromJson(Map<String, dynamic> json) {
    return NetworkPolicyChangeSet(
      id: _int(json['id']),
      actionType: _string(json['action_type']),
      status: _string(json['status']),
      executionMode: _string(json['execution_mode']),
      createdAt: _string(json['created_at']),
      finishedAt: _string(json['finished_at']),
      rollbackEligible: _bool(json['rollback_eligible']),
      targets: _list(json['targets'])
          .map((item) => NetworkPolicyChangeTarget.fromJson(_map(item)))
          .toList(),
    );
  }

  String get actionLabel => switch (actionType) {
        'apply' => 'تطبيق',
        'rollback' => 'تراجع',
        _ => unknownActionLabel(actionType),
      };

  String get statusLabel => networkPolicyExecutionStatusLabel(status);
}

class NetworkPolicyChangeTarget {
  const NetworkPolicyChangeTarget({
    required this.routerId,
    required this.status,
    required this.errorMessage,
  });

  final int routerId;
  final String status;
  final String errorMessage;

  factory NetworkPolicyChangeTarget.fromJson(Map<String, dynamic> json) {
    return NetworkPolicyChangeTarget(
      routerId: _int(json['router_id']),
      status: _string(json['status']),
      errorMessage: _string(json['error_message']),
    );
  }

  String get statusLabel => networkPolicyExecutionStatusLabel(status);
}

String networkPolicyExecutionStatusLabel(String status) {
  return switch (status) {
    'planned' => 'مخططة',
    'running' => 'قيد التنفيذ',
    'succeeded' => 'نجحت',
    'failed' => 'فشلت',
    'partially_succeeded' => 'نجحت جزئيًا',
    'rolled_back' => 'تم التراجع',
    'rollback_pending' => 'تراجع قيد الانتظار',
    'rollback_running' => 'تراجع قيد التنفيذ',
    'rollback_failed' => 'فشل التراجع',
    'partially_rolled_back' => 'تراجع جزئي',
    'pending' => 'قيد الانتظار',
    'skipped' => 'تم التخطي',
    _ => unknownStatusLabel(
        status,
        unknownLabel: 'حالة تنفيذ غير معروفة',
      ),
  };
}

String networkPolicyFieldLabel(String key, Object? value) {
  final text = _string(value);
  if (text.isEmpty) return '';
  return switch (key) {
    'allow_winbox' => _bool(value) ? 'Winbox مسموح' : 'Winbox مغلق',
    'allow_ssh' => _bool(value) ? 'SSH مسموح' : 'SSH مغلق',
    'allow_api' => _bool(value) ? 'واجهة الربط مسموحة' : 'واجهة الربط مغلقة',
    'allow_api_ssl' =>
      _bool(value) ? 'واجهة الربط الآمنة مسموحة' : 'واجهة الربط الآمنة مغلقة',
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

List<String> _issueMessages(Object? value) {
  if (value is List) {
    return value
        .map((item) {
          final map = _map(item);
          return _string(
            map['message_ar'],
            fallback: _string(
              map['reason_ar'],
              fallback: _string(map['message'], fallback: item.toString()),
            ),
          );
        })
        .where((text) => text.isNotEmpty)
        .toList();
  }
  return _strings(value);
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
