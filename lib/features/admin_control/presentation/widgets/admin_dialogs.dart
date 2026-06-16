import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../domain/admin_control_model.dart';

/// One-line text-edit dialog. Resolves with the entered text on
/// confirm, `null` on cancel.
Future<String?> showAdminTextDialog(
  BuildContext context, {
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

/// Yes/no confirmation. Returns `true` only on explicit confirm.
Future<bool> showAdminConfirm(
  BuildContext context, {
  required String title,
  required String body,
}) async {
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

/// "Show this once" dialog used after a fresh API token is generated —
/// the secret value is never returned by list endpoints, so the
/// operator must copy it here or lose it.
Future<void> showAdminTokenDialog(
  BuildContext context,
  String? tokenValue,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('انسخ المفتاح الآن'),
      content: SelectableText(tokenValue ?? ''),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('تم'),
        ),
      ],
    ),
  );
}

/// Create / edit-tenant dialog. Resolves with the built [TenantRecord]
/// on save, `null` on cancel. When [existing] is provided, the slug
/// field is read-only and identity-preserving fields (currency,
/// locale, timezone) are carried over.
Future<TenantRecord?> showAdminTenantDialog(
  BuildContext context, {
  TenantRecord? existing,
}) async {
  final slug = TextEditingController(text: existing?.slug ?? '');
  final name = TextEditingController(text: existing?.name ?? '');
  final displayName = TextEditingController(text: existing?.displayName ?? '');
  final email = TextEditingController(text: existing?.email ?? '');
  final phone = TextEditingController(text: existing?.phone ?? '');
  final maxSubscribers = TextEditingController(
    text: '${existing?.maxSubscribers ?? 200}',
  );
  final maxNas = TextEditingController(text: '${existing?.maxNas ?? 1}');
  final apiRpm = TextEditingController(text: '${existing?.apiRpm ?? 0}');
  final currency = TextEditingController(text: existing?.currency ?? 'JOD');
  final timezone =
      TextEditingController(text: existing?.timezone ?? 'Asia/Amman');
  final primaryColor =
      TextEditingController(text: existing?.primaryColor ?? '#2BAACC');
  final logoUrl = TextEditingController(text: existing?.logoUrl ?? '');
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
                    DropdownMenuItem(value: 'starter', child: Text('بداية')),
                    DropdownMenuItem(value: 'pro', child: Text('احترافي')),
                    DropdownMenuItem(
                      value: 'enterprise',
                      child: Text('مؤسسات'),
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
                  decoration: const InputDecoration(labelText: 'حد المشتركين'),
                ),
                TextField(
                  controller: maxNas,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'حد أجهزة الشبكة'),
                ),
                TextField(
                  controller: apiRpm,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'حد طلبات الربط بالدقيقة، 0 يعني بدون حد',
                  ),
                ),
                TextField(
                  controller: currency,
                  decoration: const InputDecoration(labelText: 'العملة'),
                ),
                TextField(
                  controller: timezone,
                  decoration: const InputDecoration(labelText: 'المنطقة الزمنية'),
                ),
                TextField(
                  controller: primaryColor,
                  decoration: const InputDecoration(
                    labelText: 'اللون الأساسي للعلامة',
                    hintText: '#2BAACC',
                  ),
                ),
                TextField(
                  controller: logoUrl,
                  decoration: const InputDecoration(
                    labelText: 'رابط الشعار',
                    hintText: 'https://…',
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
                  currency: currency.text.trim().isEmpty
                      ? 'JOD'
                      : currency.text.trim(),
                  locale: existing?.locale ?? 'ar',
                  timezone: timezone.text.trim().isEmpty
                      ? 'Asia/Amman'
                      : timezone.text.trim(),
                  status: status,
                  planTier: tier,
                  maxSubscribers: int.tryParse(maxSubscribers.text) ?? 0,
                  maxNas: int.tryParse(maxNas.text) ?? 0,
                  apiRpm: int.tryParse(apiRpm.text) ?? 0,
                  primaryColor: primaryColor.text.trim(),
                  logoUrl: logoUrl.text.trim(),
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
  currency.dispose();
  timezone.dispose();
  primaryColor.dispose();
  logoUrl.dispose();
  return result;
}
