import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';

// ─────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────

class JudgeScore {
  final String judgeName;
  final double score;

  const JudgeScore({required this.judgeName, required this.score});
}

class Deduction {
  final String reason;
  final double points;

  const Deduction({required this.reason, required this.points});
}

class DanceGroupResult {
  final int rank;
  final String groupName;
  final String category;
  final List<JudgeScore> judgeScores;
  final List<Deduction> deductions;

  const DanceGroupResult({
    required this.rank,
    required this.groupName,
    required this.category,
    required this.judgeScores,
    required this.deductions,
  });

  double get totalJudgeScore => judgeScores.fold(0, (sum, j) => sum + j.score);

  double get totalDeductions => deductions.fold(0, (sum, d) => sum + d.points);

  double get finalScore => totalJudgeScore - totalDeductions;
}

// ─────────────────────────────────────────
// SAMPLE DATA
// ─────────────────────────────────────────

final List<DanceGroupResult> _sampleResults = [
  DanceGroupResult(
    rank: 1,
    groupName: "Groove Masters",
    category: "Street Hip-Hop",
    judgeScores: const [
      JudgeScore(judgeName: "Judge 1", score: 92),
      JudgeScore(judgeName: "Judge 2", score: 95),
      JudgeScore(judgeName: "Judge 3", score: 90),
    ],
    deductions: const [Deduction(reason: "Costume violation", points: 2)],
  ),
  DanceGroupResult(
    rank: 2,
    groupName: "Pandan Steppers",
    category: "Street Hip-Hop",
    judgeScores: const [
      JudgeScore(judgeName: "Judge 1", score: 88),
      JudgeScore(judgeName: "Judge 2", score: 91),
      JudgeScore(judgeName: "Judge 3", score: 89),
    ],
    deductions: const [],
  ),
  DanceGroupResult(
    rank: 3,
    groupName: "Urban Pulse",
    category: "Breaking",
    judgeScores: const [
      JudgeScore(judgeName: "Judge 1", score: 85),
      JudgeScore(judgeName: "Judge 2", score: 87),
      JudgeScore(judgeName: "Judge 3", score: 86),
    ],
    deductions: const [Deduction(reason: "Late entry", points: 3)],
  ),
  DanceGroupResult(
    rank: 4,
    groupName: "Rhythm Force",
    category: "Breaking",
    judgeScores: const [
      JudgeScore(judgeName: "Judge 1", score: 80),
      JudgeScore(judgeName: "Judge 2", score: 83),
      JudgeScore(judgeName: "Judge 3", score: 81),
    ],
    deductions: const [],
  ),
  DanceGroupResult(
    rank: 5,
    groupName: "Street Legends",
    category: "Waacking",
    judgeScores: const [
      JudgeScore(judgeName: "Judge 1", score: 78),
      JudgeScore(judgeName: "Judge 2", score: 80),
      JudgeScore(judgeName: "Judge 3", score: 79),
    ],
    deductions: const [Deduction(reason: "Music violation", points: 5)],
  ),
];

