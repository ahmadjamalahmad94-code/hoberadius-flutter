import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/sessions_repository.dart';
import '../domain/session_model.dart';

class SessionsListScreen extends ConsumerStatefulWidget {
  const SessionsListScreen({super.key});

  @override
  ConsumerState<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends ConsumerState<SessionsListScreen> {
  final _searchController = TextEditingController();
  OnlineSessionKind _kind = OnlineSessionKind.all;
  String _search = '';

  OnlineSessionsQuery get _query =>
      OnlineSessionsQuery(kind: _kind, search: _search);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatBytes(int b) {
    if (b <= 0) return '0 KB';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double v = b.toDouble();
    var i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v.toStringAsFixed(v < 10 ? 1 : 0)} ${units[i]}';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return 'غير معروف';
    final d = Duration(seconds: seconds);
    if (d.inDays > 0) return '${d.inDays}ي ${d.inHours.remainder(24)}س';
    if (d.inHours > 0) return '${d.inHours}س ${d.inMinutes.remainder(60)}د';
    if (d.inMinutes > 0) return '${d.inMinutes}د ${d.inSeconds.remainder(60)}ث';
    return '${d.inSeconds}ث';
  }

  Future<void> _disconnect(OnlineSession s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('طرد الجلسة'),
        content: Text(
          'سيتم طرد ${s.isCard ? 'البطاقة' : 'المشترك'} "${s.username}" من الشبكة الآن.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTokens.red),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.power_settings_new),
            label: const Text('طرد الآن'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(sessionsRepositoryProvider).disconnect(
            username: s.username,
            sessionId: s.sessionId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال أمر الطرد لـ ${s.username}')),
      );
      ref.invalidate(onlineSessionsProvider(_query));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر الطرد: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(onlineSessionsProvider(_query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'المتصلون الآن',
          subtitle: 'مشتركين وكروت متصلة مع إمكانية الطرد المباشر من الشبكة.',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () => ref.invalidate(onlineSessionsProvider(_query)),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        _FiltersCard(
          kind: _kind,
          searchController: _searchController,
          onKindChanged: (kind) {
            if (_kind == kind) return;
            setState(() => _kind = kind);
          },
          onSearch: () {
            final next = _searchController.text.trim();
            if (next == _search) {
              ref.invalidate(onlineSessionsProvider(_query));
              return;
            }
            setState(() => _search = next);
          },
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب المتصلين',
            subtitle: '$e',
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(onlineSessionsProvider(_query)),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.signal_wifi_off_outlined,
                title: _kind == OnlineSessionKind.cards
                    ? 'لا توجد كروت متصلة الآن'
                    : _kind == OnlineSessionKind.subscribers
                        ? 'لا يوجد مشتركين متصلين الآن'
                        : 'لا يوجد متصلون الآن',
                subtitle: 'أي جلسة نشطة ستظهر هنا فور وصولها من RADIUS.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryStrip(items: items),
                const SizedBox(height: AppTokens.s12),
                ...items.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s8),
                    child: _SessionTile(
                      session: session,
                      formatBytes: _formatBytes,
                      formatDuration: _formatDuration,
                      onDisconnect: () => _disconnect(session),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.kind,
    required this.searchController,
    required this.onKindChanged,
    required this.onSearch,
  });

  final OnlineSessionKind kind;
  final TextEditingController searchController;
  final ValueChanged<OnlineSessionKind> onKindChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<OnlineSessionKind>(
            segments: const [
              ButtonSegment(
                value: OnlineSessionKind.all,
                icon: Icon(Icons.wifi_tethering),
                label: Text('الكل'),
              ),
              ButtonSegment(
                value: OnlineSessionKind.subscribers,
                icon: Icon(Icons.person_outline),
                label: Text('مشتركين'),
              ),
              ButtonSegment(
                value: OnlineSessionKind.cards,
                icon: Icon(Icons.credit_card),
                label: Text('كروت'),
              ),
            ],
            selected: {kind},
            onSelectionChanged: (selection) => onKindChanged(selection.first),
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: const InputDecoration(
                    labelText: 'بحث',
                    hintText: 'اسم الدخول أو MAC أو IP',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search),
                label: const Text('بحث'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.items});
  final List<OnlineSession> items;

  @override
  Widget build(BuildContext context) {
    final subscribers = items.where((item) => item.isSubscriber).length;
    final cards = items.where((item) => item.isCard).length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 640 ? 3 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          childAspectRatio: constraints.maxWidth < 420 ? 2.2 : 2.8,
          mainAxisSpacing: AppTokens.s8,
          crossAxisSpacing: AppTokens.s8,
          children: [
            _SummaryTile(
              icon: Icons.wifi_tethering,
              label: 'كل المتصلين',
              value: '${items.length}',
            ),
            _SummaryTile(
              icon: Icons.person_outline,
              label: 'مشتركين',
              value: '$subscribers',
            ),
            _SummaryTile(
              icon: Icons.credit_card,
              label: 'كروت',
              value: '$cards',
            ),
          ],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTokens.brandSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTokens.brand, size: 20),
            ),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTokens.sidebarBg,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.formatBytes,
    required this.formatDuration,
    required this.onDisconnect,
  });

  final OnlineSession session;
  final String Function(int) formatBytes;
  final String Function(int) formatDuration;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: session.isCard
                    ? AppTokens.brandSoft
                    : const Color(0xFFE6F6EC),
                child: Icon(
                  session.isCard ? Icons.credit_card : Icons.person_outline,
                  color: session.isCard ? AppTokens.brand : AppTokens.green,
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: AppTokens.s8,
                      runSpacing: AppTokens.s4,
                      children: [
                        StatusPill(
                          text: session.isCard ? 'كرت' : 'مشترك',
                          tone: session.isCard ? PillTone.cyan : PillTone.green,
                        ),
                        StatusPill(
                          text: _stateLabel(session),
                          tone: _stateTone(session),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onDisconnect,
                icon: const Icon(Icons.power_settings_new),
                label: const Text('طرد'),
                style: FilledButton.styleFrom(
                  foregroundColor: AppTokens.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _MetaChip(
                icon: Icons.timer_outlined,
                text: formatDuration(session.sessionTime),
              ),
              _MetaChip(
                icon: Icons.download,
                text: 'تنزيل ${formatBytes(session.bytesIn)}',
              ),
              _MetaChip(
                icon: Icons.upload,
                text: 'رفع ${formatBytes(session.bytesOut)}',
              ),
              if (session.framedIpAddress.isNotEmpty)
                _MetaChip(icon: Icons.dns, text: session.framedIpAddress),
              if (session.callingStationId.isNotEmpty)
                _MetaChip(icon: Icons.devices, text: session.callingStationId),
              if (session.nasIpAddress.isNotEmpty)
                _MetaChip(icon: Icons.router, text: session.nasIpAddress),
              if (session.startedAt != null)
                _MetaChip(
                  icon: Icons.play_circle_outline,
                  text: 'بدأت ${df.format(session.startedAt!.toLocal())}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _stateLabel(OnlineSession s) {
    final raw = s.stateLabel.isNotEmpty ? s.stateLabel : s.state;
    return switch (raw) {
      'online' => 'متصل',
      'active' => 'نشط',
      'expired' => 'منتهي',
      'frozen' => 'مجمّد',
      'disconnected' => 'مفصول',
      _ => raw,
    };
  }

  static PillTone _stateTone(OnlineSession s) => switch (s.stateColor) {
        'green' => PillTone.green,
        'orange' => PillTone.orange,
        'red' => PillTone.red,
        'blue' => PillTone.cyan,
        'gray' => PillTone.neutral,
        _ => PillTone.cyan,
      };
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTokens.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTokens.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
