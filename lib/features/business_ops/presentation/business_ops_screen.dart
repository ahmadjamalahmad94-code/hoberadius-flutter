import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/l10n/arabic_labels.dart';
import '../../../core/theme/tokens.dart';
import '../../../features/admin_control/application/admin_control_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/currency_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_kpi.dart';
import '../data/business_ops_repository.dart';
import '../domain/business_ops_model.dart';

final _summaryProvider = FutureProvider.autoDispose<BusinessSummary>((ref) {
  return ref.watch(businessOpsRepositoryProvider).summary();
});

final _ledgerProvider = FutureProvider.autoDispose
    .family<List<BusinessLedgerEntry>, String>((ref, entryType) {
  return ref
      .watch(businessOpsRepositoryProvider)
      .listLedger(entryType: entryType);
});

final _snapshotsProvider = FutureProvider.autoDispose
    .family<List<PriceSnapshot>, String>((ref, referenceType) {
  return ref
      .watch(businessOpsRepositoryProvider)
      .listSnapshots(referenceType: referenceType);
});

/// Business-OS operators console — append-only finance ledger (with correction
/// posting) and immutable pricing snapshots. Mirrors the web
/// `business_operators` / finance-center surfaces, admin-authed via
/// `require_api_token`.
class BusinessOpsScreen extends ConsumerStatefulWidget {
  const BusinessOpsScreen({super.key});

  @override
  ConsumerState<BusinessOpsScreen> createState() => _BusinessOpsScreenState();
}

class _BusinessOpsScreenState extends ConsumerState<BusinessOpsScreen> {
  String _entryType = '';
  String _referenceType = '';

  void _refreshAll() {
    ref.invalidate(_summaryProvider);
    ref.invalidate(_ledgerProvider(_entryType));
    ref.invalidate(_snapshotsProvider(_referenceType));
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(_summaryProvider);
    final ledgerAsync = ref.watch(_ledgerProvider(_entryType));
    final snapshotsAsync = ref.watch(_snapshotsProvider(_referenceType));
    final currency = ref.watch(tenantCurrencyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'كونسول مشغّلي الأعمال',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.sidebarBg,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: _refreshAll,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        const AppCard(
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTokens.brand),
              SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'السجل المالي إضافة فقط — لا حذف ولا تعديل مباشر. أي تصحيح '
                  'يُسجَّل كقيد جديد قابل للتتبع. لقطات التسعير غير قابلة للتغيير '
                  'بعد التقاطها.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        summaryAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTokens.s24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب مؤشرات الأعمال',
            subtitle: visibleErrorMessage(e),
          ),
          data: (summary) => _SummaryHero(summary, currency: currency),
        ),
        const SizedBox(height: AppTokens.s20),
        _LedgerSection(
          async: ledgerAsync,
          entryType: _entryType,
          onEntryTypeChanged: (value) => setState(() => _entryType = value),
          onNewCorrection: _openCorrectionDialog,
        ),
        const SizedBox(height: AppTokens.s20),
        _SnapshotsSection(
          async: snapshotsAsync,
          referenceType: _referenceType,
          onReferenceTypeChanged: (value) =>
              setState(() => _referenceType = value),
          onCapture: _openSnapshotDialog,
        ),
      ],
    );
  }

  Future<void> _openCorrectionDialog() async {
    final currency = ref.read(tenantCurrencyProvider);
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CorrectionDialog(currency: currency),
    );
    if (created == true) {
      ref.invalidate(_ledgerProvider(_entryType));
      ref.invalidate(_summaryProvider);
    }
  }

  Future<void> _openSnapshotDialog() async {
    final currency = ref.read(tenantCurrencyProvider);
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _SnapshotDialog(currency: currency),
    );
    if (created == true) {
      ref.invalidate(_snapshotsProvider(_referenceType));
      ref.invalidate(_summaryProvider);
    }
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero(this.summary, {required this.currency});

  final BusinessSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final kpis = <Widget>[
      HubKpi(
        label: 'إجمالي السجل المالي',
        value: amountWithCurrency(summary.ledgerTotal, currency),
        icon: Icons.menu_book_outlined,
        variant: KpiVariant.brand,
        subtitle: '${summary.ledgerEntries} قيد',
      ),
      HubKpi(
        label: 'أرصدة المحافظ',
        value: amountWithCurrency(summary.walletBalance, currency),
        icon: Icons.account_balance_wallet_outlined,
        variant: KpiVariant.blue,
        subtitle: '${summary.wallets} محفظة',
      ),
      HubKpi(
        label: 'لقطات التسعير',
        value: '${summary.priceSnapshots}',
        icon: Icons.sell_outlined,
        variant: KpiVariant.amber,
      ),
      HubKpi(
        label: 'سجلات الإيراد',
        value: '${summary.revenueRecords}',
        icon: Icons.receipt_long_outlined,
        variant: KpiVariant.green,
        subtitle: '${summary.events} حدث أعمال',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 880
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        const gap = AppTokens.s12;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final kpi in kpis) SizedBox(width: itemWidth, child: kpi),
          ],
        );
      },
    );
  }
}

