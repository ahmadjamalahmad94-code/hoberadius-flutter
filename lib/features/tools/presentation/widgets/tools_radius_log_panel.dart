import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/tools_providers.dart';

class ToolsRadiusLogPanel extends ConsumerWidget {
  const ToolsRadiusLogPanel({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(radiusLogProvider);
    return AppCard(
      padding: EdgeInsets.zero,
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppTokens.s20),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(AppTokens.s20),
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب سجل RADIUS',
            subtitle: visibleErrorMessage(e),
          ),
        ),
        data: (snapshot) {
          if (snapshot.items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppTokens.s20),
              child: EmptyState(
                icon: Icons.rss_feed,
                title: 'لا توجد قرارات دخول بعد',
              ),
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('القرار')),
                DataColumn(label: Text('اسم الدخول')),
                DataColumn(label: Text('NAS')),
                DataColumn(label: Text('السبب')),
                DataColumn(label: Text('الوقت')),
              ],
              rows: snapshot.items
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(
                          StatusPill(
                            text: item.ok ? 'قبول' : 'رفض',
                            tone: item.ok ? PillTone.green : PillTone.red,
                          ),
                        ),
                        DataCell(Text(item.username)),
                        DataCell(
                          Text(item.nas.isEmpty ? 'غير معروف' : item.nas),
                        ),
                        DataCell(
                          Text(
                            item.reason.isEmpty ? item.reply : item.reason,
                          ),
                        ),
                        DataCell(Text(item.authdate)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}
