import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';

// ═══════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════

class Penalty {
  final String reason;
  final double deduction;
  final String issuedBy;

  const Penalty({
    required this.reason,
    required this.deduction,
    required this.issuedBy,
  });
}

class JudgeCriteriaScore {
  final String judgeName;
  final Map<String, double> criteriaScores;

  const JudgeCriteriaScore({
    required this.judgeName,
    required this.criteriaScores,
  });

  double get total => criteriaScores.values.fold(0, (a, b) => a + b);
}

class DanceGroup {
  final String name;
  final String school;
  final String category;
  final List<JudgeCriteriaScore> judgeScores;
  final List<Penalty> penalties;

  const DanceGroup({
    required this.name,
    required this.school,
    required this.category,
    required this.judgeScores,
    required this.penalties,
  });

  Map<String, double> get avgCriteriaScores {
    final Map<String, double> totals = {};
    for (final j in judgeScores) {
      j.criteriaScores.forEach((k, v) {
        totals[k] = (totals[k] ?? 0) + v;
      });
    }
    return totals.map((k, v) => MapEntry(k, v / judgeScores.length));
  }

  double get rawTotal =>
      judgeScores.map((j) => j.total).reduce((a, b) => a + b) /
      judgeScores.length;

  double get totalPenalty =>
      penalties.fold(0.0, (sum, p) => sum + p.deduction);

  double get finalScore => (rawTotal - totalPenalty).clamp(0.0, 50.0);
}

// ═══════════════════════════════════════════════════════════════
//  MOCK DATA
// ═══════════════════════════════════════════════════════════════

const List<String> kCriteria = [
  'Choreography',
  'Technique',
  'Costume & Props',
  'Crowd Impact',
  'Street Culture',
];

const List<String> kJudges = [
  'Judge A',
  'Judge B',
  'Judge C',
  'Judge D',
  'Judge E',
];

