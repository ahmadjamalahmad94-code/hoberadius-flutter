import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';

class FinanceNotice extends StatelessWidget {
  const FinanceNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTokens.brand),
          SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              'تجربة فقط لا تغير حساب RADIUS. التطبيق الفعلي يمدد/يفعل الحساب حسب نتيجة الخادم.',
              style: TextStyle(color: AppTokens.textMuted),
            ),
          ),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'تسجيل دفعة',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: AppTokens.s12),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'المبلغ'),
          ),
          const SizedBox(height: AppTokens.s8),
          TextField(
            controller: notes,
            decoration: const InputDecoration(labelText: 'ملاحظات'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('تطبيق على RADIUS'),
            subtitle: const Text('يمدد الحساب حسب المدة المستحقة'),
            value: applyToRadius,
            onChanged: busy ? null : onApplyChanged,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('تجربة فقط'),
            value: dryRun,
            onChanged: busy ? null : (v) => onDryRunChanged(v ?? true),
          ),
          ElevatedButton.icon(
            onPressed: busy ? null : onSubmit,
            icon: const Icon(Icons.add),
            label: const Text('تسجيل الدفعة'),
          ),
        ],
      ),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'منح سلفة',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: AppTokens.s12),
          TextField(
            controller: hours,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'عدد الساعات'),
          ),
          const SizedBox(height: AppTokens.s8),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'قيمة السلفة'),
          ),
          const SizedBox(height: AppTokens.s8),
          TextField(
            controller: reason,
            decoration: const InputDecoration(labelText: 'سبب السلفة'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('تطبيق مؤقت على RADIUS'),
            value: applyToRadius,
            onChanged: busy ? null : onApplyChanged,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('تجربة فقط'),
            value: dryRun,
            onChanged: busy ? null : (v) => onDryRunChanged(v ?? true),
          ),
          ElevatedButton.icon(
            onPressed: busy ? null : onSubmit,
            icon: const Icon(Icons.schedule),
            label: const Text('منح السلفة'),
          ),
        ],
      ),
    );
  }
}
