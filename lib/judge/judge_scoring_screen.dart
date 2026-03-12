import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';
import 'package:pandan_fest/models/app_models.dart';
import 'package:pandan_fest/services.dart';

// ── Active judge for this session (TODO: set via login/route arg with Firebase) ──
const String _activeJudgeId = 'j1';

// ── Stage/group flow states ──
enum _JudgeScreenState { selectContestant, scoring, submitted }

// ═══════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════

class JudgeScoringScreen extends StatefulWidget {
  const JudgeScoringScreen({super.key});

  @override
  State<JudgeScoringScreen> createState() => _JudgeScoringScreenState();
}

class _JudgeScoringScreenState extends State<JudgeScoringScreen> {
  _JudgeScreenState _screenState = _JudgeScreenState.selectContestant;
  PerformingGroup? _selectedGroup;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _errors = {};
  bool _isSubmitting = false;

  // Track which groups have been scored this session
  final Set<String> _scoredGroupIds = {};

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
    for (final ctrl in _controllers.values) ctrl.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────

  AppJudge get _activeJudge => staticJudges.firstWhere(
        (j) => j.id == _activeJudgeId,
        orElse: () => const AppJudge(id: '', name: '', position: '', stageId: 's1'),
      );

  CompetitionStage get _activeStage => staticStages.firstWhere(
        (s) => s.id == _activeJudge.stageId,
        orElse: () => staticStages.first,
      );

  static const _stageColors = [Color(0xFF5856D6), Color(0xFF007AFF), Color(0xFFAF52DE)];

