import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';
import 'package:pandan_fest/models/app_models.dart';
import 'package:pandan_fest/services.dart';

enum JudgeScreenState { selectContestant, scoring, submitted }

// ═══════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════

class JudgeTopBar extends StatelessWidget {
  final String judgeId;
  final CompetitionStage stage;
  final Color stageColor;
  final String categoryTitle;
  final IconData categoryIcon;
  final Color categoryColor;
  final VoidCallback? onBack;

  const JudgeTopBar({
    super.key,
    required this.judgeId,
    required this.stage,
    required this.stageColor,
    required this.categoryTitle,
    required this.categoryIcon,
    required this.categoryColor,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
              onPressed: onBack,
              tooltip: "Back to contestant list",
            ),
            const SizedBox(width: 4),
          ],
          ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(12),
            child: Image.asset("assets/images/PandanFestLogo.png", width: 46, height: 46),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("PandanFest 2026", style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              Row(children: [
                Icon(categoryIcon, size: 12, color: categoryColor.withOpacity(0.9)),
                const SizedBox(width: 4),
                Text(categoryTitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                Text(" · Judge Portal", style: GoogleFonts.poppins(fontSize: 11, color: Colors.white38)),
              ]),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: categoryColor.withOpacity(0.5)),
            ),
            child: Row(children: [
              Icon(categoryIcon, size: 13, color: categoryColor),
              const SizedBox(width: 6),
              Text(categoryTitle.toUpperCase(), style: GoogleFonts.poppins(
                  fontSize: 11, color: categoryColor, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            ]),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.live.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.live.withOpacity(0.5)),
            ),
            child: Row(children: [
              Container(width: 7, height: 7,
                  decoration: const BoxDecoration(color: AppColors.live, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text("LIVE", style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.live, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ]),
          ),
          const SizedBox(width: 16),
          Row(children: [
            const CircleAvatar(radius: 18, backgroundColor: Colors.white24,
                child: Icon(Icons.gavel_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(resolveJudgeName(judgeId), style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              Text(resolveJudgePosition(judgeId), style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.white60)),
            ]),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: stageColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: stageColor.withOpacity(0.5)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.flag_rounded, size: 12, color: Colors.white70),
                const SizedBox(width: 5),
                Text(stage.name, style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),
            ),
          ]),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CONTESTANT PICKER
// ═══════════════════════════════════════════════════════════════════

class JudgeContestantPicker extends StatelessWidget {
  final String categoryTitle;
  final IconData categoryIcon;
  final Color categoryColor;
  final List<ActiveCriterion> criteria;
  final Set<String> scoredGroupIds;
  final void Function(PerformingGroup) onSelect;
  final String? pushedGroupId; // if set, only this group can be scored

  const JudgeContestantPicker({
    super.key,
    required this.categoryTitle,
    required this.categoryIcon,
    required this.categoryColor,
    required this.criteria,
    required this.scoredGroupIds,
    required this.onSelect,
    this.pushedGroupId,
  });

