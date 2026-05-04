import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatefulWidget {
    const SignUpScreen({super.key});

    @override
    State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>{
    final TextEditingController _usernameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _confirmPasswordController = TextEditingController();
    
    Future<void> registerUser() async{
        if (_passwordController.text != _confirmPasswordController.text) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Passwords do not match')),
            );
            return;
        }

        final response = await http.post(
            Uri.parse('http://10.0.2.2:8000/api/register/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
                'username': _usernameController.text,
                'email': _emailController.text,
                'password': _passwordController.text,
            }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
            final data = jsonDecode(response.body);
            print("Registration Successful! Token: ${data['token']}");
        } else {
            print("Registration failed: ${response.body}");
        } 
    }

    @override
    Widget build(BuildContext context){
        return Scaffold(
            appBar: AppBar(title: const Text('Sign Up')),
            body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                        TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(labelText: 'Username'),
                        ),
                        TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email address'),
                        ),
                        TextField(
                            controller: _passwordController,
                            decoration: const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                        ),
                        TextField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(labelText: 'Confirm Password'),
                            obscureText: true,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                            onPressed: (){

                            },
                            child: const Text('Create Account'),
                        ),
                    ],
                ),

            ),

        );
    }
}

