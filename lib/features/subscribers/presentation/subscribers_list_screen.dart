import 'package:hoberadius_app/core/format/panel_time.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/api/paging.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/format/bidi.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/even_choice_bar.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/load_more_footer.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../provider_grants/application/provider_grants_provider.dart';
import '../../provider_grants/presentation/limit_usage_banner.dart';
import '../../sessions/presentation/sessions_list_screen.dart'
    show compactSessionDuration;
import '../data/subscribers_repository.dart';
import '../domain/subscriber_model.dart';
import 'widgets/subscriber_actions_sheet.dart';

/// Pseudo-status for «ينتهي خلال ٣ أيام» (active subscribers whose expiry
/// falls in the next 3 days) — matches the web's `attention=expiring_3d` and
/// the dashboard «expiring_soon» counter.
const kExpiringSoonFilter = 'expiring_3d';

/// What the list asks the server for: a status chip, the access chip
/// (hotspot / broadband) and the search box.
class SubscribersQuery {
  const SubscribersQuery({
    this.status,
    this.search = '',
    this.access = AccessKind.all,
  });

  final String? status;
  final String search;
  final AccessKind access;

  @override
  bool operator ==(Object other) =>
      other is SubscribersQuery &&
      other.status == status &&
      other.search == search &&
      other.access == access;

  @override
  int get hashCode => Object.hash(status, search, access);
}

/// Server-side search + paging (infinite scroll). The list used to fetch the
/// newest 100 rows once and search/filter them on the phone, so older
/// subscribers were unreachable and the «منتهي»/«ينتهي خلال ٣ أيام» chips
/// were capped at 100.
class SubscribersListController extends AutoDisposeFamilyAsyncNotifier<
    PagedList<Subscriber>, SubscribersQuery> {
  static const pageSize = 50;

  @override
  Future<PagedList<Subscriber>> build(SubscribersQuery arg) async {
    ref.watch(subscribersRepositoryProvider);
    final (items, page) = await _fetch(0);
    return PagedList<Subscriber>(
      items: items,
      hasMore: page.hasMore && page.rawCount > 0,
      total: page.total,
      nextOffset: page.rawCount,
    );
  }

  bool get _expiring => arg.status == kExpiringSoonFilter;

  Future<(List<Subscriber>, SubscribersPage)> _fetch(int offset) async {
    final repo = ref.read(subscribersRepositoryProvider);
    final page = await repo.listPage(
      status: _expiring ? 'enabled' : arg.status,
      // Newer backends filter the window themselves; the client-side guard
      // below keeps older servers (param ignored) showing only the right rows.
      expiringWithinDays: _expiring ? 3 : null,
      search: arg.search,
      access: arg.access.apiValue,
      limit: pageSize,
      offset: offset,
    );
    final items =
        _expiring ? filterExpiringSoon(page.items, panelNow()) : page.items;
    return (items, page);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true, loadMoreError: null));
    try {
      final (items, page) = await _fetch(current.nextOffset);
      final (merged, added) =
          mergeUniqueBy(current.items, items, (s) => s.username);
      // A page that brings nothing new (older server ignoring offset) ends
      // the paging instead of looping forever.
      final progressed = page.rawCount > 0 && (added > 0 || _expiring);
      state = AsyncData(
        current.copyWith(
          items: merged,
          hasMore: page.hasMore && progressed,
          total: page.total ?? current.total,
          nextOffset: current.nextOffset + page.rawCount,
          loadingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncData(
        current.copyWith(loadingMore: false, loadMoreError: e),
      );
    }
  }
}

final subscribersListProvider = AsyncNotifierProvider.autoDispose
    .family<SubscribersListController, PagedList<Subscriber>, SubscribersQuery>(
  SubscribersListController.new,
);

/// Subscribers whose expiry is after [now] and within the next 3 days — the
/// same window as the dashboard «ينتهي خلال ٣ أيام» counter.
List<Subscriber> filterExpiringSoon(List<Subscriber> items, DateTime now) {
  final until = now.add(const Duration(days: 3));
  return items.where((s) {
    final exp = s.expireAt;
    return exp != null && exp.isAfter(now) && !exp.isAfter(until);
  }).toList();
}

/// Maps a `/subscribers?status=…` or the web-style `?attention=…` deep link
/// (dashboard tiles, alerts) to the list's filter value.
String? subscribersFilterFromQuery(Map<String, String> q) {
  final status = q['status'];
  if (status != null && status.isNotEmpty) return status;
  return switch (q['attention']) {
    'expiring_3d' || 'expiring' => kExpiringSoonFilter,
    'expired' => 'expired',
    _ => null,
  };
}

