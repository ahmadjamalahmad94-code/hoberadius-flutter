import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/admins_repository.dart';
import '../domain/admin_model.dart';

final adminsListProvider = FutureProvider.autoDispose<List<Admin>>((ref) {
  return ref.watch(adminsRepositoryProvider).listAdmins();
});

class AdminsListScreen extends ConsumerWidget {
  const AdminsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminsListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'المدراء',
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
            title: 'تعذّر جلب القائمة',
            subtitle: '$e',
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.admin_panel_settings_outlined,
                title: 'لا توجد حسابات إدارية بعد',
              );
            }
            final df = DateFormat('yyyy-MM-dd HH:mm');
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final a = items[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTokens.navy800,
                      child: Text(
                        a.username.isEmpty ? '?' : a.username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      a.fullName.isEmpty ? a.username : a.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                        a.username,
                        if (a.email.isNotEmpty) a.email,
                        if (a.lastLoginAt != null) 'آخر دخول: ${df.format(a.lastLoginAt!)}',
                        if (a.lastLoginIp.isNotEmpty) a.lastLoginIp,
                      ].join(' • '),
                      style: const TextStyle(color: AppTokens.textMuted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (a.roleName.isNotEmpty)
                          StatusPill(text: a.roleName, tone: PillTone.navy),
                        const SizedBox(width: AppTokens.s8),
                        StatusPill(
                          text: a.disabled ? 'معطّل' : 'مفعّل',
                          tone: a.disabled ? PillTone.red : PillTone.green,
                        ),
                      ],
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
