import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';
import 'package:pandan_fest/models/app_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pandan_fest/services.dart';
import 'judge_shared_widgets.dart' hide JudgeScoreService;

// ═══════════════════════════════════════════════════════════════════
// STREET DANCE SCORING SCREEN
//
// Changes from original:
//   1. Live timer shown between group card and criteria (from
//      live_sessions/current timerElapsed + timerRunning fields).
//   2. Scored key is now "{groupId}_{stationId}" so the same group
//      can be scored at each of the 4 stations separately.
//   3. "Already Scored" screen replaces the form when judge has
//      already submitted for this group+station combo.
//   4. Lock resets automatically once ALL groups have been scored
//      at the current station (checked after each submission).
// ═══════════════════════════════════════════════════════════════════

class StreetDanceScoringScreen extends StatefulWidget {
  const StreetDanceScoringScreen({super.key});

  @override
  State<StreetDanceScoringScreen> createState() =>
      _StreetDanceScoringScreenState();
}

class _StreetDanceScoringScreenState extends State<StreetDanceScoringScreen> {
  // ── services ──────────────────────────────────────────────────
  final _service = JudgeScoreService();
  final _auth = FirebaseAuth.instance;

  // ── screen state ──────────────────────────────────────────────
  JudgeScreenState _screenState = JudgeScreenState.selectContestant;
  PerformingGroup? _selectedGroup;

  // ── form state ────────────────────────────────────────────────
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _errors = {};
  bool _isSubmitting = false;

  // ── Firestore live data ───────────────────────────────────────
  List<PerformingGroup> _groups = [];
  bool _groupsLoading = true;

  // ── session state from Firestore ──────────────────────────────
  String? _pushedGroupId;
  String? _currentStationId; // ← active station from live_sessions
  String? _currentStationName;
  List<String> _activeCriteriaIds = [];

  // ── timer state (synced from live_sessions) ───────────────────
  int _timerElapsed = 0; // seconds elapsed (from Firestore)
  bool _timerRunning = false;
  Timer? _localTick; // local 1-second ticker to keep UI smooth
  DateTime? _lastServerSync; // when we last received a Firestore update

  // ── judge identity ────────────────────────────────────────────
  String get _judgeEmail =>
      _auth.currentUser?.email ?? 'unknown@pandanfest.com';

  // ── scored keys: "{groupId}_{stationId}" ─────────────────────
  // Tracks which group+station combos this judge has submitted.
  final Set<String> _scoredKeys = {};

  // ── subscriptions ────────────────────────────────────────────
  StreamSubscription? _groupsSub;
  StreamSubscription? _sessionSub;

  // ── category config ───────────────────────────────────────────
  static const Color _color = Color(0xFF5856D6);
  static const IconData _icon = Icons.music_video_rounded;
  static const String _title = 'Street Dance';

  List<ActiveCriterion> get _criteria {
    if (_activeCriteriaIds.isEmpty) return streetDanceCriteria;
    return streetDanceCriteria
        .where((c) => _activeCriteriaIds.contains(c.id))
        .toList();
  }

  CompetitionStage get _activeStage => staticStages.first;
  Color get _stageColor => const Color(0xFF5856D6);

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

  /// Returns true if this judge already scored the currently
  /// selected group at the current station.
  bool get _alreadyScoredCurrent {
    if (_selectedGroup == null || _currentStationId == null) return false;
    return _scoredKeys.contains('${_selectedGroup!.id}_$_currentStationId');
  }

  // ══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _initControllers(streetDanceCriteria);
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
      setState(() {
        _groups = groups;
        _groupsLoading = false;
      });
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

      // ── Only react to street dance pushes ──────────────────
      if (isPushed && timerPreset != 'streetDance') {
        setState(() => _pushedGroupId = null);
        return;
      }

      setState(() {
        _activeCriteriaIds = rawIds != null ? List<String>.from(rawIds) : [];
        _pushedGroupId = (isPushed && pushedGroupId != null)
            ? pushedGroupId
            : null;
        _currentStationId = stationId;
        _currentStationName = stationName;
      });

      // If admin reset while judge is on submitted screen → back to picker
      if (!isPushed && _screenState == JudgeScreenState.submitted) {
        setState(() => _screenState = JudgeScreenState.selectContestant);
      }

      // If judge is currently on scoring/alreadyScored and the station
      // changed, re-evaluate the already-scored state.
      if (_screenState == JudgeScreenState.scoring ||
          _screenState == JudgeScreenState.alreadyScored) {
        _reevaluateScoredState();
      }
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  TIMER SYNC
  //
  // We receive timerElapsed from Firestore every ~5 seconds (throttled
  // by admin). Between Firestore updates we run a local 1-second tick
  // so the judge sees a smooth counter.
  // ══════════════════════════════════════════════════════════════

