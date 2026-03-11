import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';
import 'package:pandan_fest/models/app_models.dart';
import 'package:pandan_fest/services.dart';

// ── Active judge for this session (TODO: set via login/route arg with Firebase) ──
const String _activeJudgeId = 'j1';

// ── Pandan Festival color palette ────────────────────────────────────────────
class _PF {
  // Deep forest greens inspired by pandan leaves
  static const Color forest = Color(0xFF1B4332);
  static const Color leaf = Color(0xFF2D6A4F);
  static const Color mint = Color(0xFF40916C);
  static const Color sage = Color(0xFF52B788);
  static const Color pale = Color(0xFFD8F3DC);
  static const Color paleLight = Color(0xFFEEFBF1);

  // Gold/amber for festive accents
  static const Color gold = Color(0xFFE9A319);
  static const Color goldLight = Color(0xFFFFF3CD);
  static const Color amber = Color(0xFFF4A261);

  // Neutrals
  static const Color ink = Color(0xFF0D1F14);
  static const Color muted = Color(0xFF6B8F71);
  static const Color border = Color(0xFFB7E4C7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF5FBF6);

  // Status
  static const Color danger = Color(0xFFE63946);
  static const Color live = Color(0xFF38B000);
}

// ── Pandan leaf decorative painter ───────────────────────────────────────────
class _LeafPatternPainter extends CustomPainter {
  final Color color;
  const _LeafPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw subtle diagonal leaf shapes in the background
    final path1 = Path()
      ..moveTo(size.width * 0.85, 0)
      ..quadraticBezierTo(
        size.width * 0.95,
        size.height * 0.3,
        size.width,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.92,
        size.height * 0.4,
        size.width * 0.78,
        0,
      )
      ..close();
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(size.width * 0.7, 0)
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.25,
        size.width * 0.88,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.3,
        size.width * 0.62,
        0,
      )
      ..close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= MAIN SCREEN =================

class JudgeScoringScreen extends StatefulWidget {
  const JudgeScoringScreen({super.key});

  @override
  State<JudgeScoringScreen> createState() => _JudgeScoringScreenState();
}

