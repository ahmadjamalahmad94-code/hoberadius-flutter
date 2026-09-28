import 'package:flutter/material.dart';
import 'package:hoberadius_app/core/format/input_rules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/hub_switch_row.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/distributors_repository.dart';
import '../domain/distributor_model.dart';
import 'distributors_list_screen.dart';

class DistributorFormScreen extends ConsumerStatefulWidget {
  const DistributorFormScreen({super.key});

  @override
  ConsumerState<DistributorFormScreen> createState() =>
      _DistributorFormScreenState();
}

class _DistributorFormScreenState extends ConsumerState<DistributorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _creditLimit = TextEditingController(text: '0');
  final _notes = TextEditingController();

  final Set<String> _permissions = {'cards.read', 'cards.sell'};
  String _status = 'active';
  bool _saving = false;

  static const _permissionOptions = [
    _PermissionOption(
      key: 'cards.read',
      label: 'عرض الكروت والحزم',
      description: 'يسمح للموزع برؤية الحزم المرتبطة به ومتابعة حالتها.',
    ),
    _PermissionOption(
      key: 'cards.sell',
      label: 'بيع الكروت',
      description: 'يسمح بتنفيذ عمليات البيع ضمن الحزم المسموحة فقط.',
    ),
  ];

  @override
  void dispose() {
    _name.dispose();
    _displayName.dispose();
    _email.dispose();
    _phone.dispose();
    _creditLimit.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nameField = TextFormField(
      controller: _name,
      decoration: const InputDecoration(
        labelText: 'اسم الدخول',
        helperText: 'اسم قصير تستخدمه الإدارة لتتبع الموزع داخليًا.',
      ),
      validator: (value) =>
          (value ?? '').trim().isEmpty ? 'اكتب اسم الدخول' : null,
    );
    final displayNameField = TextFormField(
      controller: _displayName,
      decoration: const InputDecoration(labelText: 'الاسم الظاهر'),
    );
    final phoneField = TextFormField(
      controller: _phone,
      decoration: const InputDecoration(labelText: 'رقم الهاتف'),
    );
    final emailField = TextFormField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
      validator: validateOptionalEmail,
    );
    final statusField = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _status,
      decoration: const InputDecoration(labelText: 'الحالة'),
      items: const [
        DropdownMenuItem(value: 'active', child: Text('مفعّل')),
        DropdownMenuItem(value: 'inactive', child: Text('غير مفعّل')),
        DropdownMenuItem(value: 'blocked', child: Text('محظور')),
      ],
      onChanged: (value) => setState(() => _status = value ?? 'active'),
    );
    final creditField = TextFormField(
      controller: _creditLimit,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'حد الائتمان'),
      validator: (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return null;
        final n = num.tryParse(t.replaceAll(',', '.'));
        if (n == null || !n.isFinite || n < 0) {
          return 'حد الائتمان رقم صفر أو أكثر.';
        }
        if (n > 1000000000) return 'حد الائتمان كبير جدًا.';
        return null;
      },
    );
    const creditHint = Text(
      'حد الائتمان قيمة مرجعية للتحكم المالي، وليست فاتورة كاملة.',
      style: TextStyle(color: AppTokens.textMuted, fontSize: 12),
    );
    final permissions = _ChoiceSection(
      title: 'صلاحيات الموزع',
      subtitle: 'اختر ما يستطيع الموزع عمله بدل كتابة رموز تقنية.',
      children: [
        for (final option in _permissionOptions)
          HubSwitchRow(
            dense: true,
            label: option.label,
            subtitle: option.description,
            value: _permissions.contains(option.key),
            onChanged: (checked) {
              setState(() {
                if (checked) {
                  _permissions.add(option.key);
                } else {
                  _permissions.remove(option.key);
                }
              });
            },
          ),
      ],
    );
    const scope = _ChoiceSection(
      title: 'نطاق البيانات',
      subtitle: 'النظام يعرض للموزع الحزم التي تربطها به الإدارة فقط.',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 20,
              color: AppTokens.brandInk,
            ),
            SizedBox(width: AppTokens.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الحزم المعيّنة فقط',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'لتوسيع وصول الموزع، اربط حزمًا إضافية من صفحة تفاصيل الموزع.',
                    style: TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
    final notesField = TextFormField(
      controller: _notes,
      minLines: 2,
      maxLines: 4,
      decoration: const InputDecoration(labelText: 'ملاحظات'),
    );
    final saveItem = ActionItem(
      icon: Icons.save,
      label: _saving ? 'جار الحفظ' : 'حفظ الموزع',
      primary: true,
      onPressed: _saving ? null : _save,
    );

    return Form(
      key: _formKey,
      // Errors re-check while typing: «اكتب اسم الدخول» no longer stays
      // after the field is filled.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'إضافة موزع',
            inlineActions: true,
            leading: IconButton(
              tooltip: 'رجوع',
              onPressed: _saving ? null : () => context.goNamed('distributors'),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              SizedBox(
                width: 96,
                child: HubActionButton(
                  item: ActionItem(
                    icon: Icons.save,
                    label: 'حفظ',
                    primary: true,
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.s12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 760;
                  if (!wide) {
                    // Phones: short fields in pairs to halve the height.
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        nameField,
                        const SizedBox(height: AppTokens.s12),
                        FormFieldPair(
                          first: displayNameField,
                          second: phoneField,
                        ),
                        const SizedBox(height: AppTokens.s12),
                        emailField,
                        const SizedBox(height: AppTokens.s12),
                        FormFieldPair(first: statusField, second: creditField),
                        const SizedBox(height: AppTokens.s4),
                        creditHint,
                        const SizedBox(height: AppTokens.s12),
                        permissions,
                        const SizedBox(height: AppTokens.s12),
                        scope,
                        const SizedBox(height: AppTokens.s12),
                        notesField,
                      ],
                    );
                  }
                  return Wrap(
                    spacing: AppTokens.s16,
                    runSpacing: AppTokens.s16,
                    children: [
                      _Box(wide: wide, child: nameField),
                      _Box(wide: wide, child: displayNameField),
                      _Box(wide: wide, child: phoneField),
                      _Box(wide: wide, child: emailField),
                      _Box(wide: wide, child: statusField),
                      _Box(
                        wide: wide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            creditField,
                            const SizedBox(height: AppTokens.s4),
                            creditHint,
                          ],
                        ),
                      ),
                      SizedBox(width: double.infinity, child: permissions),
                      const SizedBox(width: double.infinity, child: scope),
                      SizedBox(width: double.infinity, child: notesField),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          ActionBar(items: [saveItem]),
        ],
      ),
    );
  }

  Map<String, dynamic> _scopePayload() => const {'card_batches': 'assigned'};

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_permissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر صلاحية واحدة على الأقل للموزع.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final permissions = _permissions.toList()..sort();
      final created = await ref.read(distributorsRepositoryProvider).create(
            Distributor(
              name: _name.text.trim(),
              displayName: _displayName.text.trim(),
              email: _email.text.trim(),
              phone: _phone.text.trim(),
              status: _status,
              permissions: permissions,
              scope: _scopePayload(),
              creditLimit: num.tryParse(_creditLimit.text) ?? 0,
              notes: _notes.text.trim(),
            ),
          );
      ref.invalidate(distributorsListProvider);
      if (mounted) {
        context.goNamed(
          'distributor-detail',
          pathParameters: {'id': '${created.id}'},
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(visibleErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTokens.bg,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.border),
      ),
      // Transparent Material so child ListTiles have a Material ancestor for
      // their ink without painting over the DecoratedBox background.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTokens.sidebarBg,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTokens.textMuted,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: AppTokens.s4),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionOption {
  const _PermissionOption({
    required this.key,
    required this.label,
    required this.description,
  });

  final String key;
  final String label;
  final String description;
}

class _Box extends StatelessWidget {
  const _Box({required this.wide, required this.child});

  final bool wide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 320 : double.infinity,
      child: child,
    );
  }
}
