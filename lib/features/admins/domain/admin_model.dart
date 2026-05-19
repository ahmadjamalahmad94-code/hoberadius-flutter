class Admin {
  Admin({
    this.id,
    required this.username,
    this.fullName = '',
    this.email = '',
    this.mobile = '',
    this.phone = '',
    this.roleId,
    this.isSuperAdmin = false,
    this.enabled = true,
    this.avatarUrl = '',
    this.tags = '',
    this.lastLoginAt,
    this.lastLoginIp = '',
  });

  final int? id;
  final String username;
  final String fullName;
  final String email;
  final String mobile;
  final String phone;
  final int? roleId;
  final bool isSuperAdmin;
  final bool enabled;
  final String avatarUrl;
  final String tags;
  final DateTime? lastLoginAt;
  final String lastLoginIp;

  factory Admin.fromJson(Map<String, dynamic> j) => Admin(
        id: j['id'] as int?,
        username: (j['username'] ?? '').toString(),
        fullName: (j['full_name'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        mobile: (j['mobile'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        roleId: j['role_id'] as int?,
        isSuperAdmin: j['is_super_admin'] == true,
        enabled: j['enabled'] != false,
        avatarUrl: (j['avatar_url'] ?? '').toString(),
        tags: (j['tags'] ?? '').toString(),
        lastLoginAt: _dt(j['last_login_at']),
        lastLoginIp: (j['last_login_ip'] ?? '').toString(),
      );

  /// Build create/patch body. Password is form-only — included only when
  /// non-empty (so PATCH leaves it untouched when blank).
  Map<String, dynamic> toBody({String? pendingPassword}) => {
        if (id == null) 'username': username,
        'full_name': fullName,
        'email': email,
        'mobile': mobile,
        'phone': phone,
        if (roleId != null) 'role_id': roleId,
        'is_super_admin': isSuperAdmin,
        'enabled': enabled,
        'avatar_url': avatarUrl,
        'tags': tags,
        if (pendingPassword != null && pendingPassword.isNotEmpty)
          'password': pendingPassword,
      };

  static DateTime? _dt(Object? v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString().replaceAll('Z', ''));
    } catch (_) {
      return null;
    }
  }

  Admin copyWith({
    int? id,
    String? username,
    String? fullName,
    String? email,
    String? mobile,
    String? phone,
    int? roleId,
    bool? clearRoleId,
    bool? isSuperAdmin,
    bool? enabled,
    String? avatarUrl,
    String? tags,
  }) => Admin(
        id: id ?? this.id,
        username: username ?? this.username,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        mobile: mobile ?? this.mobile,
        phone: phone ?? this.phone,
        roleId: clearRoleId == true ? null : (roleId ?? this.roleId),
        isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
        enabled: enabled ?? this.enabled,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        tags: tags ?? this.tags,
        lastLoginAt: lastLoginAt,
        lastLoginIp: lastLoginIp,
      );
}

class Role {
  Role({
    this.id,
    required this.name,
    this.displayName = '',
    this.description = '',
    this.permissions = const <String>[],
    this.isSystem = false,
    this.color = '#2BAACC',
  });

  final int? id;
  final String name;
  final String displayName;
  final String description;
  final List<String> permissions;
  final bool isSystem;
  final String color;

  String get label => displayName.isNotEmpty ? displayName : name;

  factory Role.fromJson(Map<String, dynamic> j) => Role(
        id: j['id'] as int?,
        name: (j['name'] ?? '').toString(),
        displayName: (j['display_name'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        permissions: ((j['permissions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        isSystem: j['is_system'] == true,
        color: (j['color'] ?? '#2BAACC').toString(),
      );

  Map<String, dynamic> toBody() => {
        if (id == null) 'name': name,
        'display_name': displayName,
        'description': description,
        'permissions': permissions,
        'color': color,
      };

  Role copyWith({
    int? id,
    String? name,
    String? displayName,
    String? description,
    List<String>? permissions,
    bool? isSystem,
    String? color,
  }) => Role(
        id: id ?? this.id,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        description: description ?? this.description,
        permissions: permissions ?? this.permissions,
        isSystem: isSystem ?? this.isSystem,
        color: color ?? this.color,
      );
}

class PermissionGroup {
  PermissionGroup({
    required this.key,
    required this.label,
    required this.permissions,
  });

  final String key;
  final String label;
  final List<String> permissions;

  factory PermissionGroup.fromJson(Map<String, dynamic> j) => PermissionGroup(
        key: (j['key'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        permissions: ((j['permissions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

class PermissionCatalog {
  PermissionCatalog({required this.items, required this.groups});

  final List<String> items;
  final List<PermissionGroup> groups;

  factory PermissionCatalog.fromJson(Map<String, dynamic> j) => PermissionCatalog(
        items: ((j['items'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        groups: ((j['groups'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(PermissionGroup.fromJson)
            .toList(),
      );
}
