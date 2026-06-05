import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/hub_kpi.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/card_users_providers.dart';
import '../data/card_users_repository.dart';
import '../domain/card_users_model.dart';

class CardUser360Screen extends ConsumerWidget {
  const CardUser360Screen({super.key, required this.cardUserId});

  final int cardUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(cardUser360Provider(cardUserId));
    final packagesAsync = ref.watch(cardMarketplacePackagesProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => HubErrorState(
        title: 'تعذر جلب ملف مستخدم الكروت',
        subtitle: visibleErrorMessage(error),
        onRetry: () => ref.invalidate(cardUser360Provider(cardUserId)),
      ),
      data: (profile) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: profile.cardUser.title,
            subtitle: 'ملف كروت 360',
            leading: IconButton(
              onPressed: () => context.goNamed('card-users'),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(cardUser360Provider(cardUserId));
                  ref.invalidate(cardUsersPageProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث'),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRechargeDialog(context, ref, cardUserId),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('شحن المحفظة'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showPasswordDialog(context, ref, cardUserId),
                icon: const Icon(Icons.lock_reset_outlined),
                label: const Text('تغيير كلمة المرور'),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          _Kpis(profile: profile),
          const SizedBox(height: AppTokens.s16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 980;
              final cards = _CardsPanel(cards: profile.cards);
              final purchases = _PurchasesPanel(purchases: profile.purchases);
              final packages = packagesAsync.when(
                loading: () => const AppCard(
                  title: 'شراء كرت من السوق',
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => HubErrorState(
                  title: 'تعذر جلب باقات السوق',
                  subtitle: visibleErrorMessage(error),
                  onRetry: () =>
                      ref.invalidate(cardMarketplacePackagesProvider),
                ),
                data: (packages) => _PurchasePanel(
                  packages: packages,
                  cardUserId: cardUserId,
                ),
              );
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _IdentityPanel(profile: profile),
                    const SizedBox(height: AppTokens.s16),
                    packages,
                    const SizedBox(height: AppTokens.s16),
                    cards,
                    const SizedBox(height: AppTokens.s16),
                    purchases,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 360,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _IdentityPanel(profile: profile),
                        const SizedBox(height: AppTokens.s16),
                        packages,
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTokens.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        cards,
                        const SizedBox(height: AppTokens.s16),
                        purchases,
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

class _Kpis extends StatelessWidget {
  const _Kpis({required this.profile});

  final CardUser360 profile;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTokens.s12,
      runSpacing: AppTokens.s12,
      children: [
        HubKpi(
          label: 'رصيد المحفظة',
          value: '${profile.wallet.balance} ${profile.wallet.currency}',
          icon: Icons.account_balance_wallet_outlined,
          variant: KpiVariant.brand,
        ),
        HubKpi(
          label: 'الكروت',
          value: '${profile.cards.length}',
          icon: Icons.credit_card_outlined,
          variant: KpiVariant.green,
        ),
        HubKpi(
          label: 'المشتريات',
          value: '${profile.purchases.length}',
          icon: Icons.shopping_bag_outlined,
          variant: KpiVariant.blue,
        ),
        HubKpi(
          label: 'الجلسات',
          value: '${profile.usage.sessionsCount}',
          icon: Icons.online_prediction,
          variant: KpiVariant.amber,
        ),
      ],
    );
  }
}

class _IdentityPanel extends StatelessWidget {
  const _IdentityPanel({required this.profile});

  final CardUser360 profile;

  @override
  Widget build(BuildContext context) {
    final user = profile.cardUser;
    return AppCard(
      title: 'بيانات المستخدم',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTokens.brandSoft,
                foregroundColor: AppTokens.brandInk,
                child: Text(user.title.isEmpty ? '?' : user.title[0]),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      user.mobile.isEmpty ? 'لا يوجد جوال' : user.mobile,
                      style: const TextStyle(color: AppTokens.textMuted),
                    ),
                  ],
                ),
              ),
              StatusPill(
                text: user.statusLabel,
                tone: user.isActive ? PillTone.green : PillTone.orange,
              ),
            ],
          ),
          const Divider(height: AppTokens.s24),
          _Line(
            label: 'البريد',
            value: user.email.isEmpty ? 'غير مدخل' : user.email,
          ),
          _Line(
            label: 'كلمة مرور البوابة',
            value: user.hasPortalPassword ? 'مضبوطة' : 'غير مضبوطة',
          ),
          _Line(
            label: 'الإنفاق',
            value: '${user.spent.toStringAsFixed(2)} ${user.walletCurrency}',
          ),
          _Line(label: 'الاستخدام', value: _usageLabel(profile.usage)),
        ],
      ),
    );
  }
}

class _PurchasePanel extends ConsumerStatefulWidget {
  const _PurchasePanel({
    required this.packages,
    required this.cardUserId,
  });

