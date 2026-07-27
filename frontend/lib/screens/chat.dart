import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_messages_provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';

class ChatScreen extends ConsumerStatefulWidget {
    const ChatScreen({super.key});

    @override
    ConsumerState<ChatScreen> createState()=> _ChatScreenState();
    
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
    final TextEditingController _messageController = TextEditingController();

    @override
    Widget build(BuildContext context) {
        final rawArgs = ModalRoute.of(context)!.settings.arguments;
        int conversationId = 0;
        String username = 'Chat';

        if (rawArgs is Map<String, dynamic>) {
            conversationId = rawArgs['conversationId'];
            username = rawArgs['username'] ?? 'Chat';
        }
        final currentUsername = ref.watch(authProvider).username ?? '';
        final messages = ref.watch(chatMessagesProvider(conversationId));

        return Scaffold(
            appBar: AppBar(
                title: Text(username),
            ),
            body: Column(
                children: [
                    // 1. Messages List
                    Expanded(
                        child: messages.isEmpty
                                ? const Center(child: Text('No messages yet. Say hello!'))
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16.0),
                                    itemCount: messages.length,
                                    itemBuilder: (context, index) {
                                        final msg = messages[index];
                                        final isMe = msg.senderUsername == currentUsername;
                                return _buildBubble(msg, isMe);
                            },
                        ),
                ),
                
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                        children: [
                            Expanded(
                                child: TextField(
                                    controller: _messageController,
                                    decoration: const InputDecoration(
                                        hintText: 'Type a message...',
                                        border: OutlineInputBorder(),
                                    ),
                                ),
                            ),
                            const SizedBox(width: 8.0),
                            IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () {
                                    final text = _messageController.text.trim();
                                    if (text.isEmpty) return;
                                    ref.read(chatMessagesProvider(conversationId).notifier).sendMessage(text);
                                    _messageController.clear();
                                },
                            ),
                        ],
                    ),
                ),
            ],
        ),
    );
    }

    Widget _buildBubble(ChatMessage msg, bool isMe) {
    return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
                color: isMe ? Colors.deepPurpleAccent : Colors.grey[800],
                borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                    bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                ),
            ),
            child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                    Text(msg.content),
                    const SizedBox(height: 2),
                    Text(
                        msg.createdAt.substring(11, 16), 
                        style: const TextStyle(fontSize: 10, color: Colors.white60),
                    ),
                ],
            ),
        ),
    );
}
}



