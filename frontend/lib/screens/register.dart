import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';

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
        final screenWidth = MediaQuery.of(context).size.width;
        final formWidth = screenWidth > 600 ? 500.0 : double.infinity;

        return Scaffold(
            appBar: AppBar(
                title: const Text('Register'),
            ),
            body: Center(
                child: SizedBox(
                    width: formWidth,
                    child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: SingleChildScrollView( 
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
                                        onPressed: () async {
                                            try {
                                                final email = _emailController.text.trim();
                                                await ApiService.register(
                                                    username: _usernameController.text,
                                                    email: _emailController.text,
                                                    password: _passwordController.text,
                                                );
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Account Created!. Please check your email for verification code.'))
                                            );
                                            Navigator.pushReplacementNamed(
                                                context,
                                                '/verify-email',
                                                arguments: {'email': email},
                                            );
                                            }
                                            catch (e)
                                            {
                                                if (!mounted) return;
                                                String errorMessage = 'Registration failed';
                                                if (e is DioException && e.response != null) {
                                                    errorMessage = e.response!.data.toString();
                                                } else {
                                                    errorMessage = e.toString();
                                                }
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(errorMessage))
                                                );
                                            }
                                        },
                                        child: const Text('Register'),
                                    ),
                                    const SizedBox(height: 16.0),
                                    OutlinedButton.icon(
                                        onPressed: _handleGoogleSignIn,
                                        icon: const Icon(Icons.g_mobiledata, size: 28),
                                        label: const Text('Sign up with Google'),
                                    ),
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Already have an account? Login'),
                                    ),
                                ],
                            ),
                        ),
                    ),
                ),
            )
        );
    }

    Future<void> _handleGoogleSignIn() async {
    try {
        final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
        final GoogleSignInAccount? account = await googleSignIn.signIn();
        if (account == null) return;

        final GoogleSignInAuthentication auth = await account.authentication;
        final idToken = auth.idToken;

        if (idToken == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to get Google ID token.')),
            );
            return;
        }

        final response = await ApiService.googleLogin(idToken: idToken);
        await AuthService.saveTokens(
            access: response['access'],
            refresh: response['refresh'],
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Sign-In successful!')),
        );
        Navigator.pushReplacementNamed(context, '/messages');
    } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
        );
    }
}

}
