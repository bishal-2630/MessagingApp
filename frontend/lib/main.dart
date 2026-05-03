import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
 Future<List<Message>> fetchMessages() async {
  final response = await http.get(Url.parse('http://10.0.2.2:8000/api/messages/'));

  if (response.statusCode == 200) {
    Map<String, dynamic> data = jsonDecode(response.body);

    List<dynamic> results = data['results'];

    return results.map((item) => Message.fromJson(item)).toList();

  } else {
    throw Exception('Failed to load messages');
  }
 }

 int  _counter = 0;

  void _incrementCounter() {
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title),
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
        }
      ),
      );
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