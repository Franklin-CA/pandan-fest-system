import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pandan_fest/constant/colors.dart';
import '../admin/admin_dashboard.dart';
import '../judge/street_dance_scoring_screen.dart';
import '../judge/focal_presentation_scoring_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, String?>> getUserInfo(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data();
    return {
      'role': data?['role'] as String?,
      'category': data?['category'] as String?,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Wait while loading auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final user = snapshot.data;

        // 2. Not logged in → Login screen
        if (user == null) {
          return const LoginScreen();
        }

        // 3. Logged in → fetch role + category
        return FutureBuilder<Map<String, String?>>(
          future: getUserInfo(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            final role = roleSnapshot.data?['role'];
            final category = roleSnapshot.data?['category'];

            if (role == 'admin') {
              return const AdminDashboard();
            }

            if (role == 'judge') {
              // Route to the correct scoring screen based on category field
              // Firestore users doc should have:
              //   category: "streetDance" | "focalPresentation"
              if (category == 'focalPresentation') {
                return const FocalPresentationScoringScreen();
              }
              // Default judges (streetDance or no category set) go to Street Dance
              return const StreetDanceScoringScreen();
            }

            return const Scaffold(
              body: Center(child: Text('Unauthorized user / No role found')),
            );
          },
        );
      },
    );
  }
}
