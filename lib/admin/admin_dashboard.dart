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

  final List<String> menuItems = [
    "Dashboard",
    "Dance Groups",
    "Judges",
    "Criteria Setup",
    "Live Control",
    "Results",
    "Settings",
  ];

  final List<IconData> menuIcons = [
    Icons.dashboard_rounded,
    Icons.groups_rounded,
    Icons.gavel_rounded,
    Icons.rule_folder_rounded,
    Icons.live_tv_rounded,
    Icons.emoji_events_rounded,
    Icons.settings_rounded,
  ];

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
              duration: const Duration(milliseconds: 300),
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

  // ================= APP BAR =================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 2,
      titleSpacing: 20,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset("assets/images/PandanFestLogo.png", height: 40),
          ),
          const SizedBox(width: 15),
          Text(
            "PandanFest 2026",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "| Street Dance Admin",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
          ),
          onPressed: () {},
        ),
        Row(
          children: [
            Icon(Icons.circle, color: AppColors.live, size: 10),
            SizedBox(width: 6),
            Text("LIVE", style: GoogleFonts.poppins(color: Colors.white)),
          ],
        ),
        const SizedBox(width: 20),
        const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.admin_panel_settings, color: Colors.black),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  // ================= SIDEBAR =================

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            menuIcons[index],
                            color: isSelected
                                ? AppColors.secondary
                                : Colors.white70,
                          ),
                          const SizedBox(width: 15),
                          Text(
                            menuItems[index],
                            style: GoogleFonts.poppins(
                              color: isSelected
                                  ? AppColors.secondary
                                  : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= CONTENT SWITCH =================

  Widget _buildContent() {
    switch (selectedIndex) {
      case 0:
        return _dashboardHome();
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
        return _dashboardHome();
    }
  }

  // ================= DASHBOARD HOME =================

  Widget _dashboardHome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Dashboard Overview",
          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1400
                  ? 4
                  : constraints.maxWidth > 900
                  ? 3
                  : 2;

              return GridView.builder(
                itemCount: dashboardCards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 25,
                  mainAxisSpacing: 25,
                  childAspectRatio: 1.6,
                ),
                itemBuilder: (context, index) {
                  return DashboardCard(
                    title: dashboardCards[index]["title"],
                    value: dashboardCards[index]["value"],
                    icon: dashboardCards[index]["icon"],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  final List<Map<String, dynamic>> dashboardCards = [
    {
      "title": "Total Dance Groups",
      "value": "12",
      "icon": Icons.groups_rounded,
    },
    {"title": "Active Judges", "value": "5", "icon": Icons.gavel_rounded},
    {"title": "Current Phase", "value": "Finals", "icon": Icons.flag_rounded},
    {"title": "Live Status", "value": "Running", "icon": Icons.live_tv_rounded},
  ];
}

// ================= DASHBOARD CARD =================

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 15,
            color: AppColors.shadow,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 36, color: AppColors.secondary),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
