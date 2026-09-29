import 'package:hoberadius_app/core/format/panel_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/subscriber_form_controller.dart';
import '../application/subscriber_form_mapper.dart';
import '../domain/subscriber_model.dart';
import '../domain/subscriber_actions_model.dart';
import 'widgets/subscriber_action_menu.dart';
import 'widgets/subscriber_actions_sheet.dart';
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

  /// The row exactly as loaded into the form: the save sends only what the
  /// operator changed relative to it (never the whole stale row).
  Subscriber? _original;

  static const _controllerKeys = kSubscriberFormControllerKeys;

  @override
  void initState() {
    super.initState();
    _c = {for (final k in _controllerKeys) k: TextEditingController()};
    // Defer so the controller's first `state =` runs AFTER initState
    // (modifying a provider during the build/initState phase is disallowed).
    // A fresh form starts clean: the action provider is app-wide and kept
    // the previous form's error (r10 N6).
    Future.microtask(() {
      if (!mounted) return;
      ref.read(subscriberFormActionProvider.notifier).clearError();
      if (widget.isEdit) _loadExisting();
    });
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
    _ownsError = true;
    final result = await ref
        .read(subscriberFormActionProvider.notifier)
        .load(widget.username!);
    if (!mounted || result.subscriber == null) return;
    _original = result.subscriber;
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

  /// A typed-value problem found before any request (collapsed sections
  /// included), shown in the error box.
  String? _localError;

  /// This form instance started a load/save — only then is the shared
  /// provider's error ours to show.
  bool _ownsError = false;

  Future<void> _rename() async {
    final u = widget.username;
    if (u == null) return;
    await runSubscriberAction(
      context,
      SubscriberAction.rename,
      SubscriberActionsContext(username: u),
      onRenamed: (name) => context.goNamed(
        'subscriber-edit',
        pathParameters: {'username': name},
      ),
    );
  }

  Future<void> _submit() async {
    final numberError = subscriberFormNumberError(_c);
    final expiryError = validateExpiryJump(
      original: _original?.expireAt,
      next: _expireAt,
      now: panelNow(),
    );
    setState(() => _localError = numberError ?? expiryError);
    if (!_formKey.currentState!.validate() || _localError != null) return;
    _ownsError = true;
    final subscriber = buildSubscriberFromForm(_c, _selections);
    final notifier = ref.read(subscriberFormActionProvider.notifier);
    final String? err;
    if (widget.isEdit) {
      final original = _original;
      if (original == null) return; // still loading — nothing to compare to
      err = await notifier.submitChanges(
        widget.username!,
        subscriber.copyWith(username: original.username).toPatchDiff(original),
      );
    } else {
      err = await notifier.submit(subscriber, isEdit: false);
    }
    if (!mounted || err != null) return;
    context.goNamed('subscribers');
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(subscriberFormActionProvider);
    final loading = action.loading;
    final error = _localError ?? (_ownsError ? action.error : null);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: widget.isEdit ? 'تعديل مشترك' : 'مشترك جديد',
            leading: IconButton(
              onPressed: () => context.goNamed('subscribers'),
              tooltip: 'رجوع',
              icon: const Icon(Icons.arrow_back),
            ),
            // Title + «حفظ» (and the ⋮ menu on edit) share ONE row — the save
            // button used to float alone on a row of its own.
            inlineActions: true,
            actions: [
              FilledButton.icon(
                onPressed: loading ? null : _submit,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('حفظ'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTokens.brand,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.s12),
                  ),
                  textStyle: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (widget.isEdit)
                SubscriberActionMenu(
                  enabled: !loading,
                  subscriber: () => buildSubscriberFromForm(_c, _selections)
                      .copyWith(username: widget.username),
                  onChanged: _loadExisting,
                  onRenamed: (name) => context.goNamed(
                    'subscriber-edit',
                    pathParameters: {'username': name},
                  ),
                  onArchived: () => context.goNamed('subscribers'),
                ),
            ],
          ),
          if (widget.isEdit) ...[
            const SizedBox(height: AppTokens.s12),
            ActionBar(
              maxPerRow: 2,
              items: [
                ActionItem(
                  icon: Icons.dashboard_customize_outlined,
                  label: 'ملف 360',
                  onPressed: () => context.goNamed(
                    'subscriber-360',
                    pathParameters: {'username': _c['username']!.text.trim()},
                  ),
                ),
                ActionItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'الدفعات والسلف',
                  onPressed: () => context.goNamed(
                    'subscriber-finance',
                    pathParameters: {'username': _c['username']!.text.trim()},
                  ),
                ),
              ],
            ),
          ],
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
          const SizedBox(height: AppTokens.s12),
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
            onRename: widget.isEdit ? _rename : null,
          ),
          const SizedBox(height: AppTokens.s12),
          SubscriberManagementSection(
            controllers: _c,
            isEdit: widget.isEdit,
            managerId: _managerId,
            onManagerChanged: (v) => setState(() => _managerId = v),
          ),
          const SizedBox(height: AppTokens.s12),
          SubscriberPersonalSection(
            controllers: _c,
            accountType: _accountType,
            onAccountTypeChanged: (v) => setState(() => _accountType = v),
          ),
          const SizedBox(height: AppTokens.s12),
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
          const SizedBox(height: AppTokens.s12),
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
          const SizedBox(height: AppTokens.s12),
          SubscriberPppoeSection(controllers: _c),
          const SizedBox(height: AppTokens.s12),
          SubscriberMtSection(
            controllers: _c,
            mtService: _mtService,
            onMtServiceChanged: (v) => setState(() => _mtService = v),
          ),
          const SizedBox(height: AppTokens.s12),
          SubscriberRadiusSection(controllers: _c),
          const SizedBox(height: AppTokens.s12),
          SubscriberLockSection(controllers: _c),
          const SizedBox(height: AppTokens.s12),
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
          const SizedBox(height: AppTokens.s12),
          SubscriberNotificationsSection(
            controllers: _c,
            notifyOnLogin: _notifyOnLogin,
            onNotifyOnLoginChanged: (v) => setState(() => _notifyOnLogin = v),
          ),
          const SizedBox(height: AppTokens.s12),
          SubscriberSubscriptionSection(
            controllers: _c,
            subscriptionType: _subscriptionType,
            onSubscriptionTypeChanged: (v) =>
                setState(() => _subscriptionType = v),
            autoRenew: _autoRenew,
            onAutoRenewChanged: (v) => setState(() => _autoRenew = v),
          ),
          const SizedBox(height: AppTokens.s12),
          SubscriberGeneralSection(controllers: _c),
          const SizedBox(height: AppTokens.s40),
        ],
      ),
    );
  }
}
