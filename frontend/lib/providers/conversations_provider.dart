import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ConversationsState {
    final List<dynamic> conversations;
    final String currentUsername;

    ConversationsState({
        required this.conversations,
        required this.currentUsername,
    });
}

final conversationsProvider = FutureProvider<ConversationsState>((ref) async {
    final results = await Future.wait([
        ApiService.getConversations(),
        AuthService.getUsername(),
    ]);

    return ConversationsState(
        conversations: results[0] as List<dynamic>? ?? [],
        currentUsername: results[1] as String? ?? '',
    );
});