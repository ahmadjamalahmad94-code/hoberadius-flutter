import 'package:hoberadius_app/core/format/bidi.dart';
import 'package:hoberadius_app/core/l10n/arabic_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

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
  String? _action;
  final _searchCtrl = TextEditingController();
  final _targetIdCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _targetIdCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final q = AuditQuery(
      actor: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      action: _action,
      targetType: _targetType,
      targetId:
          _targetIdCtrl.text.trim().isEmpty ? null : _targetIdCtrl.text.trim(),
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
                  hintText: 'ابحث باسم المدير أو رمز التكامل...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onSubmitted: (_) => _applyFilters(),
              );
              final action = DropdownButton<String?>(
                value: _action,
                hint: const Text('الإجراء'),
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: null, child: Text('كل الإجراءات')),
                  DropdownMenuItem(value: 'create', child: Text('إنشاء')),
                  DropdownMenuItem(value: 'update', child: Text('تعديل')),
                  DropdownMenuItem(value: 'delete', child: Text('حذف')),
                  DropdownMenuItem(value: 'archive', child: Text('أرشفة')),
                  DropdownMenuItem(value: 'restore', child: Text('استعادة')),
                  DropdownMenuItem(value: 'login', child: Text('دخول')),
                  DropdownMenuItem(value: 'logout', child: Text('خروج')),
                ],
                onChanged: (v) {
                  setState(() => _action = v);
                  _applyFilters();
                },
              );
              final type = DropdownButton<String?>(
                value: _targetType,
                hint: const Text('النوع'),
                isExpanded: true,
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
              final targetId = TextField(
                controller: _targetIdCtrl,
                decoration: const InputDecoration(
                  hintText: 'رقم العنصر',
                  prefixIcon: Icon(Icons.tag_outlined),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _applyFilters(),
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
                    const SizedBox(height: AppTokens.s12),
                    action,
                    const SizedBox(height: AppTokens.s12),
                    targetId,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: AppTokens.s12),
                  SizedBox(width: 130, child: action),
                  const SizedBox(width: AppTokens.s8),
                  SizedBox(width: 150, child: type),
                  const SizedBox(width: AppTokens.s8),
                  SizedBox(width: 140, child: targetId),
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
            subtitle: visibleErrorMessage(e),
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
    final tone = _toneFor(event.action);
    final accent = switch (tone) {
      PillTone.red => AppTokens.redInk,
      PillTone.green => AppTokens.greenInk,
      PillTone.orange => AppTokens.amberInk,
      PillTone.navy => AppTokens.brandInk,
      _ => AppTokens.brand,
    };
    return ListTile(
      leading: SizedBox(
        width: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                _iconFor(event.targetType),
                color: accent,
                size: 16,
              ),
            ),
          ],
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
            'المنفذ: ${event.actorName.isNotEmpty ? event.actorName : _actorLabel(event.actor)}',
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
  if (value == 'admin') return 'المدير';
  return actorLabel(value.replaceAll('actor:', '').trim());
}

