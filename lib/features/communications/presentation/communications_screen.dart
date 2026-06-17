import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/communications_providers.dart';
import '../data/communications_repository.dart';
import '../domain/communications_model.dart';

class CommunicationsScreen extends ConsumerWidget {
  const CommunicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(communicationsTabProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'مركز التواصل',
          subtitle:
              'قوالب رسائل، شرائح جمهور، إرسال داخلي آمن، ومعاينة حملات بدون تشغيل مزود خارجي تلقائي.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => _refresh(ref),
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
            ElevatedButton.icon(
              onPressed: () => _showTemplateDialog(context, ref),
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('قالب جديد'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        _TabBar(selected: tab),
        const SizedBox(height: AppTokens.s16),
        switch (tab) {
          'templates' => const _TemplatesPanel(),
          'send' => const _SendPanel(),
          'audience' => const _AudiencePanel(),
          'campaigns' => const _CampaignsPanel(),
          'deliveries' => const _DeliveriesPanel(),
          'channels' => const _ChannelsPanel(),
          'whatsapp' => const _WhatsappBridgePanel(),
          'quota' => const _QuotaPanel(),
          _ => const _OverviewPanel(),
        },
      ],
    );
  }
}

class _TabBar extends ConsumerWidget {
  const _TabBar({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tabs = [
      ('overview', 'نظرة عامة', Icons.dashboard_customize_outlined),
      ('templates', 'القوالب', Icons.description_outlined),
      ('send', 'إرسال', Icons.send_outlined),
      ('audience', 'الجمهور', Icons.groups_2_outlined),
      ('campaigns', 'الحملات', Icons.campaign_outlined),
      ('deliveries', 'سجل الإرسال', Icons.local_shipping_outlined),
      ('channels', 'قنوات الإرسال', Icons.settings_input_antenna),
      ('whatsapp', 'واتساب الرسمي', Icons.mark_chat_read_outlined),
      ('quota', 'الرصيد والحزم', Icons.account_balance_wallet_outlined),
    ];
    return AppCard(
      child: Wrap(
        spacing: AppTokens.s8,
        runSpacing: AppTokens.s8,
        children: [
          for (final item in tabs)
            ChoiceChip(
              avatar: Icon(item.$3, size: 16),
              label: Text(item.$2),
              selected: selected == item.$1,
              onSelected: (_) {
                ref.read(communicationsTabProvider.notifier).state = item.$1;
              },
            ),
        ],
      ),
    );
  }
}

class _OverviewPanel extends ConsumerWidget {
  const _OverviewPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(communicationsHomeProvider);
    return home.when(
      loading: () => const _Loading(),
      error: (error, _) => HubErrorState(
        title: 'تعذر تحميل مركز التواصل',
        subtitle: visibleErrorMessage(error),
        onRetry: () => ref.invalidate(communicationsHomeProvider),
      ),
      data: (data) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1040;
          final summary = _SummaryPanel(summary: data.summary);
          final recent = _RecentPanel(home: data);
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                summary,
                const SizedBox(height: AppTokens.s12),
                recent,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 340, child: summary),
              const SizedBox(width: AppTokens.s12),
              Expanded(child: recent),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.summary});

  final CommunicationsSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'ملخص التواصل',
      icon: Icons.insights_outlined,
      child: Column(
        children: [
          _SummaryRow(
            'القوالب',
            summary.templates,
            Icons.description_outlined,
          ),
          const Divider(height: AppTokens.s20),
          _SummaryRow(
            'شرائح الجمهور',
            summary.segments,
            Icons.groups_2_outlined,
          ),
          const Divider(height: AppTokens.s20),
          _SummaryRow(
            'في الطابور',
            summary.queued,
            Icons.schedule_send_outlined,
          ),
          const Divider(height: AppTokens.s20),
          _SummaryRow(
            'فشل الإرسال',
            summary.failed,
            Icons.error_outline,
          ),
        ],
      ),
    );
  }
}

class _RecentPanel extends StatelessWidget {
  const _RecentPanel({required this.home});

  final CommunicationsHome home;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppCard(
          child: Row(
            children: [
              StatusPill(
                text: 'وضع آمن',
                tone: PillTone.blue,
                icon: Icons.verified_user_outlined,
              ),
              SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'الرسائل تحفظ في الطابور أولًا. الإرسال الخارجي يحتاج ربط مزود فعلي من إعدادات الخادم.',
                  style: TextStyle(color: AppTokens.textMuted, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        _TemplateList(title: 'أحدث القوالب', items: home.templates),
        const SizedBox(height: AppTokens.s12),
        _DeliveryList(title: 'أحدث عمليات الإرسال', items: home.deliveries),
      ],
    );
  }
}

class _TemplatesPanel extends ConsumerWidget {
  const _TemplatesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(messageTemplatesProvider);
    return templates.when(
      loading: () => const _Loading(),
      error: (error, _) => HubErrorState(
        title: 'تعذر تحميل القوالب',
        subtitle: visibleErrorMessage(error),
        onRetry: () => ref.invalidate(messageTemplatesProvider),
      ),
      data: (page) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ElevatedButton.icon(
              onPressed: () => _showTemplateDialog(context, ref),
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('قالب جديد'),
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          _TemplateList(title: 'قوالب الرسائل', items: page.items),
        ],
      ),
    );
  }
}

