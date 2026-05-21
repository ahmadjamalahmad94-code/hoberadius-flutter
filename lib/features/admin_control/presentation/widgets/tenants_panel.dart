import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/admin_control_providers.dart';
import '../../domain/admin_control_model.dart';
import 'admin_section_common.dart';

class TenantsPanel extends ConsumerWidget {
  const TenantsPanel({
    super.key,
    required this.onCreate,
    required this.onEdit,
    required this.busy,
  });

  final VoidCallback onCreate;
  final ValueChanged<TenantRecord> onEdit;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tenantsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ElevatedButton.icon(
            onPressed: busy ? null : onCreate,
            icon: const Icon(Icons.add_business),
            label: const Text('مستأجر جديد'),
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const AdminLoadingCard(title: 'المستأجرون'),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب المستأجرين',
            subtitle: '$e',
          ),
          data: (tenants) => AppCard(
            title: 'المستأجرون',
            icon: Icons.business,
            padding: EdgeInsets.zero,
            child: AdminListSection(
              count: tenants.length,
              itemBuilder: (_, i) {
                final tenant = tenants[i];
                return ListTile(
                  title: Text(
                    tenant.displayName.isEmpty
                        ? tenant.name
                        : tenant.displayName,
                  ),
                  subtitle: Text(
                    [
                      tenant.slug,
                      tenant.planTier,
                      'مشتركين: ${tenant.maxSubscribers}',
                      'NAS: ${tenant.maxNas}',
                      'API: ${tenant.apiRpm == 0 ? 'بدون حد' : tenant.apiRpm}',
                    ].join(' • '),
                  ),
                  leading: StatusPill(
                    text: tenantStatusLabel(tenant.status),
                    tone: tenantStatusTone(tenant.status),
                  ),
                  trailing: IconButton(
                    tooltip: 'تعديل',
                    onPressed: busy ? null : () => onEdit(tenant),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
