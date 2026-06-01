import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/mikrotik_providers.dart';
import '../data/mikrotik_repository.dart';
import '../domain/mikrotik_model.dart';
import 'widgets/mikrotik_config_card.dart';
import 'widgets/mikrotik_form_card.dart';

class MikrotikScreen extends ConsumerStatefulWidget {
  const MikrotikScreen({super.key});

  @override
  ConsumerState<MikrotikScreen> createState() => _MikrotikScreenState();
}

class _MikrotikScreenState extends ConsumerState<MikrotikScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _host = TextEditingController();
  final _port = TextEditingController(text: '8728');
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _timeout = TextEditingController(text: '10');

  MikrotikConfig? _editing;
  bool _formVisible = false;
  bool _useTls = false;
  bool _verifyTls = true;
  bool _enabled = true;
  bool _saving = false;
  bool _testingForm = false;
  final Set<int> _testingIds = {};

  @override
  void dispose() {
    for (final c in [_name, _host, _port, _username, _password, _timeout]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(mikrotikConfigsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'اتصالات MikroTik',
          subtitle:
              'إدارة بيانات اتصال API للراوترات واختبارها من التطبيق. كلمة المرور لا تظهر بعد الحفظ.',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(mikrotikConfigsProvider),
              icon: const Icon(Icons.refresh),
            ),
            ElevatedButton.icon(
              onPressed: _startCreate,
              icon: const Icon(Icons.add),
              label: const Text('اتصال جديد'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        if (_formVisible) ...[
          MikrotikFormCard(
            formKey: _formKey,
            editing: _editing,
            name: _name,
            host: _host,
            port: _port,
            username: _username,
            password: _password,
            timeout: _timeout,
            useTls: _useTls,
            verifyTls: _verifyTls,
            enabled: _enabled,
            saving: _saving,
            testing: _testingForm,
            onUseTlsChanged: _setUseTls,
            onVerifyTlsChanged: (v) => setState(() => _verifyTls = v),
            onEnabledChanged: (v) => setState(() => _enabled = v),
            onCancel: _hideForm,
            onSave: _save,
            onTest: _testFormCredentials,
          ),
          const SizedBox(height: AppTokens.s16),
        ],
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب اتصالات MikroTik',
            subtitle: '$error',
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(mikrotikConfigsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.router_outlined,
                title: 'لا توجد اتصالات MikroTik بعد',
                subtitle:
                    'أضف أول اتصال لاختبار الراوتر وربطه بعمليات RADIUS/MikroTik.',
                action: ElevatedButton.icon(
                  onPressed: _startCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('اتصال جديد'),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items) ...[
                  MikrotikConfigCard(
                    config: item,
                    testing: item.id != null && _testingIds.contains(item.id),
                    onEdit: () => _startEdit(item),
                    onTest: item.id == null ? null : () => _testSaved(item),
                    onDelete:
                        item.id == null ? null : () => _confirmDelete(item),
                  ),
                  const SizedBox(height: AppTokens.s12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  void _startCreate() {
    setState(() {
      _editing = null;
      _formVisible = true;
      _name.clear();
      _host.clear();
      _port.text = '8728';
      _username.clear();
      _password.clear();
      _timeout.text = '10';
      _useTls = false;
      _verifyTls = true;
      _enabled = true;
    });
  }

  void _startEdit(MikrotikConfig config) {
    setState(() {
      _editing = config;
      _formVisible = true;
      _name.text = config.name;
      _host.text = config.host;
      _port.text = '${config.port}';
      _username.text = config.username;
      _password.clear();
      _timeout.text = '${config.timeoutSec}';
      _useTls = config.useTls;
      _verifyTls = config.verifyTls;
      _enabled = config.enabled;
    });
  }

  void _hideForm() {
    setState(() {
      _formVisible = false;
      _editing = null;
      _saving = false;
      _testingForm = false;
    });
  }

  void _setUseTls(bool value) {
    setState(() {
      final currentPort = int.tryParse(_port.text.trim()) ?? 0;
      _useTls = value;
      if (currentPort == 8728 || currentPort == 8729 || currentPort == 0) {
        _port.text = value ? '8729' : '8728';
      }
    });
  }

  MikrotikConfig _configFromForm() {
    return MikrotikConfig(
      id: _editing?.id,
      name: _name.text.trim().isEmpty ? _host.text.trim() : _name.text.trim(),
      host: _host.text.trim(),
      port: int.tryParse(_port.text.trim()) ?? (_useTls ? 8729 : 8728),
      username: _username.text.trim(),
      useTls: _useTls,
      verifyTls: _verifyTls,
      timeoutSec: int.tryParse(_timeout.text.trim()) ?? 10,
      enabled: _enabled,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_editing == null && _password.text.trim().isEmpty) {
      _show('كلمة المرور مطلوبة عند إضافة اتصال جديد.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(mikrotikRepositoryProvider);
      final config = _configFromForm();
      if (_editing == null) {
        await repo.create(config, password: _password.text);
      } else {
        await repo.update(config, password: _password.text);
      }
      ref.invalidate(mikrotikConfigsProvider);
      if (!mounted) return;
      _show(_editing == null ? 'تمت إضافة الاتصال.' : 'تم حفظ التعديلات.');
      _hideForm();
    } catch (error) {
      _show('$error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _testFormCredentials() async {
    if (_testingForm) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_password.text.trim().isEmpty) {
      _show('اكتب كلمة المرور لاختبار البيانات قبل الحفظ.', error: true);
      return;
    }
    setState(() => _testingForm = true);
    try {
      final result = await ref
          .read(mikrotikRepositoryProvider)
          .testCredentials(_configFromForm(), password: _password.text);
      if (!mounted) return;
      _showTestResult(result);
    } catch (error) {
      _show('$error', error: true);
    } finally {
      if (mounted) setState(() => _testingForm = false);
    }
  }

  Future<void> _testSaved(MikrotikConfig config) async {
    final id = config.id;
    if (id == null || _testingIds.contains(id)) return;
    setState(() => _testingIds.add(id));
    try {
      final result = await ref.read(mikrotikRepositoryProvider).test(id);
      if (!mounted) return;
      _showTestResult(result);
    } catch (error) {
      _show('$error', error: true);
    } finally {
      if (mounted) setState(() => _testingIds.remove(id));
    }
  }

  Future<void> _confirmDelete(MikrotikConfig config) async {
    final id = config.id;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف اتصال MikroTik'),
        content: Text(
          'سيتم حذف بيانات الاتصال "${config.name}". هذا لا يحذف NAS ولا يطرد أي مستخدم من الشبكة.',
        ),
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
    try {
      await ref.read(mikrotikRepositoryProvider).delete(id);
      ref.invalidate(mikrotikConfigsProvider);
      _show('تم حذف الاتصال.');
    } catch (error) {
      _show('$error', error: true);
    }
  }

  void _showTestResult(MikrotikTestResult result) {
    final details = [
      if (result.boardName.isNotEmpty) 'الجهاز: ${result.boardName}',
      if (result.version.isNotEmpty) 'الإصدار: ${result.version}',
      if (result.uptime.isNotEmpty) 'مدة التشغيل: ${result.uptime}',
      if (result.cpuLoad.isNotEmpty) 'حمل المعالج: ${result.cpuLoad}%',
    ];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(result.connected ? 'الاتصال ناجح' : 'تعذر الاتصال'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.displayName),
            if (details.isNotEmpty) ...[
              const SizedBox(height: AppTokens.s12),
              for (final line in details)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(line),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _show(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? AppTokens.red : AppTokens.green,
        content: Text(message),
      ),
    );
  }
}
