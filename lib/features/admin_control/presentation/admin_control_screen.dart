import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/admin_control_controller.dart';
import '../domain/admin_control_model.dart';
import 'widgets/settings_panel.dart';

/// System settings — edits go through [adminControlControllerProvider].
class AdminControlScreen extends ConsumerStatefulWidget {
  const AdminControlScreen({super.key});

  @override
  ConsumerState<AdminControlScreen> createState() => _AdminControlScreenState();
}

class _AdminControlScreenState extends ConsumerState<AdminControlScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'إعدادات النظام',
          inlineActions: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref
                  .read(adminControlControllerProvider.notifier)
                  .refreshAll(),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        SettingsPanel(onEdit: _editSetting),
      ],
    );
  }

  Future<void> _editSetting(SettingItem item) async {
    final controller = TextEditingController(text: item.value);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.displayLabel),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'القيمة',
            helperText: item.defaultValue.isEmpty
                ? null
                : 'الافتراضي: ${item.defaultValue}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    final result = await ref
        .read(adminControlControllerProvider.notifier)
        .updateSetting(item.key, value);
    _afterAction(result.error, 'تم حفظ الإعداد');
  }

  void _afterAction(String? error, String successMessage) {
    if (!mounted) return;
    _snack(error ?? successMessage);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
