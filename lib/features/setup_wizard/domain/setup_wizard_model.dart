class SetupWizardOverview {
  const SetupWizardOverview({
    required this.health,
    required this.serverReadiness,
    required this.recentRuns,
    required this.runsSummary,
    required this.safeOperations,
  });

  final SetupWizardHealth health;
  final SetupWizardServerReadiness serverReadiness;
  final List<SetupWizardRun> recentRuns;
  final SetupWizardRunsSummary runsSummary;
  final SetupWizardSafeOperations safeOperations;

  factory SetupWizardOverview.fromJson(Map<String, dynamic> json) {
    final rawRuns = json['recent_runs'];
    return SetupWizardOverview(
      health: SetupWizardHealth.fromJson(_map(json['health'])),
      serverReadiness:
          SetupWizardServerReadiness.fromJson(_map(json['server_readiness'])),
      recentRuns: rawRuns is List
          ? rawRuns
              .whereType<Map>()
              .map((item) => SetupWizardRun.fromJson(_map(item)))
              .toList()
          : const [],
      runsSummary: SetupWizardRunsSummary.fromJson(_map(json['runs_summary'])),
      safeOperations:
          SetupWizardSafeOperations.fromJson(_map(json['safe_operations'])),
    );
  }
}

class SetupWizardHealth {
  const SetupWizardHealth({
    required this.overall,
    required this.checkedAt,
    required this.durationMs,
    required this.version,
    required this.checks,
  });

  final String overall;
  final String checkedAt;
  final int durationMs;
  final String version;
  final List<SetupWizardHealthCheck> checks;

  factory SetupWizardHealth.fromJson(Map<String, dynamic> json) {
    final rawChecks = json['checks'];
    final checks = <SetupWizardHealthCheck>[];
    if (rawChecks is Map) {
      for (final entry in rawChecks.entries) {
        checks.add(
          SetupWizardHealthCheck.fromJson(
            entry.key.toString(),
            _map(entry.value),
          ),
        );
      }
    }
    return SetupWizardHealth(
      overall: _string(json['overall'], fallback: 'unknown'),
      checkedAt: _string(json['checked_at']),
      durationMs: _int(json['duration_ms']),
      version: _string(json['version']),
      checks: checks,
    );
  }

  String get label => switch (overall) {
        'healthy' => 'سليم',
        'degraded' => 'يحتاج متابعة',
        'critical' => 'حرج',
        _ => 'غير معروف',
      };
}

class SetupWizardHealthCheck {
  const SetupWizardHealthCheck({
    required this.key,
    required this.status,
    required this.title,
    required this.details,
  });

  final String key;
  final String status;
  final String title;
  final String details;

  factory SetupWizardHealthCheck.fromJson(
    String key,
    Map<String, dynamic> json,
  ) {
    return SetupWizardHealthCheck(
      key: key,
      status: _string(json['status'], fallback: 'unknown'),
      title: _arabicOr(
        _string(json['title_ar']),
        _healthLabels[key] ?? key,
      ),
      details: _string(json['details']),
    );
  }

  String get statusLabel => switch (status) {
        'ok' => 'سليم',
        'warn' => 'تنبيه',
        'fail' => 'فشل',
        _ => 'غير معروف',
      };
}

class SetupWizardServerReadiness {
  const SetupWizardServerReadiness({
    required this.status,
    required this.configured,
    required this.nextAction,
    required this.checks,
    required this.diagnostics,
  });

  final String status;
  final bool configured;
  final String nextAction;
  final List<SetupWizardReadinessCheck> checks;
  final List<SetupWizardDiagnostic> diagnostics;

  factory SetupWizardServerReadiness.fromJson(Map<String, dynamic> json) {
    final rawChecks = json['checks'];
    final checks = <SetupWizardReadinessCheck>[];
    if (rawChecks is Map) {
      for (final entry in rawChecks.entries) {
        checks.add(
          SetupWizardReadinessCheck.fromJson(
            entry.key.toString(),
            _map(entry.value),
          ),
        );
      }
    }
    final rawDiagnostics = json['diagnostics'];
    return SetupWizardServerReadiness(
      status: _string(json['status'], fallback: 'unknown'),
      configured: _bool(json['configured']),
      nextAction: _readinessNextAction(
        _string(json['status']),
        _string(json['next_action_ar']),
      ),
      checks: checks,
      diagnostics: rawDiagnostics is List
          ? rawDiagnostics
              .whereType<Map>()
              .map((item) => SetupWizardDiagnostic.fromJson(_map(item)))
              .toList()
          : const [],
    );
  }

