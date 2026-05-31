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
        'in_progress' => 'قيد التنفيذ',
        'resolved' => 'تم الحل',
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

class ServicePaymentRequest {
  const ServicePaymentRequest({
    required this.id,
    required this.amount,
    required this.currency,
    required this.referenceCode,
    required this.status,
  });

  final int id;
  final double amount;
  final String currency;
  final String referenceCode;
  final String status;

  factory ServicePaymentRequest.fromJson(Map<String, dynamic> json) {
    return ServicePaymentRequest(
      id: _int(json['id']),
      amount: _double(json['amount']),
      currency: _string(json['currency'], fallback: 'ILS'),
      referenceCode: _string(json['reference_code']),
      status: _string(json['status'], fallback: 'pending'),
    );
  }

  String get amountLabel =>
      '${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)} $currency';
}

class ServiceRequestResult {
  const ServiceRequestResult({
    required this.reference,
    required this.ticketId,
    required this.paymentRequestId,
    required this.serviceLabel,
    required this.requestLabel,
    required this.localServiceApply,
    required this.trialDays,
    required this.expiresAt,
    required this.ticket,
    required this.paymentRequest,
  });

  final String reference;
  final int ticketId;
  final int paymentRequestId;
  final String serviceLabel;
  final String requestLabel;
  final bool localServiceApply;
  final int trialDays;
  final DateTime? expiresAt;
  final SupportTicket ticket;
  final ServicePaymentRequest? paymentRequest;

  factory ServiceRequestResult.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final request = _map(data['service_request']);
    final payment = data['payment_request'];
    return ServiceRequestResult(
      reference: _string(request['reference']),
      ticketId: _int(request['ticket_id']),
      paymentRequestId: _int(request['payment_request_id']),
      serviceLabel: _string(request['service_label']),
      requestLabel: _string(request['request_label']),
      localServiceApply: _bool(request['local_service_apply']),
      trialDays: _int(request['trial_days']),
      expiresAt: _date(request['expires_at']),
      ticket: SupportTicket.fromJson(_map(data['ticket'])),
      paymentRequest: payment == null
          ? null
          : ServicePaymentRequest.fromJson(_map(payment)),
    );
  }

  String get trialMessage {
    if (!localServiceApply) return 'تم تسجيل قرار الإدارة';
    final days = trialDays > 0 ? ' لمدة $trialDays يوم' : '';
    final expiry = expiresAt == null ? '' : ' حتى ${_dateLabel(expiresAt)}';
    return 'تم فتح التجربة$days$expiry';
  }
}

Map<String, dynamic> _data(Map<String, dynamic> json) {
  final data = json['data'];
  return _map(data).isEmpty ? json : _map(data);
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
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

double _double(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

DateTime? _date(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text.replaceFirst('Z', ''));
}

String _dateLabel(DateTime? value) {
  if (value == null) return '';
  String two(int item) => item.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
}
