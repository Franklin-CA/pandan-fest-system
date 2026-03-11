import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';
import 'package:pandan_fest/models/app_models.dart';

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
    _tab = TabController(length: 4, vsync: this);
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
        const SizedBox(height: 16),
        if (_resultsFinalized) _buildFinalizedBanner(),
        if (_resultsFinalized) const SizedBox(height: 14),
        _buildSummaryRow(),
        const SizedBox(height: 18),
        _buildTabBar(),
        const SizedBox(height: 16),
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
        Column(
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
            const SizedBox(height: 6),
            Text(
              'Competition Results',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'View rankings, review judge scores, apply deductions, and export final results',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.silverRank,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (!_resultsFinalized)
          Tooltip(
            message: 'Lock all scores and mark the competition complete',
            child: OutlinedButton.icon(
              onPressed: _finalizeResults,
              icon: const Icon(Icons.lock_rounded, size: 16),
              label: Text(
                'Finalize Results',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: AppColors.accentGreen,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Text(
                  'Results Finalized',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGreen,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _isExporting ? null : () => _tab.animateTo(3),
          icon: _isExporting
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.download_rounded, size: 17),
          label: Text(
            _isExporting ? 'Exporting…' : 'Export Results',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentGreen.withOpacity(0.12),
            AppColors.accentGreen.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.accentGreen,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Results are finalized',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGreen,
                  ),
                ),
                Text(
                  'All judging panels are locked. You may still view, review, and export the results below.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.accentGreen.withOpacity(0.8),
                  ),
                ),
              ],
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
        const SizedBox(width: 12),
        _SummaryCard(
          icon: Icons.gavel_rounded,
          label: 'Score Sheets',
          value: '$submitted / $total',
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _SummaryCard(
          icon: Icons.rule_folder_rounded,
          label: 'Scoring Criteria',
          value: '${staticCriteria.length}',
          color: const Color(0xFF007AFF),
        ),
        const SizedBox(width: 12),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9EF),
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
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard_rounded, size: 15),
                SizedBox(width: 6),
                Text('Live Rankings'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_rounded, size: 15),
                SizedBox(width: 6),
                Text('Judge Breakdown'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.remove_circle_outline_rounded, size: 15),
                SizedBox(width: 6),
                Text('Deductions'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_rounded, size: 15),
                SizedBox(width: 6),
                Text('Export'),
              ],
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: smallValue ? 13 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
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
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.leaderboard_rounded,
                size: 32,
                color: Color(0xFFAEAEB2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No scores yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6C6C70),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rankings will appear here once judges begin submitting scores.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFFAEAEB2),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Podium top 3
        if (rankings.length >= 3) ...[
          _PodiumRow(rankings: rankings.take(3).toList()),
          const SizedBox(height: 20),
          Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),
        ],
        // Full list
        Expanded(
          child: ListView.separated(
            itemCount: rankings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _RankingRow(entry: rankings[i]),
          ),
        ),
      ],
    );
  }
}

// ── Podium ─────────────────────────────────────────────────────

class _PodiumRow extends StatelessWidget {
  final List<RankingEntry> rankings;
  const _PodiumRow({required this.rankings});

  @override
  Widget build(BuildContext context) {
    // Order: 2nd, 1st, 3rd
    final order = [rankings[1], rankings[0], rankings[2]];
    final heights = [120.0, 150.0, 100.0];
    final colors = [
      AppColors.silverRank,
      AppColors.goldRank,
      AppColors.bronzeRank,
    ];

    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final entry = order[i];
          final h = heights[i];
          final c = colors[i];
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  entry.groupName.split(' ').first,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.averageScore.toStringAsFixed(2),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: c,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: h,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.15),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    border: Border.all(color: c.withOpacity(0.4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_rounded, color: c, size: 28),
                      const SizedBox(height: 4),
                      Text(
                        entry.rank == 1
                            ? '1st'
                            : entry.rank == 2
                            ? '2nd'
                            : '3rd',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
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
        }),
      ),
    );
  }
}

