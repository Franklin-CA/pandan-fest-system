import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';
import 'package:pandan_fest/models/app_models.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  AWARDS DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

enum _AwardTier { champion, firstRunnerUp, secondRunnerUp }

enum _SpecialAwardType {
  bestFocalPresentation,
  bestStreetDance,
  bestCostume,
  bestProductDesign,
  festivalQueen,
}

class _MainAward {
  final _AwardTier tier;
  final String cashPrize;
  const _MainAward({required this.tier, required this.cashPrize});

  String get label {
    switch (tier) {
      case _AwardTier.champion:
        return 'Champion';
      case _AwardTier.firstRunnerUp:
        return '1st Runner-Up';
      case _AwardTier.secondRunnerUp:
        return '2nd Runner-Up';
    }
  }

  Color get rankColor {
    switch (tier) {
      case _AwardTier.champion:
        return AppColors.goldRank;
      case _AwardTier.firstRunnerUp:
        return AppColors.silverRank;
      case _AwardTier.secondRunnerUp:
        return AppColors.bronzeRank;
    }
  }

  IconData get icon {
    switch (tier) {
      case _AwardTier.champion:
        return Icons.emoji_events_rounded;
      case _AwardTier.firstRunnerUp:
        return Icons.military_tech_rounded;
      case _AwardTier.secondRunnerUp:
        return Icons.workspace_premium_rounded;
    }
  }
}

class _SpecialAward {
  final _SpecialAwardType type;
  const _SpecialAward({required this.type});

  String get label {
    switch (type) {
      case _SpecialAwardType.bestFocalPresentation:
        return 'Best in Focal Presentation';
      case _SpecialAwardType.bestStreetDance:
        return 'Best in Street Dance';
      case _SpecialAwardType.bestCostume:
        return 'Best in Costume';
      case _SpecialAwardType.bestProductDesign:
        return 'Best in Product Design';
      case _SpecialAwardType.festivalQueen:
        return 'Festival Queen';
    }
  }

  IconData get icon {
    switch (type) {
      case _SpecialAwardType.bestFocalPresentation:
        return Icons.star_rounded;
      case _SpecialAwardType.bestStreetDance:
        return Icons.directions_run_rounded;
      case _SpecialAwardType.bestCostume:
        return Icons.dry_cleaning_rounded;
      case _SpecialAwardType.bestProductDesign:
        return Icons.design_services_rounded;
      case _SpecialAwardType.festivalQueen:
        return Icons.auto_awesome_rounded;
    }
  }

  Color get color {
    switch (type) {
      case _SpecialAwardType.bestFocalPresentation:
        return const Color(0xFF007AFF);
      case _SpecialAwardType.bestStreetDance:
        return const Color(0xFF34C759);
      case _SpecialAwardType.bestCostume:
        return const Color(0xFFFF2D55);
      case _SpecialAwardType.bestProductDesign:
        return const Color(0xFF5856D6);
      case _SpecialAwardType.festivalQueen:
        return AppColors.goldRank;
    }
  }
}

const _kMainAwards = [
  _MainAward(tier: _AwardTier.champion, cashPrize: '₱50,000'),
  _MainAward(tier: _AwardTier.firstRunnerUp, cashPrize: '₱30,000'),
  _MainAward(tier: _AwardTier.secondRunnerUp, cashPrize: '₱20,000'),
];

const _kSpecialAwards = [
  _SpecialAward(type: _SpecialAwardType.bestFocalPresentation),
  _SpecialAward(type: _SpecialAwardType.bestStreetDance),
  _SpecialAward(type: _SpecialAwardType.bestCostume),
  _SpecialAward(type: _SpecialAwardType.bestProductDesign),
  _SpecialAward(type: _SpecialAwardType.festivalQueen),
];

