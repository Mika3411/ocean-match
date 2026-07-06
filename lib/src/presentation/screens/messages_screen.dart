import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'conversation_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OceanMatchScope.of(context);
    final conversations = controller.conversationSummaries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: controller.refreshConversations,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: conversations.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SectionCard(
                    title: 'Aucune conversation',
                    subtitle:
                        'Les messages apparaissent apres un match. La messagerie texte entre matchs est gratuite.',
                    child: PrivacyNote(),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final summary = conversations[index];
                  final lastMessage = summary.lastMessage?.content ??
                      'Vous avez matche. Dites bonjour.';
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: OceanColors.mist,
                        child: summary.otherPhoto == null
                            ? const Icon(Icons.person)
                            : ClipOval(
                                child: PhotoTile(
                                  url: summary.otherPhoto!.url,
                                  borderRadius: 28,
                                ),
                              ),
                      ),
                      title: Text(
                        summary.otherProfile.firstName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        summary.isBlocked
                            ? 'Conversation bloquee'
                            : lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: summary.isBlocked
                          ? const Icon(Icons.block, color: OceanColors.coral)
                          : const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConversationScreen(
                              conversationId: summary.conversation.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: conversations.length,
              ),
      ),
    );
  }
}
