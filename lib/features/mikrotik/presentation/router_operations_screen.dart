import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../nas/domain/nas_model.dart';
import '../application/mikrotik_providers.dart';
import '../data/mikrotik_repository.dart';
import '../domain/mikrotik_model.dart';

class RouterOperationsScreen extends ConsumerStatefulWidget {
  const RouterOperationsScreen({super.key});

  @override
  ConsumerState<RouterOperationsScreen> createState() =>
      _RouterOperationsScreenState();
}

class _RouterOperationsScreenState
    extends ConsumerState<RouterOperationsScreen> {
  int? _selectedRouterId;

  @override
  Widget build(BuildContext context) {
    final routersAsync = ref.watch(mikrotikRoutersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'عمليات الراوتر',
          subtitle:
              'متابعة حالة الراوتر الحية من عقد ميكروتك الموجود في الريدياس، مع إبقاء أوامر التغيير وإعادة التشغيل ضمن إجراءات محمية ومراجعة.',
          actions: [
            IconButton(
              tooltip: 'تحديث الراوترات',
              onPressed: () => ref.invalidate(mikrotikRoutersProvider),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        routersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => HubErrorState(
            title: 'تعذر جلب الراوترات',
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(mikrotikRoutersProvider),
          ),
          data: _body,
        ),
      ],
    );
  }

  Widget _body(List<NasDevice> routers) {
    final available = routers.where((router) => router.id != null).toList();
    if (available.isEmpty) {
      return const EmptyState(
        icon: Icons.router_outlined,
        title: 'لا توجد راوترات مسجلة',
        subtitle:
            'أضف جهاز شبكة من صفحة أجهزة الشبكة ثم ارجع إلى هنا لمتابعة الحالة الحية.',
      );
    }

    final selectedId = _selectedRouterId ?? available.first.id!;
    if (_selectedRouterId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedRouterId = selectedId);
      });
    }
    final selected = available.firstWhere(
      (router) => router.id == selectedId,
      orElse: () => available.first,
    );
    final overviewAsync =
        ref.watch(mikrotikRouterOverviewProvider(selected.id!));
    final liveAsync = ref.watch(mikrotikLiveSnapshotProvider(selected.id!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: selected.id,
                decoration: const InputDecoration(labelText: 'الراوتر'),
                items: [
                  for (final router in available)
                    DropdownMenuItem(
                      value: router.id,
                      child: Text('${router.name} - ${router.address}'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRouterId = value);
                  }
                },
              ),
              const SizedBox(height: AppTokens.s12),
              Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _DiagnosticsDialog(routerId: selected.id!),
                    ),
                    icon: const Icon(Icons.troubleshoot_outlined),
                    label: const Text('تشخيص'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _HealthDialog(routerId: selected.id!),
                    ),
                    icon: const Icon(Icons.health_and_safety_outlined),
                    label: const Text('المخاطر'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(
                      '/router-programming/${selected.id!}',
                    ),
                    icon: const Icon(Icons.tune_outlined),
                    label: const Text('برمجة'),
                  ),
                  IconButton(
                    tooltip: 'تحديث الحالة',
                    onPressed: () {
                      ref.invalidate(
                        mikrotikRouterOverviewProvider(selected.id!),
                      );
                      ref.invalidate(
                        mikrotikLiveSnapshotProvider(selected.id!),
                      );
                    },
                    icon: const Icon(Icons.sync),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        _GuidedAssistantPanel(routerId: selected.id!),
        const SizedBox(height: AppTokens.s12),
        _RouterProtectedActions(
          routerId: selected.id!,
          routerName: selected.name,
          onRefresh: () {
            ref.invalidate(mikrotikRouterOverviewProvider(selected.id!));
            ref.invalidate(mikrotikLiveSnapshotProvider(selected.id!));
            ref.invalidate(mikrotikRouterBackupsProvider(selected.id!));
          },
        ),
        const SizedBox(height: AppTokens.s12),
        overviewAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => HubErrorState(
            title: 'تعذر قراءة حالة الراوتر',
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(
              mikrotikRouterOverviewProvider(selected.id!),
            ),
          ),
          data: (overview) => _OverviewBody(overview: overview),
        ),
        const SizedBox(height: AppTokens.s16),
        _RouterBackupsPanel(routerId: selected.id!),
        const SizedBox(height: AppTokens.s16),
        liveAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => HubErrorState(
            title: 'تعذر قراءة تفاصيل الراوتر',
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(
              mikrotikLiveSnapshotProvider(selected.id!),
            ),
          ),
          data: (snapshot) => _LiveSnapshotPanel(
            routerId: selected.id!,
            snapshot: snapshot,
            onRefresh: () => ref.invalidate(
              mikrotikLiveSnapshotProvider(selected.id!),
            ),
          ),
        ),
      ],
    );
  }
}

class _RouterProtectedActions extends ConsumerWidget {
  const _RouterProtectedActions({
    required this.routerId,
    required this.routerName,
    required this.onRefresh,
  });

