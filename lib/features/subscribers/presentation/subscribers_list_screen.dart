import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/subscribers_repository.dart';
import '../domain/subscriber_model.dart';

final subscribersListProvider =
    FutureProvider.autoDispose.family<List<Subscriber>, String?>((ref, status) {
  return ref.watch(subscribersRepositoryProvider).list(status: status);
});

enum _Density { comfortable, compact }

class SubscribersListScreen extends ConsumerStatefulWidget {
  const SubscribersListScreen({super.key});

  @override
  ConsumerState<SubscribersListScreen> createState() =>
      _SubscribersListScreenState();
}

class _SubscribersListScreenState extends ConsumerState<SubscribersListScreen> {
  String? _status;
  String _query = '';
  _Density _density = _Density.comfortable;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(subscribersListProvider(_status));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'المشتركون',
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
            const SizedBox(width: AppTokens.s8),
            ElevatedButton.icon(
              onPressed: () => context.goNamed('subscriber-new'),
              icon: const Icon(Icons.add),
              label: const Text('مشترك جديد'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
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
            subtitle: '$e',
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
      ('disabled', 'معطّل'),
      ('expired', 'منتهي'),
    ];
    return Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      children: [
        for (final (code, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: value == code,
            onSelected: (_) => onChanged(code),
          ),
      ],
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.items, required this.density});
  final List<Subscriber> items;
  final _Density density;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    final p = AppPalette.of(context);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final s = items[i];
        final tone = s.status == 'enabled'
            ? PillTone.green
            : s.status == 'disabled'
                ? PillTone.red
                : PillTone.orange;
        return Dismissible(
          key: ValueKey('sub:${s.username}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            ctx.goNamed(
              'subscriber-finance',
              pathParameters: {'username': s.username},
            );
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
          child: ListTile(
            dense: density == _Density.compact,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppTokens.s16,
              vertical: density == _Density.compact ? 0 : AppTokens.s8,
            ),
            leading: CircleAvatar(
              backgroundColor: p.brandSoft,
              child: Icon(Icons.person, color: p.brand),
            ),
            title: Text(
              s.fullName.isEmpty ? s.username : s.fullName,
              style: AppTypography.labelLarge.copyWith(color: p.textPrimary),
            ),
            subtitle: Text(
              [
                s.username,
                if (s.mobile.isNotEmpty) s.mobile,
                if (s.expireAt != null) 'ينتهي: ${df.format(s.expireAt!)}',
              ].join(' • '),
              style: AppTypography.caption.copyWith(color: p.textMuted),
            ),
            trailing: Wrap(
              spacing: AppTokens.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusPill(text: _statusLabel(s.status), tone: tone),
                IconButton(
                  tooltip: 'ملف 360',
                  onPressed: () => ctx.goNamed(
                    'subscriber-360',
                    pathParameters: {'username': s.username},
                  ),
                  icon: const Icon(Icons.dashboard_customize_outlined),
                ),
                IconButton(
                  tooltip: 'الدفعات والسلف',
                  onPressed: () => ctx.goNamed(
                    'subscriber-finance',
                    pathParameters: {'username': s.username},
                  ),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                ),
              ],
            ),
            onTap: () => ctx.goNamed(
              'subscriber-360',
              pathParameters: {'username': s.username},
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
        _ => s,
      };
}
