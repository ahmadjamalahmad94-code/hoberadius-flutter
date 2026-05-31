import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/subscribers_repository.dart';
import '../domain/subscriber_360_model.dart';

final subscriber360Provider =
    FutureProvider.autoDispose.family<Subscriber360, String>((ref, username) {
  return ref.watch(subscribersRepositoryProvider).get360(username);
});

class Subscriber360Screen extends ConsumerWidget {
  const Subscriber360Screen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subscriber360Provider(username));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        async.when(
          loading: () => PageHeader(
            title: 'ملف المشترك 360',
            leading: IconButton(
              onPressed: () => context.goNamed('subscribers'),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          error: (_, __) => Column(
            children: [
              PageHeader(
                title: 'ملف المشترك 360',
                leading: IconButton(
                  onPressed: () => context.goNamed('subscribers'),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              HubErrorState(
                title: 'تعذر جلب ملف المشترك',
                subtitle: 'تحقق من اتصال التطبيق بالريدياس ثم أعد المحاولة.',
                onRetry: () => ref.invalidate(subscriber360Provider(username)),
              ),
            ],
          ),
          data: (data) => _Subscriber360Content(data: data),
        ),
      ],
    );
  }
}

class _Subscriber360Content extends ConsumerWidget {
  const _Subscriber360Content({required this.data});

  final Subscriber360 data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = data.subscriber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: s.fullName.isEmpty ? s.username : s.fullName,
          subtitle:
              'ملف المشترك 360: هوية، خدمة، مالية، استخدام، أجهزة، وأحداث.',
          leading: IconButton(
            onPressed: () => context.goNamed('subscribers'),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.goNamed(
                'subscriber-edit',
                pathParameters: {'username': s.username},
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('تعديل'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.goNamed(
                'subscriber-finance',
                pathParameters: {'username': s.username},
              ),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('المالية'),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () =>
                  ref.invalidate(subscriber360Provider(s.username)),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            StatusPill(
              text: _statusLabel(data.status),
              tone: _statusTone(data.status),
              dot: true,
            ),
            StatusPill(text: data.serviceType, tone: PillTone.blue),
            StatusPill(text: data.planName, tone: PillTone.brand),
            if (s.onlineCount > 0)
              const StatusPill(
                text: 'متصل الآن',
                tone: PillTone.green,
                dot: true,
              ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        _KpiGrid(
          items: [
            _Kpi(
              'الرصيد',
              _money(data.walletBalance),
              Icons.wallet_outlined,
            ),
            _Kpi(
              'دين مفتوح',
              _money(data.openDebt),
              Icons.receipt_long_outlined,
            ),
            _Kpi(
              'إجمالي المدفوع',
              _money(data.financial.totalPaid),
              Icons.payments_outlined,
            ),
            _Kpi(
              'الاستخدام',
              _bytes(data.usage.totalBytes),
              Icons.data_usage_outlined,
            ),
            _Kpi(
              'الجلسات',
              '${data.sessionCount}',
              Icons.online_prediction,
            ),
            _Kpi(
              'الأجهزة',
              '${data.devices.length}',
              Icons.devices_other_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            final details = _DetailsCard(data: data);
            final usage = _UsageCard(data: data);
            if (!wide) {
              return Column(
                children: [
                  details,
                  const SizedBox(height: AppTokens.s16),
                  usage,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: details),
                const SizedBox(width: AppTokens.s16),
                Expanded(child: usage),
              ],
            );
          },
        ),
        const SizedBox(height: AppTokens.s16),
        _DevicesCard(devices: data.devices),
        const SizedBox(height: AppTokens.s16),
        _TimelineCard(items: data.timeline),
        const SizedBox(height: AppTokens.s40),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.items});

  final List<_Kpi> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 620
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: AppTokens.s8,
          mainAxisSpacing: AppTokens.s8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: cols == 1 ? 3.4 : 2.4,
          children: items.map(_KpiTile.new).toList(),
        );
      },
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _KpiTile extends StatelessWidget {
  const _KpiTile(this.item);

  final _Kpi item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.card,
        border: Border.all(color: AppTokens.border),
        borderRadius: BorderRadius.circular(AppTokens.r14),
        boxShadow: AppTokens.shCard,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTokens.brandSoft,
              borderRadius: BorderRadius.circular(AppTokens.r10),
            ),
            child: Icon(item.icon, color: AppTokens.brand),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.data});

  final Subscriber360 data;

  @override
  Widget build(BuildContext context) {
    final s = data.subscriber;
    return AppCard(
      title: 'بيانات الحساب والخدمة',
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          _InfoRow('اسم الدخول', s.username),
          _InfoRow('الاسم', s.fullName),
          _InfoRow('الجوال', s.mobile),
          _InfoRow('البريد', s.email),
          _InfoRow('نوع الخدمة', data.serviceType),
          _InfoRow('الباقة', data.planName),
          _InfoRow(
            'السعر المخصص',
            s.customPrice > 0
                ? '${_money(s.customPrice)} (بدل سعر الباقة)'
                : 'سعر الباقة',
          ),
          _InfoRow('IP ثابت', s.staticIp),
          _InfoRow('قفل MAC', s.macLock),
          _InfoRow('ملاحظات', data.notes.isEmpty ? s.remark : data.notes),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.data});

  final Subscriber360 data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'الاستخدام والجلسات',
      icon: Icons.insights_outlined,
      child: Column(
        children: [
          _InfoRow('إجمالي وقت الاتصال', _duration(data.usage.totalSeconds)),
          _InfoRow('التحميل', _bytes(data.usage.downloadBytes)),
          _InfoRow('الرفع', _bytes(data.usage.uploadBytes)),
          _InfoRow('عدد الجلسات', '${data.usage.sessions.length}'),
          if (data.usage.sessions.isNotEmpty)
            _InfoRow(
              'آخر جلسة',
              data.usage.sessions.first['acctstarttime']?.toString() ?? '',
            ),
          if (data.loginEvents.isNotEmpty)
            _InfoRow(
              'آخر محاولة دخول',
              data.loginEvents.first['reply']?.toString() ?? '',
            ),
        ],
      ),
    );
  }
}

