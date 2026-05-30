import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../nas/data/nas_repository.dart';
import '../../nas/domain/nas_model.dart';
import '../application/network_policy_providers.dart';
import '../data/network_policy_repository.dart';
import '../domain/network_policy_model.dart';

class NetworkPolicyScreen extends ConsumerWidget {
  const NetworkPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedKind = ref.watch(selectedNetworkPolicyProvider);
    final page = ref.watch(networkPolicyPageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'مركز سياسات الشبكة',
          subtitle:
              'حفظ ومعاينة سياسات الراوتر من التطبيق، والتنفيذ يبقى من مسار التشغيل المعتمد في الخادم.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(networkPolicyPageProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
            ElevatedButton.icon(
              onPressed: () => _showCreatePolicyDialog(
                context: context,
                ref: ref,
                kind: selectedKind,
              ),
              icon: const Icon(Icons.add),
              label: const Text('سياسة جديدة'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        _PolicyKindSelector(selected: selectedKind),
        const SizedBox(height: AppTokens.s16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1040;
            final list = page.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppTokens.s40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => HubErrorState(
                title: 'تعذر تحميل سياسات الشبكة',
                subtitle: '$error',
                onRetry: () => ref.invalidate(networkPolicyPageProvider),
              ),
              data: (data) => _PoliciesList(
                kind: selectedKind,
                items: data.items,
              ),
            );
            final side = _PolicySidePanel(kind: selectedKind);
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
                SizedBox(width: 330, child: side),
                const SizedBox(width: AppTokens.s12),
                Expanded(child: list),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PolicyKindSelector extends ConsumerWidget {
  const _PolicyKindSelector({required this.selected});

  final NetworkPolicyKind selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: [
        for (final kind in networkPolicyKinds)
          ButtonSegment(
            value: kind.slug,
            label: Text(kind.label),
            icon: Icon(_kindIcon(kind)),
          ),
      ],
      selected: {selected.slug},
      onSelectionChanged: (selection) {
        ref.read(selectedNetworkPolicyKindProvider.notifier).state =
            selection.first;
      },
    );
  }
}

class _PolicySidePanel extends StatelessWidget {
  const _PolicySidePanel({required this.kind});

  final NetworkPolicyKind kind;

  @override
  Widget build(BuildContext context) {
    final rows = kind.isRemoteAccess
        ? const [
            ('الخدمات', 'Winbox وSSH وAPI وWebFig حسب الحاجة'),
            ('المصدر', 'قائمة عناوين موثوقة أو مدة انتهاء واضحة'),
            ('المعاينة', 'تفحص الأثر والتحذيرات قبل أي تنفيذ'),
          ]
        : kind.isWebBlock
            ? const [
                ('الأهداف', 'نطاق أو IP أو شبكة CIDR للحظر'),
                ('النطاق', 'حاليًا كل المستخدمين حسب عقد الخادم'),
                ('المعاينة', 'توضح عدد أوامر الحظر والتحذيرات'),
              ]
            : const [
                ('العناصر', 'نطاق دفع أو IP مسموح قبل الدخول'),
                ('البروفايل', 'اختياري لتحديد Hotspot Profile'),
                ('المعاينة', 'تراجع السماح وقابلية التراجع'),
              ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTokens.brandSoft,
                child: Icon(_kindIcon(kind), color: AppTokens.brandInk),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  kind.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTokens.sidebarBg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Text(
            kind.description,
            style: const TextStyle(color: AppTokens.textMuted, height: 1.45),
          ),
          const Divider(height: AppTokens.s24),
          for (final row in rows) ...[
            Text(
              row.$1,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              row.$2,
              style: const TextStyle(color: AppTokens.textMuted, height: 1.35),
            ),
            const SizedBox(height: AppTokens.s12),
          ],
          const SizedBox(height: AppTokens.s4),
          const StatusPill(
            text: 'معاينة فقط من التطبيق',
            tone: PillTone.blue,
            icon: Icons.visibility_outlined,
          ),
        ],
      ),
    );
  }
}

class _PoliciesList extends ConsumerWidget {
  const _PoliciesList({
    required this.kind,
    required this.items,
  });

