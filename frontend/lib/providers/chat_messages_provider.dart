import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

 class ChatMessage {
    final int id;
    final int sender;
    final String senderUsername;
    final String content;
    final String createdAt;

    ChatMessage({
        required this.id,
        required this.sender,
        required this.senderUsername,
        required this.content,
        required this.createdAt,
    });

    factory ChatMessage.fromJson(Map<String, dynamic> json) {
        return ChatMessage(
            id: json['id'],
            sender: json['sender'],
            senderUsername: json['sender_username'],
            content: json['content'],
            createdAt: json['created_at'],
        );
    }
 }

 class ChatMessageNotifier extends StateNotifier<List<ChatMessage>> {
    final WebSocketService _wsService = WebSocketService();
    ChatMessageNotifier() : super([]);

    Future<void> init(int conversationId) async {
        try {
            final history = await ApiService.getMessages(conversationId);
            state = history.map((m) => ChatMessage.fromJson(m)).toList();
            
            await _wsService.connect(conversationId);
            _wsService.messages.listen((raw) {
                final data = jsonDecode(raw as String);
                final newMessage = ChatMessage.fromJson(data);
                state = [...state, newMessage];
            });  
        } catch (e) {
            state = [
                ChatMessage(
                    id: -1, 
                    sender: -1, 
                    senderUsername: 'System Error', 
                    content: 'Failed to load messages: $e', 
                    createdAt: DateTime.now().toIso8601String()
                )
            ];
        }
    }
    void sendMessage(String content) {
        _wsService.sendMessage(content);
    }

    void dispose_ws() {
        _wsService.disconnect();
    }
 }

 final chatMessagesProvider = StateNotifierProvider.autoDispose.family<ChatMessageNotifier, List<ChatMessage>, int>((ref, conversationId) {
    final notifier = ChatMessageNotifier();
    notifier.init(conversationId);
    ref.onDispose(() => notifier.dispose_ws());
    return notifier;
 });