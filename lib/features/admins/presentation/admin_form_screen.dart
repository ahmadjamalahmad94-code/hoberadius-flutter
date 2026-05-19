import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/form_field_row.dart';

class AdminFormScreen extends ConsumerStatefulWidget {
  const AdminFormScreen({super.key, this.adminId});
  final int? adminId;
  bool get isEdit => adminId != null;

  @override
  ConsumerState<AdminFormScreen> createState() => _AdminFormScreenState();
}

class _AdminFormScreenState extends ConsumerState<AdminFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _roleId = TextEditingController();
  bool _disabled = false;

  @override
  void dispose() {
    for (final c in [_username, _fullName, _email, _mobile, _password, _passwordConfirm, _roleId]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.goNamed('admins'),
                icon: const Icon(Icons.arrow_back),
              ),
              Text(
                widget.isEdit ? 'تعديل مدير' : 'مدير جديد',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTokens.navy900,
                    ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('endpoint /api/admin/admins لم يُعرَض بعد على Flask.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ'),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'admin.core',
            icon: Icons.admin_panel_settings_outlined,
            title: 'بيانات الحساب',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'اسم المستخدم',
                  required: true,
                  child: TextFormField(
                    controller: _username,
                    enabled: !widget.isEdit,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                FormFieldRow(label: 'الاسم الكامل', child: TextFormField(controller: _fullName)),
                FormFieldRow(label: 'البريد', child: TextFormField(controller: _email)),
                FormFieldRow(label: 'الجوال', child: TextFormField(controller: _mobile)),
                FormFieldRow(
                  label: 'الدور',
                  hint: 'role_id من قائمة الأدوار',
                  child: TextFormField(
                    controller: _roleId,
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'معطّل',
                  child: Switch(
                    value: _disabled,
                    onChanged: (v) => setState(() => _disabled = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'admin.password',
            icon: Icons.password,
            title: widget.isEdit ? 'تغيير كلمة المرور (اختياري)' : 'كلمة المرور',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'كلمة المرور',
                  required: !widget.isEdit,
                  child: TextFormField(
                    controller: _password,
                    obscureText: true,
                    validator: (v) {
                      if (widget.isEdit && (v == null || v.isEmpty)) return null;
                      if (v == null || v.length < 8) return '8 أحرف على الأقل';
                      return null;
                    },
                  ),
                ),
                FormFieldRow(
                  label: 'تأكيد كلمة المرور',
                  required: !widget.isEdit,
                  child: TextFormField(
                    controller: _passwordConfirm,
                    obscureText: true,
                    validator: (v) {
                      if (widget.isEdit && (v == null || v.isEmpty)) return null;
                      if (v != _password.text) return 'غير متطابقة';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s40),
        ],
      ),
    );
  }
}
