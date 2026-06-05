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
    expect(overview.recentRuns.single.stateLabel, 'جمع بيانات الراوتر');
    expect(overview.runsSummary.byState['COLLECTING'], 1);
    expect(overview.safeOperations.canApplyRouterChanges, isFalse);
    expect(overview.safeOperations.canPlanPhases, isTrue);
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
}
