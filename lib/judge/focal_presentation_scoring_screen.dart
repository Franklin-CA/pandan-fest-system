import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/models/app_models.dart';
import 'package:pandan_fest/services.dart';
import 'judge_shared_widgets.dart';

// ═══════════════════════════════════════════════════════════════════
// FOCAL PRESENTATION SCORING SCREEN  —  /judge/focal
// Admin push → directly opens scoring form for that contestant.
// No contestant picker shown.
// ═══════════════════════════════════════════════════════════════════

class FocalPresentationScoringScreen extends StatefulWidget {
  const FocalPresentationScoringScreen({super.key});

  @override
  State<FocalPresentationScoringScreen> createState() => _FocalPresentationScoringScreenState();
}

class _FocalPresentationScoringScreenState extends State<FocalPresentationScoringScreen> {
  // Only two states: scoring or submitted. No selectContestant step.
  bool _isScoring = false;
  bool _isSubmitted = false;
  PerformingGroup? _activeGroup;
  String? _lastPushedGroupId; // track which group we already auto-loaded

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _errors = {};
  bool _isSubmitting = false;
  final Set<String> _scoredGroupIds = {};

  static const String _judgeId = 'j1';
  static const Color _color = Color(0xFFFF2D55);
  static const IconData _icon = Icons.star_rounded;
  static const String _title = "Focal Presentation";

  List<ActiveCriterion> get _criteria => focalPresentationCriteria;

  AppJudge get _activeJudge => staticJudges.firstWhere(
        (j) => j.id == _judgeId,
        orElse: () => const AppJudge(id: "", name: "", position: "", stageId: "s1"),
      );

  CompetitionStage get _activeStage => staticStages.firstWhere(
        (s) => s.id == _activeJudge.stageId,
        orElse: () => staticStages.first,
      );

  static const _stageColors = [Color(0xFF5856D6), Color(0xFF007AFF), Color(0xFFAF52DE)];
  Color get _stageColor => _stageColors[(_activeStage.order - 1).clamp(0, 2)];

  @override
  void initState() {
    super.initState();
    for (final c in _criteria) {
      _controllers[c.id] = TextEditingController();
      _errors[c.id] = null;
    }
    // Listen to live state changes (cross-tab admin push)
    LiveSessionState.instance.addListener(_onLiveStateChanged);
  }

