import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/permissions.dart';
import '../../core/theme/tokens.dart';

/// What the shell's content area shows for the current session phase.
enum SessionContentPhase {
  /// The screen itself.
  ready,

  /// The saved token is being read, or `/api/admin/me` is pending and no
  /// saved grants exist: a neutral loading state (no screen is built, so no
  /// forbidden form opens and no forbidden request is sent — f07 N-B1).
  checking,

  /// `/api/admin/me` failed at start-up and no saved grants exist: the
  /// reason and a retry — the session is kept (f03 N3).
  unverified,
}

SessionContentPhase sessionContentPhase(AuthState auth, AppPermissions p) {
  if (auth.bootstrapping) return SessionContentPhase.checking;
  if (!auth.isAuthenticated) return SessionContentPhase.ready;
  if (!p.pending) return SessionContentPhase.ready;
  return auth.offline && !auth.restoring
      ? SessionContentPhase.unverified
      : SessionContentPhase.checking;
}

/// Wraps the routed screen: shows it only once this admin's grants are
/// known (from the server or this admin's saved copy).
class SessionContentGate extends ConsumerWidget {
  const SessionContentGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final perms = ref.watch(permissionsProvider);
    return switch (sessionContentPhase(auth, perms)) {
      SessionContentPhase.ready => child,
      SessionContentPhase.checking => const _Checking(),
      SessionContentPhase.unverified =>
        _Unverified(message: auth.offlineMessage),
    };
  }
}

class _Checking extends StatelessWidget {
  const _Checking();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'جارٍ التحقق من صلاحياتك',
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: AppTokens.s12),
            Text(
              'جارٍ التحقق من صلاحياتك…',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Unverified extends ConsumerWidget {
  const _Unverified({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: AppTokens.textMuted,
          ),
          const SizedBox(height: AppTokens.s12),
          const Text(
            'تعذّر التحقق من صلاحياتك',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            message.isEmpty ? kSessionOfflineMessage : message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTokens.textSecondary),
          ),
          const SizedBox(height: AppTokens.s4),
          const Text(
            'جلستك محفوظة — أعد المحاولة عند توفّر الاتصال.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTokens.textMuted, fontSize: 12),
          ),
          const SizedBox(height: AppTokens.s16),
          FilledButton.icon(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).retrySession(),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

/// The offline banner above the content: `/api/admin/me` failed at
/// start-up, the app runs on this admin's saved grants.
class SessionOfflineBanner extends ConsumerWidget {
  const SessionOfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (!auth.isAuthenticated || !auth.offline) return const SizedBox.shrink();
    final msg = auth.offlineMessage.isEmpty
        ? kSessionOfflineMessage
        : auth.offlineMessage;
    return Semantics(
      liveRegion: true,
      container: true,
      label: 'تنبيه الاتصال: $msg',
      child: Material(
        color: AppTokens.warningBg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12,
            vertical: AppTokens.s8,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 18,
                color: AppTokens.warningFg,
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  msg,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.warningFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s4),
              auth.restoring
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: () => ref
                          .read(authControllerProvider.notifier)
                          .retrySession(),
                      child: const Text('إعادة المحاولة'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
