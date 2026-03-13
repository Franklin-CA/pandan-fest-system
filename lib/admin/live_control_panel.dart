import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';
import 'package:pandan_fest/models/app_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ═══════════════════════════════════════════════════════════════
//  FIRESTORE COLLECTIONS USED
//
//  live_sessions/current  — single active-session document
//  {
//    "groupId": "...",
//    "groupName": "...",
//    "barangay": "...",
//    "stationId": "station_1",
//    "stationName": "Apaya Arch",
//    "criteriaIds": ["sd_1", "sd_2", ...],
//    "isPushed": true,
//    "timerElapsed": 0,
//    "timerRunning": false,
//    "timerPreset": "streetDance",
//    "pushedAt": Timestamp,
//    "pushedBy": "admin@pandanfest.com"
//  }
//
//  judge_scores/{judgeEmail}_{groupId}  — one doc per judge per group
//  {
//    "judgeEmail": "judge1@pandanfest.com",
//    "groupId": "...",
//    "sessionId": "current",
//    "scores": { "sd_1": 85, "sd_2": 90, ... },
//    "isSubmitted": true,
//    "submittedAt": Timestamp
//  }
//
//  dance_groups/ — read-only here, written by DanceGroupManagement
// ═══════════════════════════════════════════════════════════════

const List<String> kJudgeEmails = [
  'judge1@pandanfest.com',
  'judge2@pandanfest.com',
  'judge3@pandanfest.com',
  'judge4@pandanfest.com',
  'judge5@pandanfest.com',
];

