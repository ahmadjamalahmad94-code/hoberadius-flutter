import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/radius_resources_providers.dart';
import '../data/radius_resources_repository.dart';
import '../domain/radius_resources_model.dart';

class RadiusResourcesScreen extends ConsumerWidget {
  const RadiusResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedRadiusResourcesTabProvider);
    final page = ref.watch(radiusResourcesSnapshotProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'موارد تشغيل الريدياس',
          subtitle:
              'إدارة تجمعات عناوين IP ومجموعات المشاركة التي تستخدمها الباقات والمشتركين بدون كتابة إعدادات تقنية خام.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(radiusResourcesSnapshotProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
            ElevatedButton.icon(
              onPressed: () => _openCreate(context, ref, tab),
              icon: const Icon(Icons.add),
              label: Text(
                tab == RadiusResourcesTab.pools ? 'تجمع جديد' : 'مجموعة جديدة',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        _Tabs(selected: tab),
        const SizedBox(height: AppTokens.s16),
        page.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => HubErrorState(
            title: 'تعذر تحميل موارد التشغيل',
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(radiusResourcesSnapshotProvider),
          ),
          data: (data) => LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1080;
              final side = _SideGuide(snapshot: data, tab: tab);
              final list = tab == RadiusResourcesTab.pools
                  ? _PoolsPanel(items: data.pools)
                  : _ShareGroupsPanel(items: data.shareGroups);
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
        ),
      ],
    );
  }

  void _openCreate(
    BuildContext context,
    WidgetRef ref,
    RadiusResourcesTab tab,
  ) {
    if (tab == RadiusResourcesTab.pools) {
      _showPoolDialog(context: context, ref: ref);
    } else {
      _showShareGroupDialog(context: context, ref: ref);
    }
  }
}

class _Tabs extends ConsumerWidget {
  const _Tabs({required this.selected});

  final RadiusResourcesTab selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<RadiusResourcesTab>(
      showSelectedIcon: false,
      selected: {selected},
      segments: const [
        ButtonSegment(
          value: RadiusResourcesTab.pools,
          icon: Icon(Icons.hub_outlined),
          label: Text('تجمعات العناوين'),
        ),
        ButtonSegment(
          value: RadiusResourcesTab.shareGroups,
          icon: Icon(Icons.groups_2_outlined),
          label: Text('مجموعات المشاركة'),
        ),
      ],
      onSelectionChanged: (selection) {
        ref.read(selectedRadiusResourcesTabProvider.notifier).state =
            selection.first;
      },
    );
  }
}

class _SideGuide extends StatelessWidget {
  const _SideGuide({
    required this.snapshot,
    required this.tab,
  });

  final RadiusResourcesSnapshot snapshot;
  final RadiusResourcesTab tab;

  @override
  Widget build(BuildContext context) {
    final isPools = tab == RadiusResourcesTab.pools;
    final rows = isPools
        ? [
            ('التجمعات', '${snapshot.pools.length} تجمع محفوظ'),
            ('مرتبطة براوتر', '${snapshot.assignedPoolRouters} تجمع'),
            ('الاستخدام', 'تربط الباقات والمشتركين بنطاق عناوين واضح.'),
          ]
        : [
            ('المجموعات', '${snapshot.shareGroups.length} مجموعة محفوظة'),
            ('مفعلة', '${snapshot.activeGroups} مجموعة'),
            ('الاستخدام', 'تجمع أكثر من مشترك على حصة أو سرعة مشتركة.'),
          ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppTokens.brandSoft,
            child: Icon(
              isPools ? Icons.hub_outlined : Icons.groups_2_outlined,
              color: AppTokens.brandInk,
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Text(
            isPools ? 'تجمعات عناوين IP' : 'مجموعات المشاركة',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: AppTokens.sidebarBg,
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            isPools
                ? 'استخدم هذه الصفحة لتحديد النطاقات التي يسحب منها الريدياس عناوين المشتركين عند التشغيل.'
                : 'استخدمها لتجميع مشتركين على حصة أو سرعة مشتركة، مع حد أقصى للأعضاء عند الحاجة.',
            style: const TextStyle(color: AppTokens.textMuted, height: 1.45),
          ),
          const Divider(height: AppTokens.s24),
          for (final row in rows) ...[
            Text(row.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(
              row.$2,
              style: const TextStyle(color: AppTokens.textMuted, height: 1.35),
            ),
            const SizedBox(height: AppTokens.s12),
          ],
          const StatusPill(
            text: 'متصل بعقد API حقيقي',
            tone: PillTone.green,
            icon: Icons.verified_outlined,
          ),
        ],
      ),
    );
  }
}

