import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admins/presentation/admins_list_screen.dart';
import '../../features/admins/presentation/roles_list_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/cards/presentation/card_batch_form_screen.dart';
import '../../features/cards/presentation/cards_list_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/nas/presentation/nas_list_screen.dart';
import '../../features/plans/presentation/plans_list_screen.dart';
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
            ],
          ),
          GoRoute(
            path: '/nas',
            name: 'nas',
            builder: (ctx, st) => const NasListScreen(),
          ),
          GoRoute(
            path: '/plans',
            name: 'plans',
            builder: (ctx, st) => const PlansListScreen(),
          ),
          GoRoute(
            path: '/admins',
            name: 'admins',
            builder: (ctx, st) => const AdminsListScreen(),
          ),
          GoRoute(
            path: '/roles',
            name: 'roles',
            builder: (ctx, st) => const RolesListScreen(),
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
