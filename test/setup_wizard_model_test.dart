import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/setup_wizard/domain/setup_wizard_model.dart';

void main() {
  test('SetupWizardOverview parses health readiness and runs safely', () {
    final overview = SetupWizardOverview.fromJson({
      'health': {
        'overall': 'degraded',
        'checked_at': '2026-06-02T12:00:00Z',
        'duration_ms': 25,
        'version': 'setup_wizard_v3',
        'checks': {
          'db_migrations': {
            'status': 'ok',
            'title_ar': 'قاعدة البيانات',
            'details': 'كل الأعمدة المطلوبة موجودة',
          },
          'freeradius_responsive': {
            'status': 'warn',
            'title_ar': 'خدمة الريدياس',
            'details': 'تحتاج متابعة',
          },
        },
      },
      'server_readiness': {
        'status': 'disabled',
        'configured': false,
        'next_action_ar': 'الفحص معطل افتراضيًا.',
        'checks': {
          'readiness_flag': {'status': 'disabled', 'detail': 'off'},
        },
        'diagnostics': [
          {
            'code': 'server_wg_readiness_disabled',
            'arabic_title': 'فحص الجاهزية معطل',
            'explanation_ar': 'لم يتم تفعيل فحص الجاهزية.',
          }
        ],
      },
      'recent_runs': [
        {
          'id': 9,
          'state': 'COLLECTING',
          'ar_state_label': 'جمع بيانات الراوتر',
          'router_name': '',
          'router_type': '',
          'router_vpn_ip': '',
          'nas_device_id': 15,
          'is_terminal': false,
          'created_at': '2026-06-02T12:00:00Z',
          'updated_at': '2026-06-02T12:00:00Z',
          'radius_secret': 'must-not-be-used',
        }
      ],
      'runs_summary': {
        'recent_count': 1,
        'active_count': 1,
        'by_state': {'COLLECTING': 1},
      },
      'safe_operations': {
        'can_create_run': true,
        'can_apply_router_changes': false,
        'can_apply_server_peer': false,
        'can_plan_phases': true,
        'can_run_lifecycle': true,
        'reason_ar': 'قراءة آمنة فقط.',
      },
    });

    expect(overview.health.label, 'يحتاج متابعة');
    expect(overview.health.checks.length, 2);
    expect(overview.serverReadiness.label, 'معطل');
    expect(overview.serverReadiness.checks.single.label, 'تفعيل فحص الجاهزية');
    expect(
      overview.serverReadiness.diagnostics.single.title,
      'فحص الجاهزية معطل',
    );
    expect(overview.recentRuns.single.id, 9);
    expect(overview.recentRuns.single.nasDeviceId, 15);
    expect(overview.recentRuns.single.stateLabel, 'جمع بيانات الراوتر');
    expect(overview.runsSummary.byState['COLLECTING'], 1);
    expect(overview.safeOperations.canApplyRouterChanges, isFalse);
    expect(overview.safeOperations.canPlanPhases, isTrue);
    expect(overview.safeOperations.canRunLifecycle, isTrue);
  });

  test('phase planner and phase plan payloads parse safely', () {
    final planner = SetupWizardPhasePlanner.fromJson({
      'phase': 'internet',
      'title_ar': 'وصلة الإنترنت',
      'description_ar': 'تجهيز منفذ الإنترنت الخارج.',
      'required_inputs': ['source_type', 'interface'],
    });

    final response = SetupWizardPhasePlanResponse.fromJson({
      'phase': 'internet',
      'run_id': 11,
      'plan': {
        'phase': 'internet',
        'is_applicable': true,
        'can_apply': true,
        'script': '/ip dhcp-client add interface=ether1',
        'rollback_script': '/ip dhcp-client remove',
        'validation_commands': ['/ip route print'],
        'warnings': ['راجع منفذ الإنترنت قبل اللصق.'],
        'notes': ['تم توليد خطة آمنة.'],
        'tags': ['HOBERADIUS_SETUP:11:internet'],
        'blocking_errors': [],
      },
      'diagnostics': [
        {
          'code': 'internet_source_missing',
          'ar_explanation': 'اختر نوع وصلة الإنترنت.',
        },
      ],
    });

    expect(planner.title, 'وصلة الإنترنت');
    expect(planner.requiredInputs, ['source_type', 'interface']);
    expect(response.runId, 11);
    expect(response.plan.canApply, isTrue);
    expect(response.plan.validationCommands.single, '/ip route print');
    expect(response.diagnostics.single.explanation, 'اختر نوع وصلة الإنترنت.');
    expect(setupWizardInputLabel('router_vpn_ip'), 'عنوان الراوتر داخل النفق');
  });

  test('script generation result hides secret fields and parses run state', () {
    final result = SetupWizardScriptResult.fromJson({
      'run': {'id': 12, 'state': 'AWAITING_HANDSHAKE'},
      'script': '/interface wireguard add',
      'short_code': 'abc123',
      'sha256': 'deadbeef',
      'expires_at': '2026-06-06T00:00:00Z',
      'script_contains_sensitive_values': true,
      'warning_ar': 'هذا السكربت يحتوي أسرار تشغيلية.',
      'radius_secret': 'ignored',
      'api_password': 'ignored',
    });

    expect(result.run.id, 12);
    expect(result.script, contains('/interface wireguard'));
    expect(result.shortCode, 'abc123');
    expect(result.containsSensitiveValues, isTrue);
    expect(result.warning, contains('أسرار'));
  });

  test('router service catalogue and status parse Arabic labels', () {
    final card = SetupWizardRouterServiceCard.fromJson({
      'key': 'hotspot',
      'title_ar': 'بوابة الدخول',
      'subtitle_ar': 'بوابة دخول عامّة',
      'icon': 'wifi',
      'color': 'blue',
      'phases_count': 4,
    });
    final status = SetupWizardRouterServicesStatus.fromJson({
      'router_id': 15,
      'services': [
        {
          'key': 'hotspot',
          'title_ar': 'بوابة الدخول',
          'enabled': true,
          'status': 'active',
          'status_ar': 'مفعّلة',
        },
        {
          'key': 'block-sites',
          'title_ar': 'حجب المواقع',
          'enabled': null,
          'status': 'unknown',
          'status_ar': 'غير معروف',
        },
      ],
    });

    expect(card.title, 'بوابة الدخول');
    expect(card.phasesCount, 4);
    expect(status.routerId, 15);
    expect(status.services.first.enabled, isTrue);
    expect(status.services.first.statusLabel, 'مفعّلة');
    expect(status.services.last.enabled, isNull);
    expect(
      setupWizardRouterServiceLabel('remote-access'),
      'الدخول الفني الآمن',
    );
  });
}
