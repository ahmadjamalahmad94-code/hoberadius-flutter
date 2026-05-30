class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subscriberId,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.closedAt,
  });

  final int id;
  final int subscriberId;
  final String subject;
  final String category;
  final String priority;
  final String status;
  final String body;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: _int(json['id']),
      subscriberId: _int(json['subscriber_id']),
      subject: _string(json['subject']),
      category: _string(json['category'], fallback: 'general'),
      priority: _string(json['priority'], fallback: 'normal'),
      status: _string(json['status'], fallback: 'open'),
      body: _string(json['body']),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
      closedAt: _date(json['closed_at']),
    );
  }

  String get statusLabel => switch (status) {
        'open' => 'مفتوحة',
        'pending' => 'بانتظار متابعة',
        'closed' => 'مغلقة',
        _ => status,
      };

  String get priorityLabel => switch (priority) {
        'low' => 'منخفضة',
        'normal' => 'عادية',
        'high' => 'مرتفعة',
        'urgent' => 'عاجلة',
        _ => priority,
      };
}

class TicketReply {
  const TicketReply({
    required this.id,
    required this.ticketId,
    required this.body,
    required this.authorType,
    required this.authorId,
    required this.createdAt,
  });

  final int id;
  final int ticketId;
  final String body;
  final String authorType;
  final int authorId;
  final DateTime? createdAt;

  factory TicketReply.fromJson(Map<String, dynamic> json) {
    return TicketReply(
      id: _int(json['id']),
      ticketId: _int(json['ticket_id']),
      body: _string(json['body']),
      authorType: _string(json['author_type']),
      authorId: _int(json['author_id']),
      createdAt: _date(json['created_at']),
    );
  }

  String get authorLabel => authorType == 'admin' ? 'الإدارة' : 'العميل';
}

class TicketsPage {
  const TicketsPage({required this.items, required this.count});

  final List<SupportTicket> items;
  final int count;

  factory TicketsPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return TicketsPage(
      items: (data['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SupportTicket.fromJson)
          .toList(),
      count: _int(data['count']),
    );
  }
}

class TicketDetail {
  const TicketDetail({required this.ticket, required this.replies});

  final SupportTicket ticket;
  final List<TicketReply> replies;

  factory TicketDetail.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return TicketDetail(
      ticket: SupportTicket.fromJson(
        data['ticket'] is Map<String, dynamic>
            ? data['ticket'] as Map<String, dynamic>
            : const {},
      ),
      replies: (data['replies'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TicketReply.fromJson)
          .toList(),
    );
  }
}

Map<String, dynamic> _data(Map<String, dynamic> json) {
  final data = json['data'];
  return data is Map<String, dynamic> ? data : json;
}

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text.replaceFirst('Z', ''));
}