  final int routerId;
  final String routerName;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(routerOperationControllerProvider);
    final controller = ref.read(routerOperationControllerProvider.notifier);
    return AppCard(
      title: 'أوامر محمية للراوتر',
      icon: Icons.admin_panel_settings_outlined,
      actions: [
        StatusPill(
          text: state.isBusy ? 'تنفيذ جارٍ' : 'جاهزة',
          tone: state.isBusy ? PillTone.amber : PillTone.green,
          dot: true,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'هذه الأوامر تُرسل عبر API محمي إلى الريدياس، ثم ينفذها الريدياس على الراوتر المسجل. لا يتم تشغيل أي أمر قبل التأكيد الواضح.',
            style: TextStyle(color: AppTokens.textSecondary, height: 1.45),
          ),
          if (state.notice.isNotEmpty || state.error.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            _ActionMessage(
              text: state.notice.isNotEmpty
                  ? state.notice
                  : visibleErrorMessage(state.error),
              isError: state.error.isNotEmpty,
              onClose: controller.clearMessage,
            ),
          ],
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _ActionButton(
                label: 'حفظ نسخة من الراوتر',
                icon: Icons.backup_outlined,
                busy: state.busyAction == 'backup_save',
                disabled: state.isBusy,
                onPressed: () async {
                  final input = await _showBackupDialog(context, routerName);
                  if (input == null) return;
                  await controller.saveBackup(
                    routerId,
                    name: input.$1,
                    notes: input.$2,
                  );
                },
              ),
              _ActionButton(
                label: 'تغيير اسم الراوتر',
                icon: Icons.badge_outlined,
                busy: state.busyAction == 'identity',
                disabled: state.isBusy,
                onPressed: () async {
                  final input = await _showIdentityDialog(context, routerName);
                  if (input == null) return;
                  await controller.setIdentity(
                    routerId,
                    name: input.$1,
                    reason: input.$2,
                  );
                },
              ),
              _ActionButton(
                label: 'مزامنة الوقت',
                icon: Icons.schedule_send_outlined,
                busy: state.busyAction == 'ntp',
                disabled: state.isBusy,
                onPressed: () async {
                  final ok = await _confirm(
                    context,
                    title: 'مزامنة وقت الراوتر',
                    body:
                        'سيتم طلب مزامنة NTP من الراوتر. الإجراء غير تخريبي ويمكن تنفيذه الآن.',
                    confirmLabel: 'مزامنة الوقت',
                  );
                  if (ok) await controller.syncNtp(routerId);
                },
              ),
              _ActionButton(
                label: 'تفريغ ذاكرة DNS',
                icon: Icons.cleaning_services_outlined,
                busy: state.busyAction == 'dns',
                disabled: state.isBusy,
                onPressed: () async {
                  final ok = await _confirm(
                    context,
                    title: 'تفريغ ذاكرة DNS',
                    body:
                        'سيتم تفريغ ذاكرة DNS المؤقتة على الراوتر فقط. الطلبات القادمة ستُقرأ من جديد.',
                    confirmLabel: 'تفريغ الذاكرة',
                  );
                  if (ok) await controller.flushDns(routerId);
                },
              ),
              _ActionButton(
                label: 'إعادة تشغيل الراوتر',
                icon: Icons.power_settings_new_outlined,
                tone: _ActionTone.danger,
                busy: state.busyAction == 'reboot',
                disabled: state.isBusy,
                onPressed: () async {
                  final reason = await _showRebootDialog(context);
                  if (reason == null) return;
                  await controller.reboot(routerId, reason: reason);
                },
              ),
              OutlinedButton.icon(
                onPressed: state.isBusy ? null : onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث الحالة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuidedAssistantPanel extends ConsumerStatefulWidget {
  const _GuidedAssistantPanel({required this.routerId});

  final int routerId;

  @override
  ConsumerState<_GuidedAssistantPanel> createState() =>
      _GuidedAssistantPanelState();
}

class _GuidedAssistantPanelState extends ConsumerState<_GuidedAssistantPanel> {
  String _operation = 'programming_hotspot';

  @override
  Widget build(BuildContext context) {
    final request = (routerId: widget.routerId, operation: _operation);
    final async = ref.watch(mikrotikGuidedAssistantProvider(request));
    return AppCard(
      title: 'مساعد ما قبل التنفيذ',
      icon: Icons.fact_check_outlined,
      actions: [
        IconButton(
          tooltip: 'تحديث الفحص',
          onPressed: () => ref.invalidate(
            mikrotikGuidedAssistantProvider(request),
          ),
          icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'يفحص حالة الراوتر، صلاحية المستخدم، النسخة الاحتياطية، وآخر العمليات قبل تنفيذ أي تغيير حساس. الفحص للقراءة فقط ولا يرسل أوامر للراوتر.',
            style: TextStyle(color: AppTokens.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppTokens.s12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _operation,
            decoration: const InputDecoration(labelText: 'نوع العملية'),
            items: [
              for (final choice in _guidedFallbackChoices)
                DropdownMenuItem(
                  value: choice.code,
                  child: Text(choice.label),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _operation = value);
            },
          ),
          const SizedBox(height: AppTokens.s12),
          async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => HubErrorState(
              title: 'تعذر تحميل فحص العملية',
              subtitle: visibleErrorMessage(error),
              onRetry: () => ref.invalidate(
                mikrotikGuidedAssistantProvider(request),
              ),
            ),
            data: _assistantBody,
          ),
        ],
      ),
    );
  }

  Widget _assistantBody(MikrotikGuidedChecklist checklist) {
    final choices = checklist.operationChoices.isEmpty
        ? _guidedFallbackChoices
        : checklist.operationChoices;
    final selectedLabel = _guidedOperationLabel(choices, checklist.operation);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            StatusPill(
              text: checklist.canProceed ? 'جاهز للمتابعة' : 'يوجد مانع',
              tone: checklist.canProceed ? PillTone.green : PillTone.red,
              dot: true,
            ),
            StatusPill(
              text: '${checklist.blockingCount} مانع',
              tone:
                  checklist.blockingCount > 0 ? PillTone.red : PillTone.neutral,
            ),
            StatusPill(
              text: '${checklist.warningCount} تنبيه',
              tone: checklist.warningCount > 0
                  ? PillTone.amber
                  : PillTone.neutral,
            ),
            if ((selectedLabel.isEmpty
                    ? checklist.operationLabel
                    : selectedLabel)
                .isNotEmpty)
              StatusPill(
                text: selectedLabel.isEmpty
                    ? checklist.operationLabel
                    : selectedLabel,
                tone: PillTone.blue,
              ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        if (checklist.steps.isEmpty)
          const EmptyState(
            icon: Icons.fact_check_outlined,
            title: 'لا توجد خطوات فحص',
            subtitle: 'لم يرجع الخادم خطوات لهذه العملية بعد.',
          )
        else
          Column(
            children: [
              for (final step in checklist.steps) ...[
                _GuidedStepRow(step: step),
                const SizedBox(height: AppTokens.s8),
              ],
            ],
          ),
        if (checklist.canProceed) ...[
          const SizedBox(height: AppTokens.s8),
          const Text(
            'يمكن المتابعة من أوامر الراوتر المحمية أو من شاشة العملية المناسبة عند توفرها داخل التطبيق.',
            style: TextStyle(color: AppTokens.greenInk, height: 1.45),
          ),
        ],
      ],
    );
  }
}

class _GuidedStepRow extends StatelessWidget {
  const _GuidedStepRow({required this.step});

  final MikrotikGuidedStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_guidedIcon(step.state), color: _guidedColor(step.state)),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppTokens.s8,
                  runSpacing: AppTokens.s8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      step.label.isEmpty ? 'خطوة فحص' : step.label,
                      style: const TextStyle(
                        color: AppTokens.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    StatusPill(
                      text: step.stateLabel,
                      tone: _guidedTone(step.state),
                    ),
                  ],
                ),
                if (step.detail.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    step.detail,
                    style: const TextStyle(
                      color: AppTokens.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouterBackupsPanel extends ConsumerWidget {
  const _RouterBackupsPanel({required this.routerId});

  final int routerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backups = ref.watch(mikrotikRouterBackupsProvider(routerId));
    final state = ref.watch(routerOperationControllerProvider);
    final controller = ref.read(routerOperationControllerProvider.notifier);
    return backups.when(
      loading: () => const AppCard(
        title: 'نسخ الراوتر المحفوظة',
        icon: Icons.restore_outlined,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => HubErrorState(
        title: 'تعذر تحميل نسخ الراوتر',
        subtitle: visibleErrorMessage(error),
        onRetry: () => ref.invalidate(mikrotikRouterBackupsProvider(routerId)),
      ),
      data: (page) {
        if (page.backups.isEmpty) {
          return const AppCard(
            title: 'نسخ الراوتر المحفوظة',
            icon: Icons.restore_outlined,
            child: EmptyState(
              icon: Icons.backup_outlined,
              title: 'لا توجد نسخ محفوظة لهذا الراوتر',
              subtitle:
                  'استخدم زر حفظ نسخة من الراوتر قبل أي تغيير كبير حتى تستطيع الرجوع لو احتجت.',
            ),
          );
        }
        return AppCard(
          title: 'نسخ الراوتر المحفوظة',
          icon: Icons.restore_outlined,
          actions: [
            StatusPill(text: '${page.count} نسخة', tone: PillTone.blue),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final backup in page.backups) ...[
                _BackupRow(
                  backup: backup,
                  busy: state.busyAction == 'restore_${backup.id}' ||
                      state.busyAction == 'delete_${backup.id}',
                  disabled: state.isBusy,
                  onRestore: () async {
                    final notes = await _showRestoreDialog(context, backup);
                    if (notes == null) return;
                    await controller.restoreBackup(
                      routerId,
                      backup.id,
                      notes: notes,
                    );
                  },
                  onDelete: () async {
                    final ok = await _confirm(
                      context,
                      title: 'حذف سجل النسخة',
                      body:
                          'سيتم حذف سجل النسخة من لوحة الريدياس فقط، ولن يتم حذف الملف الموجود على الراوتر.',
                      confirmLabel: 'حذف السجل',
                      danger: true,
                    );
                    if (ok) await controller.deleteBackup(routerId, backup.id);
                  },
                ),
                const SizedBox(height: AppTokens.s8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BackupRow extends StatelessWidget {
  const _BackupRow({
    required this.backup,
    required this.busy,
    required this.disabled,
    required this.onRestore,
    required this.onDelete,
  });

  final MikrotikRouterBackup backup;
  final bool busy;
  final bool disabled;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                backup.displayName,
                style: const TextStyle(
                  color: AppTokens.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: [
                  StatusPill(
                    text: backup.routerStatusLabel,
                    tone: backup.canRestoreFromRouter
                        ? PillTone.green
                        : PillTone.neutral,
                  ),
                  if (backup.createdAt.isNotEmpty)
                    _MiniFact('تاريخ الحفظ', backup.createdAt),
                  if (backup.manifestSummary.isNotEmpty)
                    _MiniFact('الملخص', backup.manifestSummary),
                ],
              ),
              if (backup.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  backup.notes,
                  style: const TextStyle(color: AppTokens.textSecondary),
                ),
              ],
            ],
          );
          final actions = Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              OutlinedButton.icon(
                onPressed: disabled || busy || !backup.canRestoreFromRouter
                    ? null
                    : onRestore,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore),
                label: const Text('استعادة'),
              ),
              TextButton.icon(
                onPressed: disabled || busy ? null : onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('حذف السجل'),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: AppTokens.s12),
                actions,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: info),
              const SizedBox(width: AppTokens.s12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _ActionMessage extends StatelessWidget {
  const _ActionMessage({
    required this.text,
    required this.isError,
    required this.onClose,
  });

  final String text;
  final bool isError;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: isError ? AppTokens.redSoft : AppTokens.greenSoft,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(
          color: isError ? AppTokens.red : AppTokens.green,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? AppTokens.redInk : AppTokens.greenInk,
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isError ? AppTokens.redInk : AppTokens.greenInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'إخفاء الرسالة',
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.disabled,
    required this.onPressed,
    this.tone = _ActionTone.normal,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final bool disabled;
  final VoidCallback onPressed;
  final _ActionTone tone;

  @override
  Widget build(BuildContext context) {
    final dangerous = tone == _ActionTone.danger;
    return dangerous
        ? OutlinedButton.icon(
            onPressed: disabled || busy ? null : onPressed,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon),
            label: Text(label),
            style: OutlinedButton.styleFrom(foregroundColor: AppTokens.redInk),
          )
        : ElevatedButton.icon(
            onPressed: disabled || busy ? null : onPressed,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon),
            label: Text(label),
          );
  }
}

enum _ActionTone { normal, danger }

class _OverviewBody extends StatelessWidget {
  const _OverviewBody({required this.overview});

  final MikrotikRouterOverview overview;

  @override
  Widget build(BuildContext context) {
    final resource = overview.section('resource')?.firstRow ?? const {};
    final identity = overview.section('identity')?.firstRow ?? const {};
    final routerboard = overview.section('routerboard')?.firstRow ?? const {};
    final displayName = (identity['name'] ?? overview.name).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          title: displayName.isEmpty ? 'راوتر بدون اسم' : displayName,
          icon: Icons.router_outlined,
          actions: [
            StatusPill(
              text: overview.anyOk ? 'متصل' : 'غير متصل',
              tone: overview.anyOk ? PillTone.green : PillTone.red,
              dot: true,
            ),
            StatusPill(text: overview.modeLabel, tone: PillTone.blue),
          ],
          child: Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _InfoChip(
                Icons.memory_outlined,
                'المعالج ${_value(resource, 'cpu-load', fallback: 'غير معروف')}%',
              ),
              _InfoChip(
                Icons.schedule_outlined,
                'مدة التشغيل ${_value(resource, 'uptime')}',
              ),
              _InfoChip(
                Icons.system_update_alt_outlined,
                'الإصدار ${_value(resource, 'version')}',
              ),
              _InfoChip(
                Icons.developer_board_outlined,
                'اللوحة ${_value(routerboard, 'model', fallback: _value(resource, 'board-name'))}',
              ),
              if (overview.dialAddress.isNotEmpty)
                _InfoChip(
                  Icons.lan_outlined,
                  'عنوان الاتصال ${overview.dialAddress}',
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            final cards = [
              for (final entry in overview.sections.entries)
                _SectionCard(name: entry.key, section: entry.value),
            ];
            if (!wide) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: AppTokens.s12),
                  ],
                ],
              );
            }
            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppTokens.s12,
              mainAxisSpacing: AppTokens.s12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.15,
              children: cards,
            );
          },
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.name, required this.section});

  final String name;
  final MikrotikOverviewSection section;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: _sectionLabel(name),
      icon: _sectionIcon(name),
      actions: [
        StatusPill(
          text: section.ok ? 'سليم' : 'مشكلة',
          tone: section.ok ? PillTone.green : PillTone.red,
          dot: true,
        ),
        if (section.cached)
          const StatusPill(text: 'من الذاكرة المؤقتة', tone: PillTone.neutral),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (section.ok)
            Text(
              'تمت القراءة خلال ${section.tookMs} مللي ثانية.',
              style: const TextStyle(color: AppTokens.textSecondary),
            )
          else
            Text(
              section.error.isEmpty
                  ? 'لم يرجع الراوتر بيانات لهذه الخانة.'
                  : section.error,
              style: const TextStyle(color: AppTokens.redInk),
            ),
          if (section.dialedAddress.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            Text(
              'عنوان الاتصال: ${section.dialedAddress}',
              style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTokens.textMuted),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppTokens.textSecondary)),
        ],
      ),
    );
  }
}

