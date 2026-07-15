import 'package:flutter/material.dart';

class RegisterScreen extends  StatefulWidget {
    const RegisterScreen({super.key});
    @override
    State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>{
    final TextEditingController _usernameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _confirmPasswordController = TextEditingController();

    @override
    void dispose() {
        _usernameController.dispose();
        _emailController.dispose();
        _passwordController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Register'),
            ),
            body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        TextFormField(
                            controller: _usernameController, 
                            decoration: const InputDecoration(
                                labelText: 'Username',
                            ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                            controller: _emailController, 
                            keyboardType: TextInputType.emailAddress,  
                            decoration: const InputDecoration(
                                labelText: 'Email',
                            ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                            controller: _passwordController, 
                            obscureText: true,

                            decoration: const InputDecoration(
                                labelText: 'Password',
                            ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                            controller: _confirmPasswordController, 
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Confirm Password',
                            ),
                        ),

                        const SizedBox(height: 24.0),
                        ElevatedButton(
                            onPressed: () {
                                print(_emailController.text);
                            },
                            child: const Text('Register'),
                        ),

                    ]
                    
                )
            )
        );
    }
}

