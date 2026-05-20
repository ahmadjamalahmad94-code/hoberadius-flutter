import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admins/presentation/admin_form_screen.dart';
import '../../features/admins/presentation/admins_list_screen.dart';
import '../../features/admins/presentation/role_form_screen.dart';
import '../../features/admins/presentation/roles_list_screen.dart';
import '../../features/accounting/presentation/financial_reports_screen.dart';
import '../../features/accounting/presentation/ledger_screen.dart';
import '../../features/accounting/presentation/subscriber_finance_screen.dart';
import '../../features/admin_control/presentation/admin_control_screen.dart';
import '../../features/audit/presentation/audit_list_screen.dart';
import '../../features/sessions/presentation/sessions_list_screen.dart';
import '../../features/system_operations/presentation/system_operations_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/backups/presentation/backups_screen.dart';
import '../../features/bandwidth_schedules/presentation/bandwidth_schedules_screen.dart';
import '../../features/cards/presentation/card_batch_detail_screen.dart';
import '../../features/cards/presentation/card_batch_edit_screen.dart';
import '../../features/cards/presentation/card_batch_form_screen.dart';
import '../../features/cards/presentation/card_checker_screen.dart';
import '../../features/cards/presentation/cards_list_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/distributors/presentation/distributor_detail_screen.dart';
import '../../features/distributors/presentation/distributor_form_screen.dart';
import '../../features/distributors/presentation/distributors_list_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/nas/presentation/nas_form_screen.dart';
import '../../features/nas/presentation/nas_list_screen.dart';
import '../../features/operational_reports/presentation/operational_reports_screen.dart';
import '../../features/plans/presentation/plan_form_screen.dart';
import '../../features/plans/presentation/plans_list_screen.dart';
import '../../features/print_templates/presentation/print_templates_screen.dart';
import '../../features/recycle_bin/presentation/recycle_bin_screen.dart';
import '../../features/shell/shell_scaffold.dart';
import '../../features/subscribers/presentation/subscriber_form_screen.dart';
import '../../features/subscribers/presentation/subscribers_list_screen.dart';
import '../auth/auth_controller.dart';

/// Routes kept in the foundation slice are only those backed by working
/// Flask endpoints. Placeholder Plans/NAS/Admins/Roles forms were dropped
/// — they will return only when the backend exposes JSON CUD for each.
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn && !atLogin) return '/login';
      if (loggedIn && atLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (ctx, st) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (ctx, st, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (ctx, st) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/subscribers',
            name: 'subscribers',
            builder: (ctx, st) => const SubscribersListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'subscriber-new',
                builder: (ctx, st) => const SubscriberFormScreen(),
              ),
              GoRoute(
                path: ':username',
                name: 'subscriber-edit',
                builder: (ctx, st) => SubscriberFormScreen(
                  username: st.pathParameters['username'],
                ),
              ),
              GoRoute(
                path: ':username/finance',
                name: 'subscriber-finance',
                builder: (ctx, st) => SubscriberFinanceScreen(
                  username: st.pathParameters['username'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/cards',
            name: 'cards',
            builder: (ctx, st) => const CardsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'card-batch-new',
                builder: (ctx, st) => const CardBatchFormScreen(),
              ),
              GoRoute(
                path: 'checker',
                name: 'card-checker',
                builder: (ctx, st) => const CardCheckerScreen(),
              ),
              GoRoute(
                path: 'batches/:id',
                name: 'card-batch-detail',
                builder: (ctx, st) => CardBatchDetailScreen(
                  batchId: int.tryParse(st.pathParameters['id'] ?? '') ?? 0,
                ),
              ),
              GoRoute(
                path: 'batches/:id/edit',
                name: 'card-batch-edit',
                builder: (ctx, st) => CardBatchEditScreen(
                  batchId: int.tryParse(st.pathParameters['id'] ?? '') ?? 0,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/nas',
            name: 'nas',
            builder: (ctx, st) => const NasListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'nas-new',
                builder: (ctx, st) => const NasFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'nas-edit',
                builder: (ctx, st) => NasFormScreen(
                  nasId: int.tryParse(st.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/plans',
            name: 'plans',
            builder: (ctx, st) => const PlansListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'plan-new',
                builder: (ctx, st) => const PlanFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'plan-edit',
                builder: (ctx, st) => PlanFormScreen(
                  planId: int.tryParse(st.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/admins',
            name: 'admins',
            builder: (ctx, st) => const AdminsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'admin-new',
                builder: (ctx, st) => const AdminFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'admin-edit',
                builder: (ctx, st) => AdminFormScreen(
                  adminId: int.tryParse(st.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/roles',
            name: 'roles',
            builder: (ctx, st) => const RolesListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'role-new',
                builder: (ctx, st) => const RoleFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'role-edit',
                builder: (ctx, st) => RoleFormScreen(
                  roleId: int.tryParse(st.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/distributors',
            name: 'distributors',
            builder: (ctx, st) => const DistributorsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'distributor-new',
                builder: (ctx, st) => const DistributorFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'distributor-detail',
                builder: (ctx, st) => DistributorDetailScreen(
                  distributorId:
                      int.tryParse(st.pathParameters['id'] ?? '') ?? 0,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/sessions',
            name: 'sessions',
            builder: (ctx, st) => const SessionsListScreen(),
          ),
          GoRoute(
            path: '/audit',
            name: 'audit',
            builder: (ctx, st) => const AuditListScreen(),
          ),
          GoRoute(
            path: '/ledger',
            name: 'ledger',
            builder: (ctx, st) => const LedgerScreen(),
          ),
          GoRoute(
            path: '/reports',
            name: 'financial-reports',
            builder: (ctx, st) => const FinancialReportsScreen(),
          ),
          GoRoute(
            path: '/operational-reports',
            name: 'operational-reports',
            builder: (ctx, st) => const OperationalReportsScreen(),
          ),
          GoRoute(
            path: '/recycle-bin',
            name: 'recycle-bin',
            builder: (ctx, st) => const RecycleBinScreen(),
          ),
          GoRoute(
            path: '/backups',
            name: 'backups',
            builder: (ctx, st) => const BackupsScreen(),
          ),
          GoRoute(
            path: '/bandwidth-schedules',
            name: 'bandwidth-schedules',
            builder: (ctx, st) => const BandwidthSchedulesScreen(),
          ),
          GoRoute(
            path: '/print-templates',
            name: 'print-templates',
            builder: (ctx, st) => const PrintTemplatesScreen(),
          ),
          GoRoute(
            path: '/system-operations',
            name: 'system-operations',
            builder: (ctx, st) => const SystemOperationsScreen(),
          ),
          GoRoute(
            path: '/admin-control',
            name: 'admin-control',
            builder: (ctx, st) => const AdminControlScreen(),
          ),
          GoRoute(
            path: '/more',
            name: 'more',
            builder: (ctx, st) => const MoreScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (ctx, st) => Scaffold(
      body: Center(child: Text('صفحة غير موجودة: ${st.uri}')),
    ),
  );
});
