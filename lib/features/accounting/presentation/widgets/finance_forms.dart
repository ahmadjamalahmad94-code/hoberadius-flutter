import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/form_field_row.dart';
import '../../../../shared/widgets/hub_layout.dart';
import '../../../../shared/widgets/hub_switch_row.dart';

/// Compact info banner (tinted, small text) — was a full white card with a
/// paragraph that took as much room as a form.
class FinanceNotice extends StatelessWidget {
  const FinanceNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.blueSoft,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.blue.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, size: 18, color: AppTokens.blueInk),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              'المعاينة بدون تنفيذ لا تغيّر حساب الريدياس. عند اعتماد التنفيذ يمدد الخادم الحساب أو يفعّله حسب النتيجة.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTokens.blueInk,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared tight layout of the two finance forms: title, fields, on/off
/// rows, then one full-width primary button.
class _FinanceFormCard extends StatelessWidget {
  const _FinanceFormCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTokens.brandInk),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          ...children,
        ],
      ),
    );
  }
}

class PaymentFormCard extends StatelessWidget {
  const PaymentFormCard({
    super.key,
    required this.amount,
    required this.notes,
    required this.applyToRadius,
    required this.dryRun,
    required this.busy,
    required this.onApplyChanged,
    required this.onDryRunChanged,
    required this.onSubmit,
  });

  final TextEditingController amount;
  final TextEditingController notes;
  final bool applyToRadius;
  final bool dryRun;
  final bool busy;
  final ValueChanged<bool> onApplyChanged;
  final ValueChanged<bool> onDryRunChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _FinanceFormCard(
      title: 'تسجيل دفعة',
      icon: Icons.payments_outlined,
      children: [
        FormFieldPair(
          first: TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'المبلغ'),
          ),
          second: TextField(
            controller: notes,
            decoration: const InputDecoration(labelText: 'ملاحظات'),
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        HubSwitchRow(
          label: 'تطبيق على الريدياس',
          subtitle: 'يمدد الحساب حسب المدة المستحقة',
          value: applyToRadius,
          onChanged: busy ? null : onApplyChanged,
          dense: true,
        ),
        HubSwitchRow(
          label: 'معاينة بدون تنفيذ',
          value: dryRun,
          onChanged: busy ? null : onDryRunChanged,
          dense: true,
        ),
        const SizedBox(height: AppTokens.s8),
        HubActionButton(
          item: ActionItem(
            icon: Icons.add,
            label: 'تسجيل الدفعة',
            primary: true,
            onPressed: busy ? null : onSubmit,
          ),
        ),
      ],
    );
  }
}

class LoanFormCard extends StatelessWidget {
  const LoanFormCard({
    super.key,
    required this.hours,
    required this.amount,
    required this.reason,
    required this.applyToRadius,
    required this.dryRun,
    required this.busy,
    required this.onApplyChanged,
    required this.onDryRunChanged,
    required this.onSubmit,
  });

  final TextEditingController hours;
  final TextEditingController amount;
  final TextEditingController reason;
  final bool applyToRadius;
  final bool dryRun;
  final bool busy;
  final ValueChanged<bool> onApplyChanged;
  final ValueChanged<bool> onDryRunChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _FinanceFormCard(
      title: 'منح سلفة',
      icon: Icons.handshake_outlined,
      children: [
        FormFieldPair(
          first: TextField(
            controller: hours,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'عدد الساعات'),
          ),
          second: TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'قيمة السلفة'),
          ),
        ),
        const SizedBox(height: AppTokens.s8),
        TextField(
          controller: reason,
          decoration: const InputDecoration(labelText: 'سبب السلفة'),
        ),
        const SizedBox(height: AppTokens.s4),
        HubSwitchRow(
          label: 'تطبيق مؤقت على الريدياس',
          value: applyToRadius,
          onChanged: busy ? null : onApplyChanged,
          dense: true,
        ),
        HubSwitchRow(
          label: 'معاينة بدون تنفيذ',
          value: dryRun,
          onChanged: busy ? null : onDryRunChanged,
          dense: true,
        ),
        const SizedBox(height: AppTokens.s8),
        HubActionButton(
          item: ActionItem(
            icon: Icons.schedule,
            label: 'منح السلفة',
            primary: true,
            onPressed: busy ? null : onSubmit,
          ),
        ),
      ],
    );
  }
}
