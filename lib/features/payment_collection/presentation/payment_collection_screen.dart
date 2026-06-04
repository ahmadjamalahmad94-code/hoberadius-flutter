import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/hub_toggle_switch.dart';
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
              onPressed: () {
                ref.invalidate(paymentCollectionSettingsProvider);
                ref.invalidate(paymentReconciliationProvider);
                ref.invalidate(paymentRequestsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        const _PaymentSettingsPanel(),
        const SizedBox(height: AppTokens.s16),
        const _PaymentReconciliationPanel(),
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
            subtitle: visibleErrorMessage(error),
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

class _PaymentSettingsPanel extends ConsumerWidget {
  const _PaymentSettingsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentCollectionSettingsProvider);
    return async.when(
      loading: () => const AppCard(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => HubErrorState(
        title: 'تعذر تحميل إعدادات التحصيل',
        subtitle: visibleErrorMessage(error),
        onRetry: () => ref.invalidate(paymentCollectionSettingsProvider),
      ),
      data: (settings) => _PaymentSettingsEditor(
        key: ValueKey(
          '${settings.id}-${settings.updatedAt?.toIso8601String() ?? ''}',
        ),
        settings: settings,
      ),
    );
  }
}

class _PaymentSettingsEditor extends ConsumerStatefulWidget {
  const _PaymentSettingsEditor({super.key, required this.settings});

  final PaymentCollectionSettings settings;

  @override
  ConsumerState<_PaymentSettingsEditor> createState() =>
      _PaymentSettingsEditorState();
}

class _PaymentSettingsEditorState
    extends ConsumerState<_PaymentSettingsEditor> {
  late bool _enabled;
  late bool _autoApply;
  late bool _allowCards;
  late bool _allowMonthly;
  late bool _allowDistributors;
  late String _provider;
  late String _currency;
  late String _confirmationMode;
  late final TextEditingController _walletController;
  late final TextEditingController _ownerController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final TextEditingController _ttlController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = widget.settings;
    _enabled = settings.enabled;
    _autoApply = settings.autoApply;
    _allowCards = settings.allowCards;
    _allowMonthly = settings.allowMonthlySubscriptions;
    _allowDistributors = settings.allowDistributorPayments;
    _provider = settings.provider;
    _currency = settings.currency;
    _confirmationMode = settings.confirmationMode;
    _walletController = TextEditingController(text: settings.walletNumber);
    _ownerController = TextEditingController(text: settings.walletOwnerName);
    _minController = TextEditingController(
      text: _moneyField(settings.minAmount),
    );
    _maxController = TextEditingController(
      text: _moneyField(settings.maxAmount),
    );
    _ttlController = TextEditingController(
      text: '${settings.paymentRequestTtlMinutes}',
    );
  }

  @override
  void dispose() {
    _walletController.dispose();
    _ownerController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _ttlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor:
                    _enabled ? AppTokens.greenSoft : AppTokens.amberSoft,
                child: Icon(
                  _enabled
                      ? Icons.account_balance_wallet_outlined
                      : Icons.wallet_outlined,
                  color: _enabled ? AppTokens.greenInk : AppTokens.amberInk,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إعدادات التحصيل والمحفظة',
                      style: TextStyle(
                        color: AppTokens.sidebarBg,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _enabled
                          ? 'طلبات الدفع مفعلة. تأكد أن رقم المحفظة والتعليمات واضحة قبل استقبال إثباتات جديدة.'
                          : 'طلبات الدفع معطلة. لن يتم إنشاء طلبات دفع جديدة حتى يتم تفعيل التحصيل.',
                      style: const TextStyle(color: AppTokens.textMuted),
                    ),
                  ],
                ),
              ),
              HubToggleSwitch(
                value: _enabled,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _enabled = value),
                semanticLabel: 'تفعيل تحصيل المدفوعات',
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 820;
              final first = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _provider,
                    decoration: const InputDecoration(labelText: 'مزود الدفع'),
                    items: const [
                      DropdownMenuItem(
                        value: 'manual_wallet',
                        child: Text('محفظة يدوية'),
                      ),
                      DropdownMenuItem(
                        value: 'jawwal_pay',
                        child: Text('Jawwal Pay'),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(
                              () => _provider = value ?? 'manual_wallet',
                            ),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  TextField(
                    controller: _walletController,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'رقم المحفظة المستقبلة',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  TextField(
                    controller: _ownerController,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'اسم صاحب المحفظة',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                ],
              );
              final second = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _currency,
                          decoration:
                              const InputDecoration(labelText: 'العملة'),
                          items: const [
                            DropdownMenuItem(value: 'ILS', child: Text('ILS')),
                            DropdownMenuItem(value: 'JOD', child: Text('JOD')),
                            DropdownMenuItem(value: 'USD', child: Text('USD')),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) => setState(
                                    () => _currency = value ?? 'ILS',
                                  ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _confirmationMode,
                          decoration: const InputDecoration(
                            labelText: 'طريقة الاعتماد',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'manual',
                              child: Text('مراجعة يدوية'),
                            ),
                            DropdownMenuItem(
                              value: 'automatic',
                              child: Text('اعتماد آلي'),
                            ),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) => setState(
                                    () => _confirmationMode = value ?? 'manual',
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minController,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'أقل مبلغ'),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s12),
                      Expanded(
                        child: TextField(
                          controller: _maxController,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'أعلى مبلغ'),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s12),
                      Expanded(
                        child: TextField(
                          controller: _ttlController,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'صلاحية الطلب بالدقائق',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    first,
                    const SizedBox(height: AppTokens.s12),
                    second,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: first),
                  const SizedBox(width: AppTokens.s16),
                  Expanded(child: second),
                ],
              );
            },
          ),
          const SizedBox(height: AppTokens.s16),
          Wrap(
            spacing: AppTokens.s12,
            runSpacing: AppTokens.s12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ToggleLine(
                label: 'السماح بشراء الكروت',
                value: _allowCards,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _allowCards = value),
              ),
              _ToggleLine(
                label: 'السماح باشتراكات المشتركين',
                value: _allowMonthly,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _allowMonthly = value),
              ),
              _ToggleLine(
                label: 'السماح بدفعات الموزعين',
                value: _allowDistributors,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _allowDistributors = value),
              ),
              _ToggleLine(
                label: 'تطبيق الخدمة تلقائيًا بعد الاعتماد',
                value: _autoApply,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _autoApply = value),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          Row(
            children: [
              StatusPill(
                text: _enabled ? 'التحصيل مفعل' : 'التحصيل معطل',
                tone: _enabled ? PillTone.green : PillTone.amber,
                dot: true,
              ),
              const SizedBox(width: AppTokens.s8),
              StatusPill(
                text: 'الاعتماد: ${_confirmationLabel(_confirmationMode)}',
                tone: PillTone.blue,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('حفظ الإعدادات'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final minAmount = _optionalAmount(_minController.text);
    final maxAmount = _optionalAmount(_maxController.text);
    if (minAmount != null && maxAmount != null && maxAmount < minAmount) {
      _snack(context, 'أعلى مبلغ يجب أن يكون أكبر من أو يساوي أقل مبلغ');
      return;
    }
    final ttl = int.tryParse(_ttlController.text.trim()) ?? 1440;
    if (ttl <= 0) {
      _snack(context, 'صلاحية الطلب يجب أن تكون رقمًا موجبًا');
      return;
    }

    setState(() => _saving = true);
    try {
      final current = widget.settings;
      final next = PaymentCollectionSettings(
        id: current.id,
        provider: _provider,
        enabled: _enabled,
        walletNumber: _walletController.text.trim(),
        walletOwnerName: _ownerController.text.trim(),
        currency: _currency,
        confirmationMode: _confirmationMode,
        autoApply: _autoApply,
        allowCards: _allowCards,
        allowMonthlySubscriptions: _allowMonthly,
        allowDistributorPayments: _allowDistributors,
        minAmount: minAmount,
        maxAmount: maxAmount,
        paymentRequestTtlMinutes: ttl,
        createdAt: current.createdAt,
        updatedAt: current.updatedAt,
      );
      await ref.read(paymentCollectionRepositoryProvider).updateSettings(next);
      ref.invalidate(paymentCollectionSettingsProvider);
      ref.invalidate(paymentRequestsProvider);
      if (mounted) _snack(context, 'تم حفظ إعدادات التحصيل');
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PaymentReconciliationPanel extends ConsumerWidget {
  const _PaymentReconciliationPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentReconciliationProvider);
    return async.when(
      loading: () => const AppCard(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => HubErrorState(
        title: 'تعذر تحميل مطابقة التحصيل',
        subtitle: visibleErrorMessage(error),
        onRetry: () => ref.invalidate(paymentReconciliationProvider),
      ),
      data: (summary) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor:
                      summary.isClean ? AppTokens.greenSoft : AppTokens.redSoft,
                  child: Icon(
                    summary.isClean
                        ? Icons.verified_user_outlined
                        : Icons.report_problem_outlined,
                    color:
                        summary.isClean ? AppTokens.greenInk : AppTokens.redInk,
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مطابقة التحصيل',
                        style: TextStyle(
                          color: AppTokens.sidebarBg,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.isClean
                            ? 'كل طلبات الدفع متطابقة مع السجل المالي وتطبيق الخدمات.'
                            : 'راجع البنود التالية قبل إغلاق التحصيل اليومي أو تطبيق الخدمات.',
                        style: const TextStyle(color: AppTokens.textMuted),
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  text: summary.isClean
                      ? 'لا توجد ملاحظات'
                      : '${summary.totalIssues} ملاحظة',
                  tone: summary.isClean ? PillTone.green : PillTone.red,
                  dot: true,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s16),
            Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              children: [
                _ReconciliationChip(
                  label: 'مدفوع بلا قيد مالي',
                  count: summary.count('paid_without_ledger'),
                ),
                _ReconciliationChip(
                  label: 'مدفوع ولم تطبق الخدمة',
                  count: summary.count('paid_not_applied'),
                ),
                _ReconciliationChip(
                  label: 'طلبات منتهية تنتظر إجراء',
                  count: summary.count('expired_pending'),
                ),
                _ReconciliationChip(
                  label: 'معاملات مزود مكررة',
                  count: summary.count('duplicate_provider_transactions'),
                ),
              ],
            ),
            if (!summary.isClean) ...[
              const SizedBox(height: AppTokens.s12),
              _ReconciliationList(summary: summary),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReconciliationChip extends StatelessWidget {
  const _ReconciliationChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      text: '$label: $count',
      tone: count == 0 ? PillTone.neutral : PillTone.amber,
      dot: count > 0,
    );
  }
}

class _ReconciliationList extends StatelessWidget {
  const _ReconciliationList({required this.summary});

  final PaymentReconciliationSummary summary;

  @override
  Widget build(BuildContext context) {
    final sections = [
      (
        title: 'مدفوع بلا قيد مالي',
        items: summary.paidWithoutLedger,
      ),
      (
        title: 'مدفوع ولم تطبق الخدمة',
        items: summary.paidNotApplied,
      ),
      (
        title: 'طلبات منتهية تنتظر إجراء',
        items: summary.expiredPending,
      ),
      (
        title: 'معاملات مزود مكررة',
        items: summary.duplicateProviderTransactions,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections)
          if (section.items.isNotEmpty) ...[
            Text(
              section.title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppTokens.s8),
            ...section.items.take(5).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTokens.soft,
                        border: Border.all(color: AppTokens.border),
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.s12),
                        child: Wrap(
                          spacing: AppTokens.s8,
                          runSpacing: AppTokens.s8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusPill(
                              text: 'مرجع ${item.displayReference}',
                              tone: PillTone.neutral,
                            ),
                            if (item.amount > 0)
                              StatusPill(
                                text: item.amountLabel,
                                tone: PillTone.blue,
                              ),
                            if (item.status.isNotEmpty)
                              StatusPill(
                                text: item.status,
                                tone: PillTone.amber,
                              ),
                            if (item.paymentRequestIds.isNotEmpty)
                              StatusPill(
                                text: 'طلبات ${item.paymentRequestIds}',
                                tone: PillTone.neutral,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            if (section.items.length > 5)
              Text(
                'يوجد ${section.items.length - 5} بند إضافي في هذا القسم.',
                style: const TextStyle(color: AppTokens.textMuted),
              ),
            const SizedBox(height: AppTokens.s8),
          ],
      ],
    );
  }
}

class _ToggleLine extends StatelessWidget {
  const _ToggleLine({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppTokens.border),
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12,
          vertical: AppTokens.s8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppTokens.s8),
            HubToggleSwitch(
              value: value,
              onChanged: onChanged,
              size: HubToggleSize.sm,
              bare: true,
              showLabel: false,
              semanticLabel: label,
            ),
          ],
        ),
      ),
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
              OutlinedButton.icon(
                onPressed: _busy ? null : _showInstructions,
                icon: const Icon(Icons.receipt_outlined),
                label: const Text('تعليمات الدفع'),
              ),
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
      if (mounted) _snack(context, visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showInstructions() async {
    setState(() => _busy = true);
    try {
      final instructions = await ref
          .read(paymentCollectionRepositoryProvider)
          .instructions(widget.request.id);
      if (mounted) {
        await _instructionsDialog(context, instructions: instructions);
      }
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
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
      if (mounted) _snack(context, visibleErrorMessage(error));
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

Future<void> _instructionsDialog(
  BuildContext context, {
  required PaymentInstructions instructions,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('تعليمات الدفع'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _InstructionLine(label: 'المبلغ', value: instructions.amountLabel),
            _InstructionLine(
              label: 'المحفظة المستقبلة',
              value: instructions.receiverWallet,
              ltr: true,
            ),
            _InstructionLine(
              label: 'صاحب المحفظة',
              value: instructions.walletOwnerName,
            ),
            _InstructionLine(
              label: 'رمز المرجع',
              value: instructions.referenceCode,
              ltr: true,
            ),
            _InstructionLine(
              label: 'الحالة',
              value: instructions.statusLabel,
            ),
            if (instructions.expiresAt != null)
              _InstructionLine(
                label: 'ينتهي في',
                value: _dateLabel(instructions.expiresAt),
                ltr: true,
              ),
            const SizedBox(height: AppTokens.s12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTokens.brandSoft,
                border: Border.all(color: AppTokens.brandLine),
                borderRadius: BorderRadius.circular(AppTokens.r12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.s12),
                child: SelectableText(
                  instructions.instructions.isEmpty
                      ? 'لا توجد تعليمات إضافية لهذا الطلب.'
                      : instructions.instructions,
                  style: const TextStyle(
                    color: AppTokens.sidebarBg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('تم'),
        ),
      ],
    ),
  );
}

class _InstructionLine extends StatelessWidget {
  const _InstructionLine({
    required this.label,
    required this.value,
    this.ltr = false,
  });

  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final shown = value.trim().isEmpty ? 'غير محدد' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(color: AppTokens.textMuted),
            ),
          ),
          Expanded(
            child: Directionality(
              textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
              child: SelectableText(
                shown,
                textAlign: ltr ? TextAlign.left : TextAlign.right,
                style: TextStyle(
                  color: AppTokens.sidebarBg,
                  fontWeight: FontWeight.w800,
                  fontFamily: ltr ? 'monospace' : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

PillTone _statusTone(String status) {
  return switch (status) {
    'paid' => PillTone.green,
    'proof_submitted' || 'under_review' => PillTone.amber,
    'rejected' || 'failed' || 'expired' => PillTone.red,
    _ => PillTone.neutral,
  };
}

String _moneyField(double? value) {
  if (value == null) return '';
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
}

double? _optionalAmount(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  return double.tryParse(text.replaceAll(',', '.'));
}

String _confirmationLabel(String mode) {
  return switch (mode) {
    'manual' => 'مراجعة يدوية',
    'automatic' => 'اعتماد آلي',
    _ => mode.trim().isEmpty ? 'غير محدد' : mode,
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
