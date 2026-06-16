import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../features/admin_control/application/admin_control_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/currency_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/hub_kpi.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/card_users_providers.dart';
import '../data/card_users_repository.dart';
import '../domain/card_users_model.dart';

class CardUsersScreen extends ConsumerWidget {
  const CardUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(cardUsersPageProvider);
    final packagesAsync = ref.watch(cardMarketplacePackagesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'مستخدمو الكروت والسوق الإلكتروني',
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(cardUsersPageProvider);
                ref.invalidate(cardMarketplacePackagesProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
            OutlinedButton.icon(
              onPressed: () => _showCreatePackageDialog(context, ref),
              icon: const Icon(Icons.sell_outlined),
              label: const Text('باقة جديدة'),
            ),
            ElevatedButton.icon(
              onPressed: () => _showCreateUserDialog(context, ref),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('مستخدم جديد'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => HubErrorState(
            title: 'تعذر جلب مستخدمي الكروت',
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(cardUsersPageProvider),
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return EmptyState(
                icon: Icons.people_outline,
                title: 'لا يوجد مستخدمو كروت بعد',
                subtitle: 'أنشئ مستخدمًا ثم اشحن محفظته أو اربطه بسوق الكروت.',
                action: ElevatedButton.icon(
                  onPressed: () => _showCreateUserDialog(context, ref),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('إضافة مستخدم'),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Summary(summary: page.summary),
                const SizedBox(height: AppTokens.s16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 980;
                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final user in page.items) ...[
                            _UserCard(user: user),
                            const SizedBox(height: AppTokens.s12),
                          ],
                          const SizedBox(height: AppTokens.s8),
                          packagesAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (error, stackTrace) =>
                                const SizedBox.shrink(),
                            data: (packages) => _PackagesPanel(
                              packages: packages,
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: AppCard(
                            padding: EdgeInsets.zero,
                            child: _UsersTable(users: page.items),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s16),
                        Expanded(
                          flex: 2,
                          child: packagesAsync.when(
                            loading: () => const AppCard(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, _) => HubErrorState(
                              title: 'تعذر جلب باقات السوق',
                              subtitle: visibleErrorMessage(error),
                              onRetry: () => ref.invalidate(
                                cardMarketplacePackagesProvider,
                              ),
                            ),
                            data: (packages) => _PackagesPanel(
                              packages: packages,
                            ),
                          ),
                        ),
                      ],
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
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final CardUsersSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTokens.s12,
      runSpacing: AppTokens.s12,
      children: [
        HubKpi(
          label: 'المستخدمون',
          value: '${summary.users}',
          icon: Icons.people_alt_outlined,
          variant: KpiVariant.brand,
        ),
        HubKpi(
          label: 'النشطون',
          value: '${summary.active}',
          icon: Icons.verified_user_outlined,
          variant: KpiVariant.green,
        ),
        HubKpi(
          label: 'الكروت المملوكة',
          value: '${summary.cards}',
          icon: Icons.credit_card_outlined,
          variant: KpiVariant.blue,
        ),
        HubKpi(
          label: 'رصيد المحافظ',
          value: '${summary.balance.toStringAsFixed(2)} ${summary.currency}',
          icon: Icons.account_balance_wallet_outlined,
          variant: KpiVariant.amber,
        ),
      ],
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.users});

  final List<CardUser> users;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('المستخدم')),
          DataColumn(label: Text('الجوال')),
          DataColumn(label: Text('الرصيد')),
          DataColumn(label: Text('الكروت')),
          DataColumn(label: Text('الحالة')),
          DataColumn(label: Text('')),
        ],
        rows: [
          for (final user in users)
            DataRow(
              cells: [
                DataCell(_UserName(user: user)),
                DataCell(Text(user.mobile.isEmpty ? 'غير مدخل' : user.mobile)),
                DataCell(
                  Text(
                    '${user.balance.toStringAsFixed(2)} ${user.walletCurrency}',
                  ),
                ),
                DataCell(Text('${user.ownedCardsCount}')),
                DataCell(_Status(user: user)),
                DataCell(
                  IconButton(
                    tooltip: 'ملف 360',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => context.goNamed(
                      'card-user-360',
                      pathParameters: {'id': '${user.id}'},
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final CardUser user;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r10),
        onTap: () => context.goNamed(
          'card-user-360',
          pathParameters: {'id': '${user.id}'},
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _UserName(user: user)),
                  _Status(user: user),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: [
                  _MiniMetric(
                    icon: Icons.account_balance_wallet_outlined,
                    label:
                        '${user.balance.toStringAsFixed(2)} ${user.walletCurrency}',
                  ),
                  _MiniMetric(
                    icon: Icons.credit_card_outlined,
                    label: '${user.ownedCardsCount} كرت',
                  ),
                  _MiniMetric(
                    icon: Icons.shopping_bag_outlined,
                    label: '${user.purchaseCount} عملية',
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

class _UserName extends StatelessWidget {
  const _UserName({required this.user});

  final CardUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          user.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          user.email.isNotEmpty ? user.email : 'رقم ${user.id}',
          style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.user});

  final CardUser user;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      text: user.statusLabel,
      tone: user.isActive ? PillTone.green : PillTone.orange,
    );
  }
}

class _PackagesPanel extends StatelessWidget {
  const _PackagesPanel({required this.packages});

  final List<MarketplacePackage> packages;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'باقات السوق الإلكتروني',
      child: packages.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'لا توجد باقات سوق مفعلة',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final package in packages.take(8)) ...[
                  _PackageTile(package: package),
                  const Divider(height: AppTokens.s20),
                ],
              ],
            ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({required this.package});

  final MarketplacePackage package;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTokens.brandSoft,
            borderRadius: BorderRadius.circular(AppTokens.r10),
          ),
          child: const Icon(Icons.local_activity_outlined),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                package.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${package.durationLabel} · ${package.speedLabel}',
                style: const TextStyle(
                  color: AppTokens.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${package.price.toStringAsFixed(2)} ${package.currency}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTokens.textSecondary),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

Future<void> _showCreatePackageDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final name = TextEditingController();
  final planId = TextEditingController();
  final price = TextEditingController();
  final duration = TextEditingController();
  final down = TextEditingController();
  final up = TextEditingController();
  final currency = ref.read(tenantCurrencyProvider);
  var busy = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        Future<void> submit() async {
          if (name.text.trim().isEmpty) return;
          setState(() => busy = true);
          try {
            await ref.read(cardUsersRepositoryProvider).createPackage(
                  name: name.text.trim(),
                  planId: int.tryParse(planId.text.trim()),
                  price: num.tryParse(price.text.trim().replaceAll(',', '.')) ?? 0,
                  currency: currency,
                  durationMinutes: int.tryParse(duration.text.trim()) ?? 0,
                  speedDownKbps: int.tryParse(down.text.trim()) ?? 0,
                  speedUpKbps: int.tryParse(up.text.trim()) ?? 0,
                );
            ref.invalidate(cardMarketplacePackagesProvider);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          } catch (error) {
            if (!dialogContext.mounted) return;
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(content: Text(visibleErrorMessage(error))),
            );
          } finally {
            if (dialogContext.mounted) setState(() => busy = false);
          }
        }

        return AlertDialog(
          title: const Text('باقة سوق إلكتروني جديدة'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'اسم الباقة'),
                ),
                const SizedBox(height: AppTokens.s8),
                TextField(
                  controller: planId,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'رقم الباقة المرتبطة (اختياري)',
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'السعر'),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(child: CurrencyField(currency: currency)),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                TextField(
                  controller: duration,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المدة (دقائق)',
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: down,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'تنزيل (kbps)',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: TextField(
                        controller: up,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'رفع (kbps)',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: busy ? null : submit,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _showCreateUserDialog(BuildContext context, WidgetRef ref) async {
  final name = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  var busy = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        Future<void> submit() async {
          if (name.text.trim().isEmpty) return;
          setState(() => busy = true);
          try {
            await ref.read(cardUsersRepositoryProvider).createUser(
                  displayName: name.text.trim(),
                  mobile: mobile.text.trim(),
                  email: email.text.trim(),
                  password: password.text,
                );
            ref.invalidate(cardUsersPageProvider);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          } catch (error) {
            if (!dialogContext.mounted) return;
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(content: Text(visibleErrorMessage(error))),
            );
          } finally {
            if (dialogContext.mounted) setState(() => busy = false);
          }
        }

        return AlertDialog(
          title: const Text('إضافة مستخدم كروت'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                ),
                const SizedBox(height: AppTokens.s8),
                TextField(
                  controller: mobile,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'الجوال'),
                ),
                const SizedBox(height: AppTokens.s8),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'البريد'),
                ),
                const SizedBox(height: AppTokens.s8),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة مرور البوابة',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: busy ? null : submit,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ'),
            ),
          ],
        );
      },
    ),
  );
}
