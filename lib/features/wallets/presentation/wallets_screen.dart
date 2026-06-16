import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/l10n/arabic_labels.dart';
import '../../../core/theme/tokens.dart';
import '../../../features/admin_control/application/admin_control_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/currency_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/wallets_repository.dart';
import '../domain/wallet_model.dart';

const _ownerTypeOptions = [
  (value: '', label: 'كل المالكين'),
  (value: 'company', label: 'الشركة'),
  (value: 'manager', label: 'مدير'),
  (value: 'distributor', label: 'موزع'),
  (value: 'subscriber', label: 'مشترك'),
  (value: 'card_user', label: 'مستخدم كروت'),
];

const _statusOptions = [
  (value: '', label: 'كل الحالات'),
  (value: 'active', label: 'نشطة'),
  (value: 'suspended', label: 'موقوفة'),
  (value: 'closed', label: 'مغلقة'),
];

const _referenceTypeOptions = [
  (value: 'manual', label: 'تسجيل يدوي'),
  (value: 'subscriber_payment', label: 'دفعة مشترك'),
  (value: 'invoice', label: 'فاتورة'),
  (value: 'voucher', label: 'كوبون'),
  (value: 'card_sale', label: 'بيع كروت'),
];

final _walletsProvider = FutureProvider.autoDispose
    .family<WalletPage, ({String ownerType, String status})>((ref, filter) {
  return ref
      .watch(walletsRepositoryProvider)
      .list(ownerType: filter.ownerType, status: filter.status);
});

final _transactionsProvider = FutureProvider.autoDispose
    .family<WalletTransactionsPage, int>((ref, walletId) {
  return ref.watch(walletsRepositoryProvider).transactions(walletId);
});

class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> {
  String _ownerType = '';
  String _status = '';

