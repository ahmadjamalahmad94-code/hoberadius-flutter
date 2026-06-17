import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hoberadius_app/features/account/presentation/account_screen.dart';
import 'package:hoberadius_app/features/accounting/presentation/financial_reports_screen.dart';
import 'package:hoberadius_app/features/accounting/presentation/ledger_screen.dart';
import 'package:hoberadius_app/features/accounting/presentation/loans_center_screen.dart';
import 'package:hoberadius_app/features/accounting/presentation/subscriber_finance_screen.dart';
import 'package:hoberadius_app/features/admin_control/presentation/admin_control_screen.dart';
import 'package:hoberadius_app/features/admins/presentation/admin_form_screen.dart';
import 'package:hoberadius_app/features/admins/presentation/admins_list_screen.dart';
import 'package:hoberadius_app/features/admins/presentation/role_form_screen.dart';
import 'package:hoberadius_app/features/admins/presentation/roles_list_screen.dart';
import 'package:hoberadius_app/features/audit/presentation/audit_list_screen.dart';
import 'package:hoberadius_app/features/backups/presentation/backups_screen.dart';
import 'package:hoberadius_app/features/bandwidth_schedules/presentation/bandwidth_schedules_screen.dart';
import 'package:hoberadius_app/features/business_ops/presentation/business_ops_screen.dart';
import 'package:hoberadius_app/features/card_users/presentation/card_user_360_screen.dart';
import 'package:hoberadius_app/features/card_users/presentation/card_users_screen.dart';
import 'package:hoberadius_app/features/cards/presentation/card_batch_detail_screen.dart';
import 'package:hoberadius_app/features/cards/presentation/card_batch_edit_screen.dart';
import 'package:hoberadius_app/features/cards/presentation/card_batch_form_screen.dart';
import 'package:hoberadius_app/features/cards/presentation/card_batch_import_screen.dart';
import 'package:hoberadius_app/features/cards/presentation/card_checker_screen.dart';
import 'package:hoberadius_app/features/cards/presentation/cards_list_screen.dart';
import 'package:hoberadius_app/features/cards/presentation/recharge_cards_screen.dart';
import 'package:hoberadius_app/features/communications/presentation/communications_screen.dart';
import 'package:hoberadius_app/features/customer_portals/presentation/customer_portals_screen.dart';
import 'package:hoberadius_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:hoberadius_app/features/device_fingerprints/presentation/device_fingerprints_screen.dart';
import 'package:hoberadius_app/features/distributors/presentation/distributor_detail_screen.dart';
import 'package:hoberadius_app/features/distributors/presentation/distributor_form_screen.dart';
import 'package:hoberadius_app/features/distributors/presentation/distributors_list_screen.dart';
import 'package:hoberadius_app/features/events/presentation/events_center_screen.dart';
import 'package:hoberadius_app/features/invoices/presentation/invoices_screen.dart';
import 'package:hoberadius_app/features/lifecycle/presentation/lifecycle_screen.dart';
import 'package:hoberadius_app/features/mikrotik/presentation/mikrotik_screen.dart';
import 'package:hoberadius_app/features/mikrotik/presentation/router_operations_screen.dart';
import 'package:hoberadius_app/features/more/presentation/more_screen.dart';
import 'package:hoberadius_app/features/nas/presentation/nas_form_screen.dart';
import 'package:hoberadius_app/features/nas/presentation/nas_list_screen.dart';
import 'package:hoberadius_app/features/network_devices/presentation/network_devices_screen.dart';
import 'package:hoberadius_app/features/network_policy/presentation/network_policy_screen.dart';
import 'package:hoberadius_app/features/operational_reports/presentation/operational_report_detail_screen.dart';
import 'package:hoberadius_app/features/operational_reports/presentation/reports_center_screen.dart';
import 'package:hoberadius_app/features/payment_collection/presentation/payment_collection_screen.dart';
import 'package:hoberadius_app/features/payment_collection/presentation/payment_request_detail_screen.dart';
import 'package:hoberadius_app/features/plans/presentation/plan_form_screen.dart';
import 'package:hoberadius_app/features/plans/presentation/plans_list_screen.dart';
import 'package:hoberadius_app/features/print_templates/presentation/print_templates_screen.dart';
import 'package:hoberadius_app/features/radius_resources/presentation/radius_resources_screen.dart';
import 'package:hoberadius_app/features/recycle_bin/presentation/recycle_bin_screen.dart';
import 'package:hoberadius_app/features/revenue/presentation/revenue_screen.dart';
import 'package:hoberadius_app/features/router_alerts/presentation/router_alerts_screen.dart';
import 'package:hoberadius_app/features/saas_modules/presentation/saas_modules_screen.dart';
import 'package:hoberadius_app/features/sessions/presentation/sessions_list_screen.dart';
import 'package:hoberadius_app/features/setup_wizard/presentation/setup_wizard_screen.dart';
import 'package:hoberadius_app/features/subscribers/presentation/subscriber_360_screen.dart';
import 'package:hoberadius_app/features/subscribers/presentation/subscriber_form_screen.dart';
import 'package:hoberadius_app/features/subscribers/presentation/subscribers_list_screen.dart';
import 'package:hoberadius_app/features/system_operations/presentation/license_file_screen.dart';
import 'package:hoberadius_app/features/system_operations/presentation/system_operations_screen.dart';
import 'package:hoberadius_app/features/tickets/presentation/ticket_detail_screen.dart';
import 'package:hoberadius_app/features/tickets/presentation/tickets_list_screen.dart';
import 'package:hoberadius_app/features/tools/presentation/tools_screen.dart';
import 'package:hoberadius_app/features/vouchers/presentation/vouchers_screen.dart';
import 'package:hoberadius_app/features/wallets/presentation/wallets_screen.dart';