class _LiveSnapshotPanel extends StatelessWidget {
  const _LiveSnapshotPanel({
    required this.routerId,
    required this.snapshot,
    required this.onRefresh,
  });

  final int routerId;
  final MikrotikLiveSnapshot snapshot;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل تشغيل الراوتر',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTokens.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'قراءة مباشرة من عقود MikroTik الموجودة في الخادم: الواجهات، الجلسات، الطوابير، الجدار الناري، الملفات، والنسخ.',
                    style: TextStyle(color: AppTokens.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            StatusPill(
              text: '${snapshot.totalRows} عنصر',
              tone: snapshot.anyOk ? PillTone.blue : PillTone.neutral,
            ),
            if (snapshot.failedSections > 0) ...[
              const SizedBox(width: AppTokens.s8),
              StatusPill(
                text: '${snapshot.failedSections} أقسام تعذرت',
                tone: PillTone.amber,
              ),
            ],
            IconButton(
              tooltip: 'تحديث تفاصيل التشغيل',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 960;
            final cards = [
              for (final section in snapshot.sections)
                _LiveSectionCard(
                  routerId: routerId,
                  section: section,
                  onChanged: onRefresh,
                ),
            ];
            if (!wide) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: AppTokens.s12),
                  ],
                ],
              );
            }
            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppTokens.s12,
              mainAxisSpacing: AppTokens.s12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              children: cards,
            );
          },
        ),
      ],
    );
  }
}

