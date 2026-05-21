import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';

class CardCheckerSearch extends StatelessWidget {
  const CardCheckerSearch({
    super.key,
    required this.controller,
    required this.loading,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final field = TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: const InputDecoration(
              labelText: 'رقم البطاقة أو اسم الدخول',
              helperText: 'ابحث بدون كشف كلمة مرور البطاقة.',
              prefixIcon: Icon(Icons.search),
            ),
          );
          final button = ElevatedButton.icon(
            onPressed: loading ? null : onSearch,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.manage_search),
            label: const Text('فحص'),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                field,
                const SizedBox(height: AppTokens.s12),
                button,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: field),
              const SizedBox(width: AppTokens.s12),
              button,
            ],
          );
        },
      ),
    );
  }
}

class CardCheckerInlineError extends StatelessWidget {
  const CardCheckerInlineError({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.dangerBg,
        borderRadius: BorderRadius.circular(AppTokens.r10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTokens.red),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppTokens.red)),
          ),
        ],
      ),
    );
  }
}
