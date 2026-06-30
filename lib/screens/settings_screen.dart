import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/audio_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseService _fbService = FirebaseService();
  bool _notificationsEnabled = true;
  bool _emailPrivacy = false;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Settings')),
      body: ListView(
        children: [
          _sectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(
              Icons.notifications_outlined,
              color: Colors.teal,
            ),
            title: const Text('Push Notifications'),
            subtitle: const Text(
              'Get notified when someone is interested in your items',
            ),
            value: _notificationsEnabled,
            activeTrackColor: Colors.teal,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
          ),
          const Divider(),

          _sectionHeader('Privacy'),
          SwitchListTile(
            secondary: const Icon(
              Icons.visibility_off_outlined,
              color: Colors.teal,
            ),
            title: const Text('Hide Email from Buyers'),
            subtitle: const Text(
              'Buyers will contact you through in-app messaging only',
            ),
            value: _emailPrivacy,
            activeTrackColor: Colors.teal,
            onChanged: (val) => setState(() => _emailPrivacy = val),
          ),
          const Divider(),

          _sectionHeader('Media'),
          ListTile(
            leading: const Icon(Icons.music_note, color: Colors.teal),
            title: const Text('Background Music'),
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Colors.teal),
              onPressed: () => AudioService.toggleBGM(),
            ),
          ),

          _sectionHeader('Language'),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.teal),
            title: const Text('App Language'),
            subtitle: Text(_selectedLanguage),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(),
          ),
          const Divider(),

          _sectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.teal),
            title: const Text('Change Password'),
            subtitle: const Text('Send a password reset email'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _sendPasswordReset(),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('Logout Account'),
            subtitle: const Text('Sign out from current session safely'),
            onTap: () async {
              await _fbService.clearSession();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
          const Divider(),

          _sectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.teal),
            title: const Text('About This App'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent, color: Colors.teal),
            title: const Text('Contact Support'),
            subtitle: const Text('support@xmum-marketplace.com'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Opening email client to: support@xmum-marketplace.com',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_outline, color: Colors.teal),
            title: const Text('Rate This App'),
            subtitle: const Text('Enjoying the app? Leave us a review!'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your support!')),
              );
            },
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Version 1.0.0 — XMUM Campus Marketplace',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Chinese', 'Bahasa Melayu'].map((lang) {
            return ListTile(
              title: Text(lang),
              trailing: _selectedLanguage == lang
                  ? const Icon(Icons.check, color: Colors.teal)
                  : null,
              onTap: () {
                setState(() => _selectedLanguage = lang);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language set to $lang')),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _sendPasswordReset() async {
    final email = _fbService.currentUserEmail;
    if (email == null) return;
    try {
      await _fbService.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.store, color: Colors.teal),
            const SizedBox(width: 8),
            const Text('XMUM Marketplace'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text(
              'A campus second-hand trading platform for XMUM students to buy, sell, and exchange pre-owned items safely within the campus community.',
            ),
            SizedBox(height: 8),
            Text(
              'Built with Flutter & Firebase.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              'SWE311 Assignment 2 — 2026',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }
}
