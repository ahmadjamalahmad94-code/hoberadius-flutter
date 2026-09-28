import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/load_more_footer.dart';
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
          // Was a whole explanation card; one muted line says the same.
          subtitle: 'سجل مراقبة فقط — لا يطبّق أوامر على الراوتر',
          inlineActions: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () {
                ref.invalidate(businessEventsProvider);
                ref.invalidate(businessSummaryProvider);
              },
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        ActionBar(
          items: [
            ActionItem(
              icon: Icons.add_alert_outlined,
              label: 'تسجيل حدث',
              primary: true,
              onPressed: () => _showRecordEventDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
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
        summary.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text(
            visibleErrorMessage(error),
            style: const TextStyle(color: AppTokens.redInk),
          ),
          data: (data) => CountGrid(
            columns: 2,
            items: [
              CountItem('الأحداث المسجلة', data.events, tone: PillTone.brand),
              CountItem('المحافظ', data.wallets, tone: PillTone.green),
              CountItem(
                'القيود المالية',
                data.ledgerEntries,
                tone: PillTone.blue,
              ),
              CountItem(
                'أسعار محفوظة',
                data.priceSnapshots,
                tone: PillTone.amber,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: category,
                  decoration: _filterDecoration('الفئة'),
                  items: [
                    for (final option in businessEventCategoryOptions)
                      DropdownMenuItem(
                        value: option.value,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    ref.read(selectedEventCategoryProvider.notifier).state =
                        value ?? '';
                  },
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: severity,
                  decoration: _filterDecoration('الخطورة'),
                  items: [
                    for (final option in businessEventSeverityOptions)
                      DropdownMenuItem(
                        value: option.value,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    ref.read(selectedEventSeverityProvider.notifier).state =
                        value ?? '';
                  },
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              IconButton.outlined(
                tooltip: 'عرض كل الأحداث',
                onPressed: () {
                  ref.read(selectedEventCategoryProvider.notifier).state = '';
                  ref.read(selectedEventSeverityProvider.notifier).state = '';
                },
                icon: const Icon(Icons.clear_all),
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
          child: Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: page.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return _EventTile(event: page.items[index]);
                },
              ),
              LoadMoreFooter(
                hasMore: page.hasMore,
                loading: false,
                shown: page.items.length,
                onLoadMore: () =>
                    ref.read(businessEventsProvider.notifier).loadMore(),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8 + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: _severityBg(event.severity),
                child: Icon(
                  _categoryIcon(event.category),
                  size: 18,
                  color: _toneFg(tone),
                ),
              ),
              const SizedBox(width: AppTokens.s8 + 2),
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
          const SizedBox(height: AppTokens.s8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
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
                isExpanded: true,
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
                isExpanded: true,
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
                isExpanded: true,
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
                      isExpanded: true,
                      initialValue: _actorType,
                      decoration: const InputDecoration(
                        labelText: 'من نفذ الإجراء',
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'رقم المنفذ',
                      ),
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
                      isExpanded: true,
                      initialValue: _targetType,
                      decoration: const InputDecoration(
                        labelText: 'العنصر المتأثر',
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'رقم العنصر',
                      ),
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
    useRootNavigator: true,
    builder: (_) => const _RecordEventDialog(),
  );
}

InputDecoration _filterDecoration(String label) => InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    );

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