/// The audit vocabulary word by word. The server logs well over a hundred
/// action codes (`card_print_template.export_pdf`, `bandwidth_schedule.
/// apply_live`, …) and no fixed list can cover them, so both the domain and
/// the verb are translated token by token and only a token the app has
/// never seen is left alone.
const Map<String, String> _auditWords = {
  // domains / nouns
  'admin': 'مدير', 'admins': 'المدراء', 'role': 'دور', 'roles': 'الأدوار',
  'user': 'مستفيد', 'users': 'المستفيدين', 'subscriber': 'مستفيد',
  'subscribers': 'المستفيدين', 'plan': 'باقة', 'plans': 'الباقات',
  'profile': 'ملف', 'card': 'بطاقة', 'cards': 'البطاقات', 'batch': 'حزمة',
  'nas': 'جهاز شبكة', 'session': 'جلسة', 'sessions': 'الجلسات',
  'payment': 'دفعة', 'payments': 'الدفعات', 'loan': 'سلفة',
  'ledger': 'قيد مالي', 'invoice': 'فاتورة', 'wallet': 'محفظة',
  'voucher': 'قسيمة', 'distributor': 'موزّع', 'store': 'متجر',
  'template': 'قالب', 'print': 'طباعة', 'backup': 'نسخة احتياطية',
  'bandwidth': 'السرعة', 'schedule': 'جدول', 'speed': 'سرعة',
  'speeds': 'السرعات', 'policy': 'سياسة', 'device': 'جهاز',
  'devices': 'الأجهزة', 'router': 'راوتر', 'mac': 'عنوان MAC',
  'password': 'كلمة المرور', 'username': 'اسم المستخدم', 'time': 'الوقت',
  'quota': 'الحصة', 'usage': 'الاستهلاك', 'data': 'البيانات',
  'notification': 'إشعار', 'notifications': 'الإشعارات', 'ticket': 'تذكرة',
  'license': 'الترخيص', 'settings': 'الإعدادات', 'hotspot': 'هوتسبوت',
  'access': 'الوصول', 'control': 'التحكّم', 'remote': 'عن بُعد',
  'member': 'عضو', 'expense': 'مصروف', 'inventory': 'المخزون',
  'item': 'عنصر', 'company': 'الشركة', 'offer': 'عرض', 'page': 'صفحة',
  'auth': 'المصادقة', 'fixtures': 'بيانات تجريبية', 'demo': 'تجريبي',
  'accounting': 'المحاسبة', 'messages': 'الرسائل', 'error': 'خطأ',
  'local': 'محليّة', 'live': 'مباشرةً', 'planned': 'المجدولة',
  'permanent': 'نهائيّ', 'default': 'الافتراضيّ', 'pdf': 'PDF',
  'panel': 'اللوحة', 'bridge': 'الجسر', 'link': 'الربط', 'mode': 'الوضع',
  'clone': 'الاستنساخ', 'anti': 'منع',
  // verbs
  'create': 'إنشاء', 'created': 'إنشاء', 'add': 'إضافة', 'update': 'تعديل',
  'updated': 'تعديل', 'patch': 'تعديل', 'edit': 'تعديل', 'set': 'ضبط',
  'save': 'حفظ', 'delete': 'حذف', 'deleted': 'حذف', 'remove': 'إزالة',
  'archive': 'أرشفة', 'restore': 'استعادة', 'purge': 'حذف نهائيّ',
  'disable': 'تعطيل', 'deactivate': 'تعطيل', 'enable': 'تفعيل',
  'activate': 'تفعيل', 'disconnect': 'طرد', 'login': 'دخول',
  'logout': 'خروج', 'export': 'تصدير', 'import': 'استيراد',
  'upload': 'رفع', 'uploaded': 'رفع', 'download': 'تنزيل',
  'generate': 'توليد', 'assign': 'إسناد', 'revoke': 'سحب',
  'reset': 'تصفير', 'apply': 'تطبيق', 'applied': 'تطبيق',
  'engage': 'تشغيل', 'extend': 'تمديد', 'adjust': 'تعديل',
  'change': 'تغيير', 'lock': 'قفل', 'unlock': 'فكّ القفل',
  'reveal': 'إظهار', 'send': 'إرسال', 'cancel': 'إلغاء',
  'accept': 'قبول', 'deny': 'رفض', 'reject': 'رفض', 'allow': 'سماح',
  'forgive': 'مسامحة', 'settle': 'تسديد', 'post': 'ترحيل',
  'reconcile': 'مطابقة', 'cleanup': 'تنظيف', 'pruned': 'تقليم',
  'prune': 'تقليم', 'run': 'تشغيل', 'close': 'إغلاق', 'open': 'فتح',
  'expire': 'إنهاء', 'visit': 'زيارة', 'failed': 'فشل',
  'aborted': 'أُلغيت', 'toggle': 'تبديل', 'upsert': 'حفظ',
  'bulk': 'جماعيّ', 'issued': 'إصدار', 'clear': 'مسح', 'copy': 'نسخ',
  'migrate': 'ترحيل', 'connect': 'ربط', 'config': 'إعداد',
  'count': 'عدد', 'health': 'فحص', 'drop': 'إسقاط', 'split': 'تقسيم',
};

/// One `snake_case` segment in Arabic. An untranslatable remainder is kept
/// as a single left-to-right run so RTL never reorders it.
String _auditSegment(String value, {required String emptyLabel}) {
  final raw = value.trim();
  if (raw.isEmpty) return emptyLabel;
  final tokens = raw.toLowerCase().split(RegExp(r'[_\s-]+'))
    ..removeWhere((t) => t.isEmpty);
  if (tokens.isEmpty) return emptyLabel;
  final out = <String>[];
  final unknown = <String>[];
  for (final t in tokens) {
    final w = _auditWords[t];
    if (w != null) {
      out.add(w);
    } else {
      unknown.add(t);
    }
  }
  if (out.isEmpty) return ltrIsolate(raw);
  if (unknown.isEmpty) return out.join(' ');
  return '${out.join(' ')} ${ltrIsolate(unknown.join(' '))}';
}

String _targetLabel(String value) => switch (value) {
      'card_batch' => 'حزمة بطاقات',
      'ledger' => 'قيد مالي',
      // نشاطُ المدير (زيارةُ صفحةٍ/محاولةٌ محجوبة) — كان يظهر «manager_activity» خامًّا
      // في كلِّ صفٍّ من «سجل التدقيق» لأنّ لا كلمةَ من مقطعَيه في _auditWords (r6ui).
      'manager_activity' => 'نشاط مدير',
      _ => _auditSegment(value, emptyLabel: 'عنصر'),
    };

String _shortActionLabel(String rawAction) {
  // The pill shows the verb only: «card_print_template.export_pdf» is
  // «تصدير PDF», not the whole dotted code.
  final action = rawAction.split('.').last;
  final a = action.toLowerCase();
  // «page_visit» كانت تُركَّب كلمةً بكلمة فتصير «صفحة زيارة» (ترتيبٌ مقلوب).
  if (a == 'page_visit') return 'زيارة صفحة';
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
  return _auditSegment(action, emptyLabel: 'عملية');
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