  String get label => switch (status) {
        'ready' => 'جاهز',
        'partial' => 'جزئي',
        'blocked' => 'محظور',
        'disabled' => 'معطل',
        _ => 'غير معروف',
      };
}

class SetupWizardReadinessCheck {
  const SetupWizardReadinessCheck({
    required this.key,
    required this.status,
    required this.detail,
  });

  final String key;
  final String status;
  final String detail;

  factory SetupWizardReadinessCheck.fromJson(
    String key,
    Map<String, dynamic> json,
  ) {
    return SetupWizardReadinessCheck(
      key: key,
      status: _string(json['status'], fallback: 'unknown'),
      detail: _string(json['detail']),
    );
  }

  String get label => _readinessLabels[key] ?? key;
  String get statusLabel => switch (status) {
        'success' => 'سليم',
        'warning' => 'تنبيه',
        'blocked' => 'محظور',
        'disabled' => 'معطل',
        _ => 'غير معروف',
      };
}

class SetupWizardDiagnostic {
  const SetupWizardDiagnostic({
    required this.code,
    required this.title,
    required this.explanation,
  });

  final String code;
  final String title;
  final String explanation;

  factory SetupWizardDiagnostic.fromJson(Map<String, dynamic> json) {
    return SetupWizardDiagnostic(
      code: _string(json['code']),
      title: _arabicOr(
        _string(json['arabic_title']),
        _diagnosticTitle(_string(json['code'])),
      ),
      explanation: _arabicOr(
        _string(json['explanation_ar']).isNotEmpty
            ? _string(json['explanation_ar'])
            : _string(json['ar_explanation']),
        _diagnosticExplanation(_string(json['code'])),
      ),
    );
  }
}

class SetupWizardRun {
  const SetupWizardRun({
    required this.id,
    required this.state,
    required this.stateLabel,
    required this.routerName,
    required this.routerType,
    required this.routerVpnAddress,
    required this.isTerminal,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String state;
  final String stateLabel;
  final String routerName;
  final String routerType;
  final String routerVpnAddress;
  final bool isTerminal;
  final String createdAt;
  final String updatedAt;

  factory SetupWizardRun.fromJson(Map<String, dynamic> json) {
    return SetupWizardRun(
      id: _int(json['id']),
      state: _string(json['state'], fallback: 'UNKNOWN'),
      stateLabel: _runStateLabel(
        _string(json['state']),
        _string(json['ar_state_label']),
      ),
      routerName: _string(json['router_name']),
      routerType: _string(json['router_type']),
      routerVpnAddress: _string(json['router_vpn_ip']),
      isTerminal: _bool(json['is_terminal']),
      createdAt: _string(json['created_at']),
      updatedAt: _string(json['updated_at']),
    );
  }

  String get routerTypeLabel => switch (routerType) {
        'hotspot' => 'بوابة دخول',
        'pppoe' => 'اشتراكات ثابتة',
        'mixed' => 'مختلط',
        '' => '',
        _ => routerType,
      };
}

class SetupWizardRunsSummary {
  const SetupWizardRunsSummary({
    required this.recentCount,
    required this.activeCount,
    required this.byState,
  });

  final int recentCount;
  final int activeCount;
  final Map<String, int> byState;

  factory SetupWizardRunsSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['by_state'];
    return SetupWizardRunsSummary(
      recentCount: _int(json['recent_count']),
      activeCount: _int(json['active_count']),
      byState: raw is Map
          ? raw.map((key, value) => MapEntry(key.toString(), _int(value)))
          : const {},
    );
  }
}

class SetupWizardSafeOperations {
  const SetupWizardSafeOperations({
    required this.canCreateRun,
    required this.canApplyRouterChanges,
    required this.canApplyServerPeer,
    required this.canPlanPhases,
    required this.canRunLifecycle,
    required this.reason,
  });

  final bool canCreateRun;
  final bool canApplyRouterChanges;
  final bool canApplyServerPeer;
  final bool canPlanPhases;
  final bool canRunLifecycle;
  final String reason;

  factory SetupWizardSafeOperations.fromJson(Map<String, dynamic> json) {
    return SetupWizardSafeOperations(
      canCreateRun: _bool(json['can_create_run']),
      canApplyRouterChanges: _bool(json['can_apply_router_changes']),
      canApplyServerPeer: _bool(json['can_apply_server_peer']),
      canPlanPhases: _bool(json['can_plan_phases']),
      canRunLifecycle: _bool(json['can_run_lifecycle']),
      reason: _string(json['reason_ar']),
    );
  }
}

class SetupWizardScriptResult {
  const SetupWizardScriptResult({
    required this.run,
    required this.script,
    required this.shortCode,
    required this.sha256,
    required this.expiresAt,
    required this.warning,
    required this.containsSensitiveValues,
  });

