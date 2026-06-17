// Store admin-management models — the Flutter mirror of the web store support
// console (`/api/v1/store/admin/*`): deposit/withdrawal requests, payment
// methods, and the support chat inbox.

class StoreRequest {
  const StoreRequest({
    required this.id,
    required this.cardUserId,
    required this.who,
    required this.amount,
    required this.confirmedAmount,
    required this.currency,
    required this.status,
    required this.statusAr,
    required this.method,
    required this.reference,
    required this.receiptUrl,
    required this.createdAt,
  });

  final int id;
  final int cardUserId;

  /// Display name/phone of the requester (payer for deposits, payee for
  /// withdrawals).
  final String who;
  final String amount;
  final String confirmedAmount;
  final String currency;
  final String status;
  final String statusAr;
  final String method;
  final String reference;
  final String receiptUrl;
  final String createdAt;

  bool get isPending => status == 'pending';

  factory StoreRequest.deposit(Map<String, dynamic> j) => StoreRequest(
        id: _int(j['id']),
        cardUserId: _int(j['card_user_id']),
        who: [_s(j['payer_name']), _s(j['payer_phone'])]
            .where((e) => e.isNotEmpty)
            .join(' • '),
        amount: _s(j['amount_claimed']),
        confirmedAmount: _s(j['confirmed_amount']),
        currency: _s(j['currency']),
        status: _s(j['status']),
        statusAr: _s(j['status_ar']),
        method: _s(j['method_ar'], fallback: _s(j['method'])),
        reference: _s(j['reference']),
        receiptUrl: _s(j['receipt_image_url']),
        createdAt: _s(j['created_at']),
      );

  factory StoreRequest.withdrawal(Map<String, dynamic> j) => StoreRequest(
        id: _int(j['id']),
        cardUserId: _int(j['card_user_id']),
        who: [_s(j['payee_name']), _s(j['payee_account'])]
            .where((e) => e.isNotEmpty)
            .join(' • '),
        amount: _s(j['amount']),
        confirmedAmount: '',
        currency: _s(j['currency']),
        status: _s(j['status']),
        statusAr: _s(j['status_ar']),
        method: _s(j['method_ar'], fallback: _s(j['method'])),
        reference: _s(j['reference']),
        receiptUrl: '',
        createdAt: _s(j['created_at']),
      );
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.method,
    required this.methodAr,
    required this.label,
    required this.accountName,
    required this.accountNumber,
    required this.instructions,
    required this.active,
    required this.sortOrder,
    required this.qrUrl,
    required this.logoUrl,
  });

  final int id;
  final String method;
  final String methodAr;
  final String label;
  final String accountName;
  final String accountNumber;
  final String instructions;
  final bool active;
  final int sortOrder;
  final String qrUrl;
  final String logoUrl;

  factory PaymentMethod.fromJson(Map<String, dynamic> j) => PaymentMethod(
        id: _int(j['id']),
        method: _s(j['method'], fallback: 'other'),
        methodAr: _s(j['method_ar']),
        label: _s(j['label']),
        accountName: _s(j['account_name']),
        accountNumber: _s(j['account_number']),
        instructions: _s(j['instructions']),
        active: j['active'] == 1 || j['active'] == true,
        sortOrder: _int(j['sort_order']),
        qrUrl: _s(j['qr_image_url']),
        logoUrl: _s(j['logo_image_url']),
      );
}

class ChatThread {
  const ChatThread({
    required this.cardUserId,
    required this.displayName,
    required this.mobile,
    required this.lastBody,
    required this.lastMessageAt,
    required this.totalCount,
    required this.unreadAdminCount,
  });

  final int cardUserId;
  final String displayName;
  final String mobile;
  final String lastBody;
  final String lastMessageAt;
  final int totalCount;
  final int unreadAdminCount;

  String get title => displayName.isNotEmpty
      ? displayName
      : (mobile.isNotEmpty ? mobile : 'زبون #$cardUserId');

  factory ChatThread.fromJson(Map<String, dynamic> j) => ChatThread(
        cardUserId: _int(j['card_user_id']),
        displayName: _s(j['display_name']),
        mobile: _s(j['mobile']),
        lastBody: _s(j['last_body']),
        lastMessageAt: _s(j['last_message_at']),
        totalCount: _int(j['total_count']),
        unreadAdminCount: _int(j['unread_admin_count']),
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.imageUrl,
    required this.createdAt,
  });

  final int id;
  final String sender; // admin | customer
  final String body;
  final String imageUrl;
  final String createdAt;

  bool get fromAdmin => sender == 'admin';

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: _int(j['id']),
        sender: _s(j['sender']),
        body: _s(j['body']),
        imageUrl: _s(j['image_url'], fallback: _s(j['image_path'])),
        createdAt: _s(j['created_at']),
      );
}

class StoreSupportSnapshot {
  const StoreSupportSnapshot({
    required this.depositsPending,
    required this.depositsResolved,
    required this.depositsPendingCount,
    required this.withdrawalsPending,
    required this.withdrawalsResolved,
    required this.withdrawalsPendingCount,
    required this.chatThreads,
    required this.chatUnreadCount,
    required this.paymentMethods,
  });

  final List<StoreRequest> depositsPending;
  final List<StoreRequest> depositsResolved;
  final int depositsPendingCount;
  final List<StoreRequest> withdrawalsPending;
  final List<StoreRequest> withdrawalsResolved;
  final int withdrawalsPendingCount;
  final List<ChatThread> chatThreads;
  final int chatUnreadCount;
  final List<PaymentMethod> paymentMethods;

  factory StoreSupportSnapshot.fromJson(Map<String, dynamic> j) {
    final dep = _map(j['deposits']);
    final wd = _map(j['withdrawals']);
    return StoreSupportSnapshot(
      depositsPending:
          _list(dep['pending']).map(StoreRequest.deposit).toList(),
      depositsResolved:
          _list(dep['resolved']).map(StoreRequest.deposit).toList(),
      depositsPendingCount: _int(dep['pending_count']),
      withdrawalsPending:
          _list(wd['pending']).map(StoreRequest.withdrawal).toList(),
      withdrawalsResolved:
          _list(wd['resolved']).map(StoreRequest.withdrawal).toList(),
      withdrawalsPendingCount: _int(wd['pending_count']),
      chatThreads: _list(j['chat_threads']).map(ChatThread.fromJson).toList(),
      chatUnreadCount: _int(j['chat_unread_count']),
      paymentMethods:
          _list(j['payment_methods']).map(PaymentMethod.fromJson).toList(),
    );
  }
}

String _s(Object? v, {String fallback = ''}) {
  final t = v?.toString().trim() ?? '';
  return t.isEmpty ? fallback : t;
}

int _int(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

Map<String, dynamic> _map(Object? v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return const {};
}

List<Map<String, dynamic>> _list(Object? v) {
  if (v is! List) return const [];
  return v.whereType<Map>().map(_map).toList();
}
