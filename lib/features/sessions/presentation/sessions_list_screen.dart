import 'dart:async';

import 'package:hoberadius_app/core/format/number_input.dart';
import 'package:flutter/material.dart';
import 'package:hoberadius_app/core/format/server_time.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/format/bidi.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/auto_height_grid.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/load_more_footer.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/even_choice_bar.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../cards/data/cards_repository.dart';
import '../../subscribers/data/subscriber_actions_repository.dart';
import '../data/sessions_repository.dart';
import '../domain/session_model.dart';

class SessionsListScreen extends ConsumerStatefulWidget {
  const SessionsListScreen({super.key});

  @override
  ConsumerState<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends ConsumerState<SessionsListScreen> {
  final _searchController = TextEditingController();
  OnlineSessionKind _kind = OnlineSessionKind.all;
  AccessKind _access = AccessKind.all;
  String _search = '';

  OnlineSessionsQuery get _query =>
      OnlineSessionsQuery(kind: _kind, search: _search, access: _access);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 ك.ب';
    const units = ['ب', 'ك.ب', 'م.ب', 'ج.ب', 'ت.ب'];
    double value = bytes.toDouble();
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }
    return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[index]}';
  }

  String _formatDuration(int seconds) => compactSessionDuration(seconds);

  void _refresh() {
    ref.invalidate(onlineSessionsProvider(_query));
    ref.invalidate(onlineTotalsProvider);
    ref.invalidate(accountingHistoryProvider);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    Color? actionColor,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: actionColor == null
                ? null
                : ElevatedButton.styleFrom(backgroundColor: actionColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _runAction({
    required OnlineSession session,
    required String successMessage,
    required Future<Object?> Function(SessionsRepository repo) action,
    SessionActionOutcome Function(Object? result)? outcome,
  }) async {
    try {
      final result = await action(ref.read(sessionsRepositoryProvider));
      if (!mounted) return;
      final o = outcome?.call(result) ??
          SessionActionOutcome(message: successMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(o.message),
          backgroundColor: o.warning ? AppTokens.warningFg : null,
          duration: o.warning
              ? const Duration(seconds: 8)
              : const Duration(milliseconds: 4000),
        ),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    }
  }

  Future<void> _disconnect(OnlineSession session) async {
    final ok = await _confirm(
      title: 'طرد الجلسة',
      message: 'سيتم إرسال أمر فصل مباشر للجلسة الخاصة بـ ${session.username}.',
      action: 'طرد الآن',
      actionColor: AppTokens.red,
    );
    if (!ok) return;
    await _runAction(
      session: session,
      successMessage: 'تم إرسال أمر الطرد لـ ${session.username}.',
      action: (repo) => repo.disconnect(
        username: session.username,
        sessionId: session.sessionId,
      ),
    );
  }

  Future<void> _lockMac(OnlineSession session) async {
    final mac = session.callingStationId.isEmpty
        ? 'MAC الجلسة الحالية'
        : session.callingStationId;
    final ok = await _confirm(
      title: 'تثبيت MAC',
      message: 'سيتم تثبيت $mac على حساب ${session.username}.',
      action: 'تثبيت MAC',
    );
    if (!ok) return;
    await _runAction(
      session: session,
      successMessage: 'تم تثبيت MAC على ${session.username}.',
      action: (repo) => repo.lockMac(
        username: session.username,
        sessionId: session.sessionId,
      ),
    );
  }

  Future<void> _lockIp(OnlineSession session) async {
    final ip = session.framedIpAddress.isEmpty
        ? 'IP الجلسة الحالية'
        : session.framedIpAddress;
    final ok = await _confirm(
      title: 'تثبيت IP',
      message: 'سيتم تثبيت $ip كعنوان ثابت للمشترك ${session.username}.',
      action: 'تثبيت IP',
    );
    if (!ok) return;
    await _runAction(
      session: session,
      successMessage: 'تم تثبيت IP على ${session.username}.',
      action: (repo) => repo.lockIp(
        username: session.username,
        sessionId: session.sessionId,
      ),
    );
  }

  Future<void> _applyTemporarySpeed(OnlineSession session) async {
    final draft = await _showTemporarySpeedDialog(context);
    if (draft == null) return;
    await _runAction(
      session: session,
      successMessage: 'تم طلب تطبيق السرعة المؤقتة على ${session.username}.',
      // The router's answer decides the message: «saved but NOT applied»
      // is a warning, never a plain success (f06 L5).
      outcome: (res) => tempSpeedOutcome(
        session.username,
        res is Map<String, dynamic> ? res : const {},
      ),
      action: (repo) async {
        return repo.applyTemporarySpeed(
          username: session.username,
          sessionId: session.sessionId,
          downloadKbps: draft.downloadKbps,
          uploadKbps: draft.uploadKbps,
          duration: draft.duration,
          durationUnit: draft.durationUnit,
        );
      },
    );
  }

  Future<void> _cancelTemporarySpeed(OnlineSession session) async {
    final ok = await _confirm(
      title: 'إلغاء السرعة المؤقتة',
      message:
          'سيتم إرجاع ${session.username} إلى سرعته الأصلية إن وجدت نافذة مؤقتة فعالة.',
      action: 'إلغاء السرعة',
    );
    if (!ok) return;
    await _runAction(
      session: session,
      successMessage: 'تم طلب إلغاء السرعة المؤقتة لـ ${session.username}.',
      outcome: (res) => cancelTempSpeedOutcome(
        session.username,
        res is Map<String, dynamic> ? res : const {},
      ),
      action: (repo) => repo.cancelTemporarySpeed(
        username: session.username,
        sessionId: session.sessionId,
      ),
    );
  }

  /// Runs a non-session action (card / subscriber API), shows the server's
  /// message on failure and refreshes the list on success.
  Future<void> _runTask({
    required String success,
    required Future<Object?> Function() task,
  }) async {
    try {
      await task();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success)),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    }
  }

  Future<void> _disableSubscriber(OnlineSession session) async {
    final ok = await _confirm(
      title: 'تعطيل المشترك',
      message: 'تعطيل «${session.username}»؟ لن يتمكّن من الاتصال حتى يُفعَّل.',
      action: 'تعطيل',
      actionColor: AppTokens.red,
    );
    if (!ok) return;
    await _runTask(
      success: 'تم تعطيل ${session.username}.',
      task: () => ref
          .read(subscriberActionsRepositoryProvider)
          .disable(session.username),
    );
  }

  Future<void> _changeCardTime(OnlineSession session) async {
    final id = session.cardId;
    if (id == null) return;
    final draft = await showCardTimeDialog(context, username: session.username);
    if (draft == null) return;
    try {
      final res = await ref.read(sessionsRepositoryProvider).adjustCardTime(
            id,
            amount: draft.amount,
            unit: draft.unit,
            subtract: draft.subtract,
          );
      if (!mounted) return;
      final o = cardTimeOutcome(session.username, draft, res);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(o.message),
          backgroundColor: o.warning ? AppTokens.warningFg : null,
          duration: o.warning
              ? const Duration(seconds: 8)
              : const Duration(milliseconds: 4000),
        ),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    }
  }

  Future<void> _resetCardUsage(OnlineSession session) async {
    final id = session.cardId;
    if (id == null) return;
    final ok = await _confirm(
      title: 'تصفير استخدام الكرت',
      message: 'تصفير استخدام «${session.username}»؟ يُصفَّر وقت بداية '
          'الاستخدام والجهاز المرصود.',
      action: 'تصفير',
      actionColor: AppTokens.brand,
    );
    if (!ok) return;
    await _runTask(
      success: 'تم تصفير استخدام ${session.username}.',
      task: () => ref.read(cardsRepositoryProvider).resetCardUsage(id),
    );
  }

  Future<void> _disableCard(OnlineSession session) async {
    final id = session.cardId;
    if (id == null) return;
    final ok = await _confirm(
      title: 'تعطيل الكرت',
      message: 'تعطيل الكرت «${session.username}»؟ لن يتمكّن من الاتصال '
          'حتى يُفعَّل من فحص الكرت.',
      action: 'تعطيل',
      actionColor: AppTokens.red,
    );
    if (!ok) return;
    await _runTask(
      success: 'تم تعطيل الكرت ${session.username}.',
      task: () => ref.read(cardsRepositoryProvider).disableCard(id),
    );
  }

  Future<void> _deleteCard(OnlineSession session) async {
    final id = session.cardId;
    if (id == null) return;
    final ok = await _confirm(
      title: 'حذف الكرت نهائيًا',
      message: 'سيُحذف الكرت «${session.username}» نهائيًا ولا يمكن التراجع '
          'عن ذلك. متابعة؟',
      action: 'حذف نهائي',
      actionColor: AppTokens.red,
    );
    if (!ok) return;
    await _runTask(
      success: 'تم حذف الكرت ${session.username} نهائيًا.',
      task: () => ref.read(cardsRepositoryProvider).deleteCardPermanently(
            id,
            username: session.username,
          ),
    );
  }

  /// «المزيد ⋯»: the less frequent actions + the router / start time.
  Future<void> _showMore(OnlineSession session, SessionMorePermissions perms) {
    final items = sessionMoreActions(session, perms);
    final df = DateFormat('yyyy-MM-dd HH:mm');
    VoidCallback run(SessionMoreAction a) => switch (a) {
          SessionMoreAction.lockIp => () => _lockIp(session),
          SessionMoreAction.subscriberProfile => () => context.goNamed(
                'subscriber-360',
                pathParameters: {'username': session.username},
              ),
          SessionMoreAction.cancelSpeed => () => _cancelTemporarySpeed(session),
          SessionMoreAction.cardChecker => () => context.goNamed(
                'card-checker',
                queryParameters: {'q': session.username},
              ),
          SessionMoreAction.disableSubscriber => () =>
              _disableSubscriber(session),
          SessionMoreAction.resetCardUsage => () => _resetCardUsage(session),
          SessionMoreAction.disableCard => () => _disableCard(session),
          SessionMoreAction.deleteCard => () => _deleteCard(session),
        };
    return showModalBottomSheet<void>(
      // Above the whole app: the shell's pages live inside one scroll view, so
      // a sheet on the inner navigator is drawn off-screen (same as the
      // subscriber actions sheet) — caught by a real tap on «المزيد».
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s16,
            0,
            AppTokens.s16,
            AppTokens.s12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                session.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTokens.sidebarBg,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              InfoGrid(
                columns: 2,
                items: [
                  InfoItem(
                    icon: Icons.router,
                    label: 'الراوتر',
                    value: session.nasIpAddress.isEmpty
                        ? '—'
                        : ltrIsolate(session.nasIpAddress),
                  ),
                  InfoItem(
                    icon: Icons.play_circle_outline,
                    label: 'بدأت',
                    value: session.startedAt == null
                        ? '—'
                        : df.format(session.startedAt!.toLocal()),
                  ),
                ],
              ),
              if (items.isNotEmpty) const SizedBox(height: AppTokens.s4),
              for (final item in items)
                ListTile(
                  key: ValueKey('more-${item.name}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(
                    item.icon,
                    color: item.danger ? AppTokens.red : AppTokens.brand,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: item.danger
                          ? AppTokens.dangerFg
                          : AppTokens.sidebarBg,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    run(item)();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onlineAsync = ref.watch(onlineSessionsProvider(_query));
    final historyAsync = ref.watch(accountingHistoryProvider);
    // Each live action follows its own server grant (online.* keys).
    final permissions = ref.watch(permissionsProvider);
    final acts = SessionActionPermissions(permissions);
    final perms = SessionMorePermissions.of(permissions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'المتصلون الآن',
          subtitle: 'الجلسات الحيّة: طرد، تثبيت MAC/IP، وسرعة مؤقتة.',
          inlineActions: true,
          actions: [
            const _LivePulseChip(),
            const SizedBox(width: AppTokens.s8),
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: _refresh,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        _FiltersCard(
          kind: _kind,
          access: _access,
          accessCounts: onlineAsync.valueOrNull?.accessCounts,
          searchController: _searchController,
          onKindChanged: (kind) {
            if (_kind == kind) return;
            setState(() => _kind = kind);
          },
          onAccessChanged: (access) {
            if (_access == access) return;
            setState(() => _access = access);
          },
          onSearch: () {
            final next = _searchController.text.trim();
            if (next == _search) {
              ref.invalidate(onlineSessionsProvider(_query));
              return;
            }
            setState(() => _search = next);
          },
        ),
        const SizedBox(height: AppTokens.s12),
        onlineAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب المتصلين',
            subtitle: visibleErrorMessage(error),
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(onlineSessionsProvider(_query)),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (loaded) {
            final items = loaded.items;
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.signal_wifi_off_outlined,
                title: _emptyTitle(_kind),
                subtitle:
                    'أي جلسة نشطة ستظهر هنا عند وصولها من سجلات الريدياس.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryStrip(
                  // 4th tile (owner: no lonely 3rd tile) — the WHOLE network:
                  // the page's own `speeds` when nothing is filtered (no extra
                  // request), the unfiltered totals read otherwise.
                  temporarySpeed: _query == const OnlineSessionsQuery()
                      ? (loaded.speedCounts ??
                          const <String, int>{})['temporary']
                      : ref
                          .watch(onlineTotalsProvider)
                          .valueOrNull
                          ?.temporarySpeed,
                  counts: onlineSummaryCounts(
                    filtered: _query,
                    items: items,
                    total: loaded.list.total,
                    typeCounts: loaded.typeCounts,
                    // A tab / search is on: the tiles still show the WHOLE
                    // network (f06 L7 «كل المتصلين 6» with 602 cards on).
                    overall: _query == const OnlineSessionsQuery()
                        ? null
                        : ref.watch(onlineTotalsProvider).valueOrNull,
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                for (final session in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s8),
                    child: _SessionTile(
                      session: session,
                      formatBytes: _formatBytes,
                      formatDuration: _formatDuration,
                      onDisconnect:
                          acts.disconnect ? () => _disconnect(session) : null,
                      onLockMac: acts.lockMac ? () => _lockMac(session) : null,
                      onMore: () => _showMore(session, perms),
                      // Cards too: updated servers apply a card's temp speed;
                      // an older one answers with its own message (422).
                      onTemporarySpeed: acts.tempSpeed
                          ? () => _applyTemporarySpeed(session)
                          : null,
                      onCancelTemporarySpeed:
                          session.isSubscriber && acts.tempSpeed
                              ? () => _cancelTemporarySpeed(session)
                              : null,
                      onChangeTime: session.isCard &&
                              session.cardId != null &&
                              perms.cardOps
                          ? () => _changeCardTime(session)
                          : null,
                    ),
                  ),
                LoadMoreFooter(
                  hasMore: loaded.list.hasMore,
                  loading: loaded.list.loadingMore,
                  error: loaded.list.loadMoreError,
                  shown: items.length,
                  total: loaded.list.total,
                  onLoadMore: () => ref
                      .read(onlineSessionsProvider(_query).notifier)
                      .loadMore(),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppTokens.s16),
        _HistorySection(
          async: historyAsync,
          formatBytes: _formatBytes,
          formatDuration: _formatDuration,
        ),
      ],
    );
  }
}

String _emptyTitle(OnlineSessionKind kind) => switch (kind) {
      OnlineSessionKind.cards => 'لا توجد كروت متصلة الآن',
      OnlineSessionKind.subscribers => 'لا يوجد مشتركون متصلون الآن',
      OnlineSessionKind.all => 'لا يوجد متصلون الآن',
    };

class _LivePulseChip extends StatefulWidget {
  const _LivePulseChip();

  @override
  State<_LivePulseChip> createState() => _LivePulseChipState();
}

class _LivePulseChipState extends State<_LivePulseChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTokens.successBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_controller),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTokens.successStrong,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'مباشر',
            style: TextStyle(
              color: AppTokens.successFg,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.kind,
    required this.access,
    required this.searchController,
    required this.onKindChanged,
    required this.onAccessChanged,
    required this.onSearch,
    this.accessCounts,
  });

  final OnlineSessionKind kind;
  final AccessKind access;
  final Map<String, int>? accessCounts;
  final TextEditingController searchController;
  final ValueChanged<OnlineSessionKind> onKindChanged;
  final ValueChanged<AccessKind> onAccessChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<OnlineSessionKind>(
            // Text-only AND no checkmark: the ✓ alone still wrapped
            // «المشتركو/ن» on a selected segment (owner, 2026-10-01). The
            // fill colour shows the selection.
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: OnlineSessionKind.all,
                label: Text('الكل'),
              ),
              ButtonSegment(
                value: OnlineSessionKind.subscribers,
                label: Text('المشتركون'),
              ),
              ButtonSegment(
                value: OnlineSessionKind.cards,
                label: Text('الكروت'),
              ),
            ],
            selected: {kind},
            onSelectionChanged: (selection) => onKindChanged(selection.first),
          ),
          const SizedBox(height: AppTokens.s8),
          AccessFilterBar(
            value: access,
            counts: accessCounts,
            onChanged: onAccessChanged,
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: const InputDecoration(
                    labelText: 'بحث',
                    hintText: 'اسم الدخول أو MAC أو IP',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              SizedBox(
                width: 56,
                height: 56,
                child: FilledButton(
                  onPressed: onSearch,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.s12),
                    ),
                  ),
                  child: const Icon(Icons.search),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What a live-session action reports to the operator.
class SessionActionOutcome {
  const SessionActionOutcome({required this.message, this.warning = false});
  final String message;

  /// Done on the server but NOT confirmed by the router.
  final bool warning;
}

/// Arabic reason of a CoA / PoD result code (`coa.code`) — the server's
/// own table (`radius_coa.coa_code_ar`, fix3 cardsnet), word for word, so
/// the app and the web say the same thing.
const Map<String, String> kCoaCodeLabels = {
  'router_not_configured': 'راوتر الجلسة معطّل أو بلا كلمة سرّ RADIUS',
  'timeout': 'لم يردّ الراوتر (انتهت المهلة)',
  'socket_error': 'تعذّر الإرسال إلى الراوتر',
  'malformed': 'ردّ غير صالح من الراوتر',
  'no_active_session': 'لا جلسة نشطة',
  'empty_rate': 'لا سرعة صالحة للإرسال',
  'empty_timeout': 'لا مهلة صالحة للإرسال',
  'exception': 'خطأ داخليّ أثناء الإرسال',
  'no_coa': 'لم يُرسَل أمر CoA',
  'CoA-ACK': 'أكّد الراوتر التطبيق',
  'Disconnect-ACK': 'أكّد الراوتر الفصل',
  'CoA-NAK': 'رفض الراوتر الأمر (CoA-NAK)',
  'Disconnect-NAK': 'رفض الراوتر الفصل (Disconnect-NAK)',
};

String coaFailureReason(String code) {
  final c = code.trim();
  final known = kCoaCodeLabels[c];
  if (known != null) return known;
  if (c.startsWith('unknown-code-')) return 'ردّ غير معروف من الراوتر';
  return 'تعذّر تأكيد التطبيق على الراوتر';
}

/// The message after «إلغاء السرعة» — the web's two flashes
/// (routes/sessions.py online_temp_speed_cancel): `temporary_speed.reverted`
/// false means there was no active temp window, NOT a success.
SessionActionOutcome cancelTempSpeedOutcome(
  String username,
  Map<String, dynamic> data,
) {
  final who = ltrIsolate(username);
  final ts = data['temporary_speed'];
  if (ts is Map && ts['reverted'] == false) {
    return SessionActionOutcome(
      message: 'لا توجد سرعة مؤقتة فعّالة لـ $who.',
    );
  }
  if (ts is Map && ts['reverted'] == true) {
    return SessionActionOutcome(
      message: 'تم إلغاء السرعة المؤقتة لـ $who وإرجاعه لسرعته العادية فورًا.',
    );
  }
  return SessionActionOutcome(
    message: 'تم طلب إلغاء السرعة المؤقتة لـ $who.',
  );
}

/// The message after «تغيير الوقت» — the web card checker's set_time flash
/// (routes/cards.py): an exhausting subtraction is a WARNING (the card is
/// now finished and its session cut); otherwise the new remaining time and
/// whether the router got the update live (`adjustment.coa`).
SessionActionOutcome cardTimeOutcome(
  String username,
  CardTimeDraft draft,
  Map<String, dynamic> data,
) {
  final who = ltrIsolate(username);
  final head = draft.subtract
      ? 'تم خصم ${draft.label} من $who'
      : 'تمت إضافة ${draft.label} إلى $who';
  final adj = data['adjustment'];
  if (adj is! Map) return SessionActionOutcome(message: '$head.');
  if (adj['exhausted'] == true) {
    return SessionActionOutcome(
      warning: true,
      message: '$head — استُنفد وقت البطاقة كلّه فصارت منتهية وقُطعت '
          'جلستها إن كانت متصلة.',
    );
  }
  final rem = int.tryParse('${adj['remaining_seconds'] ?? ''}');
  var tail = '';
  if (rem != null && rem > 0) {
    final h = rem ~/ 3600;
    final m = (rem % 3600) ~/ 60;
    tail = ' المتبقي الآن: $h ساعة و $m دقيقة.';
  }
  final coa = adj['coa'];
  var coaNote = '';
  var warning = false;
  if (coa is Map) {
    final code = '${coa['code'] ?? ''}'.trim();
    if (coa['ok'] == true) {
      coaNote = ' — وصل التحديث للراوتر.';
    } else if (code == 'no_active_session') {
      coaNote = ' — لا جلسة نشطة الآن، سيُطبَّق في الجلسة التالية.';
    } else {
      warning = true;
      coaNote = ' — لم يصل التحديث الفوري للراوتر (${coaFailureReason(code)}).';
    }
  }
  return SessionActionOutcome(
    warning: warning,
    message: '$head.$tail$coaNote',
  );
}

/// The message after «سرعة مؤقتة», the same cases as the web flash
/// (sessions.py): the server saved the window, and `temporary_speed.coa`
/// says whether the ROUTER applied it. A failed CoA is a WARNING that says
/// so clearly (f06 L5); no live session is an «info» (applied on the next
/// login). An older server without `coa` keeps the neutral line.
SessionActionOutcome tempSpeedOutcome(
  String username,
  Map<String, dynamic> data,
) {
  final ts = data['temporary_speed'];
  final coa = ts is Map ? ts['coa'] : null;
  final who = ltrIsolate(username);
  if (coa is! Map) {
    return SessionActionOutcome(
      message: 'تم طلب تطبيق السرعة المؤقتة على $who.',
    );
  }
  final rate = ts is Map && '${ts['rate'] ?? ''}'.trim().isNotEmpty
      ? ' (${ltrIsolate('${ts['rate']}'.trim())})'
      : '';
  final endsRaw = ts is Map ? ts['ends_at'] : null;
  final ends = endsRaw == null ? '' : formatServerTimestamp('$endsRaw');
  final until = ends.isEmpty || ends == '—' ? '' : ' حتى ${ltrIsolate(ends)}';
  final reauth = ts is Map && '${ts['mode'] ?? ''}' == 'disconnect_reauth';
  final code = '${coa['code'] ?? ''}'.trim();
  if (coa['ok'] == true) {
    return SessionActionOutcome(
      message: reauth
          ? 'طُبِّقت السرعة المؤقتة$rate على $who بالفصل وإعادة الاتصال — '
              'سيعود بالسرعة الجديدة خلال ثوانٍ$until.'
          : 'تم تطبيق السرعة المؤقتة$rate على $who مباشرةً — بدون فصل '
              'المستخدم$until.',
    );
  }
  if (code == 'no_active_session') {
    return SessionActionOutcome(
      message: 'حُفظت السرعة المؤقتة$rate لـ $who — لا جلسة نشطة الآن؛ '
          'ستُطبَّق تلقائيًا فور إعادة اتصاله.',
    );
  }
  if (code == 'empty_rate') {
    return const SessionActionOutcome(
      warning: true,
      message: 'لم تُحدَّد سرعة صالحة للإرسال.',
    );
  }
  final reason = coaFailureReason(code);
  return SessionActionOutcome(
    warning: true,
    message: reauth
        ? 'حُفظت السرعة المؤقتة$rate لـ $who، لكن تعذّر الفصل ($reason) — '
            'تحقّق من اتصال الراوتر.'
        : 'حُفظت السرعة المؤقتة$rate لـ $who$until، لكن الراوتر لم يؤكّد '
            'تطبيقها ($reason). لم يُفصل المستخدم؛ إن لم تتغيّر سرعته افصل '
            'الجلسة ليعيد الاتصال بالسرعة الجديدة (وتحقّق من CoA: المنفذ 3799 '
            'وكلمة السرّ).',
  );
}

/// The three counters of «المتصلون».
class OnlineSummaryCounts {
  const OnlineSummaryCounts({
    required this.allLabel,
    required this.all,
    required this.subscribers,
    required this.cards,
  });
  final String allLabel;
  final int all;
  final int subscribers;
  final int cards;
}

/// «كل المتصلين» is the whole network, whatever tab or search is on: under
/// a filter the tiles use [overall] (an unfiltered count); while it is not
/// known the first tile says «المعروض» instead of claiming «كل المتصلين».
OnlineSummaryCounts onlineSummaryCounts({
  required OnlineSessionsQuery filtered,
  required List<OnlineSession> items,
  int? total,
  Map<String, int>? typeCounts,
  OnlineTotals? overall,
}) {
  final isFiltered = filtered != const OnlineSessionsQuery();
  if (isFiltered && overall != null) {
    return OnlineSummaryCounts(
      allLabel: 'كل المتصلين',
      all: overall.total,
      subscribers: overall.subscribers,
      cards: overall.cards,
    );
  }
  final subscribers = typeCounts?['subscriber'] ??
      items.where((item) => item.isSubscriber).length;
  final cards =
      typeCounts?['card'] ?? items.where((item) => item.isCard).length;
  return OnlineSummaryCounts(
    allLabel: isFiltered ? 'المعروض' : 'كل المتصلين',
    all: total ?? items.length,
    subscribers: subscribers,
    cards: cards,
  );
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.counts, this.temporarySpeed});

  final OnlineSummaryCounts counts;
  final int? temporarySpeed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Four tiles: 2×2 on a phone, one row of 4 on a wide screen — never
        // a lonely tile with empty space beside it (owner 2026-10-01).
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        // Content-sized tiles: a fixed aspect ratio clipped the value by
        // 33–51 px at 360×640.
        return AutoHeightGrid(
          columns: columns,
          spacing: AppTokens.s8,
          children: [
            _SummaryTile(
              icon: Icons.wifi_tethering,
              label: counts.allLabel,
              value: '${counts.all}',
            ),
            _SummaryTile(
              icon: Icons.person_outline,
              label: 'مشتركون',
              value: '${counts.subscribers}',
            ),
            _SummaryTile(
              icon: Icons.credit_card,
              label: 'كروت',
              value: '${counts.cards}',
            ),
            _SummaryTile(
              icon: Icons.speed,
              label: 'سرعة مؤقتة',
              value: temporarySpeed == null ? '—' : '$temporarySpeed',
            ),
          ],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTokens.brandSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTokens.brand, size: 20),
            ),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTokens.sidebarBg,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.formatBytes,
    required this.formatDuration,
    required this.onMore,
    this.onDisconnect,
    this.onLockMac,
    this.onTemporarySpeed,
    this.onCancelTemporarySpeed,
    this.onChangeTime,
  });

  final OnlineSession session;
  final String Function(int) formatBytes;
  final String Function(int) formatDuration;
  final VoidCallback onMore;
  final VoidCallback? onDisconnect;
  final VoidCallback? onLockMac;
  final VoidCallback? onTemporarySpeed;

  /// Subscribers' second-row action.
  final VoidCallback? onCancelTemporarySpeed;

  /// Cards' second-row action («تغيير الوقت»).
  final VoidCallback? onChangeTime;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final state = _stateLabel(session);
    // A card whose time the server sent: «مُستخدَم / متبقّي» take the third
    // row; router + start time move to «المزيد».
    final cardTime = session.isCard && session.cardTimeKnown;
    final row1 = <ActionItem>[
      if (onDisconnect != null)
        ActionItem(
          icon: Icons.power_settings_new,
          label: 'طرد',
          tone: PillTone.red,
          onPressed: onDisconnect,
        ),
      if (onLockMac != null)
        ActionItem(
          icon: Icons.phonelink_lock_outlined,
          label: 'تثبيت MAC',
          onPressed: onLockMac,
        ),
      ActionItem(
        icon: Icons.more_horiz,
        label: 'المزيد',
        onPressed: onMore,
      ),
    ];
    final row2 = <ActionItem>[
      if (onTemporarySpeed != null)
        ActionItem(
          icon: Icons.speed_outlined,
          label: 'سرعة مؤقتة',
          onPressed: onTemporarySpeed,
        ),
      if (session.isSubscriber && onCancelTemporarySpeed != null)
        ActionItem(
          icon: Icons.restore_outlined,
          label: 'إلغاء السرعة',
          onPressed: onCancelTemporarySpeed,
        ),
      if (session.isCard && onChangeTime != null)
        ActionItem(
          icon: Icons.more_time_outlined,
          label: 'تغيير الوقت',
          onPressed: onChangeTime,
        ),
    ];
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    session.isCard ? AppTokens.brandSoft : AppTokens.successBg,
                child: Icon(
                  session.isCard ? Icons.credit_card : Icons.person_outline,
                  color: session.isCard ? AppTokens.brand : AppTokens.green,
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      // «كرت · هوت سبوت (حزمة علاء)» — owner 2026-10-05.
                      [
                            session.isCard ? 'كرت' : 'مشترك',
                            if (accessTypeLabel(session.accessType).isNotEmpty)
                              accessTypeLabel(session.accessType),
                          ].join(' · ') +
                          (session.isCard && session.cardBatchName.isNotEmpty
                              ? ' (${session.cardBatchName})'
                              : ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTokens.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              // Owner 2026-10-04: we are already in «المتصلون», so the
              // «متصل» pill said nothing — show the speed the session runs
              // at now (raised → highlighted, temporary → live countdown).
              if (session.speedKnown)
                SessionSpeedBadge(session: session)
              else
                StatusPill(text: state, tone: toneForStatus(state), dot: true),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          InfoGrid(
            items: [
              InfoItem(
                icon: Icons.timer_outlined,
                label: 'المدة',
                value: formatDuration(session.effectiveSessionTime()),
              ),
              // RFC 2866: input octets (bytesIn) = the user's UPLOAD,
              // output octets (bytesOut) = DOWNLOAD — as the web shows.
              InfoItem(
                icon: Icons.download,
                label: 'تنزيل',
                value: formatBytes(session.bytesOut),
              ),
              InfoItem(
                icon: Icons.upload,
                label: 'رفع',
                value: formatBytes(session.bytesIn),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          InfoGrid(
            columns: 2,
            items: [
              if (session.framedIpAddress.isNotEmpty)
                InfoItem(
                  icon: Icons.dns,
                  label: 'IP',
                  value: ltrIsolate(session.framedIpAddress),
                ),
              if (session.callingStationId.isNotEmpty)
                InfoItem(
                  icon: Icons.devices,
                  label: 'MAC',
                  value: ltrIsolate(session.callingStationId),
                ),
              if (!cardTime && session.nasIpAddress.isNotEmpty)
                InfoItem(
                  icon: Icons.router,
                  label: 'الراوتر',
                  value: ltrIsolate(session.nasIpAddress),
                ),
              if (!cardTime && session.startedAt != null)
                InfoItem(
                  icon: Icons.play_circle_outline,
                  label: 'بدأت',
                  value: df.format(session.startedAt!.toLocal()),
                ),
            ],
          ),
          if (cardTime) ...[
            const SizedBox(height: AppTokens.s8),
            InfoGrid(
              key: const ValueKey('card-time-row'),
              columns: 2,
              items: [
                InfoItem(
                  icon: Icons.hourglass_bottom,
                  label: 'مُستخدَم',
                  value: cardTimeLabel(session.cardUsedSeconds ?? 0),
                  background: AppTokens.dangerBg,
                  foreground: AppTokens.dangerFg,
                ),
                InfoItem(
                  icon: Icons.hourglass_top,
                  label: 'متبقّي',
                  value: session.cardRemainingSeconds == null
                      ? 'غير محدود'
                      : cardTimeLabel(session.cardRemainingSeconds!),
                  background: AppTokens.successBg,
                  foreground: AppTokens.successFg,
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTokens.s12),
          // Two fixed rows, the same shape for a card and a subscriber; a
          // button the admin may not use is left out and the rest of its
          // row share the width evenly.
          ActionBar(items: row1),
          if (row2.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            ActionBar(items: row2),
          ],
        ],
      ),
    );
  }
}

/// «هوت سبوت» / «برود باند» for a session's `access_type` ('' = unknown).
String accessTypeLabel(String accessType) => switch (accessType) {
      'hotspot' => 'هوت سبوت',
      'broadband' => 'برود باند',
      'both' => 'هوت سبوت + برود باند',
      _ => '',
    };

/// A card's used / remaining time in the duration box's format («2 س 10 د»);
/// nothing left is «0 د», never «غير معروف».
String cardTimeLabel(int seconds) =>
    seconds <= 0 ? '0 د' : compactSessionDuration(seconds);

/// The rows of «المزيد ⋯».
enum SessionMoreAction {
  lockIp(Icons.pin_outlined, 'تثبيت IP'),
  subscriberProfile(Icons.account_circle_outlined, 'ملف المشترك'),
  cancelSpeed(Icons.restore_outlined, 'إلغاء السرعة'),
  cardChecker(Icons.manage_search_outlined, 'فحص الكرت'),
  resetCardUsage(Icons.restart_alt, 'تصفير الاستخدام'),
  disableSubscriber(Icons.pause_circle_outline, 'تعطيل', danger: true),
  disableCard(Icons.pause_circle_outline, 'تعطيل', danger: true),
  deleteCard(Icons.delete_forever_outlined, 'حذف نهائي', danger: true);

  const SessionMoreAction(this.icon, this.label, {this.danger = false});
  final IconData icon;
  final String label;
  final bool danger;
}

/// What «المزيد» may offer this admin.
class SessionMorePermissions {
  const SessionMorePermissions({
    required this.acts,
    this.subscriberStatus = false,
    this.cardCheck = false,
    this.cardOps = false,
    this.cardDelete = false,
  });

  factory SessionMorePermissions.of(AppPermissions p) {
    // Single-card operations = cards.verify (the web checker); a permanent
    // delete is owner / co-owner / super-user only on the server.
    final cardOps = p.can('cards.verify');
    return SessionMorePermissions(
      acts: SessionActionPermissions(p),
      subscriberStatus: p.canAction('subscriber.status'),
      cardCheck: p.canAny(const ['cards.view', 'cards.verify']),
      cardOps: cardOps,
      cardDelete: cardOps && (p.isOwnerLike || p.isSuperAdmin),
    );
  }

  final SessionActionPermissions acts;
  final bool subscriberStatus;
  final bool cardCheck;
  final bool cardOps;
  final bool cardDelete;
}

/// «المزيد» rows for [session]: a subscriber gets IP lock, profile and
/// disable; a card gets cancel-speed, the checker, disable and delete (IP
/// lock is subscriber-only on the server).
List<SessionMoreAction> sessionMoreActions(
  OnlineSession session,
  SessionMorePermissions perms,
) {
  final hasCard = session.cardId != null;
  if (session.isCard) {
    return [
      if (perms.acts.tempSpeed) SessionMoreAction.cancelSpeed,
      if (perms.cardCheck) SessionMoreAction.cardChecker,
      if (hasCard && perms.cardOps) SessionMoreAction.resetCardUsage,
      if (hasCard && perms.cardOps) SessionMoreAction.disableCard,
      if (hasCard && perms.cardDelete) SessionMoreAction.deleteCard,
    ];
  }
  return [
    if (perms.acts.lockIp) SessionMoreAction.lockIp,
    SessionMoreAction.subscriberProfile,
    if (perms.subscriberStatus) SessionMoreAction.disableSubscriber,
  ];
}

/// «تغيير الوقت» of a card: add or subtract [amount] [unit].
class CardTimeDraft {
  const CardTimeDraft({
    required this.amount,
    required this.unit,
    required this.subtract,
  });

  final int amount;

  /// `minutes` | `hours` | `days` (the adjust-time API units).
  final String unit;
  final bool subtract;

  String get label => '$amount ${switch (unit) {
        'days' => 'يوم',
        'hours' => 'ساعة',
        _ => 'دقيقة',
      }}';
}

/// Card time dialog guard: a whole positive amount, at most a year per
/// operation (the owner's cap; the server checks it too).
String? validateCardTimeInput(String amountText, String unit) {
  final err = validateNumberInput(amountText, decimal: false, min: 1);
  if (err != null) return 'المدة: $err';
  final v = parseIntInput(amountText) ?? 0;
  final minutes = switch (unit) {
    'days' => v * 1440,
    'hours' => v * 60,
    _ => v,
  };
  if (minutes > 365 * 1440) return 'المدة: الحدّ الأعلى سنة في المرّة.';
  return null;
}

Future<CardTimeDraft?> showCardTimeDialog(
  BuildContext context, {
  required String username,
}) {
  final amount = TextEditingController(text: '30');
  var unit = 'minutes';
  var subtract = false;
  return showDialog<CardTimeDraft>(
    context: context,
    builder: (ctx) {
      String? error;
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('تغيير وقت الكرت'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ltrIsolate(username),
                style: const TextStyle(
                  color: AppTokens.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              SegmentedButton<bool>(
                key: const ValueKey('card-time-op'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.add),
                    label: Text('إضافة'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.remove),
                    label: Text('خصم'),
                  ),
                ],
                selected: {subtract},
                onSelectionChanged: (s) => setState(() => subtract = s.first),
              ),
              const SizedBox(height: AppTokens.s12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('card-time-amount'),
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المدة',
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: unit,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'الوحدة'),
                      items: const [
                        DropdownMenuItem(
                          value: 'minutes',
                          child: Text('دقائق'),
                        ),
                        DropdownMenuItem(value: 'hours', child: Text('ساعات')),
                        DropdownMenuItem(value: 'days', child: Text('أيام')),
                      ],
                      onChanged: (v) => setState(() => unit = v ?? 'minutes'),
                    ),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: AppTokens.s8),
                Text(error!, style: const TextStyle(color: AppTokens.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final problem = validateCardTimeInput(amount.text, unit);
                if (problem != null) {
                  setState(() => error = problem);
                  return;
                }
                Navigator.pop(
                  ctx,
                  CardTimeDraft(
                    amount: parseIntInput(amount.text) ?? 0,
                    unit: unit,
                    subtract: subtract,
                  ),
                );
              },
              child: Text(subtract ? 'خصم' : 'إضافة'),
            ),
          ],
        ),
      );
    },
  ).whenComplete(amount.dispose);
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.async,
    required this.formatBytes,
    required this.formatDuration,
  });

  final AsyncValue<List<AccountingSessionHistory>> async;
  final String Function(int) formatBytes;
  final String Function(int) formatDuration;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.s12),
            child: Row(
              children: [
                const Icon(Icons.history_outlined, color: AppTokens.brand),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: Text(
                    'آخر جلسات المحاسبة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppTokens.s20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(AppTokens.s20),
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'تعذر جلب تاريخ الجلسات',
                subtitle: visibleErrorMessage(error),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(AppTokens.s20),
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'لا توجد جلسات محاسبة محفوظة بعد',
                  ),
                );
              }
              return Column(
                children: [
                  for (final item in items.take(12))
                    _HistoryRow(
                      item: item,
                      formatBytes: formatBytes,
                      formatDuration: formatDuration,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.item,
    required this.formatBytes,
    required this.formatDuration,
  });

  final AccountingSessionHistory item;
  final String Function(int) formatBytes;
  final String Function(int) formatDuration;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final state = item.isOnline ? 'متصلة' : 'منتهية';
    final where = [
      if (item.nasIpAddress.isNotEmpty) ltrIsolate(item.nasIpAddress),
      if (item.framedIpAddress.isNotEmpty) ltrIsolate(item.framedIpAddress),
    ].join(' · ');
    final when = [
      if (item.startedAt != null) 'من ${df.format(item.startedAt!.toLocal())}',
      if (item.stoppedAt != null) 'إلى ${df.format(item.stoppedAt!.toLocal())}',
    ].join('  ');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.username.isEmpty ? 'مستخدم غير محدد' : item.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTokens.sidebarBg,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  StatusPill(
                    text: state,
                    tone: toneForStatus(state),
                    dot: item.isOnline,
                  ),
                ],
              ),
              if (where.isNotEmpty || when.isNotEmpty) ...[
                const SizedBox(height: AppTokens.s4),
                if (where.isNotEmpty)
                  Text(
                    where,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
                if (when.isNotEmpty)
                  Text(
                    when,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
              const SizedBox(height: AppTokens.s8),
              InfoGrid(
                items: [
                  InfoItem(
                    icon: Icons.timer_outlined,
                    label: 'المدة',
                    value: formatDuration(item.sessionTime),
                  ),
                  InfoItem(
                    icon: Icons.download,
                    label: 'تنزيل',
                    value: formatBytes(item.bytesOut),
                  ),
                  InfoItem(
                    icon: Icons.upload,
                    label: 'رفع',
                    value: formatBytes(item.bytesIn),
                  ),
                ],
              ),
              if (item.terminateCause.isNotEmpty) ...[
                const SizedBox(height: AppTokens.s4),
                Text(
                  'سبب الانتهاء: ${_terminateCauseLabel(item.terminateCause)}',
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _TemporarySpeedDraft {
  const _TemporarySpeedDraft({
    required this.downloadKbps,
    required this.uploadKbps,
    required this.duration,
    required this.durationUnit,
  });

  final int downloadKbps;
  final int uploadKbps;
  final int duration;

  /// `minutes` | `hours` | `days` — the web temp-speed form's units.
  final String durationUnit;
}

Future<_TemporarySpeedDraft?> _showTemporarySpeedDialog(BuildContext context) {
  // الافتراضيّ مطابق لنموذج الويب (sessions_list.html: 2500/2500 Kbit/s).
  final download = TextEditingController(text: '2500');
  final upload = TextEditingController(text: '2500');
  final duration = TextEditingController(text: '30');
  var unit = 'minutes';

  return showDialog<_TemporarySpeedDraft>(
    context: context,
    builder: (ctx) {
      String? error;
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('سرعة مؤقتة للجلسة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'أدخل السرعة بالكيلوبت/ثانية (0 = غير محدود في ذلك الاتجاه، وإلّا 64 فأكثر) والمدة ووحدتها — حتى يوم واحد. سيتم إرسال الطلب إلى الريدياس لتطبيق CoA إن كان متاحًا.',
              ),
              const SizedBox(height: AppTokens.s12),
              TextField(
                controller: download,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سرعة التحميل Kbps',
                  prefixIcon: Icon(Icons.download),
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              TextField(
                controller: upload,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سرعة الرفع Kbps',
                  prefixIcon: Icon(Icons.upload),
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    // 1:1 (was 2:1) — at 390 px the unit read «دقا…».
                    child: TextField(
                      controller: duration,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المدة',
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: unit,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'الوحدة'),
                      items: const [
                        DropdownMenuItem(
                          value: 'minutes',
                          child: Text('دقائق'),
                        ),
                        DropdownMenuItem(
                          value: 'hours',
                          child: Text('ساعات'),
                        ),
                        DropdownMenuItem(
                          value: 'days',
                          child: Text('أيام'),
                        ),
                      ],
                      onChanged: (v) => setState(() => unit = v ?? 'minutes'),
                    ),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: AppTokens.s8),
                Text(
                  error!,
                  style: const TextStyle(color: AppTokens.red),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.speed_outlined),
              label: const Text('تطبيق'),
              onPressed: () {
                final problem = validateTemporarySpeedInput(
                  downloadText: download.text,
                  uploadText: upload.text,
                  durationText: duration.text,
                  unit: unit,
                );
                if (problem != null) {
                  setState(() => error = problem);
                  return;
                }
                final down = parseIntInput(download.text) ?? 0;
                final up = parseIntInput(upload.text) ?? 0;
                final value = parseIntInput(duration.text) ?? 0;
                Navigator.pop(
                  ctx,
                  _TemporarySpeedDraft(
                    downloadKbps: down,
                    uploadKbps: up,
                    duration: value,
                    durationUnit: unit,
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  ).whenComplete(() {
    download.dispose();
    upload.dispose();
    duration.dispose();
  });
}

/// Temp-speed dialog guard (Arabic) — the server's own rules
/// (`services/temp_speed.py` apply_temp_speed): each speed is 0 (= unlimited
/// in that direction) or 64…1,000,000 Kbps, not both 0; the window is
/// 1…1440 minutes (a day at most) whatever the unit.
String? validateTemporarySpeedInput({
  required String downloadText,
  required String uploadText,
  required String durationText,
  required String unit,
}) {
  for (final (label, text) in [
    ('سرعة التنزيل', downloadText),
    ('سرعة الرفع', uploadText),
  ]) {
    final err = validateNumberInput(text, decimal: false, min: 0);
    if (err != null) return '$label: $err';
    final v = parseIntInput(text) ?? 0;
    if (v > 0 && v < 64) {
      return '$label: 0 (غير محدود) أو 64 كيلوبت فأكثر.';
    }
    if (v > 1000000) return '$label: السرعة المدخلة كبيرة جدًا.';
  }
  if ((parseIntInput(downloadText) ?? 0) == 0 &&
      (parseIntInput(uploadText) ?? 0) == 0) {
    return 'السرعة المؤقتة تحتاج سرعة تنزيل أو رفع — 0/0 تعني «بلا تقييد».';
  }
  final err = validateNumberInput(durationText, decimal: false, min: 1);
  if (err != null) return 'المدة: $err';
  final v = parseIntInput(durationText) ?? 0;
  final minutes = switch (unit) {
    'days' => v * 1440,
    'hours' => v * 60,
    _ => v,
  };
  if (minutes > 1440) {
    return 'المدة: الحدّ الأعلى يوم واحد (1440 دقيقة).';
  }
  return null;
}

String _terminateCauseLabel(String value) {
  return switch (value) {
    'User-Request' => 'طلب المستخدم',
    'Stale-Session-Timeout' => 'انتهت بسبب انقطاع التحديث',
    'Lost-Carrier' => 'انقطاع الاتصال',
    'Session-Timeout' => 'انتهاء مدة الجلسة',
    _ => value,
  };
}

String _stateLabel(OnlineSession session) {
  final raw =
      session.stateLabel.isNotEmpty ? session.stateLabel : session.state;
  return switch (raw) {
    'online' => 'متصل',
    'active' => 'نشط',
    'expired' => 'منتهي',
    'frozen' => 'مجمّد',
    'disconnected' => 'مفصول',
    _ => raw.trim().isEmpty ? 'غير محدد' : raw,
  };
}

/// «1.6M» / «512K» — compact for the speed badge.
String compactKbps(int kbps) {
  if (kbps <= 0) return '—';
  if (kbps >= 1000) {
    // 2048k reads «2M», 1536k «1.5M» — never a trailing «.0».
    var t = (kbps / 1000).toStringAsFixed(1);
    if (t.endsWith('.0')) t = t.substring(0, t.length - 2);
    return '${t}M';
  }
  return '${kbps}K';
}

/// The live speed of a session beside its name: «↓1.6M ↑1.6M». A raised
/// speed (temporary / custom / not the plan's) is highlighted; a temporary
/// one counts down to its end every second.
class SessionSpeedBadge extends StatefulWidget {
  const SessionSpeedBadge({super.key, required this.session});
  final OnlineSession session;

  @override
  State<SessionSpeedBadge> createState() => _SessionSpeedBadgeState();
}

class _SessionSpeedBadgeState extends State<SessionSpeedBadge> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(covariant SessionSpeedBadge old) {
    super.didUpdateWidget(old);
    _arm();
  }

  void _arm() {
    _tick?.cancel();
    _tick = null;
    if (widget.session.tempEndsAt != null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  static String _clock(int s) {
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final raised = s.isRaisedSpeed;
    final fg = raised ? AppTokens.brand : AppTokens.green;
    final bg = raised ? AppTokens.brandSoft : AppTokens.successBg;
    final ends = s.tempEndsAt;
    final left =
        ends?.difference(DateTime.now().toUtc()).inSeconds.clamp(0, 1 << 31);
    return Container(
      key: const ValueKey('session-speed-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ltrIsolate(
              '↓${compactKbps(s.rateDownKbps)} ↑${compactKbps(s.rateUpKbps)}',
            ),
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          if (left != null)
            Text(
              'مؤقتة · ${_clock(left)}',
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (raised)
            Text(
              s.isTemporarySpeed ? 'مؤقتة' : 'سرعة خاصة',
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

/// A session length short enough for a third of a 360 px row: «12 د 28 ث»,
/// «1 س 22 د», «3 ي 4 س». The long form («12 دقيقة 28 ثانية») was cut to
/// «12 دقيقة 28 ثا…» at 360 and 390 (R07 N15).
String compactSessionDuration(int seconds) {
  if (seconds <= 0) return 'غير معروف';
  final d = Duration(seconds: seconds);
  if (d.inDays > 0) return '${d.inDays} ي ${d.inHours.remainder(24)} س';
  if (d.inHours > 0) return '${d.inHours} س ${d.inMinutes.remainder(60)} د';
  if (d.inMinutes > 0) {
    return '${d.inMinutes} د ${d.inSeconds.remainder(60)} ث';
  }
  return '${d.inSeconds} ث';
}

/// Live-session actions the admin may run (server ACTION_REGISTRY
/// `session.*`, derived from the online.* / users.temp_speed keys).
class SessionActionPermissions {
  const SessionActionPermissions(this.p);
  final AppPermissions p;

  bool get disconnect => p.canAction('session.disconnect');
  bool get lockMac => p.canAction('session.lock_mac');
  bool get lockIp => p.canAction('session.lock_ip');
  bool get tempSpeed => p.canAction('session.temp_speed');
}
