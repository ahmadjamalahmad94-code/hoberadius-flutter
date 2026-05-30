import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/saas_modules/domain/saas_module_model.dart';

void main() {
  test('SaaS module record hides raw status codes from visible text', () {
    final record = SaasRecord.fromJson({
      'id': 1,
      'status': 'paid',
      'enabled': true,
      'name': 'اشتراك شهري',
    });

    expect(record.rawText('status'), 'paid');
    expect(record.text('status'), 'مدفوعة');
    expect(record.text('enabled'), 'مفعّلة');
  });

  test('service and ticket statuses are Arabic friendly', () {
    expect(
      SaasRecord.fromJson({'status': 'given'}).text('status'),
      'مسلمة للعميل',
    );
    expect(
      SaasRecord.fromJson({'status': 'pending'}).text('status'),
      'بانتظار متابعة',
    );
    expect(
      SaasRecord.fromJson({'status': 'revoked'}).text('status'),
      'ملغاة',
    );
  });
}
