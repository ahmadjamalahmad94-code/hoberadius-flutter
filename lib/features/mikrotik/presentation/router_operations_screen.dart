import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../nas/domain/nas_model.dart';
import '../application/mikrotik_providers.dart';
import '../domain/mikrotik_model.dart';

class RouterOperationsScreen extends ConsumerStatefulWidget {
  const RouterOperationsScreen({super.key});

  @override
  ConsumerState<RouterOperationsScreen> createState() =>
      _RouterOperationsScreenState();
}

class _RouterOperationsScreenState
    extends ConsumerState<RouterOperationsScreen> {
  int? _selectedRouterId;

  @override
  Widget build(BuildContext context) {
    final routersAsync = ref.watch(mikrotikRoutersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'عمليات الراوتر',
          subtitle:
              'متابعة حالة الراوتر الحية من عقد ميكروتك الموجود في الريدياس، مع إبقاء أوامر التغيير وإعادة التشغيل ضمن إجراءات محمية ومراجعة.',
          actions: [
            IconButton(
              tooltip: 'تحديث الراوترات',
              onPressed: () => ref.invalidate(mikrotikRoutersProvider),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        routersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => HubErrorState(
            title: 'تعذر جلب الراوترات',
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(mikrotikRoutersProvider),
          ),
          data: _body,
        ),
      ],
    );
  }

  Widget _body(List<NasDevice> routers) {
    final available = routers.where((router) => router.id != null).toList();
    if (available.isEmpty) {
      return const EmptyState(
        icon: Icons.router_outlined,
        title: 'لا توجد راوترات مسجلة',
        subtitle:
            'أضف جهاز شبكة من صفحة أجهزة الشبكة ثم ارجع إلى هنا لمتابعة الحالة الحية.',
      );
    }

    final selectedId = _selectedRouterId ?? available.first.id!;
    if (_selectedRouterId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedRouterId = selectedId);
      });
    }
    final selected = available.firstWhere(
      (router) => router.id == selectedId,
      orElse: () => available.first,
    );
    final overviewAsync =
        ref.watch(mikrotikRouterOverviewProvider(selected.id!));
    final liveAsync = ref.watch(mikrotikLiveSnapshotProvider(selected.id!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selected.id,
                  decoration: const InputDecoration(labelText: 'الراوتر'),
                  items: [
                    for (final router in available)
                      DropdownMenuItem(
                        value: router.id,
                        child: Text('${router.name} - ${router.address}'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRouterId = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              IconButton(
                tooltip: 'تحديث الحالة',
                onPressed: () {
                  ref.invalidate(mikrotikRouterOverviewProvider(selected.id!));
                  ref.invalidate(mikrotikLiveSnapshotProvider(selected.id!));
                },
                icon: const Icon(Icons.sync),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        overviewAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => HubErrorState(
            title: 'تعذر قراءة حالة الراوتر',
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(
              mikrotikRouterOverviewProvider(selected.id!),
            ),
          ),
          data: (overview) => _OverviewBody(overview: overview),
        ),
        const SizedBox(height: AppTokens.s16),
        liveAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => HubErrorState(
            title: 'تعذر قراءة تفاصيل الراوتر',
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(
              mikrotikLiveSnapshotProvider(selected.id!),
            ),
          ),
          data: (snapshot) => _LiveSnapshotPanel(
            snapshot: snapshot,
            onRefresh: () => ref.invalidate(
              mikrotikLiveSnapshotProvider(selected.id!),
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewBody extends StatelessWidget {
  const _OverviewBody({required this.overview});

  final MikrotikRouterOverview overview;

  @override
  Widget build(BuildContext context) {
    final resource = overview.section('resource')?.firstRow ?? const {};
    final identity = overview.section('identity')?.firstRow ?? const {};
    final routerboard = overview.section('routerboard')?.firstRow ?? const {};
    final displayName = (identity['name'] ?? overview.name).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          title: displayName.isEmpty ? 'راوتر بدون اسم' : displayName,
          icon: Icons.router_outlined,
          actions: [
            StatusPill(
              text: overview.anyOk ? 'متصل' : 'غير متصل',
              tone: overview.anyOk ? PillTone.green : PillTone.red,
              dot: true,
            ),
            StatusPill(text: overview.modeLabel, tone: PillTone.blue),
          ],
          child: Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _InfoChip(
                Icons.memory_outlined,
                'المعالج ${_value(resource, 'cpu-load', fallback: 'غير معروف')}%',
              ),
              _InfoChip(
                Icons.schedule_outlined,
                'مدة التشغيل ${_value(resource, 'uptime')}',
              ),
              _InfoChip(
                Icons.system_update_alt_outlined,
                'الإصدار ${_value(resource, 'version')}',
              ),
              _InfoChip(
                Icons.developer_board_outlined,
                'اللوحة ${_value(routerboard, 'model', fallback: _value(resource, 'board-name'))}',
              ),
              if (overview.dialAddress.isNotEmpty)
                _InfoChip(
                  Icons.lan_outlined,
                  'عنوان الاتصال ${overview.dialAddress}',
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            final cards = [
              for (final entry in overview.sections.entries)
                _SectionCard(name: entry.key, section: entry.value),
            ];
            if (!wide) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: AppTokens.s12),
                  ],
                ],
              );
            }
            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppTokens.s12,
              mainAxisSpacing: AppTokens.s12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.15,
              children: cards,
            );
          },
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.name, required this.section});

  final String name;
  final MikrotikOverviewSection section;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: _sectionLabel(name),
      icon: _sectionIcon(name),
      actions: [
        StatusPill(
          text: section.ok ? 'سليم' : 'مشكلة',
          tone: section.ok ? PillTone.green : PillTone.red,
          dot: true,
        ),
        if (section.cached)
          const StatusPill(text: 'من الذاكرة المؤقتة', tone: PillTone.neutral),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (section.ok)
            Text(
              'تمت القراءة خلال ${section.tookMs} مللي ثانية.',
              style: const TextStyle(color: AppTokens.textSecondary),
            )
          else
            Text(
              section.error.isEmpty
                  ? 'لم يرجع الراوتر بيانات لهذه الخانة.'
                  : section.error,
              style: const TextStyle(color: AppTokens.redInk),
            ),
          if (section.dialedAddress.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            Text(
              'عنوان الاتصال: ${section.dialedAddress}',
              style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
            ),
          ],
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

class _LiveSnapshotPanel extends StatelessWidget {
  const _LiveSnapshotPanel({
    required this.snapshot,
    required this.onRefresh,
  });

  final MikrotikLiveSnapshot snapshot;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل تشغيل الراوتر',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTokens.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'قراءة مباشرة من عقود MikroTik الموجودة في الخادم: الواجهات، الجلسات، الطوابير، الجدار الناري، الملفات، والنسخ.',
                    style: TextStyle(color: AppTokens.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            StatusPill(
              text: '${snapshot.totalRows} عنصر',
              tone: snapshot.anyOk ? PillTone.blue : PillTone.neutral,
            ),
            if (snapshot.failedSections > 0) ...[
              const SizedBox(width: AppTokens.s8),
              StatusPill(
                text: '${snapshot.failedSections} أقسام تعذرت',
                tone: PillTone.amber,
              ),
            ],
            IconButton(
              tooltip: 'تحديث تفاصيل التشغيل',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 960;
            final cards = [
              for (final section in snapshot.sections)
                _LiveSectionCard(section: section),
            ];
            if (!wide) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: AppTokens.s12),
                  ],
                ],
              );
            }
            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppTokens.s12,
              mainAxisSpacing: AppTokens.s12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              children: cards,
            );
          },
        ),
      ],
    );
  }
}

