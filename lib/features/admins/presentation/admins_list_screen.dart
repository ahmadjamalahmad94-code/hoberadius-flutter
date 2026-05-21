import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/admins_repository.dart';
import '../domain/admin_model.dart';

class AdminsListScreen extends ConsumerWidget {
  const AdminsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAdmins = ref.watch(adminsListProvider);
    final asyncRoles = ref.watch(rolesListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'المدراء',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.sidebarBg,
                  ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () => ref.invalidate(adminsListProvider),
            ),
            const SizedBox(width: AppTokens.s4),
            ElevatedButton.icon(
              onPressed: () => context.goNamed('admin-new'),
              icon: const Icon(Icons.add),
              label: const Text('مدير جديد'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        asyncAdmins.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب القائمة',
            subtitle: '$e',
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(adminsListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (admins) {
            if (admins.isEmpty) {
              return const EmptyState(
                icon: Icons.admin_panel_settings_outlined,
                title: 'لا توجد حسابات إدارية بعد',
              );
            }
            final rolesByID = <int, Role>{
              for (final r in asyncRoles.valueOrNull ?? const <Role>[])
                if (r.id != null) r.id!: r,
            };
            return AppCard(
              padding: EdgeInsets.zero,
              child: _AdminsTable(admins: admins, roles: rolesByID),
            );
          },
        ),
      ],
    );
  }
}

class _AdminsTable extends StatelessWidget {
  const _AdminsTable({required this.admins, required this.roles});
  final List<Admin> admins;
  final Map<int, Role> roles;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: admins.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final a = admins[i];
        final role = a.roleId == null ? null : roles[a.roleId];
        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: a.isSuperAdmin
                  ? AppTokens.brandGradient
                  : const LinearGradient(
                      colors: [
                        AppTokens.sidebarBgElev1,
                        AppTokens.sidebarBgElev2,
                      ],
                    ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTokens.brand.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              a.username.isEmpty ? '?' : a.username[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  a.fullName.isEmpty ? a.username : a.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (a.isSuperAdmin)
                const StatusPill(text: 'مدير عام', tone: PillTone.purple),
            ],
          ),
          subtitle: Text(
            [
              '@${a.username}',
              if (a.email.isNotEmpty) a.email,
              if (role != null) role.label,
              if (a.lastLoginAt != null) 'آخر دخول: ${df.format(a.lastLoginAt!)}',
              if (a.lastLoginIp.isNotEmpty) a.lastLoginIp,
            ].join(' • '),
            style: const TextStyle(color: AppTokens.textMuted),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusPill(
                text: a.enabled ? 'مفعّل' : 'معطّل',
                tone: a.enabled ? PillTone.green : PillTone.red,
              ),
            ],
          ),
          onTap: a.id == null
              ? null
              : () => ctx.goNamed('admin-edit', pathParameters: {'id': '${a.id}'}),
        );
      },
    );
  }
}