class _SendPanel extends ConsumerStatefulWidget {
  const _SendPanel();

  @override
  ConsumerState<_SendPanel> createState() => _SendPanelState();
}

class _SendPanelState extends ConsumerState<_SendPanel> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  final _ids = TextEditingController();
  String _target = 'subscriber';
  String _channel = 'internal';
  bool _busy = false;
  AudiencePreview? _preview;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    _ids.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'إرسال رسالة',
      icon: Icons.send_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AudienceFields(
            target: _target,
            ids: _ids,
            onTargetChanged: (value) => setState(() => _target = value),
          ),
          const SizedBox(height: AppTokens.s12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _channel,
            decoration: const InputDecoration(labelText: 'القناة'),
            items: _channelItems(),
            onChanged: (value) => setState(() => _channel = value ?? _channel),
          ),
          const SizedBox(height: AppTokens.s12),
          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'العنوان'),
          ),
          const SizedBox(height: AppTokens.s12),
          TextField(
            controller: _message,
            decoration: const InputDecoration(labelText: 'نص الرسالة'),
            minLines: 3,
            maxLines: 6,
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _previewAudience,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('معاينة الجمهور'),
              ),
              FilledButton.icon(
                onPressed: _busy ? null : _send,
                icon: const Icon(Icons.schedule_send_outlined),
                label: const Text('إضافة للطابور'),
              ),
            ],
          ),
          if (_preview != null) ...[
            const Divider(height: AppTokens.s24),
            _RecipientsPreview(preview: _preview!),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _audience() => {
        'target': _target,
        'ids': _ids.text.trim(),
        'limit': 100,
      };

  Future<void> _previewAudience() async {
    setState(() => _busy = true);
    try {
      final preview = await ref
          .read(communicationsRepositoryProvider)
          .previewAudience(_audience());
      if (mounted) setState(() => _preview = preview);
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final message = _message.text.trim();
    if (message.isEmpty) {
      _snack(context, 'أدخل نص الرسالة أولًا');
      return;
    }
    setState(() => _busy = true);
    try {
      final count = await ref.read(communicationsRepositoryProvider).sendManual(
            channel: _channel,
            subject: _subject.text.trim(),
            message: message,
            audience: _audience(),
          );
      _refresh(ref);
      if (mounted) _snack(context, 'تمت إضافة $count رسالة للطابور');
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _AudiencePanel extends ConsumerStatefulWidget {
  const _AudiencePanel();

  @override
  ConsumerState<_AudiencePanel> createState() => _AudiencePanelState();
}

class _AudiencePanelState extends ConsumerState<_AudiencePanel> {
  final _title = TextEditingController();
  final _ids = TextEditingController();
  String _target = 'subscriber';
  bool _busy = false;
  AudiencePreview? _preview;

  @override
  void dispose() {
    _title.dispose();
    _ids.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segments = ref.watch(audienceSegmentsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          title: 'بناء جمهور',
          icon: Icons.groups_2_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'اسم الشريحة'),
              ),
              const SizedBox(height: AppTokens.s12),
              _AudienceFields(
                target: _target,
                ids: _ids,
                onTargetChanged: (value) => setState(() => _target = value),
              ),
              const SizedBox(height: AppTokens.s12),
              Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _previewAudience,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('معاينة'),
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _saveSegment,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('حفظ الشريحة'),
                  ),
                ],
              ),
              if (_preview != null) ...[
                const Divider(height: AppTokens.s24),
                _RecipientsPreview(preview: _preview!),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        segments.when(
          loading: () => const _Loading(),
          error: (error, _) => HubErrorState(
            title: 'تعذر تحميل شرائح الجمهور',
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(audienceSegmentsProvider),
          ),
          data: (page) => _SegmentList(items: page.items),
        ),
      ],
    );
  }

  Map<String, dynamic> _audience() => {
        'target': _target,
        'ids': _ids.text.trim(),
        'limit': 100,
      };

  Future<void> _previewAudience() async {
    setState(() => _busy = true);
    try {
      final preview = await ref
          .read(communicationsRepositoryProvider)
          .previewAudience(_audience());
      if (mounted) setState(() => _preview = preview);
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveSegment() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _snack(context, 'أدخل اسم الشريحة');
      return;
    }
    setState(() => _busy = true);
    try {
      final preview =
          await ref.read(communicationsRepositoryProvider).createSegment(
                title: title,
                audience: _audience(),
              );
      _refresh(ref);
      if (mounted) setState(() => _preview = preview);
      if (mounted) _snack(context, 'تم حفظ الشريحة');
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _CampaignsPanel extends ConsumerStatefulWidget {
  const _CampaignsPanel();

  @override
  ConsumerState<_CampaignsPanel> createState() => _CampaignsPanelState();
}

class _CampaignsPanelState extends ConsumerState<_CampaignsPanel> {
  final _title = TextEditingController();
  final _ids = TextEditingController();
  String _target = 'subscriber';
  int? _templateId;
  bool _recordEvent = true;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _ids.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(messageTemplatesProvider);
    final campaigns = ref.watch(campaignsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        templates.when(
          loading: () => const _Loading(),
          error: (error, _) => HubErrorState(
            title: 'تعذر تحميل القوالب',
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(messageTemplatesProvider),
          ),
          data: (page) => AppCard(
            title: 'تجهيز معاينة حملة بدون إرسال',
            icon: Icons.campaign_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (page.items.isEmpty)
                  const EmptyState(
                    icon: Icons.description_outlined,
                    title: 'أنشئ قالبًا أولًا',
                    subtitle:
                        'الحملة تحتاج قالب رسالة حتى يتم حساب الجمهور ومراجعة خطة الإرسال.',
                  )
                else ...[
                  TextField(
                    controller: _title,
                    decoration:
                        const InputDecoration(labelText: 'عنوان الحملة'),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _templateId ?? page.items.first.id,
                    decoration: const InputDecoration(labelText: 'القالب'),
                    items: [
                      for (final template in page.items)
                        DropdownMenuItem(
                          value: template.id,
                          child: Text(template.title),
                        ),
                    ],
                    onChanged: (value) => setState(() => _templateId = value),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  _AudienceFields(
                    target: _target,
                    ids: _ids,
                    onTargetChanged: (value) => setState(() => _target = value),
                  ),
                  CheckboxListTile(
                    value: _recordEvent,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تسجيل حدث متابعة ضمن الخطة'),
                    onChanged: (value) {
                      setState(() => _recordEvent = value ?? true);
                    },
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _dryRun(page.items),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('تجهيز المعاينة'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        campaigns.when(
          loading: () => const _Loading(),
          error: (error, _) => HubErrorState(
            title: 'تعذر تحميل الحملات',
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(campaignsProvider),
          ),
          data: (page) => _CampaignList(items: page.items),
        ),
      ],
    );
  }

  Future<void> _dryRun(List<MessageTemplate> templates) async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _snack(context, 'أدخل عنوان الحملة');
      return;
    }
    final templateId = _templateId ?? templates.first.id;
    setState(() => _busy = true);
    try {
      final campaign =
          await ref.read(communicationsRepositoryProvider).dryRunCampaign(
                title: title,
                templateId: templateId,
                audience: {
                  'target': _target,
                  'ids': _ids.text.trim(),
                  'limit': 100,
                },
                actions: _recordEvent ? ['record_event'] : const [],
              );
      _refresh(ref);
      if (mounted) {
        _snack(context, 'تم تجهيز حملة لـ ${campaign.recipientCount} مستلم');
      }
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DeliveriesPanel extends ConsumerWidget {
  const _DeliveriesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveries = ref.watch(messageDeliveriesProvider);
    return deliveries.when(
      loading: () => const _Loading(),
      error: (error, _) => HubErrorState(
        title: 'تعذر تحميل سجل الإرسال',
        subtitle: visibleErrorMessage(error),
        onRetry: () => ref.invalidate(messageDeliveriesProvider),
      ),
      data: (page) => _DeliveryList(title: 'سجل الإرسال', items: page.items),
    );
  }
}

class _ChannelsPanel extends ConsumerWidget {
  const _ChannelsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(communicationChannelsProvider);
    return page.when(
      loading: () => const _Loading(),
      error: (error, _) => HubErrorState(
        title: 'تعذر تحميل قنوات الإرسال',
        subtitle: visibleErrorMessage(error),
        onRetry: () => ref.invalidate(communicationChannelsProvider),
      ),
      data: (data) {
        if (data.items.isEmpty) {
          return const EmptyState(
            icon: Icons.settings_input_antenna,
            title: 'لا توجد قنوات قابلة للضبط',
            subtitle:
                'عند توفر قناة إرسال من الخادم ستظهر هنا لتفعيلها وضبط رابط المزود.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppCard(
              child: Row(
                children: [
                  StatusPill(
                    text: 'إعداد إنتاجي',
                    tone: PillTone.blue,
                    icon: Icons.verified_user_outlined,
                  ),
                  SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: Text(
                      'فعّل القناة فقط بعد إدخال رابط إرسال صحيح من مزود الرسائل. استخدم {phone} لرقم الجوال و {msg} لنص الرسالة داخل رابط المزود.',
                      style:
                          TextStyle(color: AppTokens.textMuted, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            for (final item in data.items) ...[
              _ChannelConfigCard(
                item: item,
                modes: data.modes,
                methods: data.methods,
              ),
              const SizedBox(height: AppTokens.s12),
            ],
          ],
        );
      },
    );
  }
}

class _ChannelConfigCard extends ConsumerStatefulWidget {
  const _ChannelConfigCard({
    required this.item,
    required this.modes,
    required this.methods,
  });

  final CommunicationChannel item;
  final List<CommunicationModeOption> modes;
  final List<String> methods;

  @override
  ConsumerState<_ChannelConfigCard> createState() => _ChannelConfigCardState();
}

class _ChannelConfigCardState extends ConsumerState<_ChannelConfigCard> {
  late final TextEditingController _sendUrl;
  late final TextEditingController _balanceUrl;
  late bool _enabled;
  late String _mode;
  late String _method;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sendUrl = TextEditingController();
    _balanceUrl = TextEditingController();
    _resetFromItem();
  }

  @override
  void didUpdateWidget(covariant _ChannelConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.channel != widget.item.channel) {
      _resetFromItem();
    }
  }

  @override
  void dispose() {
    _sendUrl.dispose();
    _balanceUrl.dispose();
    super.dispose();
  }

  void _resetFromItem() {
    _enabled = widget.item.enabled;
    _mode = widget.item.mode;
    _method = widget.item.config.httpMethod;
    _sendUrl.text = widget.item.config.sendUrlTemplate;
    _balanceUrl.text = widget.item.config.balanceUrl;
  }

  @override
  Widget build(BuildContext context) {
    final modeOptions = widget.modes.isEmpty
        ? const [
            CommunicationModeOption(
              key: 'self_api',
              label: 'ربط مباشر من العميل',
            ),
            CommunicationModeOption(
              key: 'admin_quota',
              label: 'رصيد مخصص من الإدارة',
            ),
          ]
        : widget.modes;
    if (!modeOptions.any((item) => item.key == _mode)) {
      _mode = modeOptions.first.key;
    }
    final methodOptions =
        widget.methods.isEmpty ? const ['GET', 'POST'] : widget.methods;
    if (!methodOptions.contains(_method)) {
      _method = methodOptions.first;
    }
    return AppCard(
      title: widget.item.label,
      icon: Icons.settings_input_antenna,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusPill(
                text: widget.item.statusLabel,
                tone: _channelTone(widget.item),
                dot: true,
              ),
              StatusPill(
                text: widget.item.modeLabel,
                tone: widget.item.quota.isQuotaMode
                    ? PillTone.amber
                    : PillTone.blue,
                icon: widget.item.quota.isQuotaMode
                    ? Icons.account_balance_wallet_outlined
                    : Icons.link_outlined,
              ),
              StatusPill(
                text: 'الرصيد ${widget.item.quota.balance}',
                tone: PillTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          SwitchListTile.adaptive(
            value: _enabled,
            contentPadding: EdgeInsets.zero,
            title: const Text('تفعيل القناة'),
            subtitle: const Text(
              'عند الإيقاف لن تستخدم هذه القناة في إرسال الرسائل الخارجية.',
            ),
            onChanged: (value) => setState(() => _enabled = value),
          ),
          const SizedBox(height: AppTokens.s12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;
              final modeField = DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _mode,
                decoration: const InputDecoration(labelText: 'طريقة التشغيل'),
                items: [
                  for (final mode in modeOptions)
                    DropdownMenuItem(value: mode.key, child: Text(mode.label)),
                ],
                onChanged: (value) => setState(() => _mode = value ?? _mode),
              );
              final methodField = DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'نوع الطلب'),
                items: [
                  for (final method in methodOptions)
                    DropdownMenuItem(value: method, child: Text(method)),
                ],
                onChanged: (value) =>
                    setState(() => _method = value ?? _method),
              );
              if (!wide) {
                return Column(
                  children: [
                    modeField,
                    const SizedBox(height: AppTokens.s12),
                    methodField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: modeField),
                  const SizedBox(width: AppTokens.s12),
                  SizedBox(width: 150, child: methodField),
                ],
              );
            },
          ),
          const SizedBox(height: AppTokens.s12),
          TextField(
            controller: _sendUrl,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'رابط إرسال الرسائل من المزود',
              hintText: 'https://provider.example/send?to={phone}&text={msg}',
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          TextField(
            controller: _balanceUrl,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'رابط قراءة الرصيد من المزود عند الحاجة',
              hintText: 'https://provider.example/balance',
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'جار الحفظ' : 'حفظ إعدادات القناة'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(communicationsRepositoryProvider).saveChannel(
            CommunicationChannelDraft(
              channel: widget.item.channel,
              enabled: _enabled,
              mode: _mode,
              sendUrlTemplate: _sendUrl.text.trim(),
              httpMethod: _method,
              balanceUrl: _balanceUrl.text.trim(),
            ),
          );
      _refresh(ref);
      ref.invalidate(communicationChannelsProvider);
      ref.invalidate(communicationQuotaProvider);
      if (mounted) _snack(context, 'تم حفظ إعدادات ${widget.item.label}');
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTokens.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: AppTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsappBridgePanel extends ConsumerWidget {
  const _WhatsappBridgePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(whatsappBridgeProvider);
    return page.when(
      loading: () => const _Loading(),
      error: (error, _) => HubErrorState(
        title: 'تعذر تحميل إعدادات واتساب',
        subtitle: visibleErrorMessage(error),
        onRetry: () => ref.invalidate(whatsappBridgeProvider),
      ),
      data: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WhatsappStatusCard(state: state),
          const SizedBox(height: AppTokens.s12),
          _WhatsappEventsCard(events: state.events),
          const SizedBox(height: AppTokens.s12),
          const _WhatsappTestCard(),
        ],
      ),
    );
  }
}

class _WhatsappStatusCard extends StatelessWidget {
  const _WhatsappStatusCard({required this.state});

  final WhatsappBridgeState state;

  @override
  Widget build(BuildContext context) {
    final status = state.status;
    final tone = !status.ok
        ? PillTone.red
        : status.connected
            ? PillTone.green
            : PillTone.amber;
    return AppCard(
      title: 'حالة الربط الرسمي',
      icon: Icons.mark_chat_read_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              StatusPill(
                text: status.onboardingLabel,
                tone: tone,
                dot: true,
              ),
              StatusPill(
                text: status.enabled ? 'الإرسال مفعّل' : 'الإرسال غير مفعّل',
                tone: status.enabled ? PillTone.green : PillTone.neutral,
              ),
              if (status.business.isNotEmpty)
                StatusPill(text: status.business, tone: PillTone.brand),
              if (status.phone.isNotEmpty)
                StatusPill(text: status.phone, tone: PillTone.blue),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Text(
            status.ok
                ? 'الربط الرسمي وإرسال الرسائل تتم إدارتهما من لوحة التراخيص. الريدياس هنا يحدد فقط أنواع الرسائل المسموح بطلب إرسالها.'
                : 'تعذر جلب حالة واتساب من لوحة التراخيص. تأكد من رابط لوحة التراخيص وسر الربط في ملف الترخيص ثم حدّث الصفحة.',
            style:
                const TextStyle(color: AppTokens.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _MiniMetric('المُرسَل', status.sentLabel),
              _MiniMetric('المتبقي', status.remainingLabel),
              _MiniMetric('الحد المتاح', status.limitLabel),
            ],
          ),
          if (state.panelPortalUrl.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            SelectableText(
              'إدارة الربط من لوحة التراخيص: ${state.panelPortalUrl}',
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: AppTokens.textMuted),
            ),
          ],
          if (state.principles.isNotEmpty) ...[
            const Divider(height: AppTokens.s24),
            for (final line in state.principles)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppTokens.greenInk,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: AppTokens.textSecondary,
                          height: 1.35,
                        ),
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
}

class _WhatsappEventsCard extends ConsumerStatefulWidget {
  const _WhatsappEventsCard({required this.events});

  final List<WhatsappBridgeEvent> events;

  @override
  ConsumerState<_WhatsappEventsCard> createState() =>
      _WhatsappEventsCardState();
}

class _WhatsappEventsCardState extends ConsumerState<_WhatsappEventsCard> {
  late Map<String, bool> _toggles;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load(widget.events);
  }

  @override
  void didUpdateWidget(covariant _WhatsappEventsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events) _load(widget.events);
  }

  void _load(List<WhatsappBridgeEvent> events) {
    _toggles = {for (final event in events) event.key: event.enabled};
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'أنواع الرسائل المسموح بها',
      icon: Icons.rule_folder_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'فعّل فقط أنواع الرسائل المتفق عليها. هذه مفاتيح سماح محلية ولا تحتوي على أي بيانات ربط أو أسرار.',
            style: TextStyle(color: AppTokens.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppTokens.s8),
          for (final event in widget.events)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _toggles[event.key] ?? false,
              title: Text(event.label),
              subtitle: Text(event.help),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _toggles[event.key] = value),
            ),
          const SizedBox(height: AppTokens.s12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'جار الحفظ' : 'حفظ السماح'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(communicationsRepositoryProvider)
          .saveWhatsappToggles(_toggles);
      ref.invalidate(whatsappBridgeProvider);
      if (mounted) {
        _snack(
          context,
          result.message.isEmpty ? 'تم حفظ إعدادات واتساب' : result.message,
        );
      }
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _WhatsappTestCard extends ConsumerStatefulWidget {
  const _WhatsappTestCard();

  @override
  ConsumerState<_WhatsappTestCard> createState() => _WhatsappTestCardState();
}

class _WhatsappTestCardState extends ConsumerState<_WhatsappTestCard> {
  final _phone = TextEditingController();
  final _template = TextEditingController();
  final _language = TextEditingController(text: 'ar');
  bool _sending = false;

  @override
  void dispose() {
    _phone.dispose();
    _template.dispose();
    _language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'رسالة اختبار',
      icon: Icons.send_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'يتم إرسال الاختبار عبر لوحة التراخيص فقط. لا يرسل تطبيق الريدياس أي رسالة واتساب مباشرة.',
            style: TextStyle(color: AppTokens.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppTokens.s12),
          TextField(
            controller: _phone,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم المستلم بصيغة دولية',
              hintText: '970599000000',
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 620;
              final template = TextField(
                controller: _template,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'اسم قالب الاختبار السحابي',
                  hintText: 'اختياري',
                ),
              );
              final language = TextField(
                controller: _language,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'لغة القالب',
                  hintText: 'ar',
                ),
              );
              if (!wide) {
                return Column(
                  children: [
                    template,
                    const SizedBox(height: AppTokens.s12),
                    language,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: template),
                  const SizedBox(width: AppTokens.s12),
                  SizedBox(width: 160, child: language),
                ],
              );
            },
          ),
          const SizedBox(height: AppTokens.s16),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              FilledButton.icon(
                onPressed: _sending ? null : () => _send(cloud: false),
                icon: const Icon(Icons.mark_chat_read_outlined),
                label: Text(_sending ? 'جار الإرسال' : 'إرسال اختبار'),
              ),
              OutlinedButton.icon(
                onPressed: _sending ? null : () => _send(cloud: true),
                icon: const Icon(Icons.cloud_outlined),
                label: const Text('اختبار الربط السحابي'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _send({required bool cloud}) async {
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      _snack(context, 'أدخل رقم هاتف لإرسال رسالة الاختبار');
      return;
    }
    setState(() => _sending = true);
    try {
      final repo = ref.read(communicationsRepositoryProvider);
      final message = cloud
          ? await repo.sendWhatsappCloudTest(
              recipientPhone: phone,
              templateName: _template.text.trim(),
              language: _language.text.trim(),
            )
          : await repo.sendWhatsappTest(phone);
      if (mounted) {
        _snack(context, message.isEmpty ? 'تم إرسال رسالة الاختبار' : message);
      }
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _QuotaPanel extends ConsumerWidget {
  const _QuotaPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(communicationQuotaProvider);
    return page.when(
      loading: () => const _Loading(),
      error: (error, _) => HubErrorState(
        title: 'تعذر تحميل رصيد الرسائل',
        subtitle: visibleErrorMessage(error),
        onRetry: () => ref.invalidate(communicationQuotaProvider),
      ),
      data: (data) {
        if (data.items.isEmpty) {
          return const EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'لا يوجد رصيد رسائل',
            subtitle:
                'القنوات التي تعمل بنظام رصيد الإدارة ستظهر هنا لمتابعة الاستهلاك وإضافة رصيد.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in data.items) ...[
              _QuotaCard(item: item),
              const SizedBox(height: AppTokens.s12),
            ],
          ],
        );
      },
    );
  }
}

class _QuotaCard extends ConsumerStatefulWidget {
  const _QuotaCard({required this.item});

  final CommunicationQuotaStatus item;

  @override
  ConsumerState<_QuotaCard> createState() => _QuotaCardState();
}

class _QuotaCardState extends ConsumerState<_QuotaCard> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: widget.item.label,
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              StatusPill(
                text: widget.item.modeLabel,
                tone: widget.item.isQuotaMode ? PillTone.amber : PillTone.blue,
                icon: widget.item.isQuotaMode
                    ? Icons.account_balance_wallet_outlined
                    : Icons.link_outlined,
              ),
              StatusPill(
                text: 'المتوفر ${widget.item.balance}',
                tone: PillTone.green,
                dot: true,
              ),
              StatusPill(
                text: 'المستخدم ${widget.item.used}',
                tone: PillTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          if (widget.item.isQuotaMode) ...[
            const Text(
              'هذه القناة تستخدم رصيدًا مخصصًا من الإدارة. أضف عدد الرسائل المتفق عليه بعد الدفع أو الموافقة.',
              style: TextStyle(color: AppTokens.textMuted, height: 1.35),
            ),
            const SizedBox(height: AppTokens.s12),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final amountField = TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'عدد الرسائل',
                    hintText: '100',
                  ),
                );
                final noteField = TextField(
                  controller: _note,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة داخلية',
                    hintText: 'مثال: دفعة شهرية أو تجربة مجانية',
                  ),
                );
                final button = FilledButton.icon(
                  onPressed: _saving ? null : _credit,
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(_saving ? 'جار الإضافة' : 'إضافة رصيد'),
                );
                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      amountField,
                      const SizedBox(height: AppTokens.s12),
                      noteField,
                      const SizedBox(height: AppTokens.s12),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: button,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    SizedBox(width: 170, child: amountField),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(child: noteField),
                    const SizedBox(width: AppTokens.s12),
                    button,
                  ],
                );
              },
            ),
          ] else
            const Text(
              'هذه القناة تعمل بربط مباشر من العميل ولا تستهلك رصيدًا محليًا من الإدارة.',
              style: TextStyle(color: AppTokens.textMuted, height: 1.35),
            ),
          const Divider(height: AppTokens.s24),
          Text(
            'آخر الحركات',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppTokens.s8),
          if (widget.item.ledger.isEmpty)
            const Text(
              'لا توجد حركات رصيد بعد.',
              style: TextStyle(color: AppTokens.textMuted),
            )
          else
            for (final entry in widget.item.ledger.take(6))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: entry.delta >= 0
                      ? AppTokens.greenSoft
                      : AppTokens.redSoft,
                  child: Icon(
                    entry.delta >= 0
                        ? Icons.add_outlined
                        : Icons.remove_outlined,
                    color: entry.delta >= 0
                        ? AppTokens.greenInk
                        : AppTokens.redInk,
                  ),
                ),
                title: Text(
                  '${entry.delta >= 0 ? '+' : ''}${entry.delta} رسالة',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  [
                    if (entry.note.isNotEmpty) entry.note,
                    'الرصيد بعد الحركة ${entry.balanceAfter}',
                    entry.tsLabel,
                  ].join(' · '),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _credit() async {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) {
      _snack(context, 'أدخل عدد رسائل صحيحًا أكبر من صفر');
      return;
    }
    setState(() => _saving = true);
    try {
      final result =
          await ref.read(communicationsRepositoryProvider).creditQuota(
                channel: widget.item.channel,
                amount: amount,
                note: _note.text.trim(),
              );
      ref.invalidate(communicationQuotaProvider);
      ref.invalidate(communicationChannelsProvider);
      ref.invalidate(communicationsHomeProvider);
      _amount.clear();
      _note.clear();
      if (mounted) {
        _snack(
          context,
          result.message.isEmpty ? 'تمت إضافة الرصيد' : result.message,
        );
      }
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AudienceFields extends StatelessWidget {
  const _AudienceFields({
    required this.target,
    required this.ids,
    required this.onTargetChanged,
  });

  final String target;
  final TextEditingController ids;
  final ValueChanged<String> onTargetChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: target,
          decoration: const InputDecoration(labelText: 'الجمهور'),
          items: _targetItems(),
          onChanged: (value) => onTargetChanged(value ?? target),
        ),
        const SizedBox(height: AppTokens.s12),
        TextField(
          controller: ids,
          decoration: const InputDecoration(
            labelText: 'أرقام محددة عند الحاجة',
            hintText: 'مثال: 1,2,3',
          ),
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}

class _TemplateList extends StatelessWidget {
  const _TemplateList({required this.title, required this.items});

  final String title;
  final List<MessageTemplate> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.description_outlined,
        title: 'لا توجد قوالب بعد',
        subtitle: 'أنشئ قالب رسالة واضحًا لاستخدامه في الإرسال والحملات.',
      );
    }
    return AppCard(
      title: title,
      icon: Icons.description_outlined,
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) => _TemplateTile(item: items[index]),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.item});

  final MessageTemplate item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppTokens.brandSoft,
        child: Icon(Icons.description_outlined, color: AppTokens.brandInk),
      ),
      title: Text(
        item.title.isEmpty ? 'قالب رسالة' : item.title,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        [
          item.channelLabel,
          if (item.subject.isNotEmpty) item.subject,
          item.statusLabel,
        ].join(' · '),
      ),
      trailing: const Icon(Icons.chevron_left, color: AppTokens.textMuted),
    );
  }
}

