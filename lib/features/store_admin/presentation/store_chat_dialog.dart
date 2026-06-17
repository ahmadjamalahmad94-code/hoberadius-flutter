import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../data/store_admin_repository.dart';
import '../domain/store_admin_model.dart';

Future<void> showStoreChatDialog(BuildContext context, ChatThread thread) {
  return showDialog<void>(
    context: context,
    builder: (_) => _StoreChatDialog(thread: thread),
  );
}

final _threadProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, int>((ref, cardUserId) {
  return ref.watch(storeAdminRepositoryProvider).chatThread(cardUserId);
});

class _StoreChatDialog extends ConsumerStatefulWidget {
  const _StoreChatDialog({required this.thread});
  final ChatThread thread;

  @override
  ConsumerState<_StoreChatDialog> createState() => _StoreChatDialogState();
}

class _StoreChatDialogState extends ConsumerState<_StoreChatDialog> {
  final _reply = TextEditingController();
  bool _sending = false;
  bool _statusChanged = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cu = widget.thread.cardUserId;
    final async = ref.watch(_threadProvider(cu));
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.thread.title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: () => _setStatus('resolved'),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('حلّ'),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        height: 420,
        child: Column(
          children: [
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    visibleErrorMessage(e),
                    style: const TextStyle(color: AppTokens.redInk),
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد رسائل بعد.',
                        style: TextStyle(color: AppTokens.textMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: false,
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) => _Bubble(message: messages[i]),
                  );
                },
              ),
            ),
            const Divider(height: AppTokens.s16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _reply,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'اكتب ردًّا…',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton.filled(
                        onPressed: _send,
                        icon: const Icon(Icons.send, size: 18),
                      ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  Future<void> _send() async {
    final body = _reply.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(storeAdminRepositoryProvider)
          .sendChatMessage(widget.thread.cardUserId, body);
      _reply.clear();
      ref.invalidate(_threadProvider(widget.thread.cardUserId));
      _statusChanged = true;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _setStatus(String status) async {
    try {
      await ref
          .read(storeAdminRepositoryProvider)
          .setChatStatus(widget.thread.cardUserId, status);
      _statusChanged = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث حالة المحادثة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    }
  }

  @override
  void deactivate() {
    // Refresh the inbox (unread/status) when the dialog closes.
    if (_statusChanged) {
      ref.invalidate(storeSupportProvider);
    }
    super.deactivate();
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final admin = message.fromAdmin;
    return Align(
      alignment: admin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12,
          vertical: AppTokens.s8,
        ),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: admin ? AppTokens.brandSoft : AppTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(
            color: admin ? AppTokens.brandLine : AppTokens.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.body.isNotEmpty)
              Text(
                message.body,
                style: TextStyle(
                  color: admin ? AppTokens.brandInk : AppTokens.textSecondary,
                ),
              ),
            if (message.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '📎 مرفق صورة',
                  style: TextStyle(
                    color: admin ? AppTokens.brandInk : AppTokens.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            if (message.createdAt.isNotEmpty)
              Text(
                message.createdAt,
                style: const TextStyle(
                  color: AppTokens.textMuted,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