class _LedgerSection extends StatelessWidget {
  const _LedgerSection({
    required this.async,
    required this.entryType,
    required this.onEntryTypeChanged,
    required this.onNewCorrection,
  });

  final AsyncValue<List<BusinessLedgerEntry>> async;
  final String entryType;
  final ValueChanged<String> onEntryTypeChanged;
  final VoidCallback onNewCorrection;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'قيود السجل المالي',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTokens.sidebarBg,
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: entryType,
                  items: const [
                    DropdownMenuItem(value: '', child: Text('كل الأنواع')),
                    DropdownMenuItem(value: 'correction', child: Text('تصحيح')),
                    DropdownMenuItem(value: 'payment', child: Text('دفعة')),
                    DropdownMenuItem(value: 'renewal', child: Text('تجديد')),
                    DropdownMenuItem(value: 'loan', child: Text('سلفة')),
                    DropdownMenuItem(value: 'debt', child: Text('دين')),
                    DropdownMenuItem(value: 'discount', child: Text('خصم')),
                    DropdownMenuItem(
                      value: 'wallet_recharge',
                      child: Text('شحن محفظة'),
                    ),
                    DropdownMenuItem(
                      value: 'card_sale',
                      child: Text('بيع بطاقة'),
                    ),
                    DropdownMenuItem(
                      value: 'profit_share',
                      child: Text('حصة ربح'),
                    ),
                    DropdownMenuItem(
                      value: 'reversal',
                      child: Text('قيد عكسي'),
                    ),
                  ],
                  onChanged: (value) => onEntryTypeChanged(value ?? ''),
                ),
                FilledButton.icon(
                  onPressed: onNewCorrection,
                  icon: const Icon(Icons.add),
                  label: const Text('قيد تصحيح'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppTokens.s24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'تعذر جلب السجل المالي',
                subtitle: visibleErrorMessage(e),
              ),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(AppTokens.s16),
                  child: EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'لا توجد قيود بهذه الفلترة',
                    subtitle: 'ابدأ بإضافة قيد تصحيح، أو غيّر نوع الفلترة.',
                  ),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('النوع')),
                    DataColumn(label: Text('مدين')),
                    DataColumn(label: Text('دائن')),
                    DataColumn(label: Text('المبلغ')),
                    DataColumn(label: Text('الهدف')),
                    DataColumn(label: Text('المرجع')),
                    DataColumn(label: Text('التاريخ')),
                  ],
                  rows: entries.map((entry) {
                    return DataRow(
                      cells: [
                        DataCell(Text('${entry.id}')),
                        DataCell(_TypeChip(entry: entry)),
                        DataCell(Text(_dash(entry.debitAccount))),
                        DataCell(Text(_dash(entry.creditAccount))),
                        DataCell(
                          Text(
                            amountWithCurrency(entry.amount, entry.currency),
                          ),
                        ),
                        DataCell(Text(_ref(entry.targetType, entry.targetId))),
                        DataCell(
                          Text(_ref(entry.referenceType, entry.referenceId)),
                        ),
                        DataCell(Text(_fmtDate(entry.createdAt))),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.entry});

  final BusinessLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final correction = entry.isCorrection;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: correction ? AppTokens.amberSoft : AppTokens.brandSoft,
        borderRadius: BorderRadius.circular(AppTokens.r10),
      ),
      child: Text(
        businessLedgerTypeLabel(entry.entryType),
        style: TextStyle(
          color: correction ? AppTokens.amberInk : AppTokens.brandInk,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SnapshotsSection extends StatelessWidget {
  const _SnapshotsSection({
    required this.async,
    required this.referenceType,
    required this.onReferenceTypeChanged,
    required this.onCapture,
  });

  final AsyncValue<List<PriceSnapshot>> async;
  final String referenceType;
  final ValueChanged<String> onReferenceTypeChanged;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'لقطات التسعير',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTokens.sidebarBg,
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: referenceType,
                  items: const [
                    DropdownMenuItem(value: '', child: Text('كل المراجع')),
                    DropdownMenuItem(value: 'package', child: Text('باقة')),
                    DropdownMenuItem(value: 'plan', child: Text('عرض')),
                    DropdownMenuItem(
                      value: 'card_batch',
                      child: Text('حزمة بطاقات'),
                    ),
                    DropdownMenuItem(
                      value: 'subscription',
                      child: Text('اشتراك'),
                    ),
                  ],
                  onChanged: (value) => onReferenceTypeChanged(value ?? ''),
                ),
                FilledButton.icon(
                  onPressed: onCapture,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('التقاط لقطة'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppTokens.s24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'تعذر جلب لقطات التسعير',
                subtitle: visibleErrorMessage(e),
              ),
            ),
            data: (snapshots) {
              if (snapshots.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(AppTokens.s16),
                  child: EmptyState(
                    icon: Icons.sell_outlined,
                    title: 'لا توجد لقطات تسعير',
                    subtitle: 'التقط لقطة لتثبيت الأسعار قبل أي إجراء إيرادي.',
                  ),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('المرجع')),
                    DataColumn(label: Text('الباقة')),
                    DataColumn(label: Text('التجزئة')),
                    DataColumn(label: Text('الجملة')),
                    DataColumn(label: Text('الفعلي')),
                    DataColumn(label: Text('الخصم')),
                    DataColumn(label: Text('التاريخ')),
                  ],
                  rows: snapshots.map((snapshot) {
                    return DataRow(
                      cells: [
                        DataCell(Text('${snapshot.id}')),
                        DataCell(
                          Text(
                            _ref(
                              snapshot.referenceType,
                              snapshot.referenceId,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            snapshot.packageId == null
                                ? '—'
                                : '${snapshot.packageId}',
                          ),
                        ),
                        DataCell(
                          Text(
                            amountWithCurrency(
                              snapshot.retailPrice,
                              snapshot.currency,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            amountWithCurrency(
                              snapshot.wholesalePrice,
                              snapshot.currency,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            amountWithCurrency(
                              snapshot.effectivePrice,
                              snapshot.currency,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            amountWithCurrency(
                              snapshot.discountAmount,
                              snapshot.currency,
                            ),
                          ),
                        ),
                        DataCell(Text(_fmtDate(snapshot.capturedAt))),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CorrectionDialog extends ConsumerStatefulWidget {
  const _CorrectionDialog({required this.currency});

  final String currency;

  @override
  ConsumerState<_CorrectionDialog> createState() => _CorrectionDialogState();
}

class _CorrectionDialogState extends ConsumerState<_CorrectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _debit = TextEditingController();
  final _credit = TextEditingController();
  final _amount = TextEditingController();
  final _targetType = TextEditingController();
  final _targetId = TextEditingController();
  final _referenceType = TextEditingController();
  final _referenceId = TextEditingController();
  final _reason = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _debit.dispose();
    _credit.dispose();
    _amount.dispose();
    _targetType.dispose();
    _targetId.dispose();
    _referenceType.dispose();
    _referenceId.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('قيد تصحيح مالي'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _debit,
                  decoration: const InputDecoration(
                    labelText: 'حساب المدين *',
                    helperText: 'مثال: cash، wallet:12، revenue',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: AppTokens.s8),
                TextFormField(
                  controller: _credit,
                  decoration: const InputDecoration(
                    labelText: 'حساب الدائن *',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: AppTokens.s8),
                TextFormField(
                  controller: _amount,
                  decoration: const InputDecoration(labelText: 'المبلغ *'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: _positiveAmount,
                ),
                const SizedBox(height: AppTokens.s8),
                CurrencyField(currency: widget.currency),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _targetType,
                        decoration:
                            const InputDecoration(labelText: 'نوع الهدف'),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: TextFormField(
                        controller: _targetId,
                        decoration:
                            const InputDecoration(labelText: 'رقم الهدف'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _referenceType,
                        decoration:
                            const InputDecoration(labelText: 'نوع المرجع'),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: TextFormField(
                        controller: _referenceId,
                        decoration:
                            const InputDecoration(labelText: 'رقم المرجع'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                TextFormField(
                  controller: _reason,
                  decoration: const InputDecoration(
                    labelText: 'سبب التصحيح',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('تسجيل القيد'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(businessOpsRepositoryProvider).createCorrection(
            debitAccount: _debit.text.trim(),
            creditAccount: _credit.text.trim(),
            amount: num.parse(_amount.text.trim()),
            currency: widget.currency,
            targetType: _targetType.text.trim(),
            targetId: int.tryParse(_targetId.text.trim()),
            referenceType: _referenceType.text.trim(),
            referenceId: int.tryParse(_referenceId.text.trim()),
            reason: _reason.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل قيد التصحيح')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    }
  }
}

class _SnapshotDialog extends ConsumerStatefulWidget {
  const _SnapshotDialog({required this.currency});

  final String currency;

  @override
  ConsumerState<_SnapshotDialog> createState() => _SnapshotDialogState();
}

class _SnapshotDialogState extends ConsumerState<_SnapshotDialog> {
  final _formKey = GlobalKey<FormState>();
  final _referenceType = TextEditingController();
  final _referenceId = TextEditingController();
  final _packageId = TextEditingController();
  final _retail = TextEditingController();
  final _wholesale = TextEditingController();
  final _effective = TextEditingController();
  final _discount = TextEditingController(text: '0');
  bool _saving = false;

  @override
  void dispose() {
    _referenceType.dispose();
    _referenceId.dispose();
    _packageId.dispose();
    _retail.dispose();
    _wholesale.dispose();
    _effective.dispose();
    _discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('التقاط لقطة تسعير'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _referenceType,
                  decoration: const InputDecoration(
                    labelText: 'نوع المرجع *',
                    helperText: 'مثال: package، plan، card_batch',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _referenceId,
                        decoration:
                            const InputDecoration(labelText: 'رقم المرجع'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: TextFormField(
                        controller: _packageId,
                        decoration:
                            const InputDecoration(labelText: 'رقم الباقة'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _retail,
                        decoration:
                            const InputDecoration(labelText: 'سعر التجزئة *'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        validator: _nonNegative,
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: TextFormField(
                        controller: _wholesale,
                        decoration:
                            const InputDecoration(labelText: 'سعر الجملة *'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        validator: _nonNegative,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _effective,
                        decoration: const InputDecoration(
                          labelText: 'السعر الفعلي',
                          helperText: 'افتراضيًا = التجزئة',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        validator: _optionalNonNegative,
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: TextFormField(
                        controller: _discount,
                        decoration: const InputDecoration(labelText: 'الخصم'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        validator: _optionalNonNegative,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                CurrencyField(currency: widget.currency),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('التقاط'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(businessOpsRepositoryProvider).captureSnapshot(
            referenceType: _referenceType.text.trim(),
            referenceId: int.tryParse(_referenceId.text.trim()),
            packageId: int.tryParse(_packageId.text.trim()),
            retailPrice: num.parse(_retail.text.trim()),
            wholesalePrice: num.parse(_wholesale.text.trim()),
            effectivePrice: _effective.text.trim().isEmpty
                ? null
                : num.tryParse(_effective.text.trim()),
            discountAmount: num.tryParse(_discount.text.trim()) ?? 0,
            currency: widget.currency,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم التقاط لقطة التسعير')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    }
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return 'مطلوب';
  return null;
}

String? _positiveAmount(String? value) {
  final parsed = num.tryParse(value?.trim() ?? '');
  if (parsed == null) return 'أدخل رقمًا صحيحًا';
  if (parsed <= 0) return 'يجب أن يكون أكبر من صفر';
  return null;
}

String? _nonNegative(String? value) {
  final parsed = num.tryParse(value?.trim() ?? '');
  if (parsed == null) return 'أدخل رقمًا صحيحًا';
  if (parsed < 0) return 'لا يمكن أن يكون سالبًا';
  return null;
}

String? _optionalNonNegative(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return _nonNegative(value);
}

String _dash(String value) => value.trim().isEmpty ? '—' : value;

String _ref(String type, int? id) {
  if (type.trim().isEmpty && id == null) return '—';
  if (id == null) return type;
  return '$type #$id';
}

String _fmtDate(DateTime? value) {
  if (value == null) return '—';
  return DateFormat('yyyy-MM-dd HH:mm').format(value);
}
