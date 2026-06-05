import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/wallet_model.dart';

class WalletsRepository {
  WalletsRepository(this._api);

  final ApiClient _api;

  Future<WalletPage> list({String ownerType = '', String status = ''}) async {
    final res = await _api.get(
      '/api/v1/finance/wallets',
      query: {
        if (ownerType.isNotEmpty) 'owner_type': ownerType,
        if (status.isNotEmpty) 'status': status,
        'limit': 200,
      },
    );
    return WalletPage.fromJson(res);
  }

  Future<WalletRecord> create(WalletCreateDraft draft) async {
    final res = await _api.post(
      '/api/v1/finance/wallets',
      body: draft.toApiJson(),
    );
    return WalletRecord.fromJson(_object(res, 'wallet'));
  }

  Future<WalletChangeResult> credit(
    int walletId,
    WalletChangeDraft draft,
  ) async {
    final res = await _api.post(
      '/api/v1/finance/wallets/$walletId/credit',
      body: draft.toApiJson(),
    );
    return WalletChangeResult.fromJson(res);
  }

  Future<WalletChangeResult> debit(
    int walletId,
    WalletChangeDraft draft,
  ) async {
    final res = await _api.post(
      '/api/v1/finance/wallets/$walletId/debit',
      body: draft.toApiJson(),
    );
    return WalletChangeResult.fromJson(res);
  }

  Future<WalletTransactionsPage> transactions(int walletId) async {
    final res = await _api.get(
      '/api/v1/finance/wallets/$walletId/transactions',
      query: {'limit': 50},
    );
    return WalletTransactionsPage.fromJson(res);
  }
}

final walletsRepositoryProvider = Provider<WalletsRepository>((ref) {
  return WalletsRepository(ref.watch(apiClientProvider));
});

Map<String, dynamic> _object(Map<String, dynamic> res, String key) {
  final data = res['data'];
  final value = data is Map ? data[key] : null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((itemKey, val) => MapEntry('$itemKey', val));
  }
  return const {};
}