class _LiveSectionCard extends StatelessWidget {
  const _LiveSectionCard({
    required this.routerId,
    required this.section,
    required this.onChanged,
  });

  final int routerId;
  final MikrotikLiveSection section;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final rows = section.rows.take(6).toList();
    return AppCard(
      title: section.title,
      icon: _liveSectionIcon(section.key),
      actions: [
        StatusPill(
          text: section.ok ? 'جاهز' : 'متعذر',
          tone: section.ok ? PillTone.green : PillTone.red,
          dot: true,
        ),
        if (section.cached)
          const StatusPill(text: 'من الذاكرة المؤقتة', tone: PillTone.neutral),
        if (section.key == 'address_lists' && section.ok)
          _AddAddressListButton(routerId: routerId, onChanged: onChanged),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _MiniFact('العناصر', section.rowCount.toString()),
              if (section.tookMs > 0)
                _MiniFact('زمن القراءة', '${section.tookMs} مللي ثانية'),
              if (section.mode.isNotEmpty)
                _MiniFact('طريقة الاتصال', _modeLabel(section.mode)),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          if (!section.ok)
            Text(
              section.error.isEmpty
                  ? 'تعذر قراءة هذا القسم من الراوتر.'
                  : section.error,
              style: const TextStyle(color: AppTokens.redInk),
            )
          else if (!section.hasData)
            const Text(
              'لا توجد بيانات حالية في هذا القسم.',
              style: TextStyle(color: AppTokens.textSecondary),
            )
          else if (rows.isEmpty)
            _KeyValueGrid(values: section.summary)
          else
            Column(
              children: [
                for (final row in rows) ...[
                  _RouterRowPreview(
                    routerId: routerId,
                    sectionKey: section.key,
                    row: row,
                    onChanged: onChanged,
                  ),
                  const SizedBox(height: AppTokens.s8),
                ],
                if (section.rows.length > rows.length)
                  Text(
                    'يعرض أول ${rows.length} من أصل ${section.rows.length} عنصر.',
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MiniFact extends StatelessWidget {
  const _MiniFact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r8),
        border: Border.all(color: AppTokens.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _RouterRowPreview extends StatelessWidget {
  const _RouterRowPreview({
    required this.routerId,
    required this.sectionKey,
    required this.row,
    required this.onChanged,
  });

  final int routerId;
  final String sectionKey;
  final Map<String, dynamic> row;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final values = _rowPreviewValues(sectionKey, row);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _KeyValueGrid(values: values)),
          _RouterRowActions(
            routerId: routerId,
            sectionKey: sectionKey,
            row: row,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Reads the MikroTik internal id (`.id`) from a live row; falls back to `id`.
String? _rowMikrotikId(Map<String, dynamic> row) {
  final raw = row['.id'] ?? row['id'];
  final value = raw?.toString().trim() ?? '';
  return value.isEmpty ? null : value;
}

/// Per-row control surface for the live sections — only the sections whose web
/// `/api/v1/mikrotik/<id>/…` mutations exist render a button (disconnect /
/// queue edit / address-list delete / file download). Everything else is
/// read-only and shows nothing.
class _RouterRowActions extends ConsumerStatefulWidget {
  const _RouterRowActions({
    required this.routerId,
    required this.sectionKey,
    required this.row,
    required this.onChanged,
  });

  final int routerId;
  final String sectionKey;
  final Map<String, dynamic> row;
  final VoidCallback onChanged;

  @override
  ConsumerState<_RouterRowActions> createState() => _RouterRowActionsState();
}

class _RouterRowActionsState extends ConsumerState<_RouterRowActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final id = _rowMikrotikId(widget.row);
    final Widget? button = switch (widget.sectionKey) {
      'hotspot_active' || 'ppp_active' when id != null => IconButton(
          tooltip: 'قطع الجلسة',
          visualDensity: VisualDensity.compact,
          color: AppTokens.redInk,
          onPressed: _busy ? null : () => _disconnect(id),
          icon: const Icon(Icons.link_off, size: 18),
        ),
      'queues' when id != null => IconButton(
          tooltip: 'تعديل الطابور',
          visualDensity: VisualDensity.compact,
          onPressed: _busy ? null : () => _editQueue(id),
          icon: const Icon(Icons.tune, size: 18),
        ),
      'address_lists' when id != null => IconButton(
          tooltip: 'حذف العنصر',
          visualDensity: VisualDensity.compact,
          color: AppTokens.redInk,
          onPressed: _busy ? null : () => _removeAddress(id),
          icon: const Icon(Icons.delete_outline, size: 18),
        ),
      'files' => IconButton(
          tooltip: 'تنزيل الملف',
          visualDensity: VisualDensity.compact,
          onPressed: _busy ? null : _downloadFile,
          icon: const Icon(Icons.download_outlined, size: 18),
        ),
      _ => null,
    };
    if (button == null) return const SizedBox.shrink();
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return button;
  }

  Future<void> _run(Future<MikrotikActionResult> Function() action) async {
    setState(() => _busy = true);
    try {
      final result = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.visibleMessage)),
      );
      if (result.ok) widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect(String id) async {
    final who = (widget.row['user'] ?? widget.row['name'] ?? id).toString();
    final confirmed = await _confirm(
      context,
      title: 'قطع الجلسة',
      body: 'سيتم فصل «$who» عن الراوتر فورًا. متابعة؟',
      confirmLabel: 'قطع',
      danger: true,
    );
    if (confirmed != true) return;
    final repo = ref.read(mikrotikRepositoryProvider);
    await _run(
      () => widget.sectionKey == 'hotspot_active'
          ? repo.disconnectHotspotSession(widget.routerId, id)
          : repo.disconnectPppSession(widget.routerId, id),
    );
  }

  Future<void> _removeAddress(String id) async {
    final addr = (widget.row['address'] ?? id).toString();
    final confirmed = await _confirm(
      context,
      title: 'حذف عنصر من قائمة العناوين',
      body: 'سيُحذف العنوان «$addr» من قائمة العناوين على الراوتر. متابعة؟',
      confirmLabel: 'حذف',
      danger: true,
    );
    if (confirmed != true) return;
    final repo = ref.read(mikrotikRepositoryProvider);
    await _run(() => repo.removeAddressListEntry(widget.routerId, id));
  }

  Future<void> _editQueue(String id) async {
    final changes = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _QueueEditDialog(row: widget.row),
    );
    if (changes == null || changes.isEmpty) return;
    final repo = ref.read(mikrotikRepositoryProvider);
    await _run(() => repo.setSimpleQueue(widget.routerId, id, changes));
  }

  Future<void> _downloadFile() async {
    final name = (widget.row['name'] ?? '').toString().trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن تحديد اسم الملف.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final bytes =
          await ref.read(mikrotikRepositoryProvider).downloadRouterFile(
                widget.routerId,
                name,
              );
      final dot = name.lastIndexOf('.');
      final base = dot > 0 ? name.substring(0, dot) : name;
      final ext =
          dot > 0 && dot < name.length - 1 ? name.substring(dot + 1) : 'bin';
      await FileSaver.instance.saveFile(
        name: base.replaceAll('/', '-'),
        bytes: bytes,
        ext: ext,
        mimeType: MimeType.other,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تنزيل «$name» (${bytes.length} بايت).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Edits the common simple-queue limits (`max-limit` up/down + enable/disable).
class _QueueEditDialog extends StatefulWidget {
  const _QueueEditDialog({required this.row});

  final Map<String, dynamic> row;

  @override
  State<_QueueEditDialog> createState() => _QueueEditDialogState();
}

class _QueueEditDialogState extends State<_QueueEditDialog> {
  late final TextEditingController _maxLimit;
  late bool _disabled;

  @override
  void initState() {
    super.initState();
    _maxLimit = TextEditingController(
      text: (widget.row['max-limit'] ?? '').toString(),
    );
    final raw = (widget.row['disabled'] ?? 'false').toString().toLowerCase();
    _disabled = raw == 'true' || raw == 'yes';
  }

  @override
  void dispose() {
    _maxLimit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.row['name'] ?? widget.row['target'] ?? '').toString();
    return AlertDialog(
      title: const Text('تعديل الطابور'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (name.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.s12),
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.textSecondary,
                ),
              ),
            ),
          TextField(
            controller: _maxLimit,
            decoration: const InputDecoration(
              labelText: 'أقصى سرعة (رفع/تنزيل)',
              helperText: 'مثال: 10M/10M',
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('تعطيل الطابور'),
            value: _disabled,
            onChanged: (v) => setState(() => _disabled = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            final changes = <String, dynamic>{
              'disabled': _disabled,
            };
            final limit = _maxLimit.text.trim();
            if (limit.isNotEmpty) changes['max-limit'] = limit;
            Navigator.pop(context, changes);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

/// Section-level "add entry" action for the firewall address-list card.
class _AddAddressListButton extends ConsumerWidget {
  const _AddAddressListButton({
    required this.routerId,
    required this.onChanged,
  });

  final int routerId;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'إضافة عنوان',
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.add, size: 18),
      onPressed: () async {
        final entry = await showDialog<_AddressListEntry>(
          context: context,
          builder: (_) => const _AddressListAddDialog(),
        );
        if (entry == null) return;
        try {
          final result =
              await ref.read(mikrotikRepositoryProvider).addAddressListEntry(
                    routerId,
                    list: entry.list,
                    address: entry.address,
                    comment: entry.comment,
                    timeout: entry.timeout,
                  );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.visibleMessage)),
          );
          if (result.ok) onChanged();
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(visibleErrorMessage(e))),
          );
        }
      },
    );
  }
}

class _AddressListEntry {
  const _AddressListEntry({
    required this.list,
    required this.address,
    required this.comment,
    required this.timeout,
  });

  final String list;
  final String address;
  final String comment;
  final String timeout;
}

class _AddressListAddDialog extends StatefulWidget {
  const _AddressListAddDialog();

  @override
  State<_AddressListAddDialog> createState() => _AddressListAddDialogState();
}

class _AddressListAddDialogState extends State<_AddressListAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _list = TextEditingController();
  final _address = TextEditingController();
  final _comment = TextEditingController();
  final _timeout = TextEditingController();

  @override
  void dispose() {
    _list.dispose();
    _address.dispose();
    _comment.dispose();
    _timeout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة عنوان لقائمة'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _list,
              decoration: const InputDecoration(
                labelText: 'اسم القائمة *',
                helperText: 'مثال: blocked، allowed',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: AppTokens.s8),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'العنوان *',
                helperText: 'IP أو نطاق، مثال: 192.168.1.5',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: AppTokens.s8),
            TextFormField(
              controller: _comment,
              decoration: const InputDecoration(labelText: 'تعليق'),
            ),
            const SizedBox(height: AppTokens.s8),
            TextFormField(
              controller: _timeout,
              decoration: const InputDecoration(
                labelText: 'مهلة (اختياري)',
                helperText: 'مثال: 1h، 30m',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(
              context,
              _AddressListEntry(
                list: _list.text.trim(),
                address: _address.text.trim(),
                comment: _comment.text.trim(),
                timeout: _timeout.text.trim(),
              ),
            );
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}

class _KeyValueGrid extends StatelessWidget {
  const _KeyValueGrid({required this.values});

  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries
        .where((entry) => _displayValue(entry.value).isNotEmpty)
        .take(5)
        .toList();
    if (entries.isEmpty) {
      return const Text(
        'لا توجد تفاصيل إضافية.',
        style: TextStyle(color: AppTokens.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 118,
                  child: Text(
                    _fieldLabel(entry.key),
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _displayValue(entry.value, key: entry.key),
                    style: const TextStyle(
                      color: AppTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Future<(String, String)?> _showBackupDialog(
  BuildContext context,
  String routerName,
) async {
  final name = TextEditingController();
  final notes = TextEditingController();
  try {
    return await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حفظ نسخة احتياطية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'سيتم إنشاء ملف نسخة على الراوتر وحفظ ملخصها داخل لوحة الريدياس.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTokens.textSecondary,
                  ),
            ),
            const SizedBox(height: AppTokens.s12),
            TextField(
              controller: name,
              decoration: InputDecoration(
                labelText: 'اسم النسخة اختياري',
                hintText: routerName.isEmpty ? 'before-change' : routerName,
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            TextField(
              controller: notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ملاحظات داخلية اختيارية',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              (name.text.trim(), notes.text.trim()),
            ),
            child: const Text('حفظ النسخة'),
          ),
        ],
      ),
    );
  } finally {
    name.dispose();
    notes.dispose();
  }
}

Future<(String, String)?> _showIdentityDialog(
  BuildContext context,
  String currentName,
) async {
  final name = TextEditingController(text: currentName);
  final reason = TextEditingController();
  try {
    return await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير اسم الراوتر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اكتب الاسم الجديد كما سيظهر داخل MikroTik. هذا الأمر يحتاج تأكيدًا ويحفظ في سجل التدقيق.',
              style: TextStyle(color: AppTokens.textSecondary, height: 1.45),
            ),
            const SizedBox(height: AppTokens.s12),
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'الاسم الجديد'),
            ),
            const SizedBox(height: AppTokens.s12),
            TextField(
              controller: reason,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'سبب التغيير اختياري',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final clean = name.text.trim();
              if (clean.isEmpty) return;
              Navigator.pop(context, (clean, reason.text.trim()));
            },
            child: const Text('تغيير الاسم'),
          ),
        ],
      ),
    );
  } finally {
    name.dispose();
    reason.dispose();
  }
}