class _PoolsPanel extends ConsumerWidget {
  const _PoolsPanel({required this.items});

  final List<IpPoolResource> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.hub_outlined,
        title: 'لا توجد تجمعات عناوين بعد',
        subtitle: 'أضف أول تجمع ليظهر كخيار جاهز عند ربط الباقات أو الراوترات.',
        action: ElevatedButton.icon(
          onPressed: () => _showPoolDialog(context: context, ref: ref),
          icon: const Icon(Icons.add),
          label: const Text('تجمع جديد'),
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _PoolTile(pool: items[index]),
      ),
    );
  }
}

class _PoolTile extends ConsumerStatefulWidget {
  const _PoolTile({required this.pool});

  final IpPoolResource pool;

  @override
  ConsumerState<_PoolTile> createState() => _PoolTileState();
}

class _PoolTileState extends ConsumerState<_PoolTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final pool = widget.pool;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: AppTokens.brandSoft,
            child: Icon(Icons.hub_outlined, color: AppTokens.brandInk),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pool.poolName.isEmpty ? 'تجمع #${pool.id}' : pool.poolName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTokens.sidebarBg,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: AppTokens.s8,
                  runSpacing: AppTokens.s8,
                  children: [
                    StatusPill(text: pool.rangeIp, tone: PillTone.blue),
                    if (pool.localIp.isNotEmpty)
                      StatusPill(
                        text: 'عنوان البوابة ${pool.localIp}',
                        tone: PillTone.cyan,
                      ),
                    if (pool.routerId != null)
                      StatusPill(
                        text: 'راوتر #${pool.routerId}',
                        tone: PillTone.purple,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Wrap(
            spacing: AppTokens.s8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _showPoolDialog(
                          context: context,
                          ref: ref,
                          pool: pool,
                        ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل'),
              ),
              IconButton(
                tooltip: 'حذف',
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await _confirm(
      context,
      title: 'حذف تجمع العناوين؟',
      message: 'سيتم حذف التجمع من الخادم. تأكد أنه غير مستخدم في باقة نشطة.',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(radiusResourcesRepositoryProvider)
          .deletePool(widget.pool.id);
      ref.invalidate(radiusResourcesSnapshotProvider);
      if (mounted) _snack(context, 'تم حذف تجمع العناوين');
    } catch (error) {
      if (mounted) _snack(context, 'تعذر حذف التجمع: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ShareGroupsPanel extends ConsumerWidget {
  const _ShareGroupsPanel({required this.items});

  final List<ShareGroupResource> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.groups_2_outlined,
        title: 'لا توجد مجموعات مشاركة بعد',
        subtitle: 'أنشئ مجموعة لتجميع أكثر من مشترك على حصة أو سرعة مشتركة.',
        action: ElevatedButton.icon(
          onPressed: () => _showShareGroupDialog(context: context, ref: ref),
          icon: const Icon(Icons.add),
          label: const Text('مجموعة جديدة'),
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _ShareGroupTile(group: items[index]),
      ),
    );
  }
}

class _ShareGroupTile extends ConsumerStatefulWidget {
  const _ShareGroupTile({required this.group});

  final ShareGroupResource group;

  @override
  ConsumerState<_ShareGroupTile> createState() => _ShareGroupTileState();
}

class _ShareGroupTileState extends ConsumerState<_ShareGroupTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor:
                    group.enabled ? AppTokens.greenSoft : AppTokens.slate100,
                child: Icon(
                  Icons.groups_2_outlined,
                  color:
                      group.enabled ? AppTokens.greenInk : AppTokens.textMuted,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name.isEmpty ? 'مجموعة #${group.id}' : group.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTokens.sidebarBg,
                      ),
                    ),
                    if (group.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        group.description,
                        style: const TextStyle(
                          color: AppTokens.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              StatusPill(
                text: group.enabled ? 'مفعلة' : 'معطلة',
                tone: group.enabled ? PillTone.green : PillTone.neutral,
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              StatusPill(text: '${group.members} عضو', tone: PillTone.blue),
              if (group.maxMembers > 0)
                StatusPill(
                  text: 'الحد ${group.maxMembers}',
                  tone: PillTone.cyan,
                ),
              if (group.sharedQuotaMb > 0)
                StatusPill(
                  text: 'الحصة ${group.sharedQuotaMb} م.ب',
                  tone: PillTone.purple,
                ),
              if (group.sharedSpeedDownKbps > 0 || group.sharedSpeedUpKbps > 0)
                StatusPill(
                  text:
                      'تنزيل ${group.sharedSpeedDownKbps} / رفع ${group.sharedSpeedUpKbps} كيلوبت',
                  tone: PillTone.amber,
                ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _openMembers,
                icon: const Icon(Icons.person_add_alt_outlined),
                label: const Text('الأعضاء'),
              ),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _showShareGroupDialog(
                          context: context,
                          ref: ref,
                          group: group,
                        ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _toggle,
                icon: Icon(
                  group.enabled ? Icons.pause_circle : Icons.play_circle,
                ),
                label: Text(group.enabled ? 'تعطيل' : 'تفعيل'),
              ),
              IconButton(
                tooltip: 'حذف',
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openMembers() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _MembersDialog(group: widget.group),
    );
    ref.invalidate(radiusResourcesSnapshotProvider);
  }

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      final group = widget.group;
      await ref.read(radiusResourcesRepositoryProvider).updateShareGroup(
            ShareGroupResource(
              id: group.id,
              name: group.name,
              description: group.description,
              sharedQuotaMb: group.sharedQuotaMb,
              sharedSpeedDownKbps: group.sharedSpeedDownKbps,
              sharedSpeedUpKbps: group.sharedSpeedUpKbps,
              maxMembers: group.maxMembers,
              enabled: !group.enabled,
              members: group.members,
              createdAt: group.createdAt,
            ),
          );
      ref.invalidate(radiusResourcesSnapshotProvider);
      if (mounted) _snack(context, 'تم تحديث حالة المجموعة');
    } catch (error) {
      if (mounted) _snack(context, 'تعذر تحديث المجموعة: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await _confirm(
      context,
      title: 'حذف مجموعة المشاركة؟',
      message: 'سيتم حذف المجموعة من الخادم وإلغاء ربط أعضائها منها.',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(radiusResourcesRepositoryProvider)
          .deleteShareGroup(widget.group.id);
      ref.invalidate(radiusResourcesSnapshotProvider);
      if (mounted) _snack(context, 'تم حذف مجموعة المشاركة');
    } catch (error) {
      if (mounted) _snack(context, 'تعذر حذف المجموعة: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _MembersDialog extends ConsumerStatefulWidget {
  const _MembersDialog({required this.group});

  final ShareGroupResource group;

  @override
  ConsumerState<_MembersDialog> createState() => _MembersDialogState();
}

class _MembersDialogState extends ConsumerState<_MembersDialog> {
  late Future<ShareGroupDetails> _future;
  final _subscriberId = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _subscriberId.dispose();
    super.dispose();
  }

  Future<ShareGroupDetails> _load() {
    return ref
        .read(radiusResourcesRepositoryProvider)
        .getShareGroup(widget.group.id);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('أعضاء ${widget.group.name}'),
      content: SizedBox(
        width: 680,
        child: FutureBuilder<ShareGroupDetails>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(AppTokens.s24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return HubErrorState(
                title: 'تعذر تحميل الأعضاء',
                subtitle: '${snapshot.error}',
                onRetry: _reload,
              );
            }
            final details = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subscriberId,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'رقم المشترك',
                          hintText: 'أدخل رقم المشترك ثم اضغط إضافة',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    ElevatedButton.icon(
                      onPressed: _busy ? null : _addMember,
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),
                if (details.members.isEmpty)
                  const EmptyState(
                    icon: Icons.group_off_outlined,
                    title: 'لا يوجد أعضاء في هذه المجموعة',
                    subtitle:
                        'أضف المشتركين حسب رقمهم الداخلي من صفحة المشتركين.',
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 380),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: details.members.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final member = details.members[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTokens.brandSoft,
                            child: Icon(
                              Icons.person_outline,
                              color: AppTokens.brandInk,
                            ),
                          ),
                          title: Text(member.displayName),
                          subtitle: Text('@${member.username}'),
                          trailing: Wrap(
                            spacing: AppTokens.s8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              StatusPill(
                                text: member.statusLabel,
                                tone: PillTone.blue,
                              ),
                              IconButton(
                                tooltip: 'إزالة',
                                onPressed: _busy
                                    ? null
                                    : () => _removeMember(member.id),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        );
                      },
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

  Future<void> _addMember() async {
    final id = int.tryParse(_subscriberId.text.trim()) ?? 0;
    if (id <= 0) {
      _snack(context, 'أدخل رقم مشترك صحيح');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(radiusResourcesRepositoryProvider).addMember(
            groupId: widget.group.id,
            subscriberId: id,
          );
      _subscriberId.clear();
      _reload();
      if (mounted) _snack(context, 'تمت إضافة العضو');
    } catch (error) {
      if (mounted) _snack(context, 'تعذرت إضافة العضو: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeMember(int subscriberId) async {
    setState(() => _busy = true);
    try {
      await ref.read(radiusResourcesRepositoryProvider).removeMember(
            groupId: widget.group.id,
            subscriberId: subscriberId,
          );
      _reload();
      if (mounted) _snack(context, 'تمت إزالة العضو');
    } catch (error) {
      if (mounted) _snack(context, 'تعذرت إزالة العضو: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

Future<void> _showPoolDialog({
  required BuildContext context,
  required WidgetRef ref,
  IpPoolResource? pool,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _PoolDialog(pool: pool),
  );
}

class _PoolDialog extends ConsumerStatefulWidget {
  const _PoolDialog({this.pool});

  final IpPoolResource? pool;

  @override
  ConsumerState<_PoolDialog> createState() => _PoolDialogState();
}

class _PoolDialogState extends ConsumerState<_PoolDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _range;
  late final TextEditingController _local;
  late final TextEditingController _router;
  bool _saving = false;

  bool get _editing => widget.pool != null;

  @override
  void initState() {
    super.initState();
    final pool = widget.pool;
    _name = TextEditingController(text: pool?.poolName ?? '');
    _range = TextEditingController(text: pool?.rangeIp ?? '');
    _local = TextEditingController(text: pool?.localIp ?? '');
    _router = TextEditingController(text: pool?.routerId?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _range.dispose();
    _local.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'تعديل تجمع العناوين' : 'تجمع عناوين جديد'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'اسم التجمع'),
                validator: _required,
              ),
              const SizedBox(height: AppTokens.s12),
              TextFormField(
                controller: _range,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'نطاق العناوين',
                  hintText: '10.10.0.10-10.10.0.250',
                ),
                validator: _required,
              ),
              const SizedBox(height: AppTokens.s12),
              TextFormField(
                controller: _local,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'عنوان البوابة المحلي',
                  hintText: 'اختياري',
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              TextFormField(
                controller: _router,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'رقم الراوتر',
                  hintText: 'اختياري',
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
          label: const Text('حفظ'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final existing = widget.pool;
      final pool = IpPoolResource(
        id: existing?.id ?? 0,
        poolName: _name.text.trim(),
        rangeIp: _range.text.trim(),
        localIp: _local.text.trim(),
        routerId: int.tryParse(_router.text.trim()),
        createdAt: existing?.createdAt,
      );
      final repo = ref.read(radiusResourcesRepositoryProvider);
      if (existing == null) {
        await repo.createPool(pool);
      } else {
        await repo.updatePool(pool);
      }
      ref.invalidate(radiusResourcesSnapshotProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack(context, 'تم حفظ تجمع العناوين');
    } catch (error) {
      if (mounted) _snack(context, 'تعذر حفظ التجمع: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

Future<void> _showShareGroupDialog({
  required BuildContext context,
  required WidgetRef ref,
  ShareGroupResource? group,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _ShareGroupDialog(group: group),
  );
}

class _ShareGroupDialog extends ConsumerStatefulWidget {
  const _ShareGroupDialog({this.group});

  final ShareGroupResource? group;

  @override
  ConsumerState<_ShareGroupDialog> createState() => _ShareGroupDialogState();
}

class _ShareGroupDialogState extends ConsumerState<_ShareGroupDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _quota;
  late final TextEditingController _down;
  late final TextEditingController _up;
  late final TextEditingController _maxMembers;
  bool _enabled = true;
  bool _saving = false;

  bool get _editing => widget.group != null;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _name = TextEditingController(text: group?.name ?? '');
    _description = TextEditingController(text: group?.description ?? '');
    _quota = TextEditingController(
      text: _optionalNumber(group?.sharedQuotaMb),
    );
    _down = TextEditingController(
      text: _optionalNumber(group?.sharedSpeedDownKbps),
    );
    _up = TextEditingController(
      text: _optionalNumber(group?.sharedSpeedUpKbps),
    );
    _maxMembers = TextEditingController(
      text: _optionalNumber(group?.maxMembers),
    );
    _enabled = group?.enabled ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _quota.dispose();
    _down.dispose();
    _up.dispose();
    _maxMembers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'تعديل مجموعة المشاركة' : 'مجموعة مشاركة جديدة'),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'اسم المجموعة'),
                  validator: _required,
                ),
                const SizedBox(height: AppTokens.s12),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'شرح مختصر',
                    hintText: 'مثال: عائلة واحدة أو مكتب واحد',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppTokens.s12),
                _NumberField(
                  controller: _quota,
                  label: 'الحصة المشتركة بالميغابايت',
                ),
                const SizedBox(height: AppTokens.s12),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        controller: _down,
                        label: 'سرعة التحميل كيلوبت',
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: _NumberField(
                        controller: _up,
                        label: 'سرعة الرفع كيلوبت',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s12),
                _NumberField(
                  controller: _maxMembers,
                  label: 'أقصى عدد أعضاء',
                ),
                const SizedBox(height: AppTokens.s8),
                SwitchListTile(
                  value: _enabled,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('المجموعة مفعلة'),
                  onChanged: (value) => setState(() => _enabled = value),
                ),
              ],
            ),
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
          label: const Text('حفظ'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final existing = widget.group;
      final group = ShareGroupResource(
        id: existing?.id ?? 0,
        name: _name.text.trim(),
        description: _description.text.trim(),
        sharedQuotaMb: _number(_quota),
        sharedSpeedDownKbps: _number(_down),
        sharedSpeedUpKbps: _number(_up),
        maxMembers: _number(_maxMembers),
        enabled: _enabled,
        members: existing?.members ?? 0,
        createdAt: existing?.createdAt,
      );
      final repo = ref.read(radiusResourcesRepositoryProvider);
      if (existing == null) {
        await repo.createShareGroup(group);
      } else {
        await repo.updateShareGroup(group);
      }
      ref.invalidate(radiusResourcesSnapshotProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack(context, 'تم حفظ مجموعة المشاركة');
    } catch (error) {
      if (mounted) _snack(context, 'تعذر حفظ المجموعة: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, hintText: 'اختياري'),
    );
  }
}

String? _required(String? value) {
  if ((value ?? '').trim().isEmpty) return 'هذا الحقل مطلوب';
  return null;
}

String _optionalNumber(int? value) {
  if (value == null || value <= 0) return '';
  return '$value';
}

int _number(TextEditingController controller) {
  return int.tryParse(controller.text.trim()) ?? 0;
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ) ??
      false;
}

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
