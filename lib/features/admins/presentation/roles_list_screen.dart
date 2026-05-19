import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/admins_repository.dart';

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
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () => ref.invalidate(rolesListProvider),
            ),
            const SizedBox(width: AppTokens.s4),
            ElevatedButton.icon(
              onPressed: () => context.goNamed('role-new'),
              icon: const Icon(Icons.add),
              label: const Text('دور جديد'),
            ),
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
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(rolesListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
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
                    leading: CircleAvatar(
                      backgroundColor: _parseColor(r.color),
                      child: const Icon(Icons.shield, color: Colors.white, size: 18),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (r.isSystem)
                          const StatusPill(text: 'نظام', tone: PillTone.purple),
                      ],
                    ),
                    subtitle: Text(
                      r.description.isEmpty
                          ? '${r.permissions.length} صلاحية'
                          : '${r.description} • ${r.permissions.length} صلاحية',
                      style: const TextStyle(color: AppTokens.textMuted),
                    ),
                    trailing: const Icon(Icons.chevron_left, color: AppTokens.textMuted),
                    onTap: r.id == null
                        ? null
                        : () => ctx.goNamed(
                              'role-edit',
                              pathParameters: {'id': '${r.id}'},
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

  static Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppTokens.cyan500;
    }
  }
}
