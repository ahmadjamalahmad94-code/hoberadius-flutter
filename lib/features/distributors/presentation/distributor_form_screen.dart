import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final _permissions = TextEditingController(text: 'cards.read, cards.sell');
  final _scope = TextEditingController(text: '{"card_batches":"assigned"}');
  final _creditLimit = TextEditingController(text: '0');
  final _notes = TextEditingController();

  String _status = 'active';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _displayName.dispose();
    _email.dispose();
    _phone.dispose();
    _permissions.dispose();
    _scope.dispose();
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
                        color: AppTokens.navy900,
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
                            helperText: 'اسم قصير يستخدم لتتبع الموزع داخليًا.',
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty
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
                          decoration:
                              const InputDecoration(labelText: 'رقم الهاتف'),
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
                          decoration:
                              const InputDecoration(labelText: 'الحالة'),
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
                          onChanged: (v) =>
                              setState(() => _status = v ?? 'active'),
                        ),
                      ),
                      _Box(
                        wide: wide,
                        child: TextFormField(
                          controller: _creditLimit,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'حد الائتمان',
                            helperText: 'قيمة مرجعية، وليست فوترة كاملة بعد.',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          controller: _permissions,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'الصلاحيات',
                            helperText:
                                'افصل الصلاحيات بفواصل. مثال: cards.read, cards.sell',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          controller: _scope,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'نطاق البيانات JSON',
                            helperText:
                                'الافتراضي يجعل الموزع يرى الحزم المربوطة به فقط.',
                          ),
                          validator: _validateScope,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          controller: _notes,
                          minLines: 2,
                          maxLines: 4,
                          decoration:
                              const InputDecoration(labelText: 'ملاحظات'),
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

  String? _validateScope(String? value) {
    try {
      final decoded = jsonDecode((value ?? '').trim().isEmpty ? '{}' : value!);
      if (decoded is! Map) return 'النطاق يجب أن يكون كائن JSON';
      return null;
    } catch (_) {
      return 'اكتب JSON صحيح';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final created = await ref.read(distributorsRepositoryProvider).create(
            Distributor(
              name: _name.text.trim(),
              displayName: _displayName.text.trim(),
              email: _email.text.trim(),
              phone: _phone.text.trim(),
              status: _status,
              permissions: _permissions.text
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toList(),
              scope: Map<String, dynamic>.from(jsonDecode(_scope.text)),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ الموزع: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
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
