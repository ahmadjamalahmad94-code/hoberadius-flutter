import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/network_devices_providers.dart';
import '../data/network_devices_repository.dart';
import '../domain/network_device_model.dart';

class NetworkDevicesScreen extends ConsumerStatefulWidget {
  const NetworkDevicesScreen({super.key});

  @override
  ConsumerState<NetworkDevicesScreen> createState() =>
      _NetworkDevicesScreenState();
}

class _NetworkDevicesScreenState extends ConsumerState<NetworkDevicesScreen> {
  final _search = TextEditingController();
  int? _checkingId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(networkDevicesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'مراقبة أجهزة الشبكة',
          subtitle:
              'الأجهزة خلف الراوترات مثل نقاط الوصول والسويتشات والكاميرات والخوادم. هذه الصفحة تدير السجل والفحص اليدوي ولا تنفذ قواعد على الراوتر.',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(networkDevicesProvider),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
            async.maybeWhen(
              data: (state) => ElevatedButton.icon(
                onPressed: state.routers.isEmpty
                    ? null
                    : () => _openForm(context, state.routers),
                icon: const Icon(Icons.add),
                label: const Text('إضافة جهاز'),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => HubErrorState(
            title: 'تعذر جلب أجهزة الشبكة',
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(networkDevicesProvider),
          ),
          data: _body,
        ),
      ],
    );
  }

  Widget _body(NetworkDevicesState state) {
    final filtered =
        state.items.where((item) => item.matches(_search.text)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryGrid(summary: state.summary),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'بحث',
              hintText: 'اسم الجهاز، العنوان، الموقع، الراوتر...',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        if (state.routers.isEmpty)
          const EmptyState(
            icon: Icons.router_outlined,
            title: 'أضف راوترًا أولًا',
            subtitle:
                'أجهزة المراقبة يجب أن ترتبط براوتر موجود حتى يعرف النظام أين توجد داخل الشبكة.',
          )
        else if (filtered.isEmpty)
          EmptyState(
            icon: Icons.devices_other_outlined,
            title: state.items.isEmpty
                ? 'لا توجد أجهزة مراقبة بعد'
                : 'لا توجد نتائج مطابقة',
            subtitle: state.items.isEmpty
                ? 'استخدم زر إضافة جهاز لتسجيل نقطة وصول أو كاميرا أو سويتش خلف الراوتر.'
                : 'غيّر كلمات البحث أو حدّث البيانات من أعلى الصفحة.',
          )
        else
          for (final item in filtered) ...[
            _NetworkDeviceCard(
              item: item,
              checking: _checkingId == item.id,
              onCheck: () => _checkNow(item),
              onEdit: () => _openForm(
                context,
                state.routers,
                device: item,
              ),
              onDelete: () => _delete(item),
            ),
            const SizedBox(height: AppTokens.s12),
          ],
      ],
    );
  }

  Future<void> _openForm(
    BuildContext context,
    List<NetworkDeviceRouter> routers, {
    NetworkDevice? device,
  }) async {
    final draft = await showDialog<NetworkDeviceDraft>(
      context: context,
      builder: (context) => _NetworkDeviceDialog(
        routers: routers,
        device: device,
      ),
    );
    if (draft == null) return;
    try {
      final repo = ref.read(networkDevicesRepositoryProvider);
      if (device == null) {
        await repo.create(draft);
      } else {
        await repo.update(device.id, draft);
      }
      ref.invalidate(networkDevicesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(device == null ? 'تمت إضافة الجهاز' : 'تم حفظ الجهاز'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    }
  }

  Future<void> _checkNow(NetworkDevice item) async {
    setState(() => _checkingId = item.id);
    try {
      final result =
          await ref.read(networkDevicesRepositoryProvider).checkNow(item.id);
      ref.invalidate(networkDevicesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.ok
                ? 'الجهاز يستجيب'
                : (result.message.isEmpty
                    ? 'تعذر الوصول إلى الجهاز'
                    : result.message),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _checkingId = null);
    }
  }

  Future<void> _delete(NetworkDevice item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف جهاز مراقبة'),
        content: Text(
          'سيتم حذف "${item.name}" من سجل المراقبة فقط. لن يتم تغيير إعدادات الراوتر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(networkDevicesRepositoryProvider).delete(item.id);
      ref.invalidate(networkDevicesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الجهاز')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    }
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final NetworkDevicesSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 900 ? 4 : 2;
        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: AppTokens.s8,
          mainAxisSpacing: AppTokens.s8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: cols == 4 ? 2.1 : 2.5,
          children: [
            _MetricCard('الإجمالي', '${summary.total}', Icons.devices_outlined),
            _MetricCard('تستجيب', '${summary.up}', Icons.check_circle_outline),
            _MetricCard('لا تستجيب', '${summary.down}', Icons.warning_outlined),
            _MetricCard('تحت المراقبة', '${summary.watched}', Icons.visibility),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Row(
        children: [
          Icon(icon, color: AppTokens.brand),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppTokens.textMuted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTokens.sidebarBg,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkDeviceCard extends StatelessWidget {
  const _NetworkDeviceCard({
    required this.item,
    required this.checking,
    required this.onCheck,
    required this.onEdit,
    required this.onDelete,
  });

  final NetworkDevice item;
  final bool checking;
  final VoidCallback onCheck;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: item.name,
      icon: _typeIcon(item.deviceType),
      actions: [
        StatusPill(
          text: item.lastStatusLabel.isEmpty
              ? _statusLabel(item.lastStatus)
              : item.lastStatusLabel,
          tone: _statusTone(item.lastStatus),
          dot: true,
        ),
        if (item.isCritical)
          const StatusPill(text: 'حرج', tone: PillTone.red, dot: true),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _InfoChip(Icons.category_outlined, item.deviceTypeLabel),
              _InfoChip(
                Icons.router_outlined,
                item.routerName.isEmpty ? 'راوتر غير محدد' : item.routerName,
              ),
              _InfoChip(
                Icons.lan_outlined,
                item.address.isEmpty ? 'عنوان الجهاز غير محدد' : item.address,
              ),
              _InfoChip(
                Icons.settings_input_component_outlined,
                'منفذ الإدارة ${item.managementPort}',
              ),
              if (item.location.isNotEmpty)
                _InfoChip(Icons.place_outlined, item.location),
              if (item.physicalAddress.isNotEmpty)
                _InfoChip(Icons.badge_outlined, item.physicalAddress),
            ],
          ),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            Text(
              item.notes,
              style: const TextStyle(color: AppTokens.textSecondary),
            ),
          ],
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              StatusPill(
                text: item.watchEnabled ? 'المراقبة مفعلة' : 'المراقبة متوقفة',
                tone: item.watchEnabled ? PillTone.green : PillTone.neutral,
                dot: true,
              ),
              StatusPill(
                text: item.alertEnabled ? 'التنبيه مفعّل' : 'التنبيه متوقف',
                tone: item.alertEnabled ? PillTone.amber : PillTone.neutral,
                dot: true,
              ),
              if (item.lastCheckedAt.isNotEmpty)
                StatusPill(
                  text: 'آخر فحص ${item.lastCheckedAt}',
                  tone: PillTone.blue,
                ),
              if (item.lastLatencyMs != null)
                StatusPill(
                  text: 'زمن الاستجابة ${item.lastLatencyMs} مللي ثانية',
                  tone: PillTone.green,
                ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              OutlinedButton.icon(
                onPressed: checking ? null : onCheck,
                icon: checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_check_outlined),
                label: Text(checking ? 'جار الفحص' : 'فحص الآن'),
              ),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل'),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('حذف'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTokens.textMuted),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppTokens.textSecondary)),
        ],
      ),
    );
  }
}

class _NetworkDeviceDialog extends StatefulWidget {
  const _NetworkDeviceDialog({
    required this.routers,
    this.device,
  });

  final List<NetworkDeviceRouter> routers;
  final NetworkDevice? device;

  @override
  State<_NetworkDeviceDialog> createState() => _NetworkDeviceDialogState();
}

class _NetworkDeviceDialogState extends State<_NetworkDeviceDialog> {
  late int _routerId;
  late String _deviceType;
  late bool _critical;
  late bool _watch;
  late bool _alert;
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _physicalAddress;
  late final TextEditingController _location;
  late final TextEditingController _port;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final draft = widget.device == null
        ? NetworkDeviceDraft(
            routerId: widget.routers.first.id,
            name: '',
            deviceType: 'other',
            address: '',
            physicalAddress: '',
            location: '',
            managementPort: 80,
            notes: '',
            isCritical: false,
            watchEnabled: false,
            alertEnabled: false,
          )
        : NetworkDeviceDraft.fromDevice(widget.device!);
    _routerId = draft.routerId;
    _deviceType = draft.deviceType;
    _critical = draft.isCritical;
    _watch = draft.watchEnabled;
    _alert = draft.alertEnabled;
    _name = TextEditingController(text: draft.name);
    _address = TextEditingController(text: draft.address);
    _physicalAddress = TextEditingController(text: draft.physicalAddress);
    _location = TextEditingController(text: draft.location);
    _port = TextEditingController(text: '${draft.managementPort}');
    _notes = TextEditingController(text: draft.notes);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _physicalAddress.dispose();
    _location.dispose();
    _port.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.device == null ? 'إضافة جهاز مراقبة' : 'تعديل جهاز مراقبة'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _routerId,
                decoration: const InputDecoration(labelText: 'الراوتر التابع له'),
                items: [
                  for (final router in widget.routers)
                    DropdownMenuItem(
                      value: router.id,
                      child: Text(
                        router.address.isEmpty
                            ? router.name
                            : '${router.name} - ${router.address}',
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _routerId = value);
                },
              ),
              const SizedBox(height: AppTokens.s12),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'اسم الجهاز'),
              ),
              const SizedBox(height: AppTokens.s12),
              DropdownButtonFormField<String>(
                value: _deviceType,
                decoration: const InputDecoration(labelText: 'نوع الجهاز'),
                items: const [
                  DropdownMenuItem(value: 'ap', child: Text('نقطة وصول')),
                  DropdownMenuItem(value: 'router', child: Text('راوتر')),
                  DropdownMenuItem(value: 'switch', child: Text('سويتش')),
                  DropdownMenuItem(value: 'camera', child: Text('كاميرا')),
                  DropdownMenuItem(value: 'nvr', child: Text('مسجل كاميرات')),
                  DropdownMenuItem(value: 'server', child: Text('خادم')),
                  DropdownMenuItem(value: 'other', child: Text('جهاز آخر')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _deviceType = value);
                },
              ),
              const SizedBox(height: AppTokens.s12),
              TextField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'عنوان الجهاز'),
              ),
              const SizedBox(height: AppTokens.s12),
              TextField(
                controller: _physicalAddress,
                decoration: const InputDecoration(
                  labelText: 'العنوان الفيزيائي',
                  hintText: 'اختياري',
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              TextField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'الموقع'),
              ),
              const SizedBox(height: AppTokens.s12),
              TextField(
                controller: _port,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'منفذ الإدارة'),
              ),
              const SizedBox(height: AppTokens.s12),
              TextField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
              const SizedBox(height: AppTokens.s12),
              SwitchListTile(
                value: _watch,
                onChanged: (value) => setState(() => _watch = value),
                title: const Text('تفعيل المراقبة'),
              ),
              SwitchListTile(
                value: _alert,
                onChanged: (value) => setState(() => _alert = value),
                title: const Text('تفعيل التنبيه'),
              ),
              SwitchListTile(
                value: _critical,
                onChanged: (value) => setState(() => _critical = value),
                title: const Text('جهاز حرج'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      NetworkDeviceDraft(
        routerId: _routerId,
        name: name,
        deviceType: _deviceType,
        address: _address.text,
        physicalAddress: _physicalAddress.text,
        location: _location.text,
        managementPort: int.tryParse(_port.text.trim()) ?? 80,
        notes: _notes.text,
        isCritical: _critical,
        watchEnabled: _watch,
        alertEnabled: _alert,
      ),
    );
  }
}

IconData _typeIcon(String type) {
  return switch (type) {
    'ap' => Icons.wifi_outlined,
    'router' => Icons.router_outlined,
    'switch' => Icons.settings_input_component_outlined,
    'camera' => Icons.videocam_outlined,
    'nvr' => Icons.video_library_outlined,
    'server' => Icons.dns_outlined,
    _ => Icons.devices_other_outlined,
  };
}

PillTone _statusTone(String status) {
  return switch (status) {
    'up' => PillTone.green,
    'down' => PillTone.red,
    _ => PillTone.neutral,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'up' => 'يستجيب',
    'down' => 'لا يستجيب',
    _ => 'غير مفحوص',
  };
}
