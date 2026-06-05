import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_endpoint_storage.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _server = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _scheme = 'https';
  bool _obscure = true;
  late final AnimationController _heroAnim;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
      vsync: this,
      duration: AppTokens.motionMedium,
    )..forward();
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
    _heroAnim.dispose();
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
    final p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s16,
                vertical: AppTokens.s24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Hero(animation: _heroAnim),
                        const SizedBox(height: AppTokens.s16),
                        if (_server.text.trim().isNotEmpty)
                          _EndpointChip(
                            scheme: _scheme,
                            host: _server.text,
                          ),
                        const SizedBox(height: AppTokens.s16),
                        _FormCard(
                          formKey: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'تسجيل دخول الإدارة',
                                textAlign: TextAlign.center,
                                style: AppTypography.titleLarge.copyWith(
                                  color: p.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppTokens.s8),
                              Text(
                                'اكتب عنوان VPS ثم بيانات مدير النظام. نفس التطبيق يعمل مع أكثر من خادم.',
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: p.textMuted,
                                ),
                              ),
                              const SizedBox(height: AppTokens.s20),
                              _ServerFields(
                                server: _server,
                                scheme: _scheme,
                                onSchemeChanged: (value) {
                                  if (value != null) {
                                    setState(() => _scheme = value);
                                  }
                                },
                                validator: _validateServer,
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
                                    (v == null || v.trim().isEmpty)
                                        ? 'مطلوب'
                                        : null,
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
                                    onPressed: () => setState(
                                      () => _obscure = !_obscure,
                                    ),
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
                                height: 50,
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
                                      : Text(
                                          'دخول',
                                          style: AppTypography.labelLarge
                                              .copyWith(color: Colors.white),
                                        ),
                                ),
                              ),
                              const SizedBox(height: AppTokens.s12),
                              OutlinedButton.icon(
                                onPressed: auth.loading
                                    ? null
                                    : () => context.goNamed(
                                          'hotspot-cards-portal',
                                        ),
                                icon: const Icon(
                                  Icons.confirmation_number_outlined,
                                ),
                                label: const Text('بوابة شراء الكروت'),
                              ),
                              const SizedBox(height: AppTokens.s12),
                              Text(
                                'سيتم حفظ عنوان الخادم على هذا الجهاز فقط، ويمكن تغييره من شاشة الدخول عند الحاجة.',
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: AppTypography.caption.copyWith(
                                  color: p.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Brand hero panel — gradient background, animated logo, app title.
class _Hero extends StatelessWidget {
  const _Hero({required this.animation});
  final AnimationController animation;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: AppTokens.motionSpringy),
    );
    final fade = CurvedAnimation(
      parent: animation,
      curve: AppTokens.motionEaseInOut,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: BoxDecoration(
        gradient: p.brandGradient,
        borderRadius: BorderRadius.circular(AppTokens.r18),
        boxShadow: [
          BoxShadow(
            color: p.brand.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: FadeTransition(
        opacity: fade,
        child: Column(
          children: [
            ScaleTransition(
              scale: scale,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.32),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.wifi_tethering,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Hobe Hub',
              style: AppTypography.displayMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'إدارة خدمة الإنترنت بالبطاقات',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact chip surfacing the last-saved server endpoint so the
/// operator confirms they're targeting the right tenant before
/// authenticating.
class _EndpointChip extends StatelessWidget {
  const _EndpointChip({required this.scheme, required this.host});
  final String scheme;
  final String host;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: p.brandSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: p.brandLine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dns_outlined, size: 14, color: p.brandInk),
            const SizedBox(width: 6),
            Text(
              '$scheme://$host',
              style: AppTypography.labelSmall.copyWith(color: p.brandInk),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.formKey, required this.child});
  final GlobalKey<FormState> formKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s24),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTokens.r18),
        border: Border.all(color: p.border),
        boxShadow: p.shCard,
      ),
      child: Form(key: formKey, child: child),
    );
  }
}

class _ServerFields extends StatelessWidget {
  const _ServerFields({
    required this.server,
    required this.scheme,
    required this.onSchemeChanged,
    required this.validator,
  });

  final TextEditingController server;
  final String scheme;
  final ValueChanged<String?> onSchemeChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final protocolField = DropdownButtonFormField<String>(
      key: ValueKey(scheme),
      initialValue: scheme,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'الاتصال'),
      items: const [
        DropdownMenuItem(value: 'https', child: Text('HTTPS')),
        DropdownMenuItem(value: 'http', child: Text('HTTP')),
      ],
      onChanged: onSchemeChanged,
    );

    final serverField = TextFormField(
      controller: server,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'IP أو دومين الخادم',
        hintText: '125.161.1.5 أو radius.example.com',
        prefixIcon: Icon(Icons.dns_outlined),
        helperText: 'بدون /api، ويمكن وضع منفذ مثل :5050',
      ),
      validator: validator,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              protocolField,
              const SizedBox(height: AppTokens.s12),
              serverField,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 124, child: protocolField),
            const SizedBox(width: AppTokens.s12),
            Expanded(child: serverField),
          ],
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: p.dangerBg,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: p.dangerStrong.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: p.dangerFg, size: 18),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              message,
              softWrap: true,
              style: AppTypography.bodySmall.copyWith(
                color: p.dangerFg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
