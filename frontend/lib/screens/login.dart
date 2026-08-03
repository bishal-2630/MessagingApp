import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:dio/dio.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>{
    final _formKey = GlobalKey<FormState>();
    bool _isPasswordVisible =false;
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();

    @override
    void dispose() {
        _emailController.dispose();
        _passwordController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final formWidth = screenWidth > 600 ? 500.0 : double.infinity;
        return Scaffold(
            body: Center(
              child: SizedBox(
                width: formWidth,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                              Text(
                                'Welcome',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 32.0),
                              TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                      labelText: 'Email',
                                      hintText: 'Enter your email',
                                      prefixIcon: Icon(Icons.email),
                                  ),
                              ),

                              
                              const SizedBox(height: 16.0),
                              TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Enter your password',
                                      prefixIcon: Icon(Icons.lock),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible =
                                                !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                  ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/forgot-password');
                                  },
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      final response = await ApiService.login(
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                      );
                                      await ref.read(authProvider.notifier).login(
                                      access: response['access'],
                                      refresh: response['refresh'],
                                      username: response['username'],
                                      );
                                      await NotificationService.init();
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Login successfull!')),
                                      );

                                      Navigator.pushReplacementNamed(context, '/messages');
                                    } catch (e) {
                                      if (!mounted) return;
                                      String errorMessage = 'Login failed';
                                      if (e is DioException && e.response != null) {
                                        errorMessage = e.response!.data.toString();
                                      } else {
                                        errorMessage = e.toString();
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(errorMessage)),
                                      );
                                    }
                                  },
                                  child: const Text('Login'),
                              ),
                              const SizedBox(height: 16.0),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Don't have an account?"),
                                    TextButton(
                                      onPressed: () {
                                          Navigator.pushNamed(context, '/register');
                                      },
                                      child: const Text('Create one'),
                                    ),
                                  ],
                              ),
                          ],
                      ),
                    ), 
                ),
              )
            )
          )
        );
  }
}
  

