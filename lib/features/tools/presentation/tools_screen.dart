import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/tools_providers.dart';
import '../data/tools_repository.dart';
import '../domain/tools_models.dart';
import 'widgets/tools_adjustments_panel.dart';
import 'widgets/tools_maintenance_panel.dart';
import 'widgets/tools_radius_log_panel.dart';
import 'widgets/tools_set_speeds_panel.dart';
import 'widgets/tools_test_auth_panel.dart';

/// Tools tab dispatcher — five panels behind an even tab bar. Shared
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'الأدوات',
          subtitle: 'سرعات، تعديلات، اختبار دخول، سجل وصيانة',
          inlineActions: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(radiusLogProvider),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        _ToolsTabBar(
          selected: _tab,
          onSelected: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: AppTokens.s12),
        IndexedStack(
          index: _tab,
          children: [
            ToolsSetSpeedsPanel(busy: _busy, run: _setSpeeds),
            ToolsAdjustmentsPanel(busy: _busy, run: _generalAdjustment),
            ToolsTestAuthPanel(busy: _busy, run: _testAuth),
            ToolsRadiusLogPanel(
              onRefresh: () => ref.invalidate(radiusLogProvider),
            ),
            ToolsMaintenancePanel(busy: _busy, runPreview: _previewMaintenance),
          ],
        ),
      ],
    );
  }

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

/// Five equal tabs (icon over a one-line label) spread across the width.
/// Replaces a SegmentedButton whose squeezed segments wrapped Arabic labels
/// one letter per line on phones.
class _ToolsTabBar extends StatelessWidget {
  const _ToolsTabBar({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  static const _tabs = <(IconData, String)>[
    (Icons.speed_outlined, 'السرعات'),
    (Icons.rule_folder_outlined, 'تعديلات'),
    (Icons.verified_user_outlined, 'اختبار'),
    (Icons.rss_feed, 'السجل'),
    (Icons.cleaning_services_outlined, 'الصيانة'),
  ];

  @override
  Widget build(BuildContext context) {
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
          for (var i = 0; i < _tabs.length; i++) ...[
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
                            _tabs[i].$1,
                            size: 20,
                            color: i == selected
                                ? Colors.white
                                : AppTokens.textSecondary,
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _tabs[i].$2,
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