  Color get _stageColor => _stageColors[(_activeStage.order - 1).clamp(0, 2)];

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
      _scoredGroupIds.add(_selectedGroup!.id);
      // ── mark scoring complete for this group ──
      LiveSessionState.instance.clearActiveGroup(_activeJudge.stageId);
      _screenState = _JudgeScreenState.submitted;
    });
  }

  void _selectContestant(PerformingGroup group) {
    for (final ctrl in _controllers.values) ctrl.clear();
    for (final key in _errors.keys) _errors[key] = null;
    // ── notify Live Control Panel ──
    LiveSessionState.instance.setActiveGroup(_activeJudge.stageId, group.id);
    setState(() {
      _selectedGroup = group;
      _screenState = _JudgeScreenState.scoring;
    });
  }

  void _backToSelection() {
    // ── clear ongoing performance ──
    LiveSessionState.instance.clearActiveGroup(_activeJudge.stageId);
    setState(() {
      _selectedGroup = null;
      _screenState = _JudgeScreenState.selectContestant;
    });
  }

  void _scoreAnother() {
    for (final ctrl in _controllers.values) ctrl.clear();
    for (final key in _errors.keys) _errors[key] = null;
    // ── clear ongoing performance ──
    LiveSessionState.instance.clearActiveGroup(_activeJudge.stageId);
    setState(() {
      _selectedGroup = null;
      _screenState = _JudgeScreenState.selectContestant;
    });
  }

  // ── BUILD ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              child: KeyedSubtree(
                key: ValueKey(_screenState),
                child: switch (_screenState) {
                  _JudgeScreenState.selectContestant => _buildContestantPicker(),
                  _JudgeScreenState.scoring          => _buildScoringBody(),
                  _JudgeScreenState.submitted        => _buildSuccessState(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTopBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      child: Row(
        children: [
          // Back button (only when scoring)
          if (_screenState == _JudgeScreenState.scoring) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
              onPressed: _backToSelection,
              tooltip: 'Back to contestant list',
            ),
            const SizedBox(width: 4),
          ],

          // Logo
          ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(12),
            child: Image.asset('assets/images/PandanFestLogo.png', width: 46, height: 46),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PandanFest 2026', style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              Text(
                _screenState == _JudgeScreenState.scoring && _selectedGroup != null
                    ? 'Scoring: ${_selectedGroup!.name}'
                    : 'Judge Portal — Select Contestant',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          const Spacer(),

          // Live badge
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
              Text('LIVE', style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.live, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ]),
          ),
          const SizedBox(width: 16),

          // Judge identity + stage badge
          Row(
            children: [
              const CircleAvatar(radius: 18, backgroundColor: Colors.white24,
                  child: Icon(Icons.gavel_rounded, color: Colors.white, size: 18)),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(resolveJudgeName(_activeJudgeId), style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                Text(resolveJudgePosition(_activeJudgeId), style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.white60)),
              ]),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _stageColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _stageColor.withOpacity(0.5)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.flag_rounded, size: 12, color: Colors.white70),
                  const SizedBox(width: 5),
                  Text(_activeStage.name, style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONTESTANT PICKER
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildContestantPicker() {
    final stage = _activeStage;
    final color = _stageColor;
    final scored = _scoredGroupIds.length;
    final total = staticGroups.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stage Banner ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.flag_rounded, color: color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Judging at ${stage.name}', style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                    Text(stage.description, style: GoogleFonts.poppins(
                        fontSize: 12, color: color.withOpacity(0.7))),
                  ])),
                  // Progress pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Column(children: [
                      Text('$scored / $total', style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                      Text('Scored', style: GoogleFonts.poppins(fontSize: 10, color: color.withOpacity(0.7))),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Section title ──
              Row(children: [
                const Icon(Icons.groups_rounded, size: 18, color: Color(0xFF1C1C1E)),
                const SizedBox(width: 8),
                Text('Select Contestant to Score', style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1C1C1E))),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(20)),
                  child: Text('${staticGroups.length} contestants', style: GoogleFonts.poppins(
                      fontSize: 11, color: const Color(0xFF6C6C70))),
                ),
              ]),
              const SizedBox(height: 6),
              Text('Tap a contestant card to begin scoring. Already scored ones are marked.',
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF8E8E93))),
              const SizedBox(height: 20),

              // ── Contestant Cards ──
              ...staticGroups.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ContestantCard(
                  group: g,
                  stageColor: color,
                  isScored: _scoredGroupIds.contains(g.id),
                  onSelect: () => _selectContestant(g),
                ),
              )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SCORING BODY
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildScoringBody() {
    final group = _selectedGroup!;
    final stage = _activeStage;
    final color = _stageColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stage + back hint ──
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
                    child: Icon(Icons.flag_rounded, color: color, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Scoring at ${stage.name}', style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                    Text(stage.description, style: GoogleFonts.poppins(
                        fontSize: 11, color: color.withOpacity(0.7))),
                  ])),
                  TextButton.icon(
                    onPressed: _backToSelection,
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 12),
                    label: Text('Change Contestant', style: GoogleFonts.poppins(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: color),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // ── Selected contestant card ──
              _CurrentGroupCard(group: group),
              const SizedBox(height: 24),

              // ── Progress ──
              _ProgressRow(filled: _filledCount, total: staticCriteria.length),
              const SizedBox(height: 20),

              // ── Scoring form ──
              Text('Score Each Criteria', style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Enter a score from 0 to 100 for each criterion. Weighted total is computed automatically.',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.silverRank)),
              const SizedBox(height: 16),

              ...List.generate(staticCriteria.length, (i) {
                final c = staticCriteria[i];
                return _CriterionRow(
                  criterion: c,
                  controller: _controllers[c.id]!,
                  errorText: _errors[c.id],
                  onChanged: (_) => setState(() => _errors[c.id] = null),
                );
              }),

              const SizedBox(height: 8),
              _WeightedTotalCard(total: _weightedTotal),
              const SizedBox(height: 28),

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

  // ═══════════════════════════════════════════════════════════════════
  // SUCCESS STATE
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSuccessState() {
    final group = _selectedGroup!;
    final remaining = staticGroups.where((g) => !_scoredGroupIds.contains(g.id)).toList();

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 44),
                ),
                const SizedBox(height: 20),
                Text('Scores Submitted!', style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Your scores for ${group.name} have been recorded successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.silverRank)),
                const SizedBox(height: 24),

                // Score summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    ...staticCriteria.map((c) {
                      final val = _controllers[c.id]?.text ?? '-';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(children: [
                          Text(c.name, style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.silverRank)),
                          const Spacer(),
                          Text('$val pts', style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                        ]),
                      );
                    }),
                    const Divider(height: 20, color: AppColors.divider),
                    Row(children: [
                      Text('Weighted Total', style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(_weightedTotal.toStringAsFixed(2), style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),

                // Remaining contestants count
                if (remaining.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.groups_rounded, size: 16, color: AppColors.secondary.withOpacity(0.8)),
                      const SizedBox(width: 8),
                      Text('${remaining.length} contestant${remaining.length > 1 ? 's' : ''} still to score',
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.secondary,
                            fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.accentGreen),
                      const SizedBox(width: 8),
                      Text('All contestants scored!', style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.accentGreen, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],

                ElevatedButton.icon(
                  onPressed: _scoreAnother,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text(remaining.isNotEmpty ? 'Score Another Contestant' : 'Back to Contestants',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
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

// ═══════════════════════════════════════════════════════════════════
// CONTESTANT CARD (picker screen)
// ═══════════════════════════════════════════════════════════════════

class _ContestantCard extends StatefulWidget {
  final PerformingGroup group;
  final Color stageColor;
  final bool isScored;
  final VoidCallback onSelect;

  const _ContestantCard({
    required this.group,
    required this.stageColor,
    required this.isScored,
    required this.onSelect,
  });

  @override
  State<_ContestantCard> createState() => _ContestantCardState();
}

class _ContestantCardState extends State<_ContestantCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final scored = widget.isScored;
    final color = scored ? AppColors.accentGreen : widget.stageColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovered
                ? (scored ? AppColors.accentGreen.withOpacity(0.05) : widget.stageColor.withOpacity(0.04))
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scored
                  ? AppColors.accentGreen.withOpacity(0.4)
                  : (_hovered ? widget.stageColor.withOpacity(0.5) : const Color(0xFFE5E5EA)),
              width: scored || _hovered ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? widget.stageColor.withOpacity(0.12)
                    : Colors.black.withOpacity(0.05),
                blurRadius: _hovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Order badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Center(
                  child: Text('#${g.performanceOrder}', style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                ),
              ),
              const SizedBox(width: 18),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(g.name, style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.bold,
                            color: const Color(0xFF1C1C1E))),
                      ),
                      if (scored)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 12, color: AppColors.accentGreen),
                            const SizedBox(width: 4),
                            Text('Scored', style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: AppColors.accentGreen)),
                          ]),
                        ),
                    ]),
                    const SizedBox(height: 6),
                    Wrap(spacing: 14, children: [
                      _infoChip(Icons.location_on_outlined, g.barangay),
                      _infoChip(Icons.palette_outlined, g.theme),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Action
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: scored
                      ? AppColors.accentGreen
                      : (_hovered ? widget.stageColor : widget.stageColor.withOpacity(0.85)),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (scored ? AppColors.accentGreen : widget.stageColor).withOpacity(0.3),
                      blurRadius: 8, offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(scored ? Icons.edit_rounded : Icons.gavel_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 7),
                  Text(scored ? 'Re-score' : 'Score Now', style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: const Color(0xFF8E8E93)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8E8E93))),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════