class _SegmentList extends StatelessWidget {
  const _SegmentList({required this.items});

  final List<AudienceSegment> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.groups_2_outlined,
        title: 'لا توجد شرائح محفوظة',
        subtitle: 'احفظ شريحة جمهور لاستخدامها مباشرة عند إنشاء الحملات.',
      );
    }
    return AppCard(
      title: 'شرائح الجمهور',
      icon: Icons.groups_2_outlined,
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final item = items[index];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTokens.greenSoft,
              child: Icon(Icons.groups_2_outlined, color: AppTokens.greenInk),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text('${item.targetLabel} · ${item.statusLabel}'),
          );
        },
      ),
    );
  }
}

class _DeliveryList extends StatelessWidget {
  const _DeliveryList({required this.title, required this.items});

  final String title;
  final List<MessageDelivery> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'لا توجد عمليات إرسال',
        subtitle: 'عند إضافة رسالة للطابور سيظهر سجلها هنا.',
      );
    }
    return AppCard(
      title: title,
      icon: Icons.local_shipping_outlined,
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) => _DeliveryTile(item: items[index]),
      ),
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  const _DeliveryTile({required this.item});

  final MessageDelivery item;

  @override
  Widget build(BuildContext context) {
    final failed = item.status == 'failed';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: failed ? AppTokens.redSoft : AppTokens.blueSoft,
        child: Icon(
          failed ? Icons.error_outline : Icons.schedule_send_outlined,
          color: failed ? AppTokens.redInk : AppTokens.blueInk,
        ),
      ),
      title: Text(
        item.subject.isEmpty ? item.body : item.subject,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        '${item.channelLabel} · ${item.recipientLabel} · ${item.createdAtLabel}',
      ),
      trailing: StatusPill(
        text: item.statusLabel,
        tone: failed ? PillTone.red : PillTone.blue,
        dot: true,
      ),
    );
  }
}

