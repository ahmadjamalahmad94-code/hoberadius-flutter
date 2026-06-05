import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/payment_collection/domain/payment_collection_model.dart';

void main() {
  test('payment settings parse and serialize api payload', () {
    final settings = PaymentCollectionSettings.fromJson({
      'ok': true,
      'data': {
        'settings': {
          'id': 2,
          'provider': 'manual_wallet',
          'enabled': true,
          'wallet_number': '0599000000',
          'wallet_owner_name': 'Hobe Radius',
          'currency': 'ILS',
          'confirmation_mode': 'manual',
          'auto_apply': false,
          'allow_cards': true,
          'allow_monthly_subscriptions': true,
          'allow_distributor_payments': false,
          'min_amount': '5',
          'max_amount': 100,
          'payment_request_ttl_minutes': 720,
          'created_at': '2026-05-30T10:00:00Z',
          'updated_at': '2026-05-30T11:00:00Z',
        },
      },
    });

    expect(settings.enabled, isTrue);
    expect(settings.providerLabel, 'محفظة يدوية');
    expect(settings.confirmationLabel, 'مراجعة يدوية');
    expect(settings.minAmount, 5);
    expect(settings.maxAmount, 100);
    expect(settings.paymentRequestTtlMinutes, 720);
    expect(settings.toApiJson(), containsPair('wallet_number', '0599000000'));
    expect(settings.toApiJson(), containsPair('allow_cards', true));
  });

  test('payment request draft serializes create request contract', () {
    const draft = PaymentRequestDraft(
      payerType: 'subscriber',
      payerId: 44,
      purpose: 'subscriber_renewal',
      amount: 55,
      currency: 'ILS',
    );

    expect(draft.toApiJson(), {
      'payer_type': 'subscriber',
      'payer_id': 44,
      'purpose': 'subscriber_renewal',
      'amount': 55,
      'currency': 'ILS',
    });
  });

  test('payment instructions parse safe customer-facing fields', () {
    final instructions = PaymentInstructions.fromJson({
      'ok': true,
      'data': {
        'instructions': {
          'amount': 25.5,
          'currency': 'ILS',
          'receiver_wallet': '0599000000',
          'wallet_owner_name': 'Hobe Radius',
          'reference_code': 'PAY-15',
          'expires_at': '2026-05-31T10:00:00Z',
          'instructions': 'أرسل المبلغ نفسه إلى المحفظة.',
          'status': 'pending',
        },
      },
    });

    expect(instructions.amountLabel, '25.50 ILS');
    expect(instructions.receiverWallet, '0599000000');
    expect(instructions.referenceCode, 'PAY-15');
    expect(instructions.statusLabel, 'بانتظار الدفع');
    expect(instructions.instructions, contains('أرسل المبلغ نفسه'));
  });

  test('payment proof draft and result parse proof upload contract', () {
    const draft = PaymentProofDraft(
      proofType: 'manual_reference',
      referenceNumber: 'TX-9',
      note: 'تم التحويل من المحفظة',
    );
    expect(draft.toApiJson(), {
      'proof_type': 'manual_reference',
      'reference_number': 'TX-9',
      'note': 'تم التحويل من المحفظة',
    });

    final result = PaymentProofResult.fromJson({
      'data': {
        'proof': {
          'id': 3,
          'payment_request_id': 9,
          'proof_type': 'manual_reference',
          'reference_number': 'TX-9',
          'image_path': '',
          'note': 'تم التحويل من المحفظة',
          'submitted_at': '2026-05-30T12:00:00Z',
          'reviewed_by': null,
          'reviewed_at': null,
          'review_status': 'pending',
          'review_note': '',
        },
      },
    });

    expect(result.proof.id, 3);
    expect(result.proof.proofTypeLabel, 'مرجع عملية');
    expect(result.proof.reviewStatusLabel, 'بانتظار المراجعة');
  });

  test('payment reconciliation summary counts operational issues', () {
    final summary = PaymentReconciliationSummary.fromJson({
      'data': {
        'reconciliation': {
          'counts': {
            'paid_without_ledger': 1,
            'paid_not_applied': 1,
            'expired_pending': 0,
            'duplicate_provider_transactions': 1,
          },
          'paid_without_ledger': [
            {
              'id': 7,
              'reference_code': 'PAY-7',
              'amount': 40,
              'currency': 'ILS',
              'status': 'paid',
              'created_at': '2026-05-30T10:00:00Z',
            },
          ],
          'paid_not_applied': [
            {
              'id': 8,
              'reference_code': 'PAY-8',
              'amount': 60,
              'currency': 'ILS',
              'status': 'paid',
              'service_apply_status': 'not_applied',
            },
          ],
          'expired_pending': [],
          'duplicate_provider_transactions': [
            {
              'provider_transaction_id': 'TX-1',
              'count': 2,
              'payment_request_ids': '9,10',
            },
          ],
        },
      },
    });

    expect(summary.isClean, isFalse);
    expect(summary.totalIssues, 3);
    expect(summary.paidWithoutLedger.single.amountLabel, '40 ILS');
    expect(
      summary.duplicateProviderTransactions.single.displayReference,
      'TX-1',
    );
  });

  test('payment request page parses review queue payload', () {
    final page = PaymentRequestPage.fromJson({
      'ok': true,
      'data': {
        'count': 1,
        'items': [
          {
            'id': 9,
            'payer_type': 'subscriber',
            'payer_id': 44,
            'purpose': 'subscriber_renewal',
            'amount': 50,
            'currency': 'ILS',
            'provider': 'manual_wallet',
            'receiver_wallet': '0590000000',
            'reference_code': 'PAY-9',
            'status': 'proof_submitted',
            'service_apply_status': 'not_applied',
            'created_at': '2026-05-30T10:00:00Z',
            'updated_at': '2026-05-30T11:00:00Z',
          },
        ],
      },
    });

    final item = page.items.single;
    expect(page.count, 1);
    expect(item.isReviewable, isTrue);
    expect(item.canSubmitProof, isTrue);
    expect(item.amountLabel, '50 ILS');
    expect(item.statusLabel, 'بانتظار مراجعة الإثبات');
    expect(item.purposeLabel, 'تجديد مشترك');
    expect(item.payerLabel, 'مشترك #44');
    expect(item.serviceApplyLabel, 'لم تطبق الخدمة');
  });

  test('paid request exposes service apply action state', () {
    final result = PaymentReviewResult.fromJson({
      'data': {
        'request': {
          'id': 10,
          'status': 'paid',
          'purpose': 'card_purchase',
          'amount': '75.5',
          'currency': 'ILS',
          'payer_type': 'card_user',
          'payer_id': 3,
          'service_apply_status': 'pending',
        },
      },
    });

    expect(result.request.isPaid, isTrue);
    expect(result.request.canSubmitProof, isFalse);
    expect(result.request.canApplyService, isTrue);
    expect(result.request.amountLabel, '75.50 ILS');
    expect(result.request.purposeLabel, 'شراء كروت');
  });

  test('payment request detail parses proofs and apply attempts', () {
    final detail = PaymentRequestDetail.fromJson({
      'data': {
        'request': {
          'id': 12,
          'status': 'paid',
          'purpose': 'monthly_subscription',
          'amount': 55,
          'currency': 'ILS',
          'payer_type': 'subscriber',
          'payer_id': 4,
          'reference_code': 'PAY-12',
          'service_apply_status': 'applied',
          'ledger_entry_id': 31,
          'ledger_applied_at': '2026-05-30T12:10:00Z',
          'service_apply_attempt_id': 9,
          'service_applied_at': '2026-05-30T12:20:00Z',
        },
        'proofs': [
          {
            'id': 7,
            'payment_request_id': 12,
            'proof_type': 'manual_reference',
            'reference_number': 'JP-7788',
            'note': 'تم الدفع',
            'review_status': 'approved',
            'review_note': 'تمت المطابقة',
          },
        ],
        'apply_attempts': [
          {
            'id': 9,
            'payment_request_id': 12,
            'status': 'applied',
            'actor': 'api-token:1',
            'result': {
              'mode': 'local_entitlement_only',
              'local_service_apply': true,
              'service_label': 'بوابة العميل',
            },
            'error_message': '',
            'created_at': '2026-05-30T12:00:00Z',
          },
        ],
      },
    });

    expect(detail.request.referenceCodeOrId, 'PAY-12');
    expect(detail.request.ledgerEntryId, 31);
    expect(detail.request.ledgerLabel, 'قيد مالي #31');
    expect(detail.request.ledgerAppliedAt, isNotNull);
    expect(detail.request.serviceApplyAttemptId, 9);
    expect(detail.request.serviceAppliedAt, isNotNull);
    expect(detail.hasProofs, isTrue);
    expect(detail.proofs.single.referenceNumber, 'JP-7788');
    expect(detail.proofs.single.reviewStatusLabel, 'معتمد');
    expect(detail.hasApplyAttempts, isTrue);
    expect(detail.applyAttempts.single.statusLabel, 'تم التطبيق');
    expect(
      detail.applyAttempts.single.modeLabel,
      'تحديث الاستحقاق المحلي',
    );
    expect(detail.applyAttempts.single.appliedLocalEntitlement, isTrue);
  });

  test('service apply result exposes local entitlement message', () {
    final result = PaymentReviewResult.fromJson({
      'data': {
        'request': {
          'id': 11,
          'status': 'paid',
          'purpose': 'monthly_subscription',
          'amount': 30,
          'currency': 'ILS',
          'service_apply_status': 'applied',
        },
        'apply_attempt': {
          'id': 4,
          'status': 'applied',
          'result': {
            'local_service_apply': true,
            'service_key': 'customer_portal',
            'service_label': 'بوابة العميل',
          },
        },
      },
    });

    expect(result.applyAttempt, isNotNull);
    expect(result.applyAttempt?.appliedLocalEntitlement, isTrue);
    expect(
      result.applyAttempt?.successMessage,
      'تم اعتماد خدمة بوابة العميل داخل عقد التشغيل',
    );
  });
}
