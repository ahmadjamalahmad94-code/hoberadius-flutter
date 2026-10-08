import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../domain/ops_labels.dart';

// The chat surface of the owner's mockup: the robot avatar, the message row
// (bubble + clock + delivery ticks), the animated typing indicator, and the
// expandable «عرض التفاصيل» row of a result card.
//
// Everything here is presentation only — no request is made and nothing is
// executed from this file.

/// The round robot avatar beside every assistant row.
class OpsBotAvatar extends StatelessWidget {
  const OpsBotAvatar({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTokens.brand,
        shape: BoxShape.circle,
        border: Border.all(color: AppTokens.brandSoft2, width: 3),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.smart_toy_outlined,
        size: size * .52,
        color: Colors.white,
      ),
    );
  }
}

/// One row of the transcript: the bubble/card, the robot avatar on the
/// assistant side, and the clock (+ the double check on the admin's own
/// messages) underneath.
///
/// In RTL the admin's own messages sit on the start (right) edge and the
/// assistant's on the end (left) edge — the mockup's arrangement.
class OpsMessageRow extends StatelessWidget {
  const OpsMessageRow({
    super.key,
    required this.child,
    required this.bot,
    this.at,
    this.avatar = true,
  });

  final Widget child;
  final bool bot;
  final DateTime? at;

  /// False for a follow-up row of the same assistant turn (keeps the gutter
  /// without repeating the face).
  final bool avatar;

  @override
  Widget build(BuildContext context) {
    const gutter = 38.0;
    final meta = at == null
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.only(top: 4, start: 6, end: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  opsClock(at!),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTokens.textMuted,
                  ),
                ),
                if (!bot) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all,
                    size: 13,
                    color: AppTokens.brandLight,
                  ),
                ],
              ],
            ),
          );

    final column = Column(
      crossAxisAlignment:
          bot ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [child, if (meta != null) meta],
    );

    if (!bot) {
      return Align(alignment: AlignmentDirectional.centerStart, child: column);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(child: column),
        const SizedBox(width: AppTokens.s8),
        SizedBox(
          width: gutter,
          child: avatar
              ? const Align(
                  alignment: Alignment.topCenter,
                  child: OpsBotAvatar(),
                )
              : null,
        ),
      ],
    );
  }
}

/// «المساعد الذكي…» with three breathing dots while a turn is in flight.
class OpsTypingIndicator extends StatefulWidget {
  const OpsTypingIndicator({super.key});

  @override
  State<OpsTypingIndicator> createState() => _OpsTypingIndicatorState();
}

class _OpsTypingIndicatorState extends State<OpsTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTokens.brandSoft,
        borderRadius: const BorderRadiusDirectional.only(
          topStart: Radius.circular(14),
          topEnd: Radius.circular(14),
          bottomStart: Radius.circular(14),
          bottomEnd: Radius.circular(4),
        ),
        border: Border.all(color: AppTokens.brandLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            OpsTexts.typingLabel,
            style: TextStyle(fontSize: 13.5, color: AppTokens.textMuted),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: Opacity(
                      // Each dot leads the next by a third of the cycle.
                      opacity: .35 +
                          .65 *
                              (1 -
                                      ((((_c.value + i / 3) % 1) - .5).abs() *
                                          2))
                                  .clamp(0.0, 1.0),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTokens.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The «عرض التفاصيل» row of a result card: the summary stays visible and
/// the full key/value rows open underneath.
class OpsExpandableDetails extends StatefulWidget {
  const OpsExpandableDetails({
    super.key,
    required this.child,
    this.toggleKey,
  });

  final Widget child;
  final Key? toggleKey;

  @override
  State<OpsExpandableDetails> createState() => _OpsExpandableDetailsState();
}

class _OpsExpandableDetailsState extends State<OpsExpandableDetails> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: AppTokens.surfaceMuted,
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(color: AppTokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                key: widget.toggleKey,
                borderRadius: BorderRadius.circular(AppTokens.r12),
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.arrow_back,
                        size: 17,
                        color: AppTokens.brand,
                      ),
                      const SizedBox(width: AppTokens.s8),
                      Expanded(
                        child: Text(
                          _open
                              ? OpsTexts.hideDetails
                              : OpsTexts.showDetails,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.brandInk,
                          ),
                        ),
                      ),
                      Icon(
                        _open ? Icons.remove : Icons.add,
                        size: 18,
                        color: AppTokens.brand,
                      ),
                    ],
                  ),
                ),
              ),
              if (_open)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: widget.child,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A small «مثال» chip inside the opening bubble.
class OpsExampleChip extends StatelessWidget {
  const OpsExampleChip({super.key, required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: AppTokens.brandSoft2,
          borderRadius: BorderRadius.circular(AppTokens.r10),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            height: 1.6,
            color: AppTokens.textPrimary,
          ),
        ),
      ),
    );
  }
}
