import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';
import 'package:pandan_fest/models/app_models.dart';
import 'package:pandan_fest/services.dart';

// ── Active judge for this session (TODO: set via login/route arg with Firebase) ──
// Change 'j1' to whichever judge is logged in.
const String _activeJudgeId = 'j1';

// ================= MAIN SCREEN =================

class JudgeScoringScreen extends StatefulWidget {
  const JudgeScoringScreen({super.key});

  @override
  State<JudgeScoringScreen> createState() => _JudgeScoringScreenState();
}

class _JudgeScoringScreenState extends State<JudgeScoringScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _errors = {};
  bool _isSubmitted = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (final c in staticCriteria) {
      _controllers[c.id] = TextEditingController();
      _errors[c.id] = null;
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ── Computed weighted total ──
  double get _weightedTotal {
    double total = 0;
    for (final c in staticCriteria) {
      final val = double.tryParse(_controllers[c.id]?.text ?? '');
      if (val != null) {
        total += val * c.weight / 100;
      }
    }
    return total;
  }

  int get _filledCount => staticCriteria
      .where((c) => _controllers[c.id]?.text.trim().isNotEmpty == true)
      .length;

  bool _validate() {
    bool valid = true;
    setState(() {
      for (final c in staticCriteria) {
        final text = _controllers[c.id]?.text.trim() ?? '';
        if (text.isEmpty) {
          _errors[c.id] = 'Required';
          valid = false;
        } else {
          final val = double.tryParse(text);
          if (val == null) {
            _errors[c.id] = 'Must be a number';
            valid = false;
          } else if (val < 0 || val > c.maxScore) {
            _errors[c.id] = 'Enter 0 – ${c.maxScore.toStringAsFixed(0)}';
            valid = false;
          } else {
            _errors[c.id] = null;
          }
        }
      }
    });
    return valid;
  }

  Future<void> _submitScores() async {
    if (!_validate()) return;
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    setState(() {
      _isSubmitting = false;
      _isSubmitted = true;
    });
  }

  void _resetForm() {
    setState(() {
      for (final ctrl in _controllers.values) {
        ctrl.clear();
      }
      for (final key in _errors.keys) {
        _errors[key] = null;
      }
      _isSubmitted = false;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _isSubmitted ? _buildSuccessState() : _buildScoringBody(),
          ),
        ],
      ),
    );
  }

  // ================= TOP BAR =================

  Widget _buildTopBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      child: Row(
        children: [
          // Logo area
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(12),
                child: Image.asset(
                  "assets/images/PandanFestLogo.png",
                  width: 50,
                  height: 50,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PandanFest 2026",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Street Dance Competition — Judge Portal",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),

          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.live.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.live.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.live,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "LIVE",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.live,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Judge identity
          PopupMenuButton<String>(
            tooltip: "Sign Out",
            color: AppColors.surface,
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: AppColors.danger,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Log Out",
                      style: GoogleFonts.poppins(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.gavel_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolveJudgeName(_activeJudgeId),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      resolveJudgePosition(_activeJudgeId),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= SCORING BODY =================

  Widget _buildScoringBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Currently Performing Group Card ──
              _CurrentGroupCard(group: staticGroups.first),
              const SizedBox(height: 24),

              // ── Progress indicator ──
              _ProgressRow(filled: _filledCount, total: staticCriteria.length),
              const SizedBox(height: 20),

              // ── Scoring Form ──
              Text(
                "Score Each Criteria",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Enter a score from 0 to 100 for each criterion. "
                "Weighted total is computed automatically.",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.silverRank,
                ),
              ),
              const SizedBox(height: 16),

              // Criterion rows
              ...List.generate(staticCriteria.length, (i) {
                final c = staticCriteria[i];
                return _CriterionRow(
                  criterion: c,
                  controller: _controllers[c.id]!,
                  errorText: _errors[c.id],
                  onChanged: (_) => setState(() {
                    _errors[c.id] = null;
                  }),
                );
              }),

              const SizedBox(height: 8),

              // ── Weighted Total Bar ──
              _WeightedTotalCard(total: _weightedTotal),
              const SizedBox(height: 28),

              // ── Submit Button ──
              _SubmitButton(
                isSubmitting: _isSubmitting,
                filledCount: _filledCount,
                totalCount: staticCriteria.length,
                onSubmit: _submitScores,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ================= SUCCESS STATE =================

  Widget _buildSuccessState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          margin: const EdgeInsets.all(30),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                blurRadius: 20,
                color: AppColors.shadow,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accentGreen,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Scores Submitted!",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your scores for ${staticGroups.first.name} have been\nrecorded successfully.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.silverRank,
                  ),
                ),
                const SizedBox(height: 24),

                // Score summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ...staticCriteria.map((c) {
                        final val = _controllers[c.id]?.text ?? '-';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Text(
                                c.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.silverRank,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "$val pts",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 20, color: AppColors.divider),
                      Row(
                        children: [
                          Text(
                            "Weighted Total",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _weightedTotal.toStringAsFixed(2),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Waiting for the next group from admin...",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.silverRank,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    "Score Another Group",
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= CURRENT GROUP CARD =================

class _CurrentGroupCard extends StatelessWidget {
  final PerformingGroup group;
  const _CurrentGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Order badge
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "#${group.performanceOrder}",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),

          // Group details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.live.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "NOW PERFORMING",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.live,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  group.name,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white60,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      group.barangay,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.palette_outlined,
                      color: Colors.white60,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      group.theme,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Icon(Icons.groups_rounded, color: Colors.white24, size: 52),
        ],
      ),
    );
  }
}

