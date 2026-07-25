import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class MessageScreen extends StatelessWidget {
    const MessageScreen({super.key});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Messages'),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                            await AuthService.deleteTokens();
                            if (!context.mounted) return;
                            Navigator.pushReplacementNamed(context, '/');
                        },
                    ),
                ],
            ),
            body: FutureBuilder<List<dynamic>>(
                future: Future.wait([
                    ApiService.getConversations(),
                    AuthService.getUsername(),
                ]),
                builder: (context, snapshot){
                    if (snapshot.connectionState == ConnectionState.waiting){
                        return const Center(child: CircularProgressIndicator());
                    }
                    if(snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final results = snapshot.data as List<dynamic>;
                    final conversations = results[0] as List<dynamic>? ?? [];
                    final currentUsername = results[1] as String? ?? '';
                    if(conversations.isEmpty) {
                        return const Center(child: Text('No messages yet. Tap + to start a conversation.'));
                    }
                    return ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                            final chat = conversations[index];
                            final participants = chat['participants'] as List<dynamic>? ?? [];
                            final names = participants.map((p) => p['username'] as String? ?? '')
                            .where((n) => n.isNotEmpty && n != currentUsername)
                            .join(', ');

                            final displayName = names.isNotEmpty ? names : 'Chat Room #${chat['id']}';
                            
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
                                    }
                                    );
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