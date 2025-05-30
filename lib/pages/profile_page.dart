// lib/pages/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _fcmToken;
  String? _apnsToken;
  bool _isLoading = true;
  String _statusMessage = 'Loading token...';

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading token...';
    });

    try {
      if (Platform.isIOS) {
        setState(() {
          _statusMessage = 'Checking APNS token...';
        });

        // Get APNS token first
        _apnsToken = await FirebaseMessaging.instance.getAPNSToken();

        if (_apnsToken == null) {
          setState(() {
            _statusMessage = 'Waiting for APNS token...';
          });

          // Wait for APNS token
          for (int i = 0; i < 10; i++) {
            await Future.delayed(const Duration(seconds: 1));
            setState(() {
              _statusMessage = 'Waiting for APNS token... (${i+1}/10)';
            });

            _apnsToken = await FirebaseMessaging.instance.getAPNSToken();
            if (_apnsToken != null) break;
          }
        }

        if (_apnsToken == null) {
          setState(() {
            _isLoading = false;
            _statusMessage = 'APNS token not available. Notifications may not work.';
          });
          return;
        }
      }

      // Now get FCM token
      _fcmToken = await FirebaseMessaging.instance.getToken();

      setState(() {
        _isLoading = false;
        if (_fcmToken != null) {
          _statusMessage = 'Token obtained successfully';
        } else {
          _statusMessage = 'Failed to get token';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
      print('❌ Token error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('Email: ${user?.email ?? 'Not signed in'}'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('Sign Out'),
          ),
          const SizedBox(height: 32),
          const Text(
            'Device Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FCM Token (for notifications):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _isLoading
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(_statusMessage),
                    ],
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _fcmToken != null ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (Platform.isIOS && _apnsToken != null) ...[
                        const Text(
                          'APNS Token:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _apnsToken!,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_fcmToken != null) ...[
                        const Text(
                          'FCM Token:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _fcmToken!,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy FCM Token'),
                            onPressed: _fcmToken == null
                                ? null
                                : () {
                              Clipboard.setData(
                                  ClipboardData(text: _fcmToken!));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Token copied to clipboard')),
                              );
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            onPressed: _loadToken,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}