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

    Future<void> _sendMessage() async {
        final text  = _messageController.text.trim();
        if (text.isEmpty) return;
        _messageController.clear();

        try {
            await ApiService.sendMessage(widget.conversationId, text);
            _fetchmessages(conversationId);

        } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to send message.')),
            );
        }
    }
}