// ================= PROGRESS ROW =================

class _ProgressRow extends StatelessWidget {
  final int filled;
  final int total;
  const _ProgressRow({required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : filled / total,
              minHeight: 7,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentGreen,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "$filled / $total criteria filled",
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.silverRank),
        ),
      ],
    );
  }
}

// ================= CRITERION ROW =================

class _CriterionRow extends StatelessWidget {
  final ActiveCriterion criterion;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _CriterionRow({
    required this.criterion,
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? AppColors.danger.withOpacity(0.5)
              : AppColors.divider,
          width: hasError ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: AppColors.shadow,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: name + description + weight badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      criterion.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${criterion.weight.toStringAsFixed(0)}%",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  criterion.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.silverRank,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Right: score input
          SizedBox(
            width: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  cursorColor: AppColors.primary,
                  controller: controller,
                  onChanged: onChanged,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    LengthLimitingTextInputFormatter(3),
                    MaxValueFormatter(criterion.maxScore),
                  ],
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: hasError ? AppColors.danger : AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: "0",
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.divider,
                    ),
                    filled: true,
                    fillColor: hasError
                        ? AppColors.danger.withOpacity(0.05)
                        : AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors.secondary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (hasError)
                  Text(
                    errorText!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.danger,
                    ),
                  )
                else
                  Text(
                    "Max: ${criterion.maxScore.toStringAsFixed(0)}",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.silverRank,
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

// ================= WEIGHTED TOTAL CARD =================

class _WeightedTotalCard extends StatelessWidget {
  final double total;
  const _WeightedTotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: AppColors.shadow,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_rounded, color: AppColors.secondary, size: 22),
          const SizedBox(width: 12),
          Text(
            "Weighted Total Score",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          Text(
            total.toStringAsFixed(2),
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "/ 100",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.silverRank,
            ),
          ),
        ],
      ),
    );
  }
}

// ================= SUBMIT BUTTON =================

class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final int filledCount;
  final int totalCount;
  final VoidCallback onSubmit;

  const _SubmitButton({
    required this.isSubmitting,
    required this.filledCount,
    required this.totalCount,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = filledCount == totalCount;

    return GestureDetector(
      onTap: isSubmitting ? null : onSubmit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSubmitting
              ? AppColors.primary.withOpacity(0.7)
              : isReady
              ? AppColors.primary
              : AppColors.divider,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isReady && !isSubmitting
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Submitting...",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.send_rounded,
                      color: isReady ? Colors.white : AppColors.silverRank,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isReady
                          ? "Submit Scores"
                          : "Fill all criteria to submit  ($filledCount/$totalCount)",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isReady ? Colors.white : AppColors.silverRank,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