// ── Full ranking row ────────────────────────────────────────────

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: entry.rank <= 3 ? _rankColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.rank <= 3
              ? _rankColor.withOpacity(0.2)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _rankColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: entry.rank <= 3
                  ? Icon(
                      Icons.emoji_events_rounded,
                      color: _rankColor,
                      size: 17,
                    )
                  : Text(
                      '${entry.rank}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _rankColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.groupName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  entry.barangay,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
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
                entry.averageScore.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _rankColor,
                ),
              ),
              SizedBox(
                width: 90,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (entry.averageScore / 100).clamp(0.0, 1.0),
                    minHeight: 5,
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
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Shows each judge\'s individual score for every group. Tap a group to expand.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.silverRank,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            itemCount: widget.groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? AppColors.secondary.withOpacity(0.4)
              : AppColors.divider,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(isExpanded ? 0.12 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${group.performanceOrder}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          group.barangay,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
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
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '$submittedCount of ${scores.length} judge${scores.length != 1 ? 's' : ''} scored',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.silverRank,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.silverRank,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded scores
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      ),
                      border: const Border(
                        top: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: scores.isEmpty
                        ? Text(
                            'No scores recorded for this group.',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: AppColors.silverRank,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Criteria header
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 130),
                                    ...criteria.map(
                                      (c) => Expanded(
                                        child: Text(
                                          c.name,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.silverRank,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 80),
                                  ],
                                ),
                              ),
                              ...scores.map((js) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 130,
                                        child: Text(
                                          js.judgeName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.5,
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
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: score != null
                                                    ? AppColors.primary
                                                          .withOpacity(0.08)
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                score != null
                                                    ? score.toStringAsFixed(1)
                                                    : '—',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
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
                                        width: 80,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                                fontSize: 12.5,
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
        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Deductions',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                    Text(
                      'Enter penalty points for rule violations (e.g. costume violations, overtime). '
                      'Deductions are subtracted from the group\'s final averaged score.',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppColors.warning.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: widget.groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasDeduction ? AppColors.danger.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(13),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${widget.group.performanceOrder}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _reasonCtrl,
                  onChanged: (_) => _update(),
                  style: GoogleFonts.poppins(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Reason for deduction (optional)',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.silverRank,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
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
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                'Deduction',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.silverRank,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: widget.controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _update(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasDeduction
                        ? AppColors.danger
                        : AppColors.silverRank,
                  ),
                  decoration: InputDecoration(
                    suffixText: 'pts',
                    suffixStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.silverRank,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: hasDeduction
                        ? AppColors.danger.withOpacity(0.07)
                        : AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
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
          if (!isFinalized)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Results have not been finalized yet. '
                      'You can still export a draft, but scores may still change. '
                      'Use "Finalize Results" in the header to lock everything first.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Text(
            'Export Format',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how you want the results exported.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppColors.silverRank,
            ),
          ),
          const SizedBox(height: 16),

          _ExportOption(
            icon: Icons.table_chart_rounded,
            color: AppColors.accentGreen,
            title: 'Excel Spreadsheet (.xlsx)',
            description:
                'Full score breakdown with per-judge rows, criteria columns, and final rankings. Best for official records.',
            buttonLabel: 'Export as Excel',
            isExporting: isExporting,
            onTap: () => onExport('Excel (.xlsx)'),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          _ExportOption(
            icon: Icons.data_object_rounded,
            color: const Color(0xFF007AFF),
            title: 'JSON Data File (.json)',
            description:
                'Raw structured data for developers or for importing into other systems.',
            buttonLabel: 'Export as JSON',
            isExporting: isExporting,
            onTap: () => onExport('JSON (.json)'),
          ),
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.silverRank,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: isExporting ? null : onTap,
            icon: isExporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.download_rounded, size: 15),
            label: Text(
              buttonLabel,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
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
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppColors.silverRank,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.silverRank,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontSize: 14),
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
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
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