final List<DanceGroup> kGroups = [
  DanceGroup(
    name: 'Sayaw Pilipinas',
    school: 'Brgy. Mabolo',
    category: 'Street Hip-Hop',
    judgeScores: [
      JudgeCriteriaScore(judgeName: 'Judge A', criteriaScores: {'Choreography': 9.5, 'Technique': 9.2, 'Costume & Props': 9.0, 'Crowd Impact': 9.8, 'Street Culture': 9.4}),
      JudgeCriteriaScore(judgeName: 'Judge B', criteriaScores: {'Choreography': 9.3, 'Technique': 9.0, 'Costume & Props': 8.6, 'Crowd Impact': 9.6, 'Street Culture': 9.2}),
      JudgeCriteriaScore(judgeName: 'Judge C', criteriaScores: {'Choreography': 9.6, 'Technique': 9.3, 'Costume & Props': 9.0, 'Crowd Impact': 9.9, 'Street Culture': 9.5}),
      JudgeCriteriaScore(judgeName: 'Judge D', criteriaScores: {'Choreography': 9.2, 'Technique': 8.9, 'Costume & Props': 8.6, 'Crowd Impact': 9.5, 'Street Culture': 9.1}),
      JudgeCriteriaScore(judgeName: 'Judge E', criteriaScores: {'Choreography': 9.4, 'Technique': 9.1, 'Costume & Props': 8.8, 'Crowd Impact': 9.7, 'Street Culture': 9.3}),
    ],
    penalties: [],
  ),
  DanceGroup(
    name: 'Wildfire Crew',
    school: 'Brgy. Lahug',
    category: 'Breaking',
    judgeScores: [
      JudgeCriteriaScore(judgeName: 'Judge A', criteriaScores: {'Choreography': 9.0, 'Technique': 9.6, 'Costume & Props': 8.5, 'Crowd Impact': 9.1, 'Street Culture': 9.3}),
      JudgeCriteriaScore(judgeName: 'Judge B', criteriaScores: {'Choreography': 9.1, 'Technique': 9.4, 'Costume & Props': 8.6, 'Crowd Impact': 9.0, 'Street Culture': 9.1}),
      JudgeCriteriaScore(judgeName: 'Judge C', criteriaScores: {'Choreography': 8.8, 'Technique': 9.7, 'Costume & Props': 8.4, 'Crowd Impact': 9.2, 'Street Culture': 9.4}),
      JudgeCriteriaScore(judgeName: 'Judge D', criteriaScores: {'Choreography': 9.0, 'Technique': 9.3, 'Costume & Props': 8.5, 'Crowd Impact': 8.9, 'Street Culture': 9.0}),
      JudgeCriteriaScore(judgeName: 'Judge E', criteriaScores: {'Choreography': 9.1, 'Technique': 9.5, 'Costume & Props': 8.5, 'Crowd Impact': 8.8, 'Street Culture': 9.2}),
    ],
    penalties: [
      Penalty(reason: 'Exceeded time limit by 30 seconds', deduction: 1.0, issuedBy: 'Head Judge'),
    ],
  ),
  DanceGroup(
    name: 'Kaleidoscope',
    school: 'Brgy. Apas',
    category: 'Waacking',
    judgeScores: [
      JudgeCriteriaScore(judgeName: 'Judge A', criteriaScores: {'Choreography': 8.8, 'Technique': 8.6, 'Costume & Props': 9.4, 'Crowd Impact': 8.7, 'Street Culture': 8.5}),
      JudgeCriteriaScore(judgeName: 'Judge B', criteriaScores: {'Choreography': 9.0, 'Technique': 8.8, 'Costume & Props': 9.2, 'Crowd Impact': 8.9, 'Street Culture': 8.7}),
      JudgeCriteriaScore(judgeName: 'Judge C', criteriaScores: {'Choreography': 8.9, 'Technique': 8.7, 'Costume & Props': 9.5, 'Crowd Impact': 8.8, 'Street Culture': 8.6}),
      JudgeCriteriaScore(judgeName: 'Judge D', criteriaScores: {'Choreography': 8.7, 'Technique': 8.5, 'Costume & Props': 9.1, 'Crowd Impact': 8.6, 'Street Culture': 8.4}),
      JudgeCriteriaScore(judgeName: 'Judge E', criteriaScores: {'Choreography': 9.1, 'Technique': 8.9, 'Costume & Props': 9.3, 'Crowd Impact': 9.0, 'Street Culture': 8.8}),
    ],
    penalties: [],
  ),
  DanceGroup(
    name: 'Force Five',
    school: 'Brgy. Talamban',
    category: 'Street Hip-Hop',
    judgeScores: [
      JudgeCriteriaScore(judgeName: 'Judge A', criteriaScores: {'Choreography': 8.4, 'Technique': 8.5, 'Costume & Props': 8.3, 'Crowd Impact': 8.6, 'Street Culture': 8.4}),
      JudgeCriteriaScore(judgeName: 'Judge B', criteriaScores: {'Choreography': 8.6, 'Technique': 8.7, 'Costume & Props': 8.5, 'Crowd Impact': 8.8, 'Street Culture': 8.6}),
      JudgeCriteriaScore(judgeName: 'Judge C', criteriaScores: {'Choreography': 8.5, 'Technique': 8.6, 'Costume & Props': 8.4, 'Crowd Impact': 8.7, 'Street Culture': 8.5}),
      JudgeCriteriaScore(judgeName: 'Judge D', criteriaScores: {'Choreography': 8.3, 'Technique': 8.4, 'Costume & Props': 8.2, 'Crowd Impact': 8.5, 'Street Culture': 8.3}),
      JudgeCriteriaScore(judgeName: 'Judge E', criteriaScores: {'Choreography': 8.7, 'Technique': 8.8, 'Costume & Props': 8.6, 'Crowd Impact': 8.9, 'Street Culture': 8.7}),
    ],
    penalties: [
      Penalty(reason: 'Prop violation - unauthorized item used', deduction: 0.5, issuedBy: 'Judge C'),
    ],
  ),
  DanceGroup(
    name: 'Aurora Dance Co.',
    school: 'Brgy. Pardo',
    category: 'Locking',
    judgeScores: [
      JudgeCriteriaScore(judgeName: 'Judge A', criteriaScores: {'Choreography': 8.1, 'Technique': 8.3, 'Costume & Props': 8.7, 'Crowd Impact': 8.2, 'Street Culture': 8.0}),
      JudgeCriteriaScore(judgeName: 'Judge B', criteriaScores: {'Choreography': 8.3, 'Technique': 8.5, 'Costume & Props': 8.9, 'Crowd Impact': 8.4, 'Street Culture': 8.2}),
      JudgeCriteriaScore(judgeName: 'Judge C', criteriaScores: {'Choreography': 8.2, 'Technique': 8.4, 'Costume & Props': 8.8, 'Crowd Impact': 8.3, 'Street Culture': 8.1}),
      JudgeCriteriaScore(judgeName: 'Judge D', criteriaScores: {'Choreography': 8.0, 'Technique': 8.2, 'Costume & Props': 8.6, 'Crowd Impact': 8.1, 'Street Culture': 7.9}),
      JudgeCriteriaScore(judgeName: 'Judge E', criteriaScores: {'Choreography': 8.4, 'Technique': 8.6, 'Costume & Props': 9.0, 'Crowd Impact': 8.5, 'Street Culture': 8.3}),
    ],
    penalties: [],
  ),
  DanceGroup(
    name: 'Tribe Unlimited',
    school: 'Brgy. Guadalupe',
    category: 'Breaking',
    judgeScores: [
      JudgeCriteriaScore(judgeName: 'Judge A', criteriaScores: {'Choreography': 7.9, 'Technique': 8.2, 'Costume & Props': 7.8, 'Crowd Impact': 8.1, 'Street Culture': 8.3}),
      JudgeCriteriaScore(judgeName: 'Judge B', criteriaScores: {'Choreography': 8.1, 'Technique': 8.4, 'Costume & Props': 8.0, 'Crowd Impact': 8.3, 'Street Culture': 8.5}),
      JudgeCriteriaScore(judgeName: 'Judge C', criteriaScores: {'Choreography': 8.0, 'Technique': 8.3, 'Costume & Props': 7.9, 'Crowd Impact': 8.2, 'Street Culture': 8.4}),
      JudgeCriteriaScore(judgeName: 'Judge D', criteriaScores: {'Choreography': 7.8, 'Technique': 8.1, 'Costume & Props': 7.7, 'Crowd Impact': 8.0, 'Street Culture': 8.2}),
      JudgeCriteriaScore(judgeName: 'Judge E', criteriaScores: {'Choreography': 8.2, 'Technique': 8.5, 'Costume & Props': 8.1, 'Crowd Impact': 8.4, 'Street Culture': 8.6}),
    ],
    penalties: [
      Penalty(reason: 'Unsportsmanlike conduct by member', deduction: 1.5, issuedBy: 'Head Judge'),
      Penalty(reason: 'Costume malfunction - incomplete attire', deduction: 0.5, issuedBy: 'Judge B'),
    ],
  ),
];

