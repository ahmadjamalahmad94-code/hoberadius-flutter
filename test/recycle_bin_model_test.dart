import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/recycle_bin/domain/recycle_bin_model.dart';

void main() {
  test('RecycleBinItem parses backend JSON fields', () {
    final item = RecycleBinItem.fromJson({
      'entity_type': 'subscribers',
      'id': '12',
      'label': 'user123',
      'status': 'disabled',
      'deleted_at': '2026-05-20T12:00:00Z',
      'deleted_by': 'admin',
      'delete_reason': 'duplicate',
    });

    expect(item.entityType, 'subscribers');
    expect(item.id, 12);
    expect(item.label, 'user123');
    expect(item.status, 'disabled');
    expect(item.deletedAt, isNotNull);
    expect(item.deletedBy, 'admin');
    expect(item.deleteReason, 'duplicate');
  });
}
