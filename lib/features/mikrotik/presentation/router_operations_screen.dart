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
              'متابعة حالة الراوتر الحية من عقد ميكروتك الموجود في الريدياس. هذه الصفحة قراءة آمنة ولا تنفذ إعادة تشغيل أو تغييرات على الراوتر.',
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
    final overviewAsync = ref.watch(mikrotikRouterOverviewProvider(selected.id!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selected.id,
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
                onPressed: () => ref.invalidate(
                  mikrotikRouterOverviewProvider(selected.id!),
                ),
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
                _InfoChip(Icons.lan_outlined, 'عنوان الاتصال ${overview.dialAddress}'),
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
              section.error.isEmpty ? 'لم يرجع الراوتر بيانات لهذه الخانة.' : section.error,
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