Future<String?> _showRebootDialog(BuildContext context) async {
  final reason = TextEditingController();
  var confirmed = false;
  try {
    return await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إعادة تشغيل الراوتر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'هذا أمر حساس. الراوتر قد يفصل المشتركين مؤقتًا أثناء إعادة التشغيل.',
                style: TextStyle(color: AppTokens.redInk, height: 1.45),
              ),
              const SizedBox(height: AppTokens.s12),
              TextField(
                controller: reason,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'سبب إعادة التشغيل اختياري',
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              CheckboxListTile(
                value: confirmed,
                onChanged: (value) {
                  setState(() => confirmed = value == true);
                },
                contentPadding: EdgeInsets.zero,
                title: const Text('أفهم أن الراوتر سيُعاد تشغيله الآن'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            OutlinedButton(
              onPressed: confirmed
                  ? () => Navigator.pop(context, reason.text.trim())
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTokens.redInk,
              ),
              child: const Text('إعادة التشغيل'),
            ),
          ],
        ),
      ),
    );
  } finally {
    reason.dispose();
  }
}

Future<String?> _showRestoreDialog(
  BuildContext context,
  MikrotikRouterBackup backup,
) async {
  final notes = TextEditingController();
  var confirmed = false;
  try {
    return await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('استعادة نسخة الراوتر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'سيتم إرسال أمر استعادة النسخة "${backup.displayName}". الراوتر سيعيد التشغيل بعد الاستعادة.',
                style: const TextStyle(
                  color: AppTokens.redInk,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              TextField(
                controller: notes,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات الاستعادة اختيارية',
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              CheckboxListTile(
                value: confirmed,
                onChanged: (value) {
                  setState(() => confirmed = value == true);
                },
                contentPadding: EdgeInsets.zero,
                title: const Text('أفهم أن الاستعادة ستعيد تشغيل الراوتر'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            OutlinedButton(
              onPressed: confirmed
                  ? () => Navigator.pop(context, notes.text.trim())
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTokens.redInk,
              ),
              child: const Text('استعادة النسخة'),
            ),
          ],
        ),
      ),
    );
  } finally {
    notes.dispose();
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(
        body,
        style: const TextStyle(color: AppTokens.textSecondary, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        danger
            ? OutlinedButton(
                onPressed: () => Navigator.pop(context, true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTokens.redInk,
                ),
                child: Text(confirmLabel),
              )
            : ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
      ],
    ),
  );
  return result == true;
}

