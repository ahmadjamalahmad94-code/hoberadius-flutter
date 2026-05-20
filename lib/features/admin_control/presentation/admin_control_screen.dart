import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/admin_control_repository.dart';
import '../domain/admin_control_model.dart';

final settingsProvider = FutureProvider.autoDispose<SettingsSnapshot>((ref) {
  return ref.watch(adminControlRepositoryProvider).settings();
});

final apiTokensProvider =
    FutureProvider.autoDispose<List<ApiTokenRecord>>((ref) {
  return ref.watch(adminControlRepositoryProvider).tokens();
});

final tenantsProvider = FutureProvider.autoDispose<List<TenantRecord>>((ref) {
  return ref.watch(adminControlRepositoryProvider).tenants();
});

final webhookConfigProvider = FutureProvider.autoDispose<WebhookConfig>((ref) {
  return ref.watch(adminControlRepositoryProvider).webhookConfig();
});

final webhookDeliveriesProvider =
    FutureProvider.autoDispose.family<List<WebhookDelivery>, String>(
  (ref, status) => ref.watch(adminControlRepositoryProvider).webhookDeliveries(
        status: status == 'all' ? null : status,
      ),
);

enum _AdminSection { settings, tokens, tenants, webhooks }

class AdminControlScreen extends ConsumerStatefulWidget {
  const AdminControlScreen({super.key});

  @override
  ConsumerState<AdminControlScreen> createState() => _AdminControlScreenState();
}

