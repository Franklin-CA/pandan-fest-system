import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/firebase_options.dart';
import 'package:pandan_fest/admin/admin_dashboard.dart';
import 'package:pandan_fest/constant/colors.dart';

class JudgeScoringScreen extends StatelessWidget {
  const JudgeScoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.primary.withOpacity(0.1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar placeholder
              Container(
                height: 80,
                color: AppColors.primary,
                child: Center(
                  child: Text(
                    'JudgeScoringScreen',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gavel_rounded, size: 64, color: Colors.grey),
                      const SizedBox(height: 24),
                      Text(
                        'Judge Scoring Screen',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Scoring implementation coming soon...',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Dashboard'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        '/': (context) => const AdminDashboard(),
        '/judge': (context) => const JudgeScoringScreen(),
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
            const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFB71C1C)),
            const SizedBox(height: 16),
            const Text(
              "Page Not Found",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              "The route you accessed does not exist.",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              "Available routes: /judge/streetdance  ·  /judge/focal",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              icon: const Icon(Icons.home_rounded),
              label: const Text("Go to Dashboard"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
