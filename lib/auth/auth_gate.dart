import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/home_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    print('AuthGate building...');
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print(
            'StreamBuilder state - ConnectionState: ${snapshot.connectionState}');
        print('StreamBuilder state - HasData: ${snapshot.hasData}');
        print('StreamBuilder state - HasError: ${snapshot.hasError}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Showing loading spinner');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          print('Auth error: ${snapshot.error}');
          return Scaffold(
            body: Center(child: Text('Auth error: ${snapshot.error}')),
          );
        }

        if (snapshot.hasData) {
          print('User is logged in, showing HomePage');
          return const HomePage();
        }

        print('No user, showing LoginPage');
        return const LoginPage();
      },
    );
  }
}
