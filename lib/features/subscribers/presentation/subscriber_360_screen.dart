import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/subscribers_repository.dart';
import '../domain/subscriber_360_model.dart';
import 'widgets/subscriber_actions_sheet.dart';

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
          subtitle: s.fullName.isEmpty ? 'ملف المشترك 360' : s.username,
          leading: IconButton(
            onPressed: () => context.goNamed('subscribers'),
            icon: const Icon(Icons.arrow_back),
          ),
          inlineActions: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () =>
                  ref.invalidate(subscriber360Provider(s.username)),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        ActionBar(
          items: [
            ActionItem(
              icon: Icons.edit_outlined,
              label: 'تعديل',
              primary: true,
              onPressed: () => context.goNamed(
                'subscriber-edit',
                pathParameters: {'username': s.username},
              ),
            ),
            ActionItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'المالية',
              onPressed: () => context.goNamed(
                'subscriber-finance',
                pathParameters: {'username': s.username},
              ),
            ),
            ActionItem(
              icon: Icons.tune,
              label: 'إجراءات',
              onPressed: () => showSubscriberActionsSheet(
                context,
                ref,
                subscriber: s,
                planName: data.planName,
                onChanged: () =>
                    ref.invalidate(subscriber360Provider(s.username)),
                onRenamed: (name) => context.goNamed(
                  'subscriber-360',
                  pathParameters: {'username': name},
                ),
                onArchived: () => context.goNamed('subscribers'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            StatusPill(
              text: _statusLabel(data.status),
              tone: _statusTone(data.status),
              dot: true,
            ),
            StatusPill(
              text: _serviceTypeLabel(data.serviceType),
              tone: PillTone.blue,
            ),
            StatusPill(text: data.planName, tone: PillTone.brand),
            if (s.onlineCount > 0)
              const StatusPill(
                text: 'متصل الآن',
                tone: PillTone.green,
                dot: true,
              ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        // Six tight colour-coded counters instead of six one-per-row cards.
        CountGrid(
          columns: 3,
          items: [
            CountItem.text(
              'الرصيد',
              _money(data.walletBalance),
              tone: data.walletBalance < 0
                  ? PillTone.red
                  : data.walletBalance > 0
                      ? PillTone.green
                      : PillTone.brand,
            ),
            CountItem.text(
              'دين مفتوح',
              _money(data.openDebt),
              tone: data.openDebt > 0 ? PillTone.red : PillTone.neutral,
            ),
            CountItem.text(
              'إجمالي المدفوع',
              _money(data.financial.totalPaid),
              tone: data.financial.totalPaid > 0
                  ? PillTone.green
                  : PillTone.neutral,
            ),
            CountItem.text(
              'الاستخدام',
              _bytes(data.usage.totalBytes),
              tone: PillTone.blue,
            ),
            CountItem(
              'الجلسات',
              data.sessionCount,
              tone: data.sessionCount > 0 ? PillTone.blue : PillTone.neutral,
            ),
            CountItem(
              'الأجهزة',
              data.devices.length,
              tone: data.devices.isNotEmpty ? PillTone.brand : PillTone.neutral,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            final details = _DetailsCard(data: data);
            final usage = _UsageCard(data: data);
            if (!wide) {
              return Column(
                children: [
                  details,
                  const SizedBox(height: AppTokens.s12),
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
        const SizedBox(height: AppTokens.s12),
        _DevicesCard(devices: data.devices),
        const SizedBox(height: AppTokens.s12),
        _TimelineCard(items: data.timeline),
        const SizedBox(height: AppTokens.s40),
      ],
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
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s12,
        AppTokens.s4,
        AppTokens.s12,
        AppTokens.s8,
      ),
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
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoGrid(
            columns: 2,
            items: [
              InfoItem(
                icon: Icons.timer_outlined,
                label: 'إجمالي وقت الاتصال',
                value: _duration(data.usage.totalSeconds),
              ),
              InfoItem(
                icon: Icons.format_list_numbered,
                label: 'عدد الجلسات',
                value: '${data.usage.sessions.length}',
              ),
              InfoItem(
                icon: Icons.download_outlined,
                label: 'التحميل',
                value: _bytes(data.usage.downloadBytes),
              ),
              InfoItem(
                icon: Icons.upload_outlined,
                label: 'الرفع',
                value: _bytes(data.usage.uploadBytes),
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(AppTokens.s12),
      child: devices.isEmpty
          ? const _EmptyLine('لا توجد أجهزة مرتبطة بعد')
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
          ? const Padding(
              padding: EdgeInsets.all(AppTokens.s12),
              child: _EmptyLine('لا توجد أحداث حديثة'),
            )
          : Column(
              children: [
                for (final item in items.take(8)) ...[
                  ListTile(
                    dense: true,
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

/// Empty section → one muted line instead of a big centred illustration.
class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.slate100,
        borderRadius: BorderRadius.circular(AppTokens.r10),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppTokens.textMuted, fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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

String _serviceTypeLabel(String value) {
  return switch (value.trim().toLowerCase()) {
    'hotspot' => 'هوتسبوت',
    'pppoe' || 'broadband' => 'برودباند',
    'cards' || 'card' => 'كروت',
    '' => 'خدمة غير محددة',
    _ => 'خدمة غير معروفة',
  };
}

String _money(num value) => value == 0 ? '0' : value.toStringAsFixed(2);

/// Left-to-right mark: keeps «0 B» / «1.2 GB» in reading order inside the
/// RTL layout (it rendered as «B 0»).
String _bytes(num bytes) => '\u200E${_bytesRaw(bytes)}';

String _bytesRaw(num bytes) {
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