  final NetworkPolicyKind kind;
  final List<NetworkPolicy> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return EmptyState(
        icon: _kindIcon(kind),
        title: 'لا توجد سياسات في ${kind.label}',
        subtitle: 'أنشئ سياسة مرتبطة براوتر ثم أضف أهدافها وراجع المعاينة.',
        action: ElevatedButton.icon(
          onPressed: () =>
              _showCreatePolicyDialog(context: context, ref: ref, kind: kind),
          icon: const Icon(Icons.add),
          label: const Text('سياسة جديدة'),
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
        itemBuilder: (context, index) {
          return _PolicyTile(kind: kind, policy: items[index]);
        },
      ),
    );
  }
}

class _PolicyTile extends ConsumerStatefulWidget {
  const _PolicyTile({
    required this.kind,
    required this.policy,
  });

  final NetworkPolicyKind kind;
  final NetworkPolicy policy;

  @override
  ConsumerState<_PolicyTile> createState() => _PolicyTileState();
}

class _PolicyTileState extends ConsumerState<_PolicyTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final policy = widget.policy;
    final fields = _fieldChips(widget.kind, policy);
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
                    policy.enabled ? AppTokens.greenSoft : AppTokens.slate100,
                child: Icon(
                  _kindIcon(widget.kind),
                  color:
                      policy.enabled ? AppTokens.greenInk : AppTokens.textMuted,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy.name.isEmpty ? 'سياسة #${policy.id}' : policy.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTokens.sidebarBg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الراوتر #${policy.routerId} · ${widget.kind.shortLabel}',
                      style: const TextStyle(color: AppTokens.textMuted),
                    ),
                  ],
                ),
              ),
              StatusPill(
                text: policy.enabled ? 'مفعّلة' : 'معطّلة',
                tone: policy.enabled ? PillTone.green : PillTone.neutral,
                dot: true,
              ),
            ],
          ),
          if (fields.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              children: fields,
            ),
          ],
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _preview,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('معاينة الأثر'),
              ),
              if (widget.kind.hasChildren)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _manageChildren,
                  icon: const Icon(Icons.format_list_bulleted_add),
                  label: Text(
                    widget.kind.isWebBlock ? 'أهداف الحظر' : 'عناصر السماح',
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _toggleEnabled,
                icon: Icon(
                  policy.enabled ? Icons.pause_circle : Icons.play_circle,
                ),
                label: Text(policy.enabled ? 'تعطيل' : 'تفعيل'),
              ),
              TextButton.icon(
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('حذف'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _fieldChips(NetworkPolicyKind kind, NetworkPolicy policy) {
    final keys = kind.isRemoteAccess
        ? const [
            'allow_winbox',
            'allow_ssh',
            'allow_api',
            'allow_api_ssl',
            'allow_webfig_http',
            'allow_webfig_https',
            'source_address_list',
            'expires_at',
          ]
        : kind.isWebBlock
            ? const ['scope', 'fail_open']
            : const ['hotspot_profile'];
    return [
      for (final key in keys)
        if (networkPolicyFieldLabel(key, policy.fields[key]).isNotEmpty)
          StatusPill(
            text: networkPolicyFieldLabel(key, policy.fields[key]),
            tone: PillTone.blue,
          ),
    ];
  }

  Future<void> _preview() async {
    setState(() => _busy = true);
    try {
      final preview = await ref
          .read(networkPolicyRepositoryProvider)
          .preview(widget.kind, widget.policy.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _PreviewDialog(preview: preview, kind: widget.kind),
      );
    } catch (error) {
      if (mounted) _snack(context, 'تعذرت المعاينة: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleEnabled() async {
    setState(() => _busy = true);
    try {
      await ref.read(networkPolicyRepositoryProvider).update(
        widget.kind,
        widget.policy.id,
        {'enabled': !widget.policy.enabled},
      );
      ref.invalidate(networkPolicyPageProvider);
      if (mounted) _snack(context, 'تم تحديث حالة السياسة');
    } catch (error) {
      if (mounted) _snack(context, 'تعذر تحديث السياسة: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف السياسة؟'),
        content:
            const Text('سيتم حذف السياسة والعناصر المرتبطة بها من الخادم.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(networkPolicyRepositoryProvider)
          .delete(widget.kind, widget.policy.id);
      ref.invalidate(networkPolicyPageProvider);
      if (mounted) _snack(context, 'تم حذف السياسة');
    } catch (error) {
      if (mounted) _snack(context, 'تعذر حذف السياسة: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manageChildren() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ChildrenDialog(kind: widget.kind, policy: widget.policy),
    );
    ref.invalidate(networkPolicyPageProvider);
  }
}

class _PreviewDialog extends StatelessWidget {
  const _PreviewDialog({
    required this.preview,
    required this.kind,
  });

  final NetworkPolicyPreview preview;
  final NetworkPolicyKind kind;

  @override
  Widget build(BuildContext context) {
    final blockers = preview.blockingErrors;
    final warnings = preview.warnings;
    return AlertDialog(
      title: Text('معاينة ${kind.label}'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: [
                  StatusPill(
                    text: preview.canApply ? 'قابلة للتطبيق' : 'تحتاج تعديل',
                    tone: preview.canApply ? PillTone.green : PillTone.red,
                    dot: true,
                  ),
                  StatusPill(
                    text: '${preview.commandCount} أمر',
                    tone: PillTone.blue,
                  ),
                  if (preview.healthScore > 0)
                    StatusPill(
                      text: 'الصحة ${preview.healthScore}%',
                      tone: preview.healthScore >= 70
                          ? PillTone.green
                          : PillTone.amber,
                    ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              if (preview.explanation.isNotEmpty)
                Text(preview.explanation, style: const TextStyle(height: 1.45)),
              if (blockers.isNotEmpty) ...[
                const SizedBox(height: AppTokens.s12),
                _MessageBox(
                  icon: Icons.error_outline,
                  title: 'موانع التطبيق',
                  items: blockers,
                  tone: PillTone.red,
                ),
              ],
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: AppTokens.s12),
                _MessageBox(
                  icon: Icons.warning_amber_outlined,
                  title: 'تنبيهات',
                  items: warnings,
                  tone: PillTone.amber,
                ),
              ],
              if (preview.scriptHash.isNotEmpty) ...[
                const SizedBox(height: AppTokens.s12),
                SelectableText(
                  'بصمة المعاينة: ${preview.scriptHash}',
                  style: const TextStyle(color: AppTokens.textMuted),
                ),
              ],
              if (preview.forwardScript.isNotEmpty ||
                  preview.rollbackScript.isNotEmpty) ...[
                const SizedBox(height: AppTokens.s12),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('عرض التفاصيل الفنية'),
                  children: [
                    if (preview.forwardScript.isNotEmpty)
                      _ScriptBox(
                        title: 'أوامر التنفيذ',
                        text: preview.forwardScript,
                      ),
                    if (preview.rollbackScript.isNotEmpty)
                      _ScriptBox(
                        title: 'أوامر التراجع',
                        text: preview.rollbackScript,
                      ),
                  ],
                ),
              ],
            ],
          ),
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

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.icon,
    required this.title,
    required this.items,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final List<String> items;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone == PillTone.red ? AppTokens.redInk : AppTokens.amberInk;
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: tone == PillTone.red ? AppTokens.redSoft : AppTokens.amberSoft,
        borderRadius: BorderRadius.circular(AppTokens.r10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppTokens.s8),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item),
            ),
        ],
      ),
    );
  }
}