  final SetupWizardRun run;
  final String script;
  final String shortCode;
  final String sha256;
  final String expiresAt;
  final String warning;
  final bool containsSensitiveValues;

  factory SetupWizardScriptResult.fromJson(Map<String, dynamic> json) {
    return SetupWizardScriptResult(
      run: SetupWizardRun.fromJson(_map(json['run'])),
      script: _string(json['script']),
      shortCode: _string(json['short_code']),
      sha256: _string(json['sha256']),
      expiresAt: _string(json['expires_at']),
      warning: _string(json['warning_ar']),
      containsSensitiveValues: _bool(json['script_contains_sensitive_values']),
    );
  }
}

class SetupWizardPhasePlanner {
  const SetupWizardPhasePlanner({
    required this.phase,
    required this.title,
    required this.description,
    required this.requiredInputs,
  });

  final String phase;
  final String title;
  final String description;
  final List<String> requiredInputs;

  factory SetupWizardPhasePlanner.fromJson(Map<String, dynamic> json) {
    return SetupWizardPhasePlanner(
      phase: _string(json['phase']),
      title: _arabicOr(
        _string(json['title_ar']),
        setupWizardPhaseLabel(_string(json['phase'])),
      ),
      description: _arabicOr(
        _string(json['description_ar']),
        setupWizardPhaseDescription(_string(json['phase'])),
      ),
      requiredInputs: _stringList(json['required_inputs']),
    );
  }
}

class SetupWizardPhasePlanResponse {
  const SetupWizardPhasePlanResponse({
    required this.phase,
    required this.runId,
    required this.plan,
    required this.diagnostics,
  });

  final String phase;
  final int runId;
  final SetupWizardPhasePlan plan;
  final List<SetupWizardDiagnostic> diagnostics;

  factory SetupWizardPhasePlanResponse.fromJson(Map<String, dynamic> json) {
    final rawDiagnostics = json['diagnostics'];
    return SetupWizardPhasePlanResponse(
      phase: _string(json['phase']),
      runId: _int(json['run_id']),
      plan: SetupWizardPhasePlan.fromJson(_map(json['plan'])),
      diagnostics: rawDiagnostics is List
          ? rawDiagnostics
              .whereType<Map>()
              .map((item) => SetupWizardDiagnostic.fromJson(_map(item)))
              .toList()
          : const [],
    );
  }
}

class SetupWizardPhasePlan {
  const SetupWizardPhasePlan({
    required this.phase,
    required this.isApplicable,
    required this.canApply,
    required this.script,
    required this.rollbackScript,
    required this.validationCommands,
    required this.warnings,
    required this.notes,
    required this.tags,
    required this.blockingErrors,
  });

  final String phase;
  final bool isApplicable;
  final bool canApply;
  final String script;
  final String rollbackScript;
  final List<String> validationCommands;
  final List<String> warnings;
  final List<String> notes;
  final List<String> tags;
  final List<String> blockingErrors;

