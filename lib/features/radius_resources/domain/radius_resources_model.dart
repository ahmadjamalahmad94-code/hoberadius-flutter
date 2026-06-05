import '../../../core/l10n/arabic_labels.dart';

class RadiusResourcesSnapshot {
  const RadiusResourcesSnapshot({
    required this.pools,
    required this.shareGroups,
  });

  final List<IpPoolResource> pools;
  final List<ShareGroupResource> shareGroups;

  int get activeGroups => shareGroups.where((group) => group.enabled).length;

  int get assignedPoolRouters =>
      pools.where((pool) => pool.routerId != null && pool.routerId! > 0).length;
}

class IpPoolResource {
  const IpPoolResource({
    required this.id,
    required this.poolName,
    required this.rangeIp,
    required this.localIp,
    required this.routerId,
    required this.createdAt,
  });

  final int id;
  final String poolName;
  final String rangeIp;
  final String localIp;
  final int? routerId;
  final DateTime? createdAt;

  factory IpPoolResource.fromJson(Map<String, dynamic> json) {
    return IpPoolResource(
      id: _int(json['id']),
      poolName: _string(json['pool_name'], fallback: _string(json['name'])),
      rangeIp: _string(json['range_ip']),
      localIp: _string(json['local_ip']),
      routerId: _nullableInt(json['router_id']),
      createdAt: _date(json['created_at']),
    );
  }

  Map<String, dynamic> toBody() => {
        'pool_name': poolName,
        'range_ip': rangeIp,
        'local_ip': localIp,
        'router_id': routerId,
      };
}

class ShareGroupResource {
  const ShareGroupResource({
    required this.id,
    required this.name,
    required this.description,
    required this.sharedQuotaMb,
    required this.sharedSpeedDownKbps,
    required this.sharedSpeedUpKbps,
    required this.maxMembers,
    required this.enabled,
    required this.members,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String description;
  final int sharedQuotaMb;
  final int sharedSpeedDownKbps;
  final int sharedSpeedUpKbps;
  final int maxMembers;
  final bool enabled;
  final int members;
  final DateTime? createdAt;

  factory ShareGroupResource.fromJson(Map<String, dynamic> json) {
    return ShareGroupResource(
      id: _int(json['id']),
      name: _string(json['name']),
      description: _string(json['description']),
      sharedQuotaMb: _int(json['shared_quota_mb']),
      sharedSpeedDownKbps: _int(json['shared_speed_down_kbps']),
      sharedSpeedUpKbps: _int(json['shared_speed_up_kbps']),
      maxMembers: _int(json['max_members']),
      enabled: _bool(json['enabled'], fallback: true),
      members: _int(json['members']),
      createdAt: _date(json['created_at']),
    );
  }

  Map<String, dynamic> toBody() => {
        'name': name,
        'description': description,
        'shared_quota_mb': sharedQuotaMb,
        'shared_speed_down_kbps': sharedSpeedDownKbps,
        'shared_speed_up_kbps': sharedSpeedUpKbps,
        'max_members': maxMembers,
        'enabled': enabled,
      };
}

class ShareGroupDetails {
  const ShareGroupDetails({
    required this.group,
    required this.members,
  });

  final ShareGroupResource group;
  final List<ShareGroupMember> members;

  factory ShareGroupDetails.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return ShareGroupDetails(
      group: ShareGroupResource.fromJson(_map(data['group'])),
      members: _list(data['members'])
          .map((item) => ShareGroupMember.fromJson(_map(item)))
          .toList(),
    );
  }
}

class ShareGroupMember {
  const ShareGroupMember({
    required this.id,
    required this.username,
    required this.fullName,
    required this.status,
  });

  final int id;
  final String username;
  final String fullName;
  final String status;

  factory ShareGroupMember.fromJson(Map<String, dynamic> json) {
    return ShareGroupMember(
      id: _int(json['id']),
      username: _string(json['username']),
      fullName: _string(json['full_name']),
      status: _string(json['status'], fallback: 'active'),
    );
  }

  String get displayName => fullName.isNotEmpty ? fullName : username;

  String get statusLabel => switch (status) {
        'active' => 'نشط',
        'disabled' => 'معطل',
        'expired' => 'منتهي',
        'suspended' => 'موقوف',
        _ => unknownStatusLabel(
            status,
            unknownLabel: 'حالة عضو غير معروفة',
          ),
      };
}

Map<String, dynamic> unwrapData(Map<String, dynamic> json) => _data(json);

Map<String, dynamic> _data(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return data.map((key, value) => MapEntry('$key', value));
  return json;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return const {};
}

List<Object?> _list(Object? value) => value is List ? value : const [];

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableInt(Object? value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _bool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  if (text == null || text.isEmpty) return fallback;
  return text == 'true' || text == '1' || text == 'yes' || text == 'on';
}

DateTime? _date(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text.replaceAll('Z', ''));
}
