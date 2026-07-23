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
                future: ApiService.getConversations(),
                builder: (context, snapshot){
                    if (snapshot.connectionState ==
                    ConnectionState.waiting){
                        return const Center(child: CircularProgressIndicator());
                    }
                    if(snapshot.hasError) {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                            await AuthService.deleteTokens();
                            if (context.mounted) {
                                Navigator.pushReplacementNamed(context, '/');
                            }
                        });
                        return const Center(child: CircularProgressIndicator());
                    }

                    final conversations = snapshot.data ?? [];
                    if(conversations.isEmpty) {
                        return const Center(child: Text('No messages yet. Tap + to start a conversation.'));
                    }
                    return ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                            final chat = conversations[index];
                            return ListTile(
                                title: Text('Conversation ${chat['id']}'),
                                subtitle: Text('Tap to open'),
                                onTap: () {
                                    Navigator.pushNamed(context, '/chat', arguments: chat['id']);
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