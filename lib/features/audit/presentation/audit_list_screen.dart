import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/audit_repository.dart';
import '../domain/audit_model.dart';

class AuditListScreen extends ConsumerStatefulWidget {
  const AuditListScreen({super.key});

  @override
  ConsumerState<AuditListScreen> createState() => _AuditListScreenState();
}

class _AuditListScreenState extends ConsumerState<AuditListScreen> {
  String? _targetType;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final q = AuditQuery(
      actor: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      targetType: _targetType,
    );
    ref.read(auditQueryProvider.notifier).state = q;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(auditListProvider);
    final df = DateFormat('yyyy-MM-dd HH:mm:ss');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'سجل التدقيق',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () => ref.invalidate(auditListProvider),
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
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'ابحث باسم المنفذ أو المدير...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onSubmitted: (_) => _applyFilters(),
              );
              final type = DropdownButton<String?>(
                value: _targetType,
                hint: const Text('النوع'),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: null, child: Text('كل الأنواع')),
                  DropdownMenuItem(value: 'admin', child: Text('مدير')),
                  DropdownMenuItem(value: 'role', child: Text('دور')),
                  DropdownMenuItem(value: 'user', child: Text('مستفيد')),
                  DropdownMenuItem(value: 'plan', child: Text('باقة')),
                  DropdownMenuItem(
                    value: 'card_batch',
                    child: Text('حزمة بطاقات'),
                  ),
                  DropdownMenuItem(value: 'card', child: Text('بطاقة')),
                  DropdownMenuItem(value: 'nas', child: Text('جهاز شبكة')),
                  DropdownMenuItem(value: 'session', child: Text('جلسة')),
                ],
                onChanged: (v) {
                  setState(() => _targetType = v);
                  _applyFilters();
                },
              );
              final button = IconButton(
                tooltip: 'تطبيق',
                onPressed: _applyFilters,
                icon: const Icon(Icons.filter_alt_outlined),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    search,
                    const SizedBox(height: AppTokens.s12),
                    Row(children: [Expanded(child: type), button]),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: AppTokens.s12),
                  type,
                  const SizedBox(width: AppTokens.s8),
                  button,
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
            title: 'تعذّر جلب السجل',
            subtitle: '$e',
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(auditListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.history_toggle_off,
                title: 'لا توجد أحداث تطابق الفلتر',
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) => _AuditTile(event: items[i], df: df),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.event, required this.df});
  final AuditEvent event;
  final DateFormat df;

  PillTone _toneFor(String action) {
    final a = action.toLowerCase();
    if (a.contains('delete') ||
        a.contains('revoke') ||
        a.contains('disconnect')) {
      return PillTone.red;
    }
    if (a.contains('create')) return PillTone.green;
    if (a.contains('update') || a.contains('patch')) return PillTone.orange;
    if (a.contains('login') || a.contains('logout')) return PillTone.navy;
    return PillTone.cyan;
  }

  IconData _iconFor(String t) => switch (t.toLowerCase()) {
        'admin' => Icons.admin_panel_settings_outlined,
        'role' => Icons.shield_outlined,
        'user' => Icons.person_outline,
        'plan' => Icons.workspace_premium_outlined,
        'card_batch' || 'card' => Icons.credit_card_outlined,
        'nas' => Icons.router_outlined,
        'session' => Icons.signal_wifi_4_bar,
        _ => Icons.event_note_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTokens.brandSoft,
        child: Icon(
          _iconFor(event.targetType),
          color: AppTokens.brand,
          size: 18,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${_actionLabel(event.action)}  •  ${_targetLabel(event.targetType)}${event.targetId.isNotEmpty ? " #${event.targetId}" : ""}',
              style: const TextStyle(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          StatusPill(
            text: _shortActionLabel(event.action),
            tone: _toneFor(event.action),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          [
            'المنفذ: ${_actorLabel(event.actor)}',
            if (event.ipAddress.isNotEmpty) event.ipAddress,
            if (event.createdAt != null) df.format(event.createdAt!.toLocal()),
          ].join(' • '),
          style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
        ),
      ),
      trailing: event.payload.isEmpty
          ? null
          : IconButton(
              tooltip: 'عرض التفاصيل',
              icon: const Icon(Icons.info_outline, color: AppTokens.textMuted),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (d) => AlertDialog(
                  title: Text('تفاصيل العملية — ${_actionLabel(event.action)}'),
                  content: SingleChildScrollView(
                    child: SelectableText(_payloadText(event.payload)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(d),
                      child: const Text('إغلاق'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

String _actorLabel(String value) {
  if (value.isEmpty) return '-';
  if (value.startsWith('api-token')) return 'رمز تكامل';
  if (value == 'admin') return 'المدير';
  return value.replaceAll('actor:', '').trim();
}

String _targetLabel(String value) => switch (value) {
      'admin' => 'مدير',
      'role' => 'دور',
      'user' => 'مستفيد',
      'subscriber' => 'مستفيد',
      'plan' => 'باقة',
      'card_batch' => 'حزمة بطاقات',
      'card' => 'بطاقة',
      'nas' => 'جهاز شبكة',
      'session' => 'جلسة',
      'payment' => 'دفعة',
      'loan' => 'سلفة',
      'ledger' => 'قيد مالي',
      _ => value.isEmpty ? 'عنصر' : value.replaceAll('_', ' '),
    };

String _shortActionLabel(String action) {
  final a = action.toLowerCase();
  if (a.contains('create')) return 'إنشاء';
  if (a.contains('update') || a.contains('patch')) return 'تعديل';
  if (a.contains('archive')) return 'أرشفة';
  if (a.contains('restore')) return 'استعادة';
  if (a.contains('disable')) return 'تعطيل';
  if (a.contains('enable')) return 'تفعيل';
  if (a.contains('disconnect')) return 'طرد';
  if (a.contains('delete')) return 'حذف';
  if (a.contains('login')) return 'دخول';
  if (a.contains('logout')) return 'خروج';
  return action.replaceAll('_', ' ');
}

String _actionLabel(String action) {
  final parts = action.split('.');
  if (parts.length >= 2) {
    return '${_targetLabel(parts.first)} - ${_shortActionLabel(parts.last)}';
  }
  return _shortActionLabel(action);
}

String _payloadText(Map<String, dynamic> payload) {
  if (payload.isEmpty) return 'لا توجد تفاصيل إضافية.';
  return payload.entries
      .map(
        (entry) => '${_payloadKey(entry.key)}: ${_payloadValue(entry.value)}',
      )
      .join('\n');
}

String _payloadKey(String key) => switch (key) {
      'mode' => 'طريقة التنفيذ',
      'reason' => 'السبب',
      'status' => 'الحالة',
      'username' => 'اسم الدخول',
      'batch_id' => 'رقم الحزمة',
      'card_id' => 'رقم البطاقة',
      'subscriber_id' => 'رقم المستفيد',
      'amount' => 'المبلغ',
      'currency' => 'العملة',
      _ => key.replaceAll('_', ' '),
    };

String _payloadValue(Object? value) {
  if (value == null) return '-';
  final text = value.toString();
  return switch (text) {
    'soft_delete' => 'أرشفة آمنة',
    'archive' => 'أرشفة',
    'restore' => 'استعادة',
    'active' => 'مفعّل',
    'disabled' => 'معطّل',
    _ => text,
  };
}
