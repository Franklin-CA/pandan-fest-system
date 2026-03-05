// ═══════════════════════════════════════════════════════════════════════════
//  PandanFest 2026 — Admin Dashboard
//
//  SETUP:
//    1. Place THIS file at:  lib/admin/admin_dashboard.dart
//    2. Place results file at: lib/results/results_screen.dart
//       (also provided in your download)
//    3. Hot-restart the app — the Results tab will now be fully live.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/admin/dance_group_management.dart';
import 'package:pandan_fest/admin/judges.dart';
import 'package:pandan_fest/admin/live_control_panel.dart';
import 'package:pandan_fest/admin/results_screen.dart';
import 'package:pandan_fest/admin/scoring_criteria_config.dart';
import 'package:pandan_fest/admin/settings.dart';
import 'package:pandan_fest/constant/colors.dart';
import 'package:pandan_fest/results/results_screen.dart';

// ─────────────────────────────────────────────────────────────────────────
//  ADMIN DASHBOARD SHELL
// ─────────────────────────────────────────────────────────────────────────

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _sel = 0;
  bool _collapsed = false;
  Timer? _ticker;
  int _tick = 0;

  static const _nav = [
    ('Dashboard',      Icons.dashboard_rounded),
    ('Dance Groups',   Icons.groups_rounded),
    ('Judges',         Icons.gavel_rounded),
    ('Criteria Setup', Icons.rule_folder_rounded),
    ('Live Control',   Icons.live_tv_rounded),
    ('Results',        Icons.emoji_events_rounded),
    ('Settings',       Icons.settings_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _tick++);
    });
  }
  @override void dispose() { _ticker?.cancel(); super.dispose(); }

  int get _penaltyBadge => kGroups.where((g) => g.penalties.isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildTopBar(),
        Expanded(child: Row(children: [
          _buildSidebar(),
          Expanded(child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOut,
            child: Padding(
              key: ValueKey(_sel),
              padding: const EdgeInsets.all(26),
              child: _page(),
            ),
          )),
        ])),
      ]),
    );
  }

  Widget _buildTopBar() {
    final leader = rankedGroups.first;
    return Container(
      height: 62, color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        IconButton(
          icon: Icon(_collapsed ? Icons.menu_open_rounded : Icons.menu_rounded, color: Colors.white),
          onPressed: () => setState(() => _collapsed = !_collapsed),
        ),
        const SizedBox(width: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset('assets/images/PandanFestLogo.png', height: 34),
        ),
        const SizedBox(width: 10),
        Text('PandanFest 2026', style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
        const SizedBox(width: 8),
        Text('| Street Dance Admin', style: GoogleFonts.poppins(
            fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w300)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            const Text('🥇', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(leader.name, style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(width: 5),
            Text(leader.finalScore.toStringAsFixed(2), style: GoogleFonts.poppins(
                color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(width: 14),
        const _LiveBadge(),
        const SizedBox(width: 8),
        IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () {}),
        const SizedBox(width: 4),
        const CircleAvatar(radius: 17, backgroundColor: Colors.white,
            child: Icon(Icons.admin_panel_settings, color: Colors.black87, size: 18)),
        const SizedBox(width: 10),
      ]),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 230),
      width: _collapsed ? 62 : 238,
      decoration: const BoxDecoration(
          color: AppColors.sidebarBackground,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
      child: Column(children: [
        const SizedBox(height: 10),
        Expanded(child: ListView.builder(
          itemCount: _nav.length,
          itemBuilder: (ctx, i) {
            final (label, icon) = _nav[i];
            final sel   = _sel == i;
            final badge = i == 5 && _penaltyBadge > 0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              child: Tooltip(
                message: _collapsed ? label : '',
                preferBelow: false,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _sel = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(
                        vertical: 13, horizontal: _collapsed ? 0 : 12),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.secondary.withOpacity(0.13) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: sel
                          ? const Border(left: BorderSide(color: AppColors.secondary, width: 3))
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: _collapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Stack(clipBehavior: Clip.none, children: [
                          Icon(icon, size: 20,
                              color: sel ? AppColors.secondary : Colors.white54),
                          if (badge) Positioned(top: -3, right: -3,
                              child: Container(width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                      color: AppColors.danger, shape: BoxShape.circle))),
                        ]),
                        if (!_collapsed) ...[
                          const SizedBox(width: 11),
                          Expanded(child: Text(label, style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: sel ? AppColors.secondary : Colors.white60,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.w400))),
                          if (badge) Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                                color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
                            child: Text('$_penaltyBadge', style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        )),
        if (!_collapsed) Padding(
          padding: const EdgeInsets.all(12),
          child: Text('v1.0.0 · PandanFest 2026', style: GoogleFonts.poppins(
              color: Colors.white24, fontSize: 10), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

<<<<<<< HEAD
  Widget _page() {
    switch (_sel) {
      case 0: return _DashboardHome(onNavigate: (i) => setState(() => _sel = i));
      case 5: return const ResultsScreen();
      default: return _PlaceholderPage(label: _nav[_sel].$1, icon: _nav[_sel].$2);
    }
  }
=======
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
>>>>>>> 72ae82dc392c77f7a5883f5c07b276ebcac04ec8
}

// ─────────────────────────────────────────────────────────────────────────
//  DASHBOARD HOME  (pulls live data from kGroups / rankedGroups)
// ─────────────────────────────────────────────────────────────────────────

class _DashboardHome extends StatelessWidget {
  final void Function(int) onNavigate;
  const _DashboardHome({required this.onNavigate});

  double get _avg  => kGroups.map((g) => g.finalScore).reduce((a, b) => a + b) / kGroups.length;
  double get _ded  => kGroups.fold(0.0, (s, g) => s + g.totalPenalty);
  int    get _penC => kGroups.where((g) => g.penalties.isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    final ranked = rankedGroups;
    final leader = ranked.first;

    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Page header
      Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dashboard Overview', style: GoogleFonts.poppins(
              fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text('PandanFest 2026 · Finals · Live',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
        ]),
        const Spacer(),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.emoji_events_rounded, size: 15),
          label: Text('View Full Results',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
          onPressed: () => onNavigate(5),
        ),
      ]),
      const SizedBox(height: 22),

      // ── Stat cards
      LayoutBuilder(builder: (ctx, bc) {
        final cards = [
          _SD('Total Groups',    '${kGroups.length}',               Icons.groups_rounded,        AppColors.primary,           '${kGroups.map((g) => g.category).toSet().length} categories'),
          _SD('Active Judges',   '${kJudges.length}',               Icons.gavel_rounded,         AppColors.accentGreen,       'All scores submitted'),
          _SD('Avg Final Score', _avg.toStringAsFixed(2),           Icons.bar_chart_rounded,     const Color(0xFF1565C0),      'Out of 50.00 pts'),
          _SD('Deductions',      '-${_ded.toStringAsFixed(1)}',     Icons.warning_amber_rounded, AppColors.danger,            '$_penC group(s) penalized'),
          _SD('Current Leader',  leader.finalScore.toStringAsFixed(2), Icons.emoji_events_rounded, AppColors.goldRank,         leader.name),
          _SD('Phase',           'Finals',                          Icons.flag_rounded,          const Color(0xFF6A1B9A),      'Live scoring active'),
        ];
        return SizedBox(
          height: 110,
          child: Row(
            children: cards.asMap().entries.map((e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: e.key == 0 ? 0 : 14),
                child: _StatCard(data: e.value),
              ),
            )).toList(),
          ),
        );
      }),
      const SizedBox(height: 22),

      // ── Two-column body
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: _buildLeaderboard(ranked)),
        const SizedBox(width: 18),
        Expanded(flex: 2, child: Column(children: [
          _buildPenalties(),
          const SizedBox(height: 18),
          _buildCriteriaAvg(),
        ])),
      ]),
      const SizedBox(height: 22),

      // ── Score distribution bar chart
      _buildDistribution(ranked),
      const SizedBox(height: 14),
    ]));
  }

  Widget _buildLeaderboard(List<DanceGroup> ranked) {
    return _DashCard(
      title: '🏆  Live Rankings',
      trailing: TextButton(
        onPressed: () => onNavigate(5),
        child: Text('See all', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 13)),
      ),
      child: Column(children: ranked.take(6).toList().asMap().entries.map((e) {
        final rank = e.key + 1;
        final g    = e.value;
        final rc   = {1: AppColors.goldRank, 2: AppColors.silverRank, 3: AppColors.bronzeRank}[rank]
            ?? Colors.grey[400]!;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: rank <= 3 ? rc.withOpacity(0.06) : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: rank <= 3 ? Border.all(color: rc.withOpacity(0.22)) : null,
          ),
          child: Row(children: [
            SizedBox(width: 30, child: rank <= 3
                ? Text(rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
                      style: const TextStyle(fontSize: 20))
                : Text('#\$rank', style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, color: Colors.grey[400], fontSize: 12))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(g.category, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
            ])),
            SizedBox(width: 140, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (g.totalPenalty > 0) ...[
                  Text('-${g.totalPenalty.toStringAsFixed(1)}',
                      style: GoogleFonts.poppins(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                ],
                Text(g.finalScore.toStringAsFixed(2), style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 13, color: rank <= 3 ? rc : Colors.black87)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: g.finalScore / 50.0,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(rank <= 3 ? rc : AppColors.primary),
                      minHeight: 5)),
            ])),
          ]),
        );
      }).toList()),
    );
  }

  Widget _buildPenalties() {
    final penalized = kGroups.where((g) => g.penalties.isNotEmpty).toList();
    return _DashCard(
      title: '⚠️  Penalties',
      trailing: TextButton(
        onPressed: () => onNavigate(5),
        child: Text('Manage', style: GoogleFonts.poppins(color: AppColors.danger, fontSize: 13)),
      ),
      child: penalized.isEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(14),
              child: Text('No penalties recorded',
                  style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13))))
          : Column(children: penalized.map((g) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withOpacity(0.14)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(g.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('-${g.totalPenalty.toStringAsFixed(1)} pts',
                        style: GoogleFonts.poppins(
                            color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ]),
                const SizedBox(height: 5),
                ...g.penalties.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(children: [
                    Icon(Icons.circle, size: 5, color: AppColors.danger.withOpacity(0.5)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(p.reason,
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]))),
                    Text('-${p.deduction.toStringAsFixed(1)}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600)),
                  ]),
                )),
              ]),
            )).toList()),
    );
  }

  Widget _buildCriteriaAvg() {
    final Map<String, double> sums = {};
    for (final g in kGroups) {
      g.avgCriteriaScores.forEach((k, v) { sums[k] = (sums[k] ?? 0) + v; });
    }
    final avgs = (sums.map((k, v) => MapEntry(k, v / kGroups.length)).entries.toList())
      ..sort((a, b) => b.value.compareTo(a.value));
    return _DashCard(
      title: '📊  Criteria Averages',
      child: Column(children: avgs.map((e) {
        final c = e.value >= 9.0 ? AppColors.success
            : e.value >= 8.5 ? AppColors.accentGreen : AppColors.warning;
        return Padding(padding: const EdgeInsets.only(bottom: 11),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(e.key,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]))),
              Text(e.value.toStringAsFixed(2),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: c)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(value: e.value / 10.0,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(c), minHeight: 7)),
          ]),
        );
      }).toList()),
    );
  }

  Widget _buildDistribution(List<DanceGroup> ranked) {
    final mx = ranked.first.finalScore, mn = ranked.last.finalScore, rng = mx - mn;
    return _DashCard(
      title: '📈  Score Distribution — All Groups',
      child: Column(children: ranked.asMap().entries.map((e) {
        final rank = e.key + 1;
        final g    = e.value;
        final rc   = {1: AppColors.goldRank, 2: AppColors.silverRank, 3: AppColors.bronzeRank}[rank]
            ?? AppColors.primary;
        final norm = rng > 0 ? 0.35 + 0.65 * (g.finalScore - mn) / rng : 1.0;
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
          SizedBox(width: 32, child: Text('#\$rank', style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: {1: AppColors.goldRank, 2: AppColors.silverRank, 3: AppColors.bronzeRank}[rank]
                  ?? Colors.grey[400]!, fontSize: 11))),
          SizedBox(width: 155, child: Text(g.name, style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 10),
          Expanded(child: Stack(children: [
            Container(height: 26, decoration: BoxDecoration(
                color: Colors.grey[100], borderRadius: BorderRadius.circular(6))),
            FractionallySizedBox(widthFactor: norm, child: Container(height: 26,
              decoration: BoxDecoration(color: rc.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: rc.withOpacity(0.38))))),
            Positioned.fill(child: Align(alignment: Alignment.centerLeft,
              child: Padding(padding: const EdgeInsets.only(left: 9), child: Row(children: [
                if (g.totalPenalty > 0) ...[
                  const Icon(Icons.warning_amber_rounded, size: 10, color: AppColors.danger),
                  const SizedBox(width: 3),
                ],
                Text(g.finalScore.toStringAsFixed(2), style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 11,
                    color: rank <= 3 ? rc : Colors.black87)),
                if (g.totalPenalty > 0) ...[
                  const SizedBox(width: 3),
                  Text('(-${g.totalPenalty.toStringAsFixed(1)})',
                      style: GoogleFonts.poppins(fontSize: 10, color: AppColors.danger)),
                ],
              ])),
            )),
          ])),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: AppColors.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7)),
            child: Text(g.category, style: GoogleFonts.poppins(
                fontSize: 9, color: AppColors.accentGreen, fontWeight: FontWeight.w500))),
        ]));
      }).toList()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  SHARED REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────

