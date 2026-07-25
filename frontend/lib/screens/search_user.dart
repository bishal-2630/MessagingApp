import 'package:flutter/material.dart';
import '../services/api_service.dart';


class SearchUserScreen extends StatefulWidget{
    const SearchUserScreen({super.key});

    @override
    State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen>{
    final TextEditingController _usernameController = TextEditingController();
    Map<String, dynamic>? _foundUser;
    bool _isLoading = false;

    Future<void> _searchUser() async {
        setState(() {
            _isLoading = true;
            _foundUser = null;
        });
        try {
            final result = await ApiService.searchUser(_usernameController.text.trim());
            setState(() {
                _foundUser = result;
                _isLoading = false;
            });
        } catch (e) {
            setState(() {
                _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User not found')),
            );
        }
    }

    @override
    Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text('Find User')
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                children:[
                    TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                            labelText: 'Search username...',
                        ),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                        onPressed: _searchUser, child: const Text('Search User')
                    ),
                    const SizedBox(height: 24),
                    if(_isLoading) const CircularProgressIndicator()
                    else if(_foundUser !=null)

                    Card(
                        child: ListTile(
                            title: Text(_foundUser!['username']),
                            subtitle: Text(_foundUser!['email']),
                            trailing: SizedBox(
                                width: 90,
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 36),
                                    ),
                                    onPressed: () async {
                                        final conv = await ApiService.getOrCreateConversation(_foundUser!['id']);
                                        Navigator.pushNamed(context, '/chat', arguments: {
                                            'conversationId':conv['id'],
                                            'username': _foundUser!['username'],
                                        });
                                    },
                                    child: const Text('Chat'),
                                ),
                            ),
                        ),
                    )
                ]
            )
        )
    );
    }
}


