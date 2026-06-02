import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'إضافة موزع',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                      ),
                ),
              ),
              OutlinedButton.icon(
                onPressed:
                    _saving ? null : () => context.goNamed('distributors'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('رجوع'),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 760;
                  return Wrap(
                    spacing: AppTokens.s16,
                    runSpacing: AppTokens.s16,
                    children: [
                      _Box(
                        wide: wide,
                        child: TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'اسم الدخول',
                            helperText:
                                'اسم قصير تستخدمه الإدارة لتتبع الموزع داخليًا.',
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'اكتب اسم الدخول'
                              : null,
                        ),
                      ),
                      _Box(
                        wide: wide,
                        child: TextFormField(
                          controller: _displayName,
                          decoration: const InputDecoration(
                            labelText: 'الاسم الظاهر',
                          ),
                        ),
                      ),
                      _Box(
                        wide: wide,
                        child: TextFormField(
                          controller: _phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف',
                          ),
                        ),
                      ),
                      _Box(
                        wide: wide,
                        child: TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                          ),
                        ),
                      ),
                      _Box(
                        wide: wide,
                        child: DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'الحالة',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'active',
                              child: Text('مفعّل'),
                            ),
                            DropdownMenuItem(
                              value: 'inactive',
                              child: Text('غير مفعّل'),
                            ),
                            DropdownMenuItem(
                              value: 'blocked',
                              child: Text('محظور'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _status = value ?? 'active'),
                        ),
                      ),
                      _Box(
                        wide: wide,
                        child: TextFormField(
                          controller: _creditLimit,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'حد الائتمان',
                            helperText:
                                'قيمة مرجعية للتحكم المالي، وليست فاتورة كاملة.',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: _ChoiceSection(
                          title: 'صلاحيات الموزع',
                          subtitle:
                              'اختر ما يستطيع الموزع عمله بدل كتابة رموز تقنية.',
                          children: _permissionOptions
                              .map(
                                (option) => CheckboxListTile(
                                  value: _permissions.contains(option.key),
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _permissions.add(option.key);
                                      } else {
                                        _permissions.remove(option.key);
                                      }
                                    });
                                  },
                                  title: Text(option.label),
                                  subtitle: Text(option.description),
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: _ChoiceSection(
                          title: 'نطاق البيانات',
                          subtitle:
                              'النظام يعرض للموزع الحزم التي تربطها به الإدارة فقط.',
                          children: const [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.verified_user_outlined),
                              title: Text('الحزم المعيّنة فقط'),
                              subtitle: Text(
                                'لتوسيع وصول الموزع، اربط حزمًا إضافية من صفحة تفاصيل الموزع.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          controller: _notes,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'جار الحفظ' : 'حفظ الموزع'),
            ),
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
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
            const SizedBox(height: AppTokens.s4),
            Text(subtitle, style: const TextStyle(color: AppTokens.textMuted)),
            const SizedBox(height: AppTokens.s8),
            ...children,
          ],
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
