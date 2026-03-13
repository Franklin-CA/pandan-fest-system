import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pandan_fest/constant/colors.dart';
import '../admin/admin_dashboard.dart';
import '../judge/judge_scoring_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String?> getUserRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return doc.data()?['role'];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Initial wait while loading auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final user = snapshot.data;

        // 2. User is not logged in (or just logged out) -> Show LoginScreen
        if (user == null) {
          return const LoginScreen();
        }

        // 3. User is logged in -> Fetch their role
        return FutureBuilder<String?>(
          future: getUserRole(user.uid),
          builder: (context, roleSnapshot) {
           if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            final role = roleSnapshot.data;

            if (role == "admin") {
              return const AdminDashboard();
            }

            if (role == "judge") {
              return const JudgeScoringScreen();
            }

            return const Scaffold(
              body: Center(child: Text("Unauthorized user / No role found")),
            );
          },
        );
      },
    );
  }
}
