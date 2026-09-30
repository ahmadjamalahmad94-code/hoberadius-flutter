import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/form_field_row.dart';
import '../../../../shared/widgets/hub_layout.dart';
import '../../../../shared/widgets/hub_switch_row.dart';
import '../../../../core/format/money_limits.dart';
import '../../../../shared/widgets/number_text_field.dart';

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
              'المعاينة بدون تنفيذ تُحسب على الهاتف ولا تُسجِّل أي مبلغ أو سلفة. أطفئها ثم اضغط «تسجيل» للتنفيذ الفعلي؛ عند تفعيل «تطبيق على الريدياس» يمدد الخادم الحساب حسب النتيجة.',
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

/// Inline red box — the server's (or the form's) Arabic error stays visible
/// on the card instead of a snackbar that can be missed.
class FinanceErrorBox extends StatelessWidget {
  const FinanceErrorBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTokens.dangerBg,
          borderRadius: BorderRadius.circular(AppTokens.r10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 18, color: AppTokens.red),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTokens.red,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Local preview result (blue note, nothing was recorded).
class FinancePreviewBox extends StatelessWidget {
  const FinancePreviewBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTokens.blueSoft,
          borderRadius: BorderRadius.circular(AppTokens.r10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.visibility_outlined,
              size: 18,
              color: AppTokens.blueInk,
            ),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTokens.blueInk,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
              ),
            ),
          ],
        ),
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
    this.currency = '',
    this.error,
    this.preview,
  });

  final TextEditingController amount;
  final TextEditingController notes;
  final String currency;
  final String? error;
  final String? preview;
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
          first: NumberTextField(
            controller: amount,
            extraError: (v) =>
                validateMoneyAmount(v, cap: MoneyCap.subscriberPayment),
            decoration: InputDecoration(
              labelText: currency.isEmpty ? 'المبلغ' : 'المبلغ ($currency)',
            ),
          ),
          second: TextField(
            controller: notes,
            decoration: const InputDecoration(labelText: 'ملاحظات'),
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        HubSwitchRow(
          label: 'تطبيق على الريدياس',
          subtitle: applyToRadius
              ? 'يمدد الحساب حسب المدة المستحقة'
              : 'مُطفأ: يُسجَّل المبلغ فقط بدون أي وقت للحساب',
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
        if (error != null) ...[
          const SizedBox(height: AppTokens.s8),
          FinanceErrorBox(message: error!),
        ],
        if (preview != null) ...[
          const SizedBox(height: AppTokens.s8),
          FinancePreviewBox(message: preview!),
        ],
        const SizedBox(height: AppTokens.s8),
        HubActionButton(
          item: ActionItem(
            icon: dryRun ? Icons.visibility_outlined : Icons.add,
            label: dryRun ? 'معاينة الدفعة' : 'تسجيل الدفعة',
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
    this.currency = '',
    this.error,
    this.preview,
  });

  final String currency;
  final String? error;
  final String? preview;
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
          first: NumberTextField(
            controller: hours,
            decimal: false,
            decoration: const InputDecoration(labelText: 'عدد الساعات'),
          ),
          second: NumberTextField(
            controller: amount,
            extraError: (v) => v > AppLimits.maxLoanAmount
                ? 'قيمة السلفة كبيرة جدًا — الحدّ الأعلى ${formatNumberBound(AppLimits.maxLoanAmount)}.'
                : null,
            decoration: InputDecoration(
              labelText:
                  currency.isEmpty ? 'قيمة السلفة' : 'قيمة السلفة ($currency)',
            ),
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
          subtitle: applyToRadius
              ? 'تُمنح المدّة للحساب فورًا'
              : 'مُطفأ: تُسجَّل السلفة بدون منح وقت',
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
        if (error != null) ...[
          const SizedBox(height: AppTokens.s8),
          FinanceErrorBox(message: error!),
        ],
        if (preview != null) ...[
          const SizedBox(height: AppTokens.s8),
          FinancePreviewBox(message: preview!),
        ],
        const SizedBox(height: AppTokens.s8),
        HubActionButton(
          item: ActionItem(
            icon: dryRun ? Icons.visibility_outlined : Icons.schedule,
            label: dryRun ? 'معاينة السلفة' : 'منح السلفة',
            primary: true,
            onPressed: busy ? null : onSubmit,
          ),
        ),
      ],
    );
  }
}
