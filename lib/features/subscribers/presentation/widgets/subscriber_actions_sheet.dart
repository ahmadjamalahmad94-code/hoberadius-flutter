import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/hub_toast.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../data/subscriber_actions_repository.dart';
import '../../domain/subscriber_actions_model.dart';
import '../../domain/subscriber_model.dart';
import 'action_dialog_kit.dart';
import 'subscriber_action_dialogs.dart';

/// Every entry of the subscriber actions sheet (web row menus «تفعيل» and
/// «إدارية», plus the app's password reset and username rename).
enum SubscriberAction {
  extend,
  quota,
  payment,
  loan,
  quotaReset,
  edit,
  finance,
  message,
  credentials,
  changePlan,
  disconnect,
  toggle,
  archive,
  resetPassword,
  rename,

  /// The web profile's «إلغاء السرعة المؤقتة» (X beside the countdown).
  tempSpeedCancel,
}

class SubscriberActionSpec {
  const SubscriberActionSpec({
    required this.action,
    required this.icon,
    required this.label,
    required this.tone,
    this.permission,
    this.fallbackPermission,
    this.legacySupported = false,
  });

  final SubscriberAction action;
  final IconData icon;
  final String label;
  final PillTone tone;

  /// Key in actions-context `permissions`; `null` = always shown.
  final String? permission;

  /// Read instead of [permission] when an older server does not send it.
  final String? fallbackPermission;

  /// Runs on a server without the new endpoints (old API had it).
  final bool legacySupported;
}

/// «تفعيل» — same order as the web row menu.
const kActivationActions = <SubscriberActionSpec>[
  SubscriberActionSpec(
    action: SubscriberAction.extend,
    icon: Icons.more_time_outlined,
    label: 'تجديد / إضافة وقت',
    tone: PillTone.green,
    permission: 'extend',
    legacySupported: true,
  ),
  SubscriberActionSpec(
    action: SubscriberAction.quota,
    icon: Icons.data_usage_outlined,
    label: 'إضافة كوتة / جيجا',
    tone: PillTone.blue,
    permission: 'quota',
  ),
  SubscriberActionSpec(
    action: SubscriberAction.payment,
    icon: Icons.payments_outlined,
    label: 'تسجيل دفعة نقدية',
    tone: PillTone.green,
    permission: 'payment',
  ),
  SubscriberActionSpec(
    action: SubscriberAction.loan,
    icon: Icons.volunteer_activism_outlined,
    label: 'منح سلفة',
    tone: PillTone.amber,
    permission: 'loan',
  ),
  SubscriberActionSpec(
    action: SubscriberAction.quotaReset,
    icon: Icons.restart_alt,
    label: 'استعادة الكوتة اليومية',
    tone: PillTone.blue,
    // The web gates it on its own endpoint (users_quota_reset_daily).
    permission: 'quota_reset',
    fallbackPermission: 'quota',
  ),
];

/// «إدارية» — same order as the web row menu (+ password / rename).
const kAdminActions = <SubscriberActionSpec>[
  SubscriberActionSpec(
    action: SubscriberAction.edit,
    icon: Icons.edit_outlined,
    label: 'تعديل المشترك',
    tone: PillTone.brand,
    permission: 'edit',
    legacySupported: true,
  ),
  SubscriberActionSpec(
    action: SubscriberAction.finance,
    icon: Icons.account_balance_wallet_outlined,
    label: 'الدفعات والسلف',
    tone: PillTone.brand,
    legacySupported: true,
  ),
  SubscriberActionSpec(
    action: SubscriberAction.message,
    icon: Icons.send_outlined,
    label: 'إرسال رسالة',
    tone: PillTone.blue,
    permission: 'send_message',
  ),
  SubscriberActionSpec(
    action: SubscriberAction.credentials,
    icon: Icons.badge_outlined,
    label: 'إرسال بيانات المشترك',
    tone: PillTone.blue,
    // Its own grant on the web («إرسال بيانات الدخول», users_send_credentials)
    // — not «إرسال SMS» (comms.sms): a manager could hold one without the other.
    permission: 'send_credentials',
  ),
  SubscriberActionSpec(
    action: SubscriberAction.changePlan,
    icon: Icons.swap_horiz,
    label: 'تغيير العرض / السرعة',
    tone: PillTone.brand,
    permission: 'change_plan',
  ),
  SubscriberActionSpec(
    action: SubscriberAction.disconnect,
    icon: Icons.content_cut,
    label: 'فصل الاتصال',
    tone: PillTone.amber,
    permission: 'disconnect',
    legacySupported: true,
  ),
  SubscriberActionSpec(
    action: SubscriberAction.tempSpeedCancel,
    icon: Icons.speed_outlined,
    label: 'إلغاء السرعة المؤقتة',
    tone: PillTone.amber,
    permission: 'temp_speed_cancel',
  ),
  SubscriberActionSpec(
    action: SubscriberAction.toggle,
    icon: Icons.pause_circle_outline,
    label: 'تعطيل المشترك',
    tone: PillTone.amber,
    permission: 'status',
    legacySupported: true,
  ),
  SubscriberActionSpec(
    action: SubscriberAction.resetPassword,
    icon: Icons.password_outlined,
    label: 'إعادة كلمة المرور',
    tone: PillTone.blue,
    permission: 'reset_password',
    legacySupported: true,
  ),
  SubscriberActionSpec(
    action: SubscriberAction.rename,
    icon: Icons.drive_file_rename_outline,
    label: 'تغيير اسم المستخدم',
    tone: PillTone.brand,
    permission: 'rename',
  ),
  SubscriberActionSpec(
    action: SubscriberAction.archive,
    icon: Icons.archive_outlined,
    label: 'أرشفة المشترك',
    tone: PillTone.red,
    permission: 'delete',
    legacySupported: true,
  ),
];