class _AdminControlScreenState extends ConsumerState<AdminControlScreen> {
  _AdminSection _section = _AdminSection.settings;
  String _deliveryStatus = 'all';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'التحكم الإداري',
          subtitle:
              'إعدادات النظام، مفاتيح API، المستأجرون، وسجل إرسال Webhooks عبر API حقيقي.',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        _SectionPicker(
          value: _section,
          onChanged: (value) => setState(() => _section = value),
        ),
        const SizedBox(height: AppTokens.s12),
        switch (_section) {
          _AdminSection.settings => _SettingsPanel(onEdit: _editSetting),
          _AdminSection.tokens => _TokensPanel(
              onCreate: _createToken,
              onRevoke: _revokeToken,
              busy: _busy,
            ),
          _AdminSection.tenants => _TenantsPanel(
              onCreate: _createTenant,
              onEdit: _editTenant,
              busy: _busy,
            ),
          _AdminSection.webhooks => _WebhooksPanel(
              selectedStatus: _deliveryStatus,
              onStatusChanged: (value) =>
                  setState(() => _deliveryStatus = value),
              onSaveConfig: _saveWebhookConfig,
              onTest: _testWebhook,
              busy: _busy,
            ),
        },
      ],
    );
  }

  void _refresh() {
    ref.invalidate(settingsProvider);
    ref.invalidate(apiTokensProvider);
    ref.invalidate(tenantsProvider);
    ref.invalidate(webhookConfigProvider);
    ref.invalidate(webhookDeliveriesProvider(_deliveryStatus));
  }

  Future<void> _editSetting(SettingItem item) async {
    final controller = TextEditingController(text: item.value);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.label),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: item.key,
            helperText: item.defaultValue.isEmpty
                ? null
                : 'الافتراضي: ${item.defaultValue}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await _run(
      () => ref.read(adminControlRepositoryProvider).updateSetting(
            item.key,
            value,
          ),
      onSuccess: () => ref.invalidate(settingsProvider),
      message: 'تم حفظ الإعداد',
    );
  }

  Future<void> _createToken() async {
    final name = await _textDialog(
      title: 'مفتاح API جديد',
      label: 'اسم المفتاح',
      initial: 'mobile-admin',
    );
    if (name == null || name.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final token = await ref
          .read(adminControlRepositoryProvider)
          .createToken(name.trim());
      ref.invalidate(apiTokensProvider);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('انسخ المفتاح الآن'),
          content: SelectableText(token.token ?? ''),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('تم'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revokeToken(ApiTokenRecord token) async {
    final ok = await _confirm(
      title: 'إلغاء المفتاح',
      body: 'سيتم إلغاء مفتاح ${token.name}. لن يستطيع استخدام API بعد ذلك.',
    );
    if (!ok) return;
    await _run(
      () => ref.read(adminControlRepositoryProvider).revokeToken(token.id),
      onSuccess: () => ref.invalidate(apiTokensProvider),
      message: 'تم إلغاء المفتاح',
    );
  }

  Future<void> _createTenant() async {
    final tenant = await _tenantDialog();
    if (tenant == null) return;
    await _run(
      () async {
        await ref.read(adminControlRepositoryProvider).createTenant(tenant);
      },
      onSuccess: () => ref.invalidate(tenantsProvider),
      message: 'تم إنشاء المستأجر',
    );
  }

  Future<void> _editTenant(TenantRecord tenant) async {
    final updated = await _tenantDialog(existing: tenant);
    if (updated == null) return;
    await _run(
      () async {
        await ref.read(adminControlRepositoryProvider).updateTenant(updated);
      },
      onSuccess: () => ref.invalidate(tenantsProvider),
      message: 'تم تحديث المستأجر',
    );
  }

  Future<void> _saveWebhookConfig({
    required String targetUrl,
    required String secret,
    required List<String> events,
  }) async {
    await _run(
      () async {
        await ref.read(adminControlRepositoryProvider).updateWebhookConfig(
              targetUrl: targetUrl,
              secret: secret,
              enabledEvents: events,
            );
      },
      onSuccess: () => ref.invalidate(webhookConfigProvider),
      message: 'تم حفظ إعدادات Webhook',
    );
  }

  Future<void> _testWebhook() async {
    await _run(
      () => ref.read(adminControlRepositoryProvider).testWebhook(),
      onSuccess: () {
        ref.invalidate(webhookConfigProvider);
        ref.invalidate(webhookDeliveriesProvider(_deliveryStatus));
      },
      message: 'تم إرسال حدث اختبار',
    );
  }

  Future<TenantRecord?> _tenantDialog({TenantRecord? existing}) async {
    final slug = TextEditingController(text: existing?.slug ?? '');
    final name = TextEditingController(text: existing?.name ?? '');
    final displayName =
        TextEditingController(text: existing?.displayName ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final maxSubscribers = TextEditingController(
      text: '${existing?.maxSubscribers ?? 200}',
    );
    final maxNas = TextEditingController(text: '${existing?.maxNas ?? 1}');
    final apiRpm = TextEditingController(text: '${existing?.apiRpm ?? 0}');
    var tier =
        existing?.planTier.isNotEmpty == true ? existing!.planTier : 'starter';
    var status =
        existing?.status.isNotEmpty == true ? existing!.status : 'active';
    final result = await showDialog<TenantRecord>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'مستأجر جديد' : 'تعديل مستأجر'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: slug,
                    enabled: existing == null,
                    decoration: const InputDecoration(labelText: 'المعرّف'),
                  ),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'الاسم'),
                  ),
                  TextField(
                    controller: displayName,
                    decoration: const InputDecoration(labelText: 'اسم العرض'),
                  ),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'البريد'),
                  ),
                  TextField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'الهاتف'),
                  ),
                  const SizedBox(height: AppTokens.s8),
                  DropdownButtonFormField<String>(
                    initialValue: tier,
                    decoration: const InputDecoration(labelText: 'الخطة'),
                    items: const [
                      DropdownMenuItem(
                        value: 'starter',
                        child: Text('Starter'),
                      ),
                      DropdownMenuItem(value: 'pro', child: Text('Pro')),
                      DropdownMenuItem(
                        value: 'enterprise',
                        child: Text('Enterprise'),
                      ),
                    ],
                    onChanged: (value) => setLocal(() => tier = value ?? tier),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'الحالة'),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('مفعّل')),
                      DropdownMenuItem(value: 'trial', child: Text('تجريبي')),
                      DropdownMenuItem(
                        value: 'suspended',
                        child: Text('موقوف'),
                      ),
                      DropdownMenuItem(value: 'closed', child: Text('مغلق')),
                    ],
                    onChanged: (value) =>
                        setLocal(() => status = value ?? status),
                  ),
                  TextField(
                    controller: maxSubscribers,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'حد المشتركين'),
                  ),
                  TextField(
                    controller: maxNas,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'حد NAS'),
                  ),
                  TextField(
                    controller: apiRpm,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'حد API بالدقيقة، 0 يعني بدون حد',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  ctx,
                  TenantRecord(
                    id: existing?.id ?? 0,
                    slug: slug.text.trim(),
                    name: name.text.trim(),
                    displayName: displayName.text.trim(),
                    email: email.text.trim(),
                    phone: phone.text.trim(),
                    currency: existing?.currency ?? 'JOD',
                    locale: existing?.locale ?? 'ar',
                    timezone: existing?.timezone ?? 'Asia/Amman',
                    status: status,
                    planTier: tier,
                    maxSubscribers: int.tryParse(maxSubscribers.text) ?? 0,
                    maxNas: int.tryParse(maxNas.text) ?? 0,
                    apiRpm: int.tryParse(apiRpm.text) ?? 0,
                  ),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    slug.dispose();
    name.dispose();
    displayName.dispose();
    email.dispose();
    phone.dispose();
    maxSubscribers.dispose();
    maxNas.dispose();
    apiRpm.dispose();
    return result;
  }

  Future<String?> _textDialog({
    required String title,
    required String label,
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool> _confirm({required String title, required String body}) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('تأكيد'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _run(
    Future<void> Function() action, {
    required VoidCallback onSuccess,
    required String message,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      onSuccess();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$error')),
    );
  }
}

class _SectionPicker extends StatelessWidget {
  const _SectionPicker({required this.value, required this.onChanged});

  final _AdminSection value;
  final ValueChanged<_AdminSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (section: _AdminSection.settings, icon: Icons.tune, label: 'الإعدادات'),
      (section: _AdminSection.tokens, icon: Icons.key, label: 'مفاتيح API'),
      (
        section: _AdminSection.tenants,
        icon: Icons.business,
        label: 'المستأجرون'
      ),
      (section: _AdminSection.webhooks, icon: Icons.bolt, label: 'Webhooks'),
    ];
    return Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      children: [
        for (final item in items)
          ChoiceChip(
            selected: value == item.section,
            avatar: Icon(item.icon, size: 16),
            label: Text(item.label),
            onSelected: (_) => onChanged(item.section),
          ),
      ],
    );
  }
}

