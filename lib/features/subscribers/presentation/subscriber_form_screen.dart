import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/subscriber_form_controller.dart';
import '../application/subscriber_form_mapper.dart';
import 'widgets/subscriber_action_menu.dart';
import 'widgets/subscriber_dialogs.dart';
import 'widgets/subscriber_form_sections.dart';

/// Subscriber create / edit form. UI-local state (text controllers and
/// the simple form selections) lives here; async actions and their
/// loading/error flags are delegated to [subscriberFormActionProvider].
class SubscriberFormScreen extends ConsumerStatefulWidget {
  const SubscriberFormScreen({super.key, this.username});
  final String? username;
  bool get isEdit => username != null;

  @override
  ConsumerState<SubscriberFormScreen> createState() =>
      _SubscriberFormScreenState();
}

class _SubscriberFormScreenState extends ConsumerState<SubscriberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  String _status = 'enabled';
  String _userType = 'subscriber';
  String _serviceType = 'Hotspot';
  String _accountType = 'Personal';
  int? _managerId;
  String _mtService = 'pppoe';
  String _subscriptionType = 'fixed';
  DateTime? _expireAt;
  final Set<String> _workingDays = {};
  bool _disableOnFirstUse = false;
  bool _notifyOnLogin = false;
  bool _autoRenew = false;
  bool _bandwidthControlEnabled = false;
  bool _customSpeed = false;
  bool _temporarySpeed = false;
  bool _quotaLimitEnabled = false;
  bool _connectionTimeLimitEnabled = false;
  bool _equalShareDownload = false;
  bool _equalShareUpload = false;

  static const _controllerKeys = [
    'username',
    'password',
    'full_name',
    'mobile',
    'email',
    'beneficiary_ref',
    'remark',
    'mac_lock',
    'static_ip',
    'plan_id',
    'custom_price',
    'balance',
    'group',
    'pool',
    'father_name',
    'national_id',
    'nationality',
    'country',
    'address',
    'city',
    'district',
    'state',
    'zip',
    'coordinates',
    'payment_method',
    'payment_reference',
    'download_speed_kbps',
    'upload_speed_kbps',
    'combined_quota_mb',
    'download_quota_mb',
    'upload_quota_mb',
    'total_connection_time_min',
    'daily_connection_time_min',
    'vlan_id',
    'device_count',
    'allowed_macs',
    'device_connection_file',
    'pppoe_username',
    'pppoe_password',
    'pppoe_ip',
    'mt_profile',
    'mt_rate_limit',
    'mt_ip_pool',
    'mt_comment',
    'dns1',
    'dns2',
    'simultaneous_use',
    'session_timeout',
    'idle_timeout',
    'called_station_id',
    'allowed_hours',
    'notify_email',
    'notify_mobile',
    'subscription_days',
    'notes',
    'tags',
  ];

  @override
  void initState() {
    super.initState();
    _c = {for (final k in _controllerKeys) k: TextEditingController()};
    // Defer the load so the controller's first `state =` runs AFTER initState
    // (modifying a provider during the build/initState phase is disallowed).
    if (widget.isEdit) Future.microtask(_loadExisting);
  }

  @override
  void dispose() {
    for (final ctrl in _c.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  String get _allowedFrom {
    final parts = _c['allowed_hours']!.text.split('-');
    return parts.isNotEmpty && parts.first.trim().isNotEmpty
        ? parts.first.trim()
        : '08:00';
  }

  String get _allowedTo {
    final parts = _c['allowed_hours']!.text.split('-');
    return parts.length > 1 && parts[1].trim().isNotEmpty
        ? parts[1].trim()
        : '22:00';
  }

  SubscriberFormSelections get _selections => SubscriberFormSelections(
        status: _status,
        userType: _userType,
        serviceType: _serviceType,
        accountType: _accountType,
        managerId: _managerId,
        mtService: _mtService,
        subscriptionType: _subscriptionType,
        expireAt: _expireAt,
        workingDays: _workingDays,
        disableOnFirstUse: _disableOnFirstUse,
        notifyOnLogin: _notifyOnLogin,
        autoRenew: _autoRenew,
        bandwidthControlEnabled: _bandwidthControlEnabled,
        customSpeed: _customSpeed,
        temporarySpeed: _temporarySpeed,
        quotaLimitEnabled: _quotaLimitEnabled,
        connectionTimeLimitEnabled: _connectionTimeLimitEnabled,
        equalShareDownload: _equalShareDownload,
        equalShareUpload: _equalShareUpload,
      );

  Future<void> _loadExisting() async {
    final result = await ref
        .read(subscriberFormActionProvider.notifier)
        .load(widget.username!);
    if (!mounted || result.subscriber == null) return;
    applySubscriberToForm(result.subscriber!, _c);
    final sel = selectionsFromSubscriber(result.subscriber!);
    setState(() {
      _status = sel.status;
      _userType = sel.userType;
      _serviceType = sel.serviceType;
      _accountType = sel.accountType;
      _managerId = sel.managerId;
      _mtService = sel.mtService;
      _subscriptionType = sel.subscriptionType;
      _expireAt = sel.expireAt;
      _workingDays
        ..clear()
        ..addAll(sel.workingDays);
      _disableOnFirstUse = sel.disableOnFirstUse;
      _notifyOnLogin = sel.notifyOnLogin;
      _autoRenew = sel.autoRenew;
      _bandwidthControlEnabled = sel.bandwidthControlEnabled;
      _customSpeed = sel.customSpeed;
      _temporarySpeed = sel.temporarySpeed;
      _quotaLimitEnabled = sel.quotaLimitEnabled;
      _connectionTimeLimitEnabled = sel.connectionTimeLimitEnabled;
      _equalShareDownload = sel.equalShareDownload;
      _equalShareUpload = sel.equalShareUpload;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final subscriber = buildSubscriberFromForm(_c, _selections);
    final err = await ref
        .read(subscriberFormActionProvider.notifier)
        .submit(subscriber, isEdit: widget.isEdit);
    if (!mounted || err != null) return;
    context.goNamed('subscribers');
  }

  Future<void> _toggleStatus() async {
    final u = widget.username;
    if (u == null) return;
    final enable = _status == 'disabled';
    final err = await ref
        .read(subscriberFormActionProvider.notifier)
        .toggle(u, enable: enable);
    if (!mounted || err != null) return;
    setState(() => _status = enable ? 'enabled' : 'disabled');
    _snack(enable ? 'تم التفعيل' : 'تم التعطيل');
  }

  Future<void> _showExtendDialog() async {
    final mins = await askExtendMinutes(context);
    if (!mounted || mins == null) return;
    final result = await ref
        .read(subscriberFormActionProvider.notifier)
        .extendTime(widget.username!, mins);
    if (!mounted || result.newExpire == null) return;
    setState(() => _expireAt = result.newExpire);
    _snack('تم التمديد $mins دقيقة');
  }

  Future<void> _showResetPwDialog() async {
    final pw = await askNewPassword(context);
    if (!mounted || pw == null) return;
    final err = await ref
        .read(subscriberFormActionProvider.notifier)
        .resetPassword(widget.username!, pw);
    if (!mounted || err != null) return;
    _snack('تمّ تحديث كلمة المرور');
  }

  Future<void> _showDeleteConfirm() async {
    final ok = await confirmDeleteSubscriber(context, widget.username!);
    if (!mounted || !ok) return;
    final err = await ref
        .read(subscriberFormActionProvider.notifier)
        .delete(widget.username!);
    if (!mounted || err != null) return;
    context.goNamed('subscribers');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(subscriberFormActionProvider);
    final loading = action.loading;
    final error = action.error;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: widget.isEdit ? 'تعديل مشترك' : 'مشترك جديد',
            leading: IconButton(
              onPressed: () => context.goNamed('subscribers'),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              if (widget.isEdit)
                SubscriberActionMenu(
                  isDisabled: _status == 'disabled',
                  onToggle: loading ? null : _toggleStatus,
                  onExtend: loading ? null : _showExtendDialog,
                  onResetPw: loading ? null : _showResetPwDialog,
                  onDelete: loading ? null : _showDeleteConfirm,
                ),
              if (widget.isEdit)
                OutlinedButton.icon(
                  onPressed: () => context.goNamed(
                    'subscriber-360',
                    pathParameters: {'username': _c['username']!.text.trim()},
                  ),
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  label: const Text('ملف 360'),
                ),
              if (widget.isEdit)
                OutlinedButton.icon(
                  onPressed: () => context.goNamed(
                    'subscriber-finance',
                    pathParameters: {'username': _c['username']!.text.trim()},
                  ),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('الدفعات والسلف'),
                ),
              ElevatedButton.icon(
                onPressed: loading ? null : _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ'),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: AppTokens.s12),
            Container(
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: AppTokens.dangerBg,
                borderRadius: BorderRadius.circular(AppTokens.r10),
              ),
              child: Text(error, style: const TextStyle(color: AppTokens.red)),
            ),
          ],
          const SizedBox(height: AppTokens.s16),
          SubscriberCoreSection(
            controllers: _c,
            isEdit: widget.isEdit,
            status: _status,
            userType: _userType,
            serviceType: _serviceType,
            expireAt: _expireAt,
            onStatusChanged: (v) => setState(() => _status = v),
            onUserTypeChanged: (v) => setState(() => _userType = v),
            onServiceTypeChanged: (v) => setState(() => _serviceType = v),
            onExpireChanged: (d) => setState(() => _expireAt = d),
          ),
          const SizedBox(height: AppTokens.s16),
          SubscriberManagementSection(
            controllers: _c,
            managerId: _managerId,
            onManagerChanged: (v) => setState(() => _managerId = v),
          ),
          const SizedBox(height: AppTokens.s16),
          SubscriberPersonalSection(
            controllers: _c,
            accountType: _accountType,
            onAccountTypeChanged: (v) => setState(() => _accountType = v),
          ),
          const SizedBox(height: AppTokens.s16),
          SubscriberSpeedSection(
            controllers: _c,
            bandwidthControlEnabled: _bandwidthControlEnabled,
            onBandwidthControlChanged: (v) =>
                setState(() => _bandwidthControlEnabled = v),
            customSpeed: _customSpeed,
            onCustomSpeedChanged: (v) => setState(() => _customSpeed = v),
            temporarySpeed: _temporarySpeed,
            onTemporarySpeedChanged: (v) => setState(() => _temporarySpeed = v),
          ),
          const SizedBox(height: AppTokens.s16),
          SubscriberQuotaSection(
            controllers: _c,
            quotaLimitEnabled: _quotaLimitEnabled,
            onQuotaLimitChanged: (v) => setState(() => _quotaLimitEnabled = v),
            connectionTimeLimitEnabled: _connectionTimeLimitEnabled,
            onConnectionTimeLimitChanged: (v) =>
                setState(() => _connectionTimeLimitEnabled = v),
            equalShareDownload: _equalShareDownload,
            onEqualShareDownloadChanged: (v) =>
                setState(() => _equalShareDownload = v),
            equalShareUpload: _equalShareUpload,
            onEqualShareUploadChanged: (v) =>
                setState(() => _equalShareUpload = v),
          ),
          const SizedBox(height: AppTokens.s16),
          SubscriberPppoeSection(controllers: _c),
          const SizedBox(height: AppTokens.s16),
          SubscriberMtSection(
            controllers: _c,
            mtService: _mtService,
            onMtServiceChanged: (v) => setState(() => _mtService = v),
          ),
          const SizedBox(height: AppTokens.s16),
          SubscriberRadiusSection(controllers: _c),
          const SizedBox(height: AppTokens.s16),
          SubscriberLockSection(controllers: _c),
          const SizedBox(height: AppTokens.s16),
          SubscriberAdvancedSection(
            allowedFrom: _allowedFrom,
            allowedTo: _allowedTo,
            onAllowedHoursChanged: (from, to) =>
                setState(() => _c['allowed_hours']!.text = '$from-$to'),
            workingDays: _workingDays,
            onWorkingDaysChanged: (days) => setState(() {
              _workingDays
                ..clear()
                ..addAll(days);
            }),
            disableOnFirstUse: _disableOnFirstUse,
            onDisableOnFirstUseChanged: (v) =>
                setState(() => _disableOnFirstUse = v),
          ),
          const SizedBox(height: AppTokens.s16),
          SubscriberNotificationsSection(
            controllers: _c,
            notifyOnLogin: _notifyOnLogin,
            onNotifyOnLoginChanged: (v) => setState(() => _notifyOnLogin = v),
          ),
          const SizedBox(height: AppTokens.s16),
          SubscriberSubscriptionSection(
            controllers: _c,
            subscriptionType: _subscriptionType,
            onSubscriptionTypeChanged: (v) =>
                setState(() => _subscriptionType = v),
            autoRenew: _autoRenew,
            onAutoRenewChanged: (v) => setState(() => _autoRenew = v),
          ),
          const SizedBox(height: AppTokens.s16),
          SubscriberGeneralSection(controllers: _c),
          const SizedBox(height: AppTokens.s40),
        ],
      ),
    );
  }
}