  @override
  Widget build(BuildContext context) {
    final color = categoryColor;
    final scored = scoredGroupIds.length;
    final total = staticGroups.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Container(width: 52, height: 52,
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                    child: Icon(categoryIcon, color: color, size: 26)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("$categoryTitle Scoring", style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                    Text("Select a contestant to begin scoring the $categoryTitle category.",
                        style: GoogleFonts.poppins(fontSize: 12, color: color.withOpacity(0.7))),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Column(children: [
                      Text("$scored / $total", style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                      Text("Scored", style: GoogleFonts.poppins(fontSize: 10, color: color.withOpacity(0.7))),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: criteria.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Text("${c.name} (${c.weight.toStringAsFixed(0)}%)",
                    style: GoogleFonts.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
                )).toList(),
              ),
              const SizedBox(height: 24),
              Row(children: [
                const Icon(Icons.groups_rounded, size: 18, color: Color(0xFF1C1C1E)),
                const SizedBox(width: 8),
                Text("Select Contestant to Score", style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1C1C1E))),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(20)),
                  child: Text("${staticGroups.length} contestants", style: GoogleFonts.poppins(
                      fontSize: 11, color: const Color(0xFF6C6C70))),
                ),
              ]),
              const SizedBox(height: 6),
              Text("Tap a contestant card to begin scoring. Already scored ones are marked.",
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF8E8E93))),
              const SizedBox(height: 20),
              ...staticGroups.map((g) {
                final isLocked = pushedGroupId != null && g.id != pushedGroupId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: JudgeContestantCard(
                    group: g,
                    categoryColor: color,
                    categoryIcon: categoryIcon,
                    isScored: scoredGroupIds.contains(g.id),
                    isLocked: isLocked,
                    onSelect: isLocked ? null : () => onSelect(g),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CONTESTANT CARD
// ═══════════════════════════════════════════════════════════════════

class JudgeContestantCard extends StatefulWidget {
  final PerformingGroup group;
  final Color categoryColor;
  final IconData categoryIcon;
  final bool isScored;
  final bool isLocked;
  final VoidCallback? onSelect;

  const JudgeContestantCard({
    super.key,
    required this.group,
    required this.categoryColor,
    required this.categoryIcon,
    required this.isScored,
    this.isLocked = false,
    this.onSelect,
  });

  @override
  State<JudgeContestantCard> createState() => _JudgeContestantCardState();
}

class _JudgeContestantCardState extends State<JudgeContestantCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final scored = widget.isScored;
    final locked = widget.isLocked;
    final color = locked
        ? const Color(0xFFAEAEB2)
        : scored ? AppColors.accentGreen : widget.categoryColor;

    return MouseRegion(
      onEnter: (_) => !locked ? setState(() => _hovered = true) : null,
      onExit: (_) => setState(() => _hovered = false),
      cursor: locked ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: locked
                ? const Color(0xFFF8F8F8)
                : _hovered
                    ? (scored ? AppColors.accentGreen.withOpacity(0.05) : widget.categoryColor.withOpacity(0.04))
                    : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: locked
                  ? const Color(0xFFE5E5EA)
                  : scored
                      ? AppColors.accentGreen.withOpacity(0.4)
                      : (_hovered ? widget.categoryColor.withOpacity(0.5) : const Color(0xFFE5E5EA)),
              width: (!locked && (scored || _hovered)) ? 1.8 : 1,
            ),
            boxShadow: [BoxShadow(
              color: locked
                  ? Colors.black.withOpacity(0.02)
                  : _hovered ? widget.categoryColor.withOpacity(0.12) : Colors.black.withOpacity(0.05),
              blurRadius: _hovered ? 16 : 8, offset: const Offset(0, 4),
            )],
          ),
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: locked
                  ? const Center(child: Icon(Icons.lock_rounded, size: 20, color: Color(0xFFAEAEB2)))
                  : Center(child: Text("#${g.performanceOrder}", style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color))),
            ),
            const SizedBox(width: 18),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(g.name, style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: locked ? const Color(0xFFAEAEB2) : const Color(0xFF1C1C1E)))),
                if (locked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.lock_rounded, size: 11, color: Color(0xFFAEAEB2)),
                      const SizedBox(width: 4),
                      Text("Not pushed", style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFFAEAEB2))),
                    ]),
                  )
                else if (scored)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.accentGreen),
                      const SizedBox(width: 4),
                      Text("Scored", style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accentGreen)),
                    ]),
                  ),
              ]),
              const SizedBox(height: 6),
              Wrap(spacing: 14, children: [
                _chip(Icons.location_on_outlined, g.barangay, locked),
                _chip(Icons.palette_outlined, g.theme, locked),
              ]),
            ])),
            const SizedBox(width: 16),
            if (locked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lock_rounded, size: 16, color: Color(0xFFAEAEB2)),
                  const SizedBox(width: 7),
                  Text("Locked", style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFAEAEB2))),
                ]),
              )
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: scored ? AppColors.accentGreen : (_hovered ? widget.categoryColor : widget.categoryColor.withOpacity(0.85)),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                    color: (scored ? AppColors.accentGreen : widget.categoryColor).withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 3),
                  )],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(scored ? Icons.edit_rounded : widget.categoryIcon, size: 16, color: Colors.white),
                  const SizedBox(width: 7),
                  Text(scored ? "Re-score" : "Score Now", style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, [bool locked = false]) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: locked ? const Color(0xFFD1D1D6) : const Color(0xFF8E8E93)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.poppins(fontSize: 12,
          color: locked ? const Color(0xFFD1D1D6) : const Color(0xFF8E8E93))),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════
// SCORING BODY
// ═══════════════════════════════════════════════════════════════════

class JudgeScoringBody extends StatelessWidget {
  final PerformingGroup group;
  final List<ActiveCriterion> criteria;
  final Map<String, TextEditingController> controllers;
  final Map<String, String?> errors;
  final String categoryTitle;
  final IconData categoryIcon;
  final Color categoryColor;
  final int filledCount;
  final double weightedTotal;
  final bool isSubmitting;
  final VoidCallback? onBack;
  final VoidCallback onSubmit;
  final void Function(String) onChanged;

