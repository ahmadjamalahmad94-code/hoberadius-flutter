/// Dart mirror of a `panel_notifications` row as returned by
/// `GET /api/v1/notifications` (radius-module api/v1/notifications.py).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    required this.link,
    required this.source,
    required this.readAt,
    required this.createdAt,
    required this.isRead,
  });

  final int id;

  /// license | subscription | service | support | billing | system
  final String type;

  /// info | success | warning | critical
  final String severity;
  final String title;
  final String body;

  /// Relative deep-link target (e.g. `/subscribers`), empty when none.
  final String link;

  /// local | bridge
  final String source;

  /// ISO timestamp, empty when unread.
  final String readAt;

  /// ISO timestamp of creation.
  final String createdAt;
  final bool isRead;

  bool get hasLink => link.trim().isNotEmpty;

  AppNotification copyWith({bool? isRead, String? readAt}) {
    return AppNotification(
      id: id,
      type: type,
      severity: severity,
      title: title,
      body: body,
      link: link,
      source: source,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _int(json['id']),
      type: (json['type'] ?? 'system').toString(),
      severity: (json['severity'] ?? 'info').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      link: (json['link'] ?? '').toString(),
      source: (json['source'] ?? 'local').toString(),
      readAt: (json['read_at'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      // Prefer the explicit flag; fall back to read_at presence.
      isRead: json['is_read'] == true ||
          (json['is_read'] == null &&
              (json['read_at'] ?? '').toString().trim().isNotEmpty),
    );
  }
}

/// A page of notifications + the global unread count (the list endpoint
/// returns both so the badge refreshes in one round-trip).
class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.unreadCount,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final int limit;
  final int offset;
  final bool hasMore;

  static const empty = NotificationsPage(
    items: [],
    unreadCount: 0,
    limit: 0,
    offset: 0,
    hasMore: false,
  );

  factory NotificationsPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <AppNotification>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map) {
          items.add(
            AppNotification.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }
    return NotificationsPage(
      items: items,
      unreadCount: _int(json['unread_count']),
      limit: _int(json['limit']),
      offset: _int(json['offset']),
      hasMore: json['has_more'] == true,
    );
  }
}

int _int(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}