const _guidedFallbackChoices = <MikrotikGuidedOperationChoice>[
  MikrotikGuidedOperationChoice(
    code: 'programming_hotspot',
    label: 'برمجة بوابة الدخول',
  ),
  MikrotikGuidedOperationChoice(
    code: 'programming_pppoe',
    label: 'برمجة البرودباند',
  ),
  MikrotikGuidedOperationChoice(
    code: 'unprogramming',
    label: 'تراجع وإزالة برمجة',
  ),
  MikrotikGuidedOperationChoice(
    code: 'restore',
    label: 'استعادة من نسخة احتياطية',
  ),
  MikrotikGuidedOperationChoice(
    code: 'backup_save',
    label: 'حفظ نسخة احتياطية',
  ),
];

String _guidedOperationLabel(
  List<MikrotikGuidedOperationChoice> choices,
  String code,
) {
  for (final choice in choices) {
    if (choice.code == code) return choice.label;
  }
  return '';
}

PillTone _guidedTone(String state) {
  return switch (state) {
    'ok' => PillTone.green,
    'warning' => PillTone.amber,
    'blocking' => PillTone.red,
    'info' => PillTone.blue,
    _ => PillTone.neutral,
  };
}

IconData _guidedIcon(String state) {
  return switch (state) {
    'ok' => Icons.check_circle_outline,
    'warning' => Icons.warning_amber_outlined,
    'blocking' => Icons.block,
    'info' => Icons.info_outline,
    _ => Icons.help_outline,
  };
}