class _DashCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _DashCard({required this.title, required this.child, this.trailing});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        const Spacer(),
        if (trailing != null) trailing!,
      ]),
      const SizedBox(height: 13),
      child,
    ]),
  );
}

class _SD {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _SD(this.label, this.value, this.icon, this.color, this.sub);
}

class _StatCard extends StatelessWidget {
  final _SD data;
  const _StatCard({required this.data});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(color: data.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(data.icon, color: data.color, size: 17)),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data.value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        Text(data.label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54)),
        Text(data.sub, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400]), overflow: TextOverflow.ellipsis),
      ]),
    ]),
  );
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();
  @override State<_LiveBadge> createState() => _LiveBadgeState();
}
class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: AppColors.live.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.live.withOpacity(0.4))),
    child: Row(children: [
      FadeTransition(opacity: _a, child: Container(width: 7, height: 7,
          decoration: const BoxDecoration(color: AppColors.live, shape: BoxShape.circle))),
      const SizedBox(width: 5),
      Text('LIVE', style: GoogleFonts.poppins(
          color: AppColors.live, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
    ]),
  );
}

class _PlaceholderPage extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PlaceholderPage({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
      child: Icon(icon, size: 32, color: AppColors.primary)),
    const SizedBox(height: 16),
    Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 21, color: Colors.black87)),
    const SizedBox(height: 7),
    Text('This screen is coming soon.',
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
  ]));
}