import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoint_storage.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/subscriber_portal_controller.dart';
import '../domain/subscriber_portal_model.dart';

class SubscriberPortalScreen extends ConsumerStatefulWidget {
  const SubscriberPortalScreen({super.key});

  @override
  ConsumerState<SubscriberPortalScreen> createState() =>
      _SubscriberPortalScreenState();
}

class _SubscriberPortalScreenState
    extends ConsumerState<SubscriberPortalScreen> {
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
    final state = ref.watch(subscriberPortalControllerProvider);
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
                          .read(subscriberPortalControllerProvider.notifier)
                          .refresh(),
                      onLogout: () => ref
                          .read(subscriberPortalControllerProvider.notifier)
                          .logout(),
                      onSubmitLoan: (minutes, reason) => ref
                          .read(subscriberPortalControllerProvider.notifier)
                          .submitLoan(
                            requestedMinutes: minutes,
                            reason: reason,
                          ),
                      onSubmitRenewal: (reason) => ref
                          .read(subscriberPortalControllerProvider.notifier)
                          .submitRenewal(reason: reason),
                      onClearMessages: () => ref
                          .read(subscriberPortalControllerProvider.notifier)
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
    await ref.read(subscriberPortalControllerProvider.notifier).login(
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
      constraints: const BoxConstraints(maxWidth: 540),
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
                    Icons.person_pin_circle_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                Text(
                  'بوابة المشترك',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  'ادخل بنفس بيانات اشتراكك لعرض الباقة، حالة الخدمة، الاستخدام، الرصيد، الطلبات، والسلف.',
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
                  _ServerFields(
                    server: server,
                    tenant: tenant,
                    scheme: scheme,
                    onSchemeChanged: onSchemeChanged,
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
                      label: const Text('دخول بوابة المشترك'),
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

class _ServerFields extends StatelessWidget {
  const _ServerFields({
    required this.server,
    required this.tenant,
    required this.scheme,
    required this.onSchemeChanged,
  });

  final TextEditingController server;
  final TextEditingController tenant;
  final String scheme;
  final ValueChanged<String?> onSchemeChanged;

  @override
  Widget build(BuildContext context) {
    final schemeField = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: scheme,
      decoration: const InputDecoration(labelText: 'نوع الاتصال'),
      items: const [
        DropdownMenuItem(value: 'https', child: Text('HTTPS')),
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
          normalizeApiBaseUrl(scheme: scheme, host: value ?? '');
          return null;
        } on FormatException {
          return 'اكتب عنوان خادم صحيح بدون /api';
        }
      },
    );
    final tenantField = TextFormField(
      controller: tenant,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
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
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;
        if (compact) {
          return Column(
            children: [
              schemeField,
              const SizedBox(height: AppTokens.s12),
              serverField,
              const SizedBox(height: AppTokens.s12),
              tenantField,
            ],
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 132, child: schemeField),
                const SizedBox(width: AppTokens.s12),
                Expanded(child: serverField),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            tenantField,
          ],
        );
      },
    );
  }
}

class _PortalDashboard extends StatelessWidget {
  const _PortalDashboard({
    required this.state,
    required this.onRefresh,
    required this.onLogout,
    required this.onSubmitLoan,
    required this.onSubmitRenewal,
    required this.onClearMessages,
  });

  final SubscriberPortalState state;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final void Function(int minutes, String reason) onSubmitLoan;
  final ValueChanged<String> onSubmitRenewal;
  final VoidCallback onClearMessages;