/// Whether an action shows, and why it is greyed out (null = runnable).
class ActionAvailability {
  const ActionAvailability({required this.visible, this.disabledReason});
  final bool visible;
  final String? disabledReason;
  bool get enabled => visible && disabledReason == null;
}

ActionAvailability actionAvailability(
  SubscriberActionSpec spec,
  SubscriberActionsContext c,
) {
  final key = spec.permission;
  final fallback = spec.fallbackPermission;
  if (key != null &&
      !(fallback == null
          ? c.permissions.allows(key)
          : c.permissions.allowsOr(key, fallback))) {
    return const ActionAvailability(visible: false);
  }
  if (spec.action == SubscriberAction.tempSpeedCancel && c.tempSpeed == null) {
    // Like the web profile: the cancel X exists only beside a temp speed.
    return const ActionAvailability(visible: false);
  }
  if (c.legacy && !spec.legacySupported) {
    return const ActionAvailability(
      visible: true,
      disabledReason: 'يتطلّب تحديث الخادم',
    );
  }
  if (spec.action == SubscriberAction.quotaReset &&
      c.dailyResetAvailable == false) {
    // Nothing to reset (no daily quota / time cap): the server refuses it.
    return const ActionAvailability(visible: false);
  }
  switch (spec.action) {
    case SubscriberAction.quota:
    case SubscriberAction.quotaReset:
      if (!c.hasQuota) {
        return const ActionAvailability(
          visible: true,
          disabledReason: 'لا توجد كوتة لهذا المشترك',
        );
      }
    case SubscriberAction.disconnect:
      // Old servers do not report live sessions — let the server decide.
      if (!c.legacy && c.onlineSessions == 0) {
        return const ActionAvailability(
          visible: true,
          disabledReason: 'غير متصل الآن',
        );
      }
    case SubscriberAction.message:
    case SubscriberAction.credentials:
      if (!c.legacy && !c.smsEnabled && !c.whatsappEnabled) {
        return const ActionAvailability(
          visible: true,
          disabledReason: 'لا توجد قناة إرسال مفعّلة',
        );
      }
      if (spec.action == SubscriberAction.credentials && !c.smsEnabled) {
        return const ActionAvailability(
          visible: true,
          disabledReason: 'يتطلّب قناة SMS مفعّلة',
        );
      }
    default:
      break;
  }
  return const ActionAvailability(visible: true);
}

/// Label/icon of the toggle entry follow the subscriber's status.
SubscriberActionSpec _resolve(
  SubscriberActionSpec s,
  SubscriberActionsContext c,
) {
  if (s.action != SubscriberAction.toggle || !c.isDisabled) return s;
  return SubscriberActionSpec(
    action: s.action,
    icon: Icons.play_circle_outline,
    label: 'تفعيل المشترك',
    tone: PillTone.green,
    permission: s.permission,
    legacySupported: s.legacySupported,
  );
}

