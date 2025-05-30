import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'auth/auth_gate.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background handlers
  if (!Firebase.apps.isNotEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  print("Handling a background message: ${message.messageId}");
}

Future<String?> getFcmToken() async {
  try {
    // For iOS, we need to check and possibly wait for the APNS token
    if (Platform.isIOS) {
      print('iOS device detected, checking APNS token...');

      // Check if APNS token is available
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) {
        print('APNS token not available yet, waiting...');

        // Wait for up to 10 seconds for the APNS token
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(seconds: 1));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken != null) {
            print('✅ APNS token obtained: ${apnsToken.substring(0, min(10, apnsToken.length))}...');
            break;
          }
          print('Still waiting for APNS token... (${i+1}/10)');
        }

        // If still null after waiting
        if (apnsToken == null) {
          print('❌ Failed to get APNS token after waiting');
          return null;
        }
      } else {
        print('✅ APNS token already available: ${apnsToken.substring(0, min(10, apnsToken.length))}...');
      }
    }

    // Now get the FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      print('✅ FCM TOKEN: ${token.substring(0, min(10, token.length))}...');
    } else {
      print('❌ FCM token is null');
    }
    return token;
  } catch (e) {
    print('❌ Failed to get FCM token: $e');
    return null;
  }
}

// Helper to get the minimum of two integers
int min(int a, int b) => a < b ? a : b;

Future<void> main() async {
  print('Starting app initialization...');
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Checking if Firebase is already initialized...');
    // Only initialize Firebase if it hasn't already been initialized
    if (Firebase.apps.isEmpty) {
      print('Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');

      // Request iOS permissions first - IMPORTANT
      print('Requesting notification permissions...');
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('User notification settings: ${settings.authorizationStatus.toString()}');

      // Only after permissions, set up other notification handlers
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else {
      print('Firebase already initialized, skipping initialization');
    }
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  print('Running app...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Got a message whilst in the foreground!");
      print("Message data: ${message.data}");

      if (message.notification != null) {
        print("Message also contained a notification: ${message.notification!.title}");
      }
    });

    return MaterialApp(
      title: 'Shop App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}