import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/admin/dance_group_management.dart';
import 'package:pandan_fest/admin/judges.dart';
import 'package:pandan_fest/admin/live_control_panel.dart';
import 'package:pandan_fest/admin/results_screen.dart';
import 'package:pandan_fest/admin/scoring_criteria_config.dart';
import 'package:pandan_fest/admin/settings.dart';
import 'package:pandan_fest/constant/colors.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  // ── Menu config ─────────────────────────────────────────────
  static const _menuItems = [
    'Dashboard',
    'Dance Groups',
    'Judges',
    'Criteria Setup',
    'Live Control',
    'Results',
    'Settings',
  ];

  static const _menuIcons = [
    Icons.dashboard_rounded,
    Icons.groups_rounded,
    Icons.gavel_rounded,
    Icons.rule_folder_rounded,
    Icons.live_tv_rounded,
    Icons.emoji_events_rounded,
    Icons.settings_rounded,
  ];

  /// Short helper text shown under each sidebar item
  static const _menuSubtitles = [
    'Overview & stats',
    'Manage performers',
    'Scoring panel',
    'Set up weights',
    'Push & monitor',
    'Rankings & export',
    'System controls',
  ];

  // ── Helpers ──────────────────────────────────────────────────
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Padding(
                key: ValueKey(selectedIndex),
                padding: const EdgeInsets.all(30),
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 2,
      titleSpacing: 20,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/images/PandanFestLogo.png', height: 40),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PandanFest 2026',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              Text(
                'Mapandan, Pangasinan · Street Dance Admin',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Live indicator
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.live.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.live.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              _PulsingDot(color: AppColors.live),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        // Notifications
        Tooltip(
          message: 'Notifications',
          child: IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
        ),
        // Admin avatar
        Tooltip(
          message: 'Admin Account',
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 16,
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.black87,
                size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // ── Sidebar ──────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Welcome strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Administrator',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Tooltip(
                    message: _menuSubtitles[index],
                    preferBelow: false,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => selectedIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 11,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondary.withOpacity(0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.secondary.withOpacity(0.3),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _menuIcons[index],
                              color: isSelected
                                  ? AppColors.secondary
                                  : Colors.white54,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _menuItems[index],
                                    style: GoogleFonts.poppins(
                                      color: isSelected
                                          ? AppColors.secondary
                                          : Colors.white70,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isSelected)
                                    Text(
                                      _menuSubtitles[index],
                                      style: GoogleFonts.poppins(
                                        color: AppColors.secondary.withOpacity(
                                          0.7,
                                        ),
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom version tag
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'PandanFest Admin v1.0',
              style: GoogleFonts.poppins(color: Colors.white24, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ── Content Router ───────────────────────────────────────────
  Widget _buildContent() {
    switch (selectedIndex) {
      case 0:
        return _buildDashboardHome();
      case 1:
        return const DanceGroupManagement();
      case 2:
        return const JudgesManagementScreen();
      case 3:
        return const ScoringCriteriaConfiguration();
      case 4:
        return const LiveControlPanel();
      case 5:
        return const ResultsScreen();
      case 6:
        return const SettingsControlsScreen();
      default:
        return _buildDashboardHome();
    }
  }

  // ── Dashboard Home ───────────────────────────────────────────
  Widget _buildDashboardHome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Overview',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'PandanFest 2026 · Street Dance Competition · Mapandan, Pangasinan',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Quick navigation buttons
            _QuickNavButton(
              icon: Icons.live_tv_rounded,
              label: 'Go Live',
              color: AppColors.live,
              onTap: () => setState(() => selectedIndex = 4),
            ),
            const SizedBox(width: 10),
            _QuickNavButton(
              icon: Icons.emoji_events_rounded,
              label: 'Results',
              color: AppColors.goldRank,
              onTap: () => setState(() => selectedIndex = 5),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Welcome banner
        _WelcomeBanner(onDismiss: () {}),
        const SizedBox(height: 24),

        // Stat cards
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 1400
                  ? 4
                  : constraints.maxWidth > 900
                  ? 3
                  : 2;
              return GridView.builder(
                itemCount: _dashboardCards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.7,
                ),
                itemBuilder: (context, index) {
                  final card = _dashboardCards[index];
                  return DashboardCard(
                    title: card['title'] as String,
                    value: card['value'] as String,
                    subtitle: card['subtitle'] as String,
                    icon: card['icon'] as IconData,
                    color: card['color'] as Color,
                    onTap: () =>
                        setState(() => selectedIndex = card['navIndex'] as int),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  final List<Map<String, dynamic>> _dashboardCards = [
    {
      'title': 'Dance Groups',
      'value': '12',
      'subtitle': 'Registered for Finals',
      'icon': Icons.groups_rounded,
      'color': AppColors.secondary,
      'navIndex': 1,
    },
    {
      'title': 'Active Judges',
      'value': '5',
      'subtitle': '2 online right now',
      'icon': Icons.gavel_rounded,
      'color': Color(0xFF007AFF),
      'navIndex': 2,
    },
    {
      'title': 'Current Phase',
      'value': 'Finals',
      'subtitle': 'Tap to manage criteria',
      'icon': Icons.flag_rounded,
      'color': Color(0xFFAF52DE),
      'navIndex': 3,
    },
    {
      'title': 'Live Status',
      'value': 'Running',
      'subtitle': 'Scoring in progress',
      'icon': Icons.live_tv_rounded,
      'color': AppColors.live,
      'navIndex': 4,
    },
  ];
}

// ── Dashboard Card ────────────────────────────────────────────

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.color = AppColors.secondary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.12)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 14,
              color: AppColors.shadow,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Colors.grey[400],
                  ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Welcome Banner ────────────────────────────────────────────

class _WelcomeBanner extends StatefulWidget {
  final VoidCallback onDismiss;
  const _WelcomeBanner({required this.onDismiss});

  @override
  State<_WelcomeBanner> createState() => _WelcomeBannerState();
}

class _WelcomeBannerState extends State<_WelcomeBanner> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.85),
            AppColors.secondary.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🌿', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to PandanFest 2026 Admin Panel',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Use the sidebar to manage dance groups, assign judges, set scoring criteria, and control the live competition.',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white54),
            onPressed: () => setState(() => _visible = false),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}

// ── Quick Nav Button ─────────────────────────────────────────

class _QuickNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickNavButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: GoogleFonts.poppins(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Pulsing Dot ──────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(
        begin: 0.4,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