// ══════════════════════════════════════════════════════════════════════════════
//  RESULTS SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _isExporting = false;
  bool _resultsFinalized = false;

  List<RankingEntry> get _rankings =>
      computeRankings(resolvedJudgeScores, staticGroups, staticCriteria);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────
  Future<void> _finalizeResults() async {
    final ok = await _confirm(
      icon: Icons.lock_rounded,
      iconColor: AppColors.primary,
      title: 'Finalize Results?',
      body:
          'This will lock all scores and mark the competition as complete. '
          'Judges will no longer be able to submit or change scores. '
          'You can still export results after finalizing.',
      confirmLabel: 'Finalize Results',
      confirmColor: AppColors.primary,
    );
    if (ok) {
      setState(() => _resultsFinalized = true);
      _toast(
        'Results have been finalized. All scoring panels are now locked.',
        AppColors.primary,
      );
    }
  }

  Future<void> _exportResults(String format) async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    setState(() => _isExporting = false);
    _toast(
      'Results exported as $format. Check the output folder.',
      AppColors.accentGreen,
    );
  }

  Future<bool> _confirm({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
      ),
    );
    return r ?? false;
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        if (_resultsFinalized) ...[
          _buildFinalizedBanner(),
          const SizedBox(height: 12),
        ],
        _buildSummaryRow(),
        const SizedBox(height: 14),
        _buildTabBar(),
        const SizedBox(height: 14),
        Expanded(
          child: TabBarView(
            controller: _tab,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _LiveRankingsTab(rankings: _rankings),
              _JudgeBreakdownTab(
                groups: staticGroups,
                judgeScores: resolvedJudgeScores,
                criteria: staticCriteria,
              ),
              _DeductionsTab(groups: staticGroups),
              _ExportTab(
                isExporting: _isExporting,
                isFinalized: _resultsFinalized,
                onExport: _exportResults,
              ),
              _AwardsTab(
                groups: staticGroups,
                rankings: _rankings,
                isFinalized: _resultsFinalized,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title block — Expanded so buttons never overflow
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PANDANFEST 2026 — STREET DANCE',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Competition Results',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'View rankings, review judge scores, apply deductions, and export final results',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: AppColors.silverRank,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Finalize / Finalized indicator
        if (!_resultsFinalized)
          OutlinedButton.icon(
            onPressed: _finalizeResults,
            icon: const Icon(Icons.lock_rounded, size: 15),
            label: Text(
              'Finalize Results',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: AppColors.accentGreen,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Results Finalized',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGreen,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 8),
        // Export button
        ElevatedButton.icon(
          onPressed: _isExporting ? null : () => _tab.animateTo(3),
          icon: _isExporting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.download_rounded, size: 15),
          label: Text(
            _isExporting ? 'Exporting…' : 'Export Results',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ── Finalized Banner ────────────────────────────────────────────
  Widget _buildFinalizedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.accentGreen,
            size: 17,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Results are finalized — all judging panels are locked. '
              'You may still view, review, and export the results below.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.accentGreen.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Row ─────────────────────────────────────────────────
  Widget _buildSummaryRow() {
    final submitted = resolvedJudgeScores.values
        .expand((s) => s)
        .where((j) => j.isSubmitted)
        .length;
    final total = resolvedJudgeScores.values.expand((s) => s).length;
    final topGroup = _rankings.isNotEmpty ? _rankings.first.groupName : '—';

    return Row(
      children: [
        _SummaryCard(
          icon: Icons.groups_rounded,
          label: 'Competing Groups',
          value: '${staticGroups.length}',
          color: AppColors.secondary,
        ),
        const SizedBox(width: 10),
        _SummaryCard(
          icon: Icons.gavel_rounded,
          label: 'Score Sheets',
          value: '$submitted / $total',
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        _SummaryCard(
          icon: Icons.rule_folder_rounded,
          label: 'Scoring Criteria',
          value: '${staticCriteria.length}',
          color: const Color(0xFF007AFF),
        ),
        const SizedBox(width: 10),
        // Top group card — uses smallValue + 2-line text to avoid overflow
        _SummaryCard(
          icon: Icons.emoji_events_rounded,
          label: 'Current Top Group',
          value: topGroup,
          color: AppColors.goldRank,
          smallValue: true,
        ),
      ],
    );
  }

  // ── Tab Bar ─────────────────────────────────────────────────────
  Widget _buildTabBar() {
    // Shortened labels so 5 tabs fit comfortably at desktop width
    final tabs = <(IconData, String)>[
      (Icons.leaderboard_rounded, 'Rankings'),
      (Icons.people_alt_rounded, 'Breakdown'),
      (Icons.remove_circle_outline_rounded, 'Deductions'),
      (Icons.download_rounded, 'Export'),
      (Icons.emoji_events_rounded, 'Awards'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEF3),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.silverRank,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.28),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        // Remove default horizontal tab padding so tabs share space evenly
        labelPadding: EdgeInsets.zero,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        tabs: tabs
            .map(
              (t) => Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.$1, size: 14),
                    const SizedBox(width: 5),
                    Text(t.$2),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SUMMARY CARD
// ══════════════════════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final bool smallValue;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      // Long group names get smaller font + 2 lines
                      fontSize: smallValue ? 11.5 : 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.silverRank,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TAB 1 — LIVE RANKINGS
// ══════════════════════════════════════════════════════════════════════════════

class _LiveRankingsTab extends StatelessWidget {
  final List<RankingEntry> rankings;
  const _LiveRankingsTab({required this.rankings});

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.leaderboard_rounded,
                size: 30,
                color: Color(0xFFAEAEB2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No scores yet',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6C6C70),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rankings will appear here once judges begin submitting scores.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFFAEAEB2),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rankings.length >= 3) ...[
          _PodiumRow(rankings: rankings.take(3).toList()),
          const SizedBox(height: 14),
          Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),
        ],
        // Full list including top-3 (rank badge distinguishes them)
        Expanded(
          child: ListView.separated(
            itemCount: rankings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _RankingRow(entry: rankings[i]),
          ),
        ),
      ],
    );
  }
}

// ── Podium ─────────────────────────────────────────────────────

class _PodiumRow extends StatelessWidget {
  final List<RankingEntry> rankings; // index 0=1st, 1=2nd, 2=3rd
  const _PodiumRow({required this.rankings});

  @override
  Widget build(BuildContext context) {
    // Visual order on screen: 2nd | 1st | 3rd
    final display = [
      (
        entry: rankings[1],
        blockH: 92.0,
        color: AppColors.silverRank,
        label: '2nd',
      ),
      (
        entry: rankings[0],
        blockH: 122.0,
        color: AppColors.goldRank,
        label: '1st',
      ),
      (
        entry: rankings[2],
        blockH: 72.0,
        color: AppColors.bronzeRank,
        label: '3rd',
      ),
    ];

    return SizedBox(
      height: 185,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: display.map((d) {
          final c = d.color;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Full group name — wraps up to 2 lines, no clipping
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    d.entry.groupName,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d.entry.averageScore.toStringAsFixed(2),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: c,
                  ),
                ),
                const SizedBox(height: 4),
                // Podium block
                Container(
                  height: d.blockH,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.13),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    border: Border.all(color: c.withOpacity(0.35)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_rounded, color: c, size: 24),
                      const SizedBox(height: 3),
                      Text(
                        d.label,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: c,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Ranking Row ─────────────────────────────────────────────────

class _RankingRow extends StatelessWidget {
  final RankingEntry entry;
  const _RankingRow({required this.entry});

  Color get _rankColor {
    switch (entry.rank) {
      case 1:
        return AppColors.goldRank;
      case 2:
        return AppColors.silverRank;
      case 3:
        return AppColors.bronzeRank;
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: isTop3 ? _rankColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isTop3 ? _rankColor.withOpacity(0.2) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: _rankColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: isTop3
                  ? Icon(
                      Icons.emoji_events_rounded,
                      color: _rankColor,
                      size: 15,
                    )
                  : Text(
                      '${entry.rank}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _rankColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 11),
          // Group name + barangay
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.groupName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  entry.barangay,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.silverRank,
                  ),
                ),
              ],
            ),
          ),
          // Score + progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.averageScore.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _rankColor,
                ),
              ),
              SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (entry.averageScore / 100).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: _rankColor.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(_rankColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TAB 2 — JUDGE BREAKDOWN
// ══════════════════════════════════════════════════════════════════════════════

class _JudgeBreakdownTab extends StatefulWidget {
  final List<PerformingGroup> groups;
  final Map<String, List<JudgeScore>> judgeScores;
  final List<ActiveCriterion> criteria;

  const _JudgeBreakdownTab({
    required this.groups,
    required this.judgeScores,
    required this.criteria,
  });

  @override
  State<_JudgeBreakdownTab> createState() => _JudgeBreakdownTabState();
}

class _JudgeBreakdownTabState extends State<_JudgeBreakdownTab> {
  String? _expandedGroupId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoBanner(
          icon: Icons.info_outline_rounded,
          color: AppColors.secondary,
          text:
              "Shows each judge's individual score for every group. "
              "Tap a group to expand.",
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: widget.groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final g = widget.groups[i];
              final scores = widget.judgeScores[g.id] ?? [];
              final isExpanded = _expandedGroupId == g.id;
              return _BreakdownCard(
                group: g,
                scores: scores,
                criteria: widget.criteria,
                isExpanded: isExpanded,
                onToggle: () =>
                    setState(() => _expandedGroupId = isExpanded ? null : g.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final PerformingGroup group;
  final List<JudgeScore> scores;
  final List<ActiveCriterion> criteria;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _BreakdownCard({
    required this.group,
    required this.scores,
    required this.criteria,
    required this.isExpanded,
    required this.onToggle,
  });

  double get avgScore {
    final submitted = scores
        .where((j) => j.isSubmitted && j.scores.isNotEmpty)
        .toList();
    if (submitted.isEmpty) return 0;
    return submitted.fold(0.0, (s, j) => s + j.totalWeighted(staticCriteria)) /
        submitted.length;
  }

  int get submittedCount => scores.where((j) => j.isSubmitted).length;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isExpanded
              ? AppColors.secondary.withOpacity(0.4)
              : AppColors.divider,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(isExpanded ? 0.1 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 33,
                    height: 33,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        '${group.performanceOrder}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          group.barangay,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.silverRank,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        avgScore > 0 ? avgScore.toStringAsFixed(2) : '—',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '$submittedCount / ${scores.length} judged',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: AppColors.silverRank,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.silverRank,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(13),
                      ),
                      border: const Border(
                        top: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: scores.isEmpty
                        ? Text(
                            'No scores recorded for this group.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.silverRank,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 118),
                                    ...criteria.map(
                                      (c) => Expanded(
                                        child: Text(
                                          c.name,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.silverRank,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 68),
                                  ],
                                ),
                              ),
                              ...scores.map((js) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 118,
                                        child: Text(
                                          js.judgeName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      ...criteria.map((c) {
                                        final score = js.scores[c.id];
                                        return Expanded(
                                          child: Center(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: score != null
                                                    ? AppColors.primary
                                                          .withOpacity(0.08)
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: Text(
                                                score != null
                                                    ? score.toStringAsFixed(1)
                                                    : '—',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: score != null
                                                      ? AppColors.primary
                                                      : AppColors.silverRank,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                      SizedBox(
                                        width: 68,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                            ),
                                            child: Text(
                                              js.isSubmitted
                                                  ? js
                                                        .totalWeighted(
                                                          staticCriteria,
                                                        )
                                                        .toStringAsFixed(1)
                                                  : '—',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TAB 3 — DEDUCTIONS
// ══════════════════════════════════════════════════════════════════════════════

class _DeductionsTab extends StatefulWidget {
  final List<PerformingGroup> groups;
  const _DeductionsTab({required this.groups});

  @override
  State<_DeductionsTab> createState() => _DeductionsTabState();
}

class _DeductionsTabState extends State<_DeductionsTab> {
  final Map<String, double> _deductions = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _reasons = {};

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoBanner(
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
          title: 'About Deductions',
          text:
              'Enter penalty points for rule violations '
              '(e.g. costume violations, overtime). '
              'Deductions are subtracted from the final averaged score.',
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: widget.groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final g = widget.groups[i];
              _controllers.putIfAbsent(
                g.id,
                () => TextEditingController(
                  text: (_deductions[g.id] ?? 0.0).toStringAsFixed(1),
                ),
              );
              return _DeductionRow(
                group: g,
                deduction: _deductions[g.id] ?? 0.0,
                reason: _reasons[g.id] ?? '',
                controller: _controllers[g.id]!,
                onChanged: (val, reason) => setState(() {
                  _deductions[g.id] = val;
                  _reasons[g.id] = reason;
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeductionRow extends StatefulWidget {
  final PerformingGroup group;
  final double deduction;
  final String reason;
  final TextEditingController controller;
  final void Function(double, String) onChanged;

  const _DeductionRow({
    required this.group,
    required this.deduction,
    required this.reason,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_DeductionRow> createState() => _DeductionRowState();
}

class _DeductionRowState extends State<_DeductionRow> {
  late final TextEditingController _reasonCtrl;

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController(text: widget.reason);
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _update() {
    final val = double.tryParse(widget.controller.text) ?? 0.0;
    widget.onChanged(val.clamp(0, 100), _reasonCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final hasDeduction = widget.deduction > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: hasDeduction ? AppColors.danger.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDeduction
              ? AppColors.danger.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                '${widget.group.performanceOrder}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _reasonCtrl,
                  onChanged: (_) => _update(),
                  style: GoogleFonts.poppins(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Reason for deduction (optional)',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: AppColors.silverRank,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.secondary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                'Deduction',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: AppColors.silverRank,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 84,
                child: TextField(
                  controller: widget.controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _update(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: hasDeduction
                        ? AppColors.danger
                        : AppColors.silverRank,
                  ),
                  decoration: InputDecoration(
                    suffixText: 'pts',
                    suffixStyle: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.silverRank,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: hasDeduction
                        ? AppColors.danger.withOpacity(0.07)
                        : AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: hasDeduction
                            ? AppColors.danger.withOpacity(0.4)
                            : AppColors.divider,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: hasDeduction
                            ? AppColors.danger.withOpacity(0.4)
                            : AppColors.divider,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.danger,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TAB 4 — EXPORT
// ══════════════════════════════════════════════════════════════════════════════

class _ExportTab extends StatelessWidget {
  final bool isExporting;
  final bool isFinalized;
  final Future<void> Function(String) onExport;

  const _ExportTab({
    required this.isExporting,
    required this.isFinalized,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFinalized) ...[
            _InfoBanner(
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              text:
                  'Results have not been finalized yet. '
                  'You can still export a draft, but scores may still change. '
                  'Use "Finalize Results" in the header to lock everything first.',
            ),
            const SizedBox(height: 14),
          ],
          Text(
            'Export Format',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Choose how you want the results exported.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.silverRank,
            ),
          ),
          const SizedBox(height: 12),
          _ExportOption(
            icon: Icons.table_chart_rounded,
            color: AppColors.accentGreen,
            title: 'Excel Spreadsheet (.xlsx)',
            description:
                'Full score breakdown with per-judge rows, criteria columns, and final rankings.',
            buttonLabel: 'Export as Excel',
            isExporting: isExporting,
            onTap: () => onExport('Excel (.xlsx)'),
          ),
          const SizedBox(height: 9),
          _ExportOption(
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFFFF3B30),
            title: 'PDF Certificate / Report',
            description:
                'Formatted results document suitable for printing awards or sharing publicly.',
            buttonLabel: 'Export as PDF',
            isExporting: isExporting,
            onTap: () => onExport('PDF'),
          ),
          const SizedBox(height: 9),
          _ExportOption(
            icon: Icons.data_object_rounded,
            color: const Color(0xFF007AFF),
            title: 'JSON Data File (.json)',
            description:
                'Raw structured data for developers or importing into other systems.',
            buttonLabel: 'Export as JSON',
            isExporting: isExporting,
            onTap: () => onExport('JSON (.json)'),
          ),
          const SizedBox(height: 9),
          _ExportOption(
            icon: Icons.text_snippet_rounded,
            color: AppColors.silverRank,
            title: 'CSV Spreadsheet (.csv)',
            description:
                'Simple comma-separated values. Compatible with Google Sheets and any spreadsheet app.',
            buttonLabel: 'Export as CSV',
            isExporting: isExporting,
            onTap: () => onExport('CSV (.csv)'),
          ),
        ],
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, description, buttonLabel;
  final bool isExporting;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.isExporting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: AppColors.silverRank,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          ElevatedButton.icon(
            onPressed: isExporting ? null : onTap,
            icon: isExporting
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.download_rounded, size: 14),
            label: Text(
              buttonLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TAB 5 — AWARDS  (redesigned)
// ══════════════════════════════════════════════════════════════════════════════

class _AwardsTab extends StatefulWidget {
  final List<PerformingGroup> groups;
  final List<RankingEntry> rankings;
  final bool isFinalized;

  const _AwardsTab({
    required this.groups,
    required this.rankings,
    required this.isFinalized,
  });

  @override
  State<_AwardsTab> createState() => _AwardsTabState();
}

class _AwardsTabState extends State<_AwardsTab> {
  final Map<_AwardTier, String?> _mainRecipients = {
    _AwardTier.champion: null,
    _AwardTier.firstRunnerUp: null,
    _AwardTier.secondRunnerUp: null,
  };

  final Map<_SpecialAwardType, String?> _specialRecipients = {
    _SpecialAwardType.bestFocalPresentation: null,
    _SpecialAwardType.bestStreetDance: null,
    _SpecialAwardType.bestCostume: null,
    _SpecialAwardType.bestProductDesign: null,
    _SpecialAwardType.festivalQueen: null,
  };

  @override
  void initState() {
    super.initState();
    _autoFillFromRankings();
  }

  void _autoFillFromRankings() {
    if (widget.rankings.length >= 3) {
      _mainRecipients[_AwardTier.champion] = widget.rankings[0].groupId;
      _mainRecipients[_AwardTier.firstRunnerUp] = widget.rankings[1].groupId;
      _mainRecipients[_AwardTier.secondRunnerUp] = widget.rankings[2].groupId;
    }
  }

  PerformingGroup? _groupById(String? id) {
    if (id == null) return null;
    try {
      return widget.groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  int get _assignedCount =>
      _mainRecipients.values.where((v) => v != null).length +
      _specialRecipients.values.where((v) => v != null).length;

  int get _totalCount => _mainRecipients.length + _specialRecipients.length;

  @override
  Widget build(BuildContext context) {
    final assigned = _assignedCount;
    final total = _totalCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top status bar ──────────────────────────────────────────
          _AwardsProgressBar(assigned: assigned, total: total),
          const SizedBox(height: 20),

          // ── Edit-mode hint ──────────────────────────────────────────
          if (!widget.isFinalized) ...[
            _InfoBanner(
              icon: Icons.edit_note_rounded,
              color: AppColors.secondary,
              text:
                  'Select recipients for each award. '
                  'Top 3 placements are pre-filled from current rankings.',
            ),
            const SizedBox(height: 20),
          ],

          // ── MAIN AWARDS ─────────────────────────────────────────────
          _AwardsSectionLabel(
            label: 'MAIN AWARDS',
            icon: Icons.emoji_events_rounded,
            color: AppColors.goldRank,
          ),
          const SizedBox(height: 12),
          ..._kMainAwards.map(
            (award) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MainAwardCard(
                award: award,
                recipientGroupId: _mainRecipients[award.tier],
                groups: widget.groups,
                isFinalized: widget.isFinalized,
                onChanged: widget.isFinalized
                    ? null
                    : (id) => setState(() => _mainRecipients[award.tier] = id),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── SPECIAL AWARDS ──────────────────────────────────────────
          _AwardsSectionLabel(
            label: 'SPECIAL AWARDS',
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFF5856D6),
          ),
          const SizedBox(height: 12),
          // 1-column list — gives each card enough room for the dropdown
          ..._kSpecialAwards.map(
            (award) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SpecialAwardCard(
                award: award,
                recipientGroupId: _specialRecipients[award.type],
                groups: widget.groups,
                isFinalized: widget.isFinalized,
                onChanged: widget.isFinalized
                    ? null
                    : (id) =>
                          setState(() => _specialRecipients[award.type] = id),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── SUMMARY ─────────────────────────────────────────────────
          _AwardsSummaryCard(
            mainRecipients: _mainRecipients,
            specialRecipients: _specialRecipients,
            assignedCount: assigned,
            totalCount: total,
            groupById: _groupById,
          ),
        ],
      ),
    );
  }
}

// ── Progress bar at the top of the Awards tab ──────────────────

class _AwardsProgressBar extends StatelessWidget {
  final int assigned;
  final int total;
  const _AwardsProgressBar({required this.assigned, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : assigned / total;
    final done = assigned == total;
    final fgColor = done ? AppColors.accentGreen : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? AppColors.accentGreen.withOpacity(0.35)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: fgColor.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.emoji_events_outlined,
                color: fgColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                done ? 'All awards assigned!' : 'Award Assignment Progress',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: done ? AppColors.accentGreen : Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: fgColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$assigned / $total assigned',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: fgColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────

class _AwardsSectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _AwardsSectionLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: color.withOpacity(0.18))),
      ],
    );
  }
}

// ── Main Award Card (champion / runner-up) ─────────────────────

class _MainAwardCard extends StatelessWidget {
  final _MainAward award;
  final String? recipientGroupId;
  final List<PerformingGroup> groups;
  final bool isFinalized;
  final ValueChanged<String?>? onChanged;

  const _MainAwardCard({
    required this.award,
    required this.recipientGroupId,
    required this.groups,
    required this.isFinalized,
    this.onChanged,
  });

  PerformingGroup? get _recipient {
    if (recipientGroupId == null) return null;
    try {
      return groups.firstWhere((g) => g.id == recipientGroupId);
    } catch (_) {
      return null;
    }
  }

  // Champion gets a richer gradient-border treatment
  bool get _isChampion => award.tier == _AwardTier.champion;

  @override
  Widget build(BuildContext context) {
    final color = award.rankColor;
    final recipient = _recipient;
    final isAssigned = recipient != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAssigned ? color.withOpacity(0.4) : AppColors.divider,
          width: isAssigned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isAssigned ? 0.12 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Coloured header strip ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: color.withOpacity(_isChampion ? 0.1 : 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                // Trophy icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    award.icon,
                    color: color,
                    size: _isChampion ? 26 : 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Rank title + badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        award.label,
                        style: GoogleFonts.poppins(
                          fontSize: _isChampion ? 17 : 15,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _AwardBadge(
                            icon: Icons.workspace_premium_rounded,
                            label: 'Trophy',
                            color: color,
                          ),
                          const SizedBox(width: 6),
                          _AwardBadge(
                            icon: Icons.payments_rounded,
                            label: award.cashPrize,
                            color: AppColors.accentGreen,
                            filled: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Assignment status chip
                if (isAssigned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.silverRank.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Unassigned',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.silverRank,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Recipient area ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: isFinalized
                ? _RecipientDisplay(group: recipient, color: color)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECT RECIPIENT',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.silverRank,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _GroupDropdown(
                        groups: groups,
                        selectedId: recipientGroupId,
                        color: color,
                        onChanged: onChanged,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Special Award Card ─────────────────────────────────────────

class _SpecialAwardCard extends StatelessWidget {
  final _SpecialAward award;
  final String? recipientGroupId;
  final List<PerformingGroup> groups;
  final bool isFinalized;
  final ValueChanged<String?>? onChanged;

  const _SpecialAwardCard({
    required this.award,
    required this.recipientGroupId,
    required this.groups,
    required this.isFinalized,
    this.onChanged,
  });

  PerformingGroup? get _recipient {
    if (recipientGroupId == null) return null;
    try {
      return groups.firstWhere((g) => g.id == recipientGroupId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = award.color;
    final recipient = _recipient;
    final isAssigned = recipient != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAssigned ? color.withOpacity(0.35) : AppColors.divider,
          width: isAssigned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isAssigned ? 0.08 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar + icon
            Container(
              width: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(13),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(award.icon, color: color, size: 19),
                  ),
                ],
              ),
            ),
            // Right content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Award name
                    Text(
                      award.label,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Special Recognition',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: AppColors.silverRank,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Recipient / dropdown
                    if (isFinalized)
                      _SpecialRecipientChip(group: recipient, color: color)
                    else
                      _GroupDropdown(
                        groups: groups,
                        selectedId: recipientGroupId,
                        color: color,
                        onChanged: onChanged,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Special recipient chip (finalized view) ────────────────────

class _SpecialRecipientChip extends StatelessWidget {
  final PerformingGroup? group;
  final Color color;
  const _SpecialRecipientChip({required this.group, required this.color});

  @override
  Widget build(BuildContext context) {
    final g = group;
    if (g == null) {
      return Row(
        children: [
          Icon(
            Icons.do_not_disturb_alt_rounded,
            size: 14,
            color: AppColors.silverRank,
          ),
          const SizedBox(width: 6),
          Text(
            'Not assigned',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.silverRank,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              g.name,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '· ${g.barangay}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: color.withOpacity(0.7),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Awards badge pill ──────────────────────────────────────────

class _AwardBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  const _AwardBadge({
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.15) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Awards Summary Card ────────────────────────────────────────

class _AwardsSummaryCard extends StatelessWidget {
  final Map<_AwardTier, String?> mainRecipients;
  final Map<_SpecialAwardType, String?> specialRecipients;
  final int assignedCount;
  final int totalCount;
  final PerformingGroup? Function(String?) groupById;

  const _AwardsSummaryCard({
    required this.mainRecipients,
    required this.specialRecipients,
    required this.assignedCount,
    required this.totalCount,
    required this.groupById,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = assignedCount == totalCount;
    final accentColor = allDone ? AppColors.accentGreen : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allDone
              ? AppColors.accentGreen.withOpacity(0.35)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.list_alt_rounded, color: accentColor, size: 18),
                const SizedBox(width: 9),
                Text(
                  'Awards Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: allDone ? AppColors.accentGreen : Colors.black87,
                  ),
                ),
                const Spacer(),
                if (allDone)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: AppColors.accentGreen,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Complete',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main awards rows
                _SummaryGroupLabel(
                  label: 'MAIN AWARDS',
                  color: AppColors.goldRank,
                ),
                const SizedBox(height: 8),
                ..._kMainAwards.map(
                  (a) => _SummaryEntryRow(
                    icon: a.icon,
                    iconColor: a.rankColor,
                    awardLabel: a.label,
                    recipientName: groupById(mainRecipients[a.tier])?.name,
                    trailingLabel: mainRecipients[a.tier] != null
                        ? a.cashPrize
                        : null,
                    trailingColor: AppColors.accentGreen,
                  ),
                ),

                const SizedBox(height: 14),
                _SummaryGroupLabel(
                  label: 'SPECIAL AWARDS',
                  color: const Color(0xFF5856D6),
                ),
                const SizedBox(height: 8),
                ..._kSpecialAwards.map(
                  (a) => _SummaryEntryRow(
                    icon: a.icon,
                    iconColor: a.color,
                    awardLabel: a.label,
                    recipientName: groupById(specialRecipients[a.type])?.name,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGroupLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SummaryGroupLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: color.withOpacity(0.7),
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SummaryEntryRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String awardLabel;
  final String? recipientName;
  final String? trailingLabel;
  final Color? trailingColor;

  const _SummaryEntryRow({
    required this.icon,
    required this.iconColor,
    required this.awardLabel,
    required this.recipientName,
    this.trailingLabel,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasRecipient = recipientName != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              awardLabel,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                if (hasRecipient) ...[
                  Icon(Icons.check_circle_rounded, size: 13, color: iconColor),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: Text(
                    recipientName ?? '— Not assigned',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: hasRecipient
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: hasRecipient
                          ? Colors.black87
                          : AppColors.silverRank,
                      fontStyle: hasRecipient
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (trailingLabel != null && trailingColor != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: trailingColor!.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                trailingLabel!,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: trailingColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SHARED HELPER WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String? title;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: title != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: title != null ? 1 : 0),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: title != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      Text(
                        text,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: color.withOpacity(0.85),
                        ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: GoogleFonts.poppins(fontSize: 12, color: color),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 15),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.silverRank,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final double fontSize;
  final double letterSpacing;

  const _Pill({
    required this.label,
    required this.color,
    this.icon,
    this.fontSize = 11,
    this.letterSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: letterSpacing,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientDisplay extends StatelessWidget {
  final PerformingGroup? group;
  final Color color;

  const _RecipientDisplay({required this.group, required this.color});

  @override
  Widget build(BuildContext context) {
    final g = group; // local var for null promotion
    if (g == null) {
      return Text(
        'No recipient assigned',
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          color: AppColors.silverRank,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Row(
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              '${g.performanceOrder}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                g.name,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                g.barangay,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.silverRank,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.verified_rounded, color: color, size: 15),
      ],
    );
  }
}

class _GroupDropdown extends StatelessWidget {
  final List<PerformingGroup> groups;
  final String? selectedId;
  final Color color;
  final ValueChanged<String?>? onChanged;
  final bool compact;

  const _GroupDropdown({
    required this.groups,
    required this.selectedId,
    required this.color,
    this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fs = compact ? 11.5 : 13.0;
    final r = compact ? 8.0 : 10.0;
    return DropdownButtonFormField<String>(
      value: selectedId,
      hint: Text(
        compact ? 'Select…' : 'Select a group…',
        style: GoogleFonts.poppins(fontSize: fs, color: AppColors.silverRank),
      ),
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 12,
          vertical: compact ? 6 : 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide: BorderSide(color: color.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide: BorderSide(color: color.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
      ),
      style: GoogleFonts.poppins(
        fontSize: fs,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      dropdownColor: Colors.white,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: color,
        size: compact ? 16 : 20,
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            compact ? '—' : '— Not assigned —',
            style: GoogleFonts.poppins(
              fontSize: fs,
              color: AppColors.silverRank,
            ),
          ),
        ),
        ...groups.map(
          (g) => DropdownMenuItem<String>(
            value: g.id,
            child: Text(
              compact
                  ? '${g.performanceOrder}. ${g.name}'
                  : '${g.performanceOrder}. ${g.name} (${g.barangay})',
              style: GoogleFonts.poppins(fontSize: fs),
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CONFIRM DIALOG
// ══════════════════════════════════════════════════════════════════════════════

class _ConfirmDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, body, confirmLabel;
  final Color confirmColor;

  const _ConfirmDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 25),
              ),
              const SizedBox(height: 13),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppColors.silverRank,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.silverRank,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
