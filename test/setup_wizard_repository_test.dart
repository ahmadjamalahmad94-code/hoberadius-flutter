import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/features/setup_wizard/data/setup_wizard_repository.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? token = 'token';

  @override
  Future<void> clear() async => token = null;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;
}

class _MemoryEndpointStorage implements ApiEndpointStorage {
  String baseUrl = 'http://127.0.0.1:5000';

  @override
  Future<String> readBaseUrl() async => baseUrl;

  @override
  Future<void> writeBaseUrl(String baseUrl) async => this.baseUrl = baseUrl;
}

class _CaptureAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final data = switch (options.path) {
      '/api/v1/setup-wizard/phase-planners' => {
          'phases': [
            {
              'phase': 'internet',
              'title_ar': 'وصلة الإنترنت',
              'description_ar': 'تجهيز منفذ الإنترنت الخارج.',
              'required_inputs': ['source_type'],
            },
          ],
        },
      '/api/v1/setup-wizard/diagnostics-catalogue' => {
          'catalogue': [
            {
              'code': 'internet_source_missing',
              'ar_explanation': 'اختر نوع وصلة الإنترنت.',
            },
          ],
        },
      String path when path.endsWith('/phase-plan/internet') => {
          'phase': 'internet',
          'run_id': 9,
          'plan': {
            'phase': 'internet',
            'is_applicable': true,
            'can_apply': true,
            'script': '/ip dhcp-client add interface=ether1',
            'validation_commands': ['/ip route print'],
          },
          'diagnostics': [],
        },
      String path when path.endsWith('/generate-script') => {
          'run': {'id': 9, 'state': 'AWAITING_HANDSHAKE'},
          'script': '/interface wireguard add',
          'short_code': 'abc123',
          'sha256': 'deadbeef',
          'expires_at': '2026-06-06T00:00:00Z',
          'script_contains_sensitive_values': true,
          'warning_ar': 'هذا السكربت يحتوي أسرار تشغيلية.',
        },
      String path when path.endsWith('/router-info') => {
          'run': {'id': 9, 'state': 'PLANNING'},
        },
      String path when path.endsWith('/submit-key') => {
          'run': {'id': 9, 'state': 'APPLYING_SERVER_PEER'},
        },
      String path when path.endsWith('/apply-server-peer') => {
          'run': {'id': 9, 'state': 'VERIFYING'},
        },
      String path when path.endsWith('/mark-handshake') => {
          'run': {'id': 9, 'state': 'REGISTERING'},
        },
      String path when path.endsWith('/register') => {
          'run': {'id': 9, 'state': 'COMPLETE'},
        },
      _ => {},
    };
    return ResponseBody.fromString(
      jsonEncode({'ok': true, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  test('SetupWizardRepository sends phase planner API requests', () async {
    final client = ApiClient(_MemoryTokenStorage(), _MemoryEndpointStorage());
    final adapter = _CaptureAdapter();
    client.dio.httpClientAdapter = adapter;
    final repo = SetupWizardRepository(client);

    final phases = await repo.phasePlanners();
    final plan = await repo.phasePlan(
      9,
      'internet',
      inputs: const {'source_type': 'dhcp', 'interface': 'ether1'},
    );
    final diagnostics = await repo.diagnosticsCatalogue();

    expect(phases.single.title, 'وصلة الإنترنت');
    expect(plan.plan.script, contains('/ip dhcp-client add'));
    expect(diagnostics.single.explanation, 'اختر نوع وصلة الإنترنت.');
    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'GET /api/v1/setup-wizard/phase-planners',
        'POST /api/v1/setup-wizard/runs/9/phase-plan/internet',
        'GET /api/v1/setup-wizard/diagnostics-catalogue',
      ],
    );
  });

  test('SetupWizardRepository sends lifecycle API requests', () async {
    final client = ApiClient(_MemoryTokenStorage(), _MemoryEndpointStorage());
    final adapter = _CaptureAdapter();
    client.dio.httpClientAdapter = adapter;
    final repo = SetupWizardRepository(client);

    final routerInfo = await repo.submitRouterInfo(
      9,
      routerName: 'main-router',
      routerType: 'mixed',
    );
    final script = await repo.generateScript(
      9,
      endpoint: 'hoberadius.com',
      serverPublicKey: List.filled(44, 'A').join(),
    );
    final key = await repo.submitPublicKey(
      9,
      publicKeyOrOutput: 'HOBERADIUS_PUBLIC_KEY=${List.filled(44, 'A').join()}',
    );
    final peer = await repo.applyServerPeer(9);
    final handshake = await repo.markHandshake(9);
    final registered = await repo.registerRouter(
      9,
      apiUser: 'admin',
      apiPassword: 'secret',
    );

    expect(routerInfo.state, 'PLANNING');
    expect(script.shortCode, 'abc123');
    expect(script.containsSensitiveValues, isTrue);
    expect(key.state, 'APPLYING_SERVER_PEER');
    expect(peer.state, 'VERIFYING');
    expect(handshake.state, 'REGISTERING');
    expect(registered.state, 'COMPLETE');
    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'POST /api/v1/setup-wizard/runs/9/router-info',
        'POST /api/v1/setup-wizard/runs/9/generate-script',
        'POST /api/v1/setup-wizard/runs/9/submit-key',
        'POST /api/v1/setup-wizard/runs/9/apply-server-peer',
        'POST /api/v1/setup-wizard/runs/9/mark-handshake',
        'POST /api/v1/setup-wizard/runs/9/register',
      ],
    );
    final routerInfoBody = adapter.requests.first.data as Map<String, dynamic>;
    expect(routerInfoBody['router_name'], 'main-router');
    expect(routerInfoBody['router_type'], 'mixed');
  });
}
