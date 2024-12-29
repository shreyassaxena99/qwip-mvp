import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';

class MainWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Check if the authentication state is still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // If no user is logged in, show the login screen
        if (!snapshot.hasData) {
          return AuthScreen();
        }

        // If the user is logged in, show the home screen
        // Extract user ID and pass it to the HomeScreen
        final userId = snapshot.data!.uid;
        return HomeScreen(
          userId: userId,
        );
      },
    );
  }
}
