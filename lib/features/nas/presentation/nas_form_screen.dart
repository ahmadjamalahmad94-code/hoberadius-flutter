import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/format/number_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/hub_switch_row.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/nas_repository.dart';
import '../domain/nas_model.dart';
import 'nas_list_screen.dart';

class NasFormScreen extends ConsumerStatefulWidget {
  const NasFormScreen({super.key, this.nasId});
  final int? nasId;
  bool get isEdit => nasId != null;

  @override
  ConsumerState<NasFormScreen> createState() => _NasFormScreenState();
}

class _NasFormScreenState extends ConsumerState<NasFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;

  String _vendor = 'mikrotik';
  String _nasType = 'hotspot';
  String _rosVersion = '';
  bool _enabled = true;
  bool _monitoring = true;
  bool _apiUseTls = false;
  bool _requireMessageAuth = false;
  NasDevice? _loaded;

  bool _loading = false;
  bool _testing = false;
  String? _error;

  static const _fields = <String>[
    'name',
    'address',
    'shortname',
    'location',
    'coordinates',
    'description',
    'snmp_community',
    'tags',
    'api_user',
    'secret',
    'api_password',
    'auth_port',
    'acct_port',
    'coa_port',
    'api_port',
    'ssh_port',
    'ports',
  ];

  @override
  void initState() {
    super.initState();
    _c = {for (final k in _fields) k: TextEditingController()};
    _c['auth_port']!.text = '1812';
    _c['acct_port']!.text = '1813';
    _c['coa_port']!.text = '3799';
    _c['api_port']!.text = '8728';
    _c['ssh_port']!.text = '22';
    // parity-c: no «public» default — the web form starts empty.
    if (widget.isEdit) _loadExisting();
  }

  @override
  void dispose() {
    for (final ctrl in _c.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final d = await ref.read(nasRepositoryProvider).get(widget.nasId!);
      _populate(d);
    } catch (e) {
      setState(() => _error = visibleErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _populate(NasDevice d) {
    _loaded = d;
    _c['name']!.text = d.name;
    _c['address']!.text = d.address;
    _c['shortname']!.text = d.shortname;
    _c['location']!.text = d.location;
    _c['coordinates']!.text = d.coordinates;
    _c['description']!.text = d.description;
    _c['snmp_community']!.text = d.snmpCommunity;
    _c['tags']!.text = d.tags;
    _c['api_user']!.text = d.apiUser;
    _c['auth_port']!.text = d.authPort.toString();
    _c['acct_port']!.text = d.acctPort.toString();
    _c['coa_port']!.text = d.coaPort.toString();
    _c['api_port']!.text = d.apiPort.toString();
    _c['ssh_port']!.text = d.sshPort.toString();
    _c['ports']!.text = d.ports.toString();
    // Secret/api_password are not returned by the server. Leave the form
    // fields empty — typing a new value rotates them; leaving empty keeps
    // the previously-stored value.
    setState(() {
      _vendor = d.vendor;
      _nasType = kNasTypeLabels.containsKey(d.nasType) ? d.nasType : 'other';
      _rosVersion =
          const {'', '6', '7'}.contains(d.rosVersion) ? d.rosVersion : '';
      _enabled = d.enabled;
      _monitoring = d.monitoringEnabled;
      _apiUseTls = d.apiUseTls;
      _requireMessageAuth = d.requireMessageAuthenticator;
    });
  }

  int _i(String key) => parseIntInput(_c[key]!.text) ?? 0;

  static const _portKeys = [
    'auth_port',
    'acct_port',
    'coa_port',
    'api_port',
    'ssh_port',
    'ports',
  ];

  /// The server said this router NAME is taken (409 `nas_name_conflict`):
  /// shown under the name field, cleared when the name is edited.
  String? _nameError;
  String _s(String key) => _c[key]!.text.trim();

  NasDevice _build() {
    final base = _loaded ?? NasDevice(name: '', address: '');
    return base.copyWith(
      name: _s('name'),
      address: _s('address'),
      vendor: _vendor,
      nasType: _nasType,
      shortname: _s('shortname'),
      ports: _i('ports'),
      snmpCommunity: _s('snmp_community'),
      authPort: _i('auth_port'),
      acctPort: _i('acct_port'),
      coaPort: _i('coa_port'),
      apiPort: _i('api_port'),
      apiUser: _s('api_user'),
      apiUseTls: _apiUseTls,
      location: _s('location'),
      coordinates: _s('coordinates'),
      monitoringEnabled: _monitoring,
      description: _s('description'),
      enabled: _enabled,
      requireMessageAuthenticator: _requireMessageAuth,
      sshPort: _i('ssh_port'),
      tags: _s('tags'),
      rosVersion: _rosVersion,
      blankPorts: {
        for (final k in _portKeys)
          if (_c[k]!.text.trim().isEmpty) k,
      },
      pendingSecret: _s('secret'),
      pendingApiPassword: _s('api_password'),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final device = _build();
      final repo = ref.read(nasRepositoryProvider);
      if (widget.isEdit) {
        await repo.update(widget.nasId!, device);
      } else {
        await repo.create(device);
      }
      ref.invalidate(nasListProvider);
      if (mounted) context.goNamed('nas');
    } catch (e) {
      setState(() {
        if (isNasNameConflict(e)) {
          _nameError = visibleErrorMessage(e);
          _error = null;
        } else {
          _error = formSaveErrorMessage(e);
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _test() async {
    if (!widget.isEdit) return;
    setState(() => _testing = true);
    try {
      final r = await ref.read(nasRepositoryProvider).test(widget.nasId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: r.ok ? AppTokens.green : AppTokens.red,
          content: Text(
            r.ok
                ? 'نجح: ${r.ip}:${r.port} في ${r.ms} ms'
                : '${r.status}: ${r.message}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      useRootNavigator: true,
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الجهاز'),
        content: Text('سيُحذف "${_c['name']!.text}" نهائيًا. متأكّد؟'),
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
      await ref.read(nasRepositoryProvider).delete(widget.nasId!);
      ref.invalidate(nasListProvider);
      if (mounted) context.goNamed('nas');
    } catch (e) {
      setState(() => _error = visibleErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Empty = the server default (like the web); otherwise 1–65535
  /// («عدد المنافذ» may be 0).
  Widget _portField(String label, String key) => FormFieldRow(
        label: label,
        child: TextFormField(
          controller: _c[key],
          keyboardType: TextInputType.number,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? null
              : validateNumberInput(
                  v,
                  decimal: false,
                  min: key == 'ports' ? 0 : 1,
                  max: 65535,
                ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: widget.isEdit ? 'تعديل جهاز' : 'جهاز جديد',
            inlineActions: true,
            leading: IconButton(
              onPressed: () => context.goNamed('nas'),
              tooltip: 'رجوع',
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              if (_loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ'),
              ),
            ],
          ),
          if (widget.isEdit) ...[
            const SizedBox(height: AppTokens.s8),
            ActionBar(
              items: [
                ActionItem(
                  icon: _testing ? Icons.hourglass_top : Icons.network_check,
                  label: _testing ? 'جارٍ الاختبار…' : 'اختبار الاتصال',
                  onPressed: (_loading || _testing) ? null : _test,
                ),
                if (ref.watch(permissionsProvider).can('nas.delete'))
                  ActionItem(
                    icon: Icons.delete_outline,
                    label: 'حذف الجهاز',
                    tone: PillTone.red,
                    onPressed: _loading ? null : _delete,
                  ),
              ],
            ),
          ],
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
          const SizedBox(height: AppTokens.s12),
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
                    controller: _c['name'],
                    decoration: InputDecoration(errorText: _nameError),
                    onChanged: (_) {
                      if (_nameError != null) {
                        setState(() => _nameError = null);
                      }
                    },
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                FormFieldRow(
                  label: 'العنوان',
                  required: true,
                  hint: 'عنوان IP أو اسم الخادم',
                  child: TextFormField(
                    controller: _c['address'],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                FormFieldPair(
                  first: FormFieldRow(
                    label: 'الشركة',
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _vendor,
                      items: const [
                        DropdownMenuItem(
                          value: 'mikrotik',
                          child: Text('ميكروتك'),
                        ),
                        DropdownMenuItem(value: 'cisco', child: Text('Cisco')),
                        DropdownMenuItem(
                          value: 'huawei',
                          child: Text('Huawei'),
                        ),
                        DropdownMenuItem(
                          value: 'ubiquiti',
                          child: Text('Ubiquiti'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('أخرى')),
                      ],
                      onChanged: (v) =>
                          setState(() => _vendor = v ?? 'mikrotik'),
                    ),
                  ),
                  // parity-c: the server's list (services/devices.py
                  // NAS_TYPES_ALLOWED) with the web labels — «wireless»
                  // was app-only and always refused (422).
                  second: FormFieldRow(
                    label: 'النوع',
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _nasType,
                      items: [
                        for (final e in kNasTypeLabels.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                      ],
                      onChanged: (v) =>
                          setState(() => _nasType = v ?? 'hotspot'),
                    ),
                  ),
                ),
                FormFieldRow(
                  label: 'إصدار RouterOS',
                  hint: 'يحدّد صيغة أمر نفق الإدارة في سكربت التهيئة. '
                      'اتركه «غير محدّد» ولن تستطيع توليد السكربت حتى تختار.',
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _rosVersion,
                    items: const [
                      DropdownMenuItem(value: '', child: Text('غير محدّد')),
                      DropdownMenuItem(
                        value: '7',
                        child: Text('RouterOS 7 (وأحدث)'),
                      ),
                      DropdownMenuItem(
                        value: '6',
                        child: Text('RouterOS 6 (قديم)'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _rosVersion = v ?? ''),
                  ),
                ),
                FormFieldPair(
                  first: FormFieldRow(
                    label: 'الاسم المختصر',
                    child: TextFormField(controller: _c['shortname']),
                  ),
                  second: FormFieldRow(
                    label: 'الموقع',
                    child: TextFormField(controller: _c['location']),
                  ),
                ),
                FormFieldPair(
                  first: FormFieldRow(
                    label: 'الإحداثيات',
                    hint: 'lat,lng',
                    child: TextFormField(controller: _c['coordinates']),
                  ),
                  second: FormFieldRow(
                    label: 'وسوم',
                    hint: 'بفواصل',
                    child: TextFormField(controller: _c['tags']),
                  ),
                ),
                FormFieldRow(
                  label: 'الوصف',
                  child:
                      TextFormField(controller: _c['description'], maxLines: 2),
                ),
                HubSwitchRow(
                  label: 'مفعّل',
                  dense: true,
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
                HubSwitchRow(
                  label: 'المراقبة',
                  dense: true,
                  value: _monitoring,
                  onChanged: (v) => setState(() => _monitoring = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          CollapsibleSection(
            storageKey: 'nas.secret',
            icon: Icons.lock_outline,
            title: 'المفتاح المشترك',
            child: Column(
              children: [
                FormFieldRow(
                  label: widget.isEdit
                      ? 'تحديث المفتاح (اتركه فارغًا للإبقاء)'
                      : 'المفتاح المشترك',
                  required: !widget.isEdit,
                  child: TextFormField(
                    controller: _c['secret'],
                    obscureText: true,
                    validator: (v) {
                      if (widget.isEdit) return null;
                      if (v == null || v.isEmpty) return 'مطلوب';
                      return null;
                    },
                  ),
                ),
                _PortsRow(
                  children: [
                    _portField('منفذ المصادقة', 'auth_port'),
                    _portField('منفذ المحاسبة', 'acct_port'),
                    _portField('منفذ CoA', 'coa_port'),
                  ],
                ),
                HubSwitchRow(
                  label: 'يتطلّب Message-Authenticator',
                  dense: true,
                  value: _requireMessageAuth,
                  onChanged: (v) => setState(() => _requireMessageAuth = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          CollapsibleSection(
            storageKey: 'nas.api',
            icon: Icons.api,
            title: 'واجهة الراوتر البرمجية',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldPair(
                  first: FormFieldRow(
                    label: 'منفذ الواجهة',
                    hint: 'افتراضي 8728',
                    child: TextFormField(
                      controller: _c['api_port'],
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  second: FormFieldRow(
                    label: 'مستخدم الواجهة',
                    child: TextFormField(controller: _c['api_user']),
                  ),
                ),
                FormFieldRow(
                  label: widget.isEdit
                      ? 'تحديث كلمة واجهة الراوتر (اتركه فارغًا للإبقاء)'
                      : 'كلمة مرور واجهة الراوتر',
                  child: TextFormField(
                    controller: _c['api_password'],
                    obscureText: true,
                  ),
                ),
                HubSwitchRow(
                  label: 'اتصال مشفّر',
                  dense: true,
                  value: _apiUseTls,
                  onChanged: (v) => setState(() => _apiUseTls = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          CollapsibleSection(
            storageKey: 'nas.snmp',
            icon: Icons.settings_remote,
            title: 'المراقبة والدخول الآمن',
            initiallyExpanded: false,
            child: Column(
              children: [
                FormFieldRow(
                  label: 'مجتمع SNMP',
                  child: TextFormField(controller: _c['snmp_community']),
                ),
                FormFieldPair(
                  first: _portField('منفذ SSH', 'ssh_port'),
                  second: _portField('عدد المنافذ', 'ports'),
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

/// `nas_type` values the server accepts, with the web form's labels.
const Map<String, String> kNasTypeLabels = {
  'hotspot': 'هوت سبوت',
  'pppoe': 'PPPoE',
  'dhcp': 'DHCP',
  'router': 'راوتر',
  'ap': 'نقطة وصول',
  'switch': 'سويتش',
  'firewall': 'جدار ناري',
  'other': 'أخرى',
};

/// Three short port fields on one row (aligned on their inputs).
class _PortsRow extends StatelessWidget {
  const _PortsRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: AppTokens.s8),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

/// A router-name clash from the server: 409 `nas_name_conflict` (fix2);
/// older servers answered a 500, so only the explicit code counts.
bool isNasNameConflict(Object? e) =>
    e is ApiException &&
    (e.code == 'nas_name_conflict' ||
        (e.status == 409 && e.message.contains('اسم الراوتر')));