  @override
  void dispose() {
    LiveSessionState.instance.removeListener(_onLiveStateChanged);
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  /// Called whenever LiveSessionState notifies (every 500ms poll or immediate write).
  /// Auto-loads the pushed contestant into scoring mode.
  void _onLiveStateChanged() {
    final pushedId = LiveSessionState.instance.pushedFocalGroupId;

    // New push arrived — load it directly into scoring
    if (pushedId != null && pushedId != _lastPushedGroupId) {
      _lastPushedGroupId = pushedId;
      final group = staticGroups.firstWhere(
        (g) => g.id == pushedId,
        orElse: () => staticGroups.first,
      );
      _loadGroupForScoring(group);
    }

    // Push was cleared (admin reset) — go back to waiting
    if (pushedId == null && _lastPushedGroupId != null) {
      _lastPushedGroupId = null;
      setState(() {
        _isScoring = false;
        _isSubmitted = false;
        _activeGroup = null;
      });
    }
  }

  void _loadGroupForScoring(PerformingGroup group) {
    // Reset fields for new contestant
    for (final ctrl in _controllers.values) {
      ctrl.clear();
    }
    for (final key in _errors.keys) {
      _errors[key] = null;
    }
    LiveSessionState.instance.setActiveGroup(_activeJudge.stageId, group.id);
    setState(() {
      _activeGroup = group;
      _isScoring = true;
      _isSubmitted = false;
    });
  }

  double get _weightedTotal {
    double total = 0;
    for (final c in _criteria) {
      final val = double.tryParse(_controllers[c.id]?.text ?? "");
      if (val != null) total += val * c.weight / 100;
    }
    return total;
  }

  int get _filledCount =>
      _criteria.where((c) => _controllers[c.id]?.text.trim().isNotEmpty == true).length;

  bool _validate() {
    bool valid = true;
    setState(() {
      for (final c in _criteria) {
        final text = _controllers[c.id]?.text.trim() ?? "";
        if (text.isEmpty) {
          _errors[c.id] = "Required"; valid = false;
        } else {
          final val = double.tryParse(text);
          if (val == null) {
            _errors[c.id] = "Must be a number"; valid = false;
          } else if (val < 0 || val > c.maxScore) {
            _errors[c.id] = "Enter 0 - ${c.maxScore.toStringAsFixed(0)}"; valid = false;
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
      _scoredGroupIds.add(_activeGroup!.id);
      LiveSessionState.instance.clearActiveGroup(_activeJudge.stageId);
      _isScoring = false;
      _isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiveSessionState.instance,
      builder: (context, _) {
        final pushedGroupId = LiveSessionState.instance.pushedFocalGroupId;

        Widget body;
        if (pushedGroupId == null) {
          body = _WaitingForAdminPush(categoryColor: _color);
        } else if (_isSubmitted && _activeGroup != null) {
          body = JudgeSuccessState(
            group: _activeGroup!,
            criteria: _criteria,
            controllers: _controllers,
            categoryTitle: _title,
            categoryIcon: _icon,
            categoryColor: _color,
            weightedTotal: _weightedTotal,
            scoredGroupIds: _scoredGroupIds,
            onScoreAnother: () {
              // Wait for next admin push — go back to waiting
              setState(() {
                _isSubmitted = false;
                _isScoring = false;
                _activeGroup = null;
                _lastPushedGroupId = null;
              });
            },
          );
        } else if (_isScoring && _activeGroup != null) {
          body = JudgeScoringBody(
            group: _activeGroup!,
            criteria: _criteria,
            controllers: _controllers,
            errors: _errors,
            categoryTitle: _title,
            categoryIcon: _icon,
            categoryColor: _color,
            filledCount: _filledCount,
            weightedTotal: _weightedTotal,
            isSubmitting: _isSubmitting,
            onBack: null, // no back button — admin controls flow
            onSubmit: _submitScores,
            onChanged: (id) => setState(() => _errors[id] = null),
          );
        } else {
          // pushedGroupId is set but _onLiveStateChanged hasn't fired yet
          // (edge case: first load after push already in storage)
          final group = staticGroups.firstWhere(
            (g) => g.id == pushedGroupId,
            orElse: () => staticGroups.first,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadGroupForScoring(group));
          body = const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F9),
          body: Column(
            children: [
              JudgeTopBar(
                judgeId: _judgeId,
                stage: _activeStage,
                stageColor: _stageColor,
                categoryTitle: _title,
                categoryIcon: _icon,
                categoryColor: _color,
                onBack: null, // admin controls which contestant to score
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  child: KeyedSubtree(
                    key: ValueKey('$pushedGroupId-$_isScoring-$_isSubmitted'),
                    child: body,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// WAITING FOR ADMIN PUSH
// ═══════════════════════════════════════════════════════════════════

class _WaitingForAdminPush extends StatefulWidget {
  final Color categoryColor;
  const _WaitingForAdminPush({required this.categoryColor});

  @override
  State<_WaitingForAdminPush> createState() => _WaitingForAdminPushState();
}

class _WaitingForAdminPushState extends State<_WaitingForAdminPush>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.categoryColor;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Opacity(
              opacity: _anim.value,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 2),
                ),
                child: Icon(Icons.wifi_tethering_rounded, size: 40, color: color),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "Waiting for Admin",
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1C1C1E)),
          ),
          const SizedBox(height: 10),
          Text(
            "The admin will push a contestant\nto begin scoring.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF8E8E93), height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_rounded, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                "Focal Presentation — Locked",
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: color),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}