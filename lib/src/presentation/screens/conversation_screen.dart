import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/app_error.dart';
import '../../core/app_theme.dart';
import '../../domain/models.dart';
import '../widgets/app_widgets.dart';
import '../widgets/safety_sheets.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _messageController = TextEditingController();
  bool _loaded = false;
  bool _loadingMessages = true;
  bool _sending = false;
  String? _loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = OceanMatchScope.of(context);
    final summary = controller.conversationSummaries
        .where(
          (item) => item.conversation.id == widget.conversationId,
        )
        .firstOrNull;

    if (summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conversation')),
        body: const Center(child: Text('Conversation introuvable.')),
      );
    }

    final messages = controller.messagesFor(widget.conversationId);
    final currentUserId = controller.currentUser!.id;
    final canSend =
        !summary.isBlocked && summary.match.status == MatchStatus.active;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (summary.otherPhoto != null) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: OceanColors.mist,
                child: ClipOval(
                  child: PhotoTile(
                    url: summary.otherPhoto!.url,
                    borderRadius: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(summary.otherProfile.firstName),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') {
                showReportSheet(
                  context: context,
                  targetUserId: summary.otherProfile.userId,
                  targetName: summary.otherProfile.firstName,
                  conversationId: widget.conversationId,
                );
              }
              if (value == 'block') {
                showBlockDialog(
                  context: context,
                  targetUserId: summary.otherProfile.userId,
                  targetName: summary.otherProfile.firstName,
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'report', child: Text('Signaler')),
              PopupMenuItem(value: 'block', child: Text('Bloquer')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!canSend)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: OceanColors.coral.withValues(alpha: 0.12),
                child: const Text(
                  'Conversation inactive : aucun nouveau message possible.',
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: OceanColors.seaTeal.withValues(alpha: 0.10),
                child: const Text(
                  'Vous avez matche. La messagerie texte est gratuite entre matchs.',
                ),
              ),
            Expanded(
              child: _buildMessagesBody(
                context: context,
                messages: messages,
                currentUserId: currentUserId,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: canSend && !_sending,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        hintText: 'Ecrire un message...',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: canSend && !_sending ? _send : null,
                    icon: const Icon(Icons.send),
                    tooltip: 'Envoyer',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesBody({
    required BuildContext context,
    required List<Message> messages,
    required String currentUserId,
  }) {
    if (_loadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }
    final loadError = _loadError;
    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(loadError, textAlign: TextAlign.center),
        ),
      );
    }
    if (messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Dites bonjour et voyez si vos routes se croisent.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMine = message.senderId == currentUserId;
        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76,
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? OceanColors.gold : OceanColors.cardAlt,
              borderRadius: BorderRadius.circular(8),
              border: isMine ? null : Border.all(color: OceanColors.line),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isMine ? OceanColors.midnight : OceanColors.ink,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loadingMessages = true;
      _loadError = null;
    });
    try {
      await OceanMatchScope.of(context).loadMessages(widget.conversationId);
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = userFacingError(error));
      }
    } finally {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  Future<void> _send() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await OceanMatchScope.of(context).sendMessage(
        conversationId: widget.conversationId,
        content: text,
      );
      _messageController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
