/// Shared paging contract of the HobeRadius list endpoints.
///
/// Newer servers answer `{items, total, has_more, limit, offset}` (and the
/// keyset endpoints `next_before_id`); older builds send only `items` and may
/// ignore `offset` altogether. [readPageInfo] works for both, and
/// [mergeUniqueBy] keeps a list free of duplicates when a page overlaps the
/// previous one (new rows arriving between two requests, or an old server
/// that returns the same first page again) — a page that adds nothing new
/// ends the paging instead of looping.
library;

class PageInfo {
  const PageInfo({
    required this.hasMore,
    this.total,
    this.nextBeforeId,
  });

  final bool hasMore;

  /// All matching rows on the server (null when the server does not say).
  final int? total;

  /// Keyset cursor for `before_id` endpoints (notifications, events).
  final int? nextBeforeId;
}

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '');
}

PageInfo readPageInfo(
  Map<String, dynamic> data, {
  required int requestedLimit,
  required int offset,
  required int itemCount,
}) {
  final total = _asInt(data['total']) ?? _asInt(data['total_count']);
  final raw = data['has_more'];
  final bool hasMore;
  if (raw is bool) {
    hasMore = raw;
  } else if (total != null) {
    hasMore = offset + itemCount < total;
  } else {
    hasMore = requestedLimit > 0 && itemCount >= requestedLimit;
  }
  return PageInfo(
    hasMore: hasMore,
    total: total,
    nextBeforeId: _asInt(data['next_before_id']),
  );
}

/// Appends [incoming] to [existing], skipping any row whose [key] is already
/// present. Returns the merged list and how many rows were really new.
(List<T>, int) mergeUniqueBy<T>(
  List<T> existing,
  List<T> incoming,
  Object? Function(T item) key,
) {
  final seen = <Object?>{for (final e in existing) key(e)};
  final merged = [...existing];
  var added = 0;
  for (final item in incoming) {
    if (seen.add(key(item))) {
      merged.add(item);
      added++;
    }
  }
  return (merged, added);
}

/// Immutable state of an infinite-scroll list.
class PagedList<T> {
  const PagedList({
    this.items = const [],
    this.hasMore = false,
    this.total,
    this.nextOffset = 0,
    this.nextBeforeId,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<T> items;
  final bool hasMore;
  final int? total;
  final int nextOffset;
  final int? nextBeforeId;
  final bool loadingMore;
  final Object? loadMoreError;

  PagedList<T> copyWith({
    List<T>? items,
    bool? hasMore,
    Object? total = _keep,
    int? nextOffset,
    Object? nextBeforeId = _keep,
    bool? loadingMore,
    Object? loadMoreError = _keep,
  }) =>
      PagedList<T>(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        total: identical(total, _keep) ? this.total : total as int?,
        nextOffset: nextOffset ?? this.nextOffset,
        nextBeforeId: identical(nextBeforeId, _keep)
            ? this.nextBeforeId
            : nextBeforeId as int?,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreError: identical(loadMoreError, _keep)
            ? this.loadMoreError
            : loadMoreError,
      );

  static const _keep = Object();
}
