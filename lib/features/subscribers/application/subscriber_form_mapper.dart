import 'package:flutter/material.dart';

import '../domain/subscriber_model.dart';

/// Form-state container for selections the form does not track in text
/// controllers (dropdowns + toggles + the expiry date + the working
/// days set).
class SubscriberFormSelections {
  const SubscriberFormSelections({
    required this.status,
    required this.userType,
    required this.mtService,
    required this.subscriptionType,
    required this.expireAt,
    required this.workingDays,
    required this.disableOnFirstUse,
    required this.notifyOnLogin,
    required this.autoRenew,
  });

  final String status;
  final String userType;
  final String mtService;
  final String subscriptionType;
  final DateTime? expireAt;
  final Set<String> workingDays;
  final bool disableOnFirstUse;
  final bool notifyOnLogin;
  final bool autoRenew;
}

/// Pours a server-returned [Subscriber] into the form's text
/// controllers. The matching selections (status / dropdowns / toggles)
/// are returned by [selectionsFromSubscriber] so the screen can
/// `setState` once with the full state restored.
void applySubscriberToForm(
  Subscriber s,
  Map<String, TextEditingController> c,
) {
  c['username']!.text = s.username;
  c['full_name']!.text = s.fullName;
  c['mobile']!.text = s.mobile;
  c['email']!.text = s.email;
  c['beneficiary_ref']!.text = s.beneficiaryRef;
  c['remark']!.text = s.remark;
  c['mac_lock']!.text = s.macLock;
  c['static_ip']!.text = s.staticIp;
  c['plan_id']!.text = s.planId?.toString() ?? '';
  c['mt_profile']!.text = s.mtProfile;
  c['mt_rate_limit']!.text = s.mtRateLimit;
  c['mt_ip_pool']!.text = s.mtIpPool;
  c['mt_comment']!.text = s.mtComment;
  c['dns1']!.text = s.primaryDnsPpp;
  c['dns2']!.text = s.secondaryDnsPpp;
  c['simultaneous_use']!.text = s.overrideConcurrent.toString();
  c['session_timeout']!.text = s.sessionTimeout?.toString() ?? '';
  c['idle_timeout']!.text = s.idleTimeout?.toString() ?? '';
  c['called_station_id']!.text = s.calledStationId;
  c['allowed_hours']!.text = s.allowedHours;
  c['notify_email']!.text = s.notifyEmail;
  c['notify_mobile']!.text = s.notifyMobile;
  c['subscription_days']!.text = s.subscriptionDays?.toString() ?? '';
  c['notes']!.text = s.notes;
  c['tags']!.text = s.tags.join(', ');
}

SubscriberFormSelections selectionsFromSubscriber(Subscriber s) =>
    SubscriberFormSelections(
      status: s.status,
      userType: s.userType,
      mtService: s.mtService,
      subscriptionType: s.subscriptionType,
      expireAt: s.expireAt,
      workingDays: Set<String>.from(s.workingDays),
      disableOnFirstUse: s.disableOnFirstUse,
      notifyOnLogin: s.notifyOnLogin,
      autoRenew: s.autoRenewal,
    );

/// Builds a [Subscriber] from the form's controllers + selections.
Subscriber buildSubscriberFromForm(
  Map<String, TextEditingController> c,
  SubscriberFormSelections sel,
) =>
    Subscriber(
      username: c['username']!.text.trim(),
      password: c['password']!.text,
      fullName: c['full_name']!.text.trim(),
      mobile: c['mobile']!.text.trim(),
      email: c['email']!.text.trim(),
      beneficiaryRef: c['beneficiary_ref']!.text.trim(),
      planId: int.tryParse(c['plan_id']!.text.trim()),
      status: sel.status,
      userType: sel.userType,
      expireAt: sel.expireAt,
      macLock: c['mac_lock']!.text.trim(),
      staticIp: c['static_ip']!.text.trim(),
      remark: c['remark']!.text.trim(),
      primaryDnsPpp: c['dns1']!.text.trim(),
      secondaryDnsPpp: c['dns2']!.text.trim(),
      overrideConcurrent:
          int.tryParse(c['simultaneous_use']!.text.trim()) ?? 0,
      workingDaysCsv: sel.workingDays.join(','),
      autoRenewal: sel.autoRenew,
      mtProfile: c['mt_profile']!.text.trim(),
      mtService: sel.mtService,
      mtRateLimit: c['mt_rate_limit']!.text.trim(),
      mtIpPool: c['mt_ip_pool']!.text.trim(),
      mtComment: c['mt_comment']!.text.trim(),
      sessionTimeout: int.tryParse(c['session_timeout']!.text.trim()),
      idleTimeout: int.tryParse(c['idle_timeout']!.text.trim()),
      calledStationId: c['called_station_id']!.text.trim(),
      allowedHours: c['allowed_hours']!.text.trim(),
      disableOnFirstUse: sel.disableOnFirstUse,
      notifyOnLogin: sel.notifyOnLogin,
      notifyEmail: c['notify_email']!.text.trim(),
      notifyMobile: c['notify_mobile']!.text.trim(),
      subscriptionType: sel.subscriptionType,
      subscriptionDays: int.tryParse(c['subscription_days']!.text.trim()),
      notes: c['notes']!.text.trim(),
      tags: c['tags']!
          .text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
