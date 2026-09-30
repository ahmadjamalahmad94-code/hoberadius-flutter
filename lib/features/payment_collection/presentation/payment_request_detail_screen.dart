import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/hub_layout.dart';
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
            subtitle: 'الإثباتات ومحاولات تطبيق الخدمة.',
            leading: IconButton(
              tooltip: 'رجوع',
              visualDensity: VisualDensity.compact,
              onPressed: () => context.goNamed('payment-collection'),
              icon: const Icon(Icons.arrow_back),
            ),
            inlineActions: true,
            actions: [
              IconButton(
                tooltip: 'تحديث',
                icon: const Icon(
                  Icons.refresh,
                  color: AppTokens.textSecondary,
                ),
                onPressed: () {
                  ref.invalidate(paymentRequestDetailProvider(requestId));
                  ref.invalidate(paymentRequestsProvider);
                  ref.invalidate(paymentReconciliationProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
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
                    const SizedBox(height: AppTokens.s12),
                    proofs,
                    const SizedBox(height: AppTokens.s12),
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
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CountGrid(
            items: [
              CountItem.text(
                'الحالة',
                request.statusLabel,
                tone: _statusTone(request.status),
              ),
              CountItem.text(
                'المبلغ',
                request.amountLabel,
                tone: PillTone.green,
              ),
              CountItem.text(
                'الخدمة',
                request.serviceApplyLabel,
                tone: PillTone.blue,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          InfoGrid(
            columns: 2,
            items: [
              InfoItem(
                icon: Icons.tag,
                label: 'رقم الطلب',
                value: '#${request.id}',
              ),
              InfoItem(
                icon: Icons.qr_code_2_outlined,
                label: 'المرجع',
                value: _orUnset(request.referenceCodeOrId),
              ),
              InfoItem(
                icon: Icons.category_outlined,
                label: 'الغرض',
                value: _orUnset(request.purposeLabel),
              ),
              InfoItem(
                icon: Icons.person_outline,
                label: 'الدافع',
                value: _orUnset(request.payerLabel),
              ),
              InfoItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'المحفظة المستقبلة',
                value: _orUnset(request.receiverWallet),
              ),
              InfoItem(
                icon: Icons.receipt_long_outlined,
                label: 'القيد المالي',
                value: _orUnset(request.ledgerLabel),
              ),
              InfoItem(
                icon: Icons.add_circle_outline,
                label: 'تاريخ الإنشاء',
                value: _dateLabel(request.createdAt),
              ),
              InfoItem(
                icon: Icons.update,
                label: 'آخر تحديث',
                value: _dateLabel(request.updatedAt),
              ),
              InfoItem(
                icon: Icons.event_busy_outlined,
                label: 'ينتهي في',
                value: _dateLabel(request.expiresAt),
              ),
              InfoItem(
                icon: Icons.account_balance_outlined,
                label: 'تاريخ الترحيل',
                value: _dateLabel(request.ledgerAppliedAt),
              ),
              InfoItem(
                icon: Icons.playlist_add_check_circle_outlined,
                label: 'تاريخ تطبيق الخدمة',
                value: _dateLabel(request.serviceAppliedAt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One muted line instead of a full [EmptyState] halo inside a panel.
class _PanelEmpty extends StatelessWidget {
  const _PanelEmpty({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTokens.textMuted),
        const SizedBox(width: AppTokens.s8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTokens.textMuted),
          ),
        ),
      ],
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
        padding: EdgeInsets.all(AppTokens.s12),
        child: _PanelEmpty(
          icon: Icons.file_present_outlined,
          text: 'لا توجد إثباتات بعد. عند رفع مرجع العملية أو صورة الإثبات '
              'ستظهر هنا للمراجعة.',
        ),
      );
    }
    return AppCard(
      title: 'إثباتات الدفع',
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < proofs.length; i++) ...[
            if (i > 0) const SizedBox(height: AppTokens.s8),
            _ProofRow(proof: proofs[i]),
          ],
        ],
      ),
    );
  }
}

class _ProofRow extends StatelessWidget {
  const _ProofRow({required this.proof});

  final PaymentProofRecord proof;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppTokens.border),
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    proof.proofTypeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTokens.sidebarBg,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                StatusPill(
                  text: proof.reviewStatusLabel,
                  tone: _proofTone(proof.reviewStatus),
                  dot: true,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s8),
            InfoGrid(
              columns: 2,
              items: [
                if (proof.referenceNumber.isNotEmpty)
                  InfoItem(
                    icon: Icons.qr_code_2_outlined,
                    label: 'مرجع العملية',
                    value: proof.referenceNumber,
                  ),
                InfoItem(
                  icon: Icons.send_outlined,
                  label: 'تاريخ الإرسال',
                  value: _dateLabel(proof.submittedAt),
                ),
                if (proof.reviewedAt != null)
                  InfoItem(
                    icon: Icons.fact_check_outlined,
                    label: 'تاريخ المراجعة',
                    value: _dateLabel(proof.reviewedAt),
                  ),
              ],
            ),
            if (proof.note.isNotEmpty)
              _Line(label: 'ملاحظة العميل', value: proof.note),
            if (proof.reviewNote.isNotEmpty)
              _Line(label: 'ملاحظة المراجعة', value: proof.reviewNote),
          ],
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
        padding: EdgeInsets.all(AppTokens.s12),
        child: _PanelEmpty(
          icon: Icons.playlist_add_check_circle_outlined,
          text: 'لم يتم تسجيل تطبيق للخدمة. بعد اعتماد الدفع يمكن تسجيل '
              'تطبيق الاستحقاق بدون تنفيذ مباشر على الراوتر.',
        ),
      );
    }
    return AppCard(
      title: 'محاولات تطبيق الخدمة',
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < attempts.length; i++) ...[
            if (i > 0) const SizedBox(height: AppTokens.s8),
            _AttemptRow(attempt: attempts[i]),
          ],
        ],
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.attempt});

  final PaymentApplyAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final failed = attempt.status == 'failed';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: failed ? AppTokens.redSoft : AppTokens.soft,
        border: Border.all(color: AppTokens.border),
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    attempt.serviceLabel.isNotEmpty
                        ? '${attempt.modeLabel} · ${attempt.serviceLabel}'
                        : attempt.modeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTokens.sidebarBg,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                StatusPill(
                  text: attempt.statusLabel,
                  tone: failed ? PillTone.red : PillTone.green,
                  dot: true,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s8),
            InfoGrid(
              items: [
                InfoItem(
                  icon: Icons.tag,
                  label: 'رقم المحاولة',
                  value: '#${attempt.id}',
                ),
                InfoItem(
                  icon: Icons.schedule_outlined,
                  label: 'تاريخ التسجيل',
                  value: _dateLabel(attempt.createdAt),
                ),
                InfoItem(
                  icon: Icons.person_outline,
                  label: 'منفذ العملية',
                  value: _orUnset(
                    attempt.actorName.isNotEmpty
                        ? attempt.actorName
                        : attempt.actor,
                  ),
                ),
              ],
            ),
            if (attempt.errorMessage.isNotEmpty)
              _Line(
                label: 'سبب الفشل',
                value: humanizeTechnicalError(attempt.errorMessage),
              ),
          ],
        ),
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
      padding: const EdgeInsets.only(top: AppTokens.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
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

String _orUnset(String value) =>
    value.trim().isEmpty ? 'غير محدد' : value.trim();

String _dateLabel(DateTime? value) {
  if (value == null) return 'غير محدد';
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
