import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_messages_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';

class ChatScreen extends ConsumerStatefulWidget {
    const ChatScreen({super.key});

    @override
    ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with WidgetsBindingObserver {
    final TextEditingController _messageController = TextEditingController();
    int? _conversationId;
    bool _isOnline = false;
    String _lastSeenText = '';
    bool _hasFetchedStatus = false;

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addObserver(this);
    }

    @override
    void dispose() {
        WidgetsBinding.instance.removeObserver(this);
        _messageController.dispose();
        super.dispose();
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
        if (state == AppLifecycleState.resumed && _conversationId != null) {
            ref.invalidate(chatMessagesProvider(_conversationId!));
        }
    }

    Future<void> _fetchStatus(int userId) async {
        try {
            final data = await ApiService.getUserStatus(userId);
            if (mounted) {
                setState(() {
                    _isOnline = data['is_online'] ?? false;
                    _lastSeenText = data['last_seen'] ?? '';
                });
            }
        } catch (_) {}
    }

    String _formatToLocalTime(String isoString) {
        try {
            final parseDate = DateTime.parse(isoString).toLocal();
            final hour = parseDate.hour.toString().padLeft(2, '0');
            final minute = parseDate.minute.toString().padLeft(2, '0');
            return '$hour:$minute';
        } catch (_) {
            return '';
        }
    }

    @override
    Widget build(BuildContext context) {
        final rawArgs = ModalRoute.of(context)!.settings.arguments;
        int conversationId = 0;
        String username = 'Chat';

        if (rawArgs is Map<String, dynamic>) {
            conversationId = rawArgs['conversationId'];
            username = rawArgs['username'] ?? 'Chat';
            _conversationId = conversationId;
            
            if (rawArgs['targetUserId'] != null && !_hasFetchedStatus) {
                _hasFetchedStatus = true;
                _fetchStatus(rawArgs['targetUserId']);
            }
        }

        final currentUsername = ref.watch(authProvider).username ?? '';
        final messages = ref.watch(chatMessagesProvider(conversationId));

        return Scaffold(
            appBar: AppBar(
                title: Row(
                    children: [
                        Stack(
                            children: [
                                CircleAvatar(
                                    radius: 18,
                                    child: Text(username.isNotEmpty ? username[0].toUpperCase() : ''),
                                ),
                                if (_isOnline)
                                    Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Theme.of(context).scaffoldBackgroundColor, 
                                                    width: 2,
                                                ),
                                            ),
                                        ),
                                    ),
                            ],
                        ),
                        const SizedBox(width: 12),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(username, style: const TextStyle(fontSize: 16)),
                                if (!_isOnline && _lastSeenText.isNotEmpty)
                                    Text(
                                        _lastSeenText,
                                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                                    ), 
                            ],
                        ),
                    ],
                ),
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
                    
                    // 2. Input Bar
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
                        Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Text(
                                    _formatToLocalTime(msg.createdAt),
                                    style: const TextStyle(fontSize: 10, color: Colors.white60),
                                ),
                                if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                        msg.isRead 
                                            ? Icons.done_all 
                                            : msg.isDelivered 
                                                ? Icons.done_all 
                                                : Icons.done,
                                        size: 12,
                                        color: msg.isRead ? Colors.green : Colors.white60,
                                    ),
                                ],
                            ],
                        ),
                    ],
                ),
            ),
        );
    }
}