  void _syncTimer(int serverElapsed, bool serverRunning) {
    // Accept the server value as source of truth
    setState(() {
      _timerElapsed = serverElapsed;
      _timerRunning = serverRunning;
    });
    _lastServerSync = DateTime.now();

    if (serverRunning) {
      _startLocalTick();
    } else {
      _stopLocalTick();
    }
  }

  void _startLocalTick() {
    if (_localTick != null) return; // already ticking
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

  /// After submitting, check if all groups are now scored at this
  /// station. If so, clear the scored keys for this station so the
  /// judge is ready for the next station round.
  Future<void> _checkAndResetIfAllScored() async {
    if (_currentStationId == null || _groups.isEmpty) return;
    final allDone = await _service.allGroupsScoredAtStation(
      judgeEmail: _judgeEmail,
      stationId: _currentStationId!,
      totalGroupCount: _groups.length,
    );
    if (allDone && mounted) {
      // All groups scored at this station — clear keys for this station
      // so the judge is unlocked when the next station begins.
      setState(() {
        _scoredKeys.removeWhere((key) => key.endsWith('_$_currentStationId'));
      });
    }
  }

  void _reevaluateScoredState() {
    if (_selectedGroup == null || _currentStationId == null) return;
    final key = '${_selectedGroup!.id}_$_currentStationId';
    final alreadyScored = _scoredKeys.contains(key);
    setState(() {
      _screenState = alreadyScored
          ? JudgeScreenState.alreadyScored
          : JudgeScreenState.scoring;
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  FORM ACTIONS
  // ══════════════════════════════════════════════════════════════

  void _selectContestant(PerformingGroup group) {
    for (final ctrl in _controllers.values) ctrl.clear();
    for (final key in _errors.keys) _errors[key] = null;

    final key = '${group.id}_$_currentStationId';
    final alreadyScored = _scoredKeys.contains(key);

    setState(() {
      _selectedGroup = group;
      _screenState = alreadyScored
          ? JudgeScreenState.alreadyScored
          : JudgeScreenState.scoring;
    });
  }

  void _backToSelection() {
    setState(() {
      _selectedGroup = null;
      _screenState = JudgeScreenState.selectContestant;
    });
  }

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
    if (!_validate() || _selectedGroup == null) return;
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
        groupId: _selectedGroup!.id,
        stationId: _currentStationId!,
        scores: scores,
        weightedTotal: _weightedTotal,
      );

      final key = '${_selectedGroup!.id}_$_currentStationId';
      setState(() {
        _isSubmitting = false;
        _scoredKeys.add(key);
        _screenState = JudgeScreenState.submitted;
      });

      // Check if all groups are now done at this station
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
    final body = switch (_screenState) {
      JudgeScreenState.selectContestant =>
        _groupsLoading
            ? const Center(child: CircularProgressIndicator(color: _color))
            : JudgeContestantPicker(
                categoryTitle: _title,
                categoryIcon: _icon,
                categoryColor: _color,
                criteria: _criteria,
                scoredGroupStationKeys: _scoredKeys,
                currentStationId: _currentStationId,
                groups: _groups,
                pushedGroupId: _pushedGroupId,
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
        // ── Live timer props ──
        timerElapsed: _timerElapsed,
        timerRunning: _timerRunning,
        timerDisplay: _timerDisplay,
        stationName: _currentStationName,
      ),
      JudgeScreenState.alreadyScored => JudgeAlreadyScoredScreen(
        group: _selectedGroup!,
        categoryTitle: _title,
        categoryIcon: _icon,
        categoryColor: _color,
        stationName: _currentStationName ?? 'this station',
        onBack: _backToSelection,
      ),
      JudgeScreenState.submitted => JudgeSuccessState(
        group: _selectedGroup!,
        criteria: _criteria,
        controllers: _controllers,
        categoryTitle: _title,
        categoryIcon: _icon,
        categoryColor: _color,
        weightedTotal: _weightedTotal,
        totalGroups: _groups.length,
        onScoreAnother: _backToSelection,
      ),
    };

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
            onBack:
                _screenState == JudgeScreenState.scoring ||
                    _screenState == JudgeScreenState.alreadyScored
                ? _backToSelection
                : null,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              child: KeyedSubtree(
                key: ValueKey(
                  '$_screenState-${_selectedGroup?.id}-$_pushedGroupId-$_currentStationId',
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
