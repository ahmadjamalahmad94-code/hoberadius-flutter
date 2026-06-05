import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/admins/presentation/admin_form_screen.dart';
import '../../features/admins/presentation/admins_list_screen.dart';
import '../../features/admins/presentation/role_form_screen.dart';
import '../../features/admins/presentation/roles_list_screen.dart';
import '../../features/accounting/presentation/financial_reports_screen.dart';
import '../../features/accounting/presentation/ledger_screen.dart';
import '../../features/accounting/presentation/subscriber_finance_screen.dart';
import '../../features/admin_control/presentation/admin_control_screen.dart';
import '../../features/audit/presentation/audit_list_screen.dart';
import 'app_page_transitions.dart';
import '../../features/sessions/presentation/sessions_list_screen.dart';
import '../../features/system_operations/presentation/license_file_screen.dart';
import '../../features/system_operations/presentation/system_operations_screen.dart';
import '../../features/tickets/presentation/ticket_detail_screen.dart';
import '../../features/tickets/presentation/tickets_list_screen.dart';
import '../../features/tools/presentation/tools_screen.dart';
import '../../features/wallets/presentation/wallets_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/backups/presentation/backups_screen.dart';
import '../../features/bandwidth_schedules/presentation/bandwidth_schedules_screen.dart';
import '../../features/card_users/presentation/card_user_360_screen.dart';
import '../../features/card_users/presentation/card_users_screen.dart';
import '../../features/cards/presentation/card_batch_detail_screen.dart';
import '../../features/cards/presentation/card_batch_edit_screen.dart';
import '../../features/cards/presentation/card_batch_form_screen.dart';
import '../../features/cards/presentation/card_batch_import_screen.dart';
import '../../features/cards/presentation/card_checker_screen.dart';
import '../../features/cards/presentation/cards_list_screen.dart';
import '../../features/cards/presentation/recharge_cards_screen.dart';
import '../../features/communications/presentation/communications_screen.dart';
import '../../features/customer_portals/presentation/customer_portals_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/device_fingerprints/presentation/device_fingerprints_screen.dart';
import '../../features/distributors/presentation/distributor_detail_screen.dart';
import '../../features/distributors/presentation/distributor_form_screen.dart';
import '../../features/distributors/presentation/distributors_list_screen.dart';
import '../../features/events/presentation/events_center_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/lifecycle/presentation/lifecycle_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/mikrotik/presentation/mikrotik_screen.dart';
import '../../features/mikrotik/presentation/router_operations_screen.dart';
import '../../features/nas/presentation/nas_form_screen.dart';
import '../../features/nas/presentation/nas_list_screen.dart';
import '../../features/network_devices/presentation/network_devices_screen.dart';
import '../../features/network_policy/presentation/network_policy_screen.dart';
import '../../features/operational_reports/presentation/operational_reports_screen.dart';
import '../../features/payment_collection/presentation/payment_collection_screen.dart';
import '../../features/plans/presentation/plan_form_screen.dart';
import '../../features/plans/presentation/plans_list_screen.dart';
import '../../features/print_templates/presentation/print_templates_screen.dart';
import '../../features/radius_resources/presentation/radius_resources_screen.dart';
import '../../features/recycle_bin/presentation/recycle_bin_screen.dart';
import '../../features/router_alerts/presentation/router_alerts_screen.dart';
import '../../features/saas_modules/presentation/saas_modules_screen.dart';
import '../../features/shell/shell_scaffold.dart';
import '../../features/setup_wizard/presentation/setup_wizard_screen.dart';
import '../../features/subscribers/presentation/subscriber_360_screen.dart';
import '../../features/subscribers/presentation/subscriber_form_screen.dart';
import '../../features/subscribers/presentation/subscribers_list_screen.dart';
import '../auth/auth_controller.dart';

