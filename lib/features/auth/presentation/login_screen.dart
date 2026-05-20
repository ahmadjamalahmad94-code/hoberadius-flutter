import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoint_storage.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/tokens.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _server = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _scheme = 'https';
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loadServer();
  }

  Future<void> _loadServer() async {
    final saved = await ref.read(apiEndpointStorageProvider).readBaseUrl();
    final uri = Uri.tryParse(saved);
    if (!mounted || uri == null || uri.host.isEmpty) return;
    setState(() {
      _scheme = uri.scheme == 'http' ? 'http' : 'https';
      _server.text = uri.authority;
    });
  }

  @override
  void dispose() {
    _server.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateServer(String? value) {
    try {
      normalizeApiBaseUrl(scheme: _scheme, host: value ?? '');
      return null;
    } on FormatException {
      return 'اكتب IP أو دومين صحيح بدون /api';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final baseUrl = normalizeApiBaseUrl(
      scheme: _scheme,
      host: _server.text,
    );
    await ref.read(authControllerProvider.notifier).login(
          baseUrl: baseUrl,
          username: _username.text.trim(),
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.s24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.s24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Brand(),
                      const SizedBox(height: AppTokens.s24),
                      Text(
                        'تسجيل دخول الإدارة',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTokens.navy900,
                            ),
                      ),
                      const SizedBox(height: AppTokens.s8),
                      Text(
                        'اكتب عنوان VPS ثم بيانات مدير النظام. نفس التطبيق يعمل مع أكثر من خادم.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTokens.textMuted,
                            ),
                      ),
                      const SizedBox(height: AppTokens.s20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 124,
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(_scheme),
                              initialValue: _scheme,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'الاتصال',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'https',
                                  child: Text('HTTPS'),
                                ),
                                DropdownMenuItem(
                                  value: 'http',
                                  child: Text('HTTP'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _scheme = v);
                              },
                            ),
                          ),
                          const SizedBox(width: AppTokens.s12),
                          Expanded(
                            child: TextFormField(
                              controller: _server,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'IP أو دومين الخادم',
                                hintText: '125.161.1.5 أو radius.example.com',
                                prefixIcon: Icon(Icons.dns_outlined),
                                helperText:
                                    'بدون /api، ويمكن وضع منفذ مثل :5050',
                              ),
                              validator: _validateServer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.s12),
                      TextFormField(
                        controller: _username,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'اسم المستخدم',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: AppTokens.s12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'مطلوب' : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: AppTokens.s12),
                        _ErrorBanner(message: auth.error!),
                      ],
                      const SizedBox(height: AppTokens.s20),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: auth.loading ? null : _submit,
                          child: auth.loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('دخول'),
                        ),
                      ),
                      const SizedBox(height: AppTokens.s12),
                      Text(
                        'سيتم حفظ عنوان الخادم على هذا الجهاز فقط، ويمكن تغييره من شاشة الدخول عند الحاجة.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTokens.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTokens.cyan500,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child:
              const Icon(Icons.wifi_tethering, color: Colors.white, size: 28),
        ),
        const SizedBox(height: AppTokens.s12),
        const Text(
          'HobeRadius',
          style: TextStyle(
            color: AppTokens.navy900,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE9E9),
        borderRadius: BorderRadius.circular(AppTokens.r10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTokens.red, size: 18),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTokens.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
