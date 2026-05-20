import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/cards_repository.dart';
import '../domain/card_model.dart';

class CardCheckerScreen extends ConsumerStatefulWidget {
  const CardCheckerScreen({super.key});

  @override
  ConsumerState<CardCheckerScreen> createState() => _CardCheckerScreenState();
}

class _CardCheckerScreenState extends ConsumerState<CardCheckerScreen> {
  final _query = TextEditingController();
  bool _loading = false;
  bool _actionLoading = false;
  String? _error;
  CardCheckResult? _result;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'اكتب رقم البطاقة أو اسم الدخول أولًا.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final card = await ref.read(cardsRepositoryProvider).checkCard(query);
      if (!mounted) return;
      setState(() => _result = card);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runAction(
    Future<CardCheckResult> Function(CardsRepository repo) call, {
    required String success,
  }) async {
    setState(() {
      _actionLoading = true;
      _error = null;
    });
    try {
      final updated = await call(ref.read(cardsRepositoryProvider));
      if (!mounted) return;
      setState(() => _result = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تنفيذ العملية: $e')),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<String?> _askText({
    required String title,
    required String label,
    String initial = '',
  }) async {
    final ctrl = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: label),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('اعتماد'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return value?.trim();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'منصة عمليات البطاقة',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed:
                  _loading || _query.text.trim().isEmpty ? null : _search,
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final field = TextField(
                controller: _query,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: const InputDecoration(
                  labelText: 'رقم البطاقة أو اسم الدخول',
                  helperText: 'ابحث بدون كشف كلمة مرور البطاقة.',
                  prefixIcon: Icon(Icons.search),
                ),
              );
              final button = ElevatedButton.icon(
                onPressed: _loading ? null : _search,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.manage_search),
                label: const Text('فحص'),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    field,
                    const SizedBox(height: AppTokens.s12),
                    button,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: field),
                  const SizedBox(width: AppTokens.s12),
                  button,
                ],
              );
            },
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppTokens.s12),
          _InlineError(text: _error!),
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
          _SummaryHeader(card: result),
          const SizedBox(height: AppTokens.s16),
          _OperationsPanel(
            card: result,
            busy: _actionLoading,
            onEnable: () => _runAction(
              (repo) => repo.enableCard(result.id!),
              success: 'تم تفعيل البطاقة.',
            ),
            onDisable: () async {
              final reason = await _askText(
                title: 'تعطيل البطاقة',
                label: 'سبب التعطيل',
              );
              if (reason == null) return;
              await _runAction(
                (repo) => repo.disableCard(result.id!, reason: reason),
                success: 'تم تعطيل البطاقة بدون حذفها.',
              );
            },
            onLockMac: () async {
              final mac = await _askText(
                title: 'تثبيت MAC',
                label: 'عنوان الجهاز',
                initial: result.macAddress ?? '',
              );
              if (mac == null || mac.isEmpty) return;
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
              final ok = await _confirm(
                'تصفير استخدام البطاقة',
                'سيتم تصفير وقت بداية الاستخدام والجهاز المرصود. متابعة؟',
              );
              if (!ok) return;
              await _runAction(
                (repo) => repo.resetCardUsage(result.id!),
                success: 'تم تصفير استخدام البطاقة.',
              );
            },
            onDisconnect: () async {
              final ok = await _confirm(
                'طرد الجلسة',
                'سيتم إرسال طلب طرد الجلسة النشطة لهذه البطاقة.',
              );
              if (!ok) return;
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
              final typed = await _askText(
                title: 'حذف نهائي شديد الحساسية',
                label: 'اكتب اسم البطاقة للتأكيد: ${result.username}',
              );
              if (typed != result.username) return;
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
          _DetailsGrid(card: result),
          const SizedBox(height: AppTokens.s16),
          _MacsCard(summary: result.accountingSummary),
          const SizedBox(height: AppTokens.s16),
          _SessionsCard(sessions: result.accountingSummary.latestSessions),
          const SizedBox(height: AppTokens.s40),
        ],
      ],
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.card});
  final CardCheckResult card;

  @override
  Widget build(BuildContext context) {
    final summary = card.accountingSummary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.username,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTokens.navy900,
                        fontFamily: 'monospace',
                      ),
                ),
              ),
              StatusPill(
                text: _statusLabel(card.status),
                tone: _statusTone(card.status),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          LayoutBuilder(
            builder: (context, constraints) {
              final items = [
                _Metric(
                  icon: Icons.devices_outlined,
                  label: 'أجهزة مختلفة',
                  value: '${summary.uniqueMacs}',
                ),
                _Metric(
                  icon: Icons.history,
                  label: 'عدد الجلسات',
                  value: '${summary.sessionsCount}',
                ),
                _Metric(
                  icon: Icons.wifi_tethering,
                  label: 'جلسات نشطة',
                  value: '${summary.onlineSessions}',
                ),
                _Metric(
                  icon: Icons.timer_outlined,
                  label: 'الوقت الكلي',
                  value: _formatDuration(summary.totalSessionSeconds),
                ),
                _Metric(
                  icon: Icons.cloud_upload_outlined,
                  label: 'رفع',
                  value: _formatBytes(summary.totalUploadBytes),
                ),
                _Metric(
                  icon: Icons.cloud_download_outlined,
                  label: 'تنزيل',
                  value: _formatBytes(summary.totalDownloadBytes),
                ),
              ];
              final cols = constraints.maxWidth >= 780 ? 3 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                mainAxisSpacing: AppTokens.s8,
                crossAxisSpacing: AppTokens.s8,
                childAspectRatio: constraints.maxWidth < 520 ? 1.65 : 2.5,
                children: items,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OperationsPanel extends StatelessWidget {
  const _OperationsPanel({
    required this.card,
    required this.busy,
    required this.onEnable,
    required this.onDisable,
    required this.onLockMac,
    required this.onUnlockMac,
    required this.onResetUsage,
    required this.onDisconnect,
    required this.onDeletePermanent,
  });

  final CardCheckResult card;
  final bool busy;
  final VoidCallback onEnable;
  final VoidCallback onDisable;
  final VoidCallback onLockMac;
  final VoidCallback onUnlockMac;
  final VoidCallback onResetUsage;
  final VoidCallback onDisconnect;
  final VoidCallback onDeletePermanent;

  @override
  Widget build(BuildContext context) {
    final id = card.id;
    final enabled = id != null && !busy;
    return AppCard(
      title: 'إجراءات البطاقة',
      icon: Icons.tune,
      child: Wrap(
        spacing: AppTokens.s8,
        runSpacing: AppTokens.s8,
        children: [
          ElevatedButton.icon(
            onPressed: enabled && card.operations.canEnable ? onEnable : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('تفعيل'),
          ),
          OutlinedButton.icon(
            onPressed: enabled && card.operations.canDisable ? onDisable : null,
            icon: const Icon(Icons.pause_circle_outline),
            label: const Text('تعطيل'),
          ),
          OutlinedButton.icon(
            onPressed: enabled ? onLockMac : null,
            icon: const Icon(Icons.lock_outline),
            label: const Text('تثبيت MAC'),
          ),
          OutlinedButton.icon(
            onPressed: enabled && (card.lockedMac?.isNotEmpty ?? false)
                ? onUnlockMac
                : null,
            icon: const Icon(Icons.lock_open),
            label: const Text('فك MAC'),
          ),
          OutlinedButton.icon(
            onPressed:
                enabled && card.operations.canResetUsage ? onResetUsage : null,
            icon: const Icon(Icons.restart_alt),
            label: const Text('تصفير الاستخدام'),
          ),
          OutlinedButton.icon(
            onPressed:
                enabled && card.operations.canDisconnect ? onDisconnect : null,
            icon: const Icon(Icons.power_settings_new),
            label: const Text('طرد الجلسة'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppTokens.red),
            onPressed: enabled && card.operations.canDeletePermanently
                ? onDeletePermanent
                : null,
            icon: const Icon(Icons.delete_forever),
            label: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.card});
  final CardCheckResult card;

  @override
  Widget build(BuildContext context) {
    final items = <_InfoItem>[
      _InfoItem('الحزمة', card.batch?.batchCode ?? 'غير معروف'),
      _InfoItem('اسم الحزمة', card.batch?.packageName ?? 'غير معروف'),
      _InfoItem('العرض', card.profile?.name ?? 'غير معروف'),
      _InfoItem(
        'كلمة المرور',
        card.hasPassword ? 'موجودة ومخفية' : 'غير موجودة',
      ),
      _InfoItem('أول استخدام', _formatDate(card.startedAt)),
      _InfoItem('آخر ظهور', _formatDate(card.lastSeenAt)),
      _InfoItem('تنتهي في', _formatDate(card.expiresAt)),
      _InfoItem('المتبقي', _formatDuration(card.remainingSeconds ?? 0)),
      _InfoItem('MAC الحالي', card.macAddress ?? 'غير معروف'),
      _InfoItem('MAC مثبت', card.lockedMac ?? 'غير مثبت'),
      _InfoItem('IP', card.ipAddress ?? 'غير معروف'),
      _InfoItem('NAS', card.nasAddress ?? 'غير معروف'),
      _InfoItem('مصادر البيانات', _joinLocalized(card.dataSources)),
      _InfoItem(
        'حقول ناقصة',
        card.missingFields.isEmpty
            ? 'لا يوجد'
            : _joinLocalized(card.missingFields),
      ),
    ];
    return AppCard(
      title: 'بيانات البطاقة',
      icon: Icons.info_outline,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 900 ? 3 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: AppTokens.s8,
              crossAxisSpacing: AppTokens.s8,
              childAspectRatio: constraints.maxWidth < 520 ? 2.45 : 4.2,
            ),
            itemBuilder: (_, i) => _InfoTile(item: items[i]),
          );
        },
      ),
    );
  }
}

class _MacsCard extends StatelessWidget {
  const _MacsCard({required this.summary});
  final CardAccountingSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.macs.isEmpty) {
      return const AppCard(
        title: 'الأجهزة التي استخدمت البطاقة',
        icon: Icons.devices_outlined,
        child: Text(
          'لا توجد أجهزة مسجلة بعد. ستظهر هنا بعد أول اتصال فعلي.',
          style: TextStyle(color: AppTokens.textMuted),
        ),
      );
    }
    return AppCard(
      title: 'الأجهزة التي استخدمت البطاقة',
      icon: Icons.devices_outlined,
      child: Column(
        children: [
          for (final mac in summary.macs)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.devices, color: AppTokens.cyan500),
              title: Text(
                mac.mac,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              subtitle: Text(
                'جلسات: ${mac.sessionsCount} • نشطة: ${mac.onlineSessions}'
                ' • آخر ظهور: ${_formatDate(mac.lastSeenAt)}',
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionsCard extends StatelessWidget {
  const _SessionsCard({required this.sessions});
  final List<CardSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const AppCard(
        title: 'جلسات البطاقة',
        icon: Icons.table_rows_outlined,
        child: Text(
          'لا توجد جلسات محفوظة لهذه البطاقة بعد.',
          style: TextStyle(color: AppTokens.textMuted),
        ),
      );
    }
    return AppCard(
      title: 'جلسات البطاقة',
      icon: Icons.table_rows_outlined,
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sessions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final s = sessions[index];
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16,
              vertical: AppTokens.s8,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    s.sessionId.isEmpty ? 'جلسة #${s.id ?? '-'}' : s.sessionId,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusPill(
                  text: s.online ? 'متصل' : 'منتهية',
                  tone: s.online ? PillTone.green : PillTone.neutral,
                ),
              ],
            ),
            subtitle: Wrap(
              spacing: AppTokens.s12,
              runSpacing: 4,
              children: [
                _Tiny(
                  icon: Icons.play_circle_outline,
                  text: _formatDate(s.startedAt),
                ),
                _Tiny(
                  icon: Icons.stop_circle_outlined,
                  text: _formatDate(s.stoppedAt),
                ),
                _Tiny(
                  icon: Icons.timer_outlined,
                  text: _formatDuration(s.durationSeconds),
                ),
                if (s.macAddress != null)
                  _Tiny(icon: Icons.devices, text: s.macAddress!),
                if (s.ipAddress != null)
                  _Tiny(icon: Icons.dns, text: s.ipAddress!),
                if (s.nasAddress != null)
                  _Tiny(icon: Icons.router_outlined, text: s.nasAddress!),
                _Tiny(
                  icon: Icons.cloud_upload_outlined,
                  text: _formatBytes(s.uploadBytes),
                ),
                _Tiny(
                  icon: Icons.cloud_download_outlined,
                  text: _formatBytes(s.downloadBytes),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTokens.cyan500, size: 20),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontSize: 11,
                    height: 1.15,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppTokens.navy900,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  _InfoItem(this.label, this.value);
  final String label;
  final String value;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.item});
  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            style: const TextStyle(color: AppTokens.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTokens.navy900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tiny extends StatelessWidget {
  const _Tiny({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTokens.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE9E9),
        borderRadius: BorderRadius.circular(AppTokens.r10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTokens.red),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppTokens.red)),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
      'available' => 'متاحة',
      'active' => 'نشطة',
      'expired' => 'منتهية',
      'revoked' => 'معطلة',
      'deleted' => 'محذوفة',
      'not_found' => 'غير موجودة',
      _ => status,
    };

PillTone _statusTone(String status) => switch (status) {
      'available' => PillTone.green,
      'active' => PillTone.cyan,
      'expired' => PillTone.orange,
      'revoked' || 'deleted' => PillTone.red,
      _ => PillTone.neutral,
    };

String _formatDate(DateTime? value) {
  if (value == null) return 'غير معروف';
  return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
}

String _formatDuration(int seconds) {
  if (seconds <= 0) return 'غير محدد';
  final d = Duration(seconds: seconds);
  if (d.inDays > 0) return '${d.inDays}ي ${d.inHours.remainder(24)}س';
  if (d.inHours > 0) return '${d.inHours}س ${d.inMinutes.remainder(60)}د';
  if (d.inMinutes > 0) return '${d.inMinutes}د ${d.inSeconds.remainder(60)}ث';
  return '${d.inSeconds}ث';
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[unit]}';
}

String _joinLocalized(List<String> values) {
  if (values.isEmpty) return 'غير متوفر';
  return values.map(_fieldLabel).join('، ');
}

String _fieldLabel(String value) => switch (value) {
      'assigned_to' => 'المسؤول عن البطاقة',
      'cancelled_at' => 'وقت الإلغاء',
      'deleted_at' => 'وقت الأرشفة',
      'sold_by' => 'البائع',
      'cards' => 'بيانات البطاقات',
      'card_batches' => 'حزم البطاقات',
      'radacct' => 'جلسات الاتصال',
      'profiles' => 'العروض',
      'nas' => 'أجهزة الشبكة',
      'accounting' => 'المحاسبة',
      _ => value.replaceAll('_', ' '),
    };
