import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/system_operations_providers.dart';
import '../data/system_operations_repository.dart';
import 'widgets/system_bridge_events_panel.dart';
import 'widgets/system_license_file_panel.dart';
import 'widgets/system_loading_card.dart';

class LicenseFileScreen extends ConsumerStatefulWidget {
  const LicenseFileScreen({super.key});

  @override
  ConsumerState<LicenseFileScreen> createState() => _LicenseFileScreenState();
}

class _LicenseFileScreenState extends ConsumerState<LicenseFileScreen> {
  String? _busyAction;

  @override
  Widget build(BuildContext context) {
    final licenseFile = ref.watch(licenseFileProvider);
    final bridgeEvents = ref.watch(bridgeEventsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'ملف الترخيص والمزامنة',
          subtitle:
              'يعرض عقد الترخيص القادم من لوحة التراخيص، حالة الربط، الخدمات، والحدود التي يطبقها الريدياس محليًا.',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        licenseFile.when(
          loading: () =>
              const SystemLoadingCard(title: 'قراءة ملف الترخيص والمزامنة'),
          error: (_, __) => HubErrorState(
            title: 'تعذر جلب ملف الترخيص',
            subtitle: 'تحقق من اتصال التطبيق بالريدياس ثم أعد المحاولة.',
            onRetry: () => ref.invalidate(licenseFileProvider),
          ),
          data: (data) => SystemLicenseFilePanel(
            state: data,
            busyAction: _busyAction,
            onSyncLicense: () => _runBridgeAction('license'),
            onSyncIdentity: () => _runBridgeAction('identity'),
            onHeartbeat: () => _runBridgeAction('heartbeat'),
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        bridgeEvents.when(
          loading: () => const SystemLoadingCard(title: 'آخر أحداث الربط'),
          error: (_, __) => HubErrorState(
            title: 'تعذر جلب أحداث الربط',
            subtitle: 'لم يتمكن التطبيق من قراءة سجل الربط الآن.',
            onRetry: () => ref.invalidate(bridgeEventsProvider),
          ),
          data: (data) => SystemBridgeEventsPanel(state: data),
        ),
      ],
    );
  }

  void _refresh() {
    ref.invalidate(licenseFileProvider);
    ref.invalidate(bridgeEventsProvider);
  }

  Future<void> _runBridgeAction(String action) async {
    if (_busyAction != null) return;
    setState(() => _busyAction = action);
    try {
      final repo = ref.read(systemOperationsRepositoryProvider);
      final result = switch (action) {
        'license' => await repo.syncLicenseContract(),
        'identity' => await repo.syncIdentity(),
        'heartbeat' => await repo.sendHeartbeatProbe(),
        _ => <String, dynamic>{'ok': false, 'status': 'unknown'},
      };
      _refresh();
      if (!mounted) return;
      final status = (result['status'] ?? '').toString();
      final success = result['ok'] == true;
      final label = systemStatusLabel(status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(success ? 'تمت العملية: $label' : 'تعذرت العملية: $label'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذرت العملية. تحقق من الاتصال ثم أعد المحاولة.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }
}