  factory SetupWizardPhasePlan.fromJson(Map<String, dynamic> json) {
    return SetupWizardPhasePlan(
      phase: _string(json['phase']),
      isApplicable: _bool(json['is_applicable']),
      canApply: _bool(json['can_apply']),
      script: _string(json['script']),
      rollbackScript: _string(json['rollback_script']),
      validationCommands: _stringList(json['validation_commands']),
      warnings: _stringList(json['warnings']),
      notes: _stringList(json['notes']),
      tags: _stringList(json['tags']),
      blockingErrors: _stringList(json['blocking_errors']),
    );
  }
}

String setupWizardPhaseLabel(String phase) {
  return switch (phase) {
    'internet' => 'وصلة الإنترنت',
    'vpn_radius' => 'الربط الآمن وخدمة الريدياس',
    'hotspot' => 'بوابة الدخول',
    'broadband' => 'اشتراكات PPPoE',
    'added_services' => 'خدمات إضافية',
    _ => phase.isEmpty ? 'مرحلة غير محددة' : phase,
  };
}

String setupWizardPhaseDescription(String phase) {
  return switch (phase) {
    'internet' => 'تجهيز منفذ الإنترنت الخارج للراوتر.',
    'vpn_radius' => 'تجهيز الربط الآمن وخدمة RADIUS.',
    'hotspot' => 'تجهيز بوابة الدخول على المنافذ المختارة.',
    'broadband' => 'تجهيز PPPoE للخطوط الثابتة.',
    'added_services' => 'إضافة خدمات تشغيلية مثل الحجب أو المواقع المفتوحة.',
    _ => 'مرحلة من مراحل معالج إعداد الراوتر.',
  };
}

String setupWizardInputLabel(String key) {
  return switch (key) {
    'source_type' => 'نوع وصلة الإنترنت',
    'interface' => 'منفذ الإنترنت',
    'nat_enabled' => 'تفعيل NAT',
    'router_vpn_ip' => 'عنوان الراوتر داخل النفق',
    'vps_vpn_ip' => 'عنوان الخادم داخل النفق',
    'vps_public_endpoint' => 'عنوان الخادم العام',
    'radius_secret' => 'سر RADIUS',
    'server_public_key' => 'مفتاح الخادم العام',
    'selected_interfaces' => 'المنافذ المختارة',
    'subnet_base' => 'شبكة Hotspot الأساسية',
    'local_address' => 'عنوان PPPoE المحلي',
    'remote_pool_cidr' => 'مدى عناوين المشتركين',
    'service_key' => 'الخدمة الإضافية',
    'domains' => 'النطاقات',
    'destinations' => 'الوجهات',
    'wireguard_interface_name' => 'واجهة WireGuard',
    _ => key,
  };
}

const _readinessLabels = {
  'readiness_flag': 'تفعيل فحص الجاهزية',
  'interface_configured': 'واجهة النفق',
  'server_ip_configured': 'عنوان الخادم داخل النفق',
  'listen_port_configured': 'منفذ النفق',
  'config_path': 'ملف الإعداد',
  'runner_mode': 'مشغل الأوامر',
  'real_adapter_flag': 'المحول الحقيقي',
  'backup_dir_configured': 'مجلد النسخ الاحتياطي',
  'rollback_strategy_configured': 'خطة الرجوع',
  'timeout_configured': 'مهلة الأوامر',
  'interface_allowlist_configured': 'قائمة الواجهات المسموحة',
  'interface_allowlisted': 'الواجهة مسموحة',
  'wg_command_available': 'قراءة حالة النفق',
  'wg_show_readable': 'مخرجات النفق',
  'wg_interface_exists': 'وجود الواجهة',
  'listen_port_matches': 'مطابقة المنفذ',
  'ip_command_available': 'قراءة العناوين',
  'server_ip_assigned': 'عنوان الخادم مثبت',
  'systemctl_readonly_info': 'حالة الخدمة',
  'peers_readable': 'قراءة النظراء',
};

const _healthLabels = {
  'db_migrations': 'قاعدة البيانات',
  'freeradius_responsive': 'استجابة خدمة الريدياس',
  'wizard_clients_directory': 'مجلد إعدادات الريدياس',
  'wizard_invariants': 'اتساق تشغيلات المعالج',
  'wizard_nas_secrets': 'مطابقة أسرار الراوترات',
  'recent_reconciler_drift': 'انحرافات المطابقة الأخيرة',
  'wg_peers_dir': 'مجلد نظراء النفق',
  'clients_conf_syntax': 'صيغة ملف العملاء',
};

const _stateLabels = {
  'COLLECTING': 'جمع بيانات الراوتر',
  'PLANNING': 'تجهيز السكربت',
  'AWAITING_HANDSHAKE': 'بانتظار تشغيل السكربت',
  'APPLYING_SERVER_PEER': 'تسجيل الراوتر على الخادم',
  'VERIFYING': 'التحقق من الاتصال',
  'REGISTERING': 'تسجيل الراوتر في النظام',
  'COMPLETE': 'اكتمل',
  'BLOCKED': 'متوقف ويحتاج تدخل',
};

const _diagnosticTitles = {
  'server_wg_readiness_disabled': 'فحص جاهزية النفق معطل',
  'missing_wg_interface': 'اسم واجهة النفق غير مضبوط',
  'missing_server_vpn_ip': 'عنوان الخادم داخل النفق غير مضبوط',
  'missing_wg_listen_port': 'منفذ النفق غير مضبوط',
  'missing_backup_dir': 'مجلد النسخ الاحتياطي غير مضبوط',
  'missing_rollback_strategy': 'خطة الرجوع غير مضبوطة',
  'missing_command_timeout': 'مهلة الأوامر غير مضبوطة',
  'missing_interface_allowlist': 'قائمة الواجهات المسموحة غير مضبوطة',
  'wg_interface_not_allowlisted': 'واجهة النفق غير مسموحة',
  'command_runner_disabled': 'مشغل الأوامر معطل',
  'wg_show_unreadable': 'تعذرت قراءة حالة النفق',
  'wg_interface_missing': 'واجهة النفق غير موجودة',
  'wg_listen_port_mismatch': 'منفذ النفق لا يطابق المتوقع',
  'server_vpn_ip_missing': 'عنوان الخادم غير مثبت على الواجهة',
  'ip_addr_unreadable': 'تعذرت قراءة عناوين الواجهة',
};

const _diagnosticExplanations = {
  'server_wg_readiness_disabled':
      'هذا آمن افتراضيًا. فعّل فحص الجاهزية فقط عند تجهيز بيئة اختبار مضبوطة.',
  'missing_wg_interface': 'اضبط اسم واجهة النفق من إعدادات الخادم قبل التجربة.',
  'missing_server_vpn_ip': 'اضبط عنوان الخادم الداخلي الذي ستتصل به الراوترات.',
  'missing_wg_listen_port': 'اضبط منفذ النفق المتوقع قبل المتابعة.',
  'missing_backup_dir': 'حدد مكان حفظ النسخ الاحتياطية قبل أي تطبيق عملي.',
  'missing_rollback_strategy': 'حدد آلية الرجوع قبل تمكين أي خطوة تطبيق.',
  'missing_command_timeout':
      'حدد مهلة قصيرة لأوامر القراءة حتى لا تعلق الفحوص.',
  'missing_interface_allowlist': 'حدد الواجهات المسموح فحصها لحماية الخادم.',
  'wg_interface_not_allowlisted': 'لا يتم فحص واجهة غير مصرّح بها.',
  'command_runner_disabled': 'لا توجد أوامر قراءة حقيقية مفعلة من التطبيق.',
  'wg_show_unreadable': 'صلاحيات القراءة أو مشغل الأوامر غير جاهزة.',
  'wg_interface_missing': 'تحقق من اسم الواجهة على الخادم.',
  'wg_listen_port_mismatch': 'راجع إعدادات منفذ النفق قبل أي تجربة.',
  'server_vpn_ip_missing': 'تحقق من تثبيت عنوان الخادم على واجهة النفق.',
  'ip_addr_unreadable': 'مشغل الأوامر أو صلاحيات القراءة غير جاهزة.',
};

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const {};
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  final text = _string(value).trim();
  return text.isEmpty ? const [] : [text];
}

