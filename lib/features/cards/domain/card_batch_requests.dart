/// Request DTOs for card-batch create / update endpoints.
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
    this.deviceCount = 1,
    this.pricePerCard = 0,
    this.totalPrice = 0,
    this.totalQuotaMb = 0,
    this.serviceName = '',
    this.notes = '',
  });

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
        'password_length': passwordLength,
        'password_generation_type': passwordGenerationType,
        'time_value': timeValue,
        'time_unit': timeUnit,
        'device_count': deviceCount,
        'price_per_card': pricePerCard,
        'total_price': totalPrice,
        'total_quota_mb': totalQuotaMb,
        if (serviceName.isNotEmpty) 'service_name': serviceName,
        'notes': notes,
      };
}

class UpdateBatchRequest {
  UpdateBatchRequest({
    required this.planId,
    required this.count,
    this.packageName = '',
    this.status = 'active',
    this.pricePerCard = 0,
    this.priceBulk = 0,
    this.totalPrice = 0,
    this.totalQuotaMb = 0,
    this.serviceName = '',
    this.managerId = 0,
    this.usernamePrefix = '',
    this.usernameSuffix = '',
    this.usernameLength = 8,
    this.passwordLength = 6,
    this.passwordGenerationType = 'medium',
    this.includeBatchNumber = false,
    this.startsWithOrEndsWith = '',
    this.prefixOrSuffixValue = '',
    this.timeValue = 0,
    this.timeUnit = 'days',
    this.deviceCount = 1,
    this.durationMode = 'time_unit',
    this.validityAfterFirstLoginDays = 0,
    this.countBySeconds = false,
    this.countFromFirstConnect = true,
    this.onQuotaExhaust = 'stop',
    this.autoRenewAfterFirstUse = false,
    this.switchToMacOnConnect = false,
    this.lockToMacOnClose = false,
    this.phoneOnlyLogin = false,
    this.notes = '',
  });

  final int planId;
  final int count;
  final String packageName;
  final String status;
  final num pricePerCard;
  final num priceBulk;
  final num totalPrice;
  final int totalQuotaMb;
  final String serviceName;
  final int managerId;
  final String usernamePrefix;
  final String usernameSuffix;
  final int usernameLength;
  final int passwordLength;
  final String passwordGenerationType;
  final bool includeBatchNumber;
  final String startsWithOrEndsWith;
  final String prefixOrSuffixValue;
  final int timeValue;
  final String timeUnit;
  final int deviceCount;
  final String durationMode;
  final int validityAfterFirstLoginDays;
  final bool countBySeconds;
  final bool countFromFirstConnect;
  final String onQuotaExhaust;
  final bool autoRenewAfterFirstUse;
  final bool switchToMacOnConnect;
  final bool lockToMacOnClose;
  final bool phoneOnlyLogin;
  final String notes;

  Map<String, dynamic> toBody() => {
        'plan_id': planId,
        'count': count,
        'package_name': packageName,
        'status': status,
        'price_per_card': pricePerCard,
        'price_bulk': priceBulk,
        'total_price': totalPrice,
        'total_quota_mb': totalQuotaMb,
        'service_name': serviceName,
        'manager_id': managerId,
        'username_prefix': usernamePrefix,
        'username_suffix': usernameSuffix,
        'username_length': usernameLength,
        'password_length': passwordLength,
        'password_generation_type': passwordGenerationType,
        'include_batch_number': includeBatchNumber,
        'starts_with_or_ends_with': startsWithOrEndsWith,
        'prefix_or_suffix_value': prefixOrSuffixValue,
        'time_value': timeValue,
        'time_unit': timeUnit,
        'device_count': deviceCount,
        'duration_mode': durationMode,
        'validity_after_first_login_days': validityAfterFirstLoginDays,
        'count_by_seconds': countBySeconds,
        'count_from_first_connect': countFromFirstConnect,
        'on_quota_exhaust': onQuotaExhaust,
        'auto_renew_after_first_use': autoRenewAfterFirstUse,
        'switch_to_mac_on_connect': switchToMacOnConnect,
        'lock_to_mac_on_close': lockToMacOnClose,
        'phone_only_login': phoneOnlyLogin,
        'notes': notes,
      };
}
