import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_kpi.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/store_admin_repository.dart';
import '../domain/store_admin_model.dart';
import 'store_chat_dialog.dart';

/// Store admin-management console — deposit/withdrawal approvals, payment
/// methods CRUD, and the support chat inbox. Mirrors the web store support
/// page, admin-authed via `/api/v1/store/admin/*`.
class StoreAdminScreen extends ConsumerWidget {
  const StoreAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(storeSupportProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'إدارة المتجر',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.sidebarBg,
                      fontWeight: FontWeight.w800,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(storeSupportProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTokens.s24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب لوحة الدعم',
            subtitle: visibleErrorMessage(e),
          ),
          data: (snapshot) => _Body(snapshot: snapshot),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.snapshot});

  final StoreSupportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(snapshot: snapshot),
        const SizedBox(height: AppTokens.s16),
        _RequestsCard(
          title: 'طلبات الإيداع',
          icon: Icons.south_west_outlined,
          pending: snapshot.depositsPending,
          resolved: snapshot.depositsResolved,
          isDeposit: true,
        ),
        const SizedBox(height: AppTokens.s16),
        _RequestsCard(
          title: 'طلبات السحب',
          icon: Icons.north_east_outlined,
          pending: snapshot.withdrawalsPending,
          resolved: snapshot.withdrawalsResolved,
          isDeposit: false,
        ),
        const SizedBox(height: AppTokens.s16),
        _PaymentMethodsCard(methods: snapshot.paymentMethods),
        const SizedBox(height: AppTokens.s16),
        _ChatInboxCard(threads: snapshot.chatThreads),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.snapshot});
  final StoreSupportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final kpis = <Widget>[
      HubKpi(
        label: 'إيداعات معلّقة',
        value: '${snapshot.depositsPendingCount}',
        icon: Icons.south_west_outlined,
        variant: KpiVariant.amber,
      ),
      HubKpi(
        label: 'سحوبات معلّقة',
        value: '${snapshot.withdrawalsPendingCount}',
        icon: Icons.north_east_outlined,
        variant: KpiVariant.blue,
      ),
      HubKpi(
        label: 'رسائل غير مقروءة',
        value: '${snapshot.chatUnreadCount}',
        icon: Icons.mark_chat_unread_outlined,
        variant: KpiVariant.brand,
      ),
      HubKpi(
        label: 'محافظ الاستلام',
        value: '${snapshot.paymentMethods.length}',
        icon: Icons.account_balance_outlined,
        variant: KpiVariant.green,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 880
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        const gap = AppTokens.s12;
        final w =
            ((constraints.maxWidth - gap * (columns - 1)) / columns)
                .floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final k in kpis) SizedBox(width: w, child: k)],
        );
      },
    );
  }
}

class _RequestsCard extends ConsumerStatefulWidget {
  const _RequestsCard({
    required this.title,
    required this.icon,
    required this.pending,
    required this.resolved,
    required this.isDeposit,
  });

  final String title;
  final IconData icon;
  final List<StoreRequest> pending;
  final List<StoreRequest> resolved;
  final bool isDeposit;

  @override
  ConsumerState<_RequestsCard> createState() => _RequestsCardState();
}

