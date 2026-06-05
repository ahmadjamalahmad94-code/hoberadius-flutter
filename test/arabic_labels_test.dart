import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/l10n/arabic_labels.dart';

void main() {
  test('currency labels are Arabic and hide raw-only codes in money text', () {
    expect(currencyLabel('ILS'), 'شيكل إسرائيلي');
    expect(currencyLabel('jod'), 'دينار أردني');
    expect(currencyLabel('USD'), 'دولار أمريكي');
    expect(amountWithCurrency('125.50', 'ILS'), '125.50 شيكل إسرائيلي');
  });

  test('unknown status and action labels stay understandable', () {
    expect(unknownStatusLabel(''), 'غير محدد');
    expect(unknownStatusLabel('backend_status'), 'حالة غير معروفة');
    expect(unknownActionLabel(''), 'عملية');
    expect(unknownActionLabel('backend_action'), 'عملية غير معروفة');
  });
}
