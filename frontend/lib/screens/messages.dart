import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../providers/conversations_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_messages_provider.dart';

class MessageScreen extends ConsumerWidget {
    const MessageScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final typingState = ref.watch(typingProvider);
        final currentUsername = ref.watch(authProvider).username ?? '';

        return Scaffold(
            appBar: AppBar(
                automaticallyImplyLeading: false,
                title: const Text('Messages'),
                actions: [
                    Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: GestureDetector(
                            onTap: () async {
                                await ref.read(authProvider.notifier).logout();
                                if (!context.mounted) return;
                                Navigator.pushReplacementNamed(context, '/');
                            },
                            child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.deepPurpleAccent,
                                child: Text(currentUsername.isNotEmpty ? currentUsername[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                        ),
                    ),
                ],
            ),
            body: ref.watch(conversationsProvider).when(
                loading: () => const Center(
                    child: CircularProgressIndicator(),
                ),
                error: (error,stack) => Center(child: Text('Error: $error')),

                data: (state) {
                    final conversations = state.conversations;
                    final currentUsername = state.currentUsername;

                    if(conversations.isEmpty) {
                        return const Center(child: Text('No messages yet. Tap + to start a conversation.'));
                    }
                    
                    return ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                            final chat = conversations[index];
                            final participants = chat['participants'] as List<dynamic>? ?? [];
                            final otherParticipants = participants.map((p) => p['username'] as String? ?? '')
                            .where((n) => n.isNotEmpty && n != currentUsername)
                            .join(', ');

                            final displayName = otherParticipants.isNotEmpty ? otherParticipants : 'You';
                            final lastMsg = chat['last_message'];
                            final lastMsgText = lastMsg != null && lastMsg['content'] != null ? lastMsg['content'] as String: 'No messages yet';
                            final bool isMyLastMsg = lastMsg != null && lastMsg['sender_username'] == currentUsername;
                            final int conversationIdInt = chat['id'] as int;
                            final isSomeoneTyping = typingState[conversationIdInt] ?? false;
                            final bool isDelivered = lastMsg != null && (lastMsg['is_delivered'] ?? false);
                            final bool isRead = lastMsg != null && (lastMsg['is_read'] ?? false);
                            final int unreadCount = chat['unread_count'] as int? ?? 0;
                            final bool hasUnread = unreadCount > 0 && !isMyLastMsg;
                            
                            return ListTile(
                                leading: Stack(
                                    children: [
                                        CircleAvatar(
                                            child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?'),
                                        ),
                                        if (participants.any((p) =>
                                            p['username'] != currentUsername &&
                                            (p['profile']?['is_online'] == true)))
                                            Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                                    ),
                                                ),
                                            ),
                                    ],
                                ),
                                title: Text(displayName),
                                subtitle: Row(
                                    children: [
                                    if (isMyLastMsg && !isSomeoneTyping) ...[
                                        Icon(
                                            isRead ? Icons.done_all
                                            : isDelivered ? Icons.done_all : Icons.done,
                                            size: 16,
                                            color: isRead ? const Color(0xFF34B7F1) : Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                        child: Text(
                                            isSomeoneTyping ? 'Typing...': lastMsgText,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: isSomeoneTyping ? const Color(0xFF34B7F1) 
                                                : hasUnread ? Colors.white : Colors.white70,
                                                fontStyle: isSomeoneTyping ? FontStyle.italic : FontStyle.normal,
                                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                            ),
                                        ),
                                    ),
                                    ],
                                ),
                                trailing: hasUnread
                                    ? Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                            color: Color(0xFF25D366),
                                            shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                            minWidth: 20,
                                            minHeight: 20,
                                        ),
                                        child: Text(
                                            '$unreadCount',
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                        ),
                                    )
                                    : null,
                                
                                onTap: () async {
                                    await Navigator.pushNamed(context, '/chat', arguments: 
                                    {
                                        'conversationId': chat['id'],
                                        'username': displayName,
                                        'targetUserId': participants
                                            .firstWhere(
                                                (p) => p['username'] != currentUsername,
                                                orElse: () => {},
                                            )['id'],
                                    });
                                    ref.invalidate(conversationsProvider);
                                },
                            );
                        },   
                    );
                },
            ),

            floatingActionButton: FloatingActionButton(
                onPressed: () {
                    Navigator.pushNamed(context, '/search');
                },
                child: const Icon(Icons.message),
            ),
            
        );
    }
}