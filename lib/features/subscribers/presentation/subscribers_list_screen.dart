import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
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

class SubscribersListScreen extends ConsumerStatefulWidget {
  const SubscribersListScreen({super.key});

  @override
  ConsumerState<SubscribersListScreen> createState() =>
      _SubscribersListScreenState();
}

class _SubscribersListScreenState extends ConsumerState<SubscribersListScreen> {
  String? _status;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(subscribersListProvider(_status));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'المشتركون',
          actions: [
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final search = TextField(
                decoration: const InputDecoration(
                  hintText: 'بحث بالاسم أو رقم الجوال…',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
              );
              final status = DropdownButtonFormField<String?>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'الحالة'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('كل الحالات')),
                  DropdownMenuItem(value: 'enabled', child: Text('مفعّل')),
                  DropdownMenuItem(value: 'disabled', child: Text('معطّل')),
                  DropdownMenuItem(value: 'expired', child: Text('منتهي')),
                ],
                onChanged: (v) => setState(() => _status = v),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    search,
                    const SizedBox(height: AppTokens.s12),
                    status,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: AppTokens.s12),
                  SizedBox(width: 180, child: status),
                ],
              );
            },
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
              child: _Table(items: filtered),
            );
          },
        ),
      ],
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.items});
  final List<Subscriber> items;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
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
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s8,
          ),
          leading: const CircleAvatar(
            backgroundColor: AppTokens.cyan100,
            child: Icon(Icons.person, color: AppTokens.cyan500),
          ),
          title: Text(
            s.fullName.isEmpty ? s.username : s.fullName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [
              s.username,
              if (s.mobile.isNotEmpty) s.mobile,
              if (s.expireAt != null) 'ينتهي: ${df.format(s.expireAt!)}',
            ].join(' • '),
            style: const TextStyle(color: AppTokens.textMuted),
          ),
          trailing: Wrap(
            spacing: AppTokens.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusPill(text: _statusLabel(s.status), tone: tone),
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
            'subscriber-edit',
            pathParameters: {'username': s.username},
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
