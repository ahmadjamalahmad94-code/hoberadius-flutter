import 'package:hoberadius_app/core/format/number_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../cards/domain/card_item.dart';
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
    final perms = ref.watch(permissionsProvider);
    // storeuser.edit = recharge / purchase (money); storeuser.password.
    final canMoney = perms.canAction('storeuser.edit');
    final canPassword = perms.canAction('storeuser.password');

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
            inlineActions: true,
            leading: IconButton(
              tooltip: 'رجوع',
              visualDensity: VisualDensity.compact,
              onPressed: () => context.goNamed('card-users'),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              IconButton(
                tooltip: 'تحديث',
                icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
                onPressed: () {
                  ref.invalidate(cardUser360Provider(cardUserId));
                  ref.invalidate(cardUsersPageProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          ActionBar(
            items: [
              if (canMoney)
                ActionItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'شحن المحفظة',
                  primary: true,
                  onPressed: () =>
                      _showRechargeDialog(context, ref, cardUserId),
                ),
              if (canPassword)
                ActionItem(
                  icon: Icons.lock_reset_outlined,
                  label: 'تغيير كلمة المرور',
                  onPressed: () =>
                      _showPasswordDialog(context, ref, cardUserId),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          _Kpis(profile: profile),
          const SizedBox(height: AppTokens.s12),
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
                data: (packages) => canMoney
                    ? _PurchasePanel(packages: packages, cardUserId: cardUserId)
                    : const SizedBox.shrink(),
              );
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _IdentityPanel(profile: profile),
                    const SizedBox(height: AppTokens.s12),
                    packages,
                    const SizedBox(height: AppTokens.s12),
                    cards,
                    const SizedBox(height: AppTokens.s12),
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
                        const SizedBox(height: AppTokens.s12),
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
                        const SizedBox(height: AppTokens.s12),
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
    return LayoutBuilder(
      builder: (context, c) => CountGrid(
        columns: c.maxWidth >= 620 ? 4 : 2,
        items: [
          CountItem.text(
            'رصيد المحفظة',
            '${profile.wallet.balance} ${profile.wallet.currency}',
            tone: PillTone.brand,
          ),
          CountItem('الكروت', profile.cards.length, tone: PillTone.blue),
          CountItem('المشتريات', profile.purchases.length),
          CountItem(
            'الجلسات',
            profile.usage.sessionsCount,
            tone: PillTone.green,
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(AppTokens.s12),
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
          const SizedBox(height: AppTokens.s12),
          InfoGrid(
            columns: 2,
            items: [
              InfoItem(
                icon: Icons.alternate_email,
                label: 'البريد',
                value: user.email.isEmpty ? 'غير مدخل' : user.email,
              ),
              InfoItem(
                icon: Icons.key_outlined,
                label: 'كلمة مرور البوابة',
                value: user.hasPortalPassword ? 'مضبوطة' : 'غير مضبوطة',
              ),
              InfoItem(
                icon: Icons.payments_outlined,
                label: 'الإنفاق',
                value:
                    '${user.spent.toStringAsFixed(2)} ${user.walletCurrency}',
              ),
              InfoItem(
                icon: Icons.data_usage,
                label: 'الاستخدام',
                value: _usageLabel(profile.usage),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchasePanel extends ConsumerStatefulWidget {
  const _PurchasePanel({required this.packages, required this.cardUserId});

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
      padding: const EdgeInsets.all(AppTokens.s12),
      child: widget.packages.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'لا توجد باقات مفعلة',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  isExpanded: true,
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
                ActionBar(
                  items: [
                    ActionItem(
                      icon: Icons.shopping_cart_checkout_outlined,
                      label: 'تنفيذ الشراء',
                      primary: true,
                      onPressed:
                          _busy || _selectedId == null ? null : _purchase,
                    ),
                  ],
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
      await ref
          .read(cardUsersRepositoryProvider)
          .purchase(widget.cardUserId, packageId: packageId);
      ref.invalidate(cardUser360Provider(widget.cardUserId));
      ref.invalidate(cardUsersPageProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم شراء الكرت')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(visibleErrorMessage(error))));
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
      padding:
          cards.isEmpty ? const EdgeInsets.all(AppTokens.s12) : EdgeInsets.zero,
      child: cards.isEmpty
          ? const EmptyState(
              icon: Icons.credit_card_off_outlined,
              title: 'لا توجد كروت مملوكة بعد',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _OwnedCardRow(card: cards[i]),
                ],
              ],
            ),
    );
  }
}

/// One owned card: code + first use on the start side, the password (tap to
/// copy) and a coloured status on the end — replaces a wide DataTable that
/// scrolled sideways on phones.
class _OwnedCardRow extends StatelessWidget {
  const _OwnedCardRow({required this.card});

  final CardUserOwnedCard card;

  @override
  Widget build(BuildContext context) {
    final tone = card.revoked
        ? PillTone.red
        : card.used
            ? PillTone.brand
            : PillTone.blue;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.sidebarBg,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'أول استخدام: ${_dateLabel(card.firstUsedAt)}',
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
          _CopyValue(value: card.password),
          const SizedBox(width: AppTokens.s4),
          StatusPill(text: card.statusLabel, tone: tone),
        ],
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
      padding: const EdgeInsets.all(AppTokens.s12),
      child: purchases.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'لا توجد عمليات شراء',
            )
          : Column(
              children: [
                for (final purchase in purchases.take(12))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppTokens.brandInk,
                    ),
                    title: Text(
                      '${purchase.amount} ${purchase.currency}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
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

class _CopyValue extends StatelessWidget {
  const _CopyValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const Text('غير متاحة');
    // Masked by the server (no reveal permission): «••••», nothing to copy.
    if (isMaskedCardPassword(value)) {
      return const Tooltip(
        message: 'كلمة المرور مخفيّة — لا تملك صلاحية كشفها.',
        child: Text('••••'),
      );
    }
    return TextButton.icon(
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s8),
      ),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم النسخ')));
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
  String? error;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        Future<void> submit() async {
          // «-3» used to be stripped to «3» and credited: the minus is kept
          // and refused here with a message.
          final read = readNumberInput(amount.text);
          final problem = read.error ?? validateMoneyAmount(read.value);
          if (problem != null) {
            setState(() => error = problem);
            return;
          }
          setState(() {
            busy = true;
            error = null;
          });
          try {
            await ref
                .read(cardUsersRepositoryProvider)
                // The normalised value («١٢٫٥» → 12.5), not the raw text.
                .recharge(cardUserId, amount: '${read.value}');
            ref.invalidate(cardUser360Provider(cardUserId));
            ref.invalidate(cardUsersPageProvider);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          } catch (error) {
            if (!dialogContext.mounted) return;
            ScaffoldMessenger.of(
              dialogContext,
            ).showSnackBar(SnackBar(content: Text(visibleErrorMessage(error))));
          } finally {
            if (dialogContext.mounted) setState(() => busy = false);
          }
        }

        return AlertDialog(
          title: const Text('شحن محفظة مستخدم الكروت'),
          content: TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: numberFieldFormatters,
            decoration: InputDecoration(
              labelText: 'المبلغ',
              errorText: error,
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
            await ref
                .read(cardUsersRepositoryProvider)
                .updatePassword(cardUserId, password: password.text);
            ref.invalidate(cardUser360Provider(cardUserId));
            ref.invalidate(cardUsersPageProvider);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          } catch (error) {
            if (!dialogContext.mounted) return;
            ScaffoldMessenger.of(
              dialogContext,
            ).showSnackBar(SnackBar(content: Text(visibleErrorMessage(error))));
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
