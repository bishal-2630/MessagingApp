import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
    const ForgotPasswordScreen({super.key});

    @override
    State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
    final _emailController = TextEditingController();
    bool _isLoading = false;
    String? _errorMessage;

    @override
    void dispose() {
        _emailController.dispose();
        super.dispose();
    }

    Future<void> _sendOtp() async {
        final email = _emailController.text.trim();
        if (email.isEmpty) {
            setState(() => _errorMessage = 'Please enter your email.');
            return;
        }

        setState(() {
            _isLoading = true;
            _errorMessage = null;
        });

        try {
            final res = await ApiService.forgotPassword(email);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res['message'] ?? 'OTP sent to your email.')),
            );
            Navigator.pushNamed(
                context,
                '/verify-otp',
                arguments: {'email': email},
            );
        } catch (e) {
            setState(() {
                _errorMessage = 'Failed to send OTP. Please check your email.';
            });
        } finally {
            if (mounted) {
                setState(() => _isLoading = false);
            }
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('Forgot Password')),
            body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAlignment.stretch,
                    children: [
                        const Icon(Icons.lock_reset, size: 72, color: Color(0xFF34B7F1)),
                        const SizedBox(height: 16),
                        const Text(
                            'Reset Password',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                            'Enter your registered email address to receive a 6-digit OTP code.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                            ),
                        ),
                        if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.redAccent),
                                textAlign: TextAlign.center,
                            ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Send OTP Code', style: TextStyle(fontSize: 16)),
                        ),
                    ],
                ),
            ),
        );
    }
}
