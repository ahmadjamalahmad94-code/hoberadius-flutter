import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/form_field_row.dart';

class NasFormScreen extends ConsumerStatefulWidget {
  const NasFormScreen({super.key, this.nasId});
  final int? nasId;
  bool get isEdit => nasId != null;

  @override
  ConsumerState<NasFormScreen> createState() => _NasFormScreenState();
}

class _NasFormScreenState extends ConsumerState<NasFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _ip = TextEditingController();
  final _secret = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();
  final _authPort = TextEditingController(text: '1812');
  final _acctPort = TextEditingController(text: '1813');
  final _apiPort = TextEditingController(text: '8728');
  final _snmpCommunity = TextEditingController(text: 'public');

  String _nasType = 'mikrotik';
  String _snmpVersion = 'v2c';
  bool _disabled = false;

  @override
  void dispose() {
    for (final c in [_name, _ip, _secret, _location, _notes, _authPort, _acctPort, _apiPort, _snmpCommunity]) {
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
                onPressed: () => context.goNamed('nas'),
                icon: const Icon(Icons.arrow_back),
              ),
              Text(
                widget.isEdit ? 'تعديل جهاز' : 'جهاز جديد',
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
                        content: Text('endpoint NAS CUD لم يُعرَض بعد على Flask.'),
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
            storageKey: 'nas.core',
            icon: Icons.router_outlined,
            title: 'البيانات الأساسية',
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
                  label: 'عنوان IP',
                  required: true,
                  hint: 'مثال: 10.0.0.1',
                  child: TextFormField(
                    controller: _ip,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                FormFieldRow(
                  label: 'النوع',
                  child: DropdownButtonFormField<String>(
                    value: _nasType,
                    items: const [
                      DropdownMenuItem(value: 'mikrotik', child: Text('MikroTik')),
                      DropdownMenuItem(value: 'cisco', child: Text('Cisco')),
                      DropdownMenuItem(value: 'ubnt', child: Text('Ubiquiti')),
                      DropdownMenuItem(value: 'huawei', child: Text('Huawei')),
                      DropdownMenuItem(value: 'other', child: Text('أخرى')),
                    ],
                    onChanged: (v) => setState(() => _nasType = v ?? 'mikrotik'),
                  ),
                ),
                FormFieldRow(
                  label: 'الموقع',
                  child: TextFormField(controller: _location),
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
            storageKey: 'nas.radius',
            icon: Icons.lock_outline,
            title: 'إعدادات RADIUS',
            child: Column(
              children: [
                FormFieldRow(
                  label: 'المفتاح المشترك',
                  required: true,
                  hint: 'shared secret بين الجهاز و RADIUS',
                  child: TextFormField(
                    controller: _secret,
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                FormFieldRow(
                  label: 'منفذ المصادقة',
                  child: TextFormField(
                    controller: _authPort,
                    keyboardType: TextInputType.number,
                  ),
                ),
                FormFieldRow(
                  label: 'منفذ المحاسبة',
                  child: TextFormField(
                    controller: _acctPort,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'nas.api',
            icon: Icons.api,
            title: 'API الراوتر',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(
                  label: 'منفذ API',
                  hint: 'MikroTik افتراضي: 8728',
                  child: TextFormField(
                    controller: _apiPort,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'nas.snmp',
            icon: Icons.settings_remote,
            title: 'SNMP',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(
                  label: 'Community',
                  child: TextFormField(controller: _snmpCommunity),
                ),
                FormFieldRow(
                  label: 'الإصدار',
                  child: DropdownButtonFormField<String>(
                    value: _snmpVersion,
                    items: const [
                      DropdownMenuItem(value: 'v1', child: Text('v1')),
                      DropdownMenuItem(value: 'v2c', child: Text('v2c')),
                      DropdownMenuItem(value: 'v3', child: Text('v3')),
                    ],
                    onChanged: (v) => setState(() => _snmpVersion = v ?? 'v2c'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          CollapsibleSection(
            storageKey: 'nas.notes',
            icon: Icons.notes,
            title: 'ملاحظات',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(label: 'ملاحظات', child: TextFormField(controller: _notes, maxLines: 3)),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s40),
        ],
      ),
    );
  }
}
