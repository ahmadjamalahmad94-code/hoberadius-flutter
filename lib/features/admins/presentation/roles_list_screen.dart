import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/admins_repository.dart';
import '../domain/admin_model.dart';

final rolesListProvider = FutureProvider.autoDispose<List<Role>>((ref) {
  return ref.watch(adminsRepositoryProvider).listRoles();
});

class RolesListScreen extends ConsumerWidget {
  const RolesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(rolesListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'الأدوار',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.navy900,
                  ),
            ),
            const Spacer(),
            const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب الأدوار',
            subtitle: '$e',
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.shield_outlined,
                title: 'لا توجد أدوار بعد',
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final r = items[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTokens.cyan100,
                      child: Icon(Icons.shield, color: AppTokens.cyan500),
                    ),
                    title: Row(
                      children: [
                        Text(
                          r.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (r.isSystem) ...[
                          const SizedBox(width: AppTokens.s8),
                          const StatusPill(text: 'نظام', tone: PillTone.purple),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      r.description.isEmpty
                          ? '${r.permissions.length} صلاحية'
                          : r.description,
                      style: const TextStyle(color: AppTokens.textMuted),
                    ),
                    trailing: r.isSystem
                        ? const Tooltip(
                            message: 'لا يمكن حذف الأدوار النظامية',
                            child: Icon(Icons.lock_outline, color: AppTokens.textMuted),
                          )
                        : IconButton(
                            tooltip: 'حذف',
                            onPressed: () {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('endpoint DELETE role لم يُعرَض بعد على Flask.'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_outline, color: AppTokens.red),
                          ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
