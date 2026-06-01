import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/admin_control_providers.dart';
import '../../domain/admin_control_model.dart';
import 'admin_section_common.dart';

class TokensPanel extends ConsumerWidget {
  const TokensPanel({
    super.key,
    required this.onCreate,
    required this.onRevoke,
    required this.busy,
  });

  final VoidCallback onCreate;
  final ValueChanged<ApiTokenRecord> onRevoke;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(apiTokensProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'المفتاح السري يظهر مرة واحدة عند الإنشاء فقط. القوائم لا تعرض token ولا hash.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
              ElevatedButton.icon(
                onPressed: busy ? null : onCreate,
                icon: const Icon(Icons.add),
                label: const Text('مفتاح جديد'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const AdminLoadingCard(title: 'مفاتيح API'),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب المفاتيح',
            subtitle: visibleErrorMessage(e),
          ),
          data: (tokens) => AppCard(
            title: 'مفاتيح API',
            icon: Icons.key,
            padding: EdgeInsets.zero,
            child: tokens.isEmpty
                ? const EmptyState(
                    icon: Icons.key_off_outlined,
                    title: 'لا توجد مفاتيح API',
                  )
                : AdminListSection(
                    count: tokens.length,
                    itemBuilder: (_, i) {
                      final token = tokens[i];
                      return ListTile(
                        title: Text(token.name),
                        subtitle: Text(
                          [
                            if (token.scopes.isNotEmpty)
                              token.scopes.join(', '),
                            if (token.lastUsedAt.isNotEmpty)
                              'آخر استخدام: ${token.lastUsedAt}',
                            if (token.expiresAt.isNotEmpty)
                              'ينتهي: ${token.expiresAt}',
                          ].join(' • '),
                        ),
                        leading: StatusPill(
                          text: token.revoked ? 'ملغى' : 'مفعّل',
                          tone: token.revoked ? PillTone.red : PillTone.green,
                        ),
                        trailing: token.revoked
                            ? null
                            : IconButton(
                                tooltip: 'إلغاء',
                                onPressed: busy ? null : () => onRevoke(token),
                                icon: const Icon(Icons.block),
                              ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
