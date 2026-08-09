import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

import 'auth_provider.dart';

final typingProvider = StateProvider<Map<int, bool>>((ref) => {});

class ChatMessage {
    final int id;
    final int sender;
    final String senderUsername;
    final String content;
    final bool isDelivered;
    final bool isRead;
    final String createdAt;

    ChatMessage({
        required this.id,
        required this.sender,
        required this.senderUsername,
        required this.content,
        required this.isDelivered,
        required this.isRead,
        required this.createdAt,
    });

    factory ChatMessage.fromJson(Map<String, dynamic> json) {
        return ChatMessage(
            id: json['id'],
            sender: json['sender'],
            senderUsername: json['sender_username'],
            content: json['content'],
            isDelivered: json['is_delivered'] ?? false,
            isRead: json['is_read'] ?? false,
            createdAt: json['created_at'],
        );
    }
}

class ChatMessageNotifier extends StateNotifier<List<ChatMessage>> {
    final WebSocketService _wsService = WebSocketService();
    final Ref _ref;
    final int _conversationId;
    bool _isInitialized = false;
    ChatMessageNotifier(this._ref, this._conversationId) : super([]);

    Future<void> init(int conversationId) async {
        await _wsService.connect(conversationId);
        _wsService.sendReadReceipt(conversationId);
        _wsService.messages.listen((raw) {
            final data = jsonDecode(raw as String);
            if (data['type'] == 'typing_status') {
                final currentUsername = _ref.read(authProvider).username;
                if (data['username'] != currentUsername) {
                    _ref.read(typingProvider.notifier).update((state) {
                        final updated = Map<int, bool>.from(state);
                        updated[conversationId] = data['is_typing'] ?? false;
                        return updated;
                    });
                }
                return;
            }
            if (data['type'] == 'message_read') {
                final readerId = data['reader_id'];
                state = state.map((msg) {
                    // Only mark as read if the reader is NOT the sender of this message
                    // (i.e. the recipient has read the sender's message)
                    if (readerId != null && msg.sender != readerId) {
                        return ChatMessage(
                            id: msg.id,
                            sender: msg.sender,
                            senderUsername: msg.senderUsername,
                            content: msg.content,
                            isDelivered: true,
                            isRead: true,
                            createdAt: msg.createdAt,
                        );
                    }
                    return msg;
                }).toList();
                return;
            }
            if (data['type'] == 'chat_message') {
                final newMessage = ChatMessage.fromJson(data);
                state = [...state, newMessage];
                final currentUsername = _ref.read(authProvider).username;
                // Only send read receipt if the message was sent by the OTHER user
                if (newMessage.senderUsername != currentUsername) {
                    _wsService.sendReadReceipt(conversationId);
                }
            }
        });
        try {
            final history = await ApiService.getMessages(conversationId);
            final messageList = history.map((m) => ChatMessage.fromJson(m)).toList();
            state = messageList;
            _isInitialized = true;
        } catch (e) {
            if (!_isInitialized && state.isEmpty) {
                state = [
                    ChatMessage(
                        id: -1, 
                        sender: -1, 
                        senderUsername: 'System Error', 
                        content: 'Failed to load messages: $e', 
                        isDelivered: false,
                        isRead: false,
                        createdAt: DateTime.now().toIso8601String()
                    )
                ];
            }
        }
    }
    
    void sendMessage(String content) {
        _wsService.sendMessage(content);
    }
}

final chatMessagesProvider = StateNotifierProvider.family<ChatMessageNotifier, List<ChatMessage>, int>((ref, conversationId) {
    final notifier = ChatMessageNotifier(ref, conversationId);
    notifier.init(conversationId);
    return notifier;
});
