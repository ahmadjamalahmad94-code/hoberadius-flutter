import 'package:flutter/material.dart';

import '../../domain/card_model.dart';

/// «تعديل بيانات الكرت» — two free-text fields (number + password),
/// prefilled with the current values. Empty or unchanged = leave as is;
/// «حفظ» is enabled only when at least one field really changed. Nothing is
/// generated here. Resolves with the draft to send, or `null` on cancel.
Future<CardIdentityDraft?> showCardIdentityDialog(
  BuildContext context, {
  required String username,
  String password = '',
  bool passwordless = false,
}) {
  return showDialog<CardIdentityDraft>(
    context: context,
    useRootNavigator: true,
    builder: (_) => CardIdentityDialog(
      username: username,
      password: password,
      passwordless: passwordless,
    ),
  );
}

class CardIdentityDialog extends StatefulWidget {
  const CardIdentityDialog({
    super.key,
    required this.username,
    this.password = '',
    this.passwordless = false,
  });

  final String username;
  final String password;
  final bool passwordless;

  @override
  State<CardIdentityDialog> createState() => _CardIdentityDialogState();
}

class _CardIdentityDialogState extends State<CardIdentityDialog> {
  late final TextEditingController _user =
      TextEditingController(text: widget.username);
  late final TextEditingController _pw =
      TextEditingController(text: widget.passwordless ? '' : widget.password);
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pw.dispose();
    super.dispose();
  }

  ({CardIdentityDraft? draft, String? error}) _read() => readCardIdentityInput(
        currentUsername: widget.username,
        currentPassword: widget.password,
        typedUsername: _user.text,
        typedPassword: _pw.text,
        passwordless: widget.passwordless,
      );

  void _save() {
    final r = _read();
    if (r.error != null) {
      setState(() => _error = r.error);
      return;
    }
    if (r.draft == null || r.draft!.isEmpty) {
      setState(() => _error = 'لم يتغيّر شيء — عدّل رقم الكرت أو كلمة المرور.');
      return;
    }
    Navigator.pop(context, r.draft);
  }

  @override
  Widget build(BuildContext context) {
    final r = _read();
    final canSave = r.draft != null && !r.draft!.isEmpty;
    return AlertDialog(
      title: const Text('تعديل بيانات الكرت'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'عدّل رقم الكرت أو كلمة المرور أو كليهما — ما تتركه كما هو لا '
              'يتغيّر. يبقى وقت البطاقة واستهلاكها كما هما، وتُقطع الجلسة '
              'النشطة ليعيد الدخول بالبيانات الجديدة.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('card-identity-username'),
              controller: _user,
              textDirection: TextDirection.ltr,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: 64,
              decoration: const InputDecoration(labelText: 'رقم الكرت'),
              onChanged: (_) => setState(() => _error = null),
            ),
            if (cardNumberHasLatinLetters(_user.text))
              Container(
                key: const ValueKey('card-identity-case-warning'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cardNumberCaseWarning,
                        style: TextStyle(color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              key: const ValueKey('card-identity-password'),
              controller: _pw,
              enabled: !widget.passwordless,
              textDirection: TextDirection.ltr,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: 64,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                hintText: widget.passwordless
                    ? 'حزمة «رقم فقط» — بلا كلمة مرور'
                    : 'اتركها فارغة إن لم تُرد تغييرها',
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_error != null || r.error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error ?? r.error!,
                key: const ValueKey('card-identity-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          key: const ValueKey('card-identity-save'),
          onPressed: canSave ? _save : null,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
