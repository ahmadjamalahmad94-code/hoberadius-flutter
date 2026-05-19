import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/audit_repository.dart';
import '../domain/audit_model.dart';

class AuditListScreen extends ConsumerStatefulWidget {
  const AuditListScreen({super.key});

  @override
  ConsumerState<AuditListScreen> createState() => _AuditListScreenState();
}

class _AuditListScreenState extends ConsumerState<AuditListScreen> {
  String? _targetType;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final q = AuditQuery(
      actor: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      targetType: _targetType,
    );
    ref.read(auditQueryProvider.notifier).state = q;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(auditListProvider);
    final df = DateFormat('yyyy-MM-dd HH:mm:ss');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'سجل التدقيق',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.navy900,
                  ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () => ref.invalidate(auditListProvider),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'فلتر بالـ actor (مثال: admin)…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _applyFilters(),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              DropdownButton<String?>(
                value: _targetType,
                hint: const Text('النوع'),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: null, child: Text('كل الأنواع')),
                  DropdownMenuItem(value: 'admin', child: Text('admin')),
                  DropdownMenuItem(value: 'role', child: Text('role')),
                  DropdownMenuItem(value: 'user', child: Text('user')),
                  DropdownMenuItem(value: 'plan', child: Text('plan')),
                  DropdownMenuItem(value: 'card_batch', child: Text('card_batch')),
                  DropdownMenuItem(value: 'card', child: Text('card')),
                  DropdownMenuItem(value: 'nas', child: Text('nas')),
                  DropdownMenuItem(value: 'session', child: Text('session')),
                ],
                onChanged: (v) {
                  setState(() => _targetType = v);
                  _applyFilters();
                },
              ),
              const SizedBox(width: AppTokens.s8),
              IconButton(
                tooltip: 'تطبيق',
                onPressed: _applyFilters,
                icon: const Icon(Icons.filter_alt_outlined),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s16),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب السجل',
            subtitle: '$e',
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(auditListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.history_toggle_off,
                title: 'لا توجد أحداث تطابق الفلتر',
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) => _AuditTile(event: items[i], df: df),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.event, required this.df});
  final AuditEvent event;
  final DateFormat df;

  PillTone _toneFor(String action) {
    final a = action.toLowerCase();
    if (a.contains('delete') || a.contains('revoke') || a.contains('disconnect')) {
      return PillTone.red;
    }
    if (a.contains('create')) return PillTone.green;
    if (a.contains('update') || a.contains('patch')) return PillTone.orange;
    if (a.contains('login') || a.contains('logout')) return PillTone.navy;
    return PillTone.cyan;
  }

  IconData _iconFor(String t) => switch (t.toLowerCase()) {
        'admin' => Icons.admin_panel_settings_outlined,
        'role' => Icons.shield_outlined,
        'user' => Icons.person_outline,
        'plan' => Icons.workspace_premium_outlined,
        'card_batch' || 'card' => Icons.credit_card_outlined,
        'nas' => Icons.router_outlined,
        'session' => Icons.signal_wifi_4_bar,
        _ => Icons.event_note_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTokens.cyan100,
        child: Icon(_iconFor(event.targetType), color: AppTokens.cyan500, size: 18),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${event.action}  •  ${event.targetType}${event.targetId.isNotEmpty ? "#${event.targetId}" : ""}',
              style: const TextStyle(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          StatusPill(text: event.action, tone: _toneFor(event.action)),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          [
            'actor: ${event.actor.isEmpty ? "-" : event.actor}',
            if (event.ipAddress.isNotEmpty) event.ipAddress,
            if (event.createdAt != null) df.format(event.createdAt!.toLocal()),
          ].join(' • '),
          style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
        ),
      ),
      trailing: event.payload.isEmpty
          ? null
          : IconButton(
              tooltip: 'عرض الـ payload',
              icon: const Icon(Icons.info_outline, color: AppTokens.textMuted),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (d) => AlertDialog(
                  title: Text('payload — ${event.action}'),
                  content: SingleChildScrollView(
                    child: SelectableText(
                      event.payload.toString(),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(d),
                      child: const Text('إغلاق'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