class PerformanceStation {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  const PerformanceStation({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

const List<PerformanceStation> kStations = [
  PerformanceStation(
    id: 'station_1',
    name: 'Apaya Arch',
    description: 'Station 1 — Starting point',
    icon: Icons.account_balance_rounded,
  ),
  PerformanceStation(
    id: 'station_2',
    name: 'Mapandan Town Center',
    description: 'Station 2 — In front of Town Center',
    icon: Icons.location_city_rounded,
  ),
  PerformanceStation(
    id: 'station_3',
    name: 'Mapandan Public Market',
    description: 'Station 3 — In front of Public Market',
    icon: Icons.store_rounded,
  ),
  PerformanceStation(
    id: 'station_4',
    name: 'Municipal Hall',
    description: 'Station 4 — In front of Municipal Hall',
    icon: Icons.account_balance_outlined,
  ),
];

enum TimerPreset { streetDance, focalPresentation }

extension TimerPresetExt on TimerPreset {
  String get label {
    switch (this) {
      case TimerPreset.streetDance:
        return 'Street Dance (3–4 min)';
      case TimerPreset.focalPresentation:
        return 'Focal Presentation (7–8 min)';
    }
  }

  String get docValue {
    switch (this) {
      case TimerPreset.streetDance:
        return 'streetDance';
      case TimerPreset.focalPresentation:
        return 'focalPresentation';
    }
  }

  int get minSeconds {
    switch (this) {
      case TimerPreset.streetDance:
        return 180;
      case TimerPreset.focalPresentation:
        return 420;
    }
  }

  int get maxSeconds {
    switch (this) {
      case TimerPreset.streetDance:
        return 240;
      case TimerPreset.focalPresentation:
        return 480;
    }
  }

  Color get color {
    switch (this) {
      case TimerPreset.streetDance:
        return AppColors.primary;
      case TimerPreset.focalPresentation:
        return AppColors.secondary;
    }
  }
}

TimerPreset _presetFromString(String? s) {
  if (s == 'focalPresentation') return TimerPreset.focalPresentation;
  return TimerPreset.streetDance;
}

// ═══════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════

class LiveControlPanel extends StatefulWidget {
  const LiveControlPanel({super.key});

  @override
  State<LiveControlPanel> createState() => _LiveControlPanelState();
}

class _LiveControlPanelState extends State<LiveControlPanel>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Group / station / criteria state ──
  String? selectedGroupId;
  String? selectedGroupName;
  String? selectedGroupBarangay;
  List<String> selectedCriteriaIds = staticCriteria.map((c) => c.id).toList();
  bool isPushedToJudges = false;
  bool isPushing = false;
  String activeStageId = 's1'; // active stage selection
  String? selectedStationId;

  // ── Timer state ──
  TimerPreset _timerPreset = TimerPreset.streetDance;
  int _elapsedSeconds = 0;
  bool _timerRunning = false;
  Timer? _countdownTimer;

  // ── Firestore listeners ──
  StreamSubscription? _sessionSub;
  StreamSubscription? _scoresSub;
  StreamSubscription? _groupsSub;

  // ── Live data from Firestore ──
  List<PerformingGroup> _groups = [];
  List<JudgeScore> _liveJudgeScores = [];
  bool _groupsLoading = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Timer sync throttle ──
  DateTime _lastTimerWrite = DateTime(2000);

  PerformingGroup? get selectedGroup => selectedGroupId != null
      ? _groups.where((g) => g.id == selectedGroupId).isNotEmpty
            ? _groups.firstWhere((g) => g.id == selectedGroupId)
            : null
      : null;

  List<ActiveCriterion> get activeCriteria =>
      staticCriteria.where((c) => selectedCriteriaIds.contains(c.id)).toList();

  List<JudgeScore> get currentScores =>
      selectedGroupId != null
          ? (resolvedStageJudgeScores(activeStageId)[selectedGroupId] ?? [])
          : [];

  List<RankingEntry> get rankings =>
      computeRankings(resolvedStageJudgeScores(activeStageId), staticGroups, staticCriteria);

  PerformanceStation? get selectedStation => selectedStationId != null
      ? kStations.firstWhere((s) => s.id == selectedStationId)
      : null;

  // ── Timer helpers ──
  String get _timerDisplay {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _isWithinTimeLimit =>
      _elapsedSeconds >= _timerPreset.minSeconds &&
      _elapsedSeconds <= _timerPreset.maxSeconds;
  bool get _isOverTimeLimit => _elapsedSeconds > _timerPreset.maxSeconds;
  Color get _timerColor {
    if (_elapsedSeconds == 0) return AppColors.silverRank;
    if (_elapsedSeconds < _timerPreset.minSeconds) return AppColors.warning;
    if (_isOverTimeLimit) return AppColors.danger;
    return AppColors.accentGreen;
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
    _listenGroups();
    _listenSession();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _sessionSub?.cancel();
    _scoresSub?.cancel();
    _groupsSub?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  FIRESTORE LISTENERS
  // ══════════════════════════════════════════════════════════════

  void _listenGroups() {
    _groupsSub = _db
        .collection('dance_groups')
        .orderBy('performanceOrder')
        .snapshots()
        .listen((snap) {
          final loaded = snap.docs.map((doc) {
            final d = doc.data();
            return PerformingGroup(
              id: doc.id,
              name: d['name'] ?? '',
              barangay: d['community'] ?? '',
              theme: d['theme'] ?? '',
              performanceOrder: d['performanceOrder'] ?? 0,
            );
          }).toList();
          setState(() {
            _groups = loaded;
            _groupsLoading = false;
          });
        });
  }

  void _listenSession() {
    _sessionSub = _db
        .collection('live_sessions')
        .doc('current')
        .snapshots()
        .listen((snap) {
          if (!snap.exists) return;
          final d = snap.data()!;
          final timerRunning = d['timerRunning'] as bool? ?? false;
          final timerElapsed = d['timerElapsed'] as int? ?? 0;

          setState(() {
            isPushedToJudges = d['isPushed'] as bool? ?? false;
            selectedGroupId = d['groupId'] as String?;
            selectedGroupName = d['groupName'] as String?;
            selectedGroupBarangay = d['barangay'] as String?;
            selectedStationId = d['stationId'] as String?;
            final rawIds = d['criteriaIds'];
            if (rawIds != null) selectedCriteriaIds = List<String>.from(rawIds);
            _timerPreset = _presetFromString(d['timerPreset'] as String?);

            // Only update timer state from Firestore if we're not locally running
            // (prevents overwriting the locally-ticking counter on each write)
            if (!_timerRunning) {
              _elapsedSeconds = timerElapsed;
              if (timerRunning) _startTimerLocal();
            }
          });

          // Listen to judge scores for this group
          if (selectedGroupId != null) _listenJudgeScores(selectedGroupId!);
        });
  }

  void _listenJudgeScores(String groupId) {
    _scoresSub?.cancel();
    _scoresSub = _db
        .collection('judge_scores')
        .where('groupId', isEqualTo: groupId)
        .where('sessionId', isEqualTo: 'current')
        .snapshots()
        .listen((snap) {
          final scores = snap.docs.map((doc) {
            final d = doc.data();
            return JudgeScore(
              judgeId: d['judgeEmail'] as String? ?? '',
              judgeName: d['judgeEmail'] as String? ?? '',
              scores: Map<String, double>.from(
                (d['scores'] as Map<String, dynamic>? ?? {}).map(
                  (k, v) => MapEntry(k, (v as num).toDouble()),
                ),
              ),
              isSubmitted: d['isSubmitted'] as bool? ?? false,
            );
          }).toList();
          setState(() => _liveJudgeScores = scores);
        });
  }

  // ══════════════════════════════════════════════════════════════
  //  FIRESTORE WRITES
  // ══════════════════════════════════════════════════════════════

  Future<void> _writeSessionPartial(Map<String, dynamic> data) async {
    try {
      await _db
          .collection('live_sessions')
          .doc('current')
          .set(data, SetOptions(merge: true));
    } catch (e) {
      _toast('Sync error: $e', AppColors.danger);
    }
  }

  Future<void> _pushToJudges() async {
    if (selectedGroupId == null ||
        activeCriteria.isEmpty ||
        selectedStationId == null) {
      return;
    }
    final user = _auth.currentUser;
    setState(() => isPushing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    // Also push to Focal Presentation judges
    LiveSessionState.instance.pushFocalContestant(selectedGroupId!);
    setState(() {
      isPushing = false;
      isPushedToJudges = true;
    });
  }

  void _resetPush() {
    LiveSessionState.instance.clearFocalPush();
    setState(() => isPushedToJudges = false);
  }

  Future<void> _resetPush() async {
    await _writeSessionPartial({'isPushed': false});
    setState(() => isPushedToJudges = false);
  }

  // ══════════════════════════════════════════════════════════════
  //  TIMER CONTROLS — local tick + Firestore sync
  // ══════════════════════════════════════════════════════════════

  void _startTimerLocal() {
    _countdownTimer?.cancel();
    setState(() => _timerRunning = true);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
      // Throttle Firestore writes to once every 5 seconds to reduce cost
      if (DateTime.now().difference(_lastTimerWrite).inSeconds >= 5) {
        _lastTimerWrite = DateTime.now();
        _writeSessionPartial({
          'timerElapsed': _elapsedSeconds,
          'timerRunning': true,
        });
      }
    });
  }

  void _startTimer() {
    setState(() {
      _elapsedSeconds = 0;
    });
    _writeSessionPartial({
      'timerElapsed': 0,
      'timerRunning': true,
      'timerPreset': _timerPreset.docValue,
    });
    _startTimerLocal();
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    setState(() => _timerRunning = false);
    _writeSessionPartial({
      'timerElapsed': _elapsedSeconds,
      'timerRunning': false,
    });
  }

  void _resetTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _elapsedSeconds = 0;
      _timerRunning = false;
    });
    _writeSessionPartial({'timerElapsed': 0, 'timerRunning': false});
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiveSessionState.instance,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                            fontSize: 13, color: AppColors.live, fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _resetPush,
                          child: Icon(Icons.close_rounded, color: AppColors.live, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2D55).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF2D55).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFF2D55), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "Focal judges unlocked",
                          style: GoogleFonts.poppins(
                            fontSize: 13, color: const Color(0xFFFF2D55), fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Stage Selector ──
        _StageSelector(
          stages: staticStages,
          activeStageId: activeStageId,
          onSelect: (id) => setState(() {
            activeStageId = id;
            selectedGroupId = null;
            isPushedToJudges = false;
          }),
        ),
        const SizedBox(height: 12),

        // ── Now Performing Banner ──
        _NowPerformingBanner(activeStageId: activeStageId),
        const SizedBox(height: 12),

        // ── Group Selector ──
        _GroupSelector(
          groups: _groups,
          isLoading: _groupsLoading,
          selectedId: selectedGroupId,
          activeGroupId: LiveSessionState.instance
              .activeGroupId(activeStageId),
          onSelect: (id) => setState(() {
            selectedGroupId = id;
            isPushedToJudges = false;
          }),
        ),
        const SizedBox(height: 12),

        // ── Station Selector ──
        _StationSelector(
          stations: kStations,
          selectedId: selectedStationId,
          onSelect: (id) {
            final s = kStations.firstWhere((s) => s.id == id);
            setState(() {
              selectedStationId = id;
              isPushedToJudges = false;
            });
            _writeSessionPartial({
              'stationId': id,
              'stationName': s.name,
              'isPushed': false,
            });
          },
        ),
        const SizedBox(height: 12),

        // ── Criteria Selector ──
        _CriteriaSelector(
          criteria: staticCriteria,
          selectedIds: selectedCriteriaIds,
          onToggle: (id) {
            setState(() {
              selectedCriteriaIds.contains(id)
                  ? selectedCriteriaIds.remove(id)
                  : selectedCriteriaIds.add(id);
              isPushedToJudges = false;
            });
            _writeSessionPartial({
              'criteriaIds': selectedCriteriaIds,
              'isPushed': false,
            });
          },
        ),
        const SizedBox(height: 12),

        // ── Judge Panel Info ──
        _JudgePanelInfo(),
        const SizedBox(height: 12),

        // ── Push Button ──
        _PushButton(
          isReady:
              selectedGroupId != null &&
              selectedStationId != null &&
              activeCriteria.isNotEmpty,
          isPushing: isPushing,
          isPushed: isPushedToJudges,
          onPush: _pushToJudges,
        ),
        if (isPushedToJudges) ...[
          const SizedBox(height: 10),
          _ResetHint(onReset: _resetPush),
        ],
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Control Panel',
                style: GoogleFonts.poppins(
                  fontSize: 26,
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
                    'LIVE SESSION ACTIVE',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.live,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Firestore sync indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_done_rounded,
                          size: 12,
                          color: AppColors.accentGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Firestore Synced',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedStation != null) ...[
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedStation!.icon,
                            size: 13,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            selectedStation!.name,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isPushedToJudges)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      'Synced to 5 judges',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.live,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _resetPush,
                      child: Tooltip(
                        message: 'Clear and select a new group',
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.live,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Step Hint ────────────────────────────────────────────────
  Widget _buildStepHint() {
    final step = selectedGroupId == null
        ? 1
        : selectedStationId == null
        ? 2
        : activeCriteria.isEmpty
        ? 3
        : !isPushedToJudges
        ? 4
        : 5;

    final steps = [
      _StepInfo(1, 'Select Group', step >= 1),
      _StepInfo(2, 'Select Station', step >= 2),
      _StepInfo(3, 'Confirm Criteria', step >= 3),
      _StepInfo(4, 'Push to Judges', step >= 4),
      _StepInfo(5, 'Monitor Live', step >= 5),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: steps
            .expand(
              (s) => [
                _StepChip(info: s, isCurrent: s.number == step),
                if (s.number < steps.length)
                  Expanded(
                    child: Container(
                      height: 1,
                      color: s.number < step
                          ? AppColors.secondary.withOpacity(0.4)
                          : AppColors.divider,
                    ),
                  ),
              ],
            )
            .toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PERFORMANCE TIMER (UI only — state managed by parent)
// ═══════════════════════════════════════════════════════════════

class _PerformanceTimer extends StatelessWidget {
  final TimerPreset preset;
  final int elapsed;
  final bool isRunning;
  final Color timerColor;
  final String display;
  final bool isWithinLimit;
  final bool isOver;
  final ValueChanged<TimerPreset> onPresetChange;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  const _PerformanceTimer({
    required this.preset,
    required this.elapsed,
    required this.isRunning,
    required this.timerColor,
    required this.display,
    required this.isWithinLimit,
    required this.isOver,
    required this.onPresetChange,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    String statusLabel;
    if (elapsed == 0) {
      statusLabel = 'Ready to start';
    } else if (elapsed < preset.minSeconds) {
      final remaining = preset.minSeconds - elapsed;
      final m = remaining ~/ 60;
      final s = remaining % 60;
      statusLabel = 'Under minimum — ${m > 0 ? '${m}m ' : ''}${s}s until valid';
    } else if (isOver) {
      final over = elapsed - preset.maxSeconds;
      final m = over ~/ 60;
      final s = over % 60;
      statusLabel = '⚠ Over time limit by ${m > 0 ? '${m}m ' : ''}${s}s';
    } else {
      statusLabel = '✓ Within time limit';
    }

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
              Icon(Icons.timer_rounded, color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Performance Timer',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              ...TimerPreset.values.map((p) {
                final isSelected = preset == p;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => onPresetChange(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? p.color.withOpacity(0.12)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? p.color : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        p.label,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? p.color : AppColors.silverRank,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      display,
                      style: GoogleFonts.poppins(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                        letterSpacing: 2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: timerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: timerColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Allowed: ${preset.minSeconds ~/ 60}–${preset.maxSeconds ~/ 60} minutes (incl. entrance & exit)',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.silverRank,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (elapsed / preset.maxSeconds).clamp(0.0, 1.0),
                          strokeWidth: 7,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                        ),
                        Icon(
                          isRunning
                              ? Icons.graphic_eq_rounded
                              : Icons.timer_rounded,
                          color: timerColor,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!isRunning)
                        _TimerBtn(
                          icon: Icons.play_arrow_rounded,
                          color: AppColors.accentGreen,
                          tooltip: 'Start timer',
                          onTap: onStart,
                        )
                      else
                        _TimerBtn(
                          icon: Icons.pause_rounded,
                          color: AppColors.warning,
                          tooltip: 'Stop timer',
                          onTap: onStop,
                        ),
                      const SizedBox(width: 8),
                      _TimerBtn(
                        icon: Icons.refresh_rounded,
                        color: AppColors.silverRank,
                        tooltip: 'Reset timer',
                        onTap: onReset,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (elapsed / preset.maxSeconds).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0:00',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.silverRank,
                    ),
                  ),
                  Text(
                    '${preset.minSeconds ~/ 60}:00 min',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${preset.maxSeconds ~/ 60}:00 max',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _TimerBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STATION SELECTOR
// ═══════════════════════════════════════════════════════════════

class _StationSelector extends StatelessWidget {
  final List<PerformanceStation> stations;
  final String? selectedId;
  final String? activeGroupId; // currently being scored by a judge
  final ValueChanged<String> onSelect;

  const _StationSelector({
    required this.stations,
    required this.selectedId,
    required this.activeGroupId,
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
              Icon(Icons.place_rounded, color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Step 2 — Select Station',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Choose the performance station/location being judged.',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: AppColors.silverRank,
            ),
          ),
          const SizedBox(height: 14),
          ...stations.asMap().entries.map((entry) {
            final i = entry.key;
            final station = entry.value;
            final isSelected = selectedId == station.id;
            return GestureDetector(
              onTap: () => onSelect(station.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isLive
                      ? AppColors.live.withOpacity(0.07)
                      : isSelected
                          ? AppColors.secondary.withOpacity(0.12)
                          : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLive
                        ? AppColors.live.withOpacity(0.5)
                        : isSelected
                            ? AppColors.secondary
                            : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isLive
                            ? AppColors.live
                            : isSelected
                                ? AppColors.secondary
                                : AppColors.divider,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isLive || isSelected
                                ? Colors.white
                                : AppColors.silverRank,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      station.icon,
                      size: 16,
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.silverRank,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.secondary : null,
                            ),
                          ),
                          Text(
                            station.description,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: AppColors.silverRank,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.live.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.live.withOpacity(0.4)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                                color: AppColors.live,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text('SCORING',
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.live,
                                  letterSpacing: 0.8)),
                        ]),
                      )
                    else if (isSelected)
                      Icon(Icons.radio_button_checked_rounded,
                          color: AppColors.secondary, size: 18)
                    else
                      Icon(Icons.radio_button_off_rounded,
                          color: AppColors.divider, size: 18),
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

// ═══════════════════════════════════════════════════════════════
//  JUDGE PANEL INFO
// ═══════════════════════════════════════════════════════════════

class _JudgePanelInfo extends StatelessWidget {
  const _JudgePanelInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: AppColors.shadow,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_alt_rounded,
                color: AppColors.secondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Judge Panel — 5 Judges',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...kJudgeEmails.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.email_outlined,
                    size: 13,
                    color: AppColors.silverRank,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    e.value,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.silverRank,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STEP HELPERS
// ═══════════════════════════════════════════════════════════════

class _StepInfo {
  final int number;
  final String label;
  final bool done;
  const _StepInfo(this.number, this.label, this.done);
}

class _StepChip extends StatelessWidget {
  final _StepInfo info;
  final bool isCurrent;
  const _StepChip({required this.info, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final color = info.done ? AppColors.secondary : AppColors.silverRank;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: info.done ? AppColors.secondary : Colors.transparent,
            border: Border.all(color: color, width: 1.5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: info.done && !isCurrent
                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                : Text(
                    '${info.number}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: info.done ? Colors.white : color,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          info.label,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            color: isCurrent ? AppColors.secondary : color,
          ),
        ),
      ],
    );
  }
}

class _ResetHint extends StatelessWidget {
  final VoidCallback onReset;
  const _ResetHint({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReset,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded, size: 15, color: AppColors.silverRank),
            const SizedBox(width: 6),
            Text(
              'Select a different group or station',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.silverRank,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GROUP SELECTOR — now driven by live Firestore data
// ═══════════════════════════════════════════════════════════════

class _GroupSelector extends StatelessWidget {
  final List<PerformingGroup> groups;
  final bool isLoading;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _GroupSelector({
    required this.groups,
    required this.isLoading,
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
              Expanded(
                child: Text(
                  'Step 1 — Select Performing Group',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '${groups.length} group${groups.length != 1 ? 's' : ''}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.silverRank,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Choose the group currently performing on stage.',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: AppColors.silverRank,
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
            )
          else if (groups.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.silverRank,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No groups registered yet. Add groups in the Dance Groups tab.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.silverRank,
                    ),
                  ),
                ],
              ),
            )
          else
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
                            '${group.performanceOrder}',
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
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.divider,
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

// ═══════════════════════════════════════════════════════════════
//  CRITERIA SELECTOR
// ═══════════════════════════════════════════════════════════════

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
              Expanded(
                child: Text(
                  'Step 3 — Active Criteria',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '${selectedIds.length} / ${criteria.length} active',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.silverRank,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Uncheck criteria you don\'t want judges to score this round.',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: AppColors.silverRank,
            ),
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
                        '${c.weight.toStringAsFixed(0)}%',
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
          if (selectedIds.length < criteria.length)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${criteria.length - selectedIds.length} criterion hidden from judges.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.warning,
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

// ═══════════════════════════════════════════════════════════════
//  PUSH BUTTON
// ═══════════════════════════════════════════════════════════════

class _PushButton extends StatelessWidget {
  final bool isReady, isPushing, isPushed;
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
    Widget child;
    VoidCallback? tapHandler;

    if (isPushing) {
      bgColor = AppColors.secondary.withOpacity(0.7);
      child = Row(
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
            'Syncing to Firestore…',
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
            'Pushed to All 5 Judges ✓',
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
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.send_rounded, color: AppColors.silverRank, size: 20),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Push to Judges',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.silverRank,
                ),
              ),
              Text(
                'Select group & station first',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.silverRank,
                ),
              ),
            ],
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Step 4 — Push to All Judges',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              Text(
                'Send group, station & criteria to 5 panels',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
              ),
            ],
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

// ═══════════════════════════════════════════════════════════════
//  SCORE DISPLAY — reads live judge scores from Firestore
// ═══════════════════════════════════════════════════════════════

class _ScoreDisplay extends StatelessWidget {
  final PerformingGroup? group;
  final PerformanceStation? station;
  final List<ActiveCriterion> criteria;
  final List<JudgeScore> judgeScores;
  final bool isPushed;

  const _ScoreDisplay({
    required this.group,
    required this.station,
    required this.criteria,
    required this.judgeScores,
    required this.isPushed,
  });

  double get avgWeightedScore {
    final submitted = judgeScores
        .where((j) => j.isSubmitted && j.scores.isNotEmpty)
        .toList();
    if (submitted.isEmpty) return 0;
    return submitted.fold(0.0, (s, j) => s + j.totalWeighted(staticCriteria)) /
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
          Row(
            children: [
              Icon(Icons.live_tv_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Step 5 — Real-Time Scores',
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
              if (station != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(station!.icon, size: 12, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        station!.name,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (group == null || !isPushed) ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.divider.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 28,
                      color: AppColors.silverRank,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    group == null
                        ? 'Waiting for group selection…'
                        : 'Group & station selected. Push to judges to begin scoring.',
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
                          'Average Score',
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
                          'Judges Submitted',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.silverRank,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$submittedCount',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentGreen,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                ' / 5',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: AppColors.silverRank,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          submittedCount == 5
                              ? 'All 5 judges submitted ✓'
                              : '${5 - submittedCount} still scoring…',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: submittedCount == 5
                                ? AppColors.accentGreen
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Show all 5 judge rows, even if not yet submitted
            ...kJudgeEmails.map((email) {
              final score =
                  judgeScores.where((j) => j.judgeName == email).isNotEmpty
                  ? judgeScores.firstWhere((j) => j.judgeName == email)
                  : JudgeScore(
                      judgeId: email,
                      judgeName: email,
                      scores: {},
                      isSubmitted: false,
                    );
              return _JudgeScoreRow(judgeScore: score, criteria: criteria);
            }),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  JUDGE SCORE ROW
// ═══════════════════════════════════════════════════════════════

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
          SizedBox(
            width: 130,
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
                          '${c.name.split(' ').first}: ${score?.toStringAsFixed(0) ?? '-'}',
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
                        ? 'Submitted — scores processing…'
                        : 'Waiting for judge to score…',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.silverRank,
                    ),
                  ),
          ),
          if (hasScores)
            Tooltip(
              message: 'Weighted total for this judge',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  judgeScore.totalWeighted(staticCriteria).toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  RANKING BOARD
// ═══════════════════════════════════════════════════════════════

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
                'Live Rankings',
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
                  'AUTO-UPDATED',
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.leaderboard_rounded,
                      size: 40,
                      color: AppColors.divider,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No scores submitted yet',
                      style: GoogleFonts.poppins(
                        color: AppColors.silverRank,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Rankings will appear here as judges score.',
                      style: GoogleFonts.poppins(
                        color: AppColors.divider,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rankings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _RankRow(entry: rankings[i]),
            ),
        ],
      ),
    );
  }
}

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
                      '${entry.rank}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _rankColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
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

// ═══════════════════════════════════════════════════════════════
// NOW PERFORMING BANNER
// Listens to LiveSessionState and shows which contestant is being
// scored right now at each stage.
// ═══════════════════════════════════════════════════════════════

class _NowPerformingBanner extends StatefulWidget {
  final String activeStageId;
  const _NowPerformingBanner({required this.activeStageId});

  @override
  State<_NowPerformingBanner> createState() => _NowPerformingBannerState();
}

class _NowPerformingBannerState extends State<_NowPerformingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  static const _stageColors = [
    Color(0xFF5856D6),
    Color(0xFF007AFF),
    Color(0xFFAF52DE),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiveSessionState.instance,
      builder: (context, _) {
        // collect active groups across ALL stages for the banner
        final activePairs = <MapEntry<CompetitionStage, PerformingGroup>>[];
        for (final stage in staticStages) {
          final gId = LiveSessionState.instance.activeGroupId(stage.id);
          if (gId == null) continue;
          try {
            final g = staticGroups.firstWhere((g) => g.id == gId);
            activePairs.add(MapEntry(stage, g));
          } catch (_) {}
        }

        if (activePairs.isEmpty) {
          // Nothing ongoing — idle state
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Row(children: [
              const Icon(Icons.sensors_off_rounded,
                  size: 16, color: Color(0xFFAEAEB2)),
              const SizedBox(width: 10),
              Text('No active scoring in progress across all stages',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: const Color(0xFFAEAEB2))),
            ]),
          );
        }

        return Column(
          children: activePairs.map((entry) {
            final stage = entry.key;
            final group = entry.value;
            final color =
                _stageColors[(stage.order - 1).clamp(0, 2)];
            final isCurrentStage = stage.id == widget.activeStageId;

            return Container(
              margin: EdgeInsets.only(
                  bottom: activePairs.last != entry ? 8 : 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(isCurrentStage ? 0.13 : 0.07),
                    color.withOpacity(isCurrentStage ? 0.06 : 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(isCurrentStage ? 0.45 : 0.25),
                  width: isCurrentStage ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                // Pulsing dot
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Opacity(
                    opacity: _pulseAnim.value,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Stage chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(stage.name,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ),
                const SizedBox(width: 10),

                // "Now Scoring" label
                Text('Now Scoring:',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: color.withOpacity(0.75),
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 6),

                // Contestant number badge
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${group.performanceOrder}',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),

                // Contestant name + barangay
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: color)),
                      Text(group.barangay,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: color.withOpacity(0.65))),
                    ],
                  ),
                ),

                // LIVE badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.live.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.live.withOpacity(0.35)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.live, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('LIVE',
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.live,
                            letterSpacing: 0.8)),
                  ]),
                ),
              ]),
            );
          }).toList(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STAGE SELECTOR WIDGET
// ═══════════════════════════════════════════════════════════════

class _StageSelector extends StatelessWidget {
  final List<CompetitionStage> stages;
  final String activeStageId;
  final void Function(String) onSelect;

  const _StageSelector({
    required this.stages,
    required this.activeStageId,
    required this.onSelect,
  });

  static const _stageColors = [
    Color(0xFF5856D6),
    Color(0xFF007AFF),
    Color(0xFFAF52DE),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.flag_rounded, size: 16, color: Color(0xFF6C6C70)),
            const SizedBox(width: 8),
            Text('Active Stage', style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1C1C1E))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.live.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                  decoration: const BoxDecoration(color: AppColors.live, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text('SCORING', style: GoogleFonts.poppins(
                  fontSize: 10, fontWeight: FontWeight.bold,
                  color: AppColors.live, letterSpacing: 0.8)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(
            children: stages.asMap().entries.map((e) {
              final stage = e.value;
              final color = _stageColors[e.key % _stageColors.length];
              final isActive = stage.id == activeStageId;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: e.key < stages.length - 1 ? 10 : 0),
                  child: GestureDetector(
                    onTap: () => onSelect(stage.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: isActive ? color.withOpacity(0.09) : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? color : const Color(0xFFE5E5EA),
                          width: isActive ? 1.8 : 1,
                        ),
                        boxShadow: isActive ? [
                          BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
                        ] : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: isActive ? color.withOpacity(0.15) : const Color(0xFFE5E5EA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.flag_rounded, size: 14,
                                  color: isActive ? color : const Color(0xFFAEAEB2)),
                            ),
                            const Spacer(),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color, borderRadius: BorderRadius.circular(20)),
                                child: Text('Active', style: GoogleFonts.poppins(
                                  fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                          ]),
                          const SizedBox(height: 8),
                          Text(stage.name, style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.bold,
                            color: isActive ? color : const Color(0xFF1C1C1E))),
                          const SizedBox(height: 2),
                          Text(
                            '${judgesForStage(stage.id).length} judge${judgesForStage(stage.id).length != 1 ? 's' : ''}',
                            style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF6C6C70)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            stages.firstWhere((s) => s.id == activeStageId, orElse: () => stages.first).description,
            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8E8E93)),
          ),
        ],
      ),
    );
  }
}
