import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/api/paging.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/load_more_footer.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../provider_grants/application/provider_grants_provider.dart';
import '../../provider_grants/presentation/limit_usage_banner.dart';
import '../data/subscribers_repository.dart';
import '../domain/subscriber_model.dart';
import 'widgets/subscriber_actions_sheet.dart';

/// Pseudo-status for «ينتهي خلال ٣ أيام» (active subscribers whose expiry
/// falls in the next 3 days) — matches the web's `attention=expiring_3d` and
/// the dashboard «expiring_soon» counter.
const kExpiringSoonFilter = 'expiring_3d';

/// What the list asks the server for: a status chip + the search box.
class SubscribersQuery {
  const SubscribersQuery({this.status, this.search = ''});

  final String? status;
  final String search;

  @override
  bool operator ==(Object other) =>
      other is SubscribersQuery &&
      other.status == status &&
      other.search == search;

  @override
  int get hashCode => Object.hash(status, search);
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
      limit: pageSize,
      offset: offset,
    );
    final items =
        _expiring ? filterExpiringSoon(page.items, DateTime.now()) : page.items;
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
  String _query = '';
  Timer? _debounce;
  _Density _density = _Density.comfortable;

  SubscribersQuery get _listQuery =>
      SubscribersQuery(status: _status, search: _query);

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'المشتركون',
          inlineActions: true,
          actions: [
            SegmentedButton<_Density>(
              segments: const [
                ButtonSegment(
                  value: _Density.comfortable,
                  icon: Icon(Icons.view_agenda_outlined),
                  tooltip: 'مريح',
                ),
                ButtonSegment(
                  value: _Density.compact,
                  icon: Icon(Icons.density_small_outlined),
                  tooltip: 'مكثّف',
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
              onPressed:
                  (ref.watch(grantLimitProvider('subscribers'))?.atCap ?? false)
                      ? null
                      : () => context.goNamed('subscriber-new'),
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
      (kExpiringSoonFilter, 'ينتهي خلال ٣ أيام'),
      ('expired', 'منتهي'),
      ('disabled', 'معطّل'),
      ('suspended', 'موقوف'),
      ('banned', 'محظور'),
    ];
    // All seven chips stay visible (they wrap onto a second row on phones);
    // the old single scrolling row hid 4 of 7 off-screen with no hint. A dot
    // in each status's own colour ties the filter to the badges in the list.
    return Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      children: [
        for (final (code, label) in options)
          ChoiceChip(
            avatar: code == null
                ? null
                : _ToneDot(
                    tone: code == kExpiringSoonFilter
                        ? PillTone.amber
                        : toneForStatus(code),
                  ),
            label: Text(label),
            selected: value == code,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => onChanged(code),
          ),
      ],
    );
  }
}

class _ToneDot extends StatelessWidget {
  const _ToneDot({required this.tone});
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final (_, fg, _) = pillToneColors(tone);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
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
    final now = DateTime.now();
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
