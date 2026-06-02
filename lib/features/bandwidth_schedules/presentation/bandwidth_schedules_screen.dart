import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../cards/domain/card_model.dart';
import '../../plans/domain/plan_model.dart';
import '../../subscribers/domain/subscriber_model.dart';
import '../application/bandwidth_schedules_controller.dart';
import '../application/bandwidth_schedules_providers.dart';
import '../domain/bandwidth_schedule_model.dart';
import 'widgets/bandwidth_form_card.dart';
import 'widgets/bandwidth_schedules_list.dart';

class BandwidthSchedulesScreen extends ConsumerStatefulWidget {
  const BandwidthSchedulesScreen({super.key});

  @override
  ConsumerState<BandwidthSchedulesScreen> createState() =>
      _BandwidthSchedulesScreenState();
}

class _BandwidthSchedulesScreenState
    extends ConsumerState<BandwidthSchedulesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _down = TextEditingController(text: '3000');
  final _up = TextEditingController(text: '1000');
  final _cirDown = TextEditingController(text: '0');
  final _cirUp = TextEditingController(text: '0');
  final _priority = TextEditingController(text: '100');
  final _notes = TextEditingController();
  String _targetType = 'plan';
  String _starts = '22:00';
  String _ends = '06:00';
  String _restoreMode = 'profile_default';
  int? _planId;
  String? _subscriberUsername;
  int? _cardBatchId;
  bool _enabled = true;
  bool _saving = false;
  bool _applying = false;

  @override
  void dispose() {
    _name.dispose();
    _down.dispose();
    _up.dispose();
    _cirDown.dispose();
    _cirUp.dispose();
    _priority.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(bandwidthSchedulesProvider);
    final plans = ref.watch(bandwidthPlansProvider);
    final subscribers = ref.watch(bandwidthSubscribersProvider);
    final batches = ref.watch(bandwidthCardBatchesProvider);
    final planItems = plans.valueOrNull ?? const <Plan>[];
    final subscriberItems = subscribers.valueOrNull ?? const <Subscriber>[];
    final batchItems = batches.valueOrNull ?? const <CardBatch>[];
    final planNames = {
      for (final plan in planItems)
        if (plan.id != null) plan.id!: plan.name,
    };
    final batchNames = {
      for (final batch in batchItems)
        if (batch.id != null)
          batch.id!: batch.packageName.isNotEmpty
              ? '${batch.batchCode} - ${batch.packageName}'
              : batch.batchCode,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'جدولة السرعات',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.sidebarBg,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () {
                ref.invalidate(bandwidthSchedulesProvider);
                ref.invalidate(bandwidthPlansProvider);
                ref.invalidate(bandwidthSubscribersProvider);
                ref.invalidate(bandwidthCardBatchesProvider);
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        const AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppTokens.amber),
              SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'هذه الشاشة تحفظ خطط تغيير السرعة وتنفذ تجربة تطبيق فقط. لا يوجد عامل تشغيل لحظي يغيّر الريدياس الآن، لذلك تظهر النتيجة: لم يتم التطبيق فعليًا.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final form = BandwidthFormCard(
              formKey: _formKey,
              plans: planItems,
              subscribers: subscriberItems,
              batches: batchItems,
              targetType: _targetType,
              planId: _planId,
              subscriberUsername: _subscriberUsername,
              cardBatchId: _cardBatchId,
              name: _name,
              down: _down,
              up: _up,
              cirDown: _cirDown,
              cirUp: _cirUp,
              priority: _priority,
              notes: _notes,
              starts: _starts,
              ends: _ends,
              restoreMode: _restoreMode,
              enabled: _enabled,
              saving: _saving,
              onTargetTypeChanged: (v) => setState(() {
                _targetType = v;
                _planId = null;
                _subscriberUsername = null;
                _cardBatchId = null;
              }),
              onPlanChanged: (v) => setState(() => _planId = v),
              onSubscriberChanged: (v) =>
                  setState(() => _subscriberUsername = v),
              onCardBatchChanged: (v) => setState(() => _cardBatchId = v),
              onStartsChanged: (v) => setState(() => _starts = v),
              onEndsChanged: (v) => setState(() => _ends = v),
              onRestoreChanged: (v) => setState(() => _restoreMode = v),
              onEnabledChanged: (v) => setState(() => _enabled = v),
              onSubmit: _createSchedule,
            );
            final list = schedules.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'تعذر تحميل جداول السرعة',
                subtitle: visibleErrorMessage(e),
              ),
              data: (items) => BandwidthSchedulesList(
                items: items,
                planNames: planNames,
                batchNames: batchNames,
                applying: _applying,
                onApplyDryRun: (item) => _applySchedule(item),
                onApplyLive: (item) => _applySchedule(item, live: true),
              ),
            );
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  form,
                  const SizedBox(height: AppTokens.s12),
                  list,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 410, child: form),
                const SizedBox(width: AppTokens.s12),
                Expanded(child: list),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _createSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result =
        await ref.read(bandwidthSchedulesControllerProvider).create(
              targetType: _targetType,
              planId: _targetType == 'plan' ? _planId : null,
              subscriberUsername:
                  _targetType == 'subscriber' ? (_subscriberUsername ?? '') : '',
              cardBatchId: _targetType == 'card_batch' ? _cardBatchId : null,
              priority: int.tryParse(_priority.text.trim()) ?? 0,
              name: _name.text.trim(),
              startsAtTime: _starts,
              endsAtTime: _ends,
              speedDownKbps: int.tryParse(_down.text.trim()) ?? 0,
              speedUpKbps: int.tryParse(_up.text.trim()) ?? 0,
              cirDownKbps: int.tryParse(_cirDown.text.trim()) ?? 0,
              cirUpKbps: int.tryParse(_cirUp.text.trim()) ?? 0,
              restoreMode: _restoreMode,
              enabled: _enabled,
              notes: _notes.text.trim(),
            );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.message != null) {
      _name.clear();
      _notes.clear();
    }
    final text = result.error ?? result.message;
    if (text != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _applySchedule(
    BandwidthSchedule item, {
    bool live = false,
  }) async {
    setState(() => _applying = true);
    final result = await ref
        .read(bandwidthSchedulesControllerProvider)
        .apply(item, live: live);
    if (!mounted) return;
    setState(() => _applying = false);
    final text = result.error ?? result.message;
    if (text != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }
}
