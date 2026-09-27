import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../provider_grants/application/provider_grants_provider.dart';
import '../../provider_grants/presentation/limit_usage_banner.dart';
import '../data/subscribers_repository.dart';
import '../domain/subscriber_model.dart';
import 'widgets/subscriber_dialogs.dart';

/// Pseudo-status for «ينتهي خلال ٣ أيام» (active subscribers whose expiry
/// falls in the next 3 days) — matches the web's `attention=expiring_3d` and
/// the dashboard «expiring_soon» counter.
const kExpiringSoonFilter = 'expiring_3d';

final subscribersListProvider = FutureProvider.autoDispose
    .family<List<Subscriber>, String?>((ref, status) async {
  final repo = ref.watch(subscribersRepositoryProvider);
  if (status != kExpiringSoonFilter) return repo.list(status: status);
  // Ask the server to filter (newer backends honour expiring_within_days)
  // and guard client-side with the same rule, so older servers that ignore
  // the param still show only the right rows.
  final items = await repo.list(status: 'enabled', expiringWithinDays: 3);
  return filterExpiringSoon(items, DateTime.now());
});

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
  _Density _density = _Density.comfortable;

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
    final async = ref.watch(subscribersListProvider(_status));
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
                  hintText: 'بحث بالاسم أو رقم الجوال…',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
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
          data: (items) {
            final filtered = items.where((s) {
              if (_query.isEmpty) return true;
              return s.username.toLowerCase().contains(_query) ||
                  s.fullName.toLowerCase().contains(_query) ||
                  s.mobile.contains(_query);
            }).toList();
            if (filtered.isEmpty) {
              return const EmptyState(
                icon: Icons.person_off_outlined,
                title: 'لا توجد نتائج',
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: _Table(items: filtered, density: _density),
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
    // One horizontal row (scrolls) instead of ragged wrapped rows; a dot in
    // each status's own colour ties the filter to the badges in the list.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (code, label) in options) ...[
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
              onSelected: (_) => onChanged(code),
            ),
            const SizedBox(width: AppTokens.s8),
          ],
        ],
      ),
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

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref,
    Subscriber s,
    String action,
  ) async {
    final repo = ref.read(subscribersRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    void snack(String m) => messenger.showSnackBar(SnackBar(content: Text(m)));
    try {
      switch (action) {
        case 'edit':
          context.goNamed(
            'subscriber-edit',
            pathParameters: {'username': s.username},
          );
          return;
        case 'toggle':
          if (s.status == 'disabled') {
            await repo.enable(s.username);
            snack('تم التفعيل');
          } else {
            await repo.disable(s.username);
            snack('تم التعطيل');
          }
        case 'extend':
          final mins = await askExtendMinutes(context);
          if (mins == null) return;
          await repo.extendTime(s.username, mins);
          snack('تم التمديد $mins دقيقة');
        case 'reset':
          final pw = await askNewPassword(context);
          if (pw == null) return;
          await repo.resetPassword(s.username, pw);
          snack('تمّ تحديث كلمة المرور');
        case 'delete':
          final ok = await confirmDeleteSubscriber(context, s.username);
          if (!ok) return;
          await repo.delete(s.username);
          snack('تم حذف ${s.username}');
      }
      ref.invalidate(subscribersListProvider);
    } catch (e) {
      snack(visibleErrorMessage(e));
    }
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    Subscriber s,
  ) async {
    final action = await showModalBottomSheet<String>(
      // Above the whole app: the shell's pages live inside one scroll view,
      // so a sheet on the inner navigator was drawn below the long content,
      // off-screen — only the dim barrier showed.
      useRootNavigator: true,
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s12,
            0,
            AppTokens.s12,
            AppTokens.s8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.s8),
                child: Text(
                  s.fullName.isEmpty ? s.username : s.fullName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(sheet).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                      ),
                ),
              ),
              for (final (value, icon, label, tone) in [
                ('edit', Icons.edit_outlined, 'تعديل', PillTone.brand),
                if (s.status == 'disabled')
                  (
                    'toggle',
                    Icons.play_circle_outline,
                    'تفعيل',
                    PillTone.green,
                  )
                else
                  (
                    'toggle',
                    Icons.pause_circle_outline,
                    'تعطيل',
                    PillTone.amber,
                  ),
                (
                  'extend',
                  Icons.more_time_outlined,
                  'تمديد الوقت',
                  PillTone.green,
                ),
                (
                  'reset',
                  Icons.password_outlined,
                  'إعادة تعيين كلمة المرور',
                  PillTone.blue,
                ),
                ('delete', Icons.delete_outline, 'حذف', PillTone.red),
              ])
                _SheetAction(
                  icon: icon,
                  label: label,
                  tone: tone,
                  onTap: () => Navigator.pop(sheet, value),
                ),
            ],
          ),
        ),
      ),
    );
    if (action != null && context.mounted) {
      await _runAction(context, ref, s, action);
    }
  }

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
      separatorBuilder: (_, __) => const Divider(height: 1),
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
        return Dismissible(
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

/// One row of the subscriber actions sheet: a tinted icon chip in the
/// action's colour + its label — compact, and each action reads at a glance.
class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final PillTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = pillToneColors(tone);
    final danger = tone == PillTone.red;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s4,
          vertical: 6,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppTokens.r10),
                border: Border.all(color: border.withValues(alpha: 0.6)),
              ),
              child: Icon(icon, size: 19, color: fg),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: danger ? AppTokens.red : AppTokens.textPrimary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