Color _guidedColor(String state) {
  return switch (state) {
    'ok' => AppTokens.greenInk,
    'warning' => AppTokens.amberInk,
    'blocking' => AppTokens.redInk,
    'info' => AppTokens.blueInk,
    _ => AppTokens.textMuted,
  };
}

String _value(
  Map<String, dynamic> map,
  String key, {
  String fallback = 'غير معروف',
}) {
  final value = (map[key] ?? '').toString().trim();
  return value.isEmpty ? fallback : value;
}

String _sectionLabel(String name) {
  return switch (name) {
    'resource' => 'الموارد',
    'health' => 'الصحة',
    'identity' => 'الهوية',
    'clock' => 'الوقت',
    'routerboard' => 'لوحة الجهاز',
    _ => 'قسم حالة',
  };
}

IconData _sectionIcon(String name) {
  return switch (name) {
    'resource' => Icons.memory_outlined,
    'health' => Icons.monitor_heart_outlined,
    'identity' => Icons.badge_outlined,
    'clock' => Icons.schedule_outlined,
    'routerboard' => Icons.developer_board_outlined,
    _ => Icons.info_outline,
  };
}

IconData _liveSectionIcon(String key) {
  return switch (key) {
    'interfaces' => Icons.settings_input_component_outlined,
    'ip_addresses' => Icons.pin_drop_outlined,
    'routes' => Icons.alt_route_outlined,
    'neighbors' => Icons.device_hub_outlined,
    'hotspot_active' => Icons.wifi_outlined,
    'ppp_active' => Icons.link_outlined,
    'queues' => Icons.speed_outlined,
    'firewall_filter' => Icons.security_outlined,
    'firewall_nat' => Icons.compare_arrows_outlined,
    'address_lists' => Icons.list_alt_outlined,
    'logs' => Icons.receipt_long_outlined,
    'files' => Icons.folder_outlined,
    'router_backups' => Icons.backup_outlined,
    'counters' => Icons.query_stats_outlined,
    _ => Icons.info_outline,
  };
}

Map<String, dynamic> _rowPreviewValues(
  String sectionKey,
  Map<String, dynamic> row,
) {
  final preferred = switch (sectionKey) {
    'interfaces' => [
        'name',
        'type',
        'running',
        'disabled',
        'rx-byte',
        'tx-byte',
      ],
    'ip_addresses' => ['address', 'interface', 'network', 'dynamic'],
    'routes' => ['dst-address', 'gateway', 'distance', 'active', 'disabled'],
    'neighbors' => ['identity', 'address', 'mac-address', 'interface'],
    'hotspot_active' => ['user', 'address', 'mac-address', 'uptime'],
    'ppp_active' => ['name', 'address', 'caller-id', 'uptime', 'service'],
    'queues' => ['name', 'target', 'max-limit', 'rate', 'disabled'],
    'firewall_filter' || 'firewall_nat' => [
        'chain',
        'action',
        'protocol',
        'src-address',
        'dst-address',
        'dst-port',
        'disabled',
      ],
    'address_lists' => ['list', 'address', 'dynamic', 'disabled', 'comment'],
    'logs' => ['time', 'topics', 'message'],
    'files' => ['name', 'type', 'size', 'creation-time'],
    'router_backups' => [
        'name',
        'router_status',
        'manifest_summary',
        'created_at',
      ],
    _ => <String>[],
  };
  final out = <String, dynamic>{};
  for (final key in preferred) {
    if (row.containsKey(key)) out[key] = row[key];
  }
  for (final entry in row.entries) {
    if (out.length >= 5) break;
    out.putIfAbsent(entry.key, () => entry.value);
  }
  return out;
}

