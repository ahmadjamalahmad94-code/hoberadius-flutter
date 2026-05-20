import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';

void main() {
  test('normalizeApiBaseUrl builds URL from IP and selected scheme', () {
    expect(
      normalizeApiBaseUrl(scheme: 'http', host: '125.161.1.5'),
      'http://125.161.1.5',
    );
    expect(
      normalizeApiBaseUrl(scheme: 'https', host: 'radius.example.com:8443'),
      'https://radius.example.com:8443',
    );
  });

  test('normalizeApiBaseUrl accepts pasted full URL but keeps origin only', () {
    expect(
      normalizeApiBaseUrl(scheme: 'http', host: 'https://demo.example.com/api'),
      'https://demo.example.com',
    );
  });

  test('normalizeApiBaseUrl rejects empty server', () {
    expect(
      () => normalizeApiBaseUrl(scheme: 'https', host: '   '),
      throwsFormatException,
    );
  });
}
