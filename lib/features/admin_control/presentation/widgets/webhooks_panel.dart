import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/admin_control_providers.dart';
import 'admin_section_common.dart';

class WebhooksPanel extends ConsumerStatefulWidget {
  const WebhooksPanel({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onSaveConfig,
    required this.onTest,
    required this.busy,
  });

  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final Future<void> Function({
    required String targetUrl,
    required String secret,
    required List<String> events,
  }) onSaveConfig;
  final Future<void> Function() onTest;
  final bool busy;

  @override
  ConsumerState<WebhooksPanel> createState() => _WebhooksPanelState();
}

class _WebhooksPanelState extends ConsumerState<WebhooksPanel> {
  final _target = TextEditingController();
  final _secret = TextEditingController();
  final _events = TextEditingController(text: 'webhook.test');

  @override
  void dispose() {
    _target.dispose();
    _secret.dispose();
    _events.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(webhookConfigProvider);
    final deliveries =
        ref.watch(webhookDeliveriesProvider(widget.selectedStatus));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        config.when(
          loading: () => const AdminLoadingCard(title: 'إعدادات Webhook'),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب إعدادات Webhook',
            subtitle: '$e',
          ),
          data: (item) {
            if (_target.text.isEmpty) _target.text = item.targetUrl;
            if (_events.text == 'webhook.test' &&
                item.enabledEvents.isNotEmpty) {
              _events.text = item.enabledEvents.join(',');
            }
            return AppCard(
              title: 'إعدادات Webhook',
              icon: Icons.bolt,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _target,
                    decoration:
                        const InputDecoration(labelText: 'رابط الاستقبال'),
                  ),
                  const SizedBox(height: AppTokens.s8),
                  TextField(
                    controller: _secret,
                    decoration: InputDecoration(
                      labelText:
                          item.secretSet ? 'سر جديد اختياري' : 'سر التوقيع',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: AppTokens.s8),
                  TextField(
                    controller: _events,
                    decoration: const InputDecoration(
                      labelText: 'الأحداث، افصل بينها بفاصلة',
                    ),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  Wrap(
                    spacing: AppTokens.s8,
                    runSpacing: AppTokens.s8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: widget.busy
                            ? null
                            : () => widget.onSaveConfig(
                                  targetUrl: _target.text.trim(),
                                  secret: _secret.text.trim(),
                                  events: _events.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList(),
                                ),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('حفظ'),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.busy ? null : widget.onTest,
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('اختبار الإرسال'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          title: 'سجل الإرسال',
          icon: Icons.receipt_long_outlined,
          actions: [
            DropdownButton<String>(
              value: widget.selectedStatus,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('كل الحالات')),
                DropdownMenuItem(value: 'queued', child: Text('بالانتظار')),
                DropdownMenuItem(
                  value: 'retrying',
                  child: Text('إعادة محاولة'),
                ),
                DropdownMenuItem(
                  value: 'delivered',
                  child: Text('تم الإرسال'),
                ),
                DropdownMenuItem(value: 'failed', child: Text('فشل')),
              ],
              onChanged: (value) {
                if (value != null) widget.onStatusChanged(value);
              },
            ),
          ],
          padding: EdgeInsets.zero,
          child: deliveries.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppTokens.s20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'تعذر جلب سجل الإرسال',
              subtitle: '$e',
            ),
            data: (items) => items.isEmpty
                ? const EmptyState(
                    icon: Icons.bolt_outlined,
                    title: 'لا توجد سجلات إرسال',
                  )
                : AdminListSection(
                    count: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return ListTile(
                        title: Text(item.event),
                        subtitle: Text(
                          [
                            item.eventId,
                            'محاولات: ${item.attempts}',
                            if (item.lastStatusCode > 0)
                              'كود: ${item.lastStatusCode}',
                            if (item.lastResponseExcerpt.isNotEmpty)
                              item.lastResponseExcerpt,
                          ].join(' • '),
                        ),
                        leading: StatusPill(
                          text: deliveryLabel(item.status),
                          tone: deliveryTone(item.status),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
