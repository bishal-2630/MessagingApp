import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
    const VerifyEmailScreen({super.key});

    @override
    State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
    final _otpController = TextEditingController();
    bool _isLoading = false;
    bool _isResending = false;
    String? _errorMessage;
    String? _successMessage;

    @override
    void dispose() {
        _otpController.dispose();
        super.dispose();
    }

    Future<void> _verifyEmail(String email) async {
        final otp = _otpController.text.trim();
        if (otp.length != 6) {
            setState(() => _errorMessage = 'Please enter a 6-digit verification code.');
            return;
        }

        setState(() {
            _isLoading = true;
            _errorMessage = null;
            _successMessage = null;
        });

        try {
            final res = await ApiService.verifyEmail(email: email, otp: otp);
            final access = res['access'];
            final refresh = res['refresh'];

            if (access != null && refresh != null) {
                await AuthService.saveTokens(access: access, refresh: refresh);
            }

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email verified successfully! Welcome to ChatMe.')),
            );

            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } catch (e) {
            setState(() {
                _errorMessage = 'Invalid or expired verification code. Please try again.';
            });
        } finally {
            if (mounted) {
                setState(() => _isLoading = false);
            }
        }
    }

    Future<void> _resendCode(String email) async {
        setState(() {
            _isResending = true;
            _errorMessage = null;
            _successMessage = null;
        });

        try {
            await ApiService.resendVerification(email: email);
            if (!mounted) return;
            setState(() {
                _successMessage = 'A new verification code has been sent to $email';
            });
        } catch (e) {
            setState(() {
                _errorMessage = 'Failed to resend code. Please try again later.';
            });
        } finally {
            if (mounted) {
                setState(() => _isResending = false);
            }
        }
    }

    @override
    Widget build(BuildContext context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] ?? '';

        return Scaffold(
            appBar: AppBar(title: const Text('Verify Email')),
            body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        const Icon(Icons.mark_email_read, size: 72, color: Color(0xFF34B7F1)),
                        const SizedBox(height: 16),
                        const Text(
                            'Verify Your Email',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'We sent a 6-digit verification code to:\n$email',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                                hintText: '000000',
                                border: OutlineInputBorder(),
                                counterText: '',
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
                        if (_successMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                                _successMessage!,
                                style: const TextStyle(color: Colors.greenAccent),
                                textAlign: TextAlign.center,
                            ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                            onPressed: _isLoading ? null : () => _verifyEmail(email),
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Verify Email', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                            onPressed: _isResending ? null : () => _resendCode(email),
                            child: _isResending
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                : const Text('Didn\'t receive code? Resend Code'),
                        ),
                    ],
                ),
            ),
        );
    }
}