  final List<MarketplacePackage> packages;
  final int cardUserId;

  @override
  ConsumerState<_PurchasePanel> createState() => _PurchasePanelState();
}

class _PurchasePanelState extends ConsumerState<_PurchasePanel> {
  int? _selectedId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'شراء كرت من السوق',
      child: widget.packages.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'لا توجد باقات مفعلة',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedId,
                  decoration: const InputDecoration(labelText: 'الباقة'),
                  items: [
                    for (final package in widget.packages)
                      DropdownMenuItem(
                        value: package.id,
                        child: Text(
                          '${package.title} · ${package.price.toStringAsFixed(2)} ${package.currency}',
                        ),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _selectedId = value),
                ),
                const SizedBox(height: AppTokens.s12),
                ElevatedButton.icon(
                  onPressed: _busy || _selectedId == null ? null : _purchase,
                  icon: const Icon(Icons.shopping_cart_checkout_outlined),
                  label: const Text('تنفيذ الشراء'),
                ),
              ],
            ),
    );
  }

  Future<void> _purchase() async {
    final packageId = _selectedId;
    if (packageId == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(cardUsersRepositoryProvider).purchase(
            widget.cardUserId,
            packageId: packageId,
          );
      ref.invalidate(cardUser360Provider(widget.cardUserId));
      ref.invalidate(cardUsersPageProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم شراء الكرت')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _CardsPanel extends StatelessWidget {
  const _CardsPanel({required this.cards});

  final List<CardUserOwnedCard> cards;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'الكروت المملوكة',
      child: cards.isEmpty
          ? const EmptyState(
              icon: Icons.credit_card_off_outlined,
              title: 'لا توجد كروت مملوكة بعد',
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('الكرت')),
                  DataColumn(label: Text('كلمة المرور')),
                  DataColumn(label: Text('الحالة')),
                  DataColumn(label: Text('أول استخدام')),
                ],
                rows: [
                  for (final card in cards)
                    DataRow(
                      cells: [
                        DataCell(Text(card.username)),
                        DataCell(_CopyValue(value: card.password)),
                        DataCell(
                          StatusPill(
                            text: card.statusLabel,
                            tone: card.revoked
                                ? PillTone.red
                                : card.used
                                    ? PillTone.orange
                                    : PillTone.green,
                          ),
                        ),
                        DataCell(Text(_dateLabel(card.firstUsedAt))),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}

class _PurchasesPanel extends StatelessWidget {
  const _PurchasesPanel({required this.purchases});

  final List<CardUserPurchase> purchases;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'المشتريات',
      child: purchases.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'لا توجد عمليات شراء',
            )
          : Column(
              children: [
                for (final purchase in purchases.take(12))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text('${purchase.amount} ${purchase.currency}'),
                    subtitle: Text(_dateLabel(purchase.createdAt)),
                    trailing: StatusPill(
                      text: purchase.statusLabel,
                      tone: purchase.status == 'completed'
                          ? PillTone.green
                          : PillTone.orange,
                    ),
                  ),
              ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppTokens.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyValue extends StatelessWidget {
  const _CopyValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const Text('غير متاحة');
    return TextButton.icon(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم النسخ')),
        );
      },
      icon: const Icon(Icons.copy, size: 16),
      label: Text(value),
    );
  }
}

Future<void> _showRechargeDialog(
  BuildContext context,
  WidgetRef ref,
  int cardUserId,
) async {
  final amount = TextEditingController();
  var busy = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        Future<void> submit() async {
          if ((num.tryParse(amount.text.trim()) ?? 0) <= 0) return;
          setState(() => busy = true);
          try {
            await ref.read(cardUsersRepositoryProvider).recharge(
                  cardUserId,
                  amount: amount.text.trim(),
                );
            ref.invalidate(cardUser360Provider(cardUserId));
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
          title: const Text('شحن محفظة مستخدم الكروت'),
          content: TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(labelText: 'المبلغ'),
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

Future<void> _showPasswordDialog(
  BuildContext context,
  WidgetRef ref,
  int cardUserId,
) async {
  final password = TextEditingController();
  var busy = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        Future<void> submit() async {
          if (password.text.length < 4) return;
          setState(() => busy = true);
          try {
            await ref.read(cardUsersRepositoryProvider).updatePassword(
                  cardUserId,
                  password: password.text,
                );
            ref.invalidate(cardUser360Provider(cardUserId));
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
          title: const Text('تغيير كلمة مرور البوابة'),
          content: TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
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

String _dateLabel(DateTime? date) {
  if (date == null) return 'غير مسجل';
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _usageLabel(CardUserUsage usage) {
  final gb = (usage.bytesIn + usage.bytesOut) / (1024 * 1024 * 1024);
  final hours = usage.totalSeconds / 3600;
  return '${hours.toStringAsFixed(1)} ساعة · ${gb.toStringAsFixed(2)} GB';
}
