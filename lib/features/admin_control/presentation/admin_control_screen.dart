import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/admin_control_controller.dart';
import '../domain/admin_control_model.dart';
import 'widgets/admin_dialogs.dart';
import 'widgets/admin_section_common.dart';
import 'widgets/admin_section_picker.dart';
import 'widgets/settings_panel.dart';
import 'widgets/tenants_panel.dart';
import 'widgets/tokens_panel.dart';
import 'widgets/webhooks_panel.dart';

/// Admin Control entry — wires the section picker to four panels and
/// delegates every async action to [adminControlControllerProvider].
class AdminControlScreen extends ConsumerStatefulWidget {
  const AdminControlScreen({super.key});

  @override
  ConsumerState<AdminControlScreen> createState() => _AdminControlScreenState();
}

class _AdminControlScreenState extends ConsumerState<AdminControlScreen> {
  AdminSection _section = AdminSection.settings;
  String _deliveryStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(adminControlControllerProvider);
    final busy = controller.busy;
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
              onPressed: () => ref
                  .read(adminControlControllerProvider.notifier)
                  .refreshAll(_deliveryStatus),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        AdminSectionPicker(
          value: _section,
          onChanged: (value) => setState(() => _section = value),
        ),
        const SizedBox(height: AppTokens.s12),
        switch (_section) {
          AdminSection.settings => SettingsPanel(onEdit: _editSetting),
          AdminSection.tokens => TokensPanel(
              onCreate: _createToken,
              onRevoke: _revokeToken,
              busy: busy,
            ),
          AdminSection.tenants => TenantsPanel(
              onCreate: _createTenant,
              onEdit: _editTenant,
              busy: busy,
            ),
          AdminSection.webhooks => WebhooksPanel(
              selectedStatus: _deliveryStatus,
              onStatusChanged: (value) =>
                  setState(() => _deliveryStatus = value),
              onSaveConfig: _saveWebhookConfig,
              onTest: _testWebhook,
              busy: busy,
            ),
        },
      ],
    );
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
    final result = await ref
        .read(adminControlControllerProvider.notifier)
        .updateSetting(item.key, value);
    _afterAction(result.error, 'تم حفظ الإعداد');
  }

  Future<void> _createToken() async {
    final name = await showAdminTextDialog(
      context,
      title: 'مفتاح API جديد',
      label: 'اسم المفتاح',
      initial: 'mobile-admin',
    );
    if (!mounted || name == null || name.trim().isEmpty) return;
    final result = await ref
        .read(adminControlControllerProvider.notifier)
        .createToken(name.trim());
    if (!mounted) return;
    if (result.token != null) {
      await showAdminTokenDialog(context, result.token!.token);
    } else if (result.error != null) {
      _snack(result.error!);
    }
  }

  Future<void> _revokeToken(ApiTokenRecord token) async {
    final ok = await showAdminConfirm(
      context,
      title: 'إلغاء المفتاح',
      body: 'سيتم إلغاء مفتاح ${token.name}. لن يستطيع استخدام API بعد ذلك.',
    );
    if (!mounted || !ok) return;
    final result = await ref
        .read(adminControlControllerProvider.notifier)
        .revokeToken(token.id);
    _afterAction(result.error, 'تم إلغاء المفتاح');
  }

  Future<void> _createTenant() async {
    final tenant = await showAdminTenantDialog(context);
    if (!mounted || tenant == null) return;
    final result = await ref
        .read(adminControlControllerProvider.notifier)
        .createTenant(tenant);
    _afterAction(result.error, 'تم إنشاء المستأجر');
  }

  Future<void> _editTenant(TenantRecord tenant) async {
    final updated = await showAdminTenantDialog(context, existing: tenant);
    if (!mounted || updated == null) return;
    final result = await ref
        .read(adminControlControllerProvider.notifier)
        .updateTenant(updated);
    _afterAction(result.error, 'تم تحديث المستأجر');
  }

  Future<void> _saveWebhookConfig({
    required String targetUrl,
    required String secret,
    required List<String> events,
  }) async {
    final result = await ref
        .read(adminControlControllerProvider.notifier)
        .saveWebhookConfig(
          targetUrl: targetUrl,
          secret: secret,
          events: events,
        );
    _afterAction(result.error, 'تم حفظ إعدادات Webhook');
  }

  Future<void> _testWebhook() async {
    final result = await ref
        .read(adminControlControllerProvider.notifier)
        .testWebhook(_deliveryStatus);
    _afterAction(result.error, 'تم إرسال حدث اختبار');
  }

  void _afterAction(String? error, String successMessage) {
    if (!mounted) return;
    _snack(error ?? successMessage);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
