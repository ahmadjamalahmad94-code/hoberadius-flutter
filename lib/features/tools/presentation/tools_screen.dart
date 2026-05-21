import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/tools_providers.dart';
import '../data/tools_repository.dart';
import '../domain/tools_models.dart';
import 'widgets/tools_adjustments_panel.dart';
import 'widgets/tools_maintenance_panel.dart';
import 'widgets/tools_radius_log_panel.dart';
import 'widgets/tools_set_speeds_panel.dart';
import 'widgets/tools_test_auth_panel.dart';

/// Tools tab dispatcher — five panels behind a SegmentedButton. Shared
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
          subtitle:
              'أدوات تشغيل حقيقية من الخادم: تعديل سرعات، اختبار دخول، سجل RADIUS، وصيانة بمعاينة قبل التنفيذ.',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(radiusLogProvider),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s8),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                icon: Icon(Icons.speed_outlined),
                label: Text('السرعات'),
              ),
              ButtonSegment(
                value: 1,
                icon: Icon(Icons.rule_folder_outlined),
                label: Text('تعديلات'),
              ),
              ButtonSegment(
                value: 2,
                icon: Icon(Icons.verified_user_outlined),
                label: Text('اختبار'),
              ),
              ButtonSegment(
                value: 3,
                icon: Icon(Icons.rss_feed),
                label: Text('السجل'),
              ),
              ButtonSegment(
                value: 4,
                icon: Icon(Icons.cleaning_services_outlined),
                label: Text('الصيانة'),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (value) => setState(() => _tab = value.first),
            showSelectedIcon: false,
          ),
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
          SnackBar(content: Text('$e')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
