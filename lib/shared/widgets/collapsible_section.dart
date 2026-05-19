import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/tokens.dart';

/// Section that remembers its open/closed state per-key in SharedPreferences.
class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({
    super.key,
    required this.storageKey,
    required this.title,
    this.icon,
    this.initiallyExpanded = true,
    this.subtitle,
    required this.child,
  });

  final String storageKey;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool initiallyExpanded;
  final Widget child;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  bool _expanded = true;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _restore();
  }

  Future<void> _restore() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getBool('section.${widget.storageKey}');
    if (mounted && v != null) {
      setState(() {
        _expanded = v;
        _restored = true;
      });
    } else {
      setState(() => _restored = true);
    }
  }

  Future<void> _persist(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('section.${widget.storageKey}', v);
  }

  @override
  Widget build(BuildContext context) {
    if (!_restored) return const SizedBox.shrink();
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.r14)),
            onTap: () {
              setState(() => _expanded = !_expanded);
              _persist(_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s20,
                vertical: AppTokens.s16,
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: AppTokens.cyan500),
                    const SizedBox(width: AppTokens.s8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTokens.navy800,
                              ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTokens.textMuted,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTokens.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTokens.s20),
              child: widget.child,
            ),
          ],
        ],
      ),
    );
  }
}
