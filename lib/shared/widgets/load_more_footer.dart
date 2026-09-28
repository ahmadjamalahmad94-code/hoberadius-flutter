import 'package:flutter/material.dart';

import '../../core/api/visible_error_message.dart';
import '../../core/theme/tokens.dart';

/// Infinite-scroll footer for the list pages that live inside the shell's
/// single scroll view: it listens to the NEAREST [Scrollable] and asks for the
/// next page when the reader gets within [threshold] px of the end, and it
/// always shows a «تحميل المزيد» button as a fallback (keyboard, a11y, pages
/// shorter than the screen). Shows «عُرض الكل» once the server says no more.
class LoadMoreFooter extends StatefulWidget {
  const LoadMoreFooter({
    super.key,
    required this.hasMore,
    required this.loading,
    required this.onLoadMore,
    this.error,
    this.shown,
    this.total,
    this.threshold = 480,
  });

  final bool hasMore;
  final bool loading;
  final VoidCallback onLoadMore;
  final Object? error;
  final int? shown;
  final int? total;
  final double threshold;

  @override
  State<LoadMoreFooter> createState() => _LoadMoreFooterState();
}

class _LoadMoreFooterState extends State<LoadMoreFooter> {
  ScrollPosition? _position;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (!identical(next, _position)) {
      _position?.removeListener(_onScroll);
      _position = next;
      _position?.addListener(_onScroll);
    }
  }

  @override
  void didUpdateWidget(covariant LoadMoreFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A page that did not fill the screen: keep loading after this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final pos = _position;
    if (pos == null || !pos.hasContentDimensions) return;
    if (!widget.hasMore || widget.loading || widget.error != null) return;
    if (pos.extentAfter < widget.threshold) widget.onLoadMore();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: AppTokens.textMuted);
    final shown = widget.shown;
    final total = widget.total;
    final counter = shown == null
        ? ''
        : total != null
            ? 'عُرض $shown من $total'
            : 'عُرض $shown';
    Widget child;
    if (widget.loading) {
      child = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (widget.error != null) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            visibleErrorMessage(widget.error),
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: AppTokens.red),
          ),
          const SizedBox(height: AppTokens.s4),
          OutlinedButton.icon(
            onPressed: widget.onLoadMore,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      );
    } else if (widget.hasMore) {
      child = OutlinedButton.icon(
        onPressed: widget.onLoadMore,
        icon: const Icon(Icons.expand_more, size: 18),
        label:
            Text(counter.isEmpty ? 'تحميل المزيد' : 'تحميل المزيد · $counter'),
      );
    } else {
      child = Text(
        counter.isEmpty ? 'نهاية القائمة' : 'نهاية القائمة · $counter',
        style: muted,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
      child: Center(child: child),
    );
  }
}
