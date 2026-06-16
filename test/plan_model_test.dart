import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/plans/domain/plan_model.dart';

void main() {
  test('Plan parses + sends RM-H3 loan / override / split-quota fields', () {
    final p = Plan.fromJson({
      'id': 5,
      'name': 'Gold',
      'loan_enabled': true,
      'max_loan_minutes': 120,
      'speed_override_allowed': true,
      'allowed_devices_count': 4,
      'force_mac_address': true,
      'daily_download_quota_mb': 800,
      'daily_upload_quota_mb': 200,
      'daily_combined_quota_mb': 1000,
      'monthly_download_quota_mb': 24000,
      'monthly_upload_quota_mb': 6000,
      'monthly_combined_quota_mb': 30000,
    });

    expect(p.loanEnabled, isTrue);
    expect(p.maxLoanMinutes, 120);
    expect(p.speedOverrideAllowed, isTrue);
    expect(p.allowedDevicesCount, 4);
    expect(p.forceMacAddress, isTrue);
    expect(p.dailyCombinedQuotaMb, 1000);
    expect(p.monthlyCombinedQuotaMb, 30000);

    final body = p.toBody();
    expect(body['loan_enabled'], true);
    expect(body['max_loan_minutes'], 120);
    expect(body['speed_override_allowed'], true);
    expect(body['allowed_devices_count'], 4);
    expect(body['force_mac_address'], true);
    expect(body['daily_download_quota_mb'], 800);
    expect(body['monthly_combined_quota_mb'], 30000);
  });

  test('Plan copyWith carries the new fields', () {
    final base = Plan(name: 'Base');
    final updated = base.copyWith(
      loanEnabled: true,
      maxLoanMinutes: 30,
      dailyCombinedQuotaMb: 500,
    );
    expect(updated.loanEnabled, isTrue);
    expect(updated.maxLoanMinutes, 30);
    expect(updated.dailyCombinedQuotaMb, 500);
    // unchanged fields preserved
    expect(updated.name, 'Base');
  });
}