class _DevicesCard extends StatelessWidget {
  const _DevicesCard({required this.devices});

  final List<Subscriber360Device> devices;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'الأجهزة المرتبطة',
      icon: Icons.devices_other_outlined,
      child: devices.isEmpty
          ? const EmptyState(
              icon: Icons.devices_other_outlined,
              title: 'لا توجد أجهزة مرتبطة بعد',
            )
          : Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              children: [
                for (final device in devices)
                  StatusPill(
                    text: '${device.mac} · ${_deviceSource(device.source)}',
                    tone: PillTone.blue,
                  ),
              ],
            ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.items});

  final List<Subscriber360TimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'آخر الأحداث',
      icon: Icons.timeline,
      padding: EdgeInsets.zero,
      child: items.isEmpty
          ? const EmptyState(
              icon: Icons.timeline,
              title: 'لا توجد أحداث حديثة',
            )
          : Column(
              children: [
                for (final item in items.take(8)) ...[
                  ListTile(
                    title: Text(item.label),
                    subtitle: Text(
                      item.createdAt.isEmpty ? 'بدون وقت' : item.createdAt,
                    ),
                    leading: const Icon(
                      Icons.circle,
                      size: 10,
                      color: AppTokens.brand,
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ],
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTokens.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppTokens.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

PillTone _statusTone(String status) {
  return switch (status) {
    'enabled' => PillTone.green,
    'disabled' => PillTone.red,
    'expired' => PillTone.orange,
    _ => PillTone.neutral,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'enabled' => 'مفعل',
    'disabled' => 'معطل',
    'expired' => 'منتهي',
    _ => 'غير معروف',
  };
}

String _money(num value) => value == 0 ? '0' : value.toStringAsFixed(2);

String _bytes(num bytes) {
  final value = bytes.toDouble();
  if (value >= 1024 * 1024 * 1024) {
    return '${(value / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
  if (value >= 1024 * 1024) {
    return '${(value / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  if (value >= 1024) return '${(value / 1024).toStringAsFixed(1)} KB';
  return '${value.toInt()} B';
}

String _duration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours > 0) return '$hours ساعة و $minutes دقيقة';
  return '$minutes دقيقة';
}

String _deviceSource(String source) {
  return switch (source) {
    'subscriber' => 'من الحساب',
    'session' => 'من الجلسات',
    _ => 'مصدر آخر',
  };
}