  const JudgeScoringBody({
    super.key,
    required this.group,
    required this.criteria,
    required this.controllers,
    required this.errors,
    required this.categoryTitle,
    required this.categoryIcon,
    required this.categoryColor,
    required this.filledCount,
    required this.weightedTotal,
    required this.isSubmitting,
    this.onBack,
    required this.onSubmit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = categoryColor;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Icon(categoryIcon, color: color, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("$categoryTitle Scoring", style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                    Text("${criteria.length} criteria · ${criteria.fold(0.0, (s, c) => s + c.weight).toStringAsFixed(0)}% total weight",
                        style: GoogleFonts.poppins(fontSize: 11, color: color.withOpacity(0.7))),
                  ])),
                  if (onBack != null)
                    TextButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 12),
                      label: Text("Change Contestant", style: GoogleFonts.poppins(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: color),
                    ),
                ]),
              ),
              const SizedBox(height: 16),
              JudgeCurrentGroupCard(group: group, categoryColor: color, categoryIcon: categoryIcon, categoryTitle: categoryTitle),
              const SizedBox(height: 24),
              JudgeProgressRow(filled: filledCount, total: criteria.length),
              const SizedBox(height: 20),
              Text("Score Each Criteria", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("Enter a score from 0 to 100. Weighted total is computed automatically.",
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.silverRank)),
              const SizedBox(height: 16),
              ...criteria.map((c) => JudgeCriterionRow(
                criterion: c,
                controller: controllers[c.id]!,
                errorText: errors[c.id],
                accentColor: color,
                onChanged: (_) => onChanged(c.id),
              )),
              const SizedBox(height: 8),
              JudgeWeightedTotalCard(total: weightedTotal, accentColor: color),
              const SizedBox(height: 28),
              JudgeSubmitButton(
                isSubmitting: isSubmitting,
                filledCount: filledCount,
                totalCount: criteria.length,
                onSubmit: onSubmit,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CURRENT GROUP CARD
// ═══════════════════════════════════════════════════════════════════

class JudgeCurrentGroupCard extends StatelessWidget {
  final PerformingGroup group;
  final Color categoryColor;
  final IconData categoryIcon;
  final String categoryTitle;

  const JudgeCurrentGroupCard({
    super.key,
    required this.group,
    required this.categoryColor,
    required this.categoryIcon,
    required this.categoryTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [categoryColor, categoryColor.withOpacity(0.78)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: categoryColor.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: Center(child: Text("#${group.performanceOrder}", style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
        ),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.live.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
              child: Text("NOW SCORING", style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.live, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(categoryIcon, size: 11, color: Colors.white70),
                const SizedBox(width: 4),
                Text(categoryTitle, style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 6),
          Text(group.name, style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Row(children: [
            _pill(Icons.location_on_rounded, group.barangay),
            const SizedBox(width: 10),
            _pill(Icons.palette_rounded, group.theme),
          ]),
        ])),
      ]),
    );
  }

  Widget _pill(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: Colors.white54),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════
// PROGRESS ROW
// ═══════════════════════════════════════════════════════════════════

class JudgeProgressRow extends StatelessWidget {
  final int filled, total;
  const JudgeProgressRow({super.key, required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ...List.generate(total, (i) => Expanded(
        child: Container(
          height: 6,
          margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
          decoration: BoxDecoration(
            color: i < filled ? AppColors.accentGreen : const Color(0xFFE5E5EA),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      )),
      const SizedBox(width: 12),
      Text("$filled / $total", style: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: filled == total ? AppColors.accentGreen : const Color(0xFF6C6C70))),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════
// CRITERION ROW
// ═══════════════════════════════════════════════════════════════════

class JudgeCriterionRow extends StatelessWidget {
  final ActiveCriterion criterion;
  final TextEditingController controller;
  final String? errorText;
  final Color accentColor;
  final ValueChanged<String> onChanged;

  const JudgeCriterionRow({
    super.key,
    required this.criterion,
    required this.controller,
    required this.errorText,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasError ? AppColors.danger.withOpacity(0.5) : const Color(0xFFE5E5EA)),
        boxShadow: const [BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        Container(width: 42, height: 42,
          decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
          child: Icon(Icons.star_rounded, color: accentColor, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(criterion.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text("${criterion.weight.toStringAsFixed(0)}%", style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600, color: accentColor)),
            ),
          ]),
          if (criterion.description.isNotEmpty)
            Text(criterion.description, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.silverRank)),
        ])),
        const SizedBox(width: 16),
        SizedBox(
          width: 100,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [MaxValueFormatter(criterion.maxScore)],
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "0",
                hintStyle: GoogleFonts.poppins(color: const Color(0xFFAEAEB2), fontSize: 16),
                filled: true,
                fillColor: hasError ? AppColors.danger.withOpacity(0.05) : const Color(0xFFF2F2F7),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: accentColor, width: 1.5)),
              ),
            ),
            if (hasError)
              Padding(padding: const EdgeInsets.only(top: 4),
                child: Text(errorText!, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.danger)))
            else
              Padding(padding: const EdgeInsets.only(top: 4),
                child: Text("max ${criterion.maxScore.toStringAsFixed(0)}",
                  style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFAEAEB2)))),
          ]),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// WEIGHTED TOTAL CARD
