import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/payment_collection_providers.dart';
import '../domain/payment_collection_model.dart';

class PaymentRequestDetailScreen extends ConsumerWidget {
  const PaymentRequestDetailScreen({super.key, required this.requestId});

  final int requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(paymentRequestDetailProvider(requestId));
    return detail.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => HubErrorState(
        title: 'تعذر فتح طلب الدفع',
        subtitle: visibleErrorMessage(error),
        onRetry: () => ref.invalidate(paymentRequestDetailProvider(requestId)),
      ),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'طلب دفع ${data.request.referenceCodeOrId}',
            subtitle:
                'تفاصيل التحصيل والإثباتات ومحاولات تطبيق الخدمة المرتبطة بهذا الطلب.',
            leading: IconButton(
              onPressed: () => context.goNamed('payment-collection'),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(paymentRequestDetailProvider(requestId));
                  ref.invalidate(paymentRequestsProvider);
                  ref.invalidate(paymentReconciliationProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث'),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 920;
              final summary = _RequestSummaryPanel(request: data.request);
              final proofs = _ProofsPanel(proofs: data.proofs);
              final attempts = _ApplyAttemptsPanel(
                attempts: data.applyAttempts,
              );
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    summary,
                    const SizedBox(height: AppTokens.s16),
                    proofs,
                    const SizedBox(height: AppTokens.s16),
                    attempts,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 360, child: summary),
                  const SizedBox(width: AppTokens.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        proofs,
                        const SizedBox(height: AppTokens.s16),
                        attempts,
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RequestSummaryPanel extends StatelessWidget {
  const _RequestSummaryPanel({required this.request});

  final PaymentRequestRecord request;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'ملخص الطلب',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              StatusPill(
                text: request.statusLabel,
                tone: _statusTone(request.status),
                dot: true,
              ),
              StatusPill(text: request.amountLabel, tone: PillTone.green),
              StatusPill(text: request.serviceApplyLabel, tone: PillTone.blue),
            ],
          ),
          const Divider(height: AppTokens.s24),
          _Line(label: 'رقم الطلب', value: '#${request.id}'),
          _Line(label: 'المرجع', value: request.referenceCodeOrId),
          _Line(label: 'الغرض', value: request.purposeLabel),
          _Line(label: 'الدافع', value: request.payerLabel),
          _Line(label: 'المحفظة المستقبلة', value: request.receiverWallet),
          _Line(label: 'القيد المالي', value: request.ledgerLabel),
          _Line(
            label: 'تاريخ الترحيل',
            value: _dateLabel(request.ledgerAppliedAt),
          ),
          _Line(
            label: 'تاريخ تطبيق الخدمة',
            value: _dateLabel(request.serviceAppliedAt),
          ),
          _Line(label: 'تاريخ الإنشاء', value: _dateLabel(request.createdAt)),
          _Line(label: 'آخر تحديث', value: _dateLabel(request.updatedAt)),
          _Line(label: 'ينتهي في', value: _dateLabel(request.expiresAt)),
        ],
      ),
    );
  }
}

class _ProofsPanel extends StatelessWidget {
  const _ProofsPanel({required this.proofs});

  final List<PaymentProofRecord> proofs;

  @override
  Widget build(BuildContext context) {
    if (proofs.isEmpty) {
      return const AppCard(
        title: 'إثباتات الدفع',
        child: EmptyState(
          icon: Icons.file_present_outlined,
          title: 'لا توجد إثباتات بعد',
          subtitle: 'عند رفع مرجع العملية أو صورة الإثبات ستظهر هنا للمراجعة.',
        ),
      );
    }
    return AppCard(
      title: 'إثباتات الدفع',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: proofs.map((proof) => _ProofRow(proof: proof)).toList(),
      ),
    );
  }
}

class _ProofRow extends StatelessWidget {
  const _ProofRow({required this.proof});

  final PaymentProofRecord proof;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppTokens.border),
          borderRadius: BorderRadius.circular(AppTokens.r12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: [
                  StatusPill(text: proof.proofTypeLabel, tone: PillTone.cyan),
                  StatusPill(
                    text: proof.reviewStatusLabel,
                    tone: _proofTone(proof.reviewStatus),
                    dot: true,
                  ),
                  if (proof.referenceNumber.isNotEmpty)
                    StatusPill(
                      text: 'مرجع العملية ${proof.referenceNumber}',
                      tone: PillTone.neutral,
                    ),
                ],
              ),
              const SizedBox(height: AppTokens.s8),
              _Line(
                label: 'تاريخ الإرسال',
                value: _dateLabel(proof.submittedAt),
              ),
              if (proof.note.isNotEmpty)
                _Line(label: 'ملاحظة العميل', value: proof.note),
              if (proof.reviewNote.isNotEmpty)
                _Line(label: 'ملاحظة المراجعة', value: proof.reviewNote),
              if (proof.reviewedAt != null)
                _Line(
                  label: 'تاريخ المراجعة',
                  value: _dateLabel(proof.reviewedAt),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplyAttemptsPanel extends StatelessWidget {
  const _ApplyAttemptsPanel({required this.attempts});

  final List<PaymentApplyAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) {
      return const AppCard(
        title: 'تطبيق الخدمة',
        child: EmptyState(
          icon: Icons.playlist_add_check_circle_outlined,
          title: 'لم يتم تسجيل تطبيق للخدمة',
          subtitle:
              'بعد اعتماد الدفع يمكن تسجيل تطبيق الاستحقاق بدون تنفيذ مباشر على الراوتر.',
        ),
      );
    }
    return AppCard(
      title: 'محاولات تطبيق الخدمة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: attempts.map((attempt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: attempt.status == 'failed'
                    ? AppTokens.redSoft
                    : AppTokens.soft,
                border: Border.all(color: AppTokens.border),
                borderRadius: BorderRadius.circular(AppTokens.r12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: AppTokens.s8,
                      runSpacing: AppTokens.s8,
                      children: [
                        StatusPill(
                          text: attempt.statusLabel,
                          tone: attempt.status == 'failed'
                              ? PillTone.red
                              : PillTone.green,
                          dot: true,
                        ),
                        StatusPill(
                          text: attempt.modeLabel,
                          tone: PillTone.blue,
                        ),
                        if (attempt.serviceLabel.isNotEmpty)
                          StatusPill(
                            text: attempt.serviceLabel,
                            tone: PillTone.cyan,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.s8),
                    _Line(label: 'رقم المحاولة', value: '#${attempt.id}'),
                    _Line(
                      label: 'تاريخ التسجيل',
                      value: _dateLabel(attempt.createdAt),
                    ),
                    if (attempt.actor.isNotEmpty)
                      _Line(label: 'منفذ العملية', value: attempt.actor),
                    if (attempt.errorMessage.isNotEmpty)
                      _Line(label: 'سبب الفشل', value: attempt.errorMessage),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cleanValue = value.trim().isEmpty ? 'غير محدد' : value.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTokens.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              cleanValue,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

PillTone _statusTone(String status) => switch (status) {
      'paid' => PillTone.green,
      'proof_submitted' || 'under_review' => PillTone.amber,
      'rejected' || 'failed' || 'expired' => PillTone.red,
      _ => PillTone.neutral,
    };

PillTone _proofTone(String status) => switch (status) {
      'approved' => PillTone.green,
      'rejected' => PillTone.red,
      _ => PillTone.amber,
    };

String _dateLabel(DateTime? value) {
  if (value == null) return 'غير محدد';
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
