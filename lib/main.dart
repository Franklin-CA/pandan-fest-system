import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/auth/auth_gate.dart';
import 'package:pandan_fest/firebase_options.dart';
import 'package:pandan_fest/judge/street_dance_scoring_screen.dart';
import 'package:pandan_fest/judge/focal_presentation_scoring_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pandan Fest',

      // ── Initial route ──        
      initialRoute: '/',

      // ── Named routes ──
      routes: {
        '/': (context) => const AuthGate(),

        // AuthGate routes judges here based on their category.
        // Both screens identify the judge via FirebaseAuth.instance.currentUser.
        '/judge/streetdance': (context) => const StreetDanceScoringScreen(),
        '/judge/focal': (context) => const FocalPresentationScoringScreen(),
      },

      // ── Fallback for unknown routes ──
      onUnknownRoute: (settings) =>
          MaterialPageRoute(builder: (_) => const _NotFoundScreen()),
    );
  }
}

// ================= 404 SCREEN =================

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Color(0xFFB71C1C),
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The route you accessed does not exist.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Go to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
