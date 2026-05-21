// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/lifecycle_repository.dart';
import '../../domain/lifecycle_model.dart';

class LifecycleCreatePolicyCard extends StatefulWidget {
  const LifecycleCreatePolicyCard({super.key, required this.onCreated});
  final VoidCallback onCreated;

  @override
  State<LifecycleCreatePolicyCard> createState() =>
      _LifecycleCreatePolicyCardState();
}

class _LifecycleCreatePolicyCardState extends State<LifecycleCreatePolicyCard> {
  String _entityType = 'card';
  int _delayValue = 2;
  String _delayUnit = 'days';
  int _retentionValue = 90;
  String _retentionUnit = 'days';
  bool _enabled = true;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'إضافة سياسة أرشفة',
                style: TextStyle(
                  color: AppTokens.sidebarBg,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              Wrap(
                spacing: AppTokens.s12,
                runSpacing: AppTokens.s12,
                children: [
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<String>(
                      initialValue: _entityType,
                      decoration: const InputDecoration(labelText: 'النوع'),
                      items: const [
                        DropdownMenuItem(value: 'card', child: Text('بطاقة')),
                        DropdownMenuItem(
                          value: 'subscriber',
                          child: Text('مشترك'),
                        ),
                        DropdownMenuItem(
                          value: 'external_file',
                          child: Text('ملف خارجي'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _entityType = value ?? 'card'),
                    ),
                  ),
                  _NumberField(
                    label: 'بعد انتهاء بمدة',
                    value: _delayValue,
                    onChanged: (value) => _delayValue = value,
                  ),
                  _UnitField(
                    label: 'وحدة التأخير',
                    value: _delayUnit,
                    onChanged: (value) =>
                        setState(() => _delayUnit = value ?? 'days'),
                  ),
                  _NumberField(
                    label: 'الاحتفاظ في السلة',
                    value: _retentionValue,
                    onChanged: (value) => _retentionValue = value,
                  ),
                  _UnitField(
                    label: 'وحدة الاحتفاظ',
                    value: _retentionUnit,
                    onChanged: (value) =>
                        setState(() => _retentionUnit = value ?? 'days'),
                  ),
                  FilterChip(
                    selected: _enabled,
                    label: const Text('مفعّلة'),
                    onSelected: (value) => setState(() => _enabled = value),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : () => _save(ref),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_saving ? 'جار الحفظ...' : 'حفظ السياسة'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save(WidgetRef ref) async {
    setState(() => _saving = true);
    try {
      await ref.read(lifecycleRepositoryProvider).createPolicy(
            LifecyclePolicy(
              entityType: _entityType,
              triggerType: 'expired_at',
              delayValue: _delayValue,
              delayUnit: _delayUnit,
              action: 'archive',
              retentionValue: _retentionValue,
              retentionUnit: _retentionUnit,
              enabled: _enabled,
            ),
          );
      widget.onCreated();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ سياسة الأرشفة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: TextFormField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: widget.label),
        onChanged: (value) => widget.onChanged(int.tryParse(value) ?? 0),
      ),
    );
  }
}

class _UnitField extends StatelessWidget {
  const _UnitField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: const [
          DropdownMenuItem(value: 'minutes', child: Text('دقائق')),
          DropdownMenuItem(value: 'hours', child: Text('ساعات')),
          DropdownMenuItem(value: 'days', child: Text('أيام')),
          DropdownMenuItem(value: 'months', child: Text('أشهر')),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
