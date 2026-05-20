import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/sessions/domain/session_model.dart';

void main() {
  test('OnlineSession parses backend radacct aliases and card metadata', () {
    final session = OnlineSession.fromJson({
      'username': 'card-001',
      'session_id': 'sess-1',
      'nas_address': '10.20.30.1',
      'framed_ip': '192.168.1.10',
      'mac_address': 'AA:BB:CC:DD:EE:FF',
      'started_at': '2026-05-20T10:00:00Z',
      'last_update_at': '2026-05-20T10:05:00Z',
      'bytes_in': 1024,
      'bytes_out': 2048,
      'session_time': 300,
      'user_type': 'card',
      'user_type_label': 'بطاقة',
      'state': 'online',
      'state_color': 'green',
      'card_id': 9,
      'card_batch_id': 3,
    });

    expect(session.username, 'card-001');
    expect(session.isCard, isTrue);
    expect(session.nasIpAddress, '10.20.30.1');
    expect(session.framedIpAddress, '192.168.1.10');
    expect(session.callingStationId, 'AA:BB:CC:DD:EE:FF');
    expect(session.bytesIn, 1024);
    expect(session.bytesOut, 2048);
    expect(session.sessionTime, 300);
    expect(session.cardId, 9);
    expect(session.cardBatchId, 3);
  });
}
