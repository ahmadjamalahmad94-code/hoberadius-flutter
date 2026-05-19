class Admin {
  Admin({
    this.id,
    required this.username,
    this.fullName = '',
    this.email = '',
    this.mobile = '',
    this.roleId,
    this.roleName = '',
    this.disabled = false,
    this.lastLoginAt,
    this.lastLoginIp = '',
    this.profileSummary = '',
  });

  final int? id;
  final String username;
  final String fullName;
  final String email;
  final String mobile;
  final int? roleId;
  final String roleName;
  final bool disabled;
  final DateTime? lastLoginAt;
  final String lastLoginIp;
  final String profileSummary;

  factory Admin.fromJson(Map<String, dynamic> j) => Admin(
        id: j['id'] as int?,
        username: (j['username'] ?? '').toString(),
        fullName: (j['full_name'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        mobile: (j['mobile'] ?? '').toString(),
        roleId: j['role_id'] as int?,
        roleName: (j['role_name'] ?? '').toString(),
        disabled: j['disabled'] == true,
        lastLoginAt: _dt(j['last_login_at']),
        lastLoginIp: (j['last_login_ip'] ?? '').toString(),
        profileSummary: (j['profile_summary'] ?? '').toString(),
      );

  static DateTime? _dt(Object? v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString().replaceAll('Z', ''));
    } catch (_) {
      return null;
    }
  }
}

class Role {
  Role({
    this.id,
    required this.name,
    this.description = '',
    this.isSystem = false,
    this.permissions = const <String>[],
  });

  final int? id;
  final String name;
  final String description;
  final bool isSystem;
  final List<String> permissions;

  factory Role.fromJson(Map<String, dynamic> j) => Role(
        id: j['id'] as int?,
        name: (j['name'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        isSystem: j['is_system'] == true || j['system'] == true,
        permissions: ((j['permissions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}
