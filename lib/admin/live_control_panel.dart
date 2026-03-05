import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';

// ================= STATIC DATA MODELS =================

class PerformingGroup {
  final String id;
  final String name;
  final String barangay;
  final String theme;
  final int performanceOrder;

  const PerformingGroup({
    required this.id,
    required this.name,
    required this.barangay,
    required this.theme,
    required this.performanceOrder,
  });
}

class ActiveCriterion {
  final String id;
  final String name;
  final double weight;
  final double maxScore;

  const ActiveCriterion({
    required this.id,
    required this.name,
    required this.weight,
    required this.maxScore,
  });
}

class JudgeScore {
  final String judgeId;
  final String judgeName;
  final Map<String, double> scores; // criterionId -> score
  final bool isSubmitted;

  const JudgeScore({
    required this.judgeId,
    required this.judgeName,
    required this.scores,
    required this.isSubmitted,
  });

  double get totalWeighted => scores.entries.fold(0.0, (sum, e) {
    final criterion = _staticCriteria.firstWhere(
      (c) => c.id == e.key,
      orElse: () =>
          const ActiveCriterion(id: '', name: '', weight: 0, maxScore: 100),
    );
    return sum + (e.value * criterion.weight / 100);
  });
}

class RankingEntry {
  final String groupId;
  final String groupName;
  final String barangay;
  final double averageScore;
  final int rank;

  const RankingEntry({
    required this.groupId,
    required this.groupName,
    required this.barangay,
    required this.averageScore,
    required this.rank,
  });
}

// ================= STATIC SAMPLE DATA =================

const List<PerformingGroup> _staticGroups = [
  PerformingGroup(
    id: 'g1',
    name: 'Sayaw Pandan',
    barangay: 'Brgy. Pandan',
    theme: 'Urban Fusion',
    performanceOrder: 1,
  ),
  PerformingGroup(
    id: 'g2',
    name: 'Ritmo Barangay',
    barangay: 'Brgy. San Isidro',
    theme: 'Cultural Heritage',
    performanceOrder: 2,
  ),
  PerformingGroup(
    id: 'g3',
    name: 'Kalye Kings',
    barangay: 'Brgy. Malaya',
    theme: 'Hip-Hop Street',
    performanceOrder: 3,
  ),
  PerformingGroup(
    id: 'g4',
    name: 'Alon Dancers',
    barangay: 'Brgy. Bagong Silang',
    theme: 'Contemporary Wave',
    performanceOrder: 4,
  ),
];

const List<ActiveCriterion> _staticCriteria = [
  ActiveCriterion(id: 'c1', name: 'Choreography', weight: 25, maxScore: 100),
  ActiveCriterion(id: 'c2', name: 'Synchronization', weight: 20, maxScore: 100),
  ActiveCriterion(id: 'c3', name: 'Costume', weight: 15, maxScore: 100),
  ActiveCriterion(id: 'c4', name: 'Musicality', weight: 20, maxScore: 100),
  ActiveCriterion(id: 'c5', name: 'Overall Impact', weight: 20, maxScore: 100),
];