class _CampaignList extends StatelessWidget {
  const _CampaignList({required this.items});

  final List<MessageCampaign> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.campaign_outlined,
        title: 'لا توجد حملات محفوظة',
        subtitle: 'جهز معاينة حملة حتى تظهر هنا للمراجعة قبل الإرسال الفعلي.',
      );
    }
    return AppCard(
      title: 'الحملات',
      icon: Icons.campaign_outlined,
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final item = items[index];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTokens.amberSoft,
              child: Icon(Icons.campaign_outlined, color: AppTokens.amberInk),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              '${item.channelLabel} · ${item.recipientCount} مستلم · إرسال خارجي: ${item.externalSend ? 'نعم' : 'لا'}',
            ),
            trailing: StatusPill(text: item.statusLabel, tone: PillTone.amber),
          );
        },
      ),
    );
  }
}

class _RecipientsPreview extends StatelessWidget {
  const _RecipientsPreview({required this.preview});

  final AudiencePreview preview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'المستلمون (${preview.count})',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppTokens.s8),
        if (preview.items.isEmpty)
          const Text(
            'لا يوجد مستلمون مطابقون.',
            style: TextStyle(color: AppTokens.textMuted),
          )
        else
          for (final item in preview.items.take(8))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(
                item.displayName.isEmpty ? item.typeLabel : item.displayName,
              ),
              subtitle: Text('${item.typeLabel} #${item.recipientId}'),
            ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, this.icon);

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTokens.brandSoft,
          child: Icon(icon, size: 16, color: AppTokens.brandInk),
        ),
        const SizedBox(width: AppTokens.s8),
        Expanded(
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppTokens.s40),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _TemplateDialog extends ConsumerStatefulWidget {
  const _TemplateDialog();

  @override
  ConsumerState<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends ConsumerState<_TemplateDialog> {
  final _title = TextEditingController();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  String _channel = 'internal';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('قالب رسالة جديد'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'اسم القالب'),
              ),
              const SizedBox(height: AppTokens.s12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _channel,
                decoration: const InputDecoration(labelText: 'القناة'),
                items: _channelItems(),
                onChanged: (value) =>
                    setState(() => _channel = value ?? _channel),
              ),
              const SizedBox(height: AppTokens.s12),
              TextField(
                controller: _subject,
                decoration: const InputDecoration(labelText: 'عنوان مختصر'),
              ),
              const SizedBox(height: AppTokens.s12),
              TextField(
                controller: _body,
                decoration: const InputDecoration(labelText: 'نص القالب'),
                minLines: 4,
                maxLines: 7,
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
          icon: const Icon(Icons.save_outlined),
          label: const Text('حفظ'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) {
      _snack(context, 'أدخل اسم القالب ونصه');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(communicationsRepositoryProvider).createTemplate(
            title: title,
            channel: _channel,
            subject: _subject.text.trim(),
            body: body,
          );
      _refresh(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack(context, 'تم حفظ القالب');
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

List<DropdownMenuItem<String>> _channelItems() {
  const values = ['internal', 'sms', 'whatsapp', 'telegram', 'email', 'push'];
  return [
    for (final value in values)
      DropdownMenuItem(
        value: value,
        child: Text(communicationChannelLabel(value)),
      ),
  ];
}

List<DropdownMenuItem<String>> _targetItems() {
  const values = [
    'subscriber',
    'card_user',
    'manager',
    'distributor',
    'company',
  ];
  return [
    for (final value in values)
      DropdownMenuItem(
        value: value,
        child: Text(communicationTargetLabel(value)),
      ),
  ];
}

Future<void> _showTemplateDialog(BuildContext context, WidgetRef ref) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const _TemplateDialog(),
  );
}

void _refresh(WidgetRef ref) {
  ref.invalidate(communicationsHomeProvider);
  ref.invalidate(messageTemplatesProvider);
  ref.invalidate(audienceSegmentsProvider);
  ref.invalidate(messageDeliveriesProvider);
  ref.invalidate(communicationChannelsProvider);
  ref.invalidate(communicationQuotaProvider);
  ref.invalidate(whatsappBridgeProvider);
  ref.invalidate(campaignsProvider);
}

PillTone _channelTone(CommunicationChannel item) {
  if (!item.enabled) return PillTone.neutral;
  return item.active ? PillTone.green : PillTone.amber;
}

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