/// Loads GET actions-context; a server without it (404) or any failure falls
/// back to what the list row knows ([SubscriberActionsContext.legacy]).
class ActionsContextResult {
  const ActionsContextResult(this.context, {this.problem});
  final SubscriberActionsContext context;

  /// Why the full context could not load (shown as a note); null = fine.
  final String? problem;
}

Future<ActionsContextResult> loadActionsContext(
  SubscriberActionsRepository repo,
  Subscriber s, {
  String planName = '',
  double planPrice = 0,
}) async {
  try {
    return ActionsContextResult(await repo.actionsContext(s.username));
  } catch (e) {
    final err = mapActionError(e);
    final legacy = SubscriberActionsContext.legacy(
      s,
      planName: planName,
      planPrice: planPrice,
    );
    return ActionsContextResult(
      legacy,
      problem: err.notUpdated
          ? 'هذا الخادم لم يُحدَّث بعد — تعمل الإجراءات التي تدعمها نسخته، '
              'والباقي معطّل حتى التحديث.'
          : 'تعذّر جلب بيانات الإجراءات (${err.message}) — تعمل الإجراءات '
              'الأساسية فقط.',
    );
  }
}

/// Opens the actions sheet for [subscriber] (list «إجراءات»/⋮, 360, edit),
/// then the chosen action's dialog; shows a toast and calls [onChanged]
/// after a successful change.
Future<void> showSubscriberActionsSheet(
  BuildContext context,
  WidgetRef ref, {
  required Subscriber subscriber,
  String planName = '',
  double planPrice = 0,
  VoidCallback? onChanged,
  ValueChanged<String>? onRenamed,
  VoidCallback? onArchived,
}) async {
  final picked =
      await showModalBottomSheet<(SubscriberAction, SubscriberActionsContext)>(
    // Above the whole app: the shell's pages live inside one scroll view, so
    // a sheet on the inner navigator was drawn off-screen.
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    context: context,
    builder: (_) => SubscriberActionsSheet(
      subscriber: subscriber,
      planName: planName,
      planPrice: planPrice,
    ),
  );
  if (picked == null || !context.mounted) return;
  await runSubscriberAction(
    context,
    picked.$1,
    picked.$2,
    onChanged: onChanged,
    onRenamed: onRenamed,
    onArchived: onArchived,
  );
}

/// Opens the dialog of [action] and reports the outcome.
Future<void> runSubscriberAction(
  BuildContext context,
  SubscriberAction action,
  SubscriberActionsContext c, {
  VoidCallback? onChanged,
  ValueChanged<String>? onRenamed,
  VoidCallback? onArchived,
}) async {
  final u = c.username;
  final Widget dialog;
  switch (action) {
    case SubscriberAction.edit:
      context.goNamed('subscriber-edit', pathParameters: {'username': u});
      return;
    case SubscriberAction.finance:
      context.goNamed('subscriber-finance', pathParameters: {'username': u});
      return;
    case SubscriberAction.extend:
      dialog = ExtendDialog(c: c);
    case SubscriberAction.quota:
      dialog = QuotaTopupDialog(c: c);
    case SubscriberAction.quotaReset:
      dialog = QuotaResetDialog(c: c);
    case SubscriberAction.payment:
      dialog = PaymentDialog(c: c);
    case SubscriberAction.loan:
      dialog = LoanDialog(c: c);
    case SubscriberAction.changePlan:
      dialog = ChangePlanDialog(c: c);
    case SubscriberAction.message:
      dialog = MessageDialog(c: c);
    case SubscriberAction.rename:
      dialog = RenameDialog(c: c);
    case SubscriberAction.resetPassword:
      dialog = ResetPasswordDialog(c: c);
    case SubscriberAction.credentials:
      dialog = credentialsConfirm(c);
    case SubscriberAction.disconnect:
      dialog = disconnectConfirm(c);
    case SubscriberAction.toggle:
      dialog = toggleConfirm(c);
    case SubscriberAction.archive:
      dialog = archiveConfirm(c);
    case SubscriberAction.tempSpeedCancel:
      dialog = tempSpeedCancelConfirm(c);
  }
  final outcome = await showActionDialog(context, dialog);
  if (outcome == null || !context.mounted) return;
  if (outcome.info) {
    HubToaster.info(context, outcome.message);
  } else {
    HubToaster.success(context, outcome.message);
  }
  if (action == SubscriberAction.archive && onArchived != null) {
    onArchived();
  } else if (outcome.renamedTo != null && onRenamed != null) {
    onRenamed(outcome.renamedTo!);
  } else {
    onChanged?.call();
  }
}

