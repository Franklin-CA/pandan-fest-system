import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';
import 'package:pandan_fest/models/app_models.dart';
import 'package:pandan_fest/services.dart';

// ═══════════════════════════════════════════════════════════════════
// RESULTS SCREEN — Firestore-connected
//
// Firestore collections consumed:
//   dance_groups/          → group name, community (barangay), theme,
//                            performanceOrder
//   judge_scores/          → {judgeEmail}_{groupId} docs, each with:
//                              judgeEmail, groupId, sessionId,
//                              scores { criterionId: double },
//                              weightedTotal, isSubmitted
//   scoring_configs/       → streetDance, focalPresentation docs with
//                              criteria list (id, name, weight, maxScore)
//   penalties/             → auto-ID docs with:
//                              groupId, reason, deduction, issuedBy,
//                              createdAt, sessionId
//   results_meta/current   → isFinalized (bool)
//
// All listeners are real-time (snapshots). Adding a penalty writes to
// the penalties/ collection and the rankings recompute instantly.
// Finalizing writes isFinalized=true to results_meta/current.
// ═══════════════════════════════════════════════════════════════════

// ───────────────────────────────────────────────────────────────────
// VIEW MODEL — assembled from Firestore, passed into pure UI widgets
// ───────────────────────────────────────────────────────────────────

class _GroupResult {
  final String id;
  final String name;
  final String barangay; // community field in dance_groups
  final String theme;
  final int performanceOrder;

  // criteria name → per-judge score map  { judgeEmail: score }
  final Map<String, Map<String, double>> criteriaByJudge;

  // penalties from the penalties/ collection
  final List<_Penalty> penalties;

  // criteria list at time of scoring (from scoring_configs)
  final List<ActiveCriterion> criteria;

  const _GroupResult({
    required this.id,
    required this.name,
    required this.barangay,
    required this.theme,
    required this.performanceOrder,
    required this.criteriaByJudge,
    required this.penalties,
    required this.criteria,
  });

  // ── per-judge weighted totals ─────────────────────────────────
  // judgeEmail → their weighted total for this group
  Map<String, double> get judgeWeightedTotals {
    final out = <String, double>{};
    final judgeEmails = <String>{};
    for (final byJudge in criteriaByJudge.values) {
      judgeEmails.addAll(byJudge.keys);
    }
    for (final email in judgeEmails) {
      double total = 0;
      for (final c in criteria) {
        final score = criteriaByJudge[c.id]?[email] ?? 0;
        total += score * c.weight / 100;
      }
      out[email] = total;
    }
    return out;
  }

  // average weighted total across all judges who submitted
  double get rawTotal {
    final totals = judgeWeightedTotals.values;
    if (totals.isEmpty) return 0;
    return totals.reduce((a, b) => a + b) / totals.length;
  }

  double get totalPenalty => penalties.fold(0.0, (s, p) => s + p.deduction);

  double get finalScore =>
      (rawTotal - totalPenalty).clamp(0.0, double.infinity);

  // average score per criterion across all judges
  Map<String, double> get avgCriteriaScores {
    final out = <String, double>{};
    for (final c in criteria) {
      final byJudge = criteriaByJudge[c.id] ?? {};
      if (byJudge.isEmpty) {
        out[c.name] = 0;
      } else {
        out[c.name] = byJudge.values.reduce((a, b) => a + b) / byJudge.length;
      }
    }
    return out;
  }

  // list of judge emails who have submitted
  List<String> get judgeEmails => judgeWeightedTotals.keys.toList();
}

class _Penalty {
  final String docId;
  final String groupId;
  final String reason;
  final double deduction;
  final String issuedBy;

  const _Penalty({
    required this.docId,
    required this.groupId,
    required this.reason,
    required this.deduction,
    required this.issuedBy,
  });
}

