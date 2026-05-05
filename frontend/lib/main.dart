import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat',
      theme: ThemeData(
        
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
 final TextEditingController _senderController = TextEditingController(text:'Bishal');
 final TextEditingController _contentController = TextEditingController();

 Future<List<Message>> fetchMessages() async {
  final prefs = await SharedPreferences.getInstance(); // <--- Corrected S and P
  final token = prefs.getString('token');
  final response = await http.get(
    Uri.parse('http://10.0.2.2:8000/api/messages/'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    },
  );
  
  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    return jsonResponse.map((data) => Message.fromJson(data)).toList();
  } else {
    throw Exception('Failed to load messages: ${response.statusCode}');
  }
}

Future<void> sendMessage() async {
    if (_contentController.text.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/messages/'),
       headers: {
        'Content-Type':'application/json',
        'Authorization': 'Token $token',
       },
  
      body: jsonEncode({
        'sender': _senderController.text,
        'content': _contentController.text,
      }),
    );

    if (response.statusCode == 201) {
      // Clear the text box after sending
      _contentController.clear();
      // Refresh the list to show the new message
      setState(() {}); 
    } else {
      print('Error sending message: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title),
      ),
      body: FutureBuilder<List<Message>>(
        future: fetchMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator());
          }
          else if (snapshot.hasError){
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          else if (snapshot.hasData){
            return ListView.builder(
              itemCount: snapshot.data!.length, 
              itemBuilder: (context, index) {
                final msg = snapshot.data![index];
                return ListTile(
                  title: Text(msg.sender),
                  subtitle: Text(msg.content),
                  leading: CircleAvatar(child: Text(msg.sender[0])),
                );
              },
            );
          }
          else{
            return const Center(child: Text('No messages'));
          }
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(hintText: 'Type a message...'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class Message {
  final int id;
  final String sender;
  final String content;

  Message({required this.id, required this.sender, required this.content});
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      sender: json['sender'],
      content: json['content'],
    );
  }
}