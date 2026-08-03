import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VerifyOtpScreen extends StatefulWidget {
    const VerifyOtpScreen({super.key});

    @override
    State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
    final _otpController = TextEditingController();
    bool _isLoading = false;
    String? _errorMessage;

    @override
    void dispose() {
        _otpController.dispose();
        super.dispose();
    }

    Future<void> _verifyOtp(String email) async {
        final otp = _otpController.text.trim();
        if (otp.length != 6) {
            setState(() => _errorMessage = 'Please enter a 6-digit OTP code.');
            return;
        }

        setState(() {
            _isLoading = true;
            _errorMessage = null;
        });

        try {
            final res = await ApiService.verifyOtp(email: email, otp: otp);
            final resetToken = res['reset_token'];
            if (!mounted) return;

            Navigator.pushReplacementNamed(
                context,
                '/reset-password',
                arguments: {'resetToken': resetToken},
            );
        } catch (e) {
            setState(() {
                _errorMessage = 'Invalid or expired OTP code. Please try again.';
            });
        } finally {
            if (mounted) {
                setState(() => _isLoading = false);
            }
        }
    }

    @override
    Widget build(BuildContext context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] ?? '';

        return Scaffold(
            appBar: AppBar(title: const Text('Verify OTP')),
            body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        const Icon(Icons.mark_email_read, size: 72, color: Color(0xFF34B7F1)),
                        const SizedBox(height: 16),
                        const Text(
                            'Enter OTP Code',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'We sent a 6-digit code to:\n$email',
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
                        const SizedBox(height: 24),
                        ElevatedButton(
                            onPressed: _isLoading ? null : () => _verifyOtp(email),
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Verify OTP', style: TextStyle(fontSize: 16)),
                        ),
                    ],
                ),
            ),
        );
    }
}