ConfirmActionDialog credentialsConfirm(SubscriberActionsContext c) =>
    ConfirmActionDialog(
      icon: Icons.badge_outlined,
      tone: PillTone.blue,
      title: 'إرسال بيانات المشترك',
      subtitle: c.username,
      message: 'إرسال اسم المستخدم وكلمة المرور إلى «${c.username}» عبر SMS؟',
      confirmLabel: 'إرسال',
      task: (repo) async {
        final res = await repo.sendCredentials(c.username);
        final msg = (res['message'] ?? '').toString();
        return msg.isNotEmpty ? msg : 'أُرسلت بيانات الدخول إلى ${c.username}';
      },
    );

ConfirmActionDialog disconnectConfirm(SubscriberActionsContext c) =>
    ConfirmActionDialog(
      icon: Icons.content_cut,
      tone: PillTone.amber,
      title: 'فصل الاتصال',
      subtitle: c.username,
      message: c.onlineSessions > 0
          ? 'فصل «${c.username}» الآن؟ (جلسات متصلة: ${c.onlineSessions})'
          : 'فصل «${c.username}» الآن؟',
      note: 'يُقطع الاتصال الحالي فقط؛ يستطيع إعادة الاتصال ما دام اشتراكه '
          'فعّالًا.',
      confirmLabel: 'فصل',
      task: (repo) async {
        if (c.legacy) {
          await repo.disconnectLegacy(c.username);
          return 'تم فصل ${c.username}';
        }
        final res = await repo.disconnect(c.username);
        final n = res['disconnected'];
        return n is num && n > 0
            ? 'تم فصل ${c.username} ($n)'
            : 'أُرسل أمر الفصل لـ ${c.username}';
      },
    );

ConfirmActionDialog toggleConfirm(SubscriberActionsContext c) {
  final enable = c.isDisabled;
  return ConfirmActionDialog(
    icon: enable ? Icons.play_circle_outline : Icons.pause_circle_outline,
    tone: enable ? PillTone.green : PillTone.amber,
    title: enable ? 'تفعيل المشترك' : 'تعطيل المشترك',
    subtitle: c.username,
    message: enable
        ? 'تفعيل «${c.username}»؟ يستطيع الاتصال فورًا.'
        : 'تعطيل «${c.username}»؟ لن يتمكّن من الاتصال حتى يُفعَّل.',
    confirmLabel: enable ? 'تفعيل' : 'تعطيل',
    task: (repo) async {
      if (enable) {
        await repo.enable(c.username);
        return 'تم تفعيل ${c.username}';
      }
      await repo.disable(c.username);
      return 'تم تعطيل ${c.username}';
    },
  );
}

ConfirmActionDialog tempSpeedCancelConfirm(SubscriberActionsContext c) {
  final ts = c.tempSpeed;
  final when = ts == null
      ? ''
      : ts.unknown
          ? ' — مفتوحة (بدون وقت نهاية)'
          : ts.expired
              ? ' — انتهت مدّتها'
              : '';
  return ConfirmActionDialog(
    icon: Icons.speed_outlined,
    tone: PillTone.amber,
    title: 'إلغاء السرعة المؤقتة',
    subtitle: c.username,
    message: ts == null
        ? 'إلغاء السرعة المؤقتة لـ «${c.username}»؟'
        : 'إلغاء السرعة المؤقتة (${ts.rateLabel})$when لـ «${c.username}»؟',
    note: 'تُعاد السرعة الطبيعية فورًا للجلسة المتصلة.',
    confirmLabel: 'إلغاء السرعة',
    task: (repo) async {
      final res = await repo.cancelTempSpeed(c.username);
      final msg = (res['message'] ?? '').toString();
      return msg.isNotEmpty
          ? msg
          : 'تم إلغاء السرعة المؤقتة لـ «${c.username}».';
    },
  );
}

ConfirmActionDialog archiveConfirm(SubscriberActionsContext c) =>
    ConfirmActionDialog(
      icon: Icons.archive_outlined,
      tone: PillTone.red,
      danger: true,
      title: 'أرشفة المشترك',
      subtitle: c.username,
      message: 'أرشفة «${c.username}»؟ يمكن استعادته من سلة المحذوفات.',
      confirmLabel: 'أرشفة',
      task: (repo) async {
        await repo.archive(c.username);
        return 'أُرشف ${c.username} — يمكن استعادته من سلة المحذوفات';
      },
    );

