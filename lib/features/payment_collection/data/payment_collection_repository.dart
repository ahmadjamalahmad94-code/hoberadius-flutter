import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/payment_collection_model.dart';

class PaymentCollectionRepository {
  PaymentCollectionRepository(this._api);

  final ApiClient _api;

  Future<PaymentCollectionSettings> settings() async {
    final res = await _api.get('/api/v1/payments/settings');
    return PaymentCollectionSettings.fromJson(res);
  }

  Future<PaymentCollectionSettings> updateSettings(
    PaymentCollectionSettings settings,
  ) async {
    final res = await _api.patch(
      '/api/v1/payments/settings',
      body: {'settings': settings.toApiJson()},
    );
    return PaymentCollectionSettings.fromJson(res);
  }

  Future<PaymentRequestPage> reviewQueue() async {
    final res = await _api.get('/api/v1/admin/payments/review-queue');
    return PaymentRequestPage.fromJson(res);
  }

  Future<PaymentRequestPage> list({String status = ''}) async {
    final res = await _api.get(
      '/api/v1/payments/requests',
      query: {
        if (status.isNotEmpty) 'status': status,
        'limit': 100,
      },
    );
    return PaymentRequestPage.fromJson(res);
  }

  Future<PaymentInstructions> instructions(int id) async {
    final res = await _api.get('/api/v1/payments/requests/$id/instructions');
    return PaymentInstructions.fromJson(res);
  }

  Future<PaymentReconciliationSummary> reconciliation() async {
    final res = await _api.get('/api/v1/admin/payments/reconciliation');
    return PaymentReconciliationSummary.fromJson(res);
  }

  Future<PaymentReviewResult> approve(int id, {String note = ''}) async {
    final res = await _api.post(
      '/api/v1/admin/payments/requests/$id/approve',
      body: {'review_note': note},
    );
    return PaymentReviewResult.fromJson(res);
  }

  Future<PaymentReviewResult> reject(int id, {String note = ''}) async {
    final res = await _api.post(
      '/api/v1/admin/payments/requests/$id/reject',
      body: {'review_note': note},
    );
    return PaymentReviewResult.fromJson(res);
  }

  Future<PaymentReviewResult> applyService(int id) async {
    final res = await _api.post(
      '/api/v1/admin/payments/requests/$id/apply-service',
    );
    return PaymentReviewResult.fromJson(res);
  }
}

final paymentCollectionRepositoryProvider =
    Provider<PaymentCollectionRepository>((ref) {
  return PaymentCollectionRepository(ref.watch(apiClientProvider));
});
