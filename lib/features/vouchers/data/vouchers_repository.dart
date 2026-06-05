import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/voucher_model.dart';

class VouchersRepository {
  VouchersRepository(this._api);

  final ApiClient _api;

  Future<VoucherPage> list({String status = ''}) async {
    final res = await _api.get(
      '/api/v1/vouchers',
      query: {
        if (status.isNotEmpty) 'status': status,
        'limit': 200,
      },
    );
    return VoucherPage.fromJson(res);
  }

  Future<VoucherGenerateResult> generate(VoucherGenerateDraft draft) async {
    final res = await _api.post(
      '/api/v1/vouchers',
      body: draft.toApiJson(),
    );
    return VoucherGenerateResult.fromJson(res);
  }

  Future<VoucherRevokeResult> revoke(int voucherId) async {
    final res = await _api.post(
      '/api/v1/vouchers/$voucherId/revoke',
      body: const {},
    );
    return VoucherRevokeResult.fromJson(res);
  }
}

final vouchersRepositoryProvider = Provider<VouchersRepository>((ref) {
  return VouchersRepository(ref.watch(apiClientProvider));
});