/// The sheet body: header, context loading, two titled groups.
class SubscriberActionsSheet extends ConsumerStatefulWidget {
  const SubscriberActionsSheet({
    super.key,
    required this.subscriber,
    this.planName = '',
    this.planPrice = 0,
    this.preloaded,
  });

  final Subscriber subscriber;
  final String planName;
  final double planPrice;

  /// Skip the network (tests / previews).
  final ActionsContextResult? preloaded;

  @override
  ConsumerState<SubscriberActionsSheet> createState() =>
      _SubscriberActionsSheetState();
}

class _SubscriberActionsSheetState
    extends ConsumerState<SubscriberActionsSheet> {
  ActionsContextResult? _result;

  @override
  void initState() {
    super.initState();
    _result = widget.preloaded;
    if (_result == null) _load();
  }

  Future<void> _load() async {
    setState(() => _result = null);
    final r = await loadActionsContext(
      ref.read(subscriberActionsRepositoryProvider),
      widget.subscriber,
      planName: widget.planName,
      planPrice: widget.planPrice,
    );
    if (mounted) setState(() => _result = r);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.subscriber;
    final text = Theme.of(context).textTheme;
    final r = _result;
    final c = r?.context;
    final maxH = MediaQuery.sizeOf(context).height * 0.86;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.fullName.isEmpty ? s.username : s.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTokens.sidebarBg,
                          ),
                        ),
                        if (s.fullName.isNotEmpty)
                          Text(
                            s.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall
                                ?.copyWith(color: AppTokens.textMuted),
                          ),
                      ],
                    ),
                  ),
                  if (c != null && c.onlineSessions > 0)
                    const Padding(
                      padding: EdgeInsetsDirectional.only(start: 6),
                      child: StatusPill(
                        text: 'متصل',
                        tone: PillTone.green,
                        dot: true,
                      ),
                    ),
                  if (c != null && c.debt > 0)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 6),
                      child: StatusPill(
                        text: 'دين ${formatMoney(c.debt, c.currency)}',
                        tone: PillTone.amber,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTokens.border),
            if (r == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  children: [
                    if (r.problem != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ActionNote(
                          text: r.problem!,
                          tone: PillTone.amber,
                        ),
                      ),
                    ..._group(
                      'تفعيل',
                      Icons.bolt,
                      kActivationActions,
                      r.context,
                    ),
                    const SizedBox(height: 6),
                    ..._group(
                      'إدارية',
                      Icons.tune,
                      kAdminActions,
                      r.context,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _group(
    String title,
    IconData icon,
    List<SubscriberActionSpec> specs,
    SubscriberActionsContext c,
  ) {
    final rows = <Widget>[];
    for (final raw in specs) {
      final spec = _resolve(raw, c);
      final a = actionAvailability(spec, c);
      if (!a.visible) continue;
      rows.add(
        SheetActionRow(
          key: ValueKey('action:${spec.action.name}'),
          icon: spec.icon,
          label: spec.label,
          tone: spec.tone,
          disabledReason: a.disabledReason,
          onTap:
              a.enabled ? () => Navigator.pop(context, (spec.action, c)) : null,
        ),
      );
    }
    if (rows.isEmpty) return const [];
    return [_GroupTitle(title: title, icon: icon), ...rows];
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTokens.brandInk),
          const SizedBox(width: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTokens.brandInk,
                ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(height: 1, color: AppTokens.brandLine)),
        ],
      ),
    );
  }
}

/// One row of the actions sheet: tinted icon chip in the action's colour +
/// label; a greyed row carries its reason under the label.
class SheetActionRow extends StatelessWidget {
  const SheetActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
    this.disabledReason,
  });

  final IconData icon;
  final String label;
  final PillTone tone;
  final VoidCallback? onTap;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final danger = tone == PillTone.red;
    final text = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            ActionIconChip(icon: icon, tone: tone, enabled: enabled, size: 34),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: !enabled
                          ? AppTokens.textMuted
                          : (danger ? AppTokens.red : AppTokens.textPrimary),
                    ),
                  ),
                  if (disabledReason != null)
                    Text(
                      disabledReason!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        color: AppTokens.amberInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            if (enabled)
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppTokens.textFaint,
              ),
          ],
        ),
      ),
    );
  }
}
