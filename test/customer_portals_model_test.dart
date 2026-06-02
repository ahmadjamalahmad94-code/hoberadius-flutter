import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/customer_portals/domain/customer_portals_model.dart';

void main() {
  test('CustomerPortalsState parses navigation-only portal contract', () {
    final state = CustomerPortalsState.fromJson({
      'items': [
        {
          'key': 'subscriber_portal',
          'label': 'بوابة المشترك',
          'description': 'دخول المشترك لعرض الاشتراك.',
          'public_path': '/portal/subscriber/login',
          'admin_path': '/admin/radius/portal/subscriber/login',
          'home_path': '/portal/subscriber',
          'available_actions': ['login', 'loan_request'],
          'security_note': 'المشترك يرى بياناته فقط.',
        },
        {
          'key': 'card_user_portal',
          'label': 'بوابة مستخدم البطاقة',
          'description': 'دخول مستخدم البطاقة.',
          'public_path': '/portal/card/login',
          'admin_path': '/admin/radius/portal/card/login',
          'home_path': '/portal/card',
          'available_actions': ['login', 'redeem_card', 'purchase_card'],
          'security_note': 'لا ترجع كلمة مرور البوابة في API.',
        },
      ],
      'security': {
        'summary': 'هذه الواجهة تعرض روابط وإرشادات فقط.',
        'admin_navigation_only': true,
        'uses_existing_portal_sessions': true,
      },
    });

    expect(state.items.length, 2);
    expect(state.items.first.label, 'بوابة المشترك');
    expect(state.items.first.availableActions, contains('loan_request'));
    expect(state.items.last.publicPath, '/portal/card/login');
    expect(state.security.adminNavigationOnly, isTrue);
    expect(state.security.usesExistingPortalSessions, isTrue);
  });
}