  @override
  Widget build(BuildContext context) {
    final dashboard = state.dashboard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'بوابة المشترك',
          subtitle:
              'كل البيانات المعروضة هنا تأتي من الريدياس مباشرة: الاشتراك، الاستخدام، الرصيد، الطلبات، والسلف.',
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
        if (dashboard == null)
          const EmptyState(
            icon: Icons.person_search_outlined,
            title: 'لم تكتمل قراءة ملف المشترك',
            subtitle: 'اضغط تحديث لإعادة قراءة البيانات من الخادم.',
          )
        else ...[
          _SubscriberSummary(dashboard: dashboard),
          const SizedBox(height: AppTokens.s16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 960;
              final left = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _UsageCard(usage: dashboard.usage),
                  const SizedBox(height: AppTokens.s16),
                  _FinanceCard(dashboard: dashboard),
                  const SizedBox(height: AppTokens.s16),
                  _SessionsCard(sessions: dashboard.sessions),
                ],
              );
              final right = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ActionsCard(
                    policy: dashboard.loanPolicy,
                    sendingLoan: state.sendingLoan,
                    sendingRenewal: state.sendingRenewal,
                    onSubmitLoan: onSubmitLoan,
                    onSubmitRenewal: onSubmitRenewal,
                  ),
                  const SizedBox(height: AppTokens.s16),
                  _RequestsCard(requests: state.requests),
                ],
              );
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    left,
                    const SizedBox(height: AppTokens.s16),
                    right,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: left),
                  const SizedBox(width: AppTokens.s16),
                  Expanded(flex: 5, child: right),
                ],
              );
            },
          ),
        ],
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
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: p.brandLine),
      ),
      child: Icon(Icons.person_pin_circle_outlined, color: p.brandInk),
    );
  }
}

class _SubscriberSummary extends StatelessWidget {
  const _SubscriberSummary({required this.dashboard});

  final SubscriberPortalDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final sub = dashboard.subscriber;
    final subscription = dashboard.subscription;
    final tone = subscription.status == 'expired'
        ? PillTone.amber
        : subscription.status == 'disabled'
            ? PillTone.neutral
            : PillTone.green;
    return AppCard(
      title: sub.title,
      icon: Icons.badge_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusPill(text: subscription.statusLabel, tone: tone, dot: true),
              _InfoChip(icon: Icons.person_outline, text: sub.username),
              if (sub.mobile.isNotEmpty)
                _InfoChip(icon: Icons.phone_outlined, text: sub.mobile),
              if (sub.email.isNotEmpty)
                _InfoChip(icon: Icons.email_outlined, text: sub.email),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final cards = [
                _MetricTile(
                  icon: Icons.speed_outlined,
                  label: 'الباقة',
                  value: dashboard.plan.title,
                  helper: dashboard.plan.durationLabel,
                ),
                _MetricTile(
                  icon: Icons.event_available_outlined,
                  label: 'انتهاء الاشتراك',
                  value: subscription.remainingLabel,
                  helper: subscription.expireAt == null
                      ? 'لا يوجد تاريخ انتهاء'
                      : _dateLabel(subscription.expireAt!),
                ),
                _MetricTile(
                  icon: Icons.payments_outlined,
                  label: 'سعر الباقة',
                  value: dashboard.plan.priceLabel,
                  helper: sub.serviceType.isEmpty ? 'الخدمة' : sub.serviceType,
                ),
              ];
              if (compact) {
                return Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      if (card != cards.last)
                        const SizedBox(height: AppTokens.s8),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (final card in cards) ...[
                    Expanded(child: card),
                    if (card != cards.last) const SizedBox(width: AppTokens.s8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.usage});

  final SubscriberPortalUsage usage;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'الاستخدام',
      icon: Icons.query_stats_outlined,
      child: Wrap(
        spacing: AppTokens.s8,
        runSpacing: AppTokens.s8,
        children: [
          _MetricTile(
            icon: Icons.download_outlined,
            label: 'التحميل',
            value: usage.downloadLabel,
            helper: 'حركة البيانات النازلة',
          ),
          _MetricTile(
            icon: Icons.upload_outlined,
            label: 'الرفع',
            value: usage.uploadLabel,
            helper: 'حركة البيانات الصاعدة',
          ),
          _MetricTile(
            icon: Icons.timer_outlined,
            label: 'وقت الاتصال',
            value: usage.sessionLabel,
            helper: 'من سجل الجلسات',
          ),
        ],
      ),
    );
  }
}

