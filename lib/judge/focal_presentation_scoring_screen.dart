import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';
import 'package:pandan_fest/models/app_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pandan_fest/services.dart';
import 'judge_shared_widgets.dart' hide JudgeScoreService;

// ═══════════════════════════════════════════════════════════════════
// FOCAL PRESENTATION SCORING SCREEN
//
// Changes from original:
//   1. Live timer shown between group card and criteria.
//   2. Scored key is now "{groupId}_{stationId}" consistent with
//      StreetDance so the same judge can't re-score the same focal
//      group at the same station.
//   3. "Already Scored" screen replaces the form if judge already
//      submitted for this group+station combo.
//   4. Lock resets once all groups have been scored at this station.
// ═══════════════════════════════════════════════════════════════════

class FocalPresentationScoringScreen extends StatefulWidget {
  const FocalPresentationScoringScreen({super.key});

  @override
  State<FocalPresentationScoringScreen> createState() =>
      _FocalPresentationScoringScreenState();
}

class _FocalPresentationScoringScreenState
    extends State<FocalPresentationScoringScreen> {
  // ── services ──────────────────────────────────────────────────
  final _service = JudgeScoreService();
  final _auth = FirebaseAuth.instance;

  // ── screen state ──────────────────────────────────────────────
  _FocalState _state = _FocalState.waiting;
  PerformingGroup? _activeGroup;

  // ── form state ────────────────────────────────────────────────
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _errors = {};
  bool _isSubmitting = false;

  // ── Firestore live data ───────────────────────────────────────
  List<PerformingGroup> _groups = [];

  // ── session data from Firestore ───────────────────────────────
  String? _pushedGroupId;
  String? _lastLoadedGroupId;
  String? _currentStationId;
  String? _currentStationName;
  List<String> _activeCriteriaIds = [];

  // ── timer state ───────────────────────────────────────────────
  int _timerElapsed = 0;
  bool _timerRunning = false;
  Timer? _localTick;

  // ── judge identity ────────────────────────────────────────────
  String get _judgeEmail =>
      _auth.currentUser?.email ?? 'unknown@pandanfest.com';

  // ── scored keys: "{groupId}_{stationId}" ─────────────────────
  final Set<String> _scoredKeys = {};

  // ── subscriptions ────────────────────────────────────────────
  StreamSubscription? _groupsSub;
  StreamSubscription? _sessionSub;

  // ── category config ───────────────────────────────────────────
  static const Color _color = Color(0xFFFF2D55);
  static const IconData _icon = Icons.star_rounded;
  static const String _title = 'Focal Presentation';

  List<ActiveCriterion> get _criteria {
    if (_activeCriteriaIds.isEmpty) return focalPresentationCriteria;
    return focalPresentationCriteria
        .where((c) => _activeCriteriaIds.contains(c.id))
        .toList();
  }

  CompetitionStage get _activeStage => staticStages.first;
  Color get _stageColor => const Color(0xFFFF2D55);

  double get _weightedTotal {
    double total = 0;
    for (final c in _criteria) {
      final val = double.tryParse(_controllers[c.id]?.text ?? '');
      if (val != null) total += val * c.weight / 100;
    }
    return total;
  }

  int get _filledCount => _criteria
      .where((c) => _controllers[c.id]?.text.trim().isNotEmpty == true)
      .length;

  // ══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _initControllers(focalPresentationCriteria);
    _listenGroups();
    _listenSession();
    _loadScoredKeys();
  }

  @override
  void dispose() {
    _groupsSub?.cancel();
    _sessionSub?.cancel();
    _localTick?.cancel();
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  void _initControllers(List<ActiveCriterion> criteria) {
    for (final c in criteria) {
      _controllers[c.id] = TextEditingController();
      _errors[c.id] = null;
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  FIRESTORE LISTENERS
  // ══════════════════════════════════════════════════════════════

  void _listenGroups() {
    _groupsSub = _service.groupsStream().listen((groups) {
      setState(() => _groups = groups);

      // Race condition fix: session fired before groups loaded
      if (_pushedGroupId != null &&
          _lastLoadedGroupId != _pushedGroupId &&
          _state == _FocalState.waiting) {
        final match = groups.firstWhere(
          (g) => g.id == _pushedGroupId,
          orElse: () => _kDummyGroup,
        );
        if (match.id.isNotEmpty) {
          _lastLoadedGroupId = _pushedGroupId;
          _loadGroupForScoring(match);
        }
      }
    });
  }

  void _listenSession() {
    _sessionSub = _service.sessionStream().listen((snap) {
      if (!snap.exists) return;
      final d = snap.data()!;
      final isPushed = d['isPushed'] as bool? ?? false;
      final pushedGroupId = d['groupId'] as String?;
      final timerPreset = d['timerPreset'] as String? ?? 'streetDance';
      final rawIds = d['criteriaIds'];
      final stationId = d['stationId'] as String?;
      final stationName = d['stationName'] as String?;

      // ── Timer sync ──────────────────────────────────────────
      final serverElapsed = d['timerElapsed'] as int? ?? 0;
      final serverRunning = d['timerRunning'] as bool? ?? false;
      _syncTimer(serverElapsed, serverRunning);

      // ── Only react to focal pushes ──────────────────────────
      if (isPushed && timerPreset != 'focalPresentation') return;

      setState(() {
        _activeCriteriaIds = rawIds != null ? List<String>.from(rawIds) : [];
        _currentStationId = stationId;
        _currentStationName = stationName;
      });

      if (isPushed && pushedGroupId != null) {
        setState(() => _pushedGroupId = pushedGroupId);

        if (pushedGroupId != _lastLoadedGroupId) {
          _lastLoadedGroupId = pushedGroupId;

          final group = _groups.firstWhere(
            (g) => g.id == pushedGroupId,
            orElse: () => _kDummyGroup,
          );

          if (group.id.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _loadGroupForScoring(group),
            );
          }
        }
      } else {
        // Admin reset
        setState(() {
          _pushedGroupId = null;
          _lastLoadedGroupId = null;
          _state = _FocalState.waiting;
          _activeGroup = null;
        });
      }
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  TIMER SYNC
  // ══════════════════════════════════════════════════════════════

  void _syncTimer(int serverElapsed, bool serverRunning) {
    setState(() {
      _timerElapsed = serverElapsed;
      _timerRunning = serverRunning;
    });
    if (serverRunning) {
      _startLocalTick();
    } else {
      _stopLocalTick();
    }
  }

  void _startLocalTick() {
    if (_localTick != null) return;
    _localTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timerElapsed++);
    });
  }

  void _stopLocalTick() {
    _localTick?.cancel();
    _localTick = null;
  }

  String get _timerDisplay {
    final m = _timerElapsed ~/ 60;
    final s = _timerElapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ══════════════════════════════════════════════════════════════
  //  SCORED KEYS
  // ══════════════════════════════════════════════════════════════

  Future<void> _loadScoredKeys() async {
    try {
      final keys = await _service.loadScoredGroupStationKeys(_judgeEmail);
      setState(() => _scoredKeys.addAll(keys));
    } catch (_) {}
  }

  Future<void> _checkAndResetIfAllScored() async {
    if (_currentStationId == null || _groups.isEmpty) return;
    final allDone = await _service.allGroupsScoredAtStation(
      judgeEmail: _judgeEmail,
      stationId: _currentStationId!,
      totalGroupCount: _groups.length,
    );
    if (allDone && mounted) {
      setState(() {
        _scoredKeys.removeWhere((key) => key.endsWith('_$_currentStationId'));
      });
    }
  }

  void _loadGroupForScoring(PerformingGroup group) {
    for (final ctrl in _controllers.values) ctrl.clear();
    for (final key in _errors.keys) _errors[key] = null;

    // Check if already scored at current station
    final key = '${group.id}_$_currentStationId';
    final alreadyScored = _scoredKeys.contains(key);

    setState(() {
      _activeGroup = group;
      _state = alreadyScored ? _FocalState.alreadyScored : _FocalState.scoring;
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  FORM ACTIONS
  // ══════════════════════════════════════════════════════════════

  bool _validate() {
    bool valid = true;
    setState(() {
      for (final c in _criteria) {
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
    if (!_validate() || _activeGroup == null) return;
    if (_currentStationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No station selected by admin. Please wait.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final scores = <String, double>{};
    for (final c in _criteria) {
      final val = double.tryParse(_controllers[c.id]?.text ?? '');
      if (val != null) scores[c.id] = val;
    }

    try {
      await _service.submitScores(
        judgeEmail: _judgeEmail,
        groupId: _activeGroup!.id,
        stationId: _currentStationId!,
        scores: scores,
        weightedTotal: _weightedTotal,
      );

      final key = '${_activeGroup!.id}_$_currentStationId';
      setState(() {
        _isSubmitting = false;
        _scoredKeys.add(key);
        _state = _FocalState.submitted;
      });

      await _checkAndResetIfAllScored();
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    Widget body;

    switch (_state) {
      case _FocalState.waiting:
        body = JudgeWaitingForPush(
          categoryColor: _color,
          categoryTitle: _title,
        );
        break;

      case _FocalState.scoring:
        if (_activeGroup == null) {
          body = const Center(child: CircularProgressIndicator(color: _color));
          break;
        }
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
          onBack: null,
          onSubmit: _submitScores,
          onChanged: (id) => setState(() => _errors[id] = null),
          // ── Live timer props ──
          timerElapsed: _timerElapsed,
          timerRunning: _timerRunning,
          timerDisplay: _timerDisplay,
          stationName: _currentStationName,
        );
        break;

      case _FocalState.alreadyScored:
        body = JudgeAlreadyScoredScreen(
          group: _activeGroup!,
          categoryTitle: _title,
          categoryIcon: _icon,
          categoryColor: _color,
          stationName: _currentStationName ?? 'this station',
          onBack: null, // admin-controlled — no free back
        );
        break;

      case _FocalState.submitted:
        body = JudgeSuccessState(
          group: _activeGroup!,
          criteria: _criteria,
          controllers: _controllers,
          categoryTitle: _title,
          categoryIcon: _icon,
          categoryColor: _color,
          weightedTotal: _weightedTotal,
          totalGroups: _groups.length,
          onScoreAnother: null,
        );
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          JudgeTopBar(
            judgeEmail: _judgeEmail,
            stage: _activeStage,
            stageColor: _stageColor,
            categoryTitle: _title,
            categoryIcon: _icon,
            categoryColor: _color,
            onBack: null,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              child: KeyedSubtree(
                key: ValueKey(
                  '$_state-${_activeGroup?.id}-$_pushedGroupId-$_currentStationId',
                ),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  INTERNAL STATE ENUM
// ══════════════════════════════════════════════════════════════

enum _FocalState { waiting, scoring, alreadyScored, submitted }

// ══════════════════════════════════════════════════════════════
//  DUMMY GROUP
// ══════════════════════════════════════════════════════════════

const _kDummyGroup = PerformingGroup(
  id: '',
  name: 'Loading…',
  barangay: '',
  theme: '',
  performanceOrder: 0,
);