class _JudgeScoringScreenState extends State<JudgeScoringScreen>
    with TickerProviderStateMixin {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _errors = {};
  bool _isSubmitted = false;
  bool _isSubmitting = false;

  late final AnimationController _livePulse;
  late final AnimationController _submitAnim;
  late final Animation<double> _submitScale;

  @override
  void initState() {
    super.initState();
    for (final c in staticCriteria) {
      _controllers[c.id] = TextEditingController();
      _errors[c.id] = null;
    }
    _livePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _submitAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _submitScale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _submitAnim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) ctrl.dispose();
    _livePulse.dispose();
    _submitAnim.dispose();
    super.dispose();
  }

  double get _weightedTotal {
    double total = 0;
    for (final c in staticCriteria) {
      final val = double.tryParse(_controllers[c.id]?.text ?? '');
      if (val != null) total += val * c.weight / 100;
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
            _errors[c.id] = '0 – ${c.maxScore.toStringAsFixed(0)}';
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
    _submitAnim.forward().then((_) => _submitAnim.reverse());
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1600));
    setState(() {
      _isSubmitting = false;
      _isSubmitted = true;
    });
  }

  void _resetForm() {
    setState(() {
      for (final ctrl in _controllers.values) ctrl.clear();
      for (final key in _errors.keys) _errors[key] = null;
      _isSubmitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PF.bg,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_PF.forest, _PF.leaf],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative leaf pattern top-right
          Positioned.fill(
            child: CustomPaint(
              painter: _LeafPatternPainter(
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            child: Row(
              children: [
                // Logo + title
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _PF.gold.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          "assets/images/PandanFestLogo.png",
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "PandanFest",
                              style: GoogleFonts.playfairDisplay(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _PF.gold.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _PF.gold.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "2026",
                                style: GoogleFonts.dmMono(
                                  fontSize: 11,
                                  color: _PF.gold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Mapandan, Pangasinan  ·  Judge Portal",
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),

                // Live badge
                AnimatedBuilder(
                  animation: _livePulse,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _PF.live.withOpacity(
                        0.1 + 0.08 * _livePulse.value,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _PF.live.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _PF.live.withOpacity(
                              0.7 + 0.3 * _livePulse.value,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "LIVE",
                          style: GoogleFonts.dmMono(
                            fontSize: 11,
                            color: _PF.live,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Judge identity
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_PF.gold, _PF.amber],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resolveJudgeName(_activeJudgeId),
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            resolveJudgePosition(_activeJudgeId),
                            style: GoogleFonts.dmSans(
                              fontSize: 10.5,
                              color: Colors.white.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CurrentGroupCard(group: staticGroups.first),
              const SizedBox(height: 20),
              _ProgressRow(filled: _filledCount, total: staticCriteria.length),
              const SizedBox(height: 24),

              // Section header
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _PF.leaf,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Score Each Criterion",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: _PF.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  "Enter a score for each criterion. Weighted total is computed live.",
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: const Color(0xFF3D5A42),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              ...List.generate(staticCriteria.length, (i) {
                final c = staticCriteria[i];
                return _CriterionRow(
                  criterion: c,
                  index: i,
                  controller: _controllers[c.id]!,
                  errorText: _errors[c.id],
                  onChanged: (_) => setState(() => _errors[c.id] = null),
                );
              }),

              const SizedBox(height: 10),
              _WeightedTotalCard(total: _weightedTotal),
              const SizedBox(height: 28),

              ScaleTransition(
                scale: _submitScale,
                child: _SubmitButton(
                  isSubmitting: _isSubmitting,
                  filledCount: _filledCount,
                  totalCount: staticCriteria.length,
                  onSubmit: _submitScores,
                ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: BoxDecoration(
              color: _PF.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  blurRadius: 40,
                  color: _PF.leaf.withOpacity(0.14),
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Green header banner ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D2B1D), _PF.forest, _PF.leaf],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _PF.gold.withOpacity(0.6),
                              width: 2.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Scores Submitted!",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            staticGroups.first.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Score breakdown ──
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _PF.bg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _PF.border, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              ...staticCriteria.map((c) {
                                final val = _controllers[c.id]?.text ?? '-';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 9,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _PF.sage,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          c.name,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 15,
                                            color: _PF.ink,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _PF.pale,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: _PF.sage.withOpacity(0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          "$val pts",
                                          style: GoogleFonts.dmMono(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _PF.forest,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              Divider(
                                color: _PF.border,
                                height: 1,
                                thickness: 1.5,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    "Weighted Total",
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: _PF.ink,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0D2B1D), _PF.leaf],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _PF.forest.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _weightedTotal.toStringAsFixed(2),
                                      style: GoogleFonts.dmMono(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(
                              Icons.hourglass_top_rounded,
                              size: 15,
                              color: _PF.muted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Waiting for the next group from admin...",
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: _PF.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _resetForm,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(
                              "Score Another Group",
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _PF.leaf,
                              side: BorderSide(
                                color: _PF.leaf.withOpacity(0.5),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _PF.forest.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Full solid dark-green background — no more fading to light
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D2B1D),
                    Color(0xFF1B4332),
                    Color(0xFF14532D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Leaf pattern overlay — slightly brighter
            Positioned.fill(
              child: CustomPaint(
                painter: _LeafPatternPainter(
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),

            // Gold top border accent — thicker for impact
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_PF.gold, _PF.amber, _PF.gold],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Order number badge — larger, bolder
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_PF.gold, Color(0xFFD4880A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _PF.gold.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "#${group.performanceOrder}",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),

                  // Group details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NOW PERFORMING pill — brighter green
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _PF.live.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _PF.live.withOpacity(0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _PF.live,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                "NOW PERFORMING",
                                style: GoogleFonts.dmMono(
                                  fontSize: 11,
                                  color: _PF.live,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Group name — large and fully white
                        Text(
                          group.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Info chips — fully opaque, gold-tinted
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.location_on_rounded,
                              label: group.barangay,
                            ),
                            const SizedBox(width: 10),
                            _InfoChip(
                              icon: Icons.auto_awesome_rounded,
                              label: group.theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Decorative icon — slightly more visible
                  Icon(
                    Icons.groups_rounded,
                    color: Colors.white.withOpacity(0.18),
                    size: 72,
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _PF.gold, size: 15),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
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
    final progress = total == 0 ? 0.0 : filled / total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _PF.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PF.border),
      ),
      child: Row(
        children: [
          Icon(Icons.checklist_rounded, color: _PF.sage, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "$filled of $total criteria filled",
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: _PF.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${(progress * 100).toStringAsFixed(0)}%",
                      style: GoogleFonts.dmMono(
                        fontSize: 14,
                        color: _PF.forest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: _PF.pale,
                    valueColor: const AlwaysStoppedAnimation<Color>(_PF.sage),
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

// ================= CRITERION ROW =================

class _CriterionRow extends StatelessWidget {
  final ActiveCriterion criterion;
  final int index;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _CriterionRow({
    required this.criterion,
    required this.index,
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final accentColor = hasError ? _PF.danger : _PF.leaf;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _PF.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? _PF.danger.withOpacity(0.4) : _PF.border,
          width: hasError ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: _PF.leaf.withOpacity(0.05),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color accent stripe with index
            Container(
              width: 48,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                border: Border(
                  right: BorderSide(
                    color: accentColor.withOpacity(0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  "${index + 1}",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: accentColor.withOpacity(0.5),
                  ),
                ),
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Criterion info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  criterion.name,
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    color: _PF.ink,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _PF.pale,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _PF.sage.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  "${criterion.weight.toStringAsFixed(0)}% weight",
                                  style: GoogleFonts.dmMono(
                                    fontSize: 13,
                                    color: _PF.forest,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            criterion.description,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: const Color(0xFF3D5A42),
                              height: 1.55,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Score input
                    SizedBox(
                      width: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            cursorColor: _PF.leaf,
                            controller: controller,
                            onChanged: onChanged,
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                              LengthLimitingTextInputFormatter(3),
                              MaxValueFormatter(criterion.maxScore),
                            ],
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: hasError ? _PF.danger : _PF.forest,
                            ),
                            decoration: InputDecoration(
                              hintText: "—",
                              hintStyle: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: _PF.border,
                              ),
                              filled: true,
                              fillColor: hasError
                                  ? _PF.danger.withOpacity(0.05)
                                  : _PF.paleLight,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _PF.sage,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          if (hasError)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 13,
                                  color: _PF.danger,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  errorText!,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: _PF.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              "Max: ${criterion.maxScore.toStringAsFixed(0)}",
                              style: GoogleFonts.dmMono(
                                fontSize: 13,
                                color: _PF.leaf,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
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

// ================= WEIGHTED TOTAL CARD =================

class _WeightedTotalCard extends StatelessWidget {
  final double total;
  const _WeightedTotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    // Grade color based on score
    final Color scoreColor = total >= 85
        ? _PF.live
        : total >= 70
        ? _PF.gold
        : total > 0
        ? _PF.amber
        : _PF.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: _PF.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PF.leaf.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: _PF.leaf.withOpacity(0.08),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _PF.pale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calculate_rounded,
              color: _PF.leaf,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Weighted Total Score",
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _PF.ink,
                ),
              ),
              Text(
                "Computed live from all criteria",
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: _PF.leaf,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: scoreColor,
            ),
            child: Text(total.toStringAsFixed(2)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 8),
            child: Text(
              "/ 100",
              style: GoogleFonts.dmSans(fontSize: 13, color: _PF.muted),
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
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isReady && !isSubmitting
              ? const LinearGradient(
                  colors: [_PF.forest, _PF.mint],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isReady && !isSubmitting ? null : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isReady && !isSubmitting
              ? [
                  BoxShadow(
                    color: _PF.forest.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      "Submitting scores...",
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isReady ? Icons.send_rounded : Icons.lock_outline_rounded,
                      color: isReady ? Colors.white : const Color(0xFF94A3B8),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isReady
                          ? "Submit Scores"
                          : "Fill all criteria to submit  ($filledCount / $totalCount)",
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isReady ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