class _FinanceCard extends StatelessWidget {
  const _FinanceCard({required this.dashboard});

  final SubscriberPortalDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'الرصيد والمدفوعات',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _MetricTile(
                icon: Icons.wallet_outlined,
                label: 'رصيد المحفظة',
                value: dashboard.wallet.balanceLabel,
                helper: 'الرصيد المتاح في حسابك',
              ),
              _MetricTile(
                icon: Icons.receipt_long_outlined,
                label: 'الدين',
                value: dashboard.hasDebt
                    ? dashboard.debt.toStringAsFixed(2)
                    : 'لا يوجد دين',
                helper: 'حسب سجل الحساب',
              ),
              _MetricTile(
                icon: Icons.handshake_outlined,
                label: 'السلفة',
                value: dashboard.loanPolicy.allowedLabel,
                helper: dashboard.loanPolicy.autoApprove
                    ? 'اعتماد تلقائي حسب الباقة'
                    : 'تحتاج مراجعة الإدارة',
              ),
            ],
          ),
          if (dashboard.payments.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            const Text(
              'آخر المدفوعات',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppTokens.s8),
            for (final p in dashboard.payments.take(8)) _PaymentRow(payment: p),
          ],
        ],
      ),
    );
  }
}

/// One row of the subscriber-portal recent-payments list (`dashboard.payments`).
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});
  final Map<String, dynamic> payment;

  @override
  Widget build(BuildContext context) {
    String s(List<String> keys) {
      for (final k in keys) {
        final v = payment[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return '';
    }

    final amount = s(['amount', 'value', 'total']);
    final currency = s(['currency']);
    final when = s(['created_at', 'date', 'paid_at']);
    final status = s(['status', 'state']);
    final note = s(['note', 'reference', 'reference_code', 'purpose']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.payments_outlined,
            size: 16,
            color: AppTokens.brand,
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              [if (note.isNotEmpty) note, if (when.isNotEmpty) when]
                  .join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTokens.textSecondary),
            ),
          ),
          if (status.isNotEmpty) ...[
            Text(status, style: const TextStyle(color: AppTokens.textMuted)),
            const SizedBox(width: AppTokens.s8),
          ],
          Text(
            '$amount $currency'.trim(),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SessionsCard extends StatelessWidget {
  const _SessionsCard({required this.sessions});

  final List<SubscriberPortalSession> sessions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'آخر الجلسات',
      icon: Icons.router_outlined,
      padding: const EdgeInsets.all(AppTokens.s12),
      child: sessions.isEmpty
          ? const EmptyState(
              icon: Icons.history_outlined,
              title: 'لا توجد جلسات مسجلة',
              subtitle: 'عند تسجيل الدخول على الشبكة ستظهر الجلسات هنا.',
            )
          : Column(
              children: [
                for (final session in sessions.take(8)) ...[
                  _SessionTile(session: session),
                  if (session != sessions.take(8).last)
                    const SizedBox(height: AppTokens.s8),
                ],
              ],
            ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final SubscriberPortalSession session;

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
      child: Row(
        children: [
          StatusPill(
            text: session.online ? 'متصل' : 'منتهية',
            tone: session.online ? PillTone.green : PillTone.neutral,
            dot: true,
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              [
                if (session.framedIp.isNotEmpty) session.framedIp,
                session.durationLabel,
                session.trafficLabel,
              ].join(' • '),
              style: AppTypography.bodySmall.copyWith(color: p.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatefulWidget {
  const _ActionsCard({
    required this.policy,
    required this.sendingLoan,
    required this.sendingRenewal,
    required this.onSubmitLoan,
    required this.onSubmitRenewal,
  });

  final SubscriberPortalLoanPolicy policy;
  final bool sendingLoan;
  final bool sendingRenewal;
  final void Function(int minutes, String reason) onSubmitLoan;
  final ValueChanged<String> onSubmitRenewal;

  @override
  State<_ActionsCard> createState() => _ActionsCardState();
}

class _ActionsCardState extends State<_ActionsCard> {
  final _loanMinutes = TextEditingController(text: '1440');
  final _loanReason = TextEditingController();
  final _renewalReason = TextEditingController();

  @override
  void dispose() {
    _loanMinutes.dispose();
    _loanReason.dispose();
    _renewalReason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'طلبات الخدمة',
      icon: Icons.support_agent_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.policy.reason.isEmpty
                ? 'يمكنك إرسال طلب تجديد أو طلب سلفة من هنا، وسيصل الطلب إلى الإدارة كتذكرة متابعة.'
                : widget.policy.reason,
            style: AppTypography.bodySmall.copyWith(
              color: AppPalette.of(context).textMuted,
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          TextField(
            controller: _loanMinutes,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'مدة السلفة بالدقائق',
              helperText: 'مثال: 1440 يعني يوم كامل.',
              prefixIcon: Icon(Icons.more_time_outlined),
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          TextField(
            controller: _loanReason,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'ملاحظة السلفة',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          FilledButton.icon(
            onPressed: widget.sendingLoan
                ? null
                : () {
                    final minutes = int.tryParse(_loanMinutes.text.trim()) ?? 0;
                    widget.onSubmitLoan(minutes, _loanReason.text.trim());
                  },
            icon: widget.sendingLoan
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.handshake_outlined),
            label: const Text('إرسال طلب سلفة'),
          ),
          const Divider(height: AppTokens.s24),
          TextField(
            controller: _renewalReason,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'ملاحظة التجديد أو الدعم',
              helperText: 'لتحويله إلى شكوى ابدأ النص بكلمة [شكوى].',
              prefixIcon: Icon(Icons.edit_note_outlined),
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          OutlinedButton.icon(
            onPressed: widget.sendingRenewal
                ? null
                : () => widget.onSubmitRenewal(_renewalReason.text.trim()),
            icon: widget.sendingRenewal
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: const Text('إرسال طلب تجديد أو دعم'),
          ),
        ],
      ),
    );
  }
}

class _RequestsCard extends StatelessWidget {
  const _RequestsCard({required this.requests});

  final List<SubscriberPortalRequest> requests;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'طلباتي',
      icon: Icons.forum_outlined,
      padding: const EdgeInsets.all(AppTokens.s12),
      child: requests.isEmpty
          ? const EmptyState(
              icon: Icons.mark_chat_unread_outlined,
              title: 'لا توجد طلبات بعد',
              subtitle: 'عند إرسال طلب خدمة سيظهر هنا مع حالته.',
            )
          : Column(
              children: [
                for (final request in requests) ...[
                  _RequestTile(request: request),
                  if (request != requests.last)
                    const SizedBox(height: AppTokens.s8),
                ],
              ],
            ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});

  final SubscriberPortalRequest request;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: p.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.confirmation_number_outlined, color: p.brandInk),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${request.typeLabel} #${request.id}',
                  style: AppTypography.labelLarge.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (request.reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    request.reason,
                    style: AppTypography.bodySmall.copyWith(
                      color: p.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          StatusPill(
            text: request.statusLabel,
            tone: request.status == 'auto_approved'
                ? PillTone.green
                : request.status == 'rejected'
                    ? PillTone.red
                    : PillTone.amber,
            dot: true,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: p.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: p.brandSoft,
              borderRadius: BorderRadius.circular(AppTokens.r10),
            ),
            child: Icon(icon, color: p.brandInk, size: 18),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(color: p.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (helper.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    helper,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(color: p.textMuted),
                  ),
                ],
              ],
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

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
