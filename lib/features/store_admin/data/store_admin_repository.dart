import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/store_admin_model.dart';

/// Repository for the admin-authed store support console
/// (`/api/v1/store/admin/*`).
class StoreAdminRepository {
  StoreAdminRepository(this._api);

  final ApiClient _api;

  Future<StoreSupportSnapshot> support() async {
    final res = await _api.get('/api/v1/store/admin/support');
    return StoreSupportSnapshot.fromJson(_data(res));
  }

  Future<void> confirmDeposit(
    int id, {
    String confirmedAmount = '',
    String note = '',
  }) async {
    await _api.post(
      '/api/v1/store/admin/deposits/$id/confirm',
      body: {
        if (confirmedAmount.trim().isNotEmpty)
          'confirmed_amount': confirmedAmount.trim(),
        if (note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
  }

  Future<void> rejectDeposit(int id, {String note = ''}) async {
    await _api.post(
      '/api/v1/store/admin/deposits/$id/reject',
      body: {if (note.trim().isNotEmpty) 'note': note.trim()},
    );
  }

  Future<void> confirmWithdrawal(int id, {String note = ''}) async {
    await _api.post(
      '/api/v1/store/admin/withdrawals/$id/confirm',
      body: {if (note.trim().isNotEmpty) 'note': note.trim()},
    );
  }

  Future<void> rejectWithdrawal(int id, {String note = ''}) async {
    await _api.post(
      '/api/v1/store/admin/withdrawals/$id/reject',
      body: {if (note.trim().isNotEmpty) 'note': note.trim()},
    );
  }

  // ── Payment methods CRUD ───────────────────────────────────────────
  Future<PaymentMethod> createPaymentMethod({
    required String method,
    required String label,
    String accountName = '',
    String accountNumber = '',
    String instructions = '',
    int sortOrder = 0,
  }) async {
    final res = await _api.post(
      '/api/v1/store/admin/payment-methods',
      body: {
        'method': method,
        'label': label,
        'account_name': accountName,
        'account_number': accountNumber,
        'instructions': instructions,
        'sort_order': sortOrder,
      },
    );
    return PaymentMethod.fromJson(_obj(_data(res), 'payment_method'));
  }

  Future<PaymentMethod> updatePaymentMethod(
    int id, {
    required String method,
    required String label,
    required String accountName,
    required String accountNumber,
    required String instructions,
    required int sortOrder,
    required bool active,
  }) async {
    final res = await _api.patch(
      '/api/v1/store/admin/payment-methods/$id',
      body: {
        'method': method,
        'label': label,
        'account_name': accountName,
        'account_number': accountNumber,
        'instructions': instructions,
        'sort_order': sortOrder,
        'active': active ? 1 : 0,
      },
    );
    return PaymentMethod.fromJson(_obj(_data(res), 'payment_method'));
  }

  Future<void> deletePaymentMethod(int id) async {
    await _api.delete('/api/v1/store/admin/payment-methods/$id');
  }

  // ── Chat ───────────────────────────────────────────────────────────
  Future<List<ChatMessage>> chatThread(int cardUserId) async {
    final res = await _api.get('/api/v1/store/admin/chat/$cardUserId');
    final data = _data(res);
    final raw = data['thread'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (m) => ChatMessage.fromJson(
            m.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .toList();
  }

  Future<void> sendChatMessage(int cardUserId, String body) async {
    await _api.post(
      '/api/v1/store/admin/chat/$cardUserId',
      body: {'body': body},
    );
  }

  Future<String> setChatStatus(int cardUserId, String status) async {
    final res = await _api.post(
      '/api/v1/store/admin/chat/$cardUserId/status',
      body: {'status': status},
    );
    return _data(res)['status']?.toString() ?? status;
  }

  Map<String, dynamic> _data(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.map((k, v) => MapEntry(k.toString(), v));
    return const {};
  }

  Map<String, dynamic> _obj(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return const {};
  }
}

final storeAdminRepositoryProvider = Provider<StoreAdminRepository>((ref) {
  return StoreAdminRepository(ref.watch(apiClientProvider));
});

final storeSupportProvider =
    FutureProvider.autoDispose<StoreSupportSnapshot>((ref) {
  return ref.watch(storeAdminRepositoryProvider).support();
});