// ═══════════════════════════════════════════════════════════════════
// RESULTS SCREEN WIDGET
// ═══════════════════════════════════════════════════════════════════

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  // ── tab ───────────────────────────────────────────────────────
  late TabController _tabController;
  int? _expandedGroupIndex;

  // ── live pulsing ──────────────────────────────────────────────
  bool _liveMode = true;
  Timer? _liveTimer;

  // ── Firestore ─────────────────────────────────────────────────
  final _db = FirebaseFirestore.instance;

  StreamSubscription? _groupsSub;
  StreamSubscription? _scoresSub;
  StreamSubscription? _penaltiesSub;
  StreamSubscription? _metaSub;
  StreamSubscription? _criteriaSDSub;
  StreamSubscription? _criteriaFPSub;

  // ── raw Firestore data ────────────────────────────────────────
  List<PerformingGroup> _groups = [];

  // judgeScoreDocs keyed by docId = "{email}_{groupId}"
  // each doc: { judgeEmail, groupId, scores: {criterionId: double}, weightedTotal, isSubmitted }
  List<Map<String, dynamic>> _scoreDocs = [];

  List<_Penalty> _penalties = [];
  bool _resultsFinalized = false;

  // criteria from scoring_configs (used to build the breakdown table)
  List<ActiveCriterion> _streetDanceCriteria = streetDanceCriteria;
  List<ActiveCriterion> _focalCriteria = focalPresentationCriteria;

  // ── loading ───────────────────────────────────────────────────
  bool _loading = true;

  // ── judge names (from registry in services.dart) ──────────────
  // All unique judge emails found in score docs
  List<String> get _allJudgeEmails {
    final emails = <String>{};
    for (final doc in _scoreDocs) {
      final email = doc['judgeEmail'] as String? ?? '';
      if (email.isNotEmpty) emails.add(email);
    }
    return emails.toList()..sort();
  }

  // ── assembled view models ─────────────────────────────────────
  List<_GroupResult> get _groupResults {
    return _groups.map((g) {
      // All score docs for this group
      final docs = _scoreDocs.where(
        (d) => d['groupId'] == g.id && (d['isSubmitted'] as bool? ?? false),
      );

      // Determine which criteria list to use based on what's in the docs
      // (street dance criteria IDs start with 'sd_', focal with 'fp_')
      // We build a unified criteria list from both — only show criteria
      // that actually have scores for this group.
      final allScoreKeys = <String>{};
      for (final doc in docs) {
        final scores = doc['scores'] as Map<String, dynamic>? ?? {};
        allScoreKeys.addAll(scores.keys);
      }
      final isStreetDance = allScoreKeys.any((k) => k.startsWith('sd_'));
      final criteriaList = isStreetDance
          ? _streetDanceCriteria
          : _focalCriteria;

      // criteriaByJudge: criterionId → { judgeEmail → score }
      final criteriaByJudge = <String, Map<String, double>>{};
      for (final doc in docs) {
        final email = doc['judgeEmail'] as String? ?? '';
        final scores = doc['scores'] as Map<String, dynamic>? ?? {};
        scores.forEach((criterionId, value) {
          criteriaByJudge.putIfAbsent(criterionId, () => {});
          criteriaByJudge[criterionId]![email] = (value as num).toDouble();
        });
      }

      final groupPenalties = _penalties
          .where((p) => p.groupId == g.id)
          .toList();

      return _GroupResult(
        id: g.id,
        name: g.name,
        barangay: g.barangay,
        theme: g.theme,
        performanceOrder: g.performanceOrder,
        criteriaByJudge: criteriaByJudge,
        penalties: groupPenalties,
        criteria: criteriaList,
      );
    }).toList();
  }

  List<_GroupResult> get _rankedResults {
    final sorted = [..._groupResults];
    sorted.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return sorted;
  }

  int _rankOf(_GroupResult g) =>
      _rankedResults.indexWhere((r) => r.id == g.id) + 1;

  // ══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _startLiveTimer();
    _listenAll();
  }

  void _startLiveTimer() {
    _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_liveMode && mounted) setState(() {});
    });
  }

  void _listenAll() {
    // 1. dance_groups
    _groupsSub = _db
        .collection('dance_groups')
        .orderBy('performanceOrder')
        .snapshots()
        .listen((snap) {
          setState(() {
            _groups = snap.docs.map((doc) {
              final d = doc.data();
              return PerformingGroup(
                id: doc.id,
                name: d['name'] as String? ?? '',
                barangay: d['community'] as String? ?? '',
                theme: d['theme'] as String? ?? '',
                performanceOrder: d['performanceOrder'] as int? ?? 0,
              );
            }).toList();
            _loading = false;
          });
        });

    // 2. judge_scores — all submitted docs for this session
    _scoresSub = _db
        .collection('judge_scores')
        .where('sessionId', isEqualTo: 'current')
        .where('isSubmitted', isEqualTo: true)
        .snapshots()
        .listen((snap) {
          setState(() {
            _scoreDocs = snap.docs.map((d) => d.data()).toList();
          });
        });

    // 3. penalties
    _penaltiesSub = _db
        .collection('penalties')
        .where('sessionId', isEqualTo: 'current')
        .orderBy('createdAt')
        .snapshots()
        .listen((snap) {
          setState(() {
            _penalties = snap.docs.map((doc) {
              final d = doc.data();
              return _Penalty(
                docId: doc.id,
                groupId: d['groupId'] as String? ?? '',
                reason: d['reason'] as String? ?? '',
                deduction: (d['deduction'] as num?)?.toDouble() ?? 0,
                issuedBy: d['issuedBy'] as String? ?? '',
              );
            }).toList();
          });
        });

    // 4. results_meta/current — isFinalized
    _metaSub = _db.collection('results_meta').doc('current').snapshots().listen(
      (snap) {
        if (!snap.exists) return;
        setState(() {
          _resultsFinalized = snap.data()?['isFinalized'] as bool? ?? false;
          if (_resultsFinalized) _liveMode = false;
        });
      },
    );

    // 5. scoring_configs/streetDance
    _criteriaSDSub = _db
        .collection('scoring_configs')
        .doc('streetDance')
        .snapshots()
        .listen((snap) {
          if (!snap.exists) return;
          final raw = snap.data()?['criteria'] as List<dynamic>?;
          if (raw != null) {
            setState(() {
              _streetDanceCriteria = raw
                  .map(
                    (e) => ActiveCriterion.fromMap(e as Map<String, dynamic>),
                  )
                  .toList();
            });
          }
        });

    // 6. scoring_configs/focalPresentation
    _criteriaFPSub = _db
        .collection('scoring_configs')
        .doc('focalPresentation')
        .snapshots()
        .listen((snap) {
          if (!snap.exists) return;
          final raw = snap.data()?['criteria'] as List<dynamic>?;
          if (raw != null) {
            setState(() {
              _focalCriteria = raw
                  .map(
                    (e) => ActiveCriterion.fromMap(e as Map<String, dynamic>),
                  )
                  .toList();
            });
          }
        });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _liveTimer?.cancel();
    _groupsSub?.cancel();
    _scoresSub?.cancel();
    _penaltiesSub?.cancel();
    _metaSub?.cancel();
    _criteriaSDSub?.cancel();
    _criteriaFPSub?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  FIRESTORE WRITE ACTIONS
  // ══════════════════════════════════════════════════════════════

  Future<void> _finalizeResults() async {
    await _db.collection('results_meta').doc('current').set({
      'isFinalized': true,
      'finalizedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _addPenalty({
    required String groupId,
    required String reason,
    required double deduction,
    required String issuedBy,
  }) async {
    await _db.collection('penalties').add({
      'groupId': groupId,
      'reason': reason,
      'deduction': deduction,
      'issuedBy': issuedBy,
      'sessionId': 'current',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deletePenalty(String docId) async {
    await _db.collection('penalties').doc(docId).delete();
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildTabBar(),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildLiveRankingTab(),
              _buildJudgeBreakdownTab(),
              _buildPenaltiesTab(),
              _buildExportTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Results & Rankings',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PandanFest 2026 · Street Dance Competition · Finals',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildLiveToggle(),
        const SizedBox(width: 12),
        _buildStatusBadge(),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _resultsFinalized
                ? Colors.grey[300]
                : AppColors.primary,
            foregroundColor: _resultsFinalized ? Colors.grey : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          icon: Icon(
            _resultsFinalized ? Icons.lock_rounded : Icons.lock_open_rounded,
            size: 18,
          ),
          label: Text(
            _resultsFinalized ? 'Locked' : 'Finalize Results',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          onPressed: _resultsFinalized
              ? null
              : () => showDialog(
                  context: context,
                  builder: (_) => _buildFinalizeDialog(),
                ),
        ),
      ],
    );
  }

  Widget _buildLiveToggle() {
    return GestureDetector(
      onTap: _resultsFinalized
          ? null
          : () => setState(() => _liveMode = !_liveMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _liveMode
              ? AppColors.live.withOpacity(0.12)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _liveMode ? AppColors.live : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            if (_liveMode)
              _PulsingDot(color: AppColors.live)
            else
              Icon(
                Icons.pause_circle_outline_rounded,
                size: 14,
                color: Colors.grey[500],
              ),
            const SizedBox(width: 6),
            Text(
              _liveMode ? 'LIVE' : 'PAUSED',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _liveMode ? AppColors.live : Colors.grey[500],
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _resultsFinalized
            ? AppColors.accentGreen.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _resultsFinalized ? AppColors.accentGreen : AppColors.warning,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _resultsFinalized
                ? Icons.check_circle_rounded
                : Icons.pending_rounded,
            color: _resultsFinalized
                ? AppColors.accentGreen
                : AppColors.warning,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _resultsFinalized ? 'Finalized' : 'Tabulating…',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _resultsFinalized
                  ? AppColors.accentGreen
                  : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TAB BAR
  // ─────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        padding: const EdgeInsets.all(6),
        tabs: const [
          Tab(text: '🏆  Live Rankings'),
          Tab(text: '👨‍⚖️  Judge Breakdown'),
          Tab(text: '⚠️  Deductions'),
          Tab(text: '📤  Export'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 1 — LIVE RANKING BOARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLiveRankingTab() {
    final ranked = _rankedResults;
    if (ranked.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No scores submitted yet.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              'Rankings will appear once judges start submitting scores.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: ranked.length,
      itemBuilder: (ctx, i) => _buildLeaderboardRow(ranked[i], i),
    );
  }

  Widget _buildLeaderboardRow(_GroupResult group, int listIndex) {
    final isExpanded = _expandedGroupIndex == listIndex;
    final rank = _rankOf(group);
    final rankColors = {
      1: AppColors.goldRank,
      2: AppColors.silverRank,
      3: AppColors.bronzeRank,
    };
    final rc = rankColors[rank] ?? Colors.grey[400]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: rank <= 3
            ? Border.all(color: rc.withOpacity(0.35), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(
              () => _expandedGroupIndex = isExpanded ? null : listIndex,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? rc.withOpacity(0.15)
                          : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: rank <= 3
                          ? Text(
                              rank == 1
                                  ? '🥇'
                                  : rank == 2
                                  ? '🥈'
                                  : '🥉',
                              style: const TextStyle(fontSize: 22),
                            )
                          : Text(
                              '#$rank',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              group.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            if (group.penalties.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 11,
                                      color: AppColors.danger,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '-${group.totalPenalty.toStringAsFixed(1)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              group.barangay,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                group.theme,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.accentGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // Judge submission count
                            const SizedBox(width: 8),
                            Icon(
                              Icons.gavel_rounded,
                              size: 12,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${group.judgeEmails.length} judge(s)',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Score column
                  SizedBox(
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (group.totalPenalty > 0) ...[
                              Text(
                                group.rawTotal.toStringAsFixed(2),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              group.judgeEmails.isEmpty
                                  ? 'Awaiting…'
                                  : '${group.finalScore.toStringAsFixed(2)} pts',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: group.judgeEmails.isEmpty
                                    ? Colors.grey[400]
                                    : (rank <= 3 ? rc : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        if (group.judgeEmails.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (group.finalScore / 100).clamp(0.0, 1.0),
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                rank <= 3 ? rc : AppColors.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildQuickCriteriaExpand(group),
        ],
      ),
    );
  }

  Widget _buildQuickCriteriaExpand(_GroupResult group) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Average Criteria Scores',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          ...group.avgCriteriaScores.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 180,
                    child: Text(
                      e.key,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (e.value / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accentGreen,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    e.value.toStringAsFixed(2),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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

  // ═══════════════════════════════════════════════════════════════
  //  TAB 2 — JUDGE SCORE BREAKDOWN
  // ═══════════════════════════════════════════════════════════════

  Widget _buildJudgeBreakdownTab() {
    final ranked = _rankedResults;
    if (ranked.isEmpty) {
      return Center(
        child: Text(
          'No judge scores yet.',
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[400]),
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: ranked.map((g) => _buildGroupJudgeCard(g)).toList(),
      ),
    );
  }

  Widget _buildGroupJudgeCard(_GroupResult group) {
    final rank = _rankOf(group);
    // Build list of judge emails who have submitted for this group
    final judgeEmails = group.judgeEmails;
    final criteria = group.criteria;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
                        group.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${group.barangay} · ${group.theme}',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Final Score',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      judgeEmails.isEmpty
                          ? '—'
                          : group.finalScore.toStringAsFixed(2),
                      style: GoogleFonts.poppins(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (judgeEmails.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No scores submitted yet.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[400],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  border: TableBorder.all(
                    color: Colors.grey[200]!,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  children: [
                    // Header row
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[50]),
                      children: [
                        _tableHeader('Judge'),
                        ...criteria.map((c) => _tableHeader(c.name)),
                        _tableHeader('Weighted Total'),
                      ],
                    ),
                    // One row per judge
                    ...judgeEmails.map((email) {
                      final judgeTotal = group.judgeWeightedTotals[email] ?? 0;
                      return TableRow(
                        children: [
                          _tableCell(
                            resolveJudgeName(email),
                            bold: true,
                            color: Colors.grey[700]!,
                          ),
                          ...criteria.map((c) {
                            final score =
                                group.criteriaByJudge[c.id]?[email] ?? 0;
                            return _tableCellScore(score);
                          }),
                          _tableCell(
                            judgeTotal.toStringAsFixed(2),
                            bold: true,
                            color: AppColors.primary,
                          ),
                        ],
                      );
                    }),
                    // Average row
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFFFF8E1)),
                      children: [
                        _tableCell(
                          'Average',
                          bold: true,
                          color: Colors.black87,
                        ),
                        ...criteria.map((c) {
                          final avg = group.avgCriteriaScores[c.name] ?? 0;
                          return _tableCell(
                            avg.toStringAsFixed(2),
                            bold: true,
                            color: AppColors.accentGreen,
                          );
                        }),
                        _tableCell(
                          group.rawTotal.toStringAsFixed(2),
                          bold: true,
                          color: AppColors.accentGreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _tableCell(
    String text, {
    bool bold = false,
    Color color = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.w400,
          color: color,
        ),
      ),
    );
  }

  Widget _tableCellScore(double score) {
    Color bg;
    Color fg;
    if (score >= 80) {
      bg = AppColors.accentGreen.withOpacity(0.08);
      fg = AppColors.accentGreen;
    } else if (score >= 60) {
      bg = AppColors.warning.withOpacity(0.08);
      fg = AppColors.warning;
    } else {
      bg = AppColors.danger.withOpacity(0.08);
      fg = AppColors.danger;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          score.toStringAsFixed(1),
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 3 — PENALTIES / DEDUCTIONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPenaltiesTab() {
    final ranked = _rankedResults;
    final withPenalty = ranked.where((g) => g.penalties.isNotEmpty).toList();
    final clean = ranked.where((g) => g.penalties.isEmpty).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPenaltySummaryBanner(),
          const SizedBox(height: 20),
          if (!_resultsFinalized) ...[
            _buildAddPenaltyButton(),
            const SizedBox(height: 20),
          ],
          if (withPenalty.isNotEmpty) ...[
            _sectionLabel(
              '⚠️  Groups with Deductions',
              color: AppColors.danger,
            ),
            const SizedBox(height: 12),
            ...withPenalty.map(
              (g) => _buildPenaltyGroupCard(g, hasPenalty: true),
            ),
            const SizedBox(height: 20),
          ],
          _sectionLabel('✅  No Deductions', color: AppColors.accentGreen),
          const SizedBox(height: 12),
          ...clean.map((g) => _buildPenaltyGroupCard(g, hasPenalty: false)),
        ],
      ),
    );
  }

  Widget _buildPenaltySummaryBanner() {
    final totalDeductions = _rankedResults.fold(
      0.0,
      (s, g) => s + g.totalPenalty,
    );
    final affectedCount = _rankedResults
        .where((g) => g.penalties.isNotEmpty)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.danger.withOpacity(0.08),
            AppColors.warning.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel_rounded, color: AppColors.danger, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Penalty Overview',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '$affectedCount group(s) received deductions · '
                  '${totalDeductions.toStringAsFixed(1)} total points deducted',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Deducted',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                '-${totalDeductions.toStringAsFixed(1)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPenaltyButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        side: const BorderSide(color: AppColors.danger),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
      label: Text(
        'Add Penalty / Deduction',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      onPressed: () => showDialog(
        context: context,
        builder: (_) => _buildAddPenaltyDialog(),
      ),
    );
  }

  Widget _buildPenaltyGroupCard(
    _GroupResult group, {
    required bool hasPenalty,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: hasPenalty
            ? Border.all(color: AppColors.danger.withOpacity(0.25), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${_rankOf(group)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                group.name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (hasPenalty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${group.totalPenalty.toStringAsFixed(1)} pts',
                    style: GoogleFonts.poppins(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Clean',
                    style: GoogleFonts.poppins(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          if (hasPenalty) ...[
            const SizedBox(height: 12),
            ...group.penalties.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                            fontSize: 12,
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
                            p.reason,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Issued by: ${p.issuedBy}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Delete button (only before finalized)
                    if (!_resultsFinalized) ...[
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        tooltip: 'Remove penalty',
                        onPressed: () async {
                          await _deletePenalty(p.docId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              _snackBar(
                                'Penalty removed.',
                                AppColors.accentGreen,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                    Text(
                      '-${p.deduction.toStringAsFixed(1)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Raw: ${group.rawTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Final: ${group.finalScore.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddPenaltyDialog() {
    String? selectedGroupId;
    final reasonController = TextEditingController();
    final deductionController = TextEditingController();
    String? selectedIssuer;
    bool saving = false;

    final judgeNames = ['Head Judge', ..._allJudgeEmails.map(resolveJudgeName)];
    final judgeValues = ['Head Judge', ..._allJudgeEmails];

    return StatefulBuilder(
      builder: (ctx, setD) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              const SizedBox(width: 10),
              Text(
                'Add Penalty / Deduction',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Group dropdown (from Firestore groups)
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Dance Group'),
                  items: _groups
                      .map(
                        (g) => DropdownMenuItem(
                          value: g.id,
                          child: Text(
                            g.name,
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setD(() => selectedGroupId = v),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonController,
                  decoration: _inputDecoration('Reason for Deduction'),
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: deductionController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration('Deduction Points (e.g. 1.0)'),
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Issued By'),
                  items: List.generate(judgeNames.length, (i) {
                    return DropdownMenuItem(
                      value: judgeValues[i],
                      child: Text(
                        judgeNames[i],
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    );
                  }),
                  onChanged: (v) => setD(() => selectedIssuer = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: saving
                  ? null
                  : () async {
                      final groupId = selectedGroupId;
                      final reason = reasonController.text.trim();
                      final deduction = double.tryParse(
                        deductionController.text.trim(),
                      );
                      final issuer = selectedIssuer;

                      if (groupId == null ||
                          reason.isEmpty ||
                          deduction == null ||
                          issuer == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          _snackBar(
                            'Please fill in all fields.',
                            AppColors.warning,
                          ),
                        );
                        return;
                      }

                      setD(() => saving = true);
                      await _addPenalty(
                        groupId: groupId,
                        reason: reason,
                        deduction: deduction,
                        issuedBy: issuer,
                      );

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          _snackBar('Penalty recorded.', AppColors.danger),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Apply Penalty',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 4 — EXPORT (UI stubs — wire real export logic here)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildExportTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('📄  Generate PDF Report'),
          const SizedBox(height: 14),
          _buildExportCard(
            icon: Icons.picture_as_pdf_rounded,
            iconColor: const Color(0xFFE53935),
            title: 'Official Results Report (PDF)',
            description:
                'Full official report with rankings, criteria scores, judge breakdown, and penalty records.',
            tags: ['Rankings', 'Criteria', 'Judges', 'Penalties'],
            buttonLabel: 'Generate PDF',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              _snackBar('PDF report generated!', AppColors.accentGreen),
            ),
          ),
          const SizedBox(height: 14),
          _buildExportCard(
            icon: Icons.leaderboard_rounded,
            iconColor: const Color(0xFF1565C0),
            title: 'Live Scoreboard Summary (PDF)',
            description: 'Condensed scoreboard for live display or printing.',
            tags: ['Rankings', 'Final Scores'],
            buttonLabel: 'Generate PDF',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              _snackBar('Scoreboard PDF generated!', AppColors.accentGreen),
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('📊  Export Results Data'),
          const SizedBox(height: 14),
          _buildExportCard(
            icon: Icons.table_chart_rounded,
            iconColor: const Color(0xFF2E7D32),
            title: 'Export to Excel (.xlsx)',
            description:
                'Complete spreadsheet with rankings, judge scores, criteria matrix, and penalties.',
            tags: ['All Sheets', 'Judge Scores', 'Criteria', 'Penalties'],
            buttonLabel: 'Export Excel',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              _snackBar('Excel file exported!', AppColors.accentGreen),
            ),
          ),
          const SizedBox(height: 14),
          _buildExportCard(
            icon: Icons.data_object_rounded,
            iconColor: const Color(0xFF6A1B9A),
            title: 'Export to CSV (.csv)',
            description:
                'Lightweight flat-file export of final scores and rankings.',
            tags: ['Rankings', 'Final Scores', 'Lightweight'],
            buttonLabel: 'Export CSV',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              _snackBar('CSV file exported!', AppColors.accentGreen),
            ),
          ),
          const SizedBox(height: 14),
          _buildExportCard(
            icon: Icons.code_rounded,
            iconColor: const Color(0xFF00695C),
            title: 'Export Raw Data (JSON)',
            description:
                'Complete machine-readable export including all judge scores, criteria, and penalties.',
            tags: ['All Data', 'Developer Use'],
            buttonLabel: 'Export JSON',
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(_snackBar('JSON exported!', AppColors.accentGreen)),
          ),
          const SizedBox(height: 24),
          _buildExportPreviewTable(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildExportCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> tags,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text(
              buttonLabel,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildExportPreviewTable() {
    final ranked = _rankedResults;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Export Preview — Final Results',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  '${ranked.length} groups',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.primary),
              headingTextStyle: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              dataTextStyle: GoogleFonts.poppins(fontSize: 13),
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Rank')),
                DataColumn(label: Text('Group')),
                DataColumn(label: Text('Barangay')),
                DataColumn(label: Text('Theme')),
                DataColumn(label: Text('Raw Score')),
                DataColumn(label: Text('Deductions')),
                DataColumn(label: Text('Final Score')),
                DataColumn(label: Text('Judges')),
              ],
              rows: ranked.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final g = entry.value;
                return DataRow(
                  color: WidgetStateProperty.resolveWith((_) {
                    if (rank == 1) {
                      return AppColors.goldRank.withOpacity(0.06);
                    }
                    return null;
                  }),
                  cells: [
                    DataCell(
                      Text(
                        '#$rank',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        g.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(Text(g.barangay)),
                    DataCell(Text(g.theme)),
                    DataCell(Text(g.rawTotal.toStringAsFixed(2))),
                    DataCell(
                      Text(
                        g.totalPenalty > 0
                            ? '-${g.totalPenalty.toStringAsFixed(1)}'
                            : '—',
                        style: GoogleFonts.poppins(
                          color: g.totalPenalty > 0
                              ? AppColors.danger
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        g.judgeEmails.isEmpty
                            ? '—'
                            : g.finalScore.toStringAsFixed(2),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${g.judgeEmails.length} / 5',
                        style: GoogleFonts.poppins(
                          color: g.judgeEmails.length == 5
                              ? AppColors.accentGreen
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FINALIZE DIALOG
  // ─────────────────────────────────────────────

  Widget _buildFinalizeDialog() {
    bool saving = false;
    return StatefulBuilder(
      builder: (ctx, setD) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: 10),
              Text(
                'Finalize Results?',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Once finalized, scores will be locked and cannot be modified. '
            'Make sure all judges have submitted their scores and all penalties have been recorded.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: saving
                  ? null
                  : () async {
                      setD(() => saving = true);
                      await _finalizeResults();
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          _snackBar(
                            'Results finalized and locked! 🏆',
                            AppColors.accentGreen,
                          ),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Yes, Finalize',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  //  SHARED HELPERS
  // ─────────────────────────────────────────────

  Widget _sectionLabel(String text, {Color? color}) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: color ?? Colors.black87,
      ),
    );
  }

  SnackBar _snackBar(String message, Color color) {
    return SnackBar(
      content: Text(message, style: GoogleFonts.poppins()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PULSING DOT WIDGET
// ═══════════════════════════════════════════════════════════════

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