import 'screen_sweep_harness.dart';

typedef ScreenBuilder = Widget Function();

/// Every routed shell screen + its constructor. Detail/form screens get dummy
/// ids/usernames — the fake API client resolves them to empty/error states,
/// which is exactly what we want to overflow-check.
final screens = <String, ScreenBuilder>{
  'dashboard': DashboardScreen.new,
  'subscribers-list': SubscribersListScreen.new,
  'subscriber-new': SubscriberFormScreen.new,
  'subscriber-edit': () => const SubscriberFormScreen(username: 'u1'),
  'subscriber-360': () => const Subscriber360Screen(username: 'u1'),
  'subscriber-finance': () => const SubscriberFinanceScreen(username: 'u1'),
  'cards-list': CardsListScreen.new,
  'card-batch-new': CardBatchFormScreen.new,
  'card-batch-import': CardBatchImportScreen.new,
  'card-checker': CardCheckerScreen.new,
  'card-batch-detail': () => const CardBatchDetailScreen(batchId: 1),
  'card-batch-edit': () => const CardBatchEditScreen(batchId: 1),
  'cards-recharge': RechargeCardsScreen.new,
  'card-users': CardUsersScreen.new,
  'card-user-360': () => const CardUser360Screen(cardUserId: 1),
  'nas-list': NasListScreen.new,
  'nas-new': NasFormScreen.new,
  'nas-edit': () => const NasFormScreen(nasId: 1),
  'mikrotik': MikrotikScreen.new,
  'router-operations': RouterOperationsScreen.new,
  'setup-wizard': SetupWizardScreen.new,
  'device-fingerprints': DeviceFingerprintsScreen.new,
  'network-devices': NetworkDevicesScreen.new,
  'router-alerts': RouterAlertsScreen.new,
  'network-policy': NetworkPolicyScreen.new,
  'radius-resources': RadiusResourcesScreen.new,
  'tickets': TicketsListScreen.new,
  'ticket-detail': () => const TicketDetailScreen(ticketId: 1),
  'communications': CommunicationsScreen.new,
  'customer-portals': CustomerPortalsScreen.new,
  'plans-list': PlansListScreen.new,
  'plan-new': PlanFormScreen.new,
  'plan-edit': () => const PlanFormScreen(planId: 1),
  'admins-list': AdminsListScreen.new,
  'admin-new': AdminFormScreen.new,
  'admin-edit': () => const AdminFormScreen(adminId: 1),
  'roles-list': RolesListScreen.new,
  'role-new': RoleFormScreen.new,
  'role-edit': () => const RoleFormScreen(roleId: 1),
  'distributors-list': DistributorsListScreen.new,
  'distributor-new': DistributorFormScreen.new,
  'distributor-detail': () => const DistributorDetailScreen(distributorId: 1),
  'sessions': SessionsListScreen.new,
  'audit': AuditListScreen.new,
  'ledger': LedgerScreen.new,
  'payment-collection': PaymentCollectionScreen.new,
  'payment-request-detail': () =>
      const PaymentRequestDetailScreen(requestId: 1),
  'invoices': InvoicesScreen.new,
  'vouchers': VouchersScreen.new,
  'wallets': WalletsScreen.new,
  'loans-center': LoansCenterScreen.new,
  'revenue': RevenueScreen.new,
  'financial-reports': FinancialReportsScreen.new,
  'reports-center': ReportsCenterScreen.new,
  'operational-report-detail': () =>
      const OperationalReportDetailScreen(slug: 'sessions'),
  'business-ops': BusinessOpsScreen.new,
  'events-center': EventsCenterScreen.new,
  'saas-modules': SaasModulesScreen.new,
  'recycle-bin': RecycleBinScreen.new,
  'lifecycle': LifecycleScreen.new,
  'backups': BackupsScreen.new,
  'bandwidth-schedules': BandwidthSchedulesScreen.new,
  'print-templates': PrintTemplatesScreen.new,
  'system-operations': SystemOperationsScreen.new,
  'license-file': LicenseFileScreen.new,
  'admin-control': AdminControlScreen.new,
  'tools': ToolsScreen.new,
  'more': MoreScreen.new,
  'account': AccountScreen.new,
};

void main() {
  group('no horizontal overflow across mobile/tablet/Windows widths', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} lays out cleanly', (tester) async {
        await expectNoOverflowAcrossWidths(tester, entry.value, entry.key);
      });
    }
  });
}
