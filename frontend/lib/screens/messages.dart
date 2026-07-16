import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
            body: const Center(
                child: Text('ChatMe'),
            ),
            
        );
    }
}