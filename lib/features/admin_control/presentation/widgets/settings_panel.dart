import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../application/admin_control_providers.dart';
import '../../domain/admin_control_model.dart';
import 'admin_section_common.dart';

class SettingsPanel extends ConsumerWidget {
  const SettingsPanel({super.key, required this.onEdit});

  final ValueChanged<SettingItem> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(settingsProvider);
    return async.when(
      loading: () => const AdminLoadingCard(title: 'الإعدادات'),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'تعذر جلب الإعدادات',
        subtitle: visibleErrorMessage(e),
      ),
      data: (snapshot) => AppCard(
        title: 'إعدادات النظام',
        icon: Icons.tune,
        padding: EdgeInsets.zero,
        child: AdminListSection(
          count: snapshot.items.length,
          itemBuilder: (_, i) {
            final item = snapshot.items[i];
            return ListTile(
              title: Text(item.label),
              subtitle: Text(
                item.key,
                style: const TextStyle(color: AppTokens.textMuted),
              ),
              trailing: Wrap(
                spacing: AppTokens.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      item.value.isEmpty ? 'غير محدد' : item.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'تعديل',
                    onPressed: () => onEdit(item),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
