import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/invoice_model.dart';

class InvoicesRepository {
  InvoicesRepository(this._api);

  final ApiClient _api;

  Future<InvoicePage> list({String status = ''}) async {
    final res = await _api.get(
      '/api/v1/invoices',
      query: {
        if (status.isNotEmpty) 'status': status,
        'limit': 200,
      },
    );
    return InvoicePage.fromJson(res);
  }

  Future<InvoiceRecord> create(InvoiceDraft draft) async {
    final res = await _api.post(
      '/api/v1/invoices',
      body: draft.toApiJson(),
    );
    return InvoiceRecord.fromJson(_dataMap(res));
  }

  Future<InvoiceRecord> updateStatus(
    int id,
    InvoiceStatusUpdate update,
  ) async {
    final res = await _api.post(
      '/api/v1/invoices/$id/status',
      body: update.toApiJson(),
    );
    return InvoiceRecord.fromJson(_dataMap(res));
  }
}

final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  return InvoicesRepository(ref.watch(apiClientProvider));
});

Map<String, dynamic> _dataMap(Map<String, dynamic> res) {
  final data = res['data'];
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return data.map((key, value) => MapEntry('$key', value));
  return const {};
}
