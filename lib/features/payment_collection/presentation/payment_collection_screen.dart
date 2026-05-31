import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/payment_collection_providers.dart';
import '../data/payment_collection_repository.dart';
import '../domain/payment_collection_model.dart';

class PaymentCollectionScreen extends ConsumerWidget {
  const PaymentCollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(paymentCollectionModeProvider);
    final status = ref.watch(paymentCollectionStatusProvider);
    final requests = ref.watch(paymentRequestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'مراجعة المدفوعات',
          subtitle:
              'قبول إثبات الدفع، رفضه، أو تطبيق الخدمة بعد اعتماد المبلغ.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(paymentRequestsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        AppCard(
          child: Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'review',
                    label: Text('بانتظار المراجعة'),
                    icon: Icon(Icons.rate_review_outlined),
                  ),
                  ButtonSegment(
                    value: 'all',
                    label: Text('كل الطلبات'),
                    icon: Icon(Icons.receipt_long_outlined),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (selection) {
                  ref.read(paymentCollectionModeProvider.notifier).state =
                      selection.first;
                },
              ),
              if (mode == 'all')
                DropdownButton<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: '', child: Text('كل الحالات')),
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('بانتظار الدفع'),
                    ),
                    DropdownMenuItem(
                      value: 'proof_submitted',
                      child: Text('بانتظار مراجعة الإثبات'),
                    ),
                    DropdownMenuItem(
                      value: 'under_review',
                      child: Text('قيد المراجعة'),
                    ),
                    DropdownMenuItem(value: 'paid', child: Text('مدفوع')),
                    DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
                  ],
                  onChanged: (value) {
                    ref.read(paymentCollectionStatusProvider.notifier).state =
                        value ?? '';
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s16),
        requests.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => HubErrorState(
            title: 'تعذر تحميل طلبات الدفع',
            subtitle: '$error',
            onRetry: () => ref.invalidate(paymentRequestsProvider),
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: mode == 'review'
                    ? 'لا توجد طلبات بانتظار المراجعة'
                    : 'لا توجد طلبات مطابقة',
                subtitle: 'عند رفع إثبات دفع سيظهر هنا للمراجعة.',
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: page.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return _PaymentRequestTile(request: page.items[index]);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PaymentRequestTile extends ConsumerStatefulWidget {
  const _PaymentRequestTile({required this.request});

  final PaymentRequestRecord request;

  @override
  ConsumerState<_PaymentRequestTile> createState() =>
      _PaymentRequestTileState();
}

class _PaymentRequestTileState extends ConsumerState<_PaymentRequestTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor:
                    r.isPaid ? AppTokens.greenSoft : AppTokens.brandSoft,
                child: Icon(
                  r.isPaid
                      ? Icons.check_circle_outline
                      : Icons.payments_outlined,
                  color: r.isPaid ? AppTokens.greenInk : AppTokens.brandInk,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r.purposeLabel} · ${r.amountLabel}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTokens.sidebarBg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${r.payerLabel} · مرجع ${r.referenceCode.isEmpty ? '#${r.id}' : r.referenceCode}',
                      style: const TextStyle(color: AppTokens.textMuted),
                    ),
                  ],
                ),
              ),
              StatusPill(
                text: r.statusLabel,
                tone: _statusTone(r.status),
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              StatusPill(text: r.serviceApplyLabel, tone: PillTone.blue),
              if (r.receiverWallet.isNotEmpty)
                StatusPill(
                  text: 'المحفظة ${r.receiverWallet}',
                  tone: PillTone.neutral,
                ),
              if (r.updatedAt != null)
                StatusPill(
                  text: 'آخر تحديث ${_dateLabel(r.updatedAt)}',
                  tone: PillTone.neutral,
                ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              if (r.isReviewable)
                FilledButton.icon(
                  onPressed: _busy ? null : () => _review(approve: true),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('استلمت المبلغ'),
                ),
              if (r.isReviewable)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _review(approve: false),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('رفض الإثبات'),
                ),
              if (r.canApplyService)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _applyService,
                  icon: const Icon(Icons.playlist_add_check_circle_outlined),
                  label: const Text('تطبيق الخدمة'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _review({required bool approve}) async {
    final note = await _noteDialog(
      context,
      title: approve ? 'اعتماد الدفع' : 'رفض الدفع',
      label: approve ? 'ملاحظة الاعتماد' : 'سبب الرفض',
    );
    if (note == null) return;
    setState(() => _busy = true);
    try {
      if (approve) {
        await ref
            .read(paymentCollectionRepositoryProvider)
            .approve(widget.request.id, note: note);
      } else {
        await ref
            .read(paymentCollectionRepositoryProvider)
            .reject(widget.request.id, note: note);
      }
      ref.invalidate(paymentRequestsProvider);
      if (mounted) {
        _snack(context, approve ? 'تم اعتماد الدفع' : 'تم رفض الدفع');
      }
    } catch (error) {
      if (mounted) _snack(context, 'تعذر تنفيذ المراجعة: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyService() async {
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(paymentCollectionRepositoryProvider)
          .applyService(widget.request.id);
      ref.invalidate(paymentRequestsProvider);
      if (mounted) {
        _snack(
          context,
          result.applyAttempt?.successMessage ?? 'تم تطبيق الخدمة',
        );
      }
    } catch (error) {
      if (mounted) _snack(context, 'تعذر تطبيق الخدمة: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

Future<String?> _noteDialog(
  BuildContext context, {
  required String title,
  required String label,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        minLines: 2,
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

PillTone _statusTone(String status) {
  return switch (status) {
    'paid' => PillTone.green,
    'proof_submitted' || 'under_review' => PillTone.amber,
    'rejected' || 'failed' || 'expired' => PillTone.red,
    _ => PillTone.neutral,
  };
}

String _dateLabel(DateTime? date) {
  if (date == null) return 'غير محدد';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
}

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
