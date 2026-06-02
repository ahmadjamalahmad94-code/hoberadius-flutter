import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/customer_portals_providers.dart';
import '../domain/customer_portals_model.dart';

class CustomerPortalsScreen extends ConsumerWidget {
  const CustomerPortalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(customerPortalsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'بوابات العملاء',
          subtitle:
              'روابط دخول العملاء الموجودة في الريدياس: بوابة المشترك وبوابة مستخدم البطاقة، مع توضيح ما تسمح به كل بوابة.',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(customerPortalsProvider),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => HubErrorState(
            title: 'تعذر جلب بوابات العملاء',
            subtitle: 'تحقق من اتصال التطبيق بالريدياس ثم أعد المحاولة.',
            onRetry: () => ref.invalidate(customerPortalsProvider),
          ),
          data: (state) => _Body(state: state),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final CustomerPortalsState state;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return const EmptyState(
        icon: Icons.door_front_door_outlined,
        title: 'لا توجد بوابات معرفة',
        subtitle: 'لم يرجع الخادم أي بوابة عملاء متاحة لهذا الريدياس.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          title: 'قيود الأمان',
          icon: Icons.shield_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                state.security.summary.isEmpty
                    ? 'هذه الصفحة تعرض روابط وإرشادات فقط.'
                    : state.security.summary,
                style: const TextStyle(color: AppTokens.textSecondary),
              ),
              const SizedBox(height: AppTokens.s12),
              Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: [
                  StatusPill(
                    text: state.security.adminNavigationOnly
                        ? 'تنقل إداري فقط'
                        : 'يتضمن إجراءات مباشرة',
                    tone: state.security.adminNavigationOnly
                        ? PillTone.green
                        : PillTone.orange,
                    dot: true,
                  ),
                  StatusPill(
                    text: state.security.usesExistingPortalSessions
                        ? 'يستخدم جلسات البوابة الأصلية'
                        : 'جلسات مستقلة',
                    tone: state.security.usesExistingPortalSessions
                        ? PillTone.green
                        : PillTone.neutral,
                    dot: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            if (!wide) {
              return Column(
                children: [
                  for (final item in state.items) ...[
                    _PortalCard(item: item),
                    const SizedBox(height: AppTokens.s12),
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < state.items.length; i++) ...[
                  Expanded(child: _PortalCard(item: state.items[i])),
                  if (i != state.items.length - 1)
                    const SizedBox(width: AppTokens.s12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PortalCard extends StatelessWidget {
  const _PortalCard({required this.item});

  final CustomerPortalItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: item.label,
      icon: item.key == 'subscriber_portal'
          ? Icons.person_outline
          : Icons.credit_card_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.description,
            style: const TextStyle(color: AppTokens.textSecondary),
          ),
          const SizedBox(height: AppTokens.s12),
          _PathRow(label: 'رابط الدخول العام', path: item.publicPath),
          const SizedBox(height: AppTokens.s8),
          _PathRow(label: 'رابط الدخول من الإدارة', path: item.adminPath),
          if (item.homePath.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            _PathRow(label: 'واجهة البوابة بعد الدخول', path: item.homePath),
          ],
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              for (final action in item.availableActions)
                StatusPill(
                  text: _actionLabel(action),
                  tone: PillTone.neutral,
                ),
            ],
          ),
          if (item.securityNote.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            Text(
              item.securityNote,
              style: const TextStyle(
                color: AppTokens.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.soft,
        border: Border.all(color: AppTokens.border),
        borderRadius: BorderRadius.circular(AppTokens.r10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                SelectableText(
                  path.isEmpty ? 'غير محدد' : path,
                  style: const TextStyle(
                    color: AppTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'نسخ الرابط',
            onPressed: path.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: path));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ الرابط')),
                    );
                  },
            icon: const Icon(Icons.copy, color: AppTokens.brand),
          ),
        ],
      ),
    );
  }
}

String _actionLabel(String action) {
  return switch (action) {
    'login' => 'تسجيل الدخول',
    'loan_request' => 'طلب سلفة',
    'renewal_request' => 'طلب تجديد',
    'redeem_card' => 'شحن المحفظة',
    'purchase_card' => 'شراء كرت',
    _ => 'إجراء بوابة',
  };
}
