import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/cards/domain/card_batch_requests.dart';
import 'package:hoberadius_app/features/cards/domain/username_preview.dart';

void main() {
  test('length is the whole name: prefix + generated + suffix', () {
    final p = UsernamePreview.of(prefix: '25', suffix: '99', totalLength: 10);
    expect(p.generatedLength, 6);
    expect(p.full, '2512345699');
    expect(p.warning, isNull);
  });

  test('batch number sits after the prefix and counts in the length', () {
    final p = UsernamePreview.of(
      prefix: 'qa',
      suffix: '',
      totalLength: 8,
      batchNumber: '14',
    );
    expect(p.full, 'qa141234');
  });

  test('Arabic digits and spaces are normalised, letters lower-cased', () {
    final p = UsernamePreview.of(prefix: '٢٥ A', suffix: '', totalLength: 6);
    expect(p.prefix, '25a');
    expect(p.generatedLength, 3);
  });

  test('warns when the affixes fill the length or digits are too few', () {
    expect(
      UsernamePreview.of(prefix: '1234', suffix: '5678', totalLength: 8)
          .warning,
      isNotNull,
    );
    final few = UsernamePreview.of(
      prefix: '25',
      suffix: '',
      totalLength: 4,
      count: 500,
    );
    expect(few.generatedLength, 2);
    expect(few.warning, contains('لا تكفي'));
  });

  test('request sends explicit prefix/suffix and include_batch_number', () {
    final body = GenerateBatchRequest(
      planId: 1,
      count: 5,
      usernamePrefix: '25',
      usernameSuffix: '99',
      includeBatchNumber: true,
      passwordGenerationType: 'digits',
    ).toBody();
    expect(body['username_prefix'], '25');
    expect(body['username_suffix'], '99');
    expect(body['include_batch_number'], true);
    expect(body.containsKey('starts_with_or_ends_with'), isFalse);
    expect(body['password_generation_type'], 'digits');
  });
}
