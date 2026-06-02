class CustomerPortalsState {
  const CustomerPortalsState({
    required this.items,
    required this.security,
  });

  final List<CustomerPortalItem> items;
  final CustomerPortalSecurity security;

  factory CustomerPortalsState.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return CustomerPortalsState(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => CustomerPortalItem.fromJson(_map(item)))
              .toList()
          : const [],
      security: CustomerPortalSecurity.fromJson(_map(json['security'])),
    );
  }
}

class CustomerPortalItem {
  const CustomerPortalItem({
    required this.key,
    required this.label,
    required this.description,
    required this.publicPath,
    required this.adminPath,
    required this.homePath,
    required this.availableActions,
    required this.securityNote,
  });

  final String key;
  final String label;
  final String description;
  final String publicPath;
  final String adminPath;
  final String homePath;
  final List<String> availableActions;
  final String securityNote;

  factory CustomerPortalItem.fromJson(Map<String, dynamic> json) {
    return CustomerPortalItem(
      key: _string(json['key']),
      label: _string(json['label']),
      description: _string(json['description']),
      publicPath: _string(json['public_path']),
      adminPath: _string(json['admin_path']),
      homePath: _string(json['home_path']),
      availableActions: _stringList(json['available_actions']),
      securityNote: _string(json['security_note']),
    );
  }
}

class CustomerPortalSecurity {
  const CustomerPortalSecurity({
    required this.summary,
    required this.adminNavigationOnly,
    required this.usesExistingPortalSessions,
  });

  final String summary;
  final bool adminNavigationOnly;
  final bool usesExistingPortalSessions;

  factory CustomerPortalSecurity.fromJson(Map<String, dynamic> json) {
    return CustomerPortalSecurity(
      summary: _string(json['summary']),
      adminNavigationOnly: _bool(json['admin_navigation_only']),
      usesExistingPortalSessions: _bool(json['uses_existing_portal_sessions']),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const {};
}

List<String> _stringList(Object? value) {
  if (value is List) return value.map((item) => _string(item)).toList();
  return const [];
}

bool _bool(Object? value) {
  if (value is bool) return value;
  final text = (value ?? '').toString().trim().toLowerCase();
  return {'1', 'true', 'yes', 'on', 'enabled'}.contains(text);
}

String _string(Object? value) => (value ?? '').toString();
