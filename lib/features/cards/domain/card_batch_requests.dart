/// Request DTOs for card-batch create / update endpoints.
library;

import '../../../core/format/money_limits.dart';

/// Most cards one generation may create — the server's hard cap
/// (`CARDS_HARD_MAX_PER_BATCH`); 1,000,000 used to be accepted and loaded
/// the server for minutes.
int get kMaxCardsPerBatch => AppLimits.maxCardsPerBatch;

/// Above this many cards the form asks for confirmation first.
const int kConfirmCardsAbove = 1000;

/// Arabic error for a card count, or null.
String? validateCardCount(int? n) {
  if (n == null || n < 1) return 'أدخل عددًا صحيحًا (1 فأكثر)';
  if (n > kMaxCardsPerBatch) {
    return 'الحدّ الأعلى $kMaxCardsPerBatch بطاقة في الدفعة الواحدة.';
  }
  return null;
}

/// Username prefix/suffix as the server stores it: spaces removed,
/// Arabic-Indic digits → Latin, lower-case.
String normalizeCardAffix(String raw) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final b = StringBuffer();
  for (final ch in raw.split('')) {
    if (ch.trim().isEmpty) continue;
    final a = arabic.indexOf(ch);
    final f = persian.indexOf(ch);
    b.write(a >= 0 ? '$a' : (f >= 0 ? '$f' : ch));
  }
  return b.toString().toLowerCase();
}

/// The server rule for a card prefix/suffix: Latin letters, digits and
/// «_ - . @», at most 16 characters.
String? validateCardAffix(String raw) {
  final v = normalizeCardAffix(raw);
  if (v.isEmpty) return null;
  if (v.length > 16) return 'البادئة/اللاحقة 16 حرفًا على الأكثر.';
  if (!RegExp(r'^[a-z0-9_.@-]+$').hasMatch(v)) {
    return 'أحرف لاتينية وأرقام و _ - . @ فقط.';
  }
  return null;
}

/// Shortest card username the forms accept (web generator `min="4"`).
const int kCardUsernameLengthMin = 4;

/// Longest card password the forms accept.
const int kCardPasswordLengthMax = 32;

/// Most devices one card may allow — the server clamps `device_count` to
/// 0..50 (0 = the global card setting).
const int kCardDeviceCountMax = 50;

/// «عدد الأجهزة» choices of the generator AND the batch editor (web: a
/// 0–50 number field; 0 = the global card setting).
const List<int> kCardDeviceCountOptions = [
  0, 1, 2, 3, 4, 5, 6, 8, 10, 15, 20, 30, 50, //
];

/// [kCardDeviceCountOptions] plus [current] when a stored batch holds a
/// value outside the list (e.g. 7) — the dropdown must show what is saved.
List<int> cardDeviceCountOptionsFor(int current) {
  if (current < 0 ||
      current > kCardDeviceCountMax ||
      kCardDeviceCountOptions.contains(current)) {
    return kCardDeviceCountOptions;
  }
  return [...kCardDeviceCountOptions, current]..sort();
}

/// Label of one «عدد الأجهزة» choice.
String cardDeviceCountLabel(int n) =>
    n <= 0 ? '0 = الافتراض العام (من الإعدادات)' : '$n';

/// A stored/absent device count as the forms show it: missing or invalid →
/// 0 (the global setting), never a silent 1.
int normalizeCardDeviceCount(int? n) =>
    (n == null || n < 0) ? 0 : (n > kCardDeviceCountMax ? kCardDeviceCountMax : n);

/// «عند بلوغ حدّ الأجهزة» (`device_limit_mode`) choices, web wording.
const Map<String, String> kCardDeviceLimitModeLabels = {
  '': 'الافتراض العام للكروت (من الإعدادات)',
  'reject': 'رفض الجلسة الجديدة',
  'replace': 'استبدال — فصل أقدم جلسة والسماح',
};

/// `reject` / `replace`, anything else → '' (follow the global setting).
String normalizeDeviceLimitMode(Object? raw) {
  final v = (raw ?? '').toString().trim().toLowerCase();
  return (v == 'reject' || v == 'replace') ? v : '';
}

class GenerateBatchRequest {
  GenerateBatchRequest({
    required this.planId,
    required this.count,
    this.packageName = '',
    this.usernamePrefix = '',
    this.usernameSuffix = '',
    this.startsWithOrEndsWith = '',
    this.prefixOrSuffixValue = '',
    this.usernameLength = 8,
    this.passwordLength = 6,
    this.passwordGenerationType = 'medium',
    this.timeValue = 0,
    this.timeUnit = 'days',
    this.deviceCount = 0,
    this.deviceLimitMode = '',
    this.pricePerCard = 0,
    this.totalPrice = 0,
    this.totalQuotaMb = 0,
    this.serviceName = '',
    this.notes = '',
    this.loginWithoutPassword = false,
    this.includeBatchNumber = false,
  });

  /// «عند بلوغ حدّ الأجهزة»: '' (global setting) | `reject` | `replace`.
  final String deviceLimitMode;

  /// «تضمين رقم الحزمة»: the batch id (digits) after the prefix, inside the
  /// total username length (web generator semantics).
  final bool includeBatchNumber;