class _RequestsCardState extends ConsumerState<_RequestsCard> {
  bool _showResolved = false;
  int? _busyId;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: '${widget.title} (${widget.pending.length} معلّق)',
      icon: widget.icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.pending.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTokens.s12),
              child: Text(
                'لا توجد طلبات معلّقة.',
                style: TextStyle(color: AppTokens.textMuted),
              ),
            )
          else
            for (final r in widget.pending) ...[
              _RequestRow(
                request: r,
                busy: _busyId == r.id,
                actions: true,
                onConfirm: () => _confirm(r),
                onReject: () => _reject(r),
              ),
              const SizedBox(height: AppTokens.s8),
            ],
          if (widget.resolved.isNotEmpty) ...[
            const Divider(height: AppTokens.s24),
            TextButton.icon(
              onPressed: () => setState(() => _showResolved = !_showResolved),
              icon: Icon(
                _showResolved ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text('المحسومة (${widget.resolved.length})'),
            ),
            if (_showResolved)
              for (final r in widget.resolved) ...[
                _RequestRow(request: r, busy: false, actions: false),
                const SizedBox(height: AppTokens.s8),
              ],
          ],
        ],
      ),
    );
  }

  Future<void> _confirm(StoreRequest r) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد ${widget.isDeposit ? 'الإيداع' : 'السحب'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ المطلوب: ${r.amount} ${r.currency}'),
            if (widget.isDeposit) ...[
              const SizedBox(height: AppTokens.s8),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'المبلغ المؤكَّد (اختياري)',
                  helperText: 'اتركه فارغًا لاعتماد المبلغ المطلوب.',
                ),
              ),
            ],
            const SizedBox(height: AppTokens.s8),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(r, () {
      final repo = ref.read(storeAdminRepositoryProvider);
      return widget.isDeposit
          ? repo.confirmDeposit(
              r.id,
              confirmedAmount: amountCtrl.text,
              note: noteCtrl.text,
            )
          : repo.confirmWithdrawal(r.id, note: noteCtrl.text);
    });
  }

  Future<void> _reject(StoreRequest r) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('رفض ${widget.isDeposit ? 'الإيداع' : 'السحب'}'),
        content: TextField(
          controller: noteCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'سبب الرفض (اختياري)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTokens.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(r, () {
      final repo = ref.read(storeAdminRepositoryProvider);
      return widget.isDeposit
          ? repo.rejectDeposit(r.id, note: noteCtrl.text)
          : repo.rejectWithdrawal(r.id, note: noteCtrl.text);
    });
  }

  Future<void> _run(StoreRequest r, Future<void> Function() action) async {
    setState(() => _busyId = r.id);
    try {
      await action();
      ref.invalidate(storeSupportProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم تحديث الطلب')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.busy,
    required this.actions,
    this.onConfirm,
    this.onReject,
  });

  final StoreRequest request;
  final bool busy;
  final bool actions;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r.amount} ${r.currency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppTokens.sidebarBg,
                      ),
                    ),
                    if (r.who.isNotEmpty)
                      Text(
                        r.who,
                        style: const TextStyle(
                          color: AppTokens.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      [r.method, r.reference, r.createdAt]
                          .where((e) => e.isNotEmpty)
                          .join(' • '),
                      style: const TextStyle(
                        color: AppTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              StatusPill(
                text: r.statusAr.isEmpty ? r.status : r.statusAr,
                tone: r.isPending
                    ? PillTone.amber
                    : (r.status == 'confirmed'
                        ? PillTone.green
                        : PillTone.red),
              ),
            ],
          ),
          if (actions) ...[
            const SizedBox(height: AppTokens.s8),
            busy
                ? const Padding(
                    padding: EdgeInsets.all(6),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Wrap(
                    spacing: AppTokens.s8,
                    runSpacing: AppTokens.s8,
                    children: [
                      FilledButton.icon(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('تأكيد'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTokens.redInk,
                        ),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('رفض'),
                      ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMethodsCard extends ConsumerWidget {
  const _PaymentMethodsCard({required this.methods});
  final List<PaymentMethod> methods;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      title: 'محافظ الاستلام',
      icon: Icons.account_balance_outlined,
      actions: [
        FilledButton.icon(
          onPressed: () => _edit(context, ref, null),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('إضافة'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (methods.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTokens.s12),
              child: Text(
                'لا توجد محافظ استلام بعد.',
                style: TextStyle(color: AppTokens.textMuted),
              ),
            )
          else
            for (final m in methods) ...[
              Container(
                padding: const EdgeInsets.all(AppTokens.s12),
                margin: const EdgeInsets.only(bottom: AppTokens.s8),
                decoration: BoxDecoration(
                  color: AppTokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppTokens.r10),
                  border: Border.all(color: AppTokens.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.label.isEmpty ? m.methodAr : m.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTokens.sidebarBg,
                            ),
                          ),
                          Text(
                            [m.accountName, m.accountNumber]
                                .where((e) => e.isNotEmpty)
                                .join(' • '),
                            style: const TextStyle(
                              color: AppTokens.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    StatusPill(
                      text: m.active ? 'مفعّلة' : 'معطّلة',
                      tone: m.active ? PillTone.green : PillTone.neutral,
                    ),
                    IconButton(
                      tooltip: 'تعديل',
                      onPressed: () => _edit(context, ref, m),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    IconButton(
                      tooltip: 'حذف',
                      onPressed: () => _delete(context, ref, m),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppTokens.redInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    PaymentMethod? method,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PaymentMethodDialog(method: method),
    );
    if (saved == true) ref.invalidate(storeSupportProvider);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PaymentMethod method,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف محفظة الاستلام'),
        content: Text('سيتم حذف «${method.label}». متابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTokens.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(storeAdminRepositoryProvider).deletePaymentMethod(
            method.id,
          );
      ref.invalidate(storeSupportProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم الحذف')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    }
  }
}

class _PaymentMethodDialog extends ConsumerStatefulWidget {
  const _PaymentMethodDialog({this.method});
  final PaymentMethod? method;

  @override
  ConsumerState<_PaymentMethodDialog> createState() =>
      _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends ConsumerState<_PaymentMethodDialog> {
  late final TextEditingController _label;
  late final TextEditingController _accountName;
  late final TextEditingController _accountNumber;
  late final TextEditingController _instructions;
  late final TextEditingController _sortOrder;
  late String _method;
  late bool _active;
  bool _saving = false;

  static const _methods = {
    'bank': 'تحويل بنكي',
    'wallet': 'محفظة إلكترونية',
    'cliq': 'كليك (CliQ)',
    'cash': 'نقدي',
    'other': 'قناة أخرى',
  };

  @override
  void initState() {
    super.initState();
    final m = widget.method;
    _label = TextEditingController(text: m?.label ?? '');
    _accountName = TextEditingController(text: m?.accountName ?? '');
    _accountNumber = TextEditingController(text: m?.accountNumber ?? '');
    _instructions = TextEditingController(text: m?.instructions ?? '');
    _sortOrder = TextEditingController(text: '${m?.sortOrder ?? 0}');
    _method = _methods.containsKey(m?.method) ? m!.method : 'other';
    _active = m?.active ?? true;
  }

  @override
  void dispose() {
    _label.dispose();
    _accountName.dispose();
    _accountNumber.dispose();
    _instructions.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.method == null ? 'محفظة استلام جديدة' : 'تعديل المحفظة'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _method,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'القناة'),
                items: [
                  for (final e in _methods.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _method = v ?? 'other'),
              ),
              const SizedBox(height: AppTokens.s8),
              TextField(
                controller: _label,
                decoration: const InputDecoration(labelText: 'الاسم المعروض'),
              ),
              const SizedBox(height: AppTokens.s8),
              TextField(
                controller: _accountName,
                decoration: const InputDecoration(labelText: 'اسم الحساب'),
              ),
              const SizedBox(height: AppTokens.s8),
              TextField(
                controller: _accountNumber,
                decoration: const InputDecoration(labelText: 'رقم الحساب/المحفظة'),
              ),
              const SizedBox(height: AppTokens.s8),
              TextField(
                controller: _instructions,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'تعليمات الدفع'),
              ),
              const SizedBox(height: AppTokens.s8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sortOrder,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الترتيب'),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                      title: const Text('مفعّلة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_label.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب الاسم المعروض.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(storeAdminRepositoryProvider);
      final sort = int.tryParse(_sortOrder.text.trim()) ?? 0;
      if (widget.method == null) {
        await repo.createPaymentMethod(
          method: _method,
          label: _label.text.trim(),
          accountName: _accountName.text.trim(),
          accountNumber: _accountNumber.text.trim(),
          instructions: _instructions.text.trim(),
          sortOrder: sort,
        );
      } else {
        await repo.updatePaymentMethod(
          widget.method!.id,
          method: _method,
          label: _label.text.trim(),
          accountName: _accountName.text.trim(),
          accountNumber: _accountNumber.text.trim(),
          instructions: _instructions.text.trim(),
          sortOrder: sort,
          active: _active,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    }
  }
}

class _ChatInboxCard extends StatelessWidget {
  const _ChatInboxCard({required this.threads});
  final List<ChatThread> threads;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'صندوق الدعم',
      icon: Icons.forum_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (threads.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTokens.s12),
              child: Text(
                'لا توجد محادثات.',
                style: TextStyle(color: AppTokens.textMuted),
              ),
            )
          else
            for (final t in threads)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppTokens.brandSoft,
                  child: Icon(Icons.person_outline, color: AppTokens.brandInk),
                ),
                title: Text(
                  t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  t.lastBody,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTokens.textMuted),
                ),
                trailing: t.unreadAdminCount > 0
                    ? StatusPill(
                        text: '${t.unreadAdminCount}',
                        tone: PillTone.red,
                      )
                    : const Icon(Icons.chevron_left, color: AppTokens.textMuted),
                onTap: () => showStoreChatDialog(context, t),
              ),
        ],
      ),
    );
  }
}
