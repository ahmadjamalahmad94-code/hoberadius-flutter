import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';

class SystemLoadingCard extends StatelessWidget {
  const SystemLoadingCard({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: title,
      child: const Padding(
        padding: EdgeInsets.all(AppTokens.s20),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