class _SettingsPanel extends ConsumerWidget {
  const _SettingsPanel({required this.onEdit});

  final ValueChanged<SettingItem> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(settingsProvider);
    return async.when(
      loading: () => const _LoadingCard(title: 'الإعدادات'),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'تعذر جلب الإعدادات',
        subtitle: '$e',
      ),
      data: (snapshot) => AppCard(
        title: 'إعدادات النظام',
        icon: Icons.tune,
        padding: EdgeInsets.zero,
        child: _ListSection(
          count: snapshot.items.length,
          itemBuilder: (_, i) {
            final item = snapshot.items[i];
            return ListTile(
              title: Text(item.label),
              subtitle: Text(
                item.key,
                style: const TextStyle(color: AppTokens.textMuted),
              ),
              trailing: Wrap(
                spacing: AppTokens.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      item.value.isEmpty ? 'غير محدد' : item.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'تعديل',
                    onPressed: () => onEdit(item),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TokensPanel extends ConsumerWidget {
  const _TokensPanel({
    required this.onCreate,
    required this.onRevoke,
    required this.busy,
  });

  final VoidCallback onCreate;
  final ValueChanged<ApiTokenRecord> onRevoke;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(apiTokensProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'المفتاح السري يظهر مرة واحدة عند الإنشاء فقط. القوائم لا تعرض token ولا hash.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
              ElevatedButton.icon(
                onPressed: busy ? null : onCreate,
                icon: const Icon(Icons.add),
                label: const Text('مفتاح جديد'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const _LoadingCard(title: 'مفاتيح API'),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب المفاتيح',
            subtitle: '$e',
          ),
          data: (tokens) => AppCard(
            title: 'مفاتيح API',
            icon: Icons.key,
            padding: EdgeInsets.zero,
            child: tokens.isEmpty
                ? const EmptyState(
                    icon: Icons.key_off_outlined,
                    title: 'لا توجد مفاتيح API',
                  )
                : _ListSection(
                    count: tokens.length,
                    itemBuilder: (_, i) {
                      final token = tokens[i];
                      return ListTile(
                        title: Text(token.name),
                        subtitle: Text(
                          [
                            if (token.scopes.isNotEmpty)
                              token.scopes.join(', '),
                            if (token.lastUsedAt.isNotEmpty)
                              'آخر استخدام: ${token.lastUsedAt}',
                            if (token.expiresAt.isNotEmpty)
                              'ينتهي: ${token.expiresAt}',
                          ].join(' • '),
                        ),
                        leading: StatusPill(
                          text: token.revoked ? 'ملغى' : 'مفعّل',
                          tone: token.revoked ? PillTone.red : PillTone.green,
                        ),
                        trailing: token.revoked
                            ? null
                            : IconButton(
                                tooltip: 'إلغاء',
                                onPressed: busy ? null : () => onRevoke(token),
                                icon: const Icon(Icons.block),
                              ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _TenantsPanel extends ConsumerWidget {
  const _TenantsPanel({
    required this.onCreate,
    required this.onEdit,
    required this.busy,
  });

  final VoidCallback onCreate;
  final ValueChanged<TenantRecord> onEdit;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tenantsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ElevatedButton.icon(
            onPressed: busy ? null : onCreate,
            icon: const Icon(Icons.add_business),
            label: const Text('مستأجر جديد'),
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const _LoadingCard(title: 'المستأجرون'),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب المستأجرين',
            subtitle: '$e',
          ),
          data: (tenants) => AppCard(
            title: 'المستأجرون',
            icon: Icons.business,
            padding: EdgeInsets.zero,
            child: _ListSection(
              count: tenants.length,
              itemBuilder: (_, i) {
                final tenant = tenants[i];
                return ListTile(
                  title: Text(
                    tenant.displayName.isEmpty
                        ? tenant.name
                        : tenant.displayName,
                  ),
                  subtitle: Text(
                    [
                      tenant.slug,
                      tenant.planTier,
                      'مشتركين: ${tenant.maxSubscribers}',
                      'NAS: ${tenant.maxNas}',
                      'API: ${tenant.apiRpm == 0 ? 'بدون حد' : tenant.apiRpm}',
                    ].join(' • '),
                  ),
                  leading: StatusPill(
                    text: _tenantStatusLabel(tenant.status),
                    tone: _tenantStatusTone(tenant.status),
                  ),
                  trailing: IconButton(
                    tooltip: 'تعديل',
                    onPressed: busy ? null : () => onEdit(tenant),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _WebhooksPanel extends ConsumerStatefulWidget {
  const _WebhooksPanel({
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onSaveConfig,
    required this.onTest,
    required this.busy,
  });

  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final Future<void> Function({
    required String targetUrl,
    required String secret,
    required List<String> events,
  }) onSaveConfig;
  final Future<void> Function() onTest;
  final bool busy;

  @override
  ConsumerState<_WebhooksPanel> createState() => _WebhooksPanelState();
}

class _WebhooksPanelState extends ConsumerState<_WebhooksPanel> {
  final _target = TextEditingController();
  final _secret = TextEditingController();
  final _events = TextEditingController(text: 'webhook.test');

  @override
  void dispose() {
    _target.dispose();
    _secret.dispose();
    _events.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(webhookConfigProvider);
    final deliveries =
        ref.watch(webhookDeliveriesProvider(widget.selectedStatus));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        config.when(
          loading: () => const _LoadingCard(title: 'إعدادات Webhook'),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب إعدادات Webhook',
            subtitle: '$e',
          ),
          data: (item) {
            if (_target.text.isEmpty) _target.text = item.targetUrl;
            if (_events.text == 'webhook.test' &&
                item.enabledEvents.isNotEmpty) {
              _events.text = item.enabledEvents.join(',');
            }
            return AppCard(
              title: 'إعدادات Webhook',
              icon: Icons.bolt,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _target,
                    decoration:
                        const InputDecoration(labelText: 'رابط الاستقبال'),
                  ),
                  const SizedBox(height: AppTokens.s8),
                  TextField(
                    controller: _secret,
                    decoration: InputDecoration(
                      labelText:
                          item.secretSet ? 'سر جديد اختياري' : 'سر التوقيع',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: AppTokens.s8),
                  TextField(
                    controller: _events,
                    decoration: const InputDecoration(
                      labelText: 'الأحداث، افصل بينها بفاصلة',
                    ),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  Wrap(
                    spacing: AppTokens.s8,
                    runSpacing: AppTokens.s8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: widget.busy
                            ? null
                            : () => widget.onSaveConfig(
                                  targetUrl: _target.text.trim(),
                                  secret: _secret.text.trim(),
                                  events: _events.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList(),
                                ),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('حفظ'),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.busy ? null : widget.onTest,
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('اختبار الإرسال'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          title: 'سجل الإرسال',
          icon: Icons.receipt_long_outlined,
          actions: [
            DropdownButton<String>(
              value: widget.selectedStatus,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('كل الحالات')),
                DropdownMenuItem(value: 'queued', child: Text('بالانتظار')),
                DropdownMenuItem(
                  value: 'retrying',
                  child: Text('إعادة محاولة'),
                ),
                DropdownMenuItem(value: 'delivered', child: Text('تم الإرسال')),
                DropdownMenuItem(value: 'failed', child: Text('فشل')),
              ],
              onChanged: (value) {
                if (value != null) widget.onStatusChanged(value);
              },
            ),
          ],
          padding: EdgeInsets.zero,
          child: deliveries.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppTokens.s20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'تعذر جلب سجل الإرسال',
              subtitle: '$e',
            ),
            data: (items) => items.isEmpty
                ? const EmptyState(
                    icon: Icons.bolt_outlined,
                    title: 'لا توجد سجلات إرسال',
                  )
                : _ListSection(
                    count: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return ListTile(
                        title: Text(item.event),
                        subtitle: Text(
                          [
                            item.eventId,
                            'محاولات: ${item.attempts}',
                            if (item.lastStatusCode > 0)
                              'كود: ${item.lastStatusCode}',
                            if (item.lastResponseExcerpt.isNotEmpty)
                              item.lastResponseExcerpt,
                          ].join(' • '),
                        ),
                        leading: StatusPill(
                          text: _deliveryLabel(item.status),
                          tone: _deliveryTone(item.status),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.count, required this.itemBuilder});

  final int count;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: itemBuilder,
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: title,
      child: const Padding(
        padding: EdgeInsets.all(AppTokens.s20),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

String _tenantStatusLabel(String value) {
  return switch (value) {
    'active' => 'مفعّل',
    'trial' => 'تجريبي',
    'suspended' => 'موقوف',
    'closed' => 'مغلق',
    _ => value.isEmpty ? 'غير معروف' : value,
  };
}

PillTone _tenantStatusTone(String value) {
  return switch (value) {
    'active' => PillTone.green,
    'trial' => PillTone.cyan,
    'suspended' => PillTone.orange,
    'closed' => PillTone.red,
    _ => PillTone.neutral,
  };
}

String _deliveryLabel(String value) {
  return switch (value) {
    'queued' => 'بالانتظار',
    'retrying' => 'إعادة محاولة',
    'delivered' => 'تم الإرسال',
    'failed' => 'فشل',
    _ => value,
  };
}

PillTone _deliveryTone(String value) {
  return switch (value) {
    'delivered' => PillTone.green,
    'failed' => PillTone.red,
    'queued' || 'retrying' => PillTone.orange,
    _ => PillTone.neutral,
  };
}
