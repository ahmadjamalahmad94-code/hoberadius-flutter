import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/admin_alerts_model.dart';

/// Repository for the Telegram admin-alerts surface (`/api/v1/alerts/telegram`).
class AdminAlertsRepository {
  AdminAlertsRepository(this._api);

  final ApiClient _api;

  Future<TelegramAlertsSnapshot> catalogue() async {
    final res = await _api.get('/api/v1/alerts/telegram');
    return TelegramAlertsSnapshot.fromJson(_data(res));
  }

  /// PATCH-style bot save. A blank [botToken] keeps the stored token (the
  /// client never receives it raw, so it must not be able to wipe it).
  Future<TelegramBot> saveBot({
    String botToken = '',
    required String chatId,
    required String threadId,
    required bool enabled,
  }) async {
    final res = await _api.patch(
      '/api/v1/alerts/telegram/bot',
      body: {
        if (botToken.trim().isNotEmpty) 'bot_token': botToken.trim(),
        'chat_id': chatId.trim(),
        'thread_id': threadId.trim(),
        'enabled': enabled,
      },
    );
    final data = _data(res);
    return TelegramBot.fromJson(_obj(data, 'bot'));
  }

  /// Sends a connectivity test message via the bot. Throws on failure.
  Future<void> testConnection() async {
    await _api.post('/api/v1/alerts/telegram/test-connection');
  }

  Future<bool> toggleAlert(String key, bool enabled) async {
    final res = await _api.post(
      '/api/v1/alerts/telegram/alerts/$key/toggle',
      body: {'enabled': enabled},
    );
    return _data(res)['enabled'] == true;
  }

  /// Sends a sample of one alert and returns the rendered text. Throws on
  /// send failure (the rendered text is still surfaced via the exception path
  /// by the caller showing the error message).
  Future<String> testAlert(String key) async {
    final res = await _api.post('/api/v1/alerts/telegram/alerts/$key/test');
    return _data(res)['rendered']?.toString() ?? '';
  }

  Map<String, dynamic> _data(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.map((k, v) => MapEntry(k.toString(), v));
    return const {};
  }

  Map<String, dynamic> _obj(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return const {};
  }
}

final adminAlertsRepositoryProvider = Provider<AdminAlertsRepository>((ref) {
  return AdminAlertsRepository(ref.watch(apiClientProvider));
});

final telegramAlertsProvider =
    FutureProvider.autoDispose<TelegramAlertsSnapshot>((ref) {
  return ref.watch(adminAlertsRepositoryProvider).catalogue();
});