// CURRENT GROUP CARD (scoring screen header)
// ═══════════════════════════════════════════════════════════════════

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
        boxShadow: [BoxShadow(
            color: AppColors.primary.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(child: Text('#${group.performanceOrder}', style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.live.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                child: Text('NOW SCORING', style: GoogleFonts.poppins(
                    fontSize: 10, color: AppColors.live, fontWeight: FontWeight.w700, letterSpacing: 1)),
              ),
              const SizedBox(height: 6),
              Text(group.name, style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Row(children: [
                _pill(Icons.location_on_rounded, group.barangay),
                const SizedBox(width: 10),
                _pill(Icons.palette_rounded, group.theme),
              ]),
            ]),
          ),
        ],
      ),
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

class _ProgressRow extends StatelessWidget {
  final int filled, total;
  const _ProgressRow({required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(total, (i) {
          final done = i < filled;
          return Expanded(
            child: Container(
              height: 6,
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: done ? AppColors.accentGreen : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
        const SizedBox(width: 12),
        Text('$filled / $total', style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: filled == total ? AppColors.accentGreen : const Color(0xFF6C6C70))),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CRITERION ROW
// ═══════════════════════════════════════════════════════════════════

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: hasError
                ? AppColors.danger.withOpacity(0.5)
                : const Color(0xFFE5E5EA)),
        boxShadow: const [BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
            child: Icon(Icons.star_rounded, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(criterion.name, style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('${criterion.weight.toStringAsFixed(0)}%', style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                ),
              ]),
              if (criterion.description.isNotEmpty)
                Text(criterion.description, style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.silverRank)),
            ]),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [MaxValueFormatter(criterion.maxScore)],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.poppins(color: const Color(0xFFAEAEB2), fontSize: 16),
                    filled: true,
                    fillColor: hasError
                        ? AppColors.danger.withOpacity(0.05)
                        : const Color(0xFFF2F2F7),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                    ),
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(errorText!, style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.danger)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('max ${criterion.maxScore.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFAEAEB2))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// WEIGHTED TOTAL CARD
// ═══════════════════════════════════════════════════════════════════

class _WeightedTotalCard extends StatelessWidget {
  final double total;
  const _WeightedTotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = (total / 100).clamp(0.0, 1.0);
    final color = total >= 80
        ? AppColors.accentGreen
        : total >= 60
            ? AppColors.warning
            : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Row(children: [
          Text('Weighted Total Score', style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(total.toStringAsFixed(2), style: GoogleFonts.poppins(
              fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text('/ 100', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.silverRank)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
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

class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final int filledCount, totalCount;
  final VoidCallback onSubmit;

  const _SubmitButton({
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
                  ready ? 'Submit Scores' : 'Fill all criteria to submit ($filledCount/$totalCount)',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ]),
      ),
    );
  }
}