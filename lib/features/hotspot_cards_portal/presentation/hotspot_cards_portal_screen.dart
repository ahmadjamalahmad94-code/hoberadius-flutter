import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoint_storage.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/hotspot_cards_portal_controller.dart';
import '../domain/hotspot_cards_portal_model.dart';

class HotspotCardsPortalScreen extends ConsumerStatefulWidget {
  const HotspotCardsPortalScreen({super.key});

  @override
  ConsumerState<HotspotCardsPortalScreen> createState() =>
      _HotspotCardsPortalScreenState();
}

class _HotspotCardsPortalScreenState
    extends ConsumerState<HotspotCardsPortalScreen> {
  final _server = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _tenant = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();
  String _scheme = 'https';
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loadServer();
  }

  Future<void> _loadServer() async {
    final saved = await ref.read(apiEndpointStorageProvider).readBaseUrl();
    final uri = Uri.tryParse(saved);
    if (!mounted || uri == null || uri.host.isEmpty) return;
    setState(() {
      _scheme = uri.scheme == 'http' ? 'http' : 'https';
      _server.text = uri.authority;
    });
  }

  @override
  void dispose() {
    _server.dispose();
    _username.dispose();
    _password.dispose();
    _tenant.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hotspotCardsPortalControllerProvider);
    final p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppTokens.s20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: state.isAuthenticated
                  ? _PortalDashboard(
                      state: state,
                      onRefresh: () => ref
                          .read(hotspotCardsPortalControllerProvider.notifier)
                          .refresh(),
                      onLogout: () => ref
                          .read(hotspotCardsPortalControllerProvider.notifier)
                          .logout(),
                      onPurchase: (item) => ref
                          .read(hotspotCardsPortalControllerProvider.notifier)
                          .purchase(item),
                      onSendSms: (card, phone) => ref
                          .read(hotspotCardsPortalControllerProvider.notifier)
                          .sendSms(card, phone),
                      onClearMessages: () => ref
                          .read(hotspotCardsPortalControllerProvider.notifier)
                          .clearMessages(),
                    )
                  : _LoginPanel(
                      formKey: _formKey,
                      server: _server,
                      username: _username,
                      password: _password,
                      tenant: _tenant,
                      scheme: _scheme,
                      obscure: _obscure,
                      loading: state.loading,
                      error: state.error,
                      onSchemeChanged: (value) {
                        if (value != null) setState(() => _scheme = value);
                      },
                      onTogglePassword: () =>
                          setState(() => _obscure = !_obscure),
                      onSubmit: _submit,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final tenantId = int.tryParse(_tenant.text.trim()) ?? 1;
    await ref.read(hotspotCardsPortalControllerProvider.notifier).login(
          scheme: _scheme,
          host: _server.text,
          username: _username.text.trim(),
          password: _password.text,
          tenantId: tenantId < 1 ? 1 : tenantId,
        );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.formKey,
    required this.server,
    required this.username,
    required this.password,
    required this.tenant,
    required this.scheme,
    required this.obscure,
    required this.loading,
    required this.error,
    required this.onSchemeChanged,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController server;
  final TextEditingController username;
  final TextEditingController password;
  final TextEditingController tenant;
  final String scheme;
  final bool obscure;
  final bool loading;
  final String error;
  final ValueChanged<String?> onSchemeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTokens.s24),
            decoration: BoxDecoration(
              gradient: p.brandGradient,
              borderRadius: BorderRadius.circular(AppTokens.r20),
              boxShadow: p.shCard,
            ),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppTokens.r18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                Text(
                  'بوابة شراء الكروت الإلكترونية',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  'سجل الدخول بحساب مستخدم الكروت لعرض الباقات، الشراء من رصيد المحفظة، ومراجعة الكروت التي تم إصدارها.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          AppCard(
            title: 'بيانات الدخول',
            icon: Icons.login_outlined,
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 440;
                      final schemeField = DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: scheme,
                        decoration: const InputDecoration(
                          labelText: 'نوع الاتصال',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'https',
                            child: Text('HTTPS'),
                          ),
                          DropdownMenuItem(value: 'http', child: Text('HTTP')),
                        ],
                        onChanged: onSchemeChanged,
                      );
                      final serverField = TextFormField(
                        controller: server,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'عنوان الخادم أو اسم النطاق',
                          hintText: 'hoberadius.com أو 127.0.0.1:5055',
                          helperText: 'لا تضف /api في نهاية العنوان.',
                          prefixIcon: Icon(Icons.dns_outlined),
                        ),
                        validator: (value) {
                          try {
                            normalizeApiBaseUrl(
                              scheme: scheme,
                              host: value ?? '',
                            );
                            return null;
                          } on FormatException {
                            return 'اكتب عنوان خادم صحيح بدون /api';
                          }
                        },
                      );
                      if (compact) {
                        return Column(
                          children: [
                            schemeField,
                            const SizedBox(height: AppTokens.s12),
                            serverField,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 132, child: schemeField),
                          const SizedBox(width: AppTokens.s12),
                          Expanded(child: serverField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppTokens.s12),
                  TextFormField(
                    controller: tenant,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'رقم المستأجر',
                      helperText: 'اتركه 1 إذا لم يخبرك المدير برقم آخر.',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse((value ?? '').trim());
                      if (parsed == null || parsed < 1) {
                        return 'رقم المستأجر يجب أن يكون 1 أو أكثر';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTokens.s12),
                  TextFormField(
                    controller: username,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'اسم المستخدم مطلوب'
                            : null,
                  ),
                  const SizedBox(height: AppTokens.s12),
                  TextFormField(
                    controller: password,
                    obscureText: obscure,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: onTogglePassword,
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'كلمة المرور مطلوبة'
                        : null,
                    onFieldSubmitted: (_) => onSubmit(),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.s12),
                    _MessageBanner(message: error, danger: true),
                  ],
                  const SizedBox(height: AppTokens.s16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : onSubmit,
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.login),
                      label: const Text('دخول بوابة الكروت'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalDashboard extends StatelessWidget {
  const _PortalDashboard({
    required this.state,
    required this.onRefresh,
    required this.onLogout,
    required this.onPurchase,
    required this.onSendSms,
    required this.onClearMessages,
  });

  final HotspotCardsPortalState state;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final ValueChanged<HotspotCatalogItem> onPurchase;
  final void Function(HotspotOwnedCard card, String phone) onSendSms;
  final VoidCallback onClearMessages;

  @override
  Widget build(BuildContext context) {
    final user = state.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'بوابة شراء الكروت الإلكترونية',
          subtitle:
              'الشراء يتم من رصيد المحفظة الحقيقي في الريدياس، والكرت الصادر يظهر هنا مباشرة بدون بيانات وهمية.',
          leading: const _HeaderIcon(),
          actions: [
            OutlinedButton.icon(
              onPressed: state.refreshing ? null : onRefresh,
              icon: state.refreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('خروج'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        if (state.error.isNotEmpty) ...[
          _MessageBanner(
            message: state.error,
            danger: true,
            onClose: onClearMessages,
          ),
          const SizedBox(height: AppTokens.s12),
        ],
        if (state.notice.isNotEmpty) ...[
          _MessageBanner(message: state.notice, onClose: onClearMessages),
          const SizedBox(height: AppTokens.s12),
        ],
        if (state.lastPurchase != null) ...[
          _LastPurchaseCard(result: state.lastPurchase!),
          const SizedBox(height: AppTokens.s12),
        ],
        _UserSummary(user: user, capabilities: state.capabilities),
        const SizedBox(height: AppTokens.s16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 940;
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CatalogSection(
                    items: state.catalog,
                    canPurchase: state.capabilities.purchase,
                    busyCatalogItemId: state.busyCatalogItemId,
                    onPurchase: onPurchase,
                  ),
                  const SizedBox(height: AppTokens.s16),
                  _MyCardsSection(
                    cards: state.cards,
                    smsEnabled: state.capabilities.sms,
                    busyPurchaseId: state.busyPurchaseId,
                    onSendSms: onSendSms,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _CatalogSection(
                    items: state.catalog,
                    canPurchase: state.capabilities.purchase,
                    busyCatalogItemId: state.busyCatalogItemId,
                    onPurchase: onPurchase,
                  ),
                ),
                const SizedBox(width: AppTokens.s16),
                Expanded(
                  flex: 6,
                  child: _MyCardsSection(
                    cards: state.cards,
                    smsEnabled: state.capabilities.sms,
                    busyPurchaseId: state.busyPurchaseId,
                    onSendSms: onSendSms,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: p.brandSoft,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: p.brandLine),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.confirmation_number_outlined, color: p.brandInk),
    );
  }
}

class _UserSummary extends StatelessWidget {
  const _UserSummary({
    required this.user,
    required this.capabilities,
  });

  final HotspotPortalUser? user;
  final HotspotPortalCapabilities capabilities;

  @override
  Widget build(BuildContext context) {
    final u = user;
    return AppCard(
      title: 'ملخص الحساب والمحفظة',
      icon: Icons.account_balance_wallet_outlined,
      child: Wrap(
        spacing: AppTokens.s12,
        runSpacing: AppTokens.s12,
        children: [
          _MetricTile(
            label: 'الحساب',
            value: u?.title.isNotEmpty == true ? u!.title : 'مستخدم الكروت',
            icon: Icons.person_outline,
          ),
          _MetricTile(
            label: 'رصيد المحفظة',
            value: u?.walletLabel.isNotEmpty == true ? u!.walletLabel : '0',
            icon: Icons.account_balance_wallet_outlined,
          ),
          _MetricTile(
            label: 'الشراء',
            value: capabilities.purchase ? 'مسموح' : 'غير مسموح',
            icon: Icons.shopping_cart_outlined,
          ),
          _MetricTile(
            label: 'إرسال الرسائل',
            value: capabilities.sms ? 'مفعل' : 'غير مفعل',
            icon: Icons.sms_outlined,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 190),
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: p.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: p.brandInk, size: 20),
          const SizedBox(width: AppTokens.s12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(color: p.textMuted),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge.copyWith(
                    color: p.textPrimary,
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

class _CatalogSection extends StatelessWidget {
  const _CatalogSection({
    required this.items,
    required this.canPurchase,
    required this.busyCatalogItemId,
    required this.onPurchase,
  });

  final List<HotspotCatalogItem> items;
  final bool canPurchase;
  final String busyCatalogItemId;
  final ValueChanged<HotspotCatalogItem> onPurchase;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'الباقات المتاحة للشراء',
      icon: Icons.storefront_outlined,
      padding: const EdgeInsets.all(AppTokens.s12),
      child: items.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'لا توجد باقات متاحة الآن',
              subtitle:
                  'عند تفعيل باقات سوق الكروت من الإدارة ستظهر هنا للشراء من رصيد المحفظة.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items) ...[
                  _CatalogCard(
                    item: item,
                    canPurchase: canPurchase && item.available,
                    busy: busyCatalogItemId == item.id,
                    onPurchase: () => onPurchase(item),
                  ),
                  if (item != items.last) const SizedBox(height: AppTokens.s12),
                ],
              ],
            ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.item,
    required this.canPurchase,
    required this.busy,
    required this.onPurchase,
  });

  final HotspotCatalogItem item;
  final bool canPurchase;
  final bool busy;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: p.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.titleMedium.copyWith(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: AppTokens.s4),
                      Text(
                        item.description,
                        style: AppTypography.bodySmall
                            .copyWith(color: p.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              StatusPill(
                text: item.available ? 'متاحة' : 'متوقفة',
                tone: item.available ? PillTone.green : PillTone.neutral,
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _InfoChip(icon: Icons.payments_outlined, text: item.priceLabel),
              if (item.profileName.isNotEmpty)
                _InfoChip(icon: Icons.speed_outlined, text: item.profileName),
              if (item.durationLabel.isNotEmpty)
                _InfoChip(
                  icon: Icons.schedule_outlined,
                  text: item.durationLabel,
                ),
              if (item.quotaLabel.isNotEmpty)
                _InfoChip(
                  icon: Icons.data_usage_outlined,
                  text: item.quotaLabel,
                ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: canPurchase && !busy ? onPurchase : null,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.shopping_cart_checkout_outlined),
              label: Text(busy ? 'جارٍ الشراء' : 'شراء الكرت'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: p.textMuted),
          const SizedBox(width: AppTokens.s8),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: p.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyCardsSection extends StatelessWidget {
  const _MyCardsSection({
    required this.cards,
    required this.smsEnabled,
    required this.busyPurchaseId,
    required this.onSendSms,
  });

  final List<HotspotOwnedCard> cards;
  final bool smsEnabled;
  final String busyPurchaseId;
  final void Function(HotspotOwnedCard card, String phone) onSendSms;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'الكروت التي تم شراؤها',
      icon: Icons.confirmation_number_outlined,
      padding: const EdgeInsets.all(AppTokens.s12),
      child: cards.isEmpty
          ? const EmptyState(
              icon: Icons.credit_card_off_outlined,
              title: 'لا توجد كروت مشتراة بعد',
              subtitle:
                  'بعد شراء أول كرت ستظهر بيانات الدخول هنا مع اسم المستخدم وكلمة المرور.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!smsEnabled) ...[
                  const _SmsDisabledNotice(),
                  const SizedBox(height: AppTokens.s12),
                ],
                for (final item in cards) ...[
                  _OwnedCardTile(
                    item: item,
                    smsEnabled: smsEnabled,
                    busy: busyPurchaseId == item.purchaseId,
                    onSendSms: onSendSms,
                  ),
                  if (item != cards.last) const SizedBox(height: AppTokens.s12),
                ],
              ],
            ),
    );
  }
}

class _SmsDisabledNotice extends StatelessWidget {
  const _SmsDisabledNotice();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: p.warningBg,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: p.warningStrong.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.sms_failed_outlined, color: p.warningFg),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              'إرسال الرسائل غير مفعّل على الخادم الحالي. يمكن نسخ بيانات الكرت يدويًا.',
              style: AppTypography.bodySmall.copyWith(
                color: p.warningFg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnedCardTile extends StatelessWidget {
  const _OwnedCardTile({
    required this.item,
    required this.smsEnabled,
    required this.busy,
    required this.onSendSms,
  });

  final HotspotOwnedCard item;
  final bool smsEnabled;
  final bool busy;
  final void Function(HotspotOwnedCard card, String phone) onSendSms;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final card = item.card;
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: p.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.packageName.isNotEmpty
                      ? item.packageName
                      : 'كرت إلكتروني',
                  style: AppTypography.titleMedium.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(
                text: card.statusLabel,
                tone: switch (card.statusLabel) {
                  'جاهزة' => PillTone.green,
                  'مستخدمة' => PillTone.blue,
                  'منتهية' => PillTone.amber,
                  _ => PillTone.neutral,
                },
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _InfoChip(icon: Icons.payments_outlined, text: item.amountLabel),
              if (card.profileName.isNotEmpty)
                _InfoChip(icon: Icons.speed_outlined, text: card.profileName),
              if (card.durationLabel.isNotEmpty)
                _InfoChip(
                  icon: Icons.schedule_outlined,
                  text: card.durationLabel,
                ),
              if (card.quotaLabel.isNotEmpty)
                _InfoChip(
                  icon: Icons.data_usage_outlined,
                  text: card.quotaLabel,
                ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final fields = [
                _CredentialBox(label: 'اسم الدخول', value: card.username),
                _CredentialBox(label: 'كلمة المرور', value: card.password),
              ];
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    fields[0],
                    const SizedBox(height: AppTokens.s8),
                    fields[1],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: fields[0]),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(child: fields[1]),
                ],
              );
            },
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _copyCard(context, item),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('نسخ البيانات'),
              ),
              OutlinedButton.icon(
                onPressed: smsEnabled && !busy
                    ? () => _askPhoneAndSend(context, item)
                    : null,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sms_outlined),
                label: Text(smsEnabled ? 'إرسال رسالة' : 'الرسائل غير مفعلة'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyCard(BuildContext context, HotspotOwnedCard item) async {
    await Clipboard.setData(
      ClipboardData(
        text: 'اسم الدخول: ${item.card.username}\n'
            'كلمة المرور: ${item.card.password}',
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ بيانات الكرت.')),
    );
  }

  Future<void> _askPhoneAndSend(
    BuildContext context,
    HotspotOwnedCard item,
  ) async {
    final phone = await showDialog<String>(
      context: context,
      builder: (context) => _SmsPhoneDialog(),
    );
    if (phone == null || phone.trim().isEmpty) return;
    onSendSms(item, phone);
  }
}

class _CredentialBox extends StatelessWidget {
  const _CredentialBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: p.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(color: p.textMuted),
          ),
          const SizedBox(height: 4),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SelectableText(
              value.isEmpty ? '-' : value,
              style: AppTypography.labelLarge.copyWith(
                color: p.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmsPhoneDialog extends StatelessWidget {
  _SmsPhoneDialog();

  final TextEditingController _phone = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إرسال بيانات الكرت'),
      content: TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'رقم الجوال',
          hintText: '0599000000',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _phone.text.trim()),
          child: const Text('إرسال'),
        ),
      ],
    );
  }
}

class _LastPurchaseCard extends StatelessWidget {
  const _LastPurchaseCard({required this.result});

  final HotspotPurchaseResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'آخر كرت تم شراؤه',
      icon: Icons.verified_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CredentialBox(label: 'اسم الدخول', value: result.card.username),
          const SizedBox(height: AppTokens.s8),
          _CredentialBox(label: 'كلمة المرور', value: result.card.password),
          const SizedBox(height: AppTokens.s12),
          Text(
            'الرصيد بعد الشراء: ${result.walletBalanceAfter}',
            style:
                AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    this.danger = false,
    this.onClose,
  });

  final String message;
  final bool danger;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final bg = danger ? p.dangerBg : p.successBg;
    final fg = danger ? p.dangerFg : p.successFg;
    final border = danger ? p.dangerStrong : p.successStrong;
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: border.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            danger ? Icons.error_outline : Icons.check_circle_outline,
            color: fg,
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onClose != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: Icon(Icons.close, color: fg, size: 18),
            ),
        ],
      ),
    );
  }
}