// Simulated scores per group per judge
final Map<String, List<JudgeScore>> _staticJudgeScores = {
  'g1': [
    JudgeScore(
      judgeId: 'j1',
      judgeName: 'Judge Reyes',
      scores: {'c1': 88, 'c2': 90, 'c3': 85, 'c4': 91, 'c5': 87},
      isSubmitted: true,
    ),
    JudgeScore(
      judgeId: 'j2',
      judgeName: 'Judge Santos',
      scores: {'c1': 92, 'c2': 88, 'c3': 90, 'c4': 86, 'c5': 93},
      isSubmitted: true,
    ),
    JudgeScore(
      judgeId: 'j3',
      judgeName: 'Judge Cruz',
      scores: {'c1': 85, 'c2': 84, 'c3': 88, 'c4': 89, 'c5': 86},
      isSubmitted: false,
    ),
  ],
  'g2': [
    JudgeScore(
      judgeId: 'j1',
      judgeName: 'Judge Reyes',
      scores: {'c1': 80, 'c2': 82, 'c3': 79, 'c4': 83, 'c5': 81},
      isSubmitted: true,
    ),
    JudgeScore(
      judgeId: 'j2',
      judgeName: 'Judge Santos',
      scores: {'c1': 84, 'c2': 80, 'c3': 83, 'c4': 78, 'c5': 82},
      isSubmitted: true,
    ),
    JudgeScore(
      judgeId: 'j3',
      judgeName: 'Judge Cruz',
      scores: {'c1': 79, 'c2': 77, 'c3': 81, 'c4': 80, 'c5': 78},
      isSubmitted: true,
    ),
  ],
  'g3': [
    JudgeScore(
      judgeId: 'j1',
      judgeName: 'Judge Reyes',
      scores: {'c1': 86, 'c2': 85, 'c3': 84, 'c4': 87, 'c5': 88},
      isSubmitted: true,
    ),
    JudgeScore(
      judgeId: 'j2',
      judgeName: 'Judge Santos',
      scores: {'c1': 89, 'c2': 87, 'c3': 86, 'c4': 84, 'c5': 90},
      isSubmitted: false,
    ),
    JudgeScore(
      judgeId: 'j3',
      judgeName: 'Judge Cruz',
      scores: {},
      isSubmitted: false,
    ),
  ],
  'g4': [
    JudgeScore(
      judgeId: 'j1',
      judgeName: 'Judge Reyes',
      scores: {},
      isSubmitted: false,
    ),
    JudgeScore(
      judgeId: 'j2',
      judgeName: 'Judge Santos',
      scores: {},
      isSubmitted: false,
    ),
    JudgeScore(
      judgeId: 'j3',
      judgeName: 'Judge Cruz',
      scores: {},
      isSubmitted: false,
    ),
  ],
};

// ================= MAIN SCREEN =================

class LiveControlPanel extends StatefulWidget {
  const LiveControlPanel({super.key});

  @override
  State<LiveControlPanel> createState() => _LiveControlPanelState();
}

