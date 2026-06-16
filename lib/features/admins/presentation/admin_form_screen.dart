import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/admins_repository.dart';
import '../domain/admin_model.dart';

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
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _tags = TextEditingController();
  final _avatar = TextEditingController();

  int? _roleId;
  bool _isSuperAdmin = false;
  bool _enabled = true;
  Admin? _loaded;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadExisting();
  }

  @override
  void dispose() {
    for (final c in [
      _username,
      _fullName,
      _email,
      _mobile,
      _phone,
      _password,
      _passwordConfirm,
      _tags,
      _avatar,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final a =
          await ref.read(adminsRepositoryProvider).getAdmin(widget.adminId!);
      _populate(a);
    } catch (e) {
      setState(() => _error = visibleErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _populate(Admin a) {
    _loaded = a;
    _username.text = a.username;
    _fullName.text = a.fullName;
    _email.text = a.email;
    _mobile.text = a.mobile;
    _phone.text = a.phone;
    _tags.text = a.tags;
    _avatar.text = a.avatarUrl;
    setState(() {
      _roleId = a.roleId;
      _isSuperAdmin = a.isSuperAdmin;
      _enabled = a.enabled;
    });
  }

  Admin _build() {
    final base = _loaded ?? Admin(username: _username.text.trim());
    return base.copyWith(
      username: _username.text.trim(),
      fullName: _fullName.text.trim(),
      email: _email.text.trim(),
      mobile: _mobile.text.trim(),
      phone: _phone.text.trim(),
      tags: _tags.text.trim(),
      avatarUrl: _avatar.text.trim(),
      roleId: _roleId,
      clearRoleId: _roleId == null,
      isSuperAdmin: _isSuperAdmin,
      enabled: _enabled,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminsRepositoryProvider);
      final admin = _build();
      if (widget.isEdit) {
        await repo.updateAdmin(
          widget.adminId!,
          admin,
          pendingPassword: _password.text,
        );
      } else {
        await repo.createAdmin(admin, _password.text);
      }
      ref.invalidate(adminsListProvider);
      if (mounted) context.goNamed('admins');
    } catch (e) {
      setState(() => _error = visibleErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المدير'),
        content: Text('سيُحذف "${_username.text}" نهائيًا. متأكّد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTokens.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(adminsRepositoryProvider).deleteAdmin(widget.adminId!);
      ref.invalidate(adminsListProvider);
      if (mounted) context.goNamed('admins');
    } catch (e) {
      setState(() => _error = visibleErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncRoles = ref.watch(rolesListProvider);
    final isProtectedSuper = _loaded?.isSuperAdmin == true;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: widget.isEdit ? 'تعديل مدير' : 'مدير جديد',
            leading: IconButton(
              onPressed: () => context.goNamed('admins'),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              if (_loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (widget.isEdit && !isProtectedSuper)
                IconButton(
                  tooltip: 'أرشفة المدير',
                  onPressed: _loading ? null : _delete,
                  icon: const Icon(Icons.delete_outline, color: AppTokens.red),
                ),
              ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTokens.s12),
            Container(
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: AppTokens.dangerBg,
                borderRadius: BorderRadius.circular(AppTokens.r10),
              ),
              child:
                  Text(_error!, style: const TextStyle(color: AppTokens.red)),
            ),
          ],
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'admin.core',
            icon: Icons.person_outline,
            title: 'البيانات الأساسية',
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
                FormFieldRow(
                  label: 'الاسم الكامل',
                  child: TextFormField(controller: _fullName),
                ),
                FormFieldRow(
                  label: 'البريد',
                  child: TextFormField(controller: _email),
                ),
                FormFieldRow(
                  label: 'الجوال',
                  child: TextFormField(controller: _mobile),
                ),
                FormFieldRow(
                  label: 'هاتف إضافي',
                  child: TextFormField(controller: _phone),
                ),
                FormFieldRow(
                  label: 'رابط الصورة الرمزية',
                  hint: 'https://…',
                  child: TextFormField(
                    controller: _avatar,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                FormFieldRow(
                  label: 'الوسوم والملاحظات',
                  hint: 'قِيَم مفصولة بفواصل',
                  child: TextFormField(controller: _tags),
                ),
                FormFieldRow(
                  label: 'الدور',
                  child: asyncRoles.when(
                    loading: () => const LinearProgressIndicator(minHeight: 4),
                    error: (e, _) => TextFormField(
                      enabled: false,
                      decoration:
                          InputDecoration(labelText: visibleErrorMessage(e)),
                    ),
                    data: (roles) => DropdownButtonFormField<int?>(
                      initialValue:
                          roles.any((r) => r.id == _roleId) ? _roleId : null,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('— بدون دور —'),
                        ),
                        ...roles.map(
                          (r) => DropdownMenuItem<int?>(
                            value: r.id,
                            child: Text(r.label),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _roleId = v),
                    ),
                  ),
                ),
                FormFieldRow(
                  label: 'مدير عام كامل الصلاحيات',
                  child: Switch(
                    value: _isSuperAdmin,
                    onChanged: isProtectedSuper
                        ? null
                        : (v) => setState(() => _isSuperAdmin = v),
                  ),
                ),
                FormFieldRow(
                  label: 'مفعّل',
                  child: Switch(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'admin.password',
            icon: Icons.password,
            title:
                widget.isEdit ? 'تغيير كلمة المرور (اختياري)' : 'كلمة المرور',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'كلمة المرور',
                  required: !widget.isEdit,
                  child: TextFormField(
                    controller: _password,
                    obscureText: true,
                    validator: (v) {
                      if (widget.isEdit && (v == null || v.isEmpty)) {
                        return null;
                      }
                      if (v == null || v.length < 4) return '4 أحرف على الأقل';
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
                      if (widget.isEdit && (v == null || v.isEmpty)) {
                        return null;
                      }
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
