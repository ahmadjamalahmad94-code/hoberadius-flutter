import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              'الأجهزة خلف الراوترات مثل نقاط الوصول والسويتشات والكاميرات والخوادم. المسح يقرأ الأجهزة فقط، والتجهيز يضيف قواعد موثوقة على الراوتر بعد مراجعتك.',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(networkDevicesProvider),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
            async.maybeWhen(
              data: (state) => OutlinedButton.icon(
                onPressed:
                    state.routers.isEmpty ? null : () => _openScan(state),
                icon: const Icon(Icons.radar_outlined),
                label: const Text('مسح الشبكة'),
              ),
              orElse: () => const SizedBox.shrink(),
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
              onBypass: () => _openBypass(item),
              onRemoteAccess: () => _openRemoteAccess(item),
              onDelete: () => _delete(item),
            ),
            const SizedBox(height: AppTokens.s12),
          ],
      ],
    );
  }

  Future<void> _openScan(NetworkDevicesState state) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _NetworkScanDialog(routers: state.routers),
    );
    if (changed == true) ref.invalidate(networkDevicesProvider);
  }

  Future<void> _openBypass(NetworkDevice item) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _NetworkDeviceBypassDialog(device: item),
    );
    if (changed == true) ref.invalidate(networkDevicesProvider);
  }

  Future<void> _openRemoteAccess(NetworkDevice item) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _NetworkRemoteAccessDialog(device: item),
    );
    ref.invalidate(networkDevicesProvider);
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(device == null ? 'تمت إضافة الجهاز' : 'تم حفظ الجهاز'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
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
          childAspectRatio: cols == 4 ? 2.1 : 1.7,
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
    required this.onBypass,
    required this.onRemoteAccess,
    required this.onDelete,
  });

  final NetworkDevice item;
  final bool checking;
  final VoidCallback onCheck;
  final VoidCallback onEdit;
  final VoidCallback onBypass;
  final VoidCallback onRemoteAccess;
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
                onPressed: item.address.isEmpty || item.physicalAddress.isEmpty
                    ? null
                    : onBypass,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('تجهيز على الراوتر'),
              ),
              OutlinedButton.icon(
                onPressed: item.address.isEmpty ? null : onRemoteAccess,
                icon: const Icon(Icons.key_outlined),
                label: const Text('وصول مؤقت'),
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

class _NetworkScanDialog extends ConsumerStatefulWidget {
  const _NetworkScanDialog({required this.routers});

  final List<NetworkDeviceRouter> routers;

  @override
  ConsumerState<_NetworkScanDialog> createState() => _NetworkScanDialogState();
}

class _NetworkScanDialogState extends ConsumerState<_NetworkScanDialog> {
  late int _routerId;
  bool _loading = false;
  bool _changed = false;
  String? _error;
  NetworkScanResult? _result;
  final Set<String> _adding = {};
  final Set<String> _added = {};

  @override
  void initState() {
    super.initState();
    _routerId = widget.routers.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('مسح الشبكة'),
      content: SizedBox(
        width: _dialogWidth(context, 720),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'المسح يقرأ ARP و DHCP والجيران من الراوتر المحدد ولا يغيّر إعدادات الراوتر.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTokens.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTokens.s12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final selector = DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _routerId,
                    decoration:
                        const InputDecoration(labelText: 'اختر الراوتر'),
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
                    onChanged: _loading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _routerId = value);
                            }
                          },
                  );
                  final button = FilledButton.icon(
                    onPressed: _loading ? null : _scan,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.radar_outlined),
                    label: Text(_loading ? 'جار المسح' : 'ابدأ المسح'),
                  );
                  if (constraints.maxWidth < 520) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        selector,
                        const SizedBox(height: AppTokens.s8),
                        button,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: selector),
                      const SizedBox(width: AppTokens.s8),
                      button,
                    ],
                  );
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: AppTokens.s12),
                _NoticeBox(
                  icon: Icons.error_outline,
                  text: _error!,
                  tone: PillTone.red,
                ),
              ],
              const SizedBox(height: AppTokens.s12),
              _scanBody(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_changed),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  Widget _scanBody() {
    final result = _result;
    if (_loading && result == null) {
      return const Padding(
        padding: EdgeInsets.all(AppTokens.s20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (result == null) {
      return const _NoticeBox(
        icon: Icons.info_outline,
        text: 'اختر الراوتر ثم ابدأ المسح لعرض الأجهزة المكتشفة.',
        tone: PillTone.blue,
      );
    }
    if (result.items.isEmpty) {
      return const EmptyState(
        icon: Icons.devices_other_outlined,
        title: 'لم يتم العثور على أجهزة',
        subtitle:
            'تأكد أن بيانات API للراوتر صحيحة وأن الأجهزة ظاهرة في ARP أو DHCP.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            StatusPill(
              text: 'تم العثور على ${result.items.length} جهاز',
              tone: PillTone.blue,
              dot: true,
            ),
            StatusPill(
              text: 'موجود مسبقًا ${result.knownIps.length}',
              tone: PillTone.neutral,
              dot: true,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        for (final item in result.items) ...[
          _ScanItemRow(
            item: item,
            adding: _adding.contains(item.address),
            added: _added.contains(item.address),
            onAdd: () => _addItem(item),
          ),
          const SizedBox(height: AppTokens.s8),
        ],
      ],
    );
  }

  Future<void> _scan() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(networkDevicesRepositoryProvider)
          .scanRouter(_routerId);
      if (!mounted) return;
      setState(() {
        _result = result;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addItem(NetworkScanItem item) async {
    setState(() {
      _adding.add(item.address);
      _error = null;
    });
    try {
      await ref.read(networkDevicesRepositoryProvider).addScannedDevice(
            routerId: _routerId,
            item: item,
          );
      if (!mounted) return;
      setState(() {
        _changed = true;
        _added.add(item.address);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = visibleErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _adding.remove(item.address));
      }
    }
  }
}

class _ScanItemRow extends StatelessWidget {
  const _ScanItemRow({
    required this.item,
    required this.adding,
    required this.added,
    required this.onAdd,
  });

  final NetworkScanItem item;
  final bool adding;
  final bool added;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final alreadyAdded = item.known || added;
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.devices_other_outlined, color: AppTokens.brand),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: const TextStyle(
                    color: AppTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: AppTokens.s8,
                  runSpacing: AppTokens.s8,
                  children: [
                    _InfoChip(Icons.lan_outlined, item.address),
                    if (item.physicalAddress.isNotEmpty)
                      _InfoChip(Icons.badge_outlined, item.physicalAddress),
                    if (item.interfaceName.isNotEmpty)
                      _InfoChip(
                        Icons.settings_input_component_outlined,
                        item.interfaceName,
                      ),
                    if (item.vendor.isNotEmpty)
                      _InfoChip(Icons.business_outlined, item.vendor),
                    if (item.sources.isNotEmpty)
                      _InfoChip(Icons.hub_outlined, item.sources.join('، ')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          OutlinedButton.icon(
            onPressed: alreadyAdded || adding ? null : onAdd,
            icon: adding
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(alreadyAdded ? Icons.check : Icons.add),
            label: Text(alreadyAdded ? 'مضاف' : 'إضافة'),
          ),
        ],
      ),
    );
  }
}

class _NetworkRemoteAccessDialog extends ConsumerStatefulWidget {
  const _NetworkRemoteAccessDialog({required this.device});

  final NetworkDevice device;

  @override
  ConsumerState<_NetworkRemoteAccessDialog> createState() =>
      _NetworkRemoteAccessDialogState();
}

class _NetworkRemoteAccessDialogState
    extends ConsumerState<_NetworkRemoteAccessDialog> {
  final _notes = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _notice;
  String _protocol = 'http';
  int _ttlMinutes = 30;
  NetworkRemoteAccessState? _state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('وصول مؤقت للجهاز'),
      content: SizedBox(
        width: _dialogWidth(context, 760),
        child: SingleChildScrollView(child: _body()),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
        FilledButton.icon(
          onPressed: _busy || _state == null || widget.device.address.isEmpty
              ? null
              : _open,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.key_outlined),
          label: Text(_busy ? 'جار التنفيذ' : 'فتح جلسة'),
        ),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppTokens.s20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NoticeBox(
            icon: Icons.error_outline,
            text: _error!,
            tone: PillTone.red,
          ),
          const SizedBox(height: AppTokens.s12),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      );
    }
    final state = _state;
    if (state == null) {
      return const _NoticeBox(
        icon: Icons.info_outline,
        text: 'لا توجد بيانات وصول لهذا الجهاز.',
        tone: PillTone.neutral,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'الجلسة تفتح منفذًا مؤقتًا عبر خادم الربط ثم تُغلق من الراوتر والخادم عند انتهاء المدة أو عند إغلاقها يدويًا.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTokens.textSecondary,
                height: 1.45,
              ),
        ),
        const SizedBox(height: AppTokens.s12),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            _InfoChip(Icons.devices_other_outlined, state.device.name),
            _InfoChip(Icons.lan_outlined, state.device.address),
            _InfoChip(Icons.router_outlined, state.router.name),
            _InfoChip(
              Icons.public_outlined,
              state.publicHost.isEmpty
                  ? 'عنوان خادم الربط غير مضبوط'
                  : state.publicHost,
            ),
          ],
        ),
        if (!state.configReady) ...[
          const SizedBox(height: AppTokens.s12),
          const _NoticeBox(
            icon: Icons.warning_outlined,
            text:
                'عنوان خادم الربط العام غير مضبوط على الخادم. يمكن إنشاء الجلسة، لكن رابط الوصول لن يظهر كاملًا حتى يتم ضبطه.',
            tone: PillTone.amber,
          ),
        ],
        if (_notice != null) ...[
          const SizedBox(height: AppTokens.s12),
          _NoticeBox(
            icon: Icons.check_circle_outline,
            text: _notice!,
            tone: PillTone.green,
          ),
        ],
        const Divider(height: AppTokens.s24),
        LayoutBuilder(
          builder: (context, constraints) {
            final protocol = DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _protocol,
              decoration: const InputDecoration(labelText: 'نوع الوصول'),
              items: [
                for (final option in state.allowedProtocols)
                  DropdownMenuItem(
                    value: option.key,
                    child: Text(option.label),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _protocol = value ?? _protocol),
            );
            final ttl = DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _ttlMinutes,
              decoration: const InputDecoration(labelText: 'مدة الجلسة'),
              items: [
                for (final option in state.ttlOptions)
                  DropdownMenuItem(
                    value: option.minutes,
                    child: Text(option.label),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) =>
                      setState(() => _ttlMinutes = value ?? _ttlMinutes),
            );
            if (constraints.maxWidth < 560) {
              return Column(
                children: [
                  protocol,
                  const SizedBox(height: AppTokens.s12),
                  ttl,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: protocol),
                const SizedBox(width: AppTokens.s12),
                Expanded(child: ttl),
              ],
            );
          },
        ),
        const SizedBox(height: AppTokens.s12),
        TextField(
          controller: _notes,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'سبب الجلسة أو ملاحظة',
            hintText: 'مثال: صيانة نقطة وصول في الطابق الثاني',
          ),
        ),
        const Divider(height: AppTokens.s24),
        Text(
          'الجلسات الحالية والسابقة',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppTokens.sidebarBg,
              ),
        ),
        const SizedBox(height: AppTokens.s12),
        if (state.sessions.isEmpty)
          const EmptyState(
            icon: Icons.key_outlined,
            title: 'لا توجد جلسات بعد',
            subtitle:
                'افتح جلسة مؤقتة عند الحاجة فقط، وستظهر هنا للمتابعة أو الإغلاق.',
          )
        else
          for (final session in state.sessions) ...[
            _RemoteAccessSessionRow(
              session: session,
              busy: _busy,
              onCopy: session.bestAccessText.isEmpty
                  ? null
                  : () => _copySession(session),
              onClose: session.active ? () => _close(session) : null,
            ),
            const SizedBox(height: AppTokens.s8),
          ],
      ],
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final state = await ref
          .read(networkDevicesRepositoryProvider)
          .remoteAccessState(widget.device.id);
      if (!mounted) return;
      setState(() {
        _state = state;
        if (state.allowedProtocols.any((option) => option.key == _protocol) ==
            false) {
          _protocol = state.allowedProtocols.isEmpty
              ? 'http'
              : state.allowedProtocols.first.key;
        }
        if (state.ttlOptions.any((option) => option.minutes == _ttlMinutes) ==
            false) {
          _ttlMinutes =
              state.ttlOptions.isEmpty ? 30 : state.ttlOptions.first.minutes;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open() async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final state =
          await ref.read(networkDevicesRepositoryProvider).openRemoteAccess(
                widget.device.id,
                protocol: _protocol,
                ttlMinutes: _ttlMinutes,
                notes: _notes.text.trim(),
              );
      if (!mounted) return;
      setState(() {
        _state = state;
        _notice = state.session?.bestAccessText.isNotEmpty == true
            ? 'تم فتح الجلسة. رابط الوصول: ${state.session!.bestAccessText}'
            : (state.message.isEmpty ? 'تم فتح الجلسة.' : state.message);
        _notes.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close(NetworkRemoteAccessSession session) async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final state = await ref
          .read(networkDevicesRepositoryProvider)
          .closeRemoteAccess(widget.device.id, session.id);
      if (!mounted) return;
      setState(() {
        _state = state;
        _notice = state.message.isEmpty ? 'تم إغلاق الجلسة.' : state.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copySession(NetworkRemoteAccessSession session) async {
    await Clipboard.setData(ClipboardData(text: session.bestAccessText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ بيانات الوصول')),
    );
  }
}

class _RemoteAccessSessionRow extends StatelessWidget {
  const _RemoteAccessSessionRow({
    required this.session,
    required this.busy,
    required this.onCopy,
    required this.onClose,
  });

  final NetworkRemoteAccessSession session;
  final bool busy;
  final VoidCallback? onCopy;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'جلسة #${session.id} - ${session.protocolLabel}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTokens.sidebarBg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.bestAccessText.isEmpty
                          ? 'المنفذ الخارجي ${session.externalPort}'
                          : session.bestAccessText,
                      style: const TextStyle(
                        color: AppTokens.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                text: session.statusLabel,
                tone: session.active ? PillTone.green : PillTone.neutral,
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              if (session.internalIp.isNotEmpty)
                _InfoChip(
                  Icons.lan_outlined,
                  '${session.internalIp}:${session.internalPort}',
                ),
              if (session.expiresAt.isNotEmpty)
                _InfoChip(Icons.timer_outlined, 'تنتهي ${session.expiresAt}'),
              if (session.requestedBy.isNotEmpty)
                _InfoChip(Icons.person_outline, session.requestedBy),
              if (session.notes.isNotEmpty)
                _InfoChip(Icons.notes_outlined, session.notes),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : onCopy,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('نسخ الوصول'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onClose,
                icon: const Icon(Icons.close_outlined),
                label: const Text('إغلاق الآن'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetworkDeviceBypassDialog extends ConsumerStatefulWidget {
  const _NetworkDeviceBypassDialog({required this.device});

  final NetworkDevice device;

  @override
  ConsumerState<_NetworkDeviceBypassDialog> createState() =>
      _NetworkDeviceBypassDialogState();
}

class _NetworkDeviceBypassDialogState
    extends ConsumerState<_NetworkDeviceBypassDialog> {
  bool _loading = true;
  bool _busy = false;
  bool _changed = false;
  bool _bypassHotspot = true;
  bool _addToAddressList = true;
  String? _error;
  String? _notice;
  String _dhcpServerName = '';
  NetworkDeviceBypassState? _state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تجهيز الجهاز على الراوتر'),
      content: SizedBox(
        width: _dialogWidth(context, 680),
        child: SingleChildScrollView(child: _body()),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(_changed),
          child: const Text('إغلاق'),
        ),
        OutlinedButton.icon(
          onPressed: _busy || _state == null ? null : _remove,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: const Text('إزالة التجهيز'),
        ),
        FilledButton.icon(
          onPressed: _busy || _state?.ready != true || _dhcpServerName.isEmpty
              ? null
              : _apply,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_user_outlined),
          label: Text(_busy ? 'جار التنفيذ' : 'تنفيذ التجهيز'),
        ),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppTokens.s20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NoticeBox(
            icon: Icons.error_outline,
            text: _error!,
            tone: PillTone.red,
          ),
          const SizedBox(height: AppTokens.s12),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      );
    }
    final state = _state;
    if (state == null) {
      return const _NoticeBox(
        icon: Icons.info_outline,
        text: 'لا توجد بيانات تجهيز لهذا الجهاز.',
        tone: PillTone.neutral,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'التجهيز يضيف lease ثابت، ويمكنه إضافة IP binding وقائمة عناوين للأجهزة الموثوقة.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTokens.textSecondary,
              ),
        ),
        const SizedBox(height: AppTokens.s12),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            _InfoChip(Icons.devices_other_outlined, state.device.name),
            _InfoChip(Icons.lan_outlined, state.device.address),
            _InfoChip(Icons.badge_outlined, state.device.physicalAddress),
            _InfoChip(Icons.router_outlined, state.router.name),
            if (state.addressListName.isNotEmpty)
              _InfoChip(Icons.list_alt_outlined, state.addressListName),
          ],
        ),
        if (!state.ready) ...[
          const SizedBox(height: AppTokens.s12),
          const _NoticeBox(
            icon: Icons.warning_outlined,
            text:
                'احفظ عنوان الجهاز والعنوان الفيزيائي قبل تنفيذ التجهيز على الراوتر.',
            tone: PillTone.amber,
          ),
        ],
        if (state.dhcpError.isNotEmpty) ...[
          const SizedBox(height: AppTokens.s12),
          _NoticeBox(
            icon: Icons.warning_outlined,
            text: state.dhcpError,
            tone: PillTone.amber,
          ),
        ],
        const SizedBox(height: AppTokens.s12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _dhcpServerName.isEmpty ? null : _dhcpServerName,
          decoration: const InputDecoration(labelText: 'خادم DHCP'),
          items: [
            for (final server in state.dhcpServers)
              DropdownMenuItem(
                value: server.name,
                enabled: !server.disabled,
                child: Text(
                  server.interfaceName.isEmpty
                      ? server.name
                      : '${server.name} - ${server.interfaceName}',
                ),
              ),
          ],
          onChanged: _busy
              ? null
              : (value) {
                  if (value != null) {
                    setState(() => _dhcpServerName = value);
                  }
                },
        ),
        const SizedBox(height: AppTokens.s8),
        SwitchListTile(
          value: _bypassHotspot,
          onChanged:
              _busy ? null : (value) => setState(() => _bypassHotspot = value),
          title: const Text('تجاوز الهوتسبوت للجهاز الموثوق'),
          subtitle:
              const Text('يضيف IP binding للجهاز حتى لا يمر بصفحة الدخول.'),
        ),
        SwitchListTile(
          value: _addToAddressList,
          onChanged: _busy
              ? null
              : (value) => setState(() => _addToAddressList = value),
          title: const Text('إضافة إلى قائمة العناوين'),
          subtitle:
              const Text('يفيد قواعد الجدار الناري أو الاستثناءات لاحقًا.'),
        ),
        if (_notice != null) ...[
          const SizedBox(height: AppTokens.s12),
          _NoticeBox(
            icon: Icons.check_circle_outline,
            text: _notice!,
            tone: PillTone.green,
          ),
        ],
      ],
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final state = await ref
          .read(networkDevicesRepositoryProvider)
          .bypassState(widget.device.id);
      if (!mounted) return;
      final enabledServers =
          state.dhcpServers.where((server) => !server.disabled).toList();
      setState(() {
        _state = state;
        _dhcpServerName =
            enabledServers.isEmpty ? '' : enabledServers.first.name;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apply() async {
    setState(() {
      _busy = true;
      _notice = null;
      _error = null;
    });
    try {
      final result =
          await ref.read(networkDevicesRepositoryProvider).applyBypass(
                widget.device.id,
                dhcpServerName: _dhcpServerName,
                bypassHotspot: _bypassHotspot,
                addToAddressList: _addToAddressList,
              );
      if (!mounted) return;
      setState(() {
        _changed = true;
        _notice = result.message.isEmpty ? 'تم تنفيذ التجهيز.' : result.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() {
      _busy = true;
      _notice = null;
      _error = null;
    });
    try {
      final result = await ref
          .read(networkDevicesRepositoryProvider)
          .removeBypass(widget.device.id);
      if (!mounted) return;
      setState(() {
        _changed = true;
        _notice = result.message.isEmpty
            ? 'تمت إزالة التجهيز من الراوتر.'
            : result.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _NoticeBox extends StatelessWidget {
  const _NoticeBox({
    required this.icon,
    required this.text,
    required this.tone,
  });

  final IconData icon;
  final String text;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (tone) {
      PillTone.green => (
          AppTokens.greenSoft,
          AppTokens.greenInk,
          AppTokens.successMed,
        ),
      PillTone.amber || PillTone.orange => (
          AppTokens.amberSoft,
          AppTokens.amberInk,
          AppTokens.warningMed,
        ),
      PillTone.red => (
          AppTokens.redSoft,
          AppTokens.redInk,
          AppTokens.dangerMed,
        ),
      PillTone.blue => (
          AppTokens.blueSoft,
          AppTokens.blueInk,
          AppTokens.infoMed,
        ),
      _ => (
          AppTokens.surfaceMuted,
          AppTokens.textSecondary,
          AppTokens.border,
        ),
    };
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: fg, fontWeight: FontWeight.w700),
            ),
          ),
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
      title: Text(
        widget.device == null ? 'إضافة جهاز مراقبة' : 'تعديل جهاز مراقبة',
      ),
      content: SizedBox(
        width: _dialogWidth(context, 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _routerId,
                decoration:
                    const InputDecoration(labelText: 'الراوتر التابع له'),
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
                isExpanded: true,
                initialValue: _deviceType,
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

double _dialogWidth(BuildContext context, double maxWidth) {
  final available = MediaQuery.sizeOf(context).width - 48;
  if (available < 280) return 280;
  return available > maxWidth ? maxWidth : available;
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