  /// «رقم فقط»: cards log in with the number alone (no password).
  final bool loginWithoutPassword;
  final int planId;
  final int count;
  final String packageName;
  final String usernamePrefix;
  final String usernameSuffix;
  final String startsWithOrEndsWith;
  final String prefixOrSuffixValue;
  final int usernameLength;
  final int passwordLength;
  final String passwordGenerationType;
  final int timeValue;
  final String timeUnit;
  final int deviceCount;
  final num pricePerCard;
  final num totalPrice;
  final int totalQuotaMb;
  final String serviceName;
  final String notes;

  Map<String, dynamic> toBody() => {
        'plan_id': planId,
        'count': count,
        if (packageName.isNotEmpty) 'package_name': packageName,
        if (usernamePrefix.isNotEmpty) 'username_prefix': usernamePrefix,
        if (usernameSuffix.isNotEmpty) 'username_suffix': usernameSuffix,
        if (startsWithOrEndsWith.isNotEmpty)
          'starts_with_or_ends_with': startsWithOrEndsWith,
        if (prefixOrSuffixValue.isNotEmpty)
          'prefix_or_suffix_value': prefixOrSuffixValue,
        'username_length': usernameLength,
        'password_length': loginWithoutPassword ? 0 : passwordLength,
        // ALWAYS explicit: a network whose default is «أرقام فقط» used to
        // ignore the app's password choice when the key was absent.
        'login_without_password': loginWithoutPassword,
        if (includeBatchNumber) 'include_batch_number': true,
        'password_generation_type': passwordGenerationType,
        'time_value': timeValue,
        'time_unit': timeUnit,
        'device_count': deviceCount,
        'device_limit_mode': normalizeDeviceLimitMode(deviceLimitMode),
        'price_per_card': pricePerCard,
        'total_price': totalPrice,
        'total_quota_mb': totalQuotaMb,
        if (serviceName.isNotEmpty) 'service_name': serviceName,
        'notes': notes,
      };
}

/// PATCH body of the batch editor. Only what the server lets an operator
/// change after generation: the structural fields (count, username
/// prefix/suffix/length, password length/type, include-batch-number and its
/// position) are locked server-side (422) and are never sent; neither are
/// `phone_only_login` (no server reader) nor `duration_mode` (derived from
/// `count_from_first_connect`).
class UpdateBatchRequest {
  UpdateBatchRequest({
    required this.planId,
    this.packageName = '',
    this.status = 'active',
    this.pricePerCard = 0,
    this.priceBulk = 0,
    this.totalPrice = 0,
    this.totalQuotaMb = 0,
    this.serviceName = '',
    this.managerId = 0,
    this.timeValue = 0,
    this.timeUnit = 'days',
    this.deviceCount = 0,
    this.deviceLimitMode = '',
    this.validityAfterFirstLoginDays = 0,
    this.countBySeconds = false,
    this.countFromFirstConnect = true,
    this.onQuotaExhaust = 'stop',
    this.autoRenewAfterFirstUse = false,
    this.switchToMacOnConnect = false,
    this.lockToMacOnClose = false,
    this.loginWithoutPassword = false,
    this.notes = '',
  });

  final int planId;
  final String packageName;
  final String status;
  final num pricePerCard;
  final num priceBulk;
  final num totalPrice;
  final int totalQuotaMb;
  final String serviceName;
  final int managerId;
  final int timeValue;
  final String timeUnit;

  /// 0 = the global card setting; 1..50 an explicit limit.
  final int deviceCount;

  /// «عند بلوغ حدّ الأجهزة»: '' (global setting) | `reject` | `replace`.
  final String deviceLimitMode;
  final int validityAfterFirstLoginDays;
  final bool countBySeconds;
  final bool countFromFirstConnect;
  final String onQuotaExhaust;
  final bool autoRenewAfterFirstUse;
  final bool switchToMacOnConnect;
  final bool lockToMacOnClose;

  /// «الدخول برقم البطاقة فقط (بلا كلمة مرور)».
  final bool loginWithoutPassword;
  final String notes;

  Map<String, dynamic> toBody() => {
        'plan_id': planId,
        'package_name': packageName,
        'status': status,
        'price_per_card': pricePerCard,
        'price_bulk': priceBulk,
        'total_price': totalPrice,
        'total_quota_mb': totalQuotaMb,
        'service_name': serviceName,
        'manager_id': managerId,
        'time_value': timeValue,
        'time_unit': timeUnit,
        'device_count': normalizeCardDeviceCount(deviceCount),
        'device_limit_mode': normalizeDeviceLimitMode(deviceLimitMode),
        'validity_after_first_login_days': validityAfterFirstLoginDays,
        'count_by_seconds': countBySeconds,
        'count_from_first_connect': countFromFirstConnect,
        'on_quota_exhaust': onQuotaExhaust,
        'auto_renew_after_first_use': autoRenewAfterFirstUse,
        'switch_to_mac_on_connect': switchToMacOnConnect,
        'lock_to_mac_on_close': lockToMacOnClose,
        'login_without_password': loginWithoutPassword,
        'notes': notes,
      };
}