String _arabicOr(String value, String fallback) {
  final text = value.trim();
  if (text.isNotEmpty && _containsArabic(text)) return text;
  return fallback;
}

String _runStateLabel(String state, String rawLabel) {
  return _arabicOr(rawLabel, _stateLabels[state] ?? state);
}

String _readinessNextAction(String status, String rawAction) {
  if (rawAction.trim().isNotEmpty && _containsArabic(rawAction)) {
    return rawAction;
  }
  return switch (status) {
    'ready' => 'الخادم يبدو جاهزًا لفحص مخبري مضبوط.',
    'partial' => 'أكمل عناصر السلامة الناقصة قبل أي تجربة تطبيق.',
    'disabled' => 'فحص الجاهزية معطل افتراضيًا، وهذا هو الوضع الآمن.',
    'blocked' => 'لا تنتقل إلى التطبيق العملي قبل حل أسباب الحظر.',
    _ => 'راجع إعدادات الجاهزية قبل تشغيل المعالج.',
  };
}

String _diagnosticTitle(String code) =>
    _diagnosticTitles[code] ?? 'تنبيه جاهزية';

String _diagnosticExplanation(String code) {
  return _diagnosticExplanations[code] ??
      'راجع إعدادات الجاهزية قبل تشغيل المعالج.';
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_string(value)) ?? 0;
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = _string(value).trim().toLowerCase();
  return text == '1' || text == 'true' || text == 'yes' || text == 'on';
}

bool _containsArabic(String value) {
  return value.runes.any(
    (r) =>
        (r >= 0x0600 && r <= 0x06FF) ||
        (r >= 0x0750 && r <= 0x077F) ||
        (r >= 0x08A0 && r <= 0x08FF) ||
        (r >= 0xFB50 && r <= 0xFDFF) ||
        (r >= 0xFE70 && r <= 0xFEFF),
  );
}
