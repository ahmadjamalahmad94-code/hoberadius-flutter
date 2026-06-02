import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/events_providers.dart';
import '../data/events_repository.dart';
import '../domain/business_event_model.dart';

class EventsCenterScreen extends ConsumerWidget {
  const EventsCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(businessEventsProvider);
    final summary = ref.watch(businessSummaryProvider);
    final category = ref.watch(selectedEventCategoryProvider);
    final severity = ref.watch(selectedEventSeverityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'مركز الأحداث',
          subtitle:
              'متابعة أحداث التشغيل والمالية والأمان من نفس سجل الخادم، مع تسجيل حدث إداري واضح عند الحاجة.',
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(businessEventsProvider);
                ref.invalidate(businessSummaryProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
            ElevatedButton.icon(
              onPressed: () => _showRecordEventDialog(context, ref),
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('تسجيل حدث'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1040;
            final side = _EventsSidePanel(
              summary: summary,
              category: category,
              severity: severity,
            );
            final list = _EventsList(events: events);
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  side,
                  const SizedBox(height: AppTokens.s12),
                  list,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 340, child: side),
                const SizedBox(width: AppTokens.s12),
                Expanded(child: list),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EventsSidePanel extends ConsumerWidget {
  const _EventsSidePanel({
    required this.summary,
    required this.category,
    required this.severity,
  });

  final AsyncValue<BusinessSummary> summary;
  final String category;
  final String severity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          title: 'الفلترة',
          icon: Icons.filter_alt_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'الفئة'),
                items: [
                  for (final option in businessEventCategoryOptions)
                    DropdownMenuItem(
                      value: option.value,
                      child: Text(option.label),
                    ),
                ],
                onChanged: (value) {
                  ref.read(selectedEventCategoryProvider.notifier).state =
                      value ?? '';
                },
              ),
              const SizedBox(height: AppTokens.s12),
              DropdownButtonFormField<String>(
                initialValue: severity,
                decoration: const InputDecoration(labelText: 'الخطورة'),
                items: [
                  for (final option in businessEventSeverityOptions)
                    DropdownMenuItem(
                      value: option.value,
                      child: Text(option.label),
                    ),
                ],
                onChanged: (value) {
                  ref.read(selectedEventSeverityProvider.notifier).state =
                      value ?? '';
                },
              ),
              const SizedBox(height: AppTokens.s12),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(selectedEventCategoryProvider.notifier).state = '';
                  ref.read(selectedEventSeverityProvider.notifier).state = '';
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('عرض كل الأحداث'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          title: 'ملخص السجل',
          icon: Icons.insights_outlined,
          child: summary.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppTokens.s16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text(
              visibleErrorMessage(error),
              style: const TextStyle(color: AppTokens.redInk),
            ),
            data: (data) => Column(
              children: [
                _SummaryRow(
                  icon: Icons.event_note_outlined,
                  label: 'الأحداث المسجلة',
                  value: data.events.toString(),
                  tone: PillTone.brand,
                ),
                const Divider(height: AppTokens.s20),
                _SummaryRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'المحافظ',
                  value: data.wallets.toString(),
                  tone: PillTone.green,
                ),
                const Divider(height: AppTokens.s20),
                _SummaryRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'القيود المالية',
                  value: data.ledgerEntries.toString(),
                  tone: PillTone.blue,
                ),
                const Divider(height: AppTokens.s20),
                _SummaryRow(
                  icon: Icons.price_change_outlined,
                  label: 'أسعار محفوظة',
                  value: data.priceSnapshots.toString(),
                  tone: PillTone.amber,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill(
                text: 'سجل مراقبة فقط',
                tone: PillTone.blue,
                icon: Icons.visibility_outlined,
              ),
              SizedBox(height: AppTokens.s12),
              Text(
                'هذه الصفحة تعرض ما سجله الخادم من أحداث تشغيلية ومالية وأمنية. تسجيل حدث يدوي يفيد في توثيق مراجعة أو إجراء إداري، ولا يطبق أوامر على الراوتر.',
                style: TextStyle(color: AppTokens.textMuted, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EventsList extends ConsumerWidget {
  const _EventsList({required this.events});

  final AsyncValue<BusinessEventsPage> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return events.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppTokens.s40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => HubErrorState(
        title: 'تعذر تحميل الأحداث',
        subtitle: visibleErrorMessage(error),
        onRetry: () => ref.invalidate(businessEventsProvider),
      ),
      data: (page) {
        if (page.items.isEmpty) {
          return EmptyState(
            icon: Icons.event_busy_outlined,
            title: 'لا توجد أحداث مطابقة',
            subtitle:
                'غيّر الفلترة أو سجل حدثًا إداريًا حتى يظهر هنا في سجل الخادم.',
            action: ElevatedButton.icon(
              onPressed: () => _showRecordEventDialog(context, ref),
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('تسجيل حدث'),
            ),
          );
        }
        return AppCard(
          title: 'الأحداث الأخيرة',
          icon: Icons.event_note_outlined,
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: page.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _EventTile(event: page.items[index]);
            },
          ),
        );
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final BusinessEvent event;

  @override
  Widget build(BuildContext context) {
    final tone = _severityTone(event.severity);
    return Padding(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: _severityBg(event.severity),
                child:
                    Icon(_categoryIcon(event.category), color: _toneFg(tone)),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.eventKeyLabel,
                      style: const TextStyle(
                        color: AppTokens.sidebarBg,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.messageLabel,
                      style: const TextStyle(
                        color: AppTokens.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(text: event.severityLabel, tone: tone, dot: true),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              StatusPill(
                text: event.categoryLabel,
                tone: PillTone.brand,
                icon: _categoryIcon(event.category),
              ),
              StatusPill(
                text: event.actorLabel,
                tone: PillTone.neutral,
                icon: Icons.person_outline,
              ),
              if (event.targetType.isNotEmpty || event.targetId > 0)
                StatusPill(
                  text: event.targetLabel,
                  tone: PillTone.neutral,
                  icon: Icons.ads_click_outlined,
                ),
              StatusPill(
                text: event.createdAtLabel,
                tone: PillTone.blue,
                icon: Icons.schedule_outlined,
              ),
              if (event.correlationId.isNotEmpty)
                const StatusPill(
                  text: 'مرتبط بسلسلة متابعة',
                  tone: PillTone.amber,
                  icon: Icons.link,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: _toneBg(tone),
          child: Icon(icon, size: 16, color: _toneFg(tone)),
        ),
        const SizedBox(width: AppTokens.s8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTokens.sidebarBg,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _RecordEventDialog extends ConsumerStatefulWidget {
  const _RecordEventDialog();

  @override
  ConsumerState<_RecordEventDialog> createState() => _RecordEventDialogState();
}

class _RecordEventDialogState extends ConsumerState<_RecordEventDialog> {
  final _message = TextEditingController();
  final _actorId = TextEditingController();
  final _targetId = TextEditingController();
  final _correlation = TextEditingController();
  String _category = 'system';
  String _severity = 'info';
  String _eventKey = _eventKeyOptions.first.value;
  String _actorType = '';
  String _targetType = '';
  bool _saving = false;

  @override
  void dispose() {
    _message.dispose();
    _actorId.dispose();
    _targetId.dispose();
    _correlation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تسجيل حدث إداري'),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'الفئة'),
                items: [
                  for (final option in businessEventCategoryOptions.skip(1))
                    DropdownMenuItem(
                      value: option.value,
                      child: Text(option.label),
                    ),
                ],
                onChanged: (value) {
                  setState(() => _category = value ?? _category);
                },
              ),
              const SizedBox(height: AppTokens.s12),
              DropdownButtonFormField<String>(
                initialValue: _severity,
                decoration: const InputDecoration(labelText: 'الخطورة'),
                items: [
                  for (final option in businessEventSeverityOptions.skip(1))
                    DropdownMenuItem(
                      value: option.value,
                      child: Text(option.label),
                    ),
                ],
                onChanged: (value) {
                  setState(() => _severity = value ?? _severity);
                },
              ),
              const SizedBox(height: AppTokens.s12),
              DropdownButtonFormField<String>(
                initialValue: _eventKey,
                decoration: const InputDecoration(labelText: 'نوع الحدث'),
                items: [
                  for (final option in _eventKeyOptions)
                    DropdownMenuItem(
                      value: option.value,
                      child: Text(option.label),
                    ),
                ],
                onChanged: (value) {
                  setState(() => _eventKey = value ?? _eventKey);
                },
              ),
              const SizedBox(height: AppTokens.s12),
              TextField(
                controller: _message,
                decoration: const InputDecoration(
                  labelText: 'وصف الحدث',
                  hintText: 'مثال: تمت مراجعة طلب العميل وتمت الموافقة عليه',
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: AppTokens.s12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _actorType,
                      decoration:
                          const InputDecoration(labelText: 'من نفذ الإجراء'),
                      items: [
                        for (final option in _entityOptions)
                          DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() => _actorType = value ?? '');
                      },
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: TextField(
                      controller: _actorId,
                      decoration:
                          const InputDecoration(labelText: 'رقم المنفذ'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _targetType,
                      decoration:
                          const InputDecoration(labelText: 'العنصر المتأثر'),
                      items: [
                        for (final option in _entityOptions)
                          DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() => _targetType = value ?? '');
                      },
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: TextField(
                      controller: _targetId,
                      decoration:
                          const InputDecoration(labelText: 'رقم العنصر'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              TextField(
                controller: _correlation,
                decoration: const InputDecoration(
                  labelText: 'مرجع متابعة اختياري',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('حفظ الحدث'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final message = _message.text.trim();
    if (message.isEmpty) {
      _snack(context, 'أدخل وصفًا واضحًا للحدث');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(eventsRepositoryProvider).record(
            category: _category,
            severity: _severity,
            eventKey: _eventKey,
            message: message,
            actorType: _actorType,
            actorId: int.tryParse(_actorId.text.trim()),
            targetType: _targetType,
            targetId: int.tryParse(_targetId.text.trim()),
            correlationId: _correlation.text.trim(),
          );
      ref.invalidate(businessEventsProvider);
      ref.invalidate(businessSummaryProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack(context, 'تم حفظ الحدث');
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Choice {
  const _Choice(this.value, this.label);

  final String value;
  final String label;
}

const _eventKeyOptions = <_Choice>[
  _Choice('operator.review', 'مراجعة تشغيل'),
  _Choice('ledger.correction', 'تصحيح مالي'),
  _Choice('wallet.credit', 'إضافة رصيد للمحفظة'),
  _Choice('wallet.debit', 'خصم رصيد من المحفظة'),
  _Choice('price_snapshot.captured', 'حفظ سعر مرجعي'),
];

const _entityOptions = <_Choice>[
  _Choice('', 'غير محدد'),
  _Choice('admin', 'مدير'),
  _Choice('api_token', 'مفتاح ربط'),
  _Choice('subscriber', 'مشترك'),
  _Choice('card_user', 'مستخدم كرت'),
  _Choice('card', 'كرت'),
  _Choice('batch', 'حزمة كروت'),
  _Choice('nas', 'راوتر'),
  _Choice('wallet', 'محفظة'),
  _Choice('ledger', 'قيد مالي'),
  _Choice('system', 'النظام'),
];

Future<void> _showRecordEventDialog(BuildContext context, WidgetRef ref) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const _RecordEventDialog(),
  );
}

PillTone _severityTone(String value) {
  return switch (value) {
    'critical' || 'error' => PillTone.red,
    'warning' => PillTone.amber,
    'debug' => PillTone.neutral,
    _ => PillTone.blue,
  };
}

Color _severityBg(String value) {
  return switch (value) {
    'critical' || 'error' => AppTokens.redSoft,
    'warning' => AppTokens.amberSoft,
    'debug' => AppTokens.slate100,
    _ => AppTokens.blueSoft,
  };
}

Color _toneBg(PillTone tone) {
  return switch (tone) {
    PillTone.green => AppTokens.greenSoft,
    PillTone.amber || PillTone.orange => AppTokens.amberSoft,
    PillTone.red => AppTokens.redSoft,
    PillTone.blue => AppTokens.blueSoft,
    PillTone.neutral => AppTokens.slate100,
    _ => AppTokens.brandSoft,
  };
}

Color _toneFg(PillTone tone) {
  return switch (tone) {
    PillTone.green => AppTokens.greenInk,
    PillTone.amber || PillTone.orange => AppTokens.amberInk,
    PillTone.red => AppTokens.redInk,
    PillTone.blue => AppTokens.blueInk,
    PillTone.neutral => AppTokens.slate500,
    _ => AppTokens.brandInk,
  };
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'manager' => Icons.admin_panel_settings_outlined,
    'subscriber' => Icons.groups_2_outlined,
    'card' => Icons.credit_card_outlined,
    'financial' => Icons.account_balance_wallet_outlined,
    'security' => Icons.security_outlined,
    'radius' => Icons.wifi_tethering,
    'notification' => Icons.notifications_active_outlined,
    _ => Icons.settings_suggest_outlined,
  };
}

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
