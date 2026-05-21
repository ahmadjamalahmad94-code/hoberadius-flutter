import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/card_checker_controller.dart';
import '../data/cards_repository.dart';
import 'widgets/card_checker_details.dart';
import 'widgets/card_checker_dialogs.dart';
import 'widgets/card_checker_operations.dart';
import 'widgets/card_checker_search.dart';
import 'widgets/card_checker_sessions.dart';
import 'widgets/card_checker_summary.dart';

/// Card-checker screen. Owns just the local search-text controller and
/// delegates state + actions to [cardCheckerControllerProvider].
class CardCheckerScreen extends ConsumerStatefulWidget {
  const CardCheckerScreen({super.key});

  @override
  ConsumerState<CardCheckerScreen> createState() => _CardCheckerScreenState();
}

class _CardCheckerScreenState extends ConsumerState<CardCheckerScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    await ref
        .read(cardCheckerControllerProvider.notifier)
        .search(_query.text);
  }

  Future<void> _runAction(
    Future<dynamic> Function(CardsRepository repo) call, {
    required String success,
  }) async {
    final outcome = await ref
        .read(cardCheckerControllerProvider.notifier)
        .runAction(
          (repo) async => await call(repo) as dynamic,
          success: success,
        );
    if (!mounted) return;
    final message = outcome.error ?? outcome.success;
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cardCheckerControllerProvider);
    final result = state.result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'منصة عمليات البطاقة',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: state.loading || _query.text.trim().isEmpty
                  ? null
                  : _search,
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        CardCheckerSearch(
          controller: _query,
          loading: state.loading,
          onSearch: _search,
        ),
        if (state.error != null) ...[
          const SizedBox(height: AppTokens.s12),
          CardCheckerInlineError(text: state.error!),
        ],
        const SizedBox(height: AppTokens.s16),
        if (result == null)
          const EmptyState(
            icon: Icons.manage_search_outlined,
            title: 'ابدأ بفحص بطاقة',
            subtitle: 'ستظهر الحالة، الجلسات، الأجهزة، والعمليات المتاحة هنا.',
          )
        else if (!result.exists)
          EmptyState(
            icon: Icons.credit_card_off_outlined,
            title: 'البطاقة غير موجودة',
            subtitle: 'لم نجد بطاقة تطابق "${result.query}".',
          )
        else ...[
          CardCheckerSummary(card: result),
          const SizedBox(height: AppTokens.s16),
          CardCheckerOperations(
            card: result,
            busy: state.actionLoading,
            onEnable: () => _runAction(
              (repo) => repo.enableCard(result.id!),
              success: 'تم تفعيل البطاقة.',
            ),
            onDisable: () async {
              final reason = await cardCheckerAskText(
                context,
                title: 'تعطيل البطاقة',
                label: 'سبب التعطيل',
              );
              if (!mounted || reason == null) return;
              await _runAction(
                (repo) => repo.disableCard(result.id!, reason: reason),
                success: 'تم تعطيل البطاقة بدون حذفها.',
              );
            },
            onLockMac: () async {
              final mac = await cardCheckerAskText(
                context,
                title: 'تثبيت MAC',
                label: 'عنوان الجهاز',
                initial: result.macAddress ?? '',
              );
              if (!mounted || mac == null || mac.isEmpty) return;
              await _runAction(
                (repo) => repo.lockCardMac(result.id!, mac),
                success: 'تم تثبيت الجهاز على البطاقة.',
              );
            },
            onUnlockMac: () => _runAction(
              (repo) => repo.unlockCardMac(result.id!),
              success: 'تم فك تثبيت الجهاز.',
            ),
            onResetUsage: () async {
              final ok = await cardCheckerConfirm(
                context,
                title: 'تصفير استخدام البطاقة',
                body:
                    'سيتم تصفير وقت بداية الاستخدام والجهاز المرصود. متابعة؟',
              );
              if (!mounted || !ok) return;
              await _runAction(
                (repo) => repo.resetCardUsage(result.id!),
                success: 'تم تصفير استخدام البطاقة.',
              );
            },
            onDisconnect: () async {
              final ok = await cardCheckerConfirm(
                context,
                title: 'طرد الجلسة',
                body: 'سيتم إرسال طلب طرد الجلسة النشطة لهذه البطاقة.',
              );
              if (!mounted || !ok) return;
              var sessionId = '';
              for (final session in result.accountingSummary.latestSessions) {
                if (session.online && session.sessionId.isNotEmpty) {
                  sessionId = session.sessionId;
                  break;
                }
              }
              await _runAction(
                (repo) => repo.disconnectCard(
                  result.id!,
                  sessionId: sessionId,
                ),
                success: 'تم إرسال طلب الطرد إلى الخادم.',
              );
            },
            onDeletePermanent: () async {
              final typed = await cardCheckerAskText(
                context,
                title: 'حذف نهائي شديد الحساسية',
                label: 'اكتب اسم البطاقة للتأكيد: ${result.username}',
              );
              if (!mounted || typed != result.username) return;
              await _runAction(
                (repo) => repo.deleteCardPermanently(
                  result.id!,
                  username: result.username,
                ),
                success: 'تم حذف البطاقة نهائيًا.',
              );
            },
          ),
          const SizedBox(height: AppTokens.s16),
          CardCheckerDetails(card: result),
          const SizedBox(height: AppTokens.s16),
          CardCheckerMacsCard(summary: result.accountingSummary),
          const SizedBox(height: AppTokens.s16),
          CardCheckerSessionsCard(
            sessions: result.accountingSummary.latestSessions,
          ),
          const SizedBox(height: AppTokens.s40),
        ],
      ],
    );
  }
}
