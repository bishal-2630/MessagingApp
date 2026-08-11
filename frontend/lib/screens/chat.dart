import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_messages_provider.dart';
import '../providers/conversations_provider.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

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
    Timer? _typingTimer;
    final ScrollController _scrollController = ScrollController();

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addObserver(this);
    }

    @override
    void dispose() {
        NotificationService.activeConversationId = null;
        WidgetsBinding.instance.removeObserver(this);
        _messageController.dispose();
        _scrollController.dispose();
        _typingTimer?.cancel();
        ref.invalidate(conversationsProvider);
        super.dispose();
    }

    void _scrollToBottom() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
                _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                );
            }
        });
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
        final rawArgs = ModalRoute.of(context)?.settings.arguments;
        int conversationId = 0;
        String username = 'Chat';

        if (rawArgs is Map<String, dynamic>) {
            conversationId = rawArgs['conversationId'];
            username = rawArgs['username'] ?? 'Chat';
            _conversationId = conversationId;

            NotificationService.activeConversationId = conversationId;
            
            if (rawArgs['targetUserId'] != null && !_hasFetchedStatus) {
                _hasFetchedStatus = true;
                _fetchStatus(rawArgs['targetUserId']);
            }
        }

        final currentUsername = ref.watch(authProvider).username ?? '';
        final messages = ref.watch(chatMessagesProvider(conversationId));
        final typingMap = ref.watch(typingProvider);
        final bool _isOtherUserTyping = typingMap[conversationId] ?? false;
        _scrollToBottom();

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
                                                color: Colors.green,
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
                                if (_isOtherUserTyping)
                                    const Text(
                                        'typing...',
                                        style: TextStyle(
                                            fontSize: 12, 
                                            color: Color(0xFF34B7F1), 
                                            fontStyle: FontStyle.italic,
                                        ),
                                    )
                                else if (!_isOnline && _lastSeenText.isNotEmpty)
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
                        child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: messages.length + (_isOtherUserTyping ? 1 : 0),
                            controller: _scrollController,
                            itemBuilder: (context, index) {
                                if (index == messages.length) {
                                    return const TypingBubble();
                                }
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
                                        decoration: InputDecoration(
                                            hintText: 'Type a message...',
                                            border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(24),   
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(24),   
                                                borderSide: BorderSide(color: Colors.white24),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(24),   
                                                borderSide: BorderSide(color: Color(0xFF34B7F1)),
                                            ),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                        onChanged: (text) {
                                            final wsService = WebSocketService();
                                            if (text.isNotEmpty) {
                                                wsService.sendTypingStatus(true);
                                            }
                                            _typingTimer?.cancel();
                                            _typingTimer = Timer(const Duration(seconds: 2), () {
                                                wsService.sendTypingStatus(false);
                                            });
                                        },
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
                                        size: 16,
                                        color: msg.isRead 
                                            ? const Color(0xFF34B7F1) 
                                            : Colors.white70,
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

class TypingBubble extends StatefulWidget {
    const TypingBubble({super.key});

    @override
    State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble> with SingleTickerProviderStateMixin {
    late AnimationController _controller;

    @override
    void initState() {
        super.initState();
        _controller = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1200),
        )..repeat();
    }

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Align(
            alignment: Alignment.centerLeft,
            child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                        bottomLeft: Radius.zero,
                    ),
                ),
                child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                        return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (index) {
                                final delay = index * 0.2;
                                final value = (math.sin((_controller.value * 2 * math.pi) - (delay * math.pi)) + 1) / 2;
                                return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: Transform.translate(
                                        offset: Offset(0, -4 * value),
                                        child: CircleAvatar(
                                            radius: 3.5,
                                            backgroundColor: const Color(0xFF34B7F1).withOpacity(0.4 + (0.6 * value)),
                                        ),
                                    ),
                                );
                            }),
                        );
                    },
                ),
            ),
        );
    }
}
