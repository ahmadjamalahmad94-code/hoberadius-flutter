import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════════════
// «المهام المقترحة» — the + sheet and the chip row above the composer.
//
// EVERY task here maps 1:1 to an action the DEPLOYED executor catalog can
// actually perform (catalog_version "ops-v3",
// app/radius/services/ops_assistant/catalog_ops_v2.json → `actions`):
//
//   executable  create_subscriber · renew_or_extend_subscriber ·
//               change_subscriber_plan · temporary_speed ·
//               suspend_subscriber · enable_subscriber · create_plan ·
//               create_offer · create_card_batch
//   lookup      list_plans · list_offers · find_subscriber ·
//               list_card_batches
//   info        card_batch_status · subscriber_info · online_sessions ·
//               recent_subscribers · recent_card_batches ·
//               recent_activity · card_info
//
// Nothing else is offered: a chip the backend cannot perform would make the
// assistant answer «لا أستطيع» and waste the admin's turn.
//
// A task only WRITES the sentence into the chat (the same path as typing it
// by hand). The model still asks for what is missing, and an executable
// action still ends at a confirmation card — tapping a chip never executes.
// ════════════════════════════════════════════════════════════════════════

/// One suggested task: a chip/row label, its icon, and the Arabic sentence
/// sent to the assistant.
@immutable
class OpsTask {
  const OpsTask({
    required this.id,
    required this.action,
    required this.label,
    required this.prompt,
    required this.icon,
  });

  /// Stable key (widget keys + tests).
  final String id;

  /// The catalog action this task leads to (documentation + the guard test).
  final String action;

  /// Short label on the chip / sheet row.
  final String label;

  /// What is written into the chat.
  final String prompt;

  final IconData icon;
}

/// A titled group of tasks in the + sheet.
@immutable
class OpsTaskGroup {
  const OpsTaskGroup({required this.title, required this.tasks});
  final String title;
  final List<OpsTask> tasks;
}

