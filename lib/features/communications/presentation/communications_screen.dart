import 'package:hoberadius_app/core/format/arabic_plural.dart';
import 'package:flutter/material.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
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
          const PreviewOnlyBanner(
            message: 'القوالب تُحفظ وتُعايَن فقط: لا يوجد مُرسِل يستعملها '
                'تلقائيًّا بعد. الإرسال الفعليّ من «إرسال» بنصٍّ تكتبه هناك.',
          ),
          const SizedBox(height: AppTokens.s12),
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
      if (mounted) {
        _snack(
          context,
          'تمت إضافة ${arCount(count, arMessage, showOne: true)} للطابور',
        );
      }
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
        const PreviewOnlyBanner(
          message: 'الحملات تُحضَّر وتُعايَن فقط: لا تُرسَل أيّ رسالة ولا '
              'يُنفَّذ أيّ إجراء من هذه الشاشة.',
        ),
        const SizedBox(height: AppTokens.s12),
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
                      'الرسائل القصيرة تُرسَل عبر حساب TweetSMS المربوط. لواتساب: فعّل القناة فقط بعد إدخال رابط إرسال صحيح من المزود، واستخدم {phone} لرقم الجوال و {msg} لنص الرسالة.',
                      style:
                          TextStyle(color: AppTokens.textMuted, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            for (final item in data.items) ...[
              // SMS = TweetSMS (owner 2026-10-06): status only, no HTTP form.
              if (item.isTweetSms)
                TweetSmsStatusCard(item: item)
              else
                _ChannelConfigCard(item: item, methods: data.methods),
              const SizedBox(height: AppTokens.s12),
            ],
          ],
        );
      },
    );
  }
}

/// «معاينة فقط» — message templates and campaigns have no sender yet (owner
/// 2026-10-06: keep them, but say so plainly, like the web pages).
class PreviewOnlyBanner extends StatelessWidget {
  const PreviewOnlyBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.visibility_outlined,
            size: 18,
            color: Color(0xFF92400E),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'معاينة فقط — ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: message),
                ],
              ),
              style: const TextStyle(color: Color(0xFF92400E), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// The SMS channel: messages go through the tenant's TweetSMS account (the
/// custom «SMS HTTP channel» was retired — owner 2026-10-06). Read-only.
class TweetSmsStatusCard extends StatelessWidget {
  const TweetSmsStatusCard({super.key, required this.item});

  final CommunicationChannel item;

  @override
  Widget build(BuildContext context) {
    final known = item.provider == 'tweetsms';
    return AppCard(
      title: 'الرسائل القصيرة (TweetSMS)',
      icon: Icons.sms_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              if (known)
                StatusPill(
                  text: item.connected ? 'مربوطة' : 'غير مربوطة',
                  tone: item.connected ? PillTone.green : PillTone.neutral,
                  dot: true,
                ),
              if (known && item.connected && item.sender.isNotEmpty)
                StatusPill(
                  text: 'المرسِل: ${item.sender}',
                  tone: PillTone.blue,
                  icon: Icons.badge_outlined,
                ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          const Text(
            'كل رسائل SMS تخرج عبر حساب TweetSMS المربوط. لا يوجد رابط HTTP مخصّص للرسائل القصيرة؛ اربط الحساب أو عدّله من لوحة الويب: «ربط SMS».',
            style: TextStyle(color: AppTokens.textMuted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ChannelConfigCard extends ConsumerStatefulWidget {
  const _ChannelConfigCard({
    required this.item,
    required this.methods,
  });

  final CommunicationChannel item;
  final List<String> methods;

  @override
  ConsumerState<_ChannelConfigCard> createState() => _ChannelConfigCardState();
}

class _ChannelConfigCardState extends ConsumerState<_ChannelConfigCard> {
  late final TextEditingController _sendUrl;
  late bool _enabled;
  late String _method;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sendUrl = TextEditingController();
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
    super.dispose();
  }

  void _resetFromItem() {
    _enabled = widget.item.enabled;
    _method = widget.item.config.httpMethod;
    _sendUrl.text = widget.item.config.sendUrlTemplate;
  }

  @override
  Widget build(BuildContext context) {
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
          // «طريقة التشغيل» removed (owner 2026-10-06): one value, unread.
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'نوع الطلب'),
            items: [
              for (final method in methodOptions)
                DropdownMenuItem(value: method, child: Text(method)),
            ],
            onChanged: (value) => setState(() => _method = value ?? _method),
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
          // «رابط قراءة الرصيد» removed (owner 2026-10-06): never queried.
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
              sendUrlTemplate: _sendUrl.text.trim(),
              httpMethod: _method,
            ),
          );
      _refresh(ref);
      ref.invalidate(communicationChannelsProvider);
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
    final reason = item.errorMessage.trim().isEmpty
        ? ''
        : serverTextOrFallback(
            item.errorMessage,
            fallback: 'تعذّر الإرسال عبر هذه القناة',
          );
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
        [
          '${item.channelLabel} · ${item.recipientLabel} · ${item.createdAtLabel}',
          if (reason.isNotEmpty) reason,
        ].join('\n'),
      ),
      trailing: StatusPill(
        text: item.statusLabel,
        tone: failed
            ? PillTone.red
            : item.status == 'skipped'
                ? PillTone.amber
                : PillTone.blue,
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
      final repo = ref.read(communicationsRepositoryProvider);
      try {
        await repo.createTemplate(
          title: title,
          channel: _channel,
          subject: _subject.text.trim(),
          body: body,
        );
      } on ApiException catch (e) {
        if (e.status != 409 || !mounted) rethrow;
        // Same key exists: replace only when the operator says so.
        final replace = await showDialog<bool>(
          context: context,
          useRootNavigator: true,
          builder: (ctx) => AlertDialog(
            title: const Text('قالب بنفس الاسم موجود'),
            content: Text(
              '${visibleErrorMessage(e)}\nهل تريد استبدال القالب الموجود؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('استبدال'),
              ),
            ],
          ),
        );
        if (replace != true) return;
        await repo.createTemplate(
          title: title,
          channel: _channel,
          subject: _subject.text.trim(),
          body: body,
          overwrite: true,
        );
      }
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
