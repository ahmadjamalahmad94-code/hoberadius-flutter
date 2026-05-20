// ignore_for_file: require_trailing_commas, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../data/cards_repository.dart';
import '../domain/card_model.dart';
import 'cards_list_screen.dart';

final _batchEditProvider =
    FutureProvider.autoDispose.family<CardBatch, int>((ref, id) {
  return ref.watch(cardsRepositoryProvider).getBatch(id);
});

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
      ref.invalidate(_batchEditProvider(widget.batchId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ تعديلات باقة الكروت')),
      );
      context.goNamed(
        'card-batch-detail',
        pathParameters: {'id': '${updated.id ?? batch.id}'},
      );
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_batchEditProvider(widget.batchId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'تعذّر جلب باقة الكروت',
        subtitle: '$e',
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
                                color: AppTokens.navy900,
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
                    color: const Color(0xFFFDE9E9),
                    borderRadius: BorderRadius.circular(AppTokens.r10),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: AppTokens.red)),
                ),
              ],
              const SizedBox(height: AppTokens.s16),
              _CoreSection(
                packageName: _packageName,
                plan: _plan,
                count: _count,
                status: _status,
                onStatus: (v) => setState(() => _status = v ?? 'active'),
                minCount: batch.generated <= 0 ? 1 : batch.generated,
              ),
              const SizedBox(height: AppTokens.s16),
              _MoneySection(
                pricePerCard: _pricePerCard,
                priceBulk: _priceBulk,
                totalPrice: _totalPrice,
                totalQuota: _totalQuota,
                serviceName: _serviceName,
                managerId: _managerId,
              ),
              const SizedBox(height: AppTokens.s16),
              _GenerationSection(
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
              _RuntimeSection(
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

class _CoreSection extends StatelessWidget {
  const _CoreSection({
    required this.packageName,
    required this.plan,
    required this.count,
    required this.status,
    required this.onStatus,
    required this.minCount,
  });

  final TextEditingController packageName;
  final TextEditingController plan;
  final TextEditingController count;
  final String status;
  final ValueChanged<String?> onStatus;
  final int minCount;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'batch.edit.core',
      icon: Icons.credit_card_outlined,
      title: 'بيانات الباقة',
      child: Column(
        children: [
          FormFieldRow(
            label: 'اسم الباقة',
            child: TextFormField(controller: packageName),
          ),
          FormFieldRow(
            label: 'معرّف العرض',
            required: true,
            hint: 'تغيير العرض يطبّق على الكروت المتاحة فقط',
            child: TextFormField(
              controller: plan,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  int.tryParse(v?.trim() ?? '') == null ? 'مطلوب' : null,
            ),
          ),
          FormFieldRow(
            label: 'عدد الباقة',
            required: true,
            hint: 'لا يمكن أن يكون أقل من $minCount',
            child: TextFormField(
              controller: count,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < minCount || n > 2000) {
                  return 'بين $minCount و 2000';
                }
                return null;
              },
            ),
          ),
          FormFieldRow(
            label: 'الحالة',
            child: DropdownButtonFormField<String>(
              value: status,
              items: const [
                DropdownMenuItem(value: 'active', child: Text('نشطة')),
                DropdownMenuItem(value: 'exhausted', child: Text('مستهلكة')),
                DropdownMenuItem(value: 'revoked', child: Text('ملغاة')),
              ],
              onChanged: onStatus,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneySection extends StatelessWidget {
  const _MoneySection({
    required this.pricePerCard,
    required this.priceBulk,
    required this.totalPrice,
    required this.totalQuota,
    required this.serviceName,
    required this.managerId,
  });

  final TextEditingController pricePerCard;
  final TextEditingController priceBulk;
  final TextEditingController totalPrice;
  final TextEditingController totalQuota;
  final TextEditingController serviceName;
  final TextEditingController managerId;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'batch.edit.money',
      icon: Icons.sell_outlined,
      title: 'السعر والحصة',
      child: Column(
        children: [
          FormFieldRow(
            label: 'سعر البطاقة',
            child: TextFormField(
                controller: pricePerCard, keyboardType: TextInputType.number),
          ),
          FormFieldRow(
            label: 'سعر الجملة',
            child: TextFormField(
                controller: priceBulk, keyboardType: TextInputType.number),
          ),
          FormFieldRow(
            label: 'السعر الإجمالي',
            child: TextFormField(
                controller: totalPrice, keyboardType: TextInputType.number),
          ),
          FormFieldRow(
            label: 'الحصة الكلية MB',
            child: TextFormField(
                controller: totalQuota, keyboardType: TextInputType.number),
          ),
          FormFieldRow(
            label: 'اسم الخدمة',
            child: TextFormField(controller: serviceName),
          ),
          FormFieldRow(
            label: 'معرّف المدير',
            child: TextFormField(
                controller: managerId, keyboardType: TextInputType.number),
          ),
        ],
      ),
    );
  }
}

class _GenerationSection extends StatelessWidget {
  const _GenerationSection({
    required this.prefix,
    required this.suffix,
    required this.ulen,
    required this.plen,
    required this.passwordType,
    required this.onPasswordType,
    required this.affixMode,
    required this.onAffixMode,
    required this.includeBatchNumber,
    required this.onIncludeBatchNumber,
  });

  final TextEditingController prefix;
  final TextEditingController suffix;
  final TextEditingController ulen;
  final TextEditingController plen;
  final String passwordType;
  final ValueChanged<String?> onPasswordType;
  final String affixMode;
  final ValueChanged<String?> onAffixMode;
  final bool includeBatchNumber;
  final ValueChanged<bool> onIncludeBatchNumber;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'batch.edit.generation',
      icon: Icons.dialpad_outlined,
      title: 'إعدادات التوليد المستقبلية',
      child: Column(
        children: [
          FormFieldRow(
            label: 'موضع الإضافة',
            child: DropdownButtonFormField<String>(
              value: affixMode.isEmpty ? 'none' : affixMode,
              items: const [
                DropdownMenuItem(value: 'none', child: Text('بدون')),
                DropdownMenuItem(value: 'prefix', child: Text('قبل الاسم')),
                DropdownMenuItem(value: 'suffix', child: Text('بعد الاسم')),
              ],
              onChanged: (v) => onAffixMode(v == 'none' ? '' : v),
            ),
          ),
          FormFieldRow(
              label: 'البادئة', child: TextFormField(controller: prefix)),
          FormFieldRow(
              label: 'اللاحقة', child: TextFormField(controller: suffix)),
          FormFieldRow(
            label: 'طول اسم الدخول',
            child: TextFormField(
                controller: ulen, keyboardType: TextInputType.number),
          ),
          FormFieldRow(
            label: 'طول كلمة المرور',
            child: TextFormField(
                controller: plen, keyboardType: TextInputType.number),
          ),
          FormFieldRow(
            label: 'نمط كلمة المرور',
            child: DropdownButtonFormField<String>(
              value: passwordType,
              items: const [
                DropdownMenuItem(value: 'digits', child: Text('أرقام فقط')),
                DropdownMenuItem(value: 'weak', child: Text('حروف')),
                DropdownMenuItem(value: 'medium', child: Text('متوسط')),
                DropdownMenuItem(value: 'strong', child: Text('قوي')),
              ],
              onChanged: onPasswordType,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: includeBatchNumber,
            onChanged: onIncludeBatchNumber,
            title: const Text('تضمين رقم الباقة'),
          ),
        ],
      ),
    );
  }
}

class _RuntimeSection extends StatelessWidget {
  const _RuntimeSection({
    required this.timeVal,
    required this.devices,
    required this.notes,
    required this.timeUnit,
    required this.onTimeUnit,
    required this.durationMode,
    required this.onDurationMode,
    required this.quotaAction,
    required this.onQuotaAction,
    required this.countFromFirstConnect,
    required this.onCountFromFirstConnect,
    required this.countBySeconds,
    required this.onCountBySeconds,
    required this.autoRenew,
    required this.onAutoRenew,
    required this.switchMac,
    required this.onSwitchMac,
    required this.lockMac,
    required this.onLockMac,
    required this.phoneOnly,
    required this.onPhoneOnly,
  });

  final TextEditingController timeVal;
  final TextEditingController devices;
  final TextEditingController notes;
  final String timeUnit;
  final ValueChanged<String?> onTimeUnit;
  final String durationMode;
  final ValueChanged<String?> onDurationMode;
  final String quotaAction;
  final ValueChanged<String?> onQuotaAction;
  final bool countFromFirstConnect;
  final ValueChanged<bool> onCountFromFirstConnect;
  final bool countBySeconds;
  final ValueChanged<bool> onCountBySeconds;
  final bool autoRenew;
  final ValueChanged<bool> onAutoRenew;
  final bool switchMac;
  final ValueChanged<bool> onSwitchMac;
  final bool lockMac;
  final ValueChanged<bool> onLockMac;
  final bool phoneOnly;
  final ValueChanged<bool> onPhoneOnly;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'batch.edit.runtime',
      icon: Icons.timer_outlined,
      title: 'الصلاحية والسلوك',
      child: Column(
        children: [
          FormFieldRow(
            label: 'قيمة الوقت',
            child: TextFormField(
                controller: timeVal, keyboardType: TextInputType.number),
          ),
          FormFieldRow(
            label: 'وحدة الوقت',
            child: DropdownButtonFormField<String>(
              value: timeUnit,
              items: const [
                DropdownMenuItem(value: 'minutes', child: Text('دقائق')),
                DropdownMenuItem(value: 'hours', child: Text('ساعات')),
                DropdownMenuItem(value: 'days', child: Text('أيام')),
              ],
              onChanged: onTimeUnit,
            ),
          ),
          FormFieldRow(
            label: 'عدد الأجهزة',
            child: TextFormField(
                controller: devices, keyboardType: TextInputType.number),
          ),
          FormFieldRow(
            label: 'وضع المدة',
            child: DropdownButtonFormField<String>(
              value: durationMode,
              items: const [
                DropdownMenuItem(value: 'time_unit', child: Text('حسب الوحدة')),
                DropdownMenuItem(value: 'seconds', child: Text('بالثواني')),
              ],
              onChanged: onDurationMode,
            ),
          ),
          FormFieldRow(
            label: 'عند انتهاء الحصة',
            child: DropdownButtonFormField<String>(
              value: quotaAction,
              items: const [
                DropdownMenuItem(value: 'stop', child: Text('إيقاف')),
                DropdownMenuItem(
                    value: 'reduce_speed', child: Text('تخفيض السرعة')),
                DropdownMenuItem(value: 'notify', child: Text('تنبيه فقط')),
              ],
              onChanged: onQuotaAction,
            ),
          ),
          _SwitchLine(
            label: 'العد من أول اتصال',
            value: countFromFirstConnect,
            onChanged: onCountFromFirstConnect,
          ),
          _SwitchLine(
              label: 'العد بالثواني',
              value: countBySeconds,
              onChanged: onCountBySeconds),
          _SwitchLine(
              label: 'تجديد تلقائي', value: autoRenew, onChanged: onAutoRenew),
          _SwitchLine(
              label: 'ربط MAC عند الاتصال',
              value: switchMac,
              onChanged: onSwitchMac),
          _SwitchLine(
              label: 'قفل MAC عند الإغلاق',
              value: lockMac,
              onChanged: onLockMac),
          _SwitchLine(
              label: 'دخول برقم الجوال فقط',
              value: phoneOnly,
              onChanged: onPhoneOnly),
          FormFieldRow(
              label: 'ملاحظات',
              child: TextFormField(controller: notes, maxLines: 3)),
        ],
      ),
    );
  }
}

class _SwitchLine extends StatelessWidget {
  const _SwitchLine({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(label),
    );
  }
}
