import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/tools_providers.dart';
import '../data/tools_repository.dart';
import '../domain/tools_models.dart';
import 'widgets/tools_adjustments_panel.dart';
import 'widgets/tools_maintenance_panel.dart';
import 'widgets/tools_radius_log_panel.dart';
import 'widgets/tools_set_speeds_panel.dart';
import 'widgets/tools_test_auth_panel.dart';

/// Tools tab dispatcher — one panel per ALLOWED tool behind an even tab bar. Shared
/// `_busy` flag prevents overlapping repository calls across tabs.
class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> {
  int _tab = 0;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    // fix2-final: only the tools the server allows (grants.tools /
    // GET /api/v1/tools); unknown (older server) = all, as before.
    final access = ref.watch(toolsAccessProvider);
    if (access.isLoading && !access.hasValue) {
      return const Padding(
        padding: EdgeInsets.all(AppTokens.s24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final keys = visibleToolKeys(access.valueOrNull);
    final showLog = keys.contains(kToolRadiusLog);
    final tab = _tab < keys.length ? _tab : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'الأدوات',
          subtitle: keys.isEmpty
              ? 'لا توجد أدوات متاحة لحسابك'
              : keys.map((k) => kToolTabs[k]!.$3).join('، '),
          inlineActions: true,
          actions: [
            if (showLog)
              IconButton(
                tooltip: 'تحديث',
                onPressed: () => ref.invalidate(radiusLogProvider),
                icon:
                    const Icon(Icons.refresh, color: AppTokens.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        if (keys.isEmpty)
          const EmptyState(
            icon: Icons.lock_outline,
            title: 'لا تملك صلاحية أيّ أداة',
            subtitle: 'ضبط السرعات والتعديلات العامّة واختبار الدخول والصيانة '
                'للمالك فقط، وسجلّ الراديوس يحتاج صلاحية التقارير.',
          )
        else ...[
          if (keys.length > 1) ...[
            _ToolsTabBar(
              keys: keys,
              selected: tab,
              onSelected: (value) => setState(() => _tab = value),
            ),
            const SizedBox(height: AppTokens.s12),
          ],
          IndexedStack(
            index: tab,
            children: [for (final k in keys) _panel(k)],
          ),
        ],
      ],
    );
  }

  Widget _panel(String key) => switch (key) {
        kToolSetSpeeds => ToolsSetSpeedsPanel(busy: _busy, run: _setSpeeds),
        kToolGeneralAdjustments =>
          ToolsAdjustmentsPanel(busy: _busy, run: _generalAdjustment),
        kToolTestAuth => ToolsTestAuthPanel(busy: _busy, run: _testAuth),
        kToolRadiusLog => ToolsRadiusLogPanel(
            onRefresh: () => ref.invalidate(radiusLogProvider),
          ),
        _ => ToolsMaintenancePanel(
            busy: _busy,
            runPreview: _previewMaintenance,
          ),
      };

  Future<SetSpeedsResult?> _setSpeeds(Map<String, dynamic> body) =>
      _guard(() => ref.read(toolsRepositoryProvider).setSpeeds(body));

  Future<Map<String, dynamic>?> _generalAdjustment(
    Map<String, dynamic> body,
  ) =>
      _guard(
        () => ref.read(toolsRepositoryProvider).generalAdjustments(body),
      );

  Future<AuthTestDecision?> _testAuth(Map<String, dynamic> body) =>
      _guard(() => ref.read(toolsRepositoryProvider).testAuth(body));

  Future<MaintenancePreview?> _previewMaintenance(
    String action,
    int days,
  ) =>
      _guard(
        () => ref.read(toolsRepositoryProvider).maintenancePreview(
              action: action,
              days: days,
            ),
      );

  Future<T?> _guard<T>(Future<T> Function() work) async {
    setState(() => _busy = true);
    try {
      return await work();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(visibleErrorMessage(e))),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Tool key → (tab icon, one-line tab label, subtitle word).
const kToolTabs = <String, (IconData, String, String)>{
  kToolSetSpeeds: (Icons.speed_outlined, 'السرعات', 'سرعات'),
  kToolGeneralAdjustments: (Icons.rule_folder_outlined, 'تعديلات', 'تعديلات'),
  kToolTestAuth: (Icons.verified_user_outlined, 'اختبار', 'اختبار دخول'),
  kToolRadiusLog: (Icons.rss_feed, 'السجل', 'سجل'),
  kToolMaintenance: (Icons.cleaning_services_outlined, 'الصيانة', 'صيانة'),
};

/// Equal tabs (icon over a one-line label) spread across the width — one
/// per allowed tool. Replaces a SegmentedButton whose squeezed segments
/// wrapped Arabic labels one letter per line on phones.
class _ToolsTabBar extends StatelessWidget {
  const _ToolsTabBar({
    required this.keys,
    required this.selected,
    required this.onSelected,
  });

  final List<String> keys;
  final int selected;
  final ValueChanged<int> onSelected;

  List<(IconData, String)> get _tabs => [
        for (final k in keys) (kToolTabs[k]!.$1, kToolTabs[k]!.$2),
      ];

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                selected: i == selected,
                button: true,
                child: Material(
                  color: i == selected ? AppTokens.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTokens.r10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTokens.r10),
                    onTap: () => onSelected(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTokens.s8,
                        horizontal: 2,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tabs[i].$1,
                            size: 20,
                            color: i == selected
                                ? Colors.white
                                : AppTokens.textSecondary,
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              tabs[i].$2,
                              maxLines: 1,
                              softWrap: false,
                              style: labelStyle?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: i == selected
                                    ? Colors.white
                                    : AppTokens.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
