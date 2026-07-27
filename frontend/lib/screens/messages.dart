import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../providers/conversations_provider.dart';
import '../providers/auth_provider.dart';

class MessageScreen extends ConsumerWidget {
    const MessageScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Messages'),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                            await ref.read(authProvider.notifier).logout();
                            if (!context.mounted) return;
                            Navigator.pushReplacementNamed(context, '/');
                        },
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
                            
                            return ListTile(
                                leading: CircleAvatar(
                                    child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?'),
                                ),
                                title: Text(displayName),
                                subtitle: Text('Tap to open'),
                                onTap: () {
                                    Navigator.pushNamed(context, '/chat', arguments: 
                                    {
                                        'conversationId': chat['id'],
                                        'username': displayName,
                                    });
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