/// The full catalogue, grouped the way the sheet shows it.
const kOpsTaskGroups = <OpsTaskGroup>[
  OpsTaskGroup(
    title: 'المشتركون',
    tasks: [
      OpsTask(
        id: 'create_subscriber',
        action: 'create_subscriber',
        label: 'إضافة مشترك',
        prompt: 'أضف مشتركًا جديدًا',
        icon: Icons.person_add_alt_1_outlined,
      ),
      OpsTask(
        id: 'renew',
        action: 'renew_or_extend_subscriber',
        label: 'تجديد اشتراك',
        prompt: 'جدّد اشتراك مشترك',
        icon: Icons.autorenew,
      ),
      OpsTask(
        id: 'change_plan',
        action: 'change_subscriber_plan',
        label: 'تغيير باقة مشترك',
        prompt: 'غيّر باقة مشترك',
        icon: Icons.swap_horiz,
      ),
      OpsTask(
        id: 'temp_speed',
        action: 'temporary_speed',
        label: 'سرعة مؤقّتة',
        prompt: 'أعطِ مشتركًا سرعة مؤقّتة',
        icon: Icons.speed_outlined,
      ),
      OpsTask(
        id: 'suspend',
        action: 'suspend_subscriber',
        label: 'إيقاف مشترك',
        prompt: 'أوقف مشتركًا',
        icon: Icons.pause_circle_outline,
      ),
      OpsTask(
        id: 'enable',
        action: 'enable_subscriber',
        label: 'تفعيل مشترك',
        prompt: 'فعّل مشتركًا موقوفًا',
        icon: Icons.play_circle_outline,
      ),
      OpsTask(
        id: 'find_subscriber',
        action: 'find_subscriber',
        label: 'بحث عن مشترك',
        prompt: 'ابحث عن مشترك',
        icon: Icons.search,
      ),
      OpsTask(
        id: 'subscriber_info',
        action: 'subscriber_info',
        label: 'معلومات مشترك',
        prompt: 'اعرض معلومات مشترك',
        icon: Icons.badge_outlined,
      ),
    ],
  ),
  OpsTaskGroup(
    title: 'الكروت',
    tasks: [
      OpsTask(
        id: 'card_stock',
        action: 'list_card_batches',
        label: 'مخزون كروت',
        prompt: 'اعرض حزم البطاقات وكم كرت متاح في كلّ حزمة',
        icon: Icons.inventory_2_outlined,
      ),
      OpsTask(
        id: 'create_card_batch',
        action: 'create_card_batch',
        label: 'توليد كروت',
        prompt: 'ولّد حزمة بطاقات جديدة',
        icon: Icons.add_card_outlined,
      ),
      OpsTask(
        id: 'batch_status',
        action: 'card_batch_status',
        label: 'وضع حزمة بطاقات',
        prompt: 'ما وضع حزمة بطاقات؟',
        icon: Icons.fact_check_outlined,
      ),
      OpsTask(
        id: 'card_info',
        action: 'card_info',
        label: 'فحص بطاقة',
        prompt: 'افحص بطاقة برقمها',
        icon: Icons.credit_card,
      ),
      OpsTask(
        id: 'recent_batches',
        action: 'recent_card_batches',
        label: 'آخر حزم البطاقات',
        prompt: 'اعرض آخر حزم البطاقات',
        icon: Icons.history_toggle_off,
      ),
    ],
  ),
  OpsTaskGroup(
    title: 'الباقات والعروض',
    tasks: [
      OpsTask(
        id: 'list_plans',
        action: 'list_plans',
        label: 'عرض الباقات',
        prompt: 'اعرض الباقات',
        icon: Icons.layers_outlined,
      ),
      OpsTask(
        id: 'list_offers',
        action: 'list_offers',
        label: 'عرض العروض',
        prompt: 'اعرض عروض البطاقات',
        icon: Icons.local_offer_outlined,
      ),
      OpsTask(
        id: 'create_plan',
        action: 'create_plan',
        label: 'إنشاء باقة',
        prompt: 'أنشئ باقة جديدة',
        icon: Icons.playlist_add,
      ),
      OpsTask(
        id: 'create_offer',
        action: 'create_offer',
        label: 'إنشاء عرض بطاقات',
        prompt: 'أنشئ عرض بطاقات جديدًا',
        icon: Icons.sell_outlined,
      ),
    ],
  ),
  OpsTaskGroup(
    title: 'التقارير',
    tasks: [
      OpsTask(
        id: 'today_report',
        action: 'recent_activity',
        label: 'تقارير اليوم',
        prompt: 'اعرض آخر نشاطي في اللوحة اليوم',
        icon: Icons.bar_chart,
      ),
      OpsTask(
        id: 'recent_subscribers',
        action: 'recent_subscribers',
        label: 'آخر المشتركين',
        prompt: 'اعرض آخر المشتركين المضافين',
        icon: Icons.group_outlined,
      ),
    ],
  ),
  OpsTaskGroup(
    title: 'الشبكة',
    tasks: [
      OpsTask(
        id: 'online_now',
        action: 'online_sessions',
        label: 'المتّصلون الآن',
        prompt: 'من المتّصل الآن؟',
        icon: Icons.wifi_tethering,
      ),
    ],
  ),
];

/// Every task, flattened.
List<OpsTask> get kOpsAllTasks =>
    [for (final g in kOpsTaskGroups) ...g.tasks];

/// The four shortcuts of the horizontal row above the composer (the mockup:
/// «مخزون كروت» · «إضافة مشترك» · «تقارير اليوم» + «المزيد»).
const kOpsQuickTaskIds = <String>[
  'card_stock',
  'create_subscriber',
  'today_report',
];

List<OpsTask> get kOpsQuickTasks => [
      for (final id in kOpsQuickTaskIds)
        kOpsAllTasks.firstWhere((t) => t.id == id),
    ];
