// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/card_batch_edit_provider.dart';
import '../application/cards_list_providers.dart';
import '../data/cards_repository.dart';
import '../domain/card_model.dart';
import 'widgets/card_batch_edit_runtime_section.dart';
import 'widgets/card_batch_edit_sections.dart';

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
  final _plan = TextEditingController();
  final _count = TextEditingController();
  final _pricePerCard = TextEditingController();
  final _priceBulk = TextEditingController();
  final _totalPrice = TextEditingController();
  final _totalQuota = TextEditingController();
  final _serviceName = TextEditingController();
  final _managerId = TextEditingController();
  final _prefix = TextEditingController();
  final _suffix = TextEditingController();
  final _ulen = TextEditingController();
  final _plen = TextEditingController();
  final _timeVal = TextEditingController();
  final _devices = TextEditingController();
  final _notes = TextEditingController();

  int? _loadedId;
  String _status = 'active';
  String _passwordType = 'medium';
  String _affixMode = '';
  String _timeUnit = 'days';
  String _durationMode = 'time_unit';
  String _quotaAction = 'stop';
  bool _includeBatchNumber = false;
  bool _countFromFirstConnect = true;
  bool _countBySeconds = false;
  bool _autoRenew = false;
  bool _switchMac = false;
  bool _lockMac = false;
  bool _phoneOnly = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _packageName,
      _plan,
      _count,
      _pricePerCard,
      _priceBulk,
      _totalPrice,
      _totalQuota,
      _serviceName,
      _managerId,
      _prefix,
      _suffix,
      _ulen,
      _plen,
      _timeVal,
      _devices,
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
    _plan.text = '${batch.planId ?? ''}';
    _count.text = '${batch.count}';
    _pricePerCard.text = '${batch.pricePerCard}';
    _priceBulk.text = '${batch.priceBulk}';
    _totalPrice.text = '${batch.totalPrice}';
    _totalQuota.text = '${batch.totalQuotaMb}';
    _serviceName.text = batch.serviceName;
    _managerId.text = '${batch.managerId}';
    _prefix.text = batch.usernamePrefix;
    _suffix.text = batch.usernameSuffix;
    _ulen.text = '${batch.usernameLength}';
    _plen.text = '${batch.passwordLength}';
    _timeVal.text = '${batch.timeValue}';
    _devices.text = '${batch.deviceCount}';
    _notes.text = batch.notes;
    _status = batch.status;
    _passwordType = batch.passwordGenerationType;
    _affixMode = batch.startsWithOrEndsWith;
    _timeUnit = batch.timeUnit;
    _durationMode = batch.durationMode;
    _quotaAction = batch.onQuotaExhaust;
    _includeBatchNumber = batch.includeBatchNumber;
    _countFromFirstConnect = batch.countFromFirstConnect;
    _countBySeconds = batch.countBySeconds;
    _autoRenew = batch.autoRenewAfterFirstUse;
    _switchMac = batch.switchToMacOnConnect;
    _lockMac = batch.lockToMacOnClose;
    _phoneOnly = batch.phoneOnlyLogin;
  }

  Future<void> _save(CardBatch batch) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref.read(cardsRepositoryProvider).updateBatch(
            widget.batchId,
            UpdateBatchRequest(
              planId: int.parse(_plan.text.trim()),
              count: int.parse(_count.text.trim()),
              packageName: _packageName.text.trim(),
              status: _status,
              pricePerCard: num.tryParse(_pricePerCard.text.trim()) ?? 0,
              priceBulk: num.tryParse(_priceBulk.text.trim()) ?? 0,
              totalPrice: num.tryParse(_totalPrice.text.trim()) ?? 0,
              totalQuotaMb: int.tryParse(_totalQuota.text.trim()) ?? 0,
              serviceName: _serviceName.text.trim(),
              managerId: int.tryParse(_managerId.text.trim()) ?? 0,
              usernamePrefix: _prefix.text.trim(),
              usernameSuffix: _suffix.text.trim(),
              usernameLength: int.tryParse(_ulen.text.trim()) ?? 8,
              passwordLength: int.tryParse(_plen.text.trim()) ?? 6,
              passwordGenerationType: _passwordType,
              includeBatchNumber: _includeBatchNumber,
              startsWithOrEndsWith: _affixMode,
              prefixOrSuffixValue: _affixMode == 'suffix'
                  ? _suffix.text.trim()
                  : _affixMode == 'prefix'
                      ? _prefix.text.trim()
                      : '',
              timeValue: int.tryParse(_timeVal.text.trim()) ?? 0,
              timeUnit: _timeUnit,
              deviceCount: int.tryParse(_devices.text.trim()) ?? 1,
              durationMode: _durationMode,
              countBySeconds: _countBySeconds,
              countFromFirstConnect: _countFromFirstConnect,
              onQuotaExhaust: _quotaAction,
              autoRenewAfterFirstUse: _autoRenew,
              switchToMacOnConnect: _switchMac,
              lockToMacOnClose: _lockMac,
              phoneOnlyLogin: _phoneOnly,
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
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.goNamed(
                      'card-batch-detail',
                      pathParameters: {'id': '${batch.id ?? widget.batchId}'},
                    ),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'تعديل ${batch.batchCode}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTokens.sidebarBg,
                              ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.goNamed('bandwidth-schedules'),
                    icon: const Icon(Icons.speed_outlined),
                    label: const Text('سرعات متعددة'),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : () => _save(batch),
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('حفظ'),
                  ),
                ],
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
              const SizedBox(height: AppTokens.s16),
              CardBatchCoreSection(
                packageName: _packageName,
                plan: _plan,
                count: _count,
                status: _status,
                onStatus: (v) => setState(() => _status = v ?? 'active'),
                minCount: batch.generated <= 0 ? 1 : batch.generated,
              ),
              const SizedBox(height: AppTokens.s16),
              CardBatchMoneySection(
                pricePerCard: _pricePerCard,
                priceBulk: _priceBulk,
                totalPrice: _totalPrice,
                totalQuota: _totalQuota,
                serviceName: _serviceName,
                managerId: _managerId,
              ),
              const SizedBox(height: AppTokens.s16),
              CardBatchGenerationSection(
                prefix: _prefix,
                suffix: _suffix,
                ulen: _ulen,
                plen: _plen,
                passwordType: _passwordType,
                onPasswordType: (v) =>
                    setState(() => _passwordType = v ?? 'medium'),
                affixMode: _affixMode,
                onAffixMode: (v) => setState(() => _affixMode = v ?? ''),
                includeBatchNumber: _includeBatchNumber,
                onIncludeBatchNumber: (v) =>
                    setState(() => _includeBatchNumber = v),
              ),
              const SizedBox(height: AppTokens.s16),
              CardBatchRuntimeSection(
                timeVal: _timeVal,
                devices: _devices,
                notes: _notes,
                timeUnit: _timeUnit,
                onTimeUnit: (v) => setState(() => _timeUnit = v ?? 'days'),
                durationMode: _durationMode,
                onDurationMode: (v) =>
                    setState(() => _durationMode = v ?? 'time_unit'),
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
                phoneOnly: _phoneOnly,
                onPhoneOnly: (v) => setState(() => _phoneOnly = v),
              ),
              const SizedBox(height: AppTokens.s40),
            ],
          ),
        );
      },
    );
  }
}
