import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _email;
  bool? _isVerified;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.getProfile();
      if (mounted) {
        setState(() {
          _email = data['email'];
          _isVerified = data['is_email_verified'] ?? false;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = ref.watch(authProvider).username ?? 'User';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            // 1. Large Avatar with User Initial
            Center(
              child: CircleAvatar(
                radius: 54,
                backgroundColor: Colors.deepPurpleAccent,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Display Username
            Text(
              username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@${username.toLowerCase()}',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 10),

            // 3. Email & Verification Status
            if (_loading)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_email != null) ...[
              Text(
                _email!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              // Verified / Unverified badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (_isVerified == true)
                      ? Colors.green.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (_isVerified == true) ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (_isVerified == true)
                          ? Icons.verified_user
                          : Icons.warning_amber_rounded,
                      size: 14,
                      color: (_isVerified == true) ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (_isVerified == true) ? 'Email Verified' : 'Email Not Verified',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: (_isVerified == true) ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // 4. Settings & Actions List
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: isDarkMode,
                activeColor: Colors.deepPurpleAccent,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
            ),

            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authProvider.notifier).logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
