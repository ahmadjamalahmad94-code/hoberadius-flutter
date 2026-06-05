import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/network_policy/domain/network_policy_model.dart';

void main() {
  test('network policy list parses all core fields', () {
    final page = NetworkPolicyPage.fromJson({
      'ok': true,
      'data': {
        'count': 1,
        'items': [
          {
            'id': 11,
            'router_id': 4,
            'name': 'حظر تيك توك',
            'slug': 'tiktok',
            'enabled': 1,
            'scope': 'all_users',
            'fail_open': 0,
            'deployment_status': 'previewed',
          },
        ],
      },
    });

    expect(page.count, 1);
    expect(page.items.single.id, 11);
    expect(page.items.single.routerId, 4);
    expect(page.items.single.enabled, isTrue);
    expect(page.items.single.flag('fail_open'), isFalse);
    expect(page.items.single.deploymentStatusLabel, 'تمت المعاينة');
    expect(
      networkPolicyFieldLabel('scope', page.items.single.fields['scope']),
      'النطاق: كل المستخدمين',
    );
  });

  test('children and preview payloads expose Arabic labels', () {
    final children = NetworkPolicyChildrenPage.fromJson({
      'data': {
        'count': 1,
        'counts': {'domain': 1, 'total': 1},
        'items': [
          {
            'id': 7,
            'policy_id': 11,
            'value': 'example.com',
            'target_type': 'domain',
            'status': 'manual_review',
          },
        ],
      },
    });
    expect(children.items.single.kindLabel, 'نطاق');
    expect(children.items.single.statusLabel, 'يحتاج مراجعة');

    final preview = NetworkPolicyPreview.fromJson({
      'data': {
        'service': 'web_block',
        'policy_id': 11,
        'router_id': 4,
        'can_apply': true,
        'summary': {
          'command_count': 3,
          'blocking_errors': [],
          'warnings': ['راجع قائمة الأهداف'],
        },
        'script_hash': 'abc',
        'forward_script': '/ip firewall address-list add',
        'rollback_script': '/ip firewall address-list remove',
        'health_score': {'score': 82},
        'beginner_explanation': {'plain_text': 'سياسة حظر جاهزة للمراجعة'},
      },
    });
    expect(preview.canApply, isTrue);
    expect(preview.commandCount, 3);
    expect(preview.healthScore, 82);
    expect(preview.warnings.single, 'راجع قائمة الأهداف');
  });

  test('runtime action and change-set payloads parse status labels', () {
    final action = NetworkPolicyActionResult.fromJson({
      'data': {
        'ok': false,
        'change_set_id': 0,
        'status': 'failed',
        'reason_ar': 'تعذر التنفيذ.',
        'blockers': [
          {'message_ar': 'لا توجد نسخة احتياطية جاهزة'},
        ],
      },
    });
    expect(action.ok, isFalse);
    expect(action.statusLabel, 'فشلت');
    expect(action.blockers.single, 'لا توجد نسخة احتياطية جاهزة');

    final changes = NetworkPolicyChangeSetPage.fromJson({
      'data': {
        'count': 1,
        'items': [
          {
            'id': 8,
            'action_type': 'apply',
            'status': 'partially_succeeded',
            'execution_mode': 'canary',
            'rollback_eligible': true,
            'targets': [
              {
                'router_id': 3,
                'status': 'failed',
                'error_message': 'تعذر الوصول للراوتر',
              },
            ],
          },
        ],
      },
    });
    expect(changes.items.single.actionLabel, 'تطبيق');
    expect(changes.items.single.statusLabel, 'نجحت جزئيًا');
    expect(changes.items.single.targets.single.statusLabel, 'فشلت');
  });
}
