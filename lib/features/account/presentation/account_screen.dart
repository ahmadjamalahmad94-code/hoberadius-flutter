import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/hub_switch_row.dart';
import '../../../shared/widgets/hub_toast.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/account_repository.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  bool _showPasswords = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final admin = auth.admin;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'حسابي',
            subtitle: 'بيانات الدخول وتغيير كلمة المرور',
            leading: _HeaderIcon(),
          ),
          const SizedBox(height: AppTokens.s12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= AppTokens.bpTablet;
              final info = _AccountInfoCard(auth: auth);
              final password = _PasswordCard(
                formKey: _formKey,
                current: _current,
                next: _next,
                confirm: _confirm,
                saving: _saving,
                showPasswords: _showPasswords,
                onToggleVisibility: () {
                  setState(() => _showPasswords = !_showPasswords);
                },
                onSave: _savePassword,
              );
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    info,
                    const SizedBox(height: AppTokens.s12),
                    password,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: info),
                  const SizedBox(width: AppTokens.s16),
                  Expanded(child: password),
                ],
              );
            },
          ),
          if (admin?.isSuperAdmin == true) ...[
            const SizedBox(height: AppTokens.s12),
            const AppCard(
              title: 'صلاحية الحساب',
              icon: Icons.admin_panel_settings_outlined,
              padding: EdgeInsets.all(AppTokens.s12),
              child: Text(
                'هذا الحساب يملك صلاحية مدير عام. أي تغيير هنا يؤثر على دخول التطبيق والويب لنفس المستخدم فقط.',
                style: TextStyle(
                  color: AppTokens.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _savePassword() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final message = await ref.read(accountRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
            confirmPassword: _confirm.text,
          );
      _current.clear();
      _next.clear();
      _confirm.clear();
      if (!mounted) return;
      HubToaster.success(context, message);
    } on ApiException catch (e) {
      if (!mounted) return;
      HubToaster.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      HubToaster.error(context, 'تعذر تحديث كلمة المرور. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppTokens.brandSoft,
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.account_circle_outlined, color: AppTokens.brand),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.auth});

  final AuthState auth;

  @override
  Widget build(BuildContext context) {
    final admin = auth.admin;
    return AppCard(
      title: 'بيانات الحساب',
      icon: Icons.badge_outlined,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoRow(
            label: 'اسم المستخدم',
            value: admin?.username ?? 'غير معروف',
          ),
          _InfoRow(
            label: 'الاسم',
            value:
                (admin?.fullName ?? '').isEmpty ? 'غير محدد' : admin!.fullName,
          ),
          _InfoRow(
            label: 'البريد',
            value: (admin?.email ?? '').isEmpty ? 'غير محدد' : admin!.email,
          ),
          _InfoRow(
            label: 'نوع الصلاحية',
            value: admin?.isSuperAdmin == true ? 'مدير عام' : 'حساب إداري',
          ),
          _InfoRow(
            label: 'الخادم المتصل',
            value: auth.serverBaseUrl ?? 'غير محدد',
            technical: true,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.technical = false,
  });

  final String label;
  final String value;
  final bool technical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTokens.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            // Technical values (the server URL) stay on one LTR line with an
            // ellipsis instead of breaking after «https://».
            child: Directionality(
              textDirection: technical ? TextDirection.ltr : TextDirection.rtl,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: technical ? TextAlign.left : TextAlign.right,
                style: TextStyle(
                  color: AppTokens.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: technical ? 12.5 : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordCard extends StatelessWidget {
  const _PasswordCard({
    required this.formKey,
    required this.current,
    required this.next,
    required this.confirm,
    required this.saving,
    required this.showPasswords,
    required this.onToggleVisibility,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController current;
  final TextEditingController next;
  final TextEditingController confirm;
  final bool saving;
  final bool showPasswords;
  final VoidCallback onToggleVisibility;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'تغيير كلمة المرور',
      icon: Icons.password_outlined,
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PasswordField(
              controller: current,
              label: 'كلمة المرور الحالية',
              showPassword: showPasswords,
            ),
            const SizedBox(height: AppTokens.s8),
            _PasswordField(
              controller: next,
              label: 'كلمة المرور الجديدة',
              showPassword: showPasswords,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 8) {
                  return 'اكتب 8 أحرف على الأقل.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTokens.s8),
            _PasswordField(
              controller: confirm,
              label: 'تأكيد كلمة المرور الجديدة',
              showPassword: showPasswords,
              validator: (value) {
                if ((value ?? '') != next.text) {
                  return 'التأكيد غير مطابق.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTokens.s4),
            HubSwitchRow(
              dense: true,
              label: 'إظهار الكلمات أثناء الكتابة',
              value: showPasswords,
              onChanged: (_) => onToggleVisibility(),
            ),
            const SizedBox(height: AppTokens.s4),
            HubActionButton(
              item: ActionItem(
                icon: Icons.save_outlined,
                label: saving ? 'جارٍ التحديث...' : 'تحديث كلمة المرور',
                primary: true,
                onPressed: saving ? null : onSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.showPassword,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool showPassword;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !showPassword,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label),
      validator: validator ??
          (value) {
            if ((value ?? '').isEmpty) return 'هذا الحقل مطلوب.';
            return null;
          },
    );
  }
}