// ─────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DanceGroupResult? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // EXPORT ACTIONS
  // ─────────────────────────────────────────

  void _generatePDF() {
    _showSnack(
      "Generating PDF report...",
      Icons.picture_as_pdf_rounded,
      Colors.red,
    );
  }

  void _exportExcel() {
    _showSnack(
      "Exporting to Excel...",
      Icons.table_chart_rounded,
      Colors.green,
    );
  }

  void _exportCSV() {
    _showSnack("Exporting to CSV...", Icons.file_present_rounded, Colors.blue);
  }

  void _showSnack(String msg, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Row(
          children: [
            Text(
              "Results & Analytics",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Export buttons
            _ExportButton(
              label: "PDF",
              icon: Icons.picture_as_pdf_rounded,
              color: Colors.red,
              onTap: _generatePDF,
            ),
            const SizedBox(width: 10),
            _ExportButton(
              label: "Excel",
              icon: Icons.table_chart_rounded,
              color: Colors.green,
              onTap: _exportExcel,
            ),
            const SizedBox(width: 10),
            _ExportButton(
              label: "CSV",
              icon: Icons.file_present_rounded,
              color: Colors.blue,
              onTap: _exportCSV,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Tab Bar ──
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                color: AppColors.shadow,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.secondary,
            indicatorWeight: 3,
            labelColor: AppColors.secondary,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w400,
              fontSize: 13,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.leaderboard_rounded), text: "Live Ranking"),
              Tab(icon: Icon(Icons.gavel_rounded), text: "Score Breakdown"),
              Tab(
                icon: Icon(Icons.remove_circle_outline_rounded),
                text: "Deductions",
              ),
              Tab(icon: Icon(Icons.file_download_rounded), text: "Export"),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Tab Views ──
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLiveRanking(),
              _buildScoreBreakdown(),
              _buildDeductionsSection(),
              _buildExportSection(),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // TAB 1 — LIVE RANKING BOARD
  // ─────────────────────────────────────────

  Widget _buildLiveRanking() {
    final sorted = [..._sampleResults]
      ..sort((a, b) => b.finalScore.compareTo(a.finalScore));

    return Container(
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
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _headerCell("Rank", flex: 1),
                _headerCell("Group Name", flex: 3),
                _headerCell("Category", flex: 2),
                _headerCell("Raw Score", flex: 2),
                _headerCell("Deductions", flex: 2),
                _headerCell("Final Score", flex: 2),
              ],
            ),
          ),
          // Table rows
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final group = sorted[index];
                final isTop3 = index < 3;
                return InkWell(
                  onTap: () => setState(() => _selectedGroup = group),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedGroup?.groupName == group.groupName
                          ? AppColors.secondary.withOpacity(0.08)
                          : index.isEven
                          ? Colors.transparent
                          : AppColors.primary.withOpacity(0.03),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _RankBadge(rank: index + 1, isTop3: isTop3),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            group.groupName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              group.category,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.secondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            group.totalJudgeScore.toStringAsFixed(1),
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            group.totalDeductions > 0
                                ? "-${group.totalDeductions.toStringAsFixed(1)}"
                                : "—",
                            style: GoogleFonts.poppins(
                              color: group.totalDeductions > 0
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            group.finalScore.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isTop3
                                  ? AppColors.secondary
                                  : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
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

  // ─────────────────────────────────────────
  // TAB 2 — SCORE BREAKDOWN PER JUDGE
  // ─────────────────────────────────────────

  Widget _buildScoreBreakdown() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group list
        SizedBox(
          width: 220,
          child: Container(
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Select Group",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sampleResults.length,
                    itemBuilder: (context, index) {
                      final group = _sampleResults[index];
                      final isSelected =
                          _selectedGroup?.groupName == group.groupName;
                      return InkWell(
                        onTap: () => setState(() => _selectedGroup = group),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          color: isSelected
                              ? AppColors.secondary.withOpacity(0.1)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                size: 16,
                                color: isSelected
                                    ? AppColors.secondary
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  group.groupName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? AppColors.secondary
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 20),

        // Score breakdown detail
        Expanded(
          child: _selectedGroup == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Select a group to view scores",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(24),
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
                      Text(
                        _selectedGroup!.groupName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _selectedGroup!.category,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Judge score bars
                      ..._selectedGroup!.judgeScores.map((j) {
                        final pct = j.score / 100;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.gavel_rounded,
                                    size: 16,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    j.judgeName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "${j.score.toStringAsFixed(1)} pts",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 12,
                                  backgroundColor: Colors.grey.withOpacity(
                                    0.15,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ScoreSummaryTile(
                            label: "Raw Score",
                            value: _selectedGroup!.totalJudgeScore
                                .toStringAsFixed(1),
                            color: Colors.blue,
                          ),
                          _ScoreSummaryTile(
                            label: "Deductions",
                            value:
                                "-${_selectedGroup!.totalDeductions.toStringAsFixed(1)}",
                            color: Colors.red,
                          ),
                          _ScoreSummaryTile(
                            label: "Final Score",
                            value: _selectedGroup!.finalScore.toStringAsFixed(
                              1,
                            ),
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // TAB 3 — DEDUCTIONS / PENALTY SECTION
  // ─────────────────────────────────────────

  Widget _buildDeductionsSection() {
    final groupsWithDeductions = _sampleResults
        .where((g) => g.deductions.isNotEmpty)
        .toList();

    return Container(
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: const Border(
                bottom: BorderSide(color: Colors.redAccent, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.remove_circle_rounded,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  "Deduction & Penalty Records",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${groupsWithDeductions.length} groups affected",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: groupsWithDeductions.isEmpty
                ? Center(
                    child: Text(
                      "No deductions recorded.",
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groupsWithDeductions.length,
                    itemBuilder: (context, index) {
                      final group = groupsWithDeductions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.red.withOpacity(0.03),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.groups_rounded,
                                  size: 18,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  group.groupName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  "Total: -${group.totalDeductions.toStringAsFixed(1)} pts",
                                  style: GoogleFonts.poppins(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...group.deductions.map(
                              (d) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.arrow_right_rounded,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        d.reason,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "-${d.points.toStringAsFixed(1)} pts",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // TAB 4 — EXPORT SECTION
  // ─────────────────────────────────────────

  Widget _buildExportSection() {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.3,
      children: [
        _ExportCard(
          icon: Icons.picture_as_pdf_rounded,
          title: "Generate PDF Report",
          description:
              "Export a full competition report with rankings, scores, and deductions as a PDF.",
          color: Colors.red,
          buttonLabel: "Generate PDF",
          onTap: _generatePDF,
        ),
        _ExportCard(
          icon: Icons.table_chart_rounded,
          title: "Export to Excel",
          description:
              "Download all scores and rankings in Excel format for further analysis.",
          color: Colors.green,
          buttonLabel: "Export Excel",
          onTap: _exportExcel,
        ),
        _ExportCard(
          icon: Icons.file_present_rounded,
          title: "Export to CSV",
          description:
              "Export raw scoring data as a CSV file compatible with any spreadsheet tool.",
          color: Colors.blue,
          buttonLabel: "Export CSV",
          onTap: _exportCSV,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────

  Widget _headerCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────

class _RankBadge extends StatelessWidget {
  final int rank;
  final bool isTop3;

  const _RankBadge({required this.rank, required this.isTop3});

  Color get _color => switch (rank) {
    1 => const Color(0xFFFFD700),
    2 => const Color(0xFFC0C0C0),
    3 => const Color(0xFFCD7F32),
    _ => Colors.grey.shade300,
  };

  IconData get _icon => switch (rank) {
    1 => Icons.emoji_events_rounded,
    2 => Icons.emoji_events_rounded,
    3 => Icons.emoji_events_rounded,
    _ => Icons.tag_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_icon, color: _color, size: isTop3 ? 22 : 16),
        const SizedBox(width: 4),
        Text(
          "#$rank",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isTop3 ? _color : Colors.grey,
            fontSize: isTop3 ? 15 : 13,
          ),
        ),
      ],
    );
  }
}

class _ScoreSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreSummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExportButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: GoogleFonts.poppins(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String buttonLabel;
  final VoidCallback onTap;

  const _ExportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.buttonLabel,
    required this.onTap,
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 16),
              label: Text(
                buttonLabel,
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
