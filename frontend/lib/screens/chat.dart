import '../services/api_service.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
    const ChatScreen({super.key});

    @override
    State<ChatScreen> createState()=> _ChatScreenState();
    
}

class _ChatScreenState extends State<ChatScreen> {
    final TextEditingController _messageController = TextEditingController();
    List<dynamic> _messages = [];
    bool _isLoading = true;

    Future<void> _fetchmessages(int conversationId) async {
        try {
            final messages = await ApiService.getMessages(conversationId);
            setState(() {
                _messages = messages;
                _isLoading = false;
            });
        } catch (_) {
            setState(() {
                _isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading messages.')),
            );
        }

    }

    Future<void> _sendMessage(int conversationId) async {
        final text  = _messageController.text.trim();
        if (text.isEmpty) return;
        _messageController.clear();

        try {
            await ApiService.sendMessage(conversationId, text);
            _fetchmessages(conversationId);

        } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to send message.')),
            );
        }
    }

        @override
    Widget build(BuildContext context) {
        final int conversationId = ModalRoute.of(context)!.settings.arguments as int;

        // Fetch messages once on page load
        if (_isLoading && _messages.isEmpty) {
            _fetchmessages(conversationId);
        }

        return Scaffold(
            appBar: AppBar(
                title: Text('Chat Room #$conversationId'),
            ),
            body: Column(
                children: [
                    // 1. Messages List
                    Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _messages.isEmpty
                                ? const Center(child: Text('No messages yet. Say hello!'))
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16.0),
                                    itemCount: _messages.length,
                                    itemBuilder: (context, index) {
                                        final msg = _messages[index];
                                        return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                    Text(
                                                        msg['sender_username'] ?? 'Unknown',
                                                        style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12.0,
                                                            color: Colors.deepPurpleAccent,
                                                        ),
                                                    ),
                                                    const SizedBox(height: 2.0),
                                                    Container(
                                                        padding: const EdgeInsets.all(10.0),
                                                        decoration: BoxDecoration(
                                                            color: Colors.grey[800],
                                                            borderRadius: BorderRadius.circular(8.0),
                                                        ),
                                                        child: Text(msg['content'] ?? ''),
                                                    ),
                                                ],
                                            ),
                                        );
                                    },
                                ),
                    ),

                    // 2. Bottom Input Bar
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
                                    onPressed: () => _sendMessage(conversationId),
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        );
    }
}