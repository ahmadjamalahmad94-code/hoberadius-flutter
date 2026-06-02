import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../data/admins_repository.dart';
import '../domain/admin_model.dart';

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
  final _displayName = TextEditingController();
  final _description = TextEditingController();
  final _color = TextEditingController(text: '#2BAACC');
  final Set<String> _permissions = {};
  Role? _loaded;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _displayName, _description, _color]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ref.read(adminsRepositoryProvider).getRole(widget.roleId!);
      _loaded = r;
      _name.text = r.name;
      _displayName.text = r.displayName;
      _description.text = r.description;
      _color.text = r.color;
      setState(() {
        _permissions
          ..clear()
          ..addAll(r.permissions);
      });
    } catch (e) {
      setState(() => _error = visibleErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminsRepositoryProvider);
      final role = Role(
        id: _loaded?.id,
        name: _name.text.trim(),
        displayName: _displayName.text.trim(),
        description: _description.text.trim(),
        color: _color.text.trim().isEmpty ? '#2BAACC' : _color.text.trim(),
        permissions: _permissions.toList(),
        isSystem: _loaded?.isSystem ?? false,
      );
      if (widget.isEdit) {
        await repo.updateRole(widget.roleId!, role);
      } else {
        await repo.createRole(role);
      }
      ref.invalidate(rolesListProvider);
      if (mounted) context.goNamed('roles');
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
        title: const Text('حذف الدور'),
        content: Text('سيُحذف "${_name.text}" نهائيًا. متأكّد؟'),
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
      await ref.read(adminsRepositoryProvider).deleteRole(widget.roleId!);
      ref.invalidate(rolesListProvider);
      if (mounted) context.goNamed('roles');
    } catch (e) {
      setState(() => _error = visibleErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSystem = _loaded?.isSystem ?? false;
    final asyncCatalog = ref.watch(permissionsCatalogProvider);
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
              Expanded(
                child: Text(
                  widget.isEdit ? 'تعديل دور' : 'دور جديد',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                      ),
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (widget.isEdit && !isSystem) ...[
                const SizedBox(width: AppTokens.s8),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: _loading ? null : _delete,
                  icon: const Icon(Icons.delete_outline, color: AppTokens.red),
                ),
              ],
              const SizedBox(width: AppTokens.s8),
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
              child: Text(_error!, style: const TextStyle(color: AppTokens.red)),
            ),
          ],
          if (isSystem) ...[
            const SizedBox(height: AppTokens.s12),
            Container(
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: AppTokens.warningBg,
                borderRadius: BorderRadius.circular(AppTokens.r10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: AppTokens.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'هذا دور نظامي — لا يمكن إعادة تسميته أو حذفه. تعديل الصلاحيات مسموح.',
                      style: TextStyle(color: AppTokens.sidebarBgElev1),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'role.core',
            icon: Icons.shield_outlined,
            title: 'بيانات الدور',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'المعرّف الداخلي (name)',
                  required: true,
                  child: TextFormField(
                    controller: _name,
                    enabled: !widget.isEdit,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                FormFieldRow(
                  label: 'اسم العرض',
                  child: TextFormField(controller: _displayName),
                ),
                FormFieldRow(
                  label: 'الوصف',
                  child: TextFormField(controller: _description, maxLines: 2),
                ),
                FormFieldRow(
                  label: 'لون',
                  hint: '#2BAACC',
                  child: TextFormField(controller: _color),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'role.perms',
            icon: Icons.checklist_rtl,
            title: 'الصلاحيات (${_permissions.length})',
            child: asyncCatalog.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppTokens.s20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(
                visibleErrorMessage(e),
                style: const TextStyle(color: AppTokens.red),
              ),
              data: (catalog) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: catalog.groups.map((g) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              g.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTokens.sidebarBgElev1,
                              ),
                            ),
                            const SizedBox(width: AppTokens.s8),
                            TextButton(
                              onPressed: () => setState(() {
                                _permissions.addAll(g.permissions);
                              }),
                              child: const Text('تحديد الكل'),
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                _permissions.removeAll(g.permissions);
                              }),
                              child: const Text('إلغاء'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: g.permissions.map((p) {
                            final selected = _permissions.contains(p);
                            return FilterChip(
                              label: Text(p),
                              selected: selected,
                              onSelected: (v) => setState(() {
                                if (v) {
                                  _permissions.add(p);
                                } else {
                                  _permissions.remove(p);
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
          ),
          const SizedBox(height: AppTokens.s40),
        ],
      ),
    );
  }
}
