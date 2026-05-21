import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

class ToolsPanelTitle extends StatelessWidget {
  const ToolsPanelTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTokens.brand),
        const SizedBox(width: AppTokens.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTokens.sidebarBg,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppTokens.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ToolsTwoFields extends StatelessWidget {
  const ToolsTwoFields({
    super.key,
    required this.first,
    required this.second,
  });

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            children: [
              first,
              const SizedBox(height: AppTokens.s8),
              second,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: AppTokens.s8),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class ToolsTintBox extends StatelessWidget {
  const ToolsTintBox({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: child,
      ),
    );
  }
}

class ToolsKeyValueBox extends StatelessWidget {
  const ToolsKeyValueBox({super.key, required this.values});

  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    return ToolsTintBox(
      color: AppTokens.surfaceMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: values.entries
            .map((entry) => Text('${entry.key}: ${entry.value}'))
            .toList(),
      ),
    );
  }
}

class ToolsTextField extends StatelessWidget {
  const ToolsTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