String _fieldLabel(String key) {
  return switch (key) {
    'name' => 'الاسم',
    'type' => 'النوع',
    'running' => 'يعمل',
    'disabled' => 'معطل',
    'rx-byte' || 'rx_bytes' => 'التحميل الوارد',
    'tx-byte' || 'tx_bytes' => 'الرفع الصادر',
    'address' => 'العنوان',
    'interface' => 'الواجهة',
    'network' => 'الشبكة',
    'dynamic' => 'تلقائي',
    'dst-address' => 'وجهة المسار',
    'gateway' => 'البوابة',
    'distance' => 'الأولوية',
    'active' => 'نشط',
    'identity' => 'هوية الجهاز',
    'mac-address' || 'caller-id' => 'عنوان MAC',
    'user' => 'المستخدم',
    'uptime' => 'مدة التشغيل',
    'service' => 'الخدمة',
    'target' => 'الهدف',
    'max-limit' => 'الحد الأقصى',
    'rate' => 'السرعة الحالية',
    'chain' => 'السلسلة',
    'action' => 'الإجراء',
    'protocol' => 'البروتوكول',
    'src-address' => 'المصدر',
    'dst-port' => 'منفذ الوجهة',
    'list' => 'القائمة',
    'comment' => 'ملاحظة',
    'time' => 'الوقت',
    'topics' => 'الموضوع',
    'message' => 'الرسالة',
    'size' || 'size_bytes' => 'الحجم',
    'creation-time' || 'created_at' => 'تاريخ الإنشاء',
    'router_status' => 'حالة ملف الراوتر',
    'manifest_summary' => 'ملخص النسخة',
    'count' => 'العدد',
    'total' => 'الإجمالي',
    _ => key.replaceAll('_', ' ').replaceAll('-', ' '),
  };
}

String _displayValue(Object? value, {String key = ''}) {
  if (value == null) return '';
  if (value is bool) return value ? 'نعم' : 'لا';
  final text = value.toString().trim();
  if (text.isEmpty) return '';
  if (key == 'router_status') {
    return switch (text) {
      'on_router' => 'موجودة على الراوتر',
      'saved' => 'محفوظة',
      'restored' => 'مستعادة',
      _ => 'حالة غير معروفة',
    };
  }
  if (key == 'disabled' || key == 'dynamic' || key == 'active') {
    return switch (text.toLowerCase()) {
      'true' || 'yes' => 'نعم',
      'false' || 'no' => 'لا',
      _ => text,
    };
  }
  return text;
}

String _modeLabel(String mode) {
  return switch (mode) {
    'vpn' => 'عبر النفق',
    'direct' => 'مباشر',
    _ => mode.isEmpty ? 'غير محدد' : mode,
  };
}

/// Diagnostics dialog — ping / traceroute / DNS-resolve run from the router
/// (mt_diagnostics.html). Backed by the /tools/* mikrotik-control endpoints.
class _DiagnosticsDialog extends ConsumerStatefulWidget {
  const _DiagnosticsDialog({required this.routerId});

  final int routerId;

  @override
  ConsumerState<_DiagnosticsDialog> createState() => _DiagnosticsDialogState();
}

class _DiagnosticsDialogState extends ConsumerState<_DiagnosticsDialog> {
  String _tool = 'ping';
  final _target = TextEditingController(text: '8.8.8.8');
  bool _busy = false;
  String _output = '';

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final target = _target.text.trim();
    if (target.isEmpty) return;
    setState(() {
      _busy = true;
      _output = '';
    });
    try {
      final repo = ref.read(mikrotikRepositoryProvider);
      final Map<String, dynamic> data = switch (_tool) {
        'traceroute' =>
          await repo.tracerouteFromRouter(widget.routerId, target),
        'dns' => await repo.dnsResolveFromRouter(widget.routerId, target),
        _ => await repo.pingFromRouter(widget.routerId, target),
      };
      setState(() => _output = _formatOutput(data));
    } catch (error) {
      setState(() => _output = visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatOutput(Map<String, dynamic> data) {
    final result = data['result'] ?? data['output'] ?? data['rows'] ?? data;
    if (result is List) {
      return result.map((e) => e.toString()).join('\n');
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تشخيص الراوتر'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              showSelectedIcon: false,
              selected: {_tool},
              segments: const [
                ButtonSegment(value: 'ping', label: Text('Ping')),
                ButtonSegment(value: 'traceroute', label: Text('Traceroute')),
                ButtonSegment(value: 'dns', label: Text('DNS')),
              ],
              onSelectionChanged: (s) => setState(() => _tool = s.first),
            ),
            const SizedBox(height: AppTokens.s12),
            TextField(
              controller: _target,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: _tool == 'dns' ? 'اسم النطاق' : 'العنوان الهدف',
                hintText: _tool == 'dns' ? 'example.com' : '8.8.8.8',
              ),
              onSubmitted: (_) => _busy ? null : _run(),
            ),
            const SizedBox(height: AppTokens.s12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 280),
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: AppTokens.surfaceMuted,
                borderRadius: BorderRadius.circular(AppTokens.r10),
                border: Border.all(color: AppTokens.border),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _output.isEmpty ? 'اكتب الهدف ثم اضغط تشغيل.' : _output,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: 'monospace', height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _run,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: const Text('تشغيل'),
        ),
      ],
    );
  }
}

/// Router risk-signals panel (P7 /health: loops / flapping / overlap),
/// using MikrotikRepository.routerHealth.
class _HealthDialog extends ConsumerStatefulWidget {
  const _HealthDialog({required this.routerId});

  final int routerId;

  @override
  ConsumerState<_HealthDialog> createState() => _HealthDialogState();
}

class _HealthDialogState extends ConsumerState<_HealthDialog> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future =
        ref.read(mikrotikRepositoryProvider).routerHealth(widget.routerId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('صحة الراوتر والمخاطر'),
      content: SizedBox(
        width: 560,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(AppTokens.s24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return HubErrorState(
                title: 'تعذر قراءة المخاطر',
                subtitle: visibleErrorMessage(snap.error),
                onRetry: () => setState(() {
                  _future = ref
                      .read(mikrotikRepositoryProvider)
                      .routerHealth(widget.routerId);
                }),
              );
            }
            final data = snap.data ?? const {};
            final signals =
                (data['signals'] ?? data['risks'] ?? data['items']) as List?;
            if (signals == null || signals.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppTokens.s16),
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, color: AppTokens.successFg),
                    SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: Text('لا توجد إشارات خطر حالية على هذا الراوتر.'),
                    ),
                  ],
                ),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in signals.whereType<Map>())
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: AppTokens.warningFg,
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Expanded(
                          child: Text(
                            (s['message'] ??
                                    s['title'] ??
                                    s['kind'] ??
                                    s.toString())
                                .toString(),
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                        if ((s['level'] ?? s['severity']) != null)
                          StatusPill(
                            text: (s['level'] ?? s['severity']).toString(),
                            tone: PillTone.amber,
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}
