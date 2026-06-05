import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoint_storage.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/visible_error_message.dart';
import '../data/hotspot_cards_portal_repository.dart';
import '../domain/hotspot_cards_portal_model.dart';

class HotspotCardsPortalState {
  const HotspotCardsPortalState({
    this.token = '',
    this.tenantId = 1,
    this.user,
    this.capabilities = HotspotPortalCapabilities.empty,
    this.catalog = const [],
    this.cards = const [],
    this.lastPurchase,
    this.loading = false,
    this.refreshing = false,
    this.busyCatalogItemId = '',
    this.busyPurchaseId = '',
    this.error = '',
    this.notice = '',
  });

  final String token;
  final int tenantId;
  final HotspotPortalUser? user;
  final HotspotPortalCapabilities capabilities;
  final List<HotspotCatalogItem> catalog;
  final List<HotspotOwnedCard> cards;
  final HotspotPurchaseResult? lastPurchase;
  final bool loading;
  final bool refreshing;
  final String busyCatalogItemId;
  final String busyPurchaseId;
  final String error;
  final String notice;

  bool get isAuthenticated => token.trim().isNotEmpty && user != null;

  HotspotCardsPortalState copyWith({
    String? token,
    int? tenantId,
    HotspotPortalUser? user,
    bool clearUser = false,
    HotspotPortalCapabilities? capabilities,
    List<HotspotCatalogItem>? catalog,
    List<HotspotOwnedCard>? cards,
    HotspotPurchaseResult? lastPurchase,
    bool clearLastPurchase = false,
    bool? loading,
    bool? refreshing,
    String? busyCatalogItemId,
    String? busyPurchaseId,
    String? error,
    String? notice,
  }) {
    return HotspotCardsPortalState(
      token: token ?? this.token,
      tenantId: tenantId ?? this.tenantId,
      user: clearUser ? null : (user ?? this.user),
      capabilities: capabilities ?? this.capabilities,
      catalog: catalog ?? this.catalog,
      cards: cards ?? this.cards,
      lastPurchase:
          clearLastPurchase ? null : (lastPurchase ?? this.lastPurchase),
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      busyCatalogItemId: busyCatalogItemId ?? this.busyCatalogItemId,
      busyPurchaseId: busyPurchaseId ?? this.busyPurchaseId,
      error: error ?? this.error,
      notice: notice ?? this.notice,
    );
  }
}

class HotspotCardsPortalController
    extends StateNotifier<HotspotCardsPortalState> {
  HotspotCardsPortalController(this._repo)
      : super(const HotspotCardsPortalState());

  final HotspotCardsPortalRepository _repo;

  Future<void> login({
    required String scheme,
    required String host,
    required String username,
    required String password,
    int tenantId = 1,
  }) async {
    state = state.copyWith(
      loading: true,
      tenantId: tenantId,
      error: '',
      notice: '',
      clearLastPurchase: true,
    );
    try {
      final baseUrl = normalizeApiBaseUrl(scheme: scheme, host: host);
      final result = await _repo.login(
        baseUrl: baseUrl,
        username: username,
        password: password,
        tenantId: tenantId,
      );
      if (result.token.isEmpty) {
        throw ApiException(
          code: 'token_required',
          message: 'تعذر فتح جلسة بوابة الكروت. حاول مرة أخرى.',
        );
      }
      state = state.copyWith(
        token: result.token,
        user: result.user,
        loading: false,
        notice: 'تم تسجيل الدخول إلى بوابة الكروت.',
      );
      await refresh(silent: true);
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: visibleErrorMessage(error),
      );
    }
  }

  Future<void> refresh({bool silent = false}) async {
    final token = state.token;
    if (token.isEmpty) return;
    state = state.copyWith(
      refreshing: !silent,
      error: '',
      notice: silent ? state.notice : '',
    );
    try {
      final profile = await _repo.me(token: token, tenantId: state.tenantId);
      final catalog = profile.capabilities.catalog
          ? await _repo.catalog(token: token, tenantId: state.tenantId)
          : const <HotspotCatalogItem>[];
      final cards = profile.capabilities.myCards
          ? await _repo.myCards(token: token, tenantId: state.tenantId)
          : const <HotspotOwnedCard>[];
      state = state.copyWith(
        user: profile.user,
        capabilities: profile.capabilities,
        catalog: catalog,
        cards: cards,
        refreshing: false,
      );
    } catch (error) {
      state = state.copyWith(
        refreshing: false,
        error: visibleErrorMessage(error),
      );
    }
  }

  Future<void> purchase(HotspotCatalogItem item) async {
    if (state.token.isEmpty || state.busyCatalogItemId.isNotEmpty) return;
    state = state.copyWith(
      busyCatalogItemId: item.id,
      error: '',
      notice: '',
      clearLastPurchase: true,
    );
    try {
      final result = await _repo.purchase(
        token: state.token,
        catalogItemId: item.id,
        tenantId: state.tenantId,
        clientRequestId:
            'flutter-${DateTime.now().toUtc().microsecondsSinceEpoch}',
      );
      state = state.copyWith(
        lastPurchase: result,
        busyCatalogItemId: '',
        notice: 'تم شراء الكرت وخصم القيمة من المحفظة.',
      );
      await refresh(silent: true);
    } catch (error) {
      state = state.copyWith(
        busyCatalogItemId: '',
        error: visibleErrorMessage(error),
      );
    }
  }

  Future<void> sendSms(HotspotOwnedCard card, String phone) async {
    if (state.token.isEmpty || state.busyPurchaseId.isNotEmpty) return;
    state = state.copyWith(
      busyPurchaseId: card.purchaseId,
      error: '',
      notice: '',
    );
    try {
      await _repo.sendSms(
        token: state.token,
        purchaseId: card.purchaseId,
        phone: phone,
        tenantId: state.tenantId,
      );
      state = state.copyWith(
        busyPurchaseId: '',
        notice: 'تم إرسال بيانات الكرت للعميل.',
      );
    } catch (error) {
      state = state.copyWith(
        busyPurchaseId: '',
        error: visibleErrorMessage(error),
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(error: '', notice: '');
  }

  void logout() {
    state = const HotspotCardsPortalState();
  }
}

final hotspotCardsPortalControllerProvider = StateNotifierProvider<
    HotspotCardsPortalController, HotspotCardsPortalState>((ref) {
  return HotspotCardsPortalController(
    ref.watch(hotspotCardsPortalRepositoryProvider),
  );
});