class _LiveSectionCard extends StatelessWidget {
  const _LiveSectionCard({required this.section});

  final MikrotikLiveSection section;

  @override
  Widget build(BuildContext context) {
    final rows = section.rows.take(6).toList();
    return AppCard(
      title: section.title,
      icon: _liveSectionIcon(section.key),
      actions: [
        StatusPill(
          text: section.ok ? 'جاهز' : 'متعذر',
          tone: section.ok ? PillTone.green : PillTone.red,
          dot: true,
        ),
        if (section.cached)
          const StatusPill(text: 'من الذاكرة المؤقتة', tone: PillTone.neutral),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _MiniFact('العناصر', section.rowCount.toString()),
              if (section.tookMs > 0)
                _MiniFact('زمن القراءة', '${section.tookMs} مللي ثانية'),
              if (section.mode.isNotEmpty)
                _MiniFact('طريقة الاتصال', _modeLabel(section.mode)),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          if (!section.ok)
            Text(
              section.error.isEmpty
                  ? 'تعذر قراءة هذا القسم من الراوتر.'
                  : section.error,
              style: const TextStyle(color: AppTokens.redInk),
            )
          else if (!section.hasData)
            const Text(
              'لا توجد بيانات حالية في هذا القسم.',
              style: TextStyle(color: AppTokens.textSecondary),
            )
          else if (rows.isEmpty)
            _KeyValueGrid(values: section.summary)
          else
            Column(
              children: [
                for (final row in rows) ...[
                  _RouterRowPreview(sectionKey: section.key, row: row),
                  const SizedBox(height: AppTokens.s8),
                ],
                if (section.rows.length > rows.length)
                  Text(
                    'يعرض أول ${rows.length} من أصل ${section.rows.length} عنصر.',
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MiniFact extends StatelessWidget {
  const _MiniFact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r8),
        border: Border.all(color: AppTokens.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _RouterRowPreview extends StatelessWidget {
  const _RouterRowPreview({
    required this.sectionKey,
    required this.row,
  });

  final String sectionKey;
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final values = _rowPreviewValues(sectionKey, row);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.border),
      ),
      child: _KeyValueGrid(values: values),
    );
  }
}

class _KeyValueGrid extends StatelessWidget {
  const _KeyValueGrid({required this.values});

  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries
        .where((entry) => _displayValue(entry.value).isNotEmpty)
        .take(5)
        .toList();
    if (entries.isEmpty) {
      return const Text(
        'لا توجد تفاصيل إضافية.',
        style: TextStyle(color: AppTokens.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 118,
                  child: Text(
                    _fieldLabel(entry.key),
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _displayValue(entry.value, key: entry.key),
                    style: const TextStyle(
                      color: AppTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _value(
  Map<String, dynamic> map,
  String key, {
  String fallback = 'غير معروف',
}) {
  final value = (map[key] ?? '').toString().trim();
  return value.isEmpty ? fallback : value;
}

String _sectionLabel(String name) {
  return switch (name) {
    'resource' => 'الموارد',
    'health' => 'الصحة',
    'identity' => 'الهوية',
    'clock' => 'الوقت',
    'routerboard' => 'لوحة الجهاز',
    _ => 'قسم حالة',
  };
}

IconData _sectionIcon(String name) {
  return switch (name) {
    'resource' => Icons.memory_outlined,
    'health' => Icons.monitor_heart_outlined,
    'identity' => Icons.badge_outlined,
    'clock' => Icons.schedule_outlined,
    'routerboard' => Icons.developer_board_outlined,
    _ => Icons.info_outline,
  };
}

IconData _liveSectionIcon(String key) {
  return switch (key) {
    'interfaces' => Icons.settings_input_component_outlined,
    'ip_addresses' => Icons.pin_drop_outlined,
    'routes' => Icons.alt_route_outlined,
    'neighbors' => Icons.device_hub_outlined,
    'hotspot_active' => Icons.wifi_outlined,
    'ppp_active' => Icons.link_outlined,
    'queues' => Icons.speed_outlined,
    'firewall_filter' => Icons.security_outlined,
    'firewall_nat' => Icons.compare_arrows_outlined,
    'address_lists' => Icons.list_alt_outlined,
    'logs' => Icons.receipt_long_outlined,
    'files' => Icons.folder_outlined,
    'router_backups' => Icons.backup_outlined,
    'counters' => Icons.query_stats_outlined,
    _ => Icons.info_outline,
  };
}

Map<String, dynamic> _rowPreviewValues(
  String sectionKey,
  Map<String, dynamic> row,
) {
  final preferred = switch (sectionKey) {
    'interfaces' => [
        'name',
        'type',
        'running',
        'disabled',
        'rx-byte',
        'tx-byte',
      ],
    'ip_addresses' => ['address', 'interface', 'network', 'dynamic'],
    'routes' => ['dst-address', 'gateway', 'distance', 'active', 'disabled'],
    'neighbors' => ['identity', 'address', 'mac-address', 'interface'],
    'hotspot_active' => ['user', 'address', 'mac-address', 'uptime'],
    'ppp_active' => ['name', 'address', 'caller-id', 'uptime', 'service'],
    'queues' => ['name', 'target', 'max-limit', 'rate', 'disabled'],
    'firewall_filter' || 'firewall_nat' => [
        'chain',
        'action',
        'protocol',
        'src-address',
        'dst-address',
        'dst-port',
        'disabled',
      ],
    'address_lists' => ['list', 'address', 'dynamic', 'disabled', 'comment'],
    'logs' => ['time', 'topics', 'message'],
    'files' => ['name', 'type', 'size', 'creation-time'],
    'router_backups' => [
        'name',
        'router_status',
        'manifest_summary',
        'created_at',
      ],
    _ => <String>[],
  };
  final out = <String, dynamic>{};
  for (final key in preferred) {
    if (row.containsKey(key)) out[key] = row[key];
  }
  for (final entry in row.entries) {
    if (out.length >= 5) break;
    out.putIfAbsent(entry.key, () => entry.value);
  }
  return out;
}

String _fieldLabel(String key) {
  return switch (key) {
    'name' => 'الاسم',
    'type' => 'النوع',
    'running' => 'يعمل',
    'disabled' => 'معطل',
    'rx-byte' || 'rx_bytes' => 'التحميل الوارد',
    'tx-byte' || 'tx_bytes' => 'الرفع الصادر',
    'address' => 'العنوان',
    'interface' => 'الواجهة',
    'network' => 'الشبكة',
    'dynamic' => 'تلقائي',
    'dst-address' => 'وجهة المسار',
    'gateway' => 'البوابة',
    'distance' => 'الأولوية',
    'active' => 'نشط',
    'identity' => 'هوية الجهاز',
    'mac-address' || 'caller-id' => 'عنوان MAC',
    'user' => 'المستخدم',
    'uptime' => 'مدة التشغيل',
    'service' => 'الخدمة',
    'target' => 'الهدف',
    'max-limit' => 'الحد الأقصى',
    'rate' => 'السرعة الحالية',
    'chain' => 'السلسلة',
    'action' => 'الإجراء',
    'protocol' => 'البروتوكول',
    'src-address' => 'المصدر',
    'dst-port' => 'منفذ الوجهة',
    'list' => 'القائمة',
    'comment' => 'ملاحظة',
    'time' => 'الوقت',
    'topics' => 'الموضوع',
    'message' => 'الرسالة',
    'size' || 'size_bytes' => 'الحجم',
    'creation-time' || 'created_at' => 'تاريخ الإنشاء',
    'router_status' => 'حالة ملف الراوتر',
    'manifest_summary' => 'ملخص النسخة',
    'count' => 'العدد',
    'total' => 'الإجمالي',
    _ => key.replaceAll('_', ' ').replaceAll('-', ' '),
  };
}

String _displayValue(Object? value, {String key = ''}) {
  if (value == null) return '';
  if (value is bool) return value ? 'نعم' : 'لا';
  final text = value.toString().trim();
  if (text.isEmpty) return '';
  if (key == 'router_status') {
    return switch (text) {
      'on_router' => 'موجودة على الراوتر',
      'saved' => 'محفوظة',
      'restored' => 'مستعادة',
      _ => 'حالة غير معروفة',
    };
  }
  if (key == 'disabled' || key == 'dynamic' || key == 'active') {
    return switch (text.toLowerCase()) {
      'true' || 'yes' => 'نعم',
      'false' || 'no' => 'لا',
      _ => text,
    };
  }
  return text;
}

String _modeLabel(String mode) {
  return switch (mode) {
    'vpn' => 'عبر النفق',
    'direct' => 'مباشر',
    _ => mode.isEmpty ? 'غير محدد' : mode,
  };
}
