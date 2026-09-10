import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billingwala_v2/core/constants/app_colors.dart';
import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';
import 'package:pos_billingwala_v2/core/widgets/app_module_icon.dart';
import 'package:pos_billingwala_v2/features/auth/domain/auth_controller.dart';
import 'package:pos_billingwala_v2/features/support/data/support_api.dart';
import 'package:pos_billingwala_v2/features/support/data/support_dtos.dart';

class SupportTicketDetailPage extends ConsumerStatefulWidget {
  const SupportTicketDetailPage({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<SupportTicketDetailPage> createState() =>
      _SupportTicketDetailPageState();
}

class _SupportTicketDetailPageState
    extends ConsumerState<SupportTicketDetailPage> {
  SupportTicketDetailsDto? _details;
  bool _loading = false;
  bool _sending = false;
  String? _error;
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) {
      setState(() => _error = 'Please login first');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = SupportApi(ref.read(apiClientProvider));
      final details = await api.getTicketDetails(userId, widget.ticketId);
      if (!mounted) return;
      setState(() {
        _details = details;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _sendReply() async {
    final details = _details;
    if (details == null || details.isClosed || _sending) return;
    final message = _replyController.text.trim();
    if (message.isEmpty) return;

    final userId = ref.read(authControllerProvider).session?.userId;
    if (userId == null || userId.isEmpty) return;

    setState(() => _sending = true);
    try {
      final api = SupportApi(ref.read(apiClientProvider));
      final result = await api.replyTicket(
        userId: userId,
        ticketId: widget.ticketId,
        message: message,
      );
      if (!mounted) return;
      if (result.isSuccess) {
        _replyController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Reply sent')),
        );
        await _reload();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to send reply')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  List<_ChatLine> get _lines {
    final details = _details;
    if (details == null) return const [];
    final lines = <_ChatLine>[];
    if (details.description.isNotEmpty) {
      lines.add(
        _ChatLine(
          isSupport: false,
          message: details.description,
          createdAt: details.createdAt,
          senderLabel: 'You',
        ),
      );
    }
    for (final m in details.messages) {
      lines.add(
        _ChatLine(
          isSupport: !m.isFromUser,
          message: m.message,
          createdAt: m.createdAt,
          senderLabel: m.isFromUser ? 'You' : (m.sender.isEmpty ? 'Support' : m.sender),
        ),
      );
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final details = _details;
    final closed = details?.isClosed ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          (details?.ticketNo ?? '').isNotEmpty
              ? details!.ticketNo!
              : 'Ticket',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _reload,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _error != null && details == null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                if (details != null)
                  Material(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  details.subject.isEmpty
                                      ? 'Support ticket'
                                      : details.subject,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                if ((details.createdAt ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    details.createdAt!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (details.status.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: closed
                                    ? AppColors.danger.withValues(alpha: 0.12)
                                    : AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                details.status,
                                style: TextStyle(
                                  color: closed
                                      ? AppColors.danger
                                      : AppColors.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (closed)
                  Container(
                    width: double.infinity,
                    color: AppColors.danger.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: const Text(
                      'This ticket is closed. Replies are disabled.',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                const Divider(height: 1),
                Expanded(
                  child: _loading && details == null
                      ? const Center(child: CircularProgressIndicator())
                      : _lines.isEmpty
                          ? const Center(child: Text('No messages yet'))
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _lines.length,
                              itemBuilder: (context, index) {
                                final line = _lines[index];
                                return _MessageBubble(line: line);
                              },
                            ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _replyController,
                            enabled: !closed && !_sending,
                            minLines: 1,
                            maxLines: 4,
                            hint: closed ? 'Ticket closed' : 'Type a reply…',
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _sendReply(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed:
                              closed || _sending ? null : _sendReply,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ChatLine {
  const _ChatLine({
    required this.isSupport,
    required this.message,
    required this.senderLabel,
    this.createdAt,
  });

  final bool isSupport;
  final String message;
  final String senderLabel;
  final String? createdAt;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.line});

  final _ChatLine line;

  @override
  Widget build(BuildContext context) {
    final align =
        line.isSupport ? Alignment.centerLeft : Alignment.centerRight;
    final bg = line.isSupport
        ? AppColors.primaryLight
        : AppColors.primary.withValues(alpha: 0.12);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(line.isSupport ? 4 : 16),
      bottomRight: Radius.circular(line.isSupport ? 16 : 4),
    );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.senderLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: line.isSupport
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(line.message),
              if ((line.createdAt ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  line.createdAt!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