/// Routes stay limited to screens backed by working Flask endpoints. Any form
/// route listed here is expected to use a real JSON contract.
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
        pageBuilder: (ctx, st) =>
            hubFadeThroughPage(child: const LoginScreen()),
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
                path: ':username/360',
                name: 'subscriber-360',
                builder: (ctx, st) => Subscriber360Screen(
                  username: st.pathParameters['username'] ?? '',
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
                path: 'import',
                name: 'card-batch-import',
                builder: (ctx, st) => const CardBatchImportScreen(),
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
            path: '/cards/recharge',
            name: 'cards-recharge',
            builder: (ctx, st) => const RechargeCardsScreen(),
          ),
          GoRoute(
            path: '/card-users',
            name: 'card-users',
            builder: (ctx, st) => const CardUsersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'card-user-360',
                builder: (ctx, st) => CardUser360Screen(
                  cardUserId: int.tryParse(st.pathParameters['id'] ?? '') ?? 0,
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
            path: '/mikrotik',
            name: 'mikrotik',
            builder: (ctx, st) => const MikrotikScreen(),
          ),
          GoRoute(
            path: '/router-operations',
            name: 'router-operations',
            builder: (ctx, st) => const RouterOperationsScreen(),
          ),
          GoRoute(
            path: '/setup-wizard',
            name: 'setup-wizard',
            builder: (ctx, st) => const SetupWizardScreen(),
          ),
          GoRoute(
            path: '/device-fingerprints',
            name: 'device-fingerprints',
            builder: (ctx, st) => const DeviceFingerprintsScreen(),
          ),
          GoRoute(
            path: '/network-devices',
            name: 'network-devices',
            builder: (ctx, st) => const NetworkDevicesScreen(),
          ),
          GoRoute(
            path: '/router-alerts',
            name: 'router-alerts',
            builder: (ctx, st) => const RouterAlertsScreen(),
          ),
          GoRoute(
            path: '/network-policy',
            name: 'network-policy',
            builder: (ctx, st) => const NetworkPolicyScreen(),
          ),
          GoRoute(
            path: '/radius-resources',
            name: 'radius-resources',
            builder: (ctx, st) => const RadiusResourcesScreen(),
          ),
          GoRoute(
            path: '/tickets',
            name: 'tickets',
            builder: (ctx, st) => const TicketsListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'ticket-detail',
                builder: (ctx, st) => TicketDetailScreen(
                  ticketId: int.tryParse(st.pathParameters['id'] ?? '') ?? 0,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/communications',
            name: 'communications',
            builder: (ctx, st) => const CommunicationsScreen(),
          ),
          GoRoute(
            path: '/customer-portals',
            name: 'customer-portals',
            builder: (ctx, st) => const CustomerPortalsScreen(),
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
            path: '/payment-collection',
            name: 'payment-collection',
            builder: (ctx, st) => const PaymentCollectionScreen(),
          ),
          GoRoute(
            path: '/invoices',
            name: 'invoices',
            builder: (ctx, st) => const InvoicesScreen(),
          ),
          GoRoute(
            path: '/wallets',
            name: 'wallets',
            builder: (ctx, st) => const WalletsScreen(),
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
            path: '/events',
            name: 'events-center',
            builder: (ctx, st) => const EventsCenterScreen(),
          ),
          GoRoute(
            path: '/saas-modules',
            name: 'saas-modules',
            builder: (ctx, st) => const SaasModulesScreen(),
          ),
          GoRoute(
            path: '/recycle-bin',
            name: 'recycle-bin',
            builder: (ctx, st) => const RecycleBinScreen(),
          ),
          GoRoute(
            path: '/lifecycle',
            name: 'lifecycle',
            builder: (ctx, st) => const LifecycleScreen(),
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
            path: '/license-file',
            name: 'license-file',
            builder: (ctx, st) => const LicenseFileScreen(),
          ),
          GoRoute(
            path: '/admin-control',
            name: 'admin-control',
            builder: (ctx, st) => const AdminControlScreen(),
          ),
          GoRoute(
            path: '/tools',
            name: 'tools',
            builder: (ctx, st) => const ToolsScreen(),
          ),
          GoRoute(
            path: '/more',
            name: 'more',
            builder: (ctx, st) => const MoreScreen(),
          ),
          GoRoute(
            path: '/account',
            name: 'account',
            builder: (ctx, st) => const AccountScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (ctx, st) => Scaffold(
      body: Center(child: Text('صفحة غير موجودة: ${st.uri}')),
    ),
  );
});
