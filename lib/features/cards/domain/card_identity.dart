/// «تعديل بيانات الكرت» (owner 2026-10-05): the card number (its RADIUS
/// login) and/or its password, exactly as the operator types them.
///
/// Rules shared by the card checker and the «المزيد» sheet of «المتصلون»:
/// - each field is optional — empty or unchanged means «leave as is»;
/// - Save needs at least one real change;
/// - nothing is ever generated here (the separate «generate password»
///   features stay where they are);
/// - Arabic-Indic digits are read as Latin (the server does the same).
library;

import '../../../core/format/number_input.dart';
import 'card_parsing.dart';
import 'card_check.dart';

/// What the dialog sends: `null` = that field is not changed.
class CardIdentityDraft {
  const CardIdentityDraft({this.username, this.password});

  final String? username;
  final String? password;

  bool get isEmpty => username == null && password == null;

  /// The PATCH body — only the changed fields.
  Map<String, dynamic> toJson() => {
        if (username != null) 'username': username,
        if (password != null) 'password': password,
      };
}

final RegExp _cardNameRe = RegExp(r'^[A-Za-z0-9._@-]{3,64}$');

/// Reads the two fields against the card's current values. Returns either a
/// draft (possibly empty = nothing changed) or an Arabic error.
({CardIdentityDraft? draft, String? error}) readCardIdentityInput({
  required String currentUsername,
  required String currentPassword,
  required String typedUsername,
  required String typedPassword,
  bool passwordless = false,
}) {
  final u = latinizeDigits(typedUsername).trim();
  final p = passwordless ? '' : latinizeDigits(typedPassword).trim();
  final userChanged =
      u.isNotEmpty && u.toLowerCase() != currentUsername.trim().toLowerCase();
  final pwChanged = p.isNotEmpty && p != currentPassword;
  if (userChanged && !_cardNameRe.hasMatch(u)) {
    return (
      draft: null,
      error: 'رقم الكرت: أحرف لاتينية وأرقام و . _ - @ فقط، '
          'من 3 إلى 64، بلا مسافات.',
    );
  }
  if (userChanged && u.toLowerCase().startsWith('rtr-')) {
    return (
      draft: null,
      error: 'البادئة «rtr-» محجوزة لحسابات إدارة الراوترات.',
    );
  }
  if (pwChanged && RegExp(r'\s').hasMatch(p)) {
    return (draft: null, error: 'كلمة المرور لا تقبل مسافات.');
  }
  if (pwChanged && p.length > 64) {
    return (draft: null, error: 'كلمة المرور أطول من 64 حرفًا.');
  }
  return (
    draft: CardIdentityDraft(
      username: userChanged ? u : null,
      password: pwChanged ? p : null,
    ),
    error: null,
  );
}

/// `PATCH /api/v1/cards/<id>` response.
class CardIdentityResult {
  CardIdentityResult({
    required this.card,
    this.changed = false,
    this.renamed = false,
    this.passwordChanged = false,
    this.oldUsername = '',
    this.username = '',
    this.kicked = false,
  });

  final CardCheckResult card;
  final bool changed;
  final bool renamed;
  final bool passwordChanged;
  final String oldUsername;
  final String username;
  final bool kicked;

  factory CardIdentityResult.fromJson(Map<String, dynamic> json) {
    final card = json['card'];
    return CardIdentityResult(
      card: CardCheckResult.fromJson(
        card is Map<String, dynamic> ? card : const {},
      ),
      changed: cardParseBool(json['changed']),
      renamed: cardParseBool(json['renamed']),
      passwordChanged: cardParseBool(json['password_changed']),
      oldUsername: (json['old_username'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      kicked: cardParseBool(json['kicked']),
    );
  }

  /// One Arabic line for the snackbar.
  String get message {
    if (!changed) return 'لم يتغيّر شيء — رقم الكرت وكلمة المرور كما هما.';
    final parts = <String>[
      if (renamed) 'رقم الكرت: من $oldUsername إلى $username',
      if (passwordChanged) 'تم تغيير كلمة المرور',
    ];
    return 'تم تعديل بيانات الكرت — ${parts.join(' · ')}.'
        '${kicked ? ' وقُطعت الجلسة النشطة ليعيد الدخول بالبيانات الجديدة.' : ''}';
  }
}
