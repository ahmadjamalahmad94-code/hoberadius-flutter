import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_model.dart';

/// The server sends expire_at in UTC. The app used to drop the «Z», read the
/// UTC clock as local time and then convert it to UTC again on save — each
/// save from the edit form cut the expiry by the UTC offset (3 h in
/// Palestine). Load → save must round-trip the exact instant.
void main() {
  test('expire_at round-trips unchanged through the edit form', () {
    final s = Subscriber.fromJson({
      'username': 'demo072',
      'expire_at': '2026-10-02T20:59:59Z',
    });
    expect(s.expireAt!.isUtc, isFalse); // shown in the phone's local time
    expect(
      s.expireAt!.toUtc(),
      DateTime.utc(2026, 10, 2, 20, 59, 59),
    );
    final sent = s.toPatchBody()['expire_at'] as String;
    expect(DateTime.parse(sent), DateTime.utc(2026, 10, 2, 20, 59, 59));
  });

  test('a naive server datetime is UTC too', () {
    final s = Subscriber.fromJson({
      'username': 'x',
      'expire_at': '2026-10-02T20:59:59',
    });
    expect(s.expireAt!.toUtc(), DateTime.utc(2026, 10, 2, 20, 59, 59));
  });
}
