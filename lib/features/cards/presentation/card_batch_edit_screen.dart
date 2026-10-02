// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/format/number_input.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../admin_control/application/admin_control_providers.dart';
import '../application/card_batch_edit_provider.dart';
import '../application/cards_list_providers.dart';
import '../data/cards_repository.dart';
import '../domain/card_model.dart';
import 'widgets/card_batch_edit_runtime_section.dart';
import 'widgets/card_batch_edit_sections.dart';
import 'widgets/cards_form_header.dart';

class CardBatchEditScreen extends ConsumerStatefulWidget {
  const CardBatchEditScreen({super.key, required this.batchId});
  final int batchId;

  @override
  ConsumerState<CardBatchEditScreen> createState() =>
      _CardBatchEditScreenState();
}

class _CardBatchEditScreenState extends ConsumerState<CardBatchEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _packageName = TextEditingController();
  final _pricePerCard = TextEditingController();
  final _priceBulk = TextEditingController();
  final _totalPrice = TextEditingController();
  final _totalQuota = TextEditingController();
  final _serviceName = TextEditingController();
  final _managerId = TextEditingController();
  final _timeVal = TextEditingController();
  final _notes = TextEditingController();

  int? _loadedId;
  int? _planId;
  String _status = 'active';
  String _timeUnit = 'days';
  String _quotaAction = 'stop';
  int _devices = 0;
  String _deviceLimitMode = '';
  bool _countFromFirstConnect = true;
  bool _countBySeconds = false;
  bool _autoRenew = false;
  bool _switchMac = false;
  bool _lockMac = false;
  bool _loginWithoutPassword = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _packageName,
      _pricePerCard,
      _priceBulk,
      _totalPrice,
      _totalQuota,
      _serviceName,
      _managerId,
      _timeVal,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(CardBatch batch) {
    if (_loadedId == batch.id) return;
    _loadedId = batch.id;
    _packageName.text = batch.packageName;
    _planId = batch.planId;
    _pricePerCard.text = '${batch.pricePerCard}';
    _priceBulk.text = '${batch.priceBulk}';
    _totalPrice.text = '${batch.totalPrice}';
    _totalQuota.text = '${batch.totalQuotaMb}';
    _serviceName.text = batch.serviceName;
    _managerId.text = '${batch.managerId}';
    _timeVal.text = '${batch.timeValue}';
    _notes.text = batch.notes;
    _status = batch.status;
    _timeUnit = batch.timeUnit;
    _quotaAction = batch.onQuotaExhaust;
    _devices = normalizeCardDeviceCount(batch.deviceCount);
    _deviceLimitMode = batch.deviceLimitMode;
    _countFromFirstConnect = batch.countFromFirstConnect;
    _countBySeconds = batch.countBySeconds;
    _autoRenew = batch.autoRenewAfterFirstUse;
    _switchMac = batch.switchToMacOnConnect;
    _lockMac = batch.lockToMacOnClose;
    _loginWithoutPassword = batch.loginWithoutPassword;
  }

  Future<void> _save(CardBatch batch) async {
    if (!_formKey.currentState!.validate()) return;
    final planId = _planId ?? batch.planId;
    if (planId == null || planId <= 0) {
      setState(() => _error = 'اختر الباقة');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref.read(cardsRepositoryProvider).updateBatch(
            widget.batchId,
            UpdateBatchRequest(
              planId: planId,
              packageName: _packageName.text.trim(),
              status: _status,
              pricePerCard: parseNumberInput(_pricePerCard.text) ?? 0,
              priceBulk: parseNumberInput(_priceBulk.text) ?? 0,
              totalPrice: parseNumberInput(_totalPrice.text) ?? 0,
              totalQuotaMb: parseIntInput(_totalQuota.text) ?? 0,
              serviceName: _serviceName.text.trim(),
              managerId: parseIntInput(_managerId.text) ?? 0,
              timeValue: parseIntInput(_timeVal.text) ?? 0,
              timeUnit: _timeUnit,
              deviceCount: _devices,
              deviceLimitMode: _deviceLimitMode,
              // Not editable here — sent back unchanged (was reset to 0).
              validityAfterFirstLoginDays: batch.validityAfterFirstLoginDays,
              countBySeconds: _countBySeconds,
              countFromFirstConnect: _countFromFirstConnect,
              onQuotaExhaust: _quotaAction,
              autoRenewAfterFirstUse: _autoRenew,
              switchToMacOnConnect: _switchMac,
              lockToMacOnClose: _lockMac,
              loginWithoutPassword: _loginWithoutPassword,
              notes: _notes.text.trim(),
            ),
          );
      ref.invalidate(batchesListProvider);
      ref.invalidate(batchEditProvider(widget.batchId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ تعديلات باقة الكروت')),
      );
      context.goNamed(
        'card-batch-detail',
        pathParameters: {'id': '${updated.id ?? batch.id}'},
      );
    } catch (e) {
      setState(() => _error = visibleErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(batchEditProvider(widget.batchId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'تعذّر جلب باقة الكروت',
        subtitle: visibleErrorMessage(e),
      ),
      data: (batch) {
        _fill(batch);
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardsFormHeader(
                title: 'تعديل ${batch.batchCode}',
                onBack: () => context.goNamed(
                  'card-batch-detail',
                  pathParameters: {'id': '${batch.id ?? widget.batchId}'},
                ),
                actionLabel: 'حفظ',
                actionIcon: Icons.save_outlined,
                busy: _saving,
                onAction: () => _save(batch),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppTokens.s12),
                Container(
                  padding: const EdgeInsets.all(AppTokens.s12),
                  decoration: BoxDecoration(
                    color: AppTokens.dangerBg,
                    borderRadius: BorderRadius.circular(AppTokens.r10),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppTokens.red),
                  ),
                ),
              ],
              const SizedBox(height: AppTokens.s12),
              CardBatchCoreSection(
                packageName: _packageName,
                planId: _planId,
                planName: batch.planName,
                onPlan: (p) => setState(() => _planId = p.id),
                count: batch.count,
                status: _status,
                onStatus: (v) => setState(() => _status = v ?? 'active'),
                currency: ref.watch(tenantCurrencyProvider),
              ),
              const SizedBox(height: AppTokens.s12),
              CardBatchMoneySection(
                pricePerCard: _pricePerCard,
                priceBulk: _priceBulk,
                totalPrice: _totalPrice,
                totalQuota: _totalQuota,
                serviceName: _serviceName,
                managerId: _managerId,
              ),
              const SizedBox(height: AppTokens.s12),
              CardBatchGenerationSection(batch: batch),
              const SizedBox(height: AppTokens.s12),
              CardBatchRuntimeSection(
                timeVal: _timeVal,
                devices: _devices,
                onDevices: (v) => setState(() => _devices = v),
                deviceLimitMode: _deviceLimitMode,
                onDeviceLimitMode: (v) => setState(() => _deviceLimitMode = v),
                notes: _notes,
                timeUnit: _timeUnit,
                onTimeUnit: (v) => setState(() => _timeUnit = v ?? 'days'),
                quotaAction: _quotaAction,
                onQuotaAction: (v) =>
                    setState(() => _quotaAction = v ?? 'stop'),
                countFromFirstConnect: _countFromFirstConnect,
                onCountFromFirstConnect: (v) =>
                    setState(() => _countFromFirstConnect = v),
                countBySeconds: _countBySeconds,
                onCountBySeconds: (v) => setState(() => _countBySeconds = v),
                autoRenew: _autoRenew,
                onAutoRenew: (v) => setState(() => _autoRenew = v),
                switchMac: _switchMac,
                onSwitchMac: (v) => setState(() => _switchMac = v),
                lockMac: _lockMac,
                onLockMac: (v) => setState(() => _lockMac = v),
                loginWithoutPassword: _loginWithoutPassword,
                onLoginWithoutPassword: (v) =>
                    setState(() => _loginWithoutPassword = v),
              ),
              const SizedBox(height: AppTokens.s40),
            ],
          ),
        );
      },
    );
  }
}
