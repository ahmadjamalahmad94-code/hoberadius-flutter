import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/admin_alerts_repository.dart';
import '../domain/admin_alerts_model.dart';

/// Telegram admin-alerts page — bot config (masked token), per-alert toggles,
/// test buttons, and a rendered preview. Mirrors the web `alerts/telegram`.
class TelegramAlertsScreen extends ConsumerWidget {
  const TelegramAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(telegramAlertsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'تنبيهات تيليجرام',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.sidebarBg,
                      fontWeight: FontWeight.w800,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(telegramAlertsProvider),
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
            title: 'تعذّر جلب إعدادات التنبيهات',
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

  final TelegramAlertsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final byGroup = <String, List<AlertItem>>{};
    for (final a in snapshot.catalogue) {
      byGroup.putIfAbsent(a.group, () => []).add(a);
    }
    final groups = snapshot.groups.isNotEmpty
        ? snapshot.groups
        : byGroup.keys
            .map((k) => AlertGroup(key: k, label: k, icon: ''))
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BotCard(bot: snapshot.bot),
        const SizedBox(height: AppTokens.s16),
        for (final g in groups)
          if ((byGroup[g.key] ?? const []).isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(
                right: AppTokens.s4,
                bottom: AppTokens.s8,
                top: AppTokens.s8,
              ),
              child: Text(
                g.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppTokens.sidebarBg,
                ),
              ),
            ),
            for (final a in byGroup[g.key]!) ...[
              _AlertTile(alert: a),
              const SizedBox(height: AppTokens.s8),
            ],
          ],
      ],
    );
  }
}

class _BotCard extends ConsumerStatefulWidget {
  const _BotCard({required this.bot});

  final TelegramBot bot;

  @override
  ConsumerState<_BotCard> createState() => _BotCardState();
}

class _BotCardState extends ConsumerState<_BotCard> {
  late final TextEditingController _token;
  late final TextEditingController _chatId;
  late final TextEditingController _threadId;
  late bool _enabled;
  bool _saving = false;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _token = TextEditingController();
    _chatId = TextEditingController(text: widget.bot.chatId);
    _threadId = TextEditingController(text: widget.bot.threadId);
    _enabled = widget.bot.enabled;
  }

  @override
  void dispose() {
    _token.dispose();
    _chatId.dispose();
    _threadId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bot = widget.bot;
    return AppCard(
      title: 'إعداد البوت',
      icon: Icons.smart_toy_outlined,
      actions: [
        StatusPill(
          text: bot.ready ? 'جاهز' : 'غير مكتمل',
          tone: bot.ready ? PillTone.green : PillTone.amber,
          dot: true,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _token,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'توكن البوت',
              prefixIcon: const Icon(Icons.key_outlined),
              helperText: bot.hasToken
                  ? 'محفوظ (${bot.tokenMasked}) — اتركه فارغًا للإبقاء عليه.'
                  : 'الصق توكن البوت من BotFather.',
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatId,
                  decoration: const InputDecoration(
                    labelText: 'معرّف المحادثة (chat_id)',
                    prefixIcon: Icon(Icons.forum_outlined),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: TextField(
                  controller: _threadId,
                  decoration: const InputDecoration(
                    labelText: 'الموضوع (thread)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            title: const Text('تفعيل إرسال التنبيهات'),
          ),
          const SizedBox(height: AppTokens.s8),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
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
              OutlinedButton.icon(
                onPressed: (_testing || !bot.hasToken) ? null : _testConnection,
                icon: _testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: const Text('اختبار الاتصال'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(adminAlertsRepositoryProvider).saveBot(
            botToken: _token.text,
            chatId: _chatId.text,
            threadId: _threadId.text,
            enabled: _enabled,
          );
      _token.clear();
      ref.invalidate(telegramAlertsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ إعداد البوت')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    try {
      await ref.read(adminAlertsRepositoryProvider).testConnection();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال رسالة اختبار بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }
}

class _AlertTile extends ConsumerStatefulWidget {
  const _AlertTile({required this.alert});

  final AlertItem alert;

  @override
  ConsumerState<_AlertTile> createState() => _AlertTileState();
}

class _AlertTileState extends ConsumerState<_AlertTile> {
  late bool _enabled = widget.alert.enabled;
  bool _busy = false;
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
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
                      a.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                      ),
                    ),
                    if (a.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        a.description,
                        style: const TextStyle(
                          color: AppTokens.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              _busy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Switch(
                      value: _enabled,
                      onChanged: (v) => _toggle(v),
                    ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              if (a.preview.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _showPreview = !_showPreview),
                  icon: Icon(
                    _showPreview ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: const Text('معاينة'),
                ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _test,
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('إرسال تجريبي'),
              ),
            ],
          ),
          if (_showPreview && a.preview.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: AppTokens.surfaceMuted,
                borderRadius: BorderRadius.circular(AppTokens.r10),
                border: Border.all(color: AppTokens.border),
              ),
              child: Text(
                a.preview,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTokens.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(adminAlertsRepositoryProvider)
          .toggleAlert(widget.alert.key, value);
      setState(() => _enabled = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() async {
    setState(() => _busy = true);
    try {
      await ref.read(adminAlertsRepositoryProvider).testAlert(widget.alert.key);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال «${widget.alert.label}» تجريبيًا')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
