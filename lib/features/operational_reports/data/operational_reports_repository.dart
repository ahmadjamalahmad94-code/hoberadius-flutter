import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../domain/operational_report_model.dart';

/// Server-side filters of one operational report page — the same query keys
/// the web report pages use (`q`, `date_from`/`date_to` = LOCAL days, inclusive,
/// `result`/`source` for the login reports) plus paging (`limit`/`offset`).
class OperationalReportQuery {
  const OperationalReportQuery({
    this.query = '',
    this.dateFrom,
    this.dateTo,
    this.result = '',
    this.source = '',
  });

  final String query;

  /// Local calendar days (only Y/M/D are sent; the server applies the panel's
  /// Palestine day boundaries — never UTC days).
  final DateTime? dateFrom;
  final DateTime? dateTo;

  /// `success` | `fail` | '' (login reports only).
  final String result;

  /// `panel` | `portal` | `network` | '' (login-status only).
  final String source;

  Map<String, dynamic> toQueryParameters({
    required int limit,
    required int offset,
  }) {
    final fmt = DateFormat('yyyy-MM-dd');
    return {
      'limit': limit,
      if (offset > 0) 'offset': offset,
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (dateFrom != null) 'date_from': fmt.format(dateFrom!),
      if (dateTo != null) 'date_to': fmt.format(dateTo!),
      if (result.isNotEmpty) 'result': result,
      if (source.isNotEmpty) 'source': source,
    };
  }

  bool get hasFilters =>
      query.trim().isNotEmpty ||
      dateFrom != null ||
      dateTo != null ||
      result.isNotEmpty ||
      source.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is OperationalReportQuery &&
      other.query == query &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo &&
      other.result == result &&
      other.source == source;

  @override
  int get hashCode => Object.hash(query, dateFrom, dateTo, result, source);
}

class OperationalReportsRepository {
  OperationalReportsRepository(this._api);

  final ApiClient _api;

  Future<OperationalReportSnapshot> fetch({
    required String slug,
    OperationalReportQuery filters = const OperationalReportQuery(),
    int limit = 100,
    int offset = 0,
  }) async {
    final res = await _api.get(
      '/api/v1/operational-reports/$slug',
      query: filters.toQueryParameters(limit: limit, offset: offset),
    );
    final data = res['data'];
    if (data is Map<String, dynamic>) {
      return OperationalReportSnapshot.fromJson(data);
    }
    if (data is Map) {
      return OperationalReportSnapshot.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return const OperationalReportSnapshot(
      slug: '',
      items: [],
      count: 0,
      query: '',
      limit: 0,
      offset: 0,
    );
  }
}

final operationalReportsRepositoryProvider =
    Provider<OperationalReportsRepository>((ref) {
  return OperationalReportsRepository(ref.watch(apiClientProvider));
});
