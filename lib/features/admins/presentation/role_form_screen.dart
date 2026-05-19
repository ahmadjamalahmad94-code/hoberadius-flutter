import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/form_field_row.dart';

class RoleFormScreen extends ConsumerStatefulWidget {
  const RoleFormScreen({super.key, this.roleId});
  final int? roleId;
  bool get isEdit => roleId != null;

  @override
  ConsumerState<RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends ConsumerState<RoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final Set<String> _permissions = {};

  static const _permGroups = <String, List<(String, String)>>{
    'المشتركون': [
      ('subscribers.read', 'عرض'),
      ('subscribers.write', 'تعديل'),
      ('subscribers.delete', 'حذف'),
    ],
    'الباقات': [
      ('plans.read', 'عرض'),
      ('plans.write', 'تعديل'),
    ],
    'الكروت': [
      ('cards.read', 'عرض'),
      ('cards.generate', 'توليد'),
      ('cards.revoke', 'إلغاء'),
    ],
    'الأجهزة': [
      ('nas.read', 'عرض'),
      ('nas.write', 'تعديل'),
      ('nas.test', 'اختبار'),
    ],
    'الإدارة': [
      ('admins.read', 'عرض المدراء'),
      ('admins.write', 'تعديل المدراء'),
      ('roles.write', 'تعديل الأدوار'),
    ],
  };

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
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
                onPressed: () => context.goNamed('roles'),
                icon: const Icon(Icons.arrow_back),
              ),
              Text(
                widget.isEdit ? 'تعديل دور' : 'دور جديد',
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
                        content: Text('endpoint /api/admin/roles لم يُعرَض بعد على Flask.'),
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
            storageKey: 'role.core',
            icon: Icons.shield_outlined,
            title: 'بيانات الدور',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'الاسم',
                  required: true,
                  child: TextFormField(
                    controller: _name,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                FormFieldRow(
                  label: 'الوصف',
                  child: TextFormField(controller: _description, maxLines: 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'role.perms',
            icon: Icons.checklist_rtl,
            title: 'الصلاحيات',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _permGroups.entries.map((g) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTokens.navy800,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: g.value.map((p) {
                          final selected = _permissions.contains(p.$1);
                          return FilterChip(
                            label: Text(p.$2),
                            selected: selected,
                            onSelected: (v) => setState(() {
                              if (v) {
                                _permissions.add(p.$1);
                              } else {
                                _permissions.remove(p.$1);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppTokens.s40),
        ],
      ),
    );
  }
}
