import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pandan_fest/constant/colors.dart';
import '../admin/admin_dashboard.dart';
import '../judge/street_dance_scoring_screen.dart';
import '../judge/focal_presentation_scoring_screen.dart';
import '../judge/festival_queen_scoring_screen.dart';
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

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

            if (role == 'admin') {
              return const AdminDashboard();
            }

            if (role == 'judge') {
              // Now using dynamic JudgeRouter based on live session
              return const JudgeRouter();
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

class JudgeRouter extends StatelessWidget {
  const JudgeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('live_sessions').doc('current').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        
        final data = snapshot.data?.data();
        final timerPreset = data?['timerPreset'] as String? ?? 'streetDance';
        
        if (timerPreset == 'focalPresentation') {
          return const FocalPresentationScoringScreen();
        } else if (timerPreset == 'festivalQueen') {
          return const FestivalQueenScoringScreen();
        }
        
        return const StreetDanceScoringScreen();
      },
    );
  }
}
