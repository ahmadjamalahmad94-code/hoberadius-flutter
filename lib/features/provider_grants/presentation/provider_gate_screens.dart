import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/provider_grants_provider.dart';
import '../domain/provider_service_labels.dart';

/// «الترخيص منتهي» — full lockout shown when the license is expired (or a sync
/// outage exceeded the local grace window, treated as expired). Only the
/// renew CTA + license/diagnostics surfaces stay reachable (router gate).
class LicenseExpiredScreen extends ConsumerWidget {
  const LicenseExpiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final license = ref.watch(effectiveGrantsProvider).license;
    final expiry = license.expiresAt;
    return _GateBody(
      icon: Icons.lock_clock_outlined,
      title: 'الترخيص منتهي',
      message: expiry == null
          ? 'انتهت صلاحية ترخيص النسخة. جدّد الاشتراك مع المزوّد لاستعادة الوصول الكامل للوحة.'
          : 'انتهت صلاحية ترخيص النسخة بتاريخ $expiry. جدّد الاشتراك مع المزوّد لاستعادة الوصول الكامل للوحة.',
      primaryLabel: 'تجديد الترخيص',
      primaryIcon: Icons.autorenew,
      onPrimary: () => context.goNamed('license-file'),
      secondaryLabel: 'إعادة المحاولة',
      onSecondary: () =>
          ref.read(providerGrantsProvider.notifier).refresh(),
    );
  }
}

/// «فعّل الترخيص» — shown for a never-activated install (no successful license
/// snapshot yet).
class LicenseActivateScreen extends ConsumerWidget {
  const LicenseActivateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GateBody(
      icon: Icons.verified_user_outlined,
      title: 'فعّل الترخيص',
      message:
          'لم يتم تفعيل هذه النسخة بعد. اربط النظام بلوحة المزوّد وفعّل الترخيص للبدء في استخدام اللوحة.',
      primaryLabel: 'تفعيل النسخة',
      primaryIcon: Icons.link,
      onPrimary: () => context.goNamed('license-file'),
      secondaryLabel: 'إعادة المحاولة',
      onSecondary: () =>
          ref.read(providerGrantsProvider.notifier).refresh(),
    );
  }
}

/// «الخدمة موقوفة من المزوّد» — shown when a disabled service is opened.
class ServiceBlockedScreen extends StatelessWidget {
  const ServiceBlockedScreen({super.key, required this.serviceKey});
  final String serviceKey;

  @override
  Widget build(BuildContext context) {
    final label = serviceLabelAr(serviceKey);
    return _GateBody(
      icon: Icons.block_outlined,
      title: 'الخدمة موقوفة من المزوّد',
      message: label.isEmpty
          ? 'أوقف المزوّد هذه الخدمة. تواصل مع مزوّد الخدمة لإعادة تفعيلها.'
          : 'أوقف المزوّد خدمة «$label». تواصل مع مزوّد الخدمة لإعادة تفعيلها.',
      primaryLabel: 'العودة للوحة',
      primaryIcon: Icons.home_outlined,
      onPrimary: () => context.goNamed('dashboard'),
    );
  }
}

/// «خدمة بانتظار التفعيل» — paid-not-active (locked_upgrade) service opened.
class ServiceUpgradeScreen extends StatelessWidget {
  const ServiceUpgradeScreen({super.key, required this.serviceKey});
  final String serviceKey;

  @override
  Widget build(BuildContext context) {
    final label = serviceLabelAr(serviceKey);
    return _GateBody(
      icon: Icons.lock_open_outlined,
      title: 'خدمة بانتظار التفعيل',
      message: label.isEmpty
          ? 'هذه الخدمة متاحة في الكتالوج لكنها تحتاج تفعيلًا/ترقية من المزوّد. اطلب تفعيلها للوصول إليها.'
          : 'خدمة «$label» متاحة في الكتالوج لكنها تحتاج تفعيلًا/ترقية من المزوّد. اطلب تفعيلها للوصول إليها.',
      primaryLabel: 'طلب تفعيل',
      primaryIcon: Icons.mail_outline,
      onPrimary: () => context.goNamed('tickets'),
      secondaryLabel: 'العودة للوحة',
      onSecondary: () => context.goNamed('dashboard'),
    );
  }
}

/// Shared centered lockout body — branded icon halo, title, message, CTAs.
class _GateBody extends StatelessWidget {
  const _GateBody({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: EmptyState(
          icon: icon,
          title: title,
          subtitle: message,
          action: Wrap(
            spacing: AppTokens.s12,
            runSpacing: AppTokens.s8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onPrimary,
                icon: Icon(primaryIcon),
                label: Text(primaryLabel),
              ),
              if (secondaryLabel != null && onSecondary != null)
                OutlinedButton(
                  onPressed: onSecondary,
                  child: Text(secondaryLabel!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