class _LiveControlPanelState extends State<LiveControlPanel>
    with SingleTickerProviderStateMixin {
  String? selectedGroupId;
  List<String> selectedCriteriaIds = _staticCriteria.map((c) => c.id).toList();
  bool isPushedToJudges = false;
  bool isPushing = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  PerformingGroup? get selectedGroup => selectedGroupId != null
      ? _staticGroups.firstWhere((g) => g.id == selectedGroupId)
      : null;

  List<ActiveCriterion> get activeCriteria =>
      _staticCriteria.where((c) => selectedCriteriaIds.contains(c.id)).toList();

  List<JudgeScore> get currentScores => selectedGroupId != null
      ? (_staticJudgeScores[selectedGroupId] ?? [])
      : [];

  List<RankingEntry> get rankings {
    final List<RankingEntry> entries = [];
    _staticJudgeScores.forEach((groupId, judgeScores) {
      final submitted = judgeScores.where((j) => j.isSubmitted).toList();
      if (submitted.isEmpty) return;
      final avg =
          submitted.fold(0.0, (sum, j) => sum + j.totalWeighted) /
          submitted.length;
      final group = _staticGroups.firstWhere((g) => g.id == groupId);
      entries.add(
        RankingEntry(
          groupId: groupId,
          groupName: group.name,
          barangay: group.barangay,
          averageScore: avg,
          rank: 0,
        ),
      );
    });
    entries.sort((a, b) => b.averageScore.compareTo(a.averageScore));
    return entries
        .asMap()
        .entries
        .map(
          (e) => RankingEntry(
            groupId: e.value.groupId,
            groupName: e.value.groupName,
            barangay: e.value.barangay,
            averageScore: e.value.averageScore,
            rank: e.key + 1,
          ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pushToJudges() async {
    if (selectedGroupId == null || activeCriteria.isEmpty) return;
    setState(() => isPushing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      isPushing = false;
      isPushedToJudges = true;
    });
  }

  void _resetPush() => setState(() => isPushedToJudges = false);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Live Control Panel",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (_, __) => Opacity(
                          opacity: _pulseAnimation.value,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.live,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "LIVE SESSION ACTIVE",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.live,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Push Status Badge
            if (isPushedToJudges)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.live.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.live.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_rounded, color: AppColors.live, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Synced to all judges",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.live,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _resetPush,
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.live,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── LEFT COLUMN: Controls (scrollable) ──
              SizedBox(
                width: 340,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _GroupSelector(
                        groups: _staticGroups,
                        selectedId: selectedGroupId,
                        onSelect: (id) => setState(() {
                          selectedGroupId = id;
                          isPushedToJudges = false;
                        }),
                      ),
                      const SizedBox(height: 16),
                      _CriteriaSelector(
                        criteria: _staticCriteria,
                        selectedIds: selectedCriteriaIds,
                        onToggle: (id) => setState(() {
                          if (selectedCriteriaIds.contains(id)) {
                            selectedCriteriaIds.remove(id);
                          } else {
                            selectedCriteriaIds.add(id);
                          }
                          isPushedToJudges = false;
                        }),
                      ),
                      const SizedBox(height: 16),
                      _PushButton(
                        isReady:
                            selectedGroupId != null &&
                            activeCriteria.isNotEmpty,
                        isPushing: isPushing,
                        isPushed: isPushedToJudges,
                        onPush: _pushToJudges,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // ── RIGHT COLUMN: Scores + Rankings ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Real-Time Score Display (intrinsic height)
                    _ScoreDisplay(
                      group: selectedGroup,
                      criteria: activeCriteria,
                      judgeScores: currentScores,
                      isPushed: isPushedToJudges,
                    ),
                    const SizedBox(height: 16),
                    // Rankings takes remaining space
                    Expanded(child: _RankingBoard(rankings: rankings)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================= GROUP SELECTOR =================

class _GroupSelector extends StatelessWidget {
  final List<PerformingGroup> groups;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _GroupSelector({
    required this.groups,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: AppColors.shadow,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded, color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              Text(
                "Current Performing Group",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...groups.map((group) {
            final isSelected = selectedId == group.id;
            return GestureDetector(
              onTap: () => onSelect(group.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.secondary.withOpacity(0.12)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.secondary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.divider,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${group.performanceOrder}",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.silverRank,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.secondary : null,
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
                    if (isSelected)
                      Icon(
                        Icons.radio_button_checked_rounded,
                        color: AppColors.secondary,
                        size: 18,
                      )
                    else
                      Icon(
                        Icons.radio_button_off_rounded,
                        color: AppColors.divider,
                        size: 18,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ================= CRITERIA SELECTOR =================

class _CriteriaSelector extends StatelessWidget {
  final List<ActiveCriterion> criteria;
  final List<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _CriteriaSelector({
    required this.criteria,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: AppColors.shadow,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rule_folder_rounded,
                color: AppColors.secondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "Active Criteria",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                "${selectedIds.length}/${criteria.length}",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.silverRank,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...criteria.map((c) {
            final isSelected = selectedIds.contains(c.id);
            return GestureDetector(
              onTap: () => onToggle(c.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.secondary.withOpacity(0.08)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.secondary.withOpacity(0.4)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.silverRank,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? null : AppColors.silverRank,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary.withOpacity(0.12)
                            : AppColors.divider.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${c.weight.toStringAsFixed(0)}%",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.silverRank,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ================= PUSH BUTTON =================

class _PushButton extends StatelessWidget {
  final bool isReady;
  final bool isPushing;
  final bool isPushed;
  final VoidCallback onPush;

  const _PushButton({
    required this.isReady,
    required this.isPushing,
    required this.isPushed,
    required this.onPush,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor = Colors.white;
    Widget child;
    VoidCallback? tapHandler;

    if (isPushing) {
      bgColor = AppColors.secondary.withOpacity(0.7);
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Syncing...",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ],
      );
      tapHandler = null;
    } else if (isPushed) {
      bgColor = AppColors.live;
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(
            "Pushed to Judges",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ],
      );
      tapHandler = onPush;
    } else if (!isReady) {
      bgColor = AppColors.divider;
      fgColor = AppColors.silverRank;
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.send_rounded, color: AppColors.silverRank, size: 20),
          const SizedBox(width: 10),
          Text(
            "Push to Judges",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.silverRank,
            ),
          ),
        ],
      );
      tapHandler = null;
    } else {
      bgColor = AppColors.primary;
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(
            "Push to Judges",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ],
      );
      tapHandler = onPush;
    }

    return GestureDetector(
      onTap: tapHandler,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isReady && !isPushing
              ? [
                  BoxShadow(
                    color: bgColor.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: child,
      ),
    );
  }
}

// ================= SCORE DISPLAY =================

class _ScoreDisplay extends StatelessWidget {
  final PerformingGroup? group;
  final List<ActiveCriterion> criteria;
  final List<JudgeScore> judgeScores;
  final bool isPushed;

  const _ScoreDisplay({
    required this.group,
    required this.criteria,
    required this.judgeScores,
    required this.isPushed,
  });

  double get avgWeightedScore {
    final submitted = judgeScores
        .where((j) => j.isSubmitted && j.scores.isNotEmpty)
        .toList();
    if (submitted.isEmpty) return 0;
    return submitted.fold(0.0, (s, j) => s + j.totalWeighted) /
        submitted.length;
  }

  int get submittedCount => judgeScores.where((j) => j.isSubmitted).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: AppColors.shadow,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.live_tv_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                "Real-Time Score Display",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (group != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    group!.name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          if (group == null || !isPushed) ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 40,
                    color: AppColors.divider,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    group == null
                        ? "Select a group and push to judges\nto start scoring."
                        : "Waiting for push to judges...",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppColors.silverRank,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            const SizedBox(height: 16),

            // Average Score Hero
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.75),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Average Score",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          avgWeightedScore.toStringAsFixed(2),
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Submitted",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.silverRank,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "$submittedCount",
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentGreen,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                " / ${judgeScores.length}",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: AppColors.silverRank,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Per-Judge Score Rows
            ...judgeScores.map(
              (js) => _JudgeScoreRow(judgeScore: js, criteria: criteria),
            ),
          ],
        ],
      ),
    );
  }
}

// ================= JUDGE SCORE ROW =================

class _JudgeScoreRow extends StatelessWidget {
  final JudgeScore judgeScore;
  final List<ActiveCriterion> criteria;

  const _JudgeScoreRow({required this.judgeScore, required this.criteria});

  @override
  Widget build(BuildContext context) {
    final hasScores = judgeScore.isSubmitted && judgeScore.scores.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasScores
            ? AppColors.accentGreen.withOpacity(0.05)
            : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasScores
              ? AppColors.accentGreen.withOpacity(0.2)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          // Judge name + status
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasScores
                        ? AppColors.accentGreen
                        : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    judgeScore.judgeName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Per-criterion scores
          Expanded(
            child: hasScores
                ? Wrap(
                    spacing: 6,
                    children: criteria.map((c) {
                      final score = judgeScore.scores[c.id];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${c.name.split(' ').first}: ${score?.toStringAsFixed(0) ?? '-'}",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : Text(
                    judgeScore.isSubmitted
                        ? "Submitted — no scores yet"
                        : "Waiting for score...",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.silverRank,
                    ),
                  ),
          ),

          // Weighted total
          if (hasScores)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                judgeScore.totalWeighted.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ================= RANKING BOARD =================

class _RankingBoard extends StatelessWidget {
  final List<RankingEntry> rankings;

  const _RankingBoard({required this.rankings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: AppColors.shadow,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: AppColors.goldRank,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "Live Rankings",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.live.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "AUTO-UPDATED",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.live,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (rankings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "No scores submitted yet.",
                  style: GoogleFonts.poppins(
                    color: AppColors.silverRank,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: rankings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final entry = rankings[i];
                  return _RankRow(entry: entry);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ================= RANK ROW =================

class _RankRow extends StatelessWidget {
  final RankingEntry entry;

  const _RankRow({required this.entry});

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: entry.rank <= 3
            ? _rankColor.withOpacity(0.06)
            : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: entry.rank <= 3
              ? _rankColor.withOpacity(0.25)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _rankColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: entry.rank <= 3
                  ? Icon(
                      Icons.emoji_events_rounded,
                      color: _rankColor,
                      size: 16,
                    )
                  : Text(
                      "${entry.rank}",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _rankColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + barangay
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

          // Score bar + value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.averageScore.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _rankColor,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (entry.averageScore / 100).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: _rankColor.withOpacity(0.15),
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
