import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
    const ResetPasswordScreen({super.key});

    @override
    State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
    final _passwordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    bool _isLoading = false;
    bool _obscurePassword = true;
    String? _errorMessage;

    @override
    void dispose() {
        _passwordController.dispose();
        _confirmPasswordController.dispose();
        super.dispose();
    }

    Future<void> _resetPassword(String resetToken) async {
        final newPassword = _passwordController.text.trim();
        final confirmPassword = _confirmPasswordController.text.trim();

        if (newPassword.length < 8) {
            setState(() => _errorMessage = 'Password must be at least 8 characters long.');
            return;
        }

        if (newPassword != confirmPassword) {
            setState(() => _errorMessage = 'Passwords do not match.');
            return;
        }

        setState(() {
            _isLoading = true;
            _errorMessage = null;
        });

        try {
            final res = await ApiService.resetPassword(
                resetToken: resetToken,
                newPassword: newPassword,
            );
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(res['message'] ?? 'Password reset successfully! Please log in.'),
                    backgroundColor: Colors.green,
                ),
            );

            Navigator.popUntil(context, ModalRoute.withName('/'));
        } catch (e) {
            setState(() {
                _errorMessage = 'Failed to reset password. Please try again.';
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
        final resetToken = args?['resetToken'] ?? '';

        return Scaffold(
            appBar: AppBar(title: const Text('Set New Password')),
            body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAlignment.stretch,
                    children: [
                        const Icon(Icons.password, size: 72, color: Color(0xFF34B7F1)),
                        const SizedBox(height: 16),
                        const Text(
                            'New Password',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                            'Please enter your new password below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                                labelText: 'New Password',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                border: const OutlineInputBorder(),
                            ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscurePassword,
                            decoration: const InputDecoration(
                                labelText: 'Confirm New Password',
                                prefixIcon: Icon(Icons.lock_outline),
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
                            onPressed: _isLoading ? null : () => _resetPassword(resetToken),
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Reset Password', style: TextStyle(fontSize: 16)),
                        ),
                    ],
                ),
            ),
        );
    }
}