// ═══════════════════════════════════════════════════════════════════

class JudgeWeightedTotalCard extends StatelessWidget {
  final double total;
  final Color accentColor;
  const JudgeWeightedTotalCard({super.key, required this.total, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final pct = (total / 100).clamp(0.0, 1.0);
    final color = total >= 80 ? AppColors.accentGreen : total >= 60 ? AppColors.warning : accentColor;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Row(children: [
          Text("Weighted Total Score", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(total.toStringAsFixed(2), style: GoogleFonts.poppins(
              fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text("/ 100", style: GoogleFonts.poppins(fontSize: 13, color: AppColors.silverRank)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct, minHeight: 8,
            backgroundColor: const Color(0xFFE5E5EA),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SUBMIT BUTTON
// ═══════════════════════════════════════════════════════════════════

class JudgeSubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final int filledCount, totalCount;
  final VoidCallback onSubmit;

  const JudgeSubmitButton({
    super.key,
    required this.isSubmitting,
    required this.filledCount,
    required this.totalCount,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final ready = filledCount == totalCount;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (ready && !isSubmitting) ? onSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ready ? AppColors.accentGreen : const Color(0xFFE5E5EA),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE5E5EA),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: ready ? 2 : 0,
        ),
        child: isSubmitting
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(ready ? Icons.check_rounded : Icons.lock_outline_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  ready ? "Submit Scores" : "Fill all criteria to submit ($filledCount/$totalCount)",
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SUCCESS STATE
// ═══════════════════════════════════════════════════════════════════

class JudgeSuccessState extends StatelessWidget {
  final PerformingGroup group;
  final List<ActiveCriterion> criteria;
  final Map<String, TextEditingController> controllers;
  final String categoryTitle;
  final IconData categoryIcon;
  final Color categoryColor;
  final double weightedTotal;
  final Set<String> scoredGroupIds;
  final VoidCallback onScoreAnother;

  const JudgeSuccessState({
    super.key,
    required this.group,
    required this.criteria,
    required this.controllers,
    required this.categoryTitle,
    required this.categoryIcon,
    required this.categoryColor,
    required this.weightedTotal,
    required this.scoredGroupIds,
    required this.onScoreAnother,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = staticGroups.where((g) => !scoredGroupIds.contains(g.id)).toList();
    final color = categoryColor;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(blurRadius: 20, color: AppColors.shadow, offset: Offset(0, 8))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(categoryIcon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(categoryTitle, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: AppColors.accentGreen.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 44),
              ),
              const SizedBox(height: 20),
              Text("Scores Submitted!", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text("Your $categoryTitle scores for ${group.name} have been recorded.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.silverRank)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  ...criteria.map((c) {
                    final val = controllers[c.id]?.text ?? "-";
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        Text(c.name, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.silverRank)),
                        const Spacer(),
                        Text("$val pts", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                    );
                  }),
                  const Divider(height: 20, color: AppColors.divider),
                  Row(children: [
                    Text("Weighted Total", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(weightedTotal.toStringAsFixed(2), style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),
              if (remaining.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.groups_rounded, size: 16, color: AppColors.secondary.withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Text("${remaining.length} contestant${remaining.length > 1 ? "s" : ""} still to score",
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w500)),
                  ]),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.accentGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.accentGreen),
                    const SizedBox(width: 8),
                    Text("All contestants scored!", style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.accentGreen, fontWeight: FontWeight.w500)),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                onPressed: onScoreAnother,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text(remaining.isNotEmpty ? "Score Another Contestant" : "Back to Contestants",
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}