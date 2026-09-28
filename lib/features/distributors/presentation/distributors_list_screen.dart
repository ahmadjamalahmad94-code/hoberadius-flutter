import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/format/currency.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/distributors_repository.dart';
import '../domain/distributor_model.dart';

final distributorsListProvider =
    FutureProvider.autoDispose<List<Distributor>>((ref) {
  return ref.watch(distributorsRepositoryProvider).list();
});

class DistributorsListScreen extends ConsumerWidget {
  const DistributorsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(distributorsListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'الموزعون والصلاحيات',
          inlineActions: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () => ref.invalidate(distributorsListProvider),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        ActionBar(
          items: [
            ActionItem(
              icon: Icons.add,
              label: 'موزع جديد',
              primary: true,
              onPressed: () => context.goNamed('distributor-new'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب الموزعين',
            subtitle: visibleErrorMessage(e),
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(distributorsListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.people_alt_outlined,
                title: 'لا يوجد موزعون بعد',
                subtitle:
                    'أضف أول موزع ثم اربط به حزم الكروت حسب النطاق المطلوب.',
                action: ElevatedButton.icon(
                  onPressed: () => context.goNamed('distributor-new'),
                  icon: const Icon(Icons.add),
                  label: const Text('موزع جديد'),
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 760;
                if (!wide) {
                  return Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppTokens.s8),
                        _DistributorCard(distributor: items[i]),
                      ],
                    ],
                  );
                }
                return Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('الموزع')),
                        DataColumn(label: Text('التواصل')),
                        DataColumn(label: Text('الصلاحيات')),
                        DataColumn(label: Text('الدين')),
                        DataColumn(label: Text('الحالة')),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final item in items)
                          DataRow(
                            cells: [
                              DataCell(_NameCell(distributor: item)),
                              DataCell(
                                Text(item.phone.isEmpty ? '—' : item.phone),
                              ),
                              DataCell(
                                Text(
                                  item.permissions
                                      .take(2)
                                      .map(distributorPermissionLabel)
                                      .join('، '),
                                ),
                              ),
                              DataCell(
                                Text(item.debtBalance.toStringAsFixed(2)),
                              ),
                              DataCell(_Status(distributor: item)),
                              DataCell(
                                IconButton(
                                  tooltip: 'عرض التفاصيل',
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: () => context.goNamed(
                                    'distributor-detail',
                                    pathParameters: {'id': '${item.id}'},
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _DistributorCard extends StatelessWidget {
  const _DistributorCard({required this.distributor});

  final Distributor distributor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r14),
        onTap: distributor.id == null
            ? null
            : () => context.goNamed(
                  'distributor-detail',
                  pathParameters: {'id': '${distributor.id}'},
                ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTokens.brandSoft,
                    child: Icon(
                      Icons.people_alt_outlined,
                      size: 17,
                      color: AppTokens.brandInk,
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(child: _NameCell(distributor: distributor)),
                  _Status(distributor: distributor),
                ],
              ),
              const SizedBox(height: AppTokens.s8),
              // Permissions + debt/limit as one row of pills (the debt used
              // to be a full-width box of its own).
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusPill(
                    text: 'دين ${distributor.debtBalance.toStringAsFixed(2)}'
                        ' · حد ${formatWithCurrency(distributor.creditLimit, '')}',
                    tone: distributor.debtBalance > 0
                        ? PillTone.amber
                        : PillTone.neutral,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  for (final permission in distributor.permissions.take(3))
                    StatusPill(
                      text: distributorPermissionLabel(permission),
                      tone: PillTone.blue,
                    ),
                  if (distributor.permissions.isEmpty)
                    const StatusPill(
                      text: 'لا توجد صلاحيات',
                      tone: PillTone.neutral,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({required this.distributor});

  final Distributor distributor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          distributor.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '@${distributor.name}',
          style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.distributor});

  final Distributor distributor;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      text: distributor.isActive
          ? 'مفعّل'
          : distributorStatusLabel(distributor.status),
      tone: distributorStatusTone(distributor),
      dot: true,
    );
  }
}

/// Active = green, disabled = red, anything else (suspended, pending) = amber.
PillTone distributorStatusTone(Distributor distributor) {
  if (distributor.isActive) return PillTone.green;
  return switch (distributor.status.trim().toLowerCase()) {
    'disabled' || 'inactive' => PillTone.red,
    _ => PillTone.amber,
  };
}

String distributorStatusLabel(String value) {
  final v = value.trim().toLowerCase();
  return switch (v) {
    'active' => 'مفعّل',
    'disabled' || 'inactive' => 'معطّل',
    'suspended' => 'موقوف',
    'pending' => 'بانتظار المراجعة',
    '' => 'غير محدد',
    _ => 'حالة غير معروفة',
  };
}

String distributorPermissionLabel(String value) {
  final v = value.trim().toLowerCase();
  return switch (v) {
    'cards.read' => 'عرض الكروت',
    'cards.sell' => 'بيع الكروت',
    'cards.view' => 'عرض الكروت',
    'cards.create' => 'إنشاء كروت',
    'wallet.credit' => 'تسجيل تحصيل',
    'wallet.debit' => 'تسجيل دين',
    'finance.view' => 'عرض المالية',
    '' => 'غير محددة',
    _ => 'صلاحية غير معروفة',
  };
}
