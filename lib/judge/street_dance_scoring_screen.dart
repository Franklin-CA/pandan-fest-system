import 'package:flutter/material.dart';
import 'package:pandan_fest/models/app_models.dart';
import 'package:pandan_fest/services.dart';
import 'judge_shared_widgets.dart';

// ═══════════════════════════════════════════════════════════════════
// STREET DANCE SCORING SCREEN  —  /judge/streetdance
// ═══════════════════════════════════════════════════════════════════

class StreetDanceScoringScreen extends StatefulWidget {
  const StreetDanceScoringScreen({super.key});

  @override
  State<StreetDanceScoringScreen> createState() => _StreetDanceScoringScreenState();
}

class _StreetDanceScoringScreenState extends State<StreetDanceScoringScreen> {
  JudgeScreenState _screenState = JudgeScreenState.selectContestant;
  PerformingGroup? _selectedGroup;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _errors = {};
  bool _isSubmitting = false;
  final Set<String> _scoredGroupIds = {};

  static const String _judgeId = 'j1';
  static const Color _color = Color(0xFF5856D6);
  static const IconData _icon = Icons.music_video_rounded;
  static const String _title = "Street Dance";

  List<ActiveCriterion> get _criteria => streetDanceCriteria;

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
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) ctrl.dispose();
    super.dispose();
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
      _scoredGroupIds.add(_selectedGroup!.id);
      LiveSessionState.instance.clearActiveGroup(_activeJudge.stageId);
      _screenState = JudgeScreenState.submitted;
    });
  }

  void _selectContestant(PerformingGroup group) {
    for (final ctrl in _controllers.values) ctrl.clear();
    for (final key in _errors.keys) _errors[key] = null;
    LiveSessionState.instance.setActiveGroup(_activeJudge.stageId, group.id);
    setState(() {
      _selectedGroup = group;
      _screenState = JudgeScreenState.scoring;
    });
  }

  void _backToSelection() {
    LiveSessionState.instance.clearActiveGroup(_activeJudge.stageId);
    setState(() {
      _selectedGroup = null;
      _screenState = JudgeScreenState.selectContestant;
    });
  }

  void _scoreAnother() {
    for (final ctrl in _controllers.values) ctrl.clear();
    for (final key in _errors.keys) _errors[key] = null;
    LiveSessionState.instance.clearActiveGroup(_activeJudge.stageId);
    setState(() {
      _selectedGroup = null;
      _screenState = JudgeScreenState.selectContestant;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            onBack: _screenState == JudgeScreenState.scoring ? _backToSelection : null,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              child: KeyedSubtree(
                key: ValueKey(_screenState),
                child: switch (_screenState) {
                  JudgeScreenState.selectContestant => JudgeContestantPicker(
                      categoryTitle: _title,
                      categoryIcon: _icon,
                      categoryColor: _color,
                      criteria: _criteria,
                      scoredGroupIds: _scoredGroupIds,
                      onSelect: _selectContestant,
                    ),
                  JudgeScreenState.scoring => JudgeScoringBody(
                      group: _selectedGroup!,
                      criteria: _criteria,
                      controllers: _controllers,
                      errors: _errors,
                      categoryTitle: _title,
                      categoryIcon: _icon,
                      categoryColor: _color,
                      filledCount: _filledCount,
                      weightedTotal: _weightedTotal,
                      isSubmitting: _isSubmitting,
                      onBack: _backToSelection,
                      onSubmit: _submitScores,
                      onChanged: (id) => setState(() => _errors[id] = null),
                    ),
                  JudgeScreenState.submitted => JudgeSuccessState(
                      group: _selectedGroup!,
                      criteria: _criteria,
                      controllers: _controllers,
                      categoryTitle: _title,
                      categoryIcon: _icon,
                      categoryColor: _color,
                      weightedTotal: _weightedTotal,
                      scoredGroupIds: _scoredGroupIds,
                      onScoreAnother: _scoreAnother,
                    ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}