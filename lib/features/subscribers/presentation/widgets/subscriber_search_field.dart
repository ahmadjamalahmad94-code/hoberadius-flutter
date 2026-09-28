import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/visible_error_message.dart';
import '../../../../core/theme/tokens.dart';
import '../../data/subscribers_repository.dart';
import '../../domain/subscriber_model.dart';

/// Server-side subscriber picker for dialogs (tickets, service requests…).
///
/// The old pickers preloaded `accounts?limit=300` (tenants have 13,000+
/// subscribers) and pre-selected an arbitrary first one. This searches the
/// whole tenant by name / username / mobile as the operator types and starts
/// with NO selection.
class SubscriberSearchField extends ConsumerStatefulWidget {
  const SubscriberSearchField({
    super.key,
    required this.onChanged,
    this.enabled = true,
    this.label = 'المشترك',
  });

  final ValueChanged<Subscriber?> onChanged;
  final bool enabled;
  final String label;

  @override
  ConsumerState<SubscriberSearchField> createState() =>
      _SubscriberSearchFieldState();
}

class _SubscriberSearchFieldState extends ConsumerState<SubscriberSearchField> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<Subscriber> _results = const [];
  Subscriber? _selected;
  bool _loading = false;
  String? _error;
  int _seq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String value) async {
    final q = value.trim();
    final seq = ++_seq;
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(subscribersRepositoryProvider)
          .listPage(search: q, limit: 20);
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = page.items.where((s) => s.id != null).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _loading = false;
        _error = visibleErrorMessage(e);
      });
    }
  }

  void _select(Subscriber? s) {
    setState(() {
      _selected = s;
      _results = const [];
      if (s == null) _query.clear();
    });
    widget.onChanged(s);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    if (selected != null) {
      return InputDecorator(
        decoration: InputDecoration(labelText: widget.label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                subscriberPickerLabel(selected),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'تغيير المشترك',
              visualDensity: VisualDensity.compact,
              onPressed: widget.enabled ? () => _select(null) : null,
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _query,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'ابحث بالاسم أو اسم المستخدم أو الجوال',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: _onChanged,
          onSubmitted: _search,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.s4),
            child: Text(
              _error!,
              style: const TextStyle(color: AppTokens.red, fontSize: 12),
            ),
          ),
        if (_query.text.trim().isNotEmpty &&
            !_loading &&
            _error == null &&
            _results.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppTokens.s4),
            child: Text(
              'لا يوجد مشترك مطابق',
              style: TextStyle(color: AppTokens.textMuted, fontSize: 12),
            ),
          ),
        for (final s in _results)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline, size: 20),
            title: Text(
              s.fullName.isEmpty ? s.username : s.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [s.username, if (s.mobile.isNotEmpty) s.mobile].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: widget.enabled ? () => _select(s) : null,
          ),
      ],
    );
  }
}

String subscriberPickerLabel(Subscriber s) {
  final name = s.fullName.trim();
  final user = s.username.trim();
  if (name.isEmpty) return user.isEmpty ? '#${s.id}' : user;
  return '$name · $user';
}