class _ScriptBox extends StatelessWidget {
  const _ScriptBox({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'نسخ',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  _snack(context, 'تم نسخ التفاصيل الفنية');
                },
                icon: const Icon(Icons.copy),
              ),
            ],
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              color: AppTokens.slate100,
              borderRadius: BorderRadius.circular(AppTokens.r10),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                text,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildrenDialog extends ConsumerWidget {
  const _ChildrenDialog({
    required this.kind,
    required this.policy,
  });

  final NetworkPolicyKind kind;
  final NetworkPolicy policy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = NetworkPolicyChildrenRequest(
      kind: kind,
      policyId: policy.id,
    );
    final children = ref.watch(networkPolicyChildrenProvider(request));
    return AlertDialog(
      title: Text(kind.isWebBlock ? 'أهداف الحظر' : 'عناصر السماح'),
      content: SizedBox(
        width: 680,
        child: children.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => HubErrorState(
            title: 'تعذر تحميل العناصر',
            subtitle: '$error',
            onRetry: () =>
                ref.invalidate(networkPolicyChildrenProvider(request)),
          ),
          data: (page) => _ChildrenEditor(
            kind: kind,
            policy: policy,
            page: page,
            request: request,
          ),
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

class _ChildrenEditor extends ConsumerStatefulWidget {
  const _ChildrenEditor({
    required this.kind,
    required this.policy,
    required this.page,
    required this.request,
  });

  final NetworkPolicyKind kind;
  final NetworkPolicy policy;
  final NetworkPolicyChildrenPage page;
  final NetworkPolicyChildrenRequest request;

  @override
  ConsumerState<_ChildrenEditor> createState() => _ChildrenEditorState();
}

class _ChildrenEditorState extends ConsumerState<_ChildrenEditor> {
  final _value = TextEditingController();
  final _category = TextEditingController(text: 'custom');
  final _notes = TextEditingController();
  final _dstPort = TextEditingController();
  String _kindValue = 'domain';
  String _protocol = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _kindValue = widget.kind.isWebBlock ? 'domain' : 'dst_host';
  }

  @override
  void dispose() {
    _value.dispose();
    _category.dispose();
    _notes.dispose();
    _dstPort.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.page.items.isEmpty)
            EmptyState(
              icon: widget.kind.isWebBlock
                  ? Icons.block_outlined
                  : Icons.verified_user_outlined,
              title: 'لا توجد عناصر بعد',
              subtitle: 'أضف أول عنصر ثم راجع المعاينة.',
            )
          else
            ...widget.page.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.value),
                subtitle: Text(
                  [
                    item.kindLabel,
                    if (item.category.isNotEmpty) item.category,
                    if (item.dstPort.isNotEmpty) 'منفذ ${item.dstPort}',
                    item.statusLabel,
                  ].join(' · '),
                ),
                trailing: IconButton(
                  tooltip: 'حذف',
                  onPressed: _saving ? null : () => _deleteChild(item),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
          const Divider(height: AppTokens.s24),
          Text(
            widget.kind.isWebBlock ? 'إضافة هدف حظر' : 'إضافة عنصر سماح',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppTokens.s12),
          DropdownButtonFormField<String>(
            initialValue: _kindValue,
            decoration: const InputDecoration(labelText: 'النوع'),
            items: widget.kind.isWebBlock
                ? const [
                    DropdownMenuItem(value: 'domain', child: Text('نطاق')),
                    DropdownMenuItem(value: 'ip', child: Text('عنوان IP')),
                    DropdownMenuItem(value: 'cidr', child: Text('شبكة CIDR')),
                  ]
                : const [
                    DropdownMenuItem(
                      value: 'dst_host',
                      child: Text('اسم نطاق'),
                    ),
                    DropdownMenuItem(
                      value: 'dst_address',
                      child: Text('عنوان IP'),
                    ),
                    DropdownMenuItem(
                      value: 'dst_address_list',
                      child: Text('قائمة عناوين'),
                    ),
                  ],
            onChanged: (value) =>
                setState(() => _kindValue = value ?? _kindValue),
          ),
          const SizedBox(height: AppTokens.s12),
          TextField(
            controller: _value,
            decoration: InputDecoration(
              labelText: widget.kind.isWebBlock
                  ? 'النطاق أو العنوان المطلوب حظره'
                  : 'النطاق أو العنوان المسموح',
            ),
          ),
          if (widget.kind.isWebBlock) ...[
            const SizedBox(height: AppTokens.s12),
            TextField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'التصنيف'),
            ),
          ] else ...[
            const SizedBox(height: AppTokens.s12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dstPort,
                    decoration: const InputDecoration(labelText: 'المنفذ'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _protocol,
                    decoration: const InputDecoration(labelText: 'البروتوكول'),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('بدون تحديد')),
                      DropdownMenuItem(value: 'tcp', child: Text('TCP')),
                      DropdownMenuItem(value: 'udp', child: Text('UDP')),
                    ],
                    onChanged: (value) {
                      setState(() => _protocol = value ?? '');
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTokens.s12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'ملاحظات'),
            maxLines: 2,
          ),
          const SizedBox(height: AppTokens.s12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _addChild,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('إضافة'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addChild() async {
    final value = _value.text.trim();
    if (value.isEmpty) {
      _snack(context, 'أدخل القيمة أولًا');
      return;
    }
    setState(() => _saving = true);
    try {
      final body = widget.kind.isWebBlock
          ? {
              'value': value,
              'target_type': _kindValue,
              'category': _category.text.trim().isEmpty
                  ? 'custom'
                  : _category.text.trim(),
              'notes': _notes.text.trim(),
            }
          : {
              'value': value,
              'entry_type': _kindValue,
              'dst_port': _dstPort.text.trim(),
              'protocol': _protocol,
              'notes': _notes.text.trim(),
            };
      await ref
          .read(networkPolicyRepositoryProvider)
          .addChild(widget.kind, widget.policy.id, body);
      _value.clear();
      _notes.clear();
      ref.invalidate(networkPolicyChildrenProvider(widget.request));
      if (mounted) _snack(context, 'تمت الإضافة');
    } catch (error) {
      if (mounted) _snack(context, 'تعذرت الإضافة: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteChild(NetworkPolicyChild child) async {
    setState(() => _saving = true);
    try {
      await ref.read(networkPolicyRepositoryProvider).deleteChild(
            widget.kind,
            widget.policy.id,
            child.id,
          );
      ref.invalidate(networkPolicyChildrenProvider(widget.request));
      if (mounted) _snack(context, 'تم حذف العنصر');
    } catch (error) {
      if (mounted) _snack(context, 'تعذر حذف العنصر: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

Future<void> _showCreatePolicyDialog({
  required BuildContext context,
  required WidgetRef ref,
  required NetworkPolicyKind kind,
}) async {
  List<NasDevice> routers;
  try {
    routers = await ref.read(nasRepositoryProvider).list();
  } catch (error) {
    if (context.mounted) _snack(context, 'تعذر تحميل أجهزة الشبكة: $error');
    return;
  }
  routers = routers.where((router) => router.id != null).toList();
  if (routers.isEmpty) {
    if (context.mounted) {
      _snack(context, 'أضف جهاز شبكة أولًا قبل إنشاء السياسة');
    }
    return;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => _CreatePolicyDialog(kind: kind, routers: routers),
  );
}

class _CreatePolicyDialog extends ConsumerStatefulWidget {
  const _CreatePolicyDialog({
    required this.kind,
    required this.routers,
  });

  final NetworkPolicyKind kind;
  final List<NasDevice> routers;

  @override
  ConsumerState<_CreatePolicyDialog> createState() =>
      _CreatePolicyDialogState();
}

class _CreatePolicyDialogState extends ConsumerState<_CreatePolicyDialog> {
  final _name = TextEditingController();
  final _source = TextEditingController();
  final _expiresAt = TextEditingController();
  final _reason = TextEditingController();
  final _hotspotProfile = TextEditingController();
  int? _routerId;
  bool _enabled = true;
  bool _saving = false;
  bool _allowWinbox = true;
  bool _allowSsh = false;
  bool _allowApi = false;
  bool _allowApiSsl = false;
  bool _allowWebfigHttp = false;
  bool _allowWebfigHttps = true;
  bool _failOpen = true;

  @override
  void initState() {
    super.initState();
    _routerId = widget.routers.first.id;
  }

  @override
  void dispose() {
    _name.dispose();
    _source.dispose();
    _expiresAt.dispose();
    _reason.dispose();
    _hotspotProfile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    return AlertDialog(
      title: Text('سياسة جديدة - ${kind.label}'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'اسم السياسة'),
              ),
              const SizedBox(height: AppTokens.s12),
              DropdownButtonFormField<int>(
                initialValue: _routerId,
                decoration: const InputDecoration(labelText: 'الراوتر'),
                items: [
                  for (final router in widget.routers)
                    DropdownMenuItem(
                      value: router.id,
                      child: Text(
                        router.name.isEmpty ? router.address : router.name,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _routerId = value),
              ),
              const SizedBox(height: AppTokens.s12),
              SwitchListTile(
                value: _enabled,
                contentPadding: EdgeInsets.zero,
                title: const Text('السياسة مفعّلة'),
                onChanged: (value) => setState(() => _enabled = value),
              ),
              if (kind.isRemoteAccess) ...[
                const Divider(height: AppTokens.s24),
                _CheckLine(
                  value: _allowWinbox,
                  label: 'السماح بـ Winbox',
                  onChanged: (v) => setState(() => _allowWinbox = v),
                ),
                _CheckLine(
                  value: _allowSsh,
                  label: 'السماح بـ SSH',
                  onChanged: (v) => setState(() => _allowSsh = v),
                ),
                _CheckLine(
                  value: _allowApi,
                  label: 'السماح بـ API',
                  onChanged: (v) => setState(() => _allowApi = v),
                ),
                _CheckLine(
                  value: _allowApiSsl,
                  label: 'السماح بـ API-SSL',
                  onChanged: (v) => setState(() => _allowApiSsl = v),
                ),
                _CheckLine(
                  value: _allowWebfigHttp,
                  label: 'السماح بـ WebFig HTTP',
                  onChanged: (v) => setState(() => _allowWebfigHttp = v),
                ),
                _CheckLine(
                  value: _allowWebfigHttps,
                  label: 'السماح بـ WebFig HTTPS',
                  onChanged: (v) => setState(() => _allowWebfigHttps = v),
                ),
                const SizedBox(height: AppTokens.s12),
                TextField(
                  controller: _source,
                  decoration: const InputDecoration(
                    labelText: 'قائمة عناوين المصادر الموثوقة',
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                TextField(
                  controller: _expiresAt,
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الانتهاء',
                    hintText: '2026-12-31T23:59:59Z',
                  ),
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: AppTokens.s12),
                TextField(
                  controller: _reason,
                  decoration: const InputDecoration(labelText: 'سبب الفتح'),
                  maxLines: 2,
                ),
              ] else if (kind.isWebBlock) ...[
                const Divider(height: AppTokens.s24),
                SwitchListTile(
                  value: _failOpen,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('عند فشل القاعدة اسمح بدل الحظر'),
                  onChanged: (value) => setState(() => _failOpen = value),
                ),
              ] else ...[
                const Divider(height: AppTokens.s24),
                TextField(
                  controller: _hotspotProfile,
                  decoration: const InputDecoration(
                    labelText: 'Hotspot Profile اختياري',
                  ),
                ),
              ],
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
    final name = _name.text.trim();
    if (name.isEmpty || _routerId == null) {
      _snack(context, 'أدخل اسم السياسة واختر الراوتر');
      return;
    }
    setState(() => _saving = true);
    try {
      final kind = widget.kind;
      final body = <String, dynamic>{
        'name': name,
        'router_id': _routerId,
        'enabled': _enabled,
        if (kind.isRemoteAccess) ...{
          'allow_winbox': _allowWinbox,
          'allow_ssh': _allowSsh,
          'allow_api': _allowApi,
          'allow_api_ssl': _allowApiSsl,
          'allow_webfig_http': _allowWebfigHttp,
          'allow_webfig_https': _allowWebfigHttps,
          'source_address_list': _source.text.trim(),
          'expires_at': _expiresAt.text.trim(),
          'reason': _reason.text.trim(),
        },
        if (kind.isWebBlock) ...{
          'scope': 'all_users',
          'fail_open': _failOpen,
        },
        if (kind.isWalledGarden) ...{
          'hotspot_profile': _hotspotProfile.text.trim(),
        },
      };
      await ref.read(networkPolicyRepositoryProvider).create(kind, body);
      ref.invalidate(networkPolicyPageProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack(context, 'تم حفظ السياسة');
    } catch (error) {
      if (mounted) _snack(context, 'تعذر حفظ السياسة: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      onChanged: (value) => onChanged(value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

IconData _kindIcon(NetworkPolicyKind kind) {
  if (kind.isRemoteAccess) return Icons.admin_panel_settings_outlined;
  if (kind.isWebBlock) return Icons.block_outlined;
  return Icons.verified_user_outlined;
}

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
