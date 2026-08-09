import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';

class ConversationsState {
    final List<dynamic> conversations;
    final String currentUsername;

    ConversationsState({
        required this.conversations,
        required this.currentUsername,
    });
}

class ConversationsNotifier extends StateNotifier<AsyncValue<ConversationsState>> {
    final WebSocketService _wsService = WebSocketService();

    ConversationsNotifier() : super(const AsyncValue.loading()) {
        fetchConversations();
        _listenToUserEvents();
    }

    Future<void> fetchConversations() async {
        try {
            final results = await Future.wait([
                ApiService.getConversations(),
                AuthService.getUsername(),
            ]);

            final stateData = ConversationsState(
                conversations: results[0] as List<dynamic>? ?? [],
                currentUsername: results[1] as String? ?? '',
            );

            state = AsyncValue.data(stateData);
        } catch (e, st) {
            state = AsyncValue.error(e, st);
        }
    }

    void _listenToUserEvents() {
        _wsService.connectUser();
        _wsService.userMessages.listen((raw) {
            try {
                final data = jsonDecode(raw as String);
                if (data['type'] == 'user_notification' || data['type'] == 'new_message') {
                    fetchConversations();
                }
            } catch (_) {}
        });
    }
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, AsyncValue<ConversationsState>>((ref) {
    return ConversationsNotifier();
});