  ({String ownerType, String status}) get _filter =>
      (ownerType: _ownerType, status: _status);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_walletsProvider(_filter));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'الخزائن والمحافظ',
          subtitle:
              'إنشاء المحافظ، شحنها أو الخصم منها، ومراجعة آخر الحركات المالية من نفس عقد الويب.',
          leading: const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppTokens.brand,
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(_walletsProvider(_filter)),
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
            FilledButton.icon(
              onPressed: _createWallet,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('محفظة جديدة'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Wrap(
            spacing: AppTokens.s12,
            runSpacing: AppTokens.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'الفلاتر:',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              _CompactSelect(
                value: _ownerType,
                options: _ownerTypeOptions,
                onChanged: (value) => setState(() => _ownerType = value ?? ''),
              ),
              _CompactSelect(
                value: _status,
                options: _statusOptions,
                onChanged: (value) => setState(() => _status = value ?? ''),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر تحميل المحافظ',
            subtitle: visibleErrorMessage(error),
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return const EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'لا توجد محافظ بهذه الفلترة',
                subtitle:
                    'أنشئ محفظة للشركة أو لمشترك أو لموزع، ثم استخدم الشحن والخصم مع سجل قابل للتتبع.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WalletSummary(items: page.items, count: page.count),
                const SizedBox(height: AppTokens.s12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 900) {
                      return Column(
                        children: [
                          for (final wallet in page.items) ...[
                            _WalletCard(
                              wallet: wallet,
                              onChanged: _refresh,
                            ),
                            const SizedBox(height: AppTokens.s12),
                          ],
                        ],
                      );
                    }
                    return _WalletsTable(
                      items: page.items,
                      onChanged: _refresh,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _refresh() {
    ref.invalidate(_walletsProvider(_filter));
  }

  Future<void> _createWallet() async {
    final draft = await _walletDialog(context, ref.read(tenantCurrencyProvider));
    if (draft == null) return;
    try {
      final created = await ref.read(walletsRepositoryProvider).create(draft);
      _refresh();
      if (!mounted) return;
      _snack(context, 'تم إنشاء محفظة ${created.ownerLabel}');
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    }
  }
}

class _WalletSummary extends StatelessWidget {
  const _WalletSummary({required this.items, required this.count});

  final List<WalletRecord> items;
  final int count;

  @override
  Widget build(BuildContext context) {
    final active = items.where((item) => item.status == 'active').length;
    final balancesByCurrency = <String, double>{};
    for (final item in items) {
      balancesByCurrency.update(
        item.currency,
        (value) => value + (double.tryParse(item.balance) ?? 0),
        ifAbsent: () => double.tryParse(item.balance) ?? 0,
      );
    }
    final balanceText = balancesByCurrency.entries
        .map((entry) => amountWithCurrency(_money(entry.value), entry.key))
        .join(' / ');
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 720 ? 2 : 3;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTokens.s8,
          crossAxisSpacing: AppTokens.s8,
          childAspectRatio: constraints.maxWidth < 720 ? 2.35 : 3,
          children: [
            _SummaryCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'عدد المحافظ',
              value: '$count',
              tone: PillTone.brand,
            ),
            _SummaryCard(
              icon: Icons.check_circle_outline,
              title: 'محافظ نشطة',
              value: '$active',
              tone: PillTone.green,
            ),
            _SummaryCard(
              icon: Icons.summarize_outlined,
              title: 'الأرصدة المعروضة',
              value: balanceText.isEmpty ? '0.00' : balanceText,
              tone: PillTone.blue,
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String value;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          StatusPill(text: '', icon: icon, tone: tone),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.sidebarBg,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletsTable extends StatelessWidget {
  const _WalletsTable({required this.items, required this.onChanged});

  final List<WalletRecord> items;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('المالك')),
            DataColumn(label: Text('الرصيد')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('آخر تحديث')),
            DataColumn(label: Text('إجراءات')),
          ],
          rows: [
            for (final wallet in items)
              DataRow(
                cells: [
                  DataCell(Text('${wallet.id}')),
                  DataCell(Text(wallet.ownerLabel)),
                  DataCell(
                    Text(amountWithCurrency(wallet.balance, wallet.currency)),
                  ),
                  DataCell(
                    StatusPill(
                      text: wallet.statusLabel,
                      tone: _statusTone(wallet.status),
                    ),
                  ),
                  DataCell(Text(_fmt(wallet.updatedAt))),
                  DataCell(
                    _WalletActions(wallet: wallet, onChanged: onChanged),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.wallet, required this.onChanged});

  final WalletRecord wallet;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppTokens.brand,
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.ownerLabel,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'محفظة رقم ${wallet.id}',
                      style: const TextStyle(color: AppTokens.textMuted),
                    ),
                  ],
                ),
              ),
              StatusPill(
                text: wallet.statusLabel,
                tone: _statusTone(wallet.status),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          _InfoLine(
            label: 'الرصيد',
            value: amountWithCurrency(wallet.balance, wallet.currency),
          ),
          _InfoLine(label: 'آخر تحديث', value: _fmt(wallet.updatedAt)),
          const SizedBox(height: AppTokens.s12),
          _WalletActions(wallet: wallet, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _WalletActions extends ConsumerWidget {
  const _WalletActions({required this.wallet, required this.onChanged});

  final WalletRecord wallet;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      children: [
        FilledButton.icon(
          onPressed: () => _changeBalance(
            context,
            ref,
            wallet,
            credit: true,
            onChanged: onChanged,
          ),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('شحن'),
        ),
        OutlinedButton.icon(
          onPressed: () => _changeBalance(
            context,
            ref,
            wallet,
            credit: false,
            onChanged: onChanged,
          ),
          icon: const Icon(Icons.remove_circle_outline),
          label: const Text('خصم'),
        ),
        TextButton.icon(
          onPressed: () => _showTransactions(context, wallet),
          icon: const Icon(Icons.history),
          label: const Text('الحركات'),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: AppTokens.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSelect extends StatelessWidget {
  const _CompactSelect({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<({String label, String value})> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option.value,
              child: Text(option.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

Future<void> _changeBalance(
  BuildContext context,
  WidgetRef ref,
  WalletRecord wallet, {
  required bool credit,
  required VoidCallback onChanged,
}) async {
  final draft = await _walletChangeDialog(context, credit: credit);
  if (draft == null) return;
  try {
    final repo = ref.read(walletsRepositoryProvider);
    final result = credit
        ? await repo.credit(wallet.id, draft)
        : await repo.debit(wallet.id, draft);
    onChanged();
    ref.invalidate(_transactionsProvider(wallet.id));
    if (!context.mounted) return;
    _snack(
      context,
      credit
          ? 'تم شحن المحفظة. الرصيد الجديد ${amountWithCurrency(result.wallet.balance, result.wallet.currency)}'
          : 'تم خصم الرصيد. الرصيد الجديد ${amountWithCurrency(result.wallet.balance, result.wallet.currency)}',
    );
  } catch (error) {
    if (context.mounted) _snack(context, visibleErrorMessage(error));
  }
}

Future<void> _showTransactions(
  BuildContext context,
  WalletRecord wallet,
) async {
  await showDialog<void>(
    context: context,
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final async = ref.watch(_transactionsProvider(wallet.id));
        return AlertDialog(
          title: Text('حركات ${wallet.ownerLabel}'),
          content: SizedBox(
            width: 560,
            child: async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppTokens.s24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text(visibleErrorMessage(error)),
              data: (page) {
                if (page.items.isEmpty) {
                  return const Text('لا توجد حركات على هذه المحفظة بعد.');
                }
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final tx in page.items) ...[
                        _TransactionRow(tx: tx),
                        const Divider(height: 1),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    ),
  );
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});

  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final credit = tx.transactionType == 'credit';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(
            text: tx.typeLabel,
            tone: credit ? PillTone.green : PillTone.amber,
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amountWithCurrency(tx.amount, tx.currency),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${tx.referenceLabel} - ${_fmt(tx.createdAt)}',
                  style: const TextStyle(color: AppTokens.textMuted),
                ),
                if (tx.notes.trim().isNotEmpty)
                  Text(
                    tx.notes,
                    style: const TextStyle(color: AppTokens.textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            tx.afterBalance,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

Future<WalletCreateDraft?> _walletDialog(
  BuildContext context,
  String tenantCurrency,
) async {
  final formKey = GlobalKey<FormState>();
  final ownerId = TextEditingController();
  var ownerType = 'company';
  final currency = tenantCurrency;
  final result = await showDialog<WalletCreateDraft>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('محفظة جديدة'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SelectField(
                label: 'نوع المالك',
                value: ownerType,
                options: _ownerTypeOptions.where(
                  (option) => option.value.isNotEmpty,
                ),
                onChanged: (value) {
                  setState(() {
                    ownerType = value ?? 'company';
                    if (ownerType == 'company') ownerId.clear();
                  });
                },
              ),
              const SizedBox(height: AppTokens.s12),
              TextFormField(
                controller: ownerId,
                enabled: ownerType != 'company',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رقم المالك',
                  helperText: 'مطلوب للمشترك أو الموزع أو مستخدم الكروت.',
                ),
                validator: (value) {
                  if (ownerType == 'company') return null;
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'أدخل رقم المالك';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.s12),
              CurrencyField(currency: currency),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                WalletCreateDraft(
                  ownerType: ownerType,
                  ownerId: int.tryParse(ownerId.text.trim()),
                  currency: currency,
                ),
              );
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    ),
  );
  ownerId.dispose();
  return result;
}

Future<WalletChangeDraft?> _walletChangeDialog(
  BuildContext context, {
  required bool credit,
}) async {
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController();
  final referenceId = TextEditingController();
  final notes = TextEditingController();
  var referenceType = 'manual';
  final result = await showDialog<WalletChangeDraft>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(credit ? 'شحن محفظة' : 'خصم من محفظة'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed <= 0) {
                      return 'أدخل مبلغًا موجبًا';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTokens.s12),
                _SelectField(
                  label: 'نوع المرجع',
                  value: referenceType,
                  options: _referenceTypeOptions,
                  onChanged: (value) =>
                      setState(() => referenceType = value ?? 'manual'),
                ),
                const SizedBox(height: AppTokens.s12),
                TextFormField(
                  controller: referenceId,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'رقم المرجع',
                    helperText: 'اختياري إذا كان التسجيل يدويًا فقط.',
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                TextFormField(
                  controller: notes,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                WalletChangeDraft(
                  amount: double.parse(amount.text.trim().replaceAll(',', '.')),
                  referenceType: referenceType,
                  referenceId: int.tryParse(referenceId.text.trim()),
                  notes: notes.text.trim(),
                ),
              );
            },
            child: Text(credit ? 'شحن' : 'خصم'),
          ),
        ],
      ),
    ),
  );
  amount.dispose();
  referenceId.dispose();
  notes.dispose();
  return result;
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Iterable<({String label, String value})> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option.value,
              child: Text(option.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

PillTone _statusTone(String status) {
  return switch (status) {
    'active' => PillTone.green,
    'suspended' => PillTone.amber,
    'closed' => PillTone.neutral,
    _ => PillTone.neutral,
  };
}

String _money(num value) {
  return NumberFormat('#,##0.##').format(value);
}

String _fmt(DateTime? value) {
  if (value == null) return 'غير محدد';
  return DateFormat('yyyy-MM-dd HH:mm').format(value);
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
