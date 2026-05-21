import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/system_operations_providers.dart';
import '../../domain/system_operations_model.dart';

class SystemDiagnosticsPanel extends StatelessWidget {
  const SystemDiagnosticsPanel({super.key, required this.diagnostics});

  final SystemDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'تشخيص الراوترات',
      icon: Icons.router_outlined,
      child: diagnostics.routers.isEmpty
          ? const EmptyState(
              icon: Icons.router_outlined,
              title: 'لا توجد راوترات للتشخيص',
            )
          : Column(
              children: diagnostics.routers
                  .map((router) => _DiagnosticRow(router: router))
                  .toList(),
            ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.router});
  final DiagnosticRouter router;

  @override
  Widget build(BuildContext context) {
    final ok = router.status == 'ok';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        ok ? Icons.check_circle_outline : Icons.error_outline,
        color: ok ? AppTokens.green : AppTokens.amber,
      ),
      title: Text(router.name.isEmpty ? router.host : router.name),
      subtitle: Text(
        [
          if (router.host.isNotEmpty) router.host,
          if (router.verdict.isNotEmpty) router.verdict,
          if (router.hint.isNotEmpty) router.hint,
        ].join(' • '),
      ),
      trailing: StatusPill(
        text: systemStatusLabel(router.status),
        tone: ok ? PillTone.green : PillTone.orange,
      ),
    );
  }
}