enum _Density { comfortable, compact }

class SubscribersListScreen extends ConsumerStatefulWidget {
  const SubscribersListScreen({super.key, this.initialStatus});

  /// Filter to open with (from a deep link such as a dashboard tile).
  final String? initialStatus;

  @override
  ConsumerState<SubscribersListScreen> createState() =>
      _SubscribersListScreenState();
}

class _SubscribersListScreenState extends ConsumerState<SubscribersListScreen> {
  late String? _status = widget.initialStatus;
  AccessKind _access = AccessKind.all;
  String _query = '';
  Timer? _debounce;
  _Density _density = _Density.comfortable;

  SubscribersQuery get _listQuery =>
      SubscribersQuery(status: _status, search: _query, access: _access);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final next = value.trim();
      if (next != _query) setState(() => _query = next);
    });
  }

  @override
  void didUpdateWidget(covariant SubscribersListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-navigating to /subscribers with a different filter reuses this
    // State; follow the new link instead of keeping the old chip.
    if (widget.initialStatus != oldWidget.initialStatus) {
      _status = widget.initialStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(subscribersListProvider(_listQuery));
    final perms = ref.watch(permissionsProvider);
    // «مشترك جديد» only when the server would SAVE it (users.create + the
    // action grant + an open section) — never a form refused after filling.
    final createDenied = subscriberCreateDenial(perms);
    final atCap = ref.watch(grantLimitProvider('subscribers'))?.atCap ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'المشتركون',
          inlineActions: true,
          actions: [
            // No `tooltip:` on the segments: a Tooltip INSIDE the segmented
            // button's render object is laid out by the shell navigator's
            // Overlay during the page transition and read its size mid-
            // layout — the first error of the debug assertion cascade after
            // «حفظ» → list (r10 N8 / f07 N-B7). The names stay for screen
            // readers.
            SegmentedButton<_Density>(
              key: const ValueKey('subscribers-density'),
              segments: const [
                ButtonSegment(
                  value: _Density.comfortable,
                  icon: Icon(
                    Icons.view_agenda_outlined,
                    semanticLabel: 'عرض مريح',
                  ),
                ),
                ButtonSegment(
                  value: _Density.compact,
                  icon: Icon(
                    Icons.density_small_outlined,
                    semanticLabel: 'عرض مكثّف',
                  ),
                ),
              ],
              selected: {_density},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _density = s.first),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        ActionBar(
          items: [
            ActionItem(
              icon: Icons.person_add_alt_1_outlined,
              label: 'مشترك جديد',
              primary: true,
              // blocked at the provider's subscriber cap (was the guarded
              // create button; the limit banner below explains it)
              onPressed: (atCap || createDenied != null)
                  ? null
                  : () => context.goNamed('subscriber-new'),
              tooltip: createDenied,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        const LimitUsageBanner(serviceKey: 'subscribers'),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'بحث',
                  hintText: 'بحث بالاسم أو اسم المستخدم أو الجوال…',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: (v) {
                  _debounce?.cancel();
                  setState(() => _query = v.trim());
                },
              ),
              const SizedBox(height: AppTokens.s12),
              _StatusChips(
                value: _status,
                onChanged: (next) => setState(() => _status = next),
              ),
              const SizedBox(height: AppTokens.s8),
              AccessFilterBar(
                value: _access,
                onChanged: (next) => setState(() => _access = next),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s16),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب القائمة',
            subtitle: visibleErrorMessage(e),
          ),
          data: (page) {
            if (page.items.isEmpty && !page.hasMore) {
              return const EmptyState(
                icon: Icons.person_off_outlined,
                title: 'لا توجد نتائج',
              );
            }
            final ctrl = ref.read(subscribersListProvider(_listQuery).notifier);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (page.total != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s8),
                    child: Text(
                      'النتائج: ${page.total}',
                      style: AppTypography.caption.copyWith(
                        color: AppTokens.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                _Table(items: page.items, density: _density),
                LoadMoreFooter(
                  hasMore: page.hasMore,
                  loading: page.loadingMore,
                  error: page.loadMoreError,
                  shown: page.items.length,
                  total: page.total,
                  onLoadMore: ctrl.loadMore,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = <(String?, String)>[
      (null, 'كل الحالات'),
      ('enabled', 'مفعّل'),
      (
        kExpiringSoonFilter,
        'قرب الانتهاء'
      ), // خلال 3 أيام — قصير كي لا يُصغَّر خطّه
      ('expired', 'منتهي'),
      ('disabled', 'معطّل'),
      ('suspended', 'موقوف'),
      ('banned', 'محظور'),
    ];
    // All seven stay visible in even, equal-width rows (4 + 3 on a phone):
    // the old Wrap left ragged rows and uneven gaps, the scrolling row hid
    // most chips. A dot in each status's own colour ties the filter to the
    // badges in the list.
    return EvenChoiceBar<String?>(
      key: const ValueKey('status-filter'),
      selected: value,
      onChanged: onChanged,
      options: [
        for (final (code, label) in options)
          EvenChoice<String?>(
            code,
            label,
            dot: code == null
                ? null
                : pillToneColors(
                    code == kExpiringSoonFilter
                        ? PillTone.amber
                        : toneForStatus(code),
                  ).$2,
          ),
      ],
    );
  }
}

/// Status as the operator sees it: an «enabled» account whose expiry already
/// passed is «منتهي» (expiry is derived from expire_at, not stored).
String effectiveSubscriberStatus(Subscriber s, DateTime now) {
  if (s.status == 'enabled' &&
      s.expireAt != null &&
      !s.expireAt!.isAfter(now)) {
    return 'expired';
  }
  return s.status;
}

class _Table extends ConsumerWidget {
  const _Table({required this.items, required this.density});
  final List<Subscriber> items;
  final _Density density;

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    Subscriber s,
  ) =>
      showSubscriberActionsSheet(
        context,
        ref,
        subscriber: s,
        onChanged: () => ref.invalidate(subscribersListProvider),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final df = DateFormat('yyyy-MM-dd');
    final p = AppPalette.of(context);
    final now = panelNow();
    final compact = density == _Density.compact;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      // Owner: separate subscribers clearly — each one its own card.
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final s = items[i];
        final status = effectiveSubscriberStatus(s, now);
        final label = _statusLabel(status);
        final exp = s.expireAt;
        final daysLeft = exp == null ? null : exp.difference(now).inHours / 24;
        final (_, expFg, _) = pillToneColors(
          daysLeft == null
              ? PillTone.neutral
              : daysLeft <= 0
                  ? PillTone.red
                  : daysLeft <= 3
                      ? PillTone.amber
                      : PillTone.neutral,
        );
        void open360() => ctx.goNamed(
              'subscriber-360',
              pathParameters: {'username': s.username},
            );
        void openFinance() => ctx.goNamed(
              'subscriber-finance',
              pathParameters: {'username': s.username},
            );
        return _RowCard(
          child: Dismissible(
            key: ValueKey('sub:${s.username}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              openFinance();
              return false;
            },
            background: Container(
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsetsDirectional.only(start: 24),
              color: p.brandSoft,
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: p.brandInk,
              ),
            ),
            child: InkWell(
              onTap: open360,
              onLongPress: () => _showActions(ctx, ref, s),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTokens.s12,
                  vertical: compact ? AppTokens.s8 : AppTokens.s12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: compact ? 16 : 20,
                          backgroundColor: p.brandSoft,
                          child: Icon(
                            Icons.person,
                            color: p.brand,
                            size: compact ? 18 : 22,
                          ),
                        ),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.fullName.isEmpty ? s.username : s.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelLarge.copyWith(
                                  color: p.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                [
                                  s.username,
                                  if (s.mobile.isNotEmpty) s.mobile,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption
                                    .copyWith(color: p.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (s.temporaryAccount) ...[
                          const SizedBox(width: AppTokens.s8),
                          const StatusPill(
                            text: 'مؤقت',
                            tone: PillTone.amber,
                          ),
                        ],
                        const SizedBox(width: AppTokens.s8),
                        StatusPill(
                          text: label,
                          tone: toneForStatus(status),
                          dot: true,
                        ),
                        if (compact)
                          IconButton(
                            tooltip: 'إجراءات',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showActions(ctx, ref, s),
                          ),
                      ],
                    ),
                    if (exp != null)
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: compact ? 44 : 52,
                          top: 2,
                        ),
                        child: Text(
                          '${daysLeft! <= 0 ? 'انتهى' : 'ينتهي'}: ${df.format(exp)}',
                          style: AppTypography.caption.copyWith(
                            color: expFg,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    SizedBox(height: compact ? 6 : AppTokens.s8),
                    SubscriberLiveStrip(subscriber: s, now: now),
                    if (!compact) ...[
                      const SizedBox(height: AppTokens.s12),
                      ActionBar(
                        items: [
                          ActionItem(
                            icon: Icons.dashboard_customize_outlined,
                            label: 'الملف',
                            primary: true,
                            onPressed: open360,
                          ),
                          ActionItem(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'المالية',
                            onPressed: openFinance,
                          ),
                          ActionItem(
                            icon: Icons.tune,
                            label: 'إجراءات',
                            onPressed: () => _showActions(ctx, ref, s),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(String s) => switch (s) {
        'enabled' => 'مفعّل',
        'disabled' => 'معطّل',
        'expired' => 'منتهي',
        'suspended' => 'موقوف',
        'banned' => 'محظور',
        _ => s,
      };
}

/// The same small strip on EVERY subscriber row (online or not): تحميل ·
/// رفع · IP · المدة of the open session, else of the last one; «—» when the
/// server sent none, so all rows keep one shape. 2×2 when the row is narrow.
class SubscriberLiveStrip extends StatelessWidget {
  const SubscriberLiveStrip({
    super.key,
    required this.subscriber,
    required this.now,
  });

  final Subscriber subscriber;
  final DateTime now;

  static const _dash = '—';

  static String bytesLabel(int bytes) {
    if (bytes <= 0) return '0';
    const units = ['ب', 'ك.ب', 'م.ب', 'ج.ب', 'ت.ب'];
    var value = bytes.toDouble();
    var i = 0;
    while (value >= 1024 && i < units.length - 1) {
      value /= 1024;
      i++;
    }
    return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final live = subscriber.live;
    final online = subscriber.online || (live?.online ?? false);
    final ip = live?.framedIp ?? '';
    final secs = live?.durationSeconds(now) ?? 0;
    // RFC 2866 (as «المتصلون»): bytes_out = DOWNLOAD, bytes_in = UPLOAD.
    final cells = <Widget>[
      _MiniBox(
        label: 'تحميل',
        value: live == null ? _dash : bytesLabel(live.bytesOut),
      ),
      _MiniBox(
        label: 'رفع',
        value: live == null ? _dash : bytesLabel(live.bytesIn),
      ),
      _MiniBox(
        label: 'IP',
        value: ip.isEmpty ? _dash : ltrIsolate(ip),
        link: ip.isNotEmpty,
        onTap: ip.isEmpty
            ? null
            : () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: 'http://$ip'));
                messenger.showSnackBar(
                  SnackBar(content: Text('نُسخ العنوان: http://$ip')),
                );
              },
      ),
      _MiniBox(
        label: 'المدة',
        value: live == null || secs <= 0 ? _dash : compactSessionDuration(secs),
        dot: online ? AppTokens.successStrong : null,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth < 280 ? 2 : 4;
        final rows = <Widget>[];
        for (var i = 0; i < cells.length; i += cols) {
          if (rows.isNotEmpty) rows.add(const SizedBox(height: 6));
          rows.add(
            Row(
              children: [
                for (var j = i; j < i + cols; j++) ...[
                  if (j > i) const SizedBox(width: 6),
                  Expanded(child: cells[j]),
                ],
              ],
            ),
          );
        }
        return Column(
          key: ValueKey('live-strip:${subscriber.username}'),
          mainAxisSize: MainAxisSize.min,
          children: rows,
        );
      },
    );
  }
}

class _MiniBox extends StatelessWidget {
  const _MiniBox({
    required this.label,
    required this.value,
    this.dot,
    this.link = false,
    this.onTap,
  });

  final String label;
  final String value;
  final Color? dot;
  final bool link;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppTokens.slate100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (dot != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 3),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.slate500,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: link ? AppTokens.brandInk : AppTokens.sidebarBg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                decoration: link ? TextDecoration.underline : null,
                decorationColor: AppTokens.brand3,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return box;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: box,
    );
  }
}

/// One subscriber = one white card (rounded, border, soft shadow) — clear
/// separation instead of a hairline between rows.
class _RowCard extends StatelessWidget {
  const _RowCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTokens.borderStrong),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1E1B4B),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(color: Colors.transparent, child: child),
      ),
    );
  }
}

/// Why «مشترك جديد» is refused for [p] (Arabic), or null when the server
/// would save a new subscriber.
String? subscriberCreateDenial(AppPermissions p) {
  if (!p.can('users.create')) return p.deniedReason(perm: 'users.create');
  if (!p.canAction('subscriber.create')) {
    return p.deniedReason(action: 'subscriber.create');
  }
  return null;
}
