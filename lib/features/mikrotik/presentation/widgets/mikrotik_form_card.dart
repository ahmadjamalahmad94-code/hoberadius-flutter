import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/mikrotik_model.dart';

class MikrotikFormCard extends StatelessWidget {
  const MikrotikFormCard({
    super.key,
    required this.formKey,
    required this.editing,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.timeout,
    required this.useTls,
    required this.verifyTls,
    required this.enabled,
    required this.saving,
    required this.testing,
    required this.onUseTlsChanged,
    required this.onVerifyTlsChanged,
    required this.onEnabledChanged,
    required this.onCancel,
    required this.onSave,
    required this.onTest,
  });

  final GlobalKey<FormState> formKey;
  final MikrotikConfig? editing;
  final TextEditingController name;
  final TextEditingController host;
  final TextEditingController port;
  final TextEditingController username;
  final TextEditingController password;
  final TextEditingController timeout;
  final bool useTls;
  final bool verifyTls;
  final bool enabled;
  final bool saving;
  final bool testing;
  final ValueChanged<bool> onUseTlsChanged;
  final ValueChanged<bool> onVerifyTlsChanged;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: editing == null ? 'اتصال ميكروتك جديد' : 'تعديل اتصال ميكروتك',
      icon: Icons.router_outlined,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final twoCols = constraints.maxWidth >= 720;
                return Wrap(
                  spacing: AppTokens.s12,
                  runSpacing: AppTokens.s12,
                  children: [
                    _FieldBox(
                      wide: twoCols,
                      child: TextFormField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'اسم الاتصال',
                          hintText: 'مثال: راوتر المكتب',
                        ),
                      ),
                    ),
                    _FieldBox(
                      wide: twoCols,
                      child: TextFormField(
                        controller: host,
                        decoration: const InputDecoration(
                          labelText: 'عنوان الراوتر',
                          hintText: 'عنوان IP أو اسم المضيف',
                        ),
                        validator: _required,
                      ),
                    ),
                    _FieldBox(
                      wide: twoCols,
                      child: TextFormField(
                        controller: username,
                        decoration: const InputDecoration(
                          labelText: 'اسم مستخدم واجهة الربط',
                        ),
                        validator: _required,
                      ),
                    ),
                    _FieldBox(
                      wide: twoCols,
                      child: TextFormField(
                        controller: password,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: editing == null
                              ? 'كلمة مرور واجهة الربط'
                              : 'كلمة مرور جديدة (اختياري)',
                          hintText: editing == null
                              ? 'مطلوبة عند الإضافة'
                              : 'اتركها فارغة للإبقاء على القديمة',
                        ),
                      ),
                    ),
                    _FieldBox(
                      wide: twoCols,
                      child: TextFormField(
                        controller: port,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'منفذ واجهة الربط',
                        ),
                        validator: _positiveNumber,
                      ),
                    ),
                    _FieldBox(
                      wide: twoCols,
                      child: TextFormField(
                        controller: timeout,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'مهلة الاتصال (ثواني)',
                        ),
                        validator: _positiveNumber,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTokens.s12),
            Wrap(
              spacing: AppTokens.s12,
              runSpacing: AppTokens.s8,
              children: [
                FilterChip(
                  selected: enabled,
                  onSelected: onEnabledChanged,
                  label: const Text('مفعّل'),
                  avatar: const Icon(Icons.power_settings_new),
                ),
                FilterChip(
                  selected: useTls,
                  onSelected: onUseTlsChanged,
                  label: const Text('استخدام TLS'),
                  avatar: const Icon(Icons.lock_outline),
                ),
                FilterChip(
                  selected: verifyTls,
                  onSelected: onVerifyTlsChanged,
                  label: const Text('التحقق من شهادة TLS'),
                  avatar: const Icon(Icons.verified_user_outlined),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s16),
            Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: saving || testing ? null : onCancel,
                  child: const Text('إلغاء'),
                ),
                OutlinedButton.icon(
                  onPressed: saving || testing ? null : onTest,
                  icon: testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check),
                  label: Text(
                    testing ? 'جار الاختبار...' : 'اختبار قبل الحفظ',
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: saving || testing ? null : onSave,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'جار الحفظ...' : 'حفظ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.wide, required this.child});
  final bool wide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 330 : double.infinity,
      child: child,
    );
  }
}

String? _required(String? value) {
  if ((value ?? '').trim().isEmpty) return 'مطلوب';
  return null;
}

String? _positiveNumber(String? value) {
  final n = int.tryParse((value ?? '').trim());
  if (n == null || n <= 0) return 'اكتب رقمًا صحيحًا أكبر من صفر';
  return null;
}