// Sort by finalScore descending
List<DanceGroup> get rankedGroups {
  final sorted = [...kGroups];
  sorted.sort((a, b) => b.finalScore.compareTo(a.finalScore));
  return sorted;
}

int rankOf(DanceGroup g) => rankedGroups.indexOf(g) + 1;

// ═══════════════════════════════════════════════════════════════
//  RESULTS SCREEN
// ═══════════════════════════════════════════════════════════════

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int? _expandedGroupIndex;
  bool _resultsFinalized = false;
  bool _liveMode = true;
  Timer? _liveTimer;
  int _liveTick = 0;

  // For penalty management
  final Map<String, List<Penalty>> _runtimePenalties = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _startLiveTicker();
  }

  void _startLiveTicker() {
    _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_liveMode && mounted) setState(() => _liveTick++);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildTabBar(),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildLiveRankingTab(),
              _buildJudgeBreakdownTab(),
              _buildPenaltiesTab(),
              _buildExportTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Results & Rankings',
                  style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 4),
              Text('PandanFest 2026 · Street Dance Competition · Finals',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ),
        // Live toggle
        _buildLiveToggle(),
        const SizedBox(width: 12),
        // Status badge
        _buildStatusBadge(),
        const SizedBox(width: 12),
        // Finalize
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _resultsFinalized ? Colors.grey[300] : AppColors.primary,
            foregroundColor:
                _resultsFinalized ? Colors.grey : Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: Icon(
              _resultsFinalized
                  ? Icons.lock_rounded
                  : Icons.lock_open_rounded,
              size: 18),
          label: Text(
              _resultsFinalized ? 'Locked' : 'Finalize Results',
              style:
                  GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          onPressed: _resultsFinalized
              ? null
              : () => showDialog(
                  context: context,
                  builder: (_) => _buildFinalizeDialog()),
        ),
      ],
    );
  }

  Widget _buildLiveToggle() {
    return GestureDetector(
      onTap: () => setState(() => _liveMode = !_liveMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _liveMode
              ? AppColors.live.withOpacity(0.12)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: _liveMode ? AppColors.live : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            if (_liveMode)
              _PulsingDot(color: AppColors.live)
            else
              Icon(Icons.pause_circle_outline_rounded,
                  size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              _liveMode ? 'LIVE' : 'PAUSED',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _liveMode ? AppColors.live : Colors.grey[500],
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _resultsFinalized
            ? AppColors.success.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: _resultsFinalized
                ? AppColors.success
                : AppColors.warning),
      ),
      child: Row(
        children: [
          Icon(
              _resultsFinalized
                  ? Icons.check_circle_rounded
                  : Icons.pending_rounded,
              color: _resultsFinalized
                  ? AppColors.success
                  : AppColors.warning,
              size: 16),
          const SizedBox(width: 6),
          Text(
            _resultsFinalized ? 'Finalized' : 'Tabulating…',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _resultsFinalized
                  ? AppColors.success
                  : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TAB BAR
  // ─────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle:
            GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 13),
        padding: const EdgeInsets.all(6),
        tabs: const [
          Tab(text: '🏆  Live Rankings'),
          Tab(text: '👨‍⚖️  Judge Breakdown'),
          Tab(text: '⚠️  Deductions'),
          Tab(text: '📤  Export'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 1 — LIVE RANKING BOARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLiveRankingTab() {
    return Column(
      children: [
        Expanded(child: _buildLeaderboard()),
      ],
    );
  }

  Widget _buildLeaderboard() {
    final groups = rankedGroups;
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (ctx, i) => _buildLeaderboardRow(groups[i], i),
    );
  }

  Widget _buildLeaderboardRow(DanceGroup group, int listIndex) {
    final isExpanded = _expandedGroupIndex == listIndex;
    final rank = rankOf(group);
    final rankColors = {
      1: AppColors.goldRank,
      2: AppColors.silverRank,
      3: AppColors.bronzeRank,
    };
    final rc = rankColors[rank] ?? Colors.grey[400]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: rank <= 3
            ? Border.all(color: rc.withOpacity(0.35), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() =>
                _expandedGroupIndex = isExpanded ? null : listIndex),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? rc.withOpacity(0.15)
                          : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: rank <= 3
                          ? Text(
                              rank == 1
                                  ? '🥇'
                                  : rank == 2
                                      ? '🥈'
                                      : '🥉',
                              style: const TextStyle(fontSize: 22))
                          : Text('#$rank',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                  fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(group.name,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.black87)),
                            if (group.penalties.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 11,
                                        color: AppColors.danger),
                                    const SizedBox(width: 3),
                                    Text(
                                      '-${group.totalPenalty.toStringAsFixed(1)}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: AppColors.danger,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 13, color: Colors.grey[400]),
                            const SizedBox(width: 3),
                            Text(group.school,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[500])),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.accentGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(group.category,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.accentGreen,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Score column
                  SizedBox(
                    width: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (group.totalPenalty > 0) ...[
                              Text(
                                group.rawTotal.toStringAsFixed(2),
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                    decoration:
                                        TextDecoration.lineThrough),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              '${group.finalScore.toStringAsFixed(2)} / 50.00',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: rank <= 3 ? rc : Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: group.finalScore / 50.0,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                rank <= 3 ? rc : AppColors.primary),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildQuickCriteriaExpand(group),
        ],
      ),
    );
  }

  Widget _buildQuickCriteriaExpand(DanceGroup group) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text('Average Criteria Scores',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey[700])),
          const SizedBox(height: 10),
          ...group.avgCriteriaScores.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                        width: 150,
                        child: Text(e.key,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[700]))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: e.value / 10.0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.accentGreen),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(e.value.toStringAsFixed(2),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 2 — JUDGE SCORE BREAKDOWN
  // ═══════════════════════════════════════════════════════════════

  Widget _buildJudgeBreakdownTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Per-judge matrix for each group
          ...rankedGroups.map((group) => _buildGroupJudgeCard(group)),
        ],
      ),
    );
  }

  Widget _buildGroupJudgeCard(DanceGroup group) {
    final rank = rankOf(group);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sidebarBackground,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('#$rank',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text('${group.school} · ${group.category}',
                          style: GoogleFonts.poppins(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Final Score',
                        style: GoogleFonts.poppins(
                            color: Colors.white54, fontSize: 11)),
                    Text(group.finalScore.toStringAsFixed(2),
                        style: GoogleFonts.poppins(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                  ],
                ),
              ],
            ),
          ),
          // Score table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: TableBorder.all(
                    color: Colors.grey[200]!,
                    borderRadius: BorderRadius.circular(8)),
                children: [
                  // Header row
                  TableRow(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8)),
                    ),
                    children: [
                      _tableHeader('Judge'),
                      ...kCriteria.map((c) => _tableHeader(c)),
                      _tableHeader('Subtotal'),
                    ],
                  ),
                  // Judge rows
                  ...group.judgeScores.map((js) {
                    return TableRow(
                      children: [
                        _tableCell(js.judgeName,
                            bold: true, color: Colors.grey[700]!),
                        ...kCriteria.map((c) {
                          final score = js.criteriaScores[c] ?? 0;
                          return _tableCellScore(score);
                        }),
                        _tableCell(js.total.toStringAsFixed(2),
                            bold: true, color: AppColors.primary),
                      ],
                    );
                  }),
                  // Average row
                  TableRow(
                    decoration: const BoxDecoration(
                        color: Color(0xFFFFF8E1)),
                    children: [
                      _tableCell('Average',
                          bold: true, color: Colors.black87),
                      ...kCriteria.map((c) {
                        final avg = group.avgCriteriaScores[c] ?? 0;
                        return _tableCell(avg.toStringAsFixed(2),
                            bold: true,
                            color: AppColors.accentGreen);
                      }),
                      _tableCell(group.rawTotal.toStringAsFixed(2),
                          bold: true, color: AppColors.accentGreen),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600])),
    );
  }

  Widget _tableCell(String text,
      {bool bold = false, Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w400,
              color: color)),
    );
  }

  Widget _tableCellScore(double score) {
    Color bg;
    Color fg;
    if (score >= 9.0) {
      bg = AppColors.success.withOpacity(0.08);
      fg = AppColors.success;
    } else if (score >= 8.0) {
      bg = AppColors.warning.withOpacity(0.08);
      fg = AppColors.warning;
    } else {
      bg = AppColors.danger.withOpacity(0.08);
      fg = AppColors.danger;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(score.toStringAsFixed(1),
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 3 — DEDUCTION / PENALTY SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPenaltiesTab() {
    final groupsWithPenalties =
        rankedGroups.where((g) => g.penalties.isNotEmpty).toList();
    final cleanGroups =
        rankedGroups.where((g) => g.penalties.isEmpty).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary banner
          _buildPenaltySummaryBanner(),
          const SizedBox(height: 20),
          // Add penalty button
          if (!_resultsFinalized) _buildAddPenaltyButton(),
          if (!_resultsFinalized) const SizedBox(height: 20),
          // Groups with penalties
          if (groupsWithPenalties.isNotEmpty) ...[
            _sectionLabel('⚠️  Groups with Deductions',
                color: AppColors.danger),
            const SizedBox(height: 12),
            ...groupsWithPenalties
                .map((g) => _buildPenaltyGroupCard(g, hasPenalty: true)),
            const SizedBox(height: 20),
          ],
          // Clean groups
          _sectionLabel('✅  No Deductions', color: AppColors.success),
          const SizedBox(height: 12),
          ...cleanGroups
              .map((g) => _buildPenaltyGroupCard(g, hasPenalty: false)),
        ],
      ),
    );
  }

  Widget _buildPenaltySummaryBanner() {
    final totalDeductions =
        rankedGroups.fold(0.0, (s, g) => s + g.totalPenalty);
    final affectedCount =
        rankedGroups.where((g) => g.penalties.isNotEmpty).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.danger.withOpacity(0.08),
            AppColors.warning.withOpacity(0.06)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel_rounded,
              color: AppColors.danger, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Penalty Overview',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87)),
                Text(
                    '$affectedCount group(s) received deductions · '
                    '${totalDeductions.toStringAsFixed(1)} total points deducted',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total Deducted',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey[500])),
              Text('-${totalDeductions.toStringAsFixed(1)}',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: AppColors.danger)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPenaltyButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        side: const BorderSide(color: AppColors.danger),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
      label: Text('Add Penalty / Deduction',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      onPressed: () =>
          showDialog(context: context, builder: (_) => _buildAddPenaltyDialog()),
    );
  }

  Widget _buildPenaltyGroupCard(DanceGroup group,
      {required bool hasPenalty}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: hasPenalty
            ? Border.all(
                color: AppColors.danger.withOpacity(0.25), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#${rankOf(group)}',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      fontSize: 13)),
              const SizedBox(width: 10),
              Text(group.name,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const Spacer(),
              if (hasPenalty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${group.totalPenalty.toStringAsFixed(1)} pts',
                    style: GoogleFonts.poppins(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Clean',
                      style: GoogleFonts.poppins(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
            ],
          ),
          if (hasPenalty) ...[
            const SizedBox(height: 12),
            ...group.penalties.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.danger.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger,
                                fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.reason,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13)),
                          Text('Issued by: ${p.issuedBy}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    Text('-${p.deduction.toStringAsFixed(1)}',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.danger)),
                  ],
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Raw: ${group.rawTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Final: ${group.finalScore.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Add penalty dialog (UI only — no state mutation on mock data)
  Widget _buildAddPenaltyDialog() {
    String? selectedGroup;
    final reasonController = TextEditingController();
    final deductionController = TextEditingController();
    String? selectedJudge;

    return StatefulBuilder(builder: (ctx, setD) {
      return AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Text('Add Penalty / Deduction',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Group dropdown
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Dance Group'),
                items: rankedGroups
                    .map((g) => DropdownMenuItem(
                        value: g.name, child: Text(g.name)))
                    .toList(),
                onChanged: (v) => setD(() => selectedGroup = v),
              ),
              const SizedBox(height: 14),
              // Reason
              TextField(
                controller: reasonController,
                decoration: _inputDecoration('Reason for Deduction'),
              ),
              const SizedBox(height: 14),
              // Points
              TextField(
                controller: deductionController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration('Deduction Points (e.g. 1.0)'),
              ),
              const SizedBox(height: 14),
              // Issued by
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Issued By'),
                items: ['Head Judge', ...kJudges]
                    .map((j) =>
                        DropdownMenuItem(value: j, child: Text(j)))
                    .toList(),
                onChanged: (v) => setD(() => selectedJudge = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Penalty recorded for ${selectedGroup ?? 'group'}',
                    style: GoogleFonts.poppins()),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            },
            child: Text('Apply Penalty',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      );
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 4 — EXPORT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildExportTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('📄  Generate PDF Report'),
          const SizedBox(height: 14),
          _buildExportCard(
            icon: Icons.picture_as_pdf_rounded,
            iconColor: const Color(0xFFE53935),
            title: 'Official Results Report (PDF)',
            description:
                'Full official report with rankings, criteria scores, judge breakdown, and penalty records. Suitable for submission and archiving.',
            tags: ['Rankings', 'Criteria', 'Judges', 'Penalties'],
            buttonLabel: 'Generate PDF',
            onPressed: () => _showExportSnackbar('PDF report generated!'),
          ),
          const SizedBox(height: 14),
          _buildExportCard(
            icon: Icons.leaderboard_rounded,
            iconColor: const Color(0xFF1565C0),
            title: 'Live Scoreboard Summary (PDF)',
            description:
                'Condensed scoreboard for live display or printing. Shows final ranks, group names, and total scores only.',
            tags: ['Rankings', 'Final Scores'],
            buttonLabel: 'Generate PDF',
            onPressed: () => _showExportSnackbar('Scoreboard PDF generated!'),
          ),
          const SizedBox(height: 24),
          _sectionLabel('📊  Export Results Data'),
          const SizedBox(height: 14),
          _buildExportCard(
            icon: Icons.table_chart_rounded,
            iconColor: const Color(0xFF2E7D32),
            title: 'Export to Excel (.xlsx)',
            description:
                'Complete spreadsheet with separate sheets for Rankings, Judge Scores, Criteria Matrix, and Penalties. Ideal for record-keeping.',
            tags: ['All Sheets', 'Judge Scores', 'Criteria', 'Penalties'],
            buttonLabel: 'Export Excel',
            onPressed: () => _showExportSnackbar('Excel file exported!'),
          ),
          const SizedBox(height: 14),
          _buildExportCard(
            icon: Icons.data_object_rounded,
            iconColor: const Color(0xFF6A1B9A),
            title: 'Export to CSV (.csv)',
            description:
                'Lightweight flat-file export of the final scores and rankings. Compatible with all spreadsheet applications.',
            tags: ['Rankings', 'Final Scores', 'Lightweight'],
            buttonLabel: 'Export CSV',
            onPressed: () => _showExportSnackbar('CSV file exported!'),
          ),
          const SizedBox(height: 14),
          _buildExportCard(
            icon: Icons.code_rounded,
            iconColor: const Color(0xFF00695C),
            title: 'Export Raw Data (JSON)',
            description:
                'Complete machine-readable export including all judge scores, criteria, and penalties. For system integrations.',
            tags: ['All Data', 'Developer Use'],
            buttonLabel: 'Export JSON',
            onPressed: () => _showExportSnackbar('JSON exported!'),
          ),
          const SizedBox(height: 24),
          // Export preview / data table
          _buildExportPreviewTable(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildExportCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> tags,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(description,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(tag,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey[600])),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text(buttonLabel,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildExportPreviewTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text('Export Preview — Final Results',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Text('${rankedGroups.length} groups',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  AppColors.sidebarBackground),
              headingTextStyle: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              dataTextStyle: GoogleFonts.poppins(fontSize: 13),
              columnSpacing: 20,
              columns: [
                const DataColumn(label: Text('Rank')),
                const DataColumn(label: Text('Group')),
                const DataColumn(label: Text('School')),
                const DataColumn(label: Text('Category')),
                const DataColumn(label: Text('Raw Score')),
                const DataColumn(label: Text('Deductions')),
                const DataColumn(label: Text('Final Score')),
              ],
              rows: rankedGroups.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final g = entry.value;
                return DataRow(
                  color: WidgetStateProperty.resolveWith((_) {
                    if (rank == 1) {
                      return AppColors.secondary.withOpacity(0.05);
                    }
                    return null;
                  }),
                  cells: [
                    DataCell(Text('#$rank',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold))),
                    DataCell(Text(g.name,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600))),
                    DataCell(Text(g.school)),
                    DataCell(Text(g.category)),
                    DataCell(Text(g.rawTotal.toStringAsFixed(2))),
                    DataCell(Text(
                      g.totalPenalty > 0
                          ? '-${g.totalPenalty.toStringAsFixed(1)}'
                          : '—',
                      style: GoogleFonts.poppins(
                          color: g.totalPenalty > 0
                              ? AppColors.danger
                              : Colors.grey[400]),
                    )),
                    DataCell(Text(g.finalScore.toStringAsFixed(2),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.poppins()),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ─────────────────────────────────────────────
  //  SHARED HELPERS
  // ─────────────────────────────────────────────

  Widget _sectionLabel(String text, {Color? color}) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color ?? Colors.black87));
  }

  Widget _buildFinalizeDialog() {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Text('Finalize Results?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Text(
        'Once finalized, scores will be locked and cannot be modified. '
        'Make sure all judges have submitted their scores and all penalties have been recorded.',
        style:
            GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.poppins(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            setState(() {
              _resultsFinalized = true;
              _liveMode = false;
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Results finalized and locked! 🏆',
                  style: GoogleFonts.poppins()),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ));
          },
          child: Text('Yes, Finalize',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PULSING DOT WIDGET
// ═══════════════════════════════════════════════════════════════

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: widget.color, shape: BoxShape.circle)),
    );
  }
}