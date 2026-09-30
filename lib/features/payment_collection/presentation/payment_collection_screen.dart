import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/format/currency.dart';
import '../../../core/l10n/arabic_labels.dart';
import '../../../core/theme/tokens.dart';
import '../../../features/admin_control/application/admin_control_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/currency_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/hub_switch_row.dart';
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
          subtitle: 'قبول إثبات الدفع أو رفضه وتطبيق الخدمة.',
          inlineActions: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () {
                ref.invalidate(paymentCollectionSettingsProvider);
                ref.invalidate(paymentReconciliationProvider);
                ref.invalidate(paymentRequestsProvider);
              },
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        ActionBar(
          items: [
            ActionItem(
              icon: Icons.add_circle_outline,
              label: 'طلب دفع جديد',
              primary: true,
              onPressed: () => _showCreatePaymentRequestDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        const _PaymentSettingsPanel(),
        const SizedBox(height: AppTokens.s12),
        const _PaymentReconciliationPanel(),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
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
              if (mode == 'all') ...[
                const SizedBox(height: AppTokens.s12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'الحالة'),
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
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
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

  /// The settings are configured once and rarely touched — the page is for
  /// reviewing payments — so the form starts folded to a one-line summary.
  bool _expanded = false;

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
    ValueChanged<bool>? toggle(void Function(bool) apply) =>
        _saving ? null : (value) => setState(() => apply(value));
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppTokens.r10),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      _enabled ? AppTokens.greenSoft : AppTokens.amberSoft,
                  child: Icon(
                    _enabled
                        ? Icons.account_balance_wallet_outlined
                        : Icons.wallet_outlined,
                    size: 20,
                    color: _enabled ? AppTokens.greenInk : AppTokens.amberInk,
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
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
                      Wrap(
                        spacing: AppTokens.s4,
                        runSpacing: AppTokens.s4,
                        children: [
                          StatusPill(
                            text: _enabled ? 'التحصيل مفعل' : 'التحصيل معطل',
                            tone: _enabled ? PillTone.green : PillTone.amber,
                            dot: true,
                          ),
                          StatusPill(
                            text: _confirmationLabel(_confirmationMode),
                            tone: PillTone.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppTokens.textSecondary,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: AppTokens.s8),
            HubSwitchRow(
              dense: true,
              label: 'تفعيل تحصيل المدفوعات',
              subtitle: _enabled
                  ? 'تأكد أن رقم المحفظة والتعليمات واضحة قبل استقبال إثباتات جديدة.'
                  : 'لن يتم إنشاء طلبات دفع جديدة حتى يتم تفعيل التحصيل.',
              value: _enabled,
              onChanged: toggle((v) => _enabled = v),
            ),
            const Divider(height: AppTokens.s16),
            FormFieldPair(
              first: FormFieldRow(
                label: 'مزود الدفع',
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _provider,
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
              ),
              second: FormFieldRow(
                label: 'صلاحية الطلب (دقيقة)',
                child: TextField(
                  controller: _ttlController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
            FormFieldPair(
              first: FormFieldRow(
                label: 'رقم المحفظة المستقبلة',
                child: TextField(
                  controller: _walletController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                ),
              ),
              second: FormFieldRow(
                label: 'اسم صاحب المحفظة',
                child: TextField(
                  controller: _ownerController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
              ),
            ),
            FormFieldPair(
              first: FormFieldRow(
                label: 'العملة',
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: kSupportedCurrencies.contains(_currency)
                      ? _currency
                      : kDefaultCurrency,
                  // Half-width field: show the name only once picked (the
                  // «— JOD» suffix stays in the open menu).
                  selectedItemBuilder: (context) => kSupportedCurrencies
                      .map(
                        (value) => Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            currencyLabel(value),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  items: kSupportedCurrencies
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            '${currencyLabel(value)} — $value',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(
                            () => _currency = normalizeCurrency(value),
                          ),
                ),
              ),
              second: FormFieldRow(
                label: 'طريقة الاعتماد',
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _confirmationMode,
                  items: const [
                    DropdownMenuItem(
                      value: 'manual',
                      child: Text(
                        'مراجعة يدوية',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'api',
                      child: Text(
                        'اعتماد عبر واجهة الربط',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(
                            () => _confirmationMode = value ?? 'manual',
                          ),
                ),
              ),
            ),
            FormFieldPair(
              first: FormFieldRow(
                label: 'أقل مبلغ',
                child: TextField(
                  controller: _minController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                ),
              ),
              second: FormFieldRow(
                label: 'أعلى مبلغ',
                child: TextField(
                  controller: _maxController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
            HubSwitchRow(
              dense: true,
              label: 'السماح بشراء الكروت',
              value: _allowCards,
              onChanged: toggle((v) => _allowCards = v),
            ),
            HubSwitchRow(
              dense: true,
              label: 'السماح باشتراكات المشتركين',
              value: _allowMonthly,
              onChanged: toggle((v) => _allowMonthly = v),
            ),
            HubSwitchRow(
              dense: true,
              label: 'السماح بدفعات الموزعين',
              value: _allowDistributors,
              onChanged: toggle((v) => _allowDistributors = v),
            ),
            HubSwitchRow(
              dense: true,
              label: 'تطبيق الخدمة تلقائيًا بعد الاعتماد',
              value: _autoApply,
              onChanged: toggle((v) => _autoApply = v),
            ),
            const SizedBox(height: AppTokens.s8),
            ActionBar(
              items: [
                ActionItem(
                  icon: _saving ? Icons.hourglass_top : Icons.save_outlined,
                  label: 'حفظ الإعدادات',
                  primary: true,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ],
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
        padding: const EdgeInsets.all(AppTokens.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      summary.isClean ? AppTokens.greenSoft : AppTokens.redSoft,
                  child: Icon(
                    summary.isClean
                        ? Icons.verified_user_outlined
                        : Icons.report_problem_outlined,
                    size: 20,
                    color:
                        summary.isClean ? AppTokens.greenInk : AppTokens.redInk,
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
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
                      Text(
                        summary.isClean
                            ? 'الطلبات متطابقة مع السجل المالي.'
                            : 'راجع البنود قبل إغلاق التحصيل اليومي.',
                        style: const TextStyle(
                          color: AppTokens.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                StatusPill(
                  text: summary.isClean
                      ? 'لا توجد ملاحظات'
                      : '${summary.totalIssues} ملاحظة',
                  tone: summary.isClean ? PillTone.green : PillTone.red,
                  dot: true,
                ),
              ],
            ),
            if (!summary.isClean) ...[
              const SizedBox(height: AppTokens.s12),
              CountGrid(
                columns: 2,
                items: [
                  CountItem(
                    'مدفوع بلا قيد مالي',
                    summary.count('paid_without_ledger'),
                    tone: PillTone.red,
                    hideWhenZero: true,
                  ),
                  CountItem(
                    'مدفوع ولم تطبق الخدمة',
                    summary.count('paid_not_applied'),
                    tone: PillTone.amber,
                    hideWhenZero: true,
                  ),
                  CountItem(
                    'طلبات منتهية تنتظر إجراء',
                    summary.count('expired_pending'),
                    tone: PillTone.amber,
                    hideWhenZero: true,
                  ),
                  CountItem(
                    'معاملات مزود مكررة',
                    summary.count('duplicate_provider_transactions'),
                    tone: PillTone.red,
                    hideWhenZero: true,
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              _ReconciliationList(summary: summary),
            ],
          ],
        ),
      ),
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
                                text: item.statusLabel,
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
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    r.isPaid ? AppTokens.greenSoft : AppTokens.brandSoft,
                child: Icon(
                  r.isPaid
                      ? Icons.check_circle_outline
                      : Icons.payments_outlined,
                  size: 20,
                  color: r.isPaid ? AppTokens.greenInk : AppTokens.brandInk,
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r.purposeLabel} - ${r.amountLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTokens.sidebarBg,
                      ),
                    ),
                    Text(
                      '${r.payerLabel} - مرجع ${r.referenceCodeOrId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              StatusPill(
                text: r.statusLabel,
                tone: _statusTone(r.status),
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          InfoGrid(
            items: [
              InfoItem(
                icon: Icons.playlist_add_check_circle_outlined,
                label: 'الخدمة',
                value: r.serviceApplyLabel,
              ),
              InfoItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'المحفظة',
                value: r.receiverWallet.isEmpty ? '—' : r.receiverWallet,
              ),
              InfoItem(
                icon: Icons.update,
                label: 'آخر تحديث',
                value: _shortDateLabel(r.updatedAt),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          ActionBar(
            maxPerRow: 2,
            items: [
              if (r.isReviewable)
                ActionItem(
                  icon: Icons.verified_outlined,
                  label: 'استلمت المبلغ',
                  primary: true,
                  onPressed: _busy ? null : () => _review(approve: true),
                ),
              if (r.isReviewable)
                ActionItem(
                  icon: Icons.cancel_outlined,
                  label: 'رفض الإثبات',
                  tone: PillTone.red,
                  onPressed: _busy ? null : () => _review(approve: false),
                ),
              if (r.canSubmitProof)
                ActionItem(
                  icon: Icons.upload_file_outlined,
                  label: 'رفع إثبات',
                  onPressed: _busy ? null : _submitProof,
                ),
              if (r.canApplyService)
                ActionItem(
                  icon: Icons.playlist_add_check_circle_outlined,
                  label: 'تطبيق الخدمة',
                  tone: PillTone.green,
                  onPressed: _busy ? null : _applyService,
                ),
              ActionItem(
                icon: Icons.open_in_new_outlined,
                label: 'تفاصيل الطلب',
                onPressed: _busy
                    ? null
                    : () => context.goNamed(
                          'payment-request-detail',
                          pathParameters: {'id': '${r.id}'},
                        ),
              ),
              ActionItem(
                icon: Icons.receipt_outlined,
                label: 'تعليمات الدفع',
                onPressed: _busy ? null : _showInstructions,
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

  Future<void> _submitProof() async {
    final draft = await _proofDialog(context);
    if (draft == null) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(paymentCollectionRepositoryProvider)
          .submitProof(widget.request.id, draft);
      ref.invalidate(paymentRequestsProvider);
      ref.invalidate(paymentReconciliationProvider);
      if (mounted) {
        _snack(
          context,
          'تم رفع الإثبات: ${result.proof.proofTypeLabel}',
        );
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

const _payerTypeOptions = [
  (value: 'subscriber', label: 'مشترك'),
  (value: 'card_user', label: 'مستخدم كرت'),
  (value: 'distributor', label: 'موزع'),
];

const _paymentPurposeOptions = [
  (value: 'card_purchase', label: 'شراء كروت'),
  (value: 'monthly_subscription', label: 'اشتراك شهري'),
  (value: 'subscriber_renewal', label: 'تجديد مشترك'),
  (value: 'quota_topup', label: 'إضافة حصة'),
  (value: 'time_extension', label: 'تمديد وقت'),
  (value: 'distributor_payment', label: 'دفعة موزع'),
  (value: 'loan_settlement', label: 'تسوية سلفة'),
];

const _proofTypeOptions = [
  (value: 'manual_reference', label: 'مرجع عملية'),
  (value: 'image', label: 'صورة إثبات'),
  (value: 'note', label: 'ملاحظة دفع'),
];

Future<void> _showCreatePaymentRequestDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final draft =
      await _paymentRequestDialog(context, ref.read(tenantCurrencyProvider));
  if (draft == null) return;
  try {
    final created = await ref
        .read(paymentCollectionRepositoryProvider)
        .createRequest(draft);
    ref.read(paymentCollectionModeProvider.notifier).state = 'all';
    ref.read(paymentCollectionStatusProvider.notifier).state = 'pending';
    ref.invalidate(paymentRequestsProvider);
    ref.invalidate(paymentReconciliationProvider);
    if (context.mounted) {
      _snack(
        context,
        'تم إنشاء طلب الدفع ${created.referenceCode.isEmpty ? '#${created.id}' : created.referenceCode}',
      );
    }
  } catch (error) {
    if (context.mounted) _snack(context, visibleErrorMessage(error));
  }
}

Future<PaymentRequestDraft?> _paymentRequestDialog(
  BuildContext context,
  String tenantCurrency,
) async {
  final formKey = GlobalKey<FormState>();
  final payerId = TextEditingController();
  final amount = TextEditingController();
  var payerType = 'subscriber';
  var purpose = 'subscriber_renewal';
  final currency = tenantCurrency;
  final result = await showDialog<PaymentRequestDraft>(
    context: context,
    useRootNavigator: true,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('طلب دفع جديد'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: payerType,
                  decoration: const InputDecoration(labelText: 'نوع الدافع'),
                  items: _payerTypeOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option.value,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => payerType = value ?? 'subscriber'),
                ),
                const SizedBox(height: AppTokens.s12),
                TextFormField(
                  controller: payerId,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'رقم الدافع',
                    helperText: 'اختياري إذا لم يتم ربط الطلب بسجل محدد.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    final parsed = int.tryParse(text);
                    if (parsed == null || parsed <= 0) {
                      return 'أدخل رقمًا صحيحًا أو اتركه فارغًا';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTokens.s12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: purpose,
                  decoration: const InputDecoration(labelText: 'الغرض'),
                  items: _paymentPurposeOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option.value,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => purpose = value ?? 'subscriber_renewal'),
                ),
                const SizedBox(height: AppTokens.s12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: amount,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'المبلغ',
                          helperText: kMaxMoneyHelper,
                        ),
                        validator: (value) =>
                            readMoneyInput(value ?? '').error,
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: CurrencyField(currency: currency),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(context).pop(
                PaymentRequestDraft(
                  payerType: payerType,
                  payerId: int.tryParse(payerId.text.trim()),
                  purpose: purpose,
                  amount: readMoneyInput(amount.text).value!,
                  currency: currency,
                ),
              );
            },
            child: const Text('إنشاء الطلب'),
          ),
        ],
      ),
    ),
  );
  payerId.dispose();
  amount.dispose();
  return result;
}

Future<PaymentProofDraft?> _proofDialog(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  final reference = TextEditingController();
  final note = TextEditingController();
  var proofType = 'manual_reference';
  final result = await showDialog<PaymentProofDraft>(
    context: context,
    useRootNavigator: true,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('رفع إثبات دفع'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: proofType,
                  decoration: const InputDecoration(labelText: 'نوع الإثبات'),
                  items: _proofTypeOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option.value,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => proofType = value ?? 'manual_reference'),
                ),
                const SizedBox(height: AppTokens.s12),
                TextFormField(
                  controller: reference,
                  decoration: const InputDecoration(
                    labelText: 'رقم العملية أو المرجع',
                    helperText: 'مطلوب عند اختيار مرجع عملية.',
                  ),
                  validator: (value) {
                    if (proofType != 'manual_reference') return null;
                    if ((value ?? '').trim().isEmpty) {
                      return 'أدخل رقم العملية';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTokens.s12),
                TextFormField(
                  controller: note,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة',
                    helperText: 'اكتب أي تفاصيل تساعد الإدارة في المراجعة.',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(context).pop(
                PaymentProofDraft(
                  proofType: proofType,
                  referenceNumber: reference.text.trim(),
                  note: note.text.trim(),
                ),
              );
            },
            child: const Text('رفع الإثبات'),
          ),
        ],
      ),
    ),
  );
  reference.dispose();
  note.dispose();
  return result;
}

Future<String?> _noteDialog(
  BuildContext context, {
  required String title,
  required String label,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    useRootNavigator: true,
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
    useRootNavigator: true,
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
    'api' => 'اعتماد عبر واجهة الربط',
    _ => unknownStatusLabel(
        mode,
        unknownLabel: 'طريقة اعتماد غير معروفة',
      ),
  };
}

/// Date for a narrow grid cell: the year only when it is not this year.
String _shortDateLabel(DateTime? date) {
  if (date == null) return '—';
  String two(int value) => value.toString().padLeft(2, '0');
  if (date.year != DateTime.now().year) {
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
  return '${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
}

String _dateLabel(DateTime? date) {
  if (date == null) return 'غير محدد';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
}

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
