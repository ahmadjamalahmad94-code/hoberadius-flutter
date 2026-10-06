// parity-c (2026-10-02): the router form matches the web — RouterOS version
// is a real field, an empty port box means «the server default» (not 0),
// and the type list is the server's (no app-only «wireless»).
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/nas/domain/nas_model.dart';
import 'package:hoberadius_app/features/nas/presentation/nas_form_screen.dart';

void main() {
  test('ros_version is read back and sent', () {
    final d = NasDevice.fromJson({
      'id': 3,
      'name': 'r',
      'address': '10.0.0.1',
      'ros_version': '6',
    });
    expect(d.rosVersion, '6');
    expect(d.toBody()['ros_version'], '6');
    expect(d.copyWith(rosVersion: '7').toBody()['ros_version'], '7');
  });

  test('empty port boxes go as null (server default), not 0', () {
    final d = NasDevice(name: 'r', address: '10.0.0.1')
        .copyWith(blankPorts: {'api_port', 'ssh_port'});
    final body = d.toBody();
    expect(body.containsKey('api_port'), isTrue);
    expect(body['api_port'], isNull);
    expect(body['ssh_port'], isNull);
    expect(body['coa_port'], 3799);
  });

  test('type list = the server NAS_TYPES_ALLOWED', () {
    expect(
      kNasTypeLabels.keys.toSet(),
      {'hotspot', 'pppoe', 'dhcp', 'router', 'ap', 'switch', 'firewall', 'other'},
    );
  });
}
