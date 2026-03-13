<<<<<<< HEAD
import 'dart:async';
import 'package:flutter/foundation.dart';
=======
// ============================================================
// services.dart
// Central service file for PandanFest judging system.
// ============================================================

>>>>>>> d3f997342664a777ecb1a2022476c936528f9fa7
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pandan_fest/models/app_models.dart';

// ═══════════════════════════════════════════════════════════════════
// JUDGE SCREEN STATE
// ═══════════════════════════════════════════════════════════════════

enum JudgeScreenState { selectContestant, scoring, submitted, alreadyScored }

// ═══════════════════════════════════════════════════════════════════
// MAX VALUE FORMATTER
// ═══════════════════════════════════════════════════════════════════

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// ─────────────────────────────────────────────────────────────────────────────
// LiveSessionState  — singleton ChangeNotifier
//
// Uses localStorage to share state across browser tabs (Admin ↔ Judge).
// Polls every 500ms so judges see admin pushes in near-real-time.
// ─────────────────────────────────────────────────────────────────────────────

class LiveSessionState extends ChangeNotifier {
  LiveSessionState._() {
    // Poll localStorage every 500ms to pick up cross-tab changes
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _syncFromStorage();
    });
    _syncFromStorage();
  }

  static final LiveSessionState instance = LiveSessionState._();

  Timer? _pollTimer;

  // ── Keys ────────────────────────────────────────────────────────
  static const String _activeGroupPrefix = 'pf_active_group_';
  static const String _focalPushedKey    = 'pf_focal_pushed';

  // ── In-memory cache (kept in sync with localStorage) ────────────
  final Map<String, String?> _activeGroupPerStage = {};
  String? _pushedFocalGroupId;

  // ── Public reads ────────────────────────────────────────────────
  String? activeGroupId(String stageId) => _activeGroupPerStage[stageId];
  String? get pushedFocalGroupId => _pushedFocalGroupId;

  // ── Sync from localStorage (called on each poll tick) ───────────
  void _syncFromStorage() {
    bool changed = false;

    // Active groups per stage
    final keys = html.window.localStorage.keys
        .where((k) => k.startsWith(_activeGroupPrefix))
        .toList();
    final stageIds = keys.map((k) => k.replaceFirst(_activeGroupPrefix, '')).toList();

    for (final stageId in stageIds) {
      final val = html.window.localStorage['$_activeGroupPrefix$stageId'];
      if (_activeGroupPerStage[stageId] != val) {
        _activeGroupPerStage[stageId] = val;
        changed = true;
      }
    }

    // Focal pushed group
    final focal = html.window.localStorage[_focalPushedKey];
    if (_pushedFocalGroupId != focal) {
      _pushedFocalGroupId = focal;
      changed = true;
    }

    if (changed) notifyListeners();
  }

  // ── Writes (write to localStorage + update cache immediately) ───

  void setActiveGroup(String stageId, String? groupId) {
    if (groupId == null) {
      html.window.localStorage.remove('$_activeGroupPrefix$stageId');
    } else {
      html.window.localStorage['$_activeGroupPrefix$stageId'] = groupId;
    }
    _activeGroupPerStage[stageId] = groupId;
    notifyListeners();
  }

  void clearActiveGroup(String stageId) => setActiveGroup(stageId, null);

  void pushFocalContestant(String groupId) {
    html.window.localStorage[_focalPushedKey] = groupId;
    _pushedFocalGroupId = groupId;
    notifyListeners();
  }

  void clearFocalPush() {
    html.window.localStorage.remove(_focalPushedKey);
    _pushedFocalGroupId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

class MaxValueFormatter extends TextInputFormatter {
  final double maxValue;
  MaxValueFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final parsed = double.tryParse(newValue.text);
    if (parsed == null) return oldValue;
    if (parsed > maxValue) return oldValue;
    return newValue;
  }
}

// ═══════════════════════════════════════════════════════════════════
// JUDGE REGISTRY
// ═══════════════════════════════════════════════════════════════════

class _JudgeInfo {
  final String name;
  final String position;
  const _JudgeInfo(this.name, this.position);
}

const Map<String, _JudgeInfo> _judgeRegistry = {
  'judge1@pandanfest.com': _JudgeInfo('Judge 1', 'Associate Judge'),
  'judge2@pandanfest.com': _JudgeInfo('Judge 2', 'Associate Judge'),
  'judge3@pandanfest.com': _JudgeInfo('Judge 3', 'Associate Judge'),
  'judge4@pandanfest.com': _JudgeInfo('Judge 4', 'Associate Judge'),
  'judge5@pandanfest.com': _JudgeInfo('Judge 5', 'Associate Judge'),
};

String resolveJudgeName(String judgeEmail) =>
    _judgeRegistry[judgeEmail]?.name ?? judgeEmail;

String resolveJudgePosition(String judgeEmail) =>
    _judgeRegistry[judgeEmail]?.position ?? 'Judge';

// ═══════════════════════════════════════════════════════════════════
// STATIC STAGE
// ═══════════════════════════════════════════════════════════════════

const List<CompetitionStage> staticStages = [
  CompetitionStage(id: 's1', name: 'Street Parade', order: 1),
];

// ═══════════════════════════════════════════════════════════════════
// STREET DANCE CRITERIA
// ═══════════════════════════════════════════════════════════════════

const List<ActiveCriterion> streetDanceCriteria = [
  ActiveCriterion(
    id: 'sd_1',
    name: 'Choreography',
    weight: 20,
    maxScore: 100,
    description:
        'Creativity, synchronization, and difficulty of dance routines.',
  ),
  ActiveCriterion(
    id: 'sd_2',
    name: 'Execution',
    weight: 10,
    maxScore: 100,
    description: 'Precision, timing, and overall coordination.',
  ),
  ActiveCriterion(
    id: 'sd_3',
    name: 'Energy and Stage Presence',
    weight: 10,
    maxScore: 100,
    description: 'Enthusiasm and engagement with the audience.',
  ),
  ActiveCriterion(
    id: 'sd_4',
    name: 'Relevance to the Theme',
    weight: 10,
    maxScore: 100,
    description:
        'Performers must wear and use distinct costumes and props inspired by their respective culture/festival.',
  ),
  ActiveCriterion(
    id: 'sd_5',
    name: 'Creativity and Aesthetic',
    weight: 10,
    maxScore: 100,
    description: 'Design, color harmony, and artistic impact.',
  ),
  ActiveCriterion(
    id: 'sd_6',
    name: 'Originality',
    weight: 10,
    maxScore: 100,
    description: 'Innovative and culturally relevant music.',
  ),
  ActiveCriterion(
    id: 'sd_7',
    name: 'Synchronization with Movements',
    weight: 10,
    maxScore: 100,
    description: 'Music and steps in perfect harmony.',
  ),
  ActiveCriterion(
    id: 'sd_8',
    name: 'Portrayal of Theme',
    weight: 10,
    maxScore: 100,
    description: 'Adherence to the festival\'s cultural identity and story.',
  ),
  ActiveCriterion(
    id: 'sd_9',
    name: 'Impact and Emotional Appeal',
    weight: 10,
    maxScore: 100,
    description:
        'Effectiveness in delivering a message or cultural representation.',
  ),
];

// ═══════════════════════════════════════════════════════════════════
// FOCAL PRESENTATION CRITERIA
// ═══════════════════════════════════════════════════════════════════

const List<ActiveCriterion> focalPresentationCriteria = [
  ActiveCriterion(
    id: 'fp_1',
    name: 'Relevance to the Festival Theme',
    weight: 15,
    maxScore: 100,
    description:
        'The presentation must highlight the essence of their festival, emphasizing culture, history, and local pride.',
  ),
  ActiveCriterion(
    id: 'fp_2',
    name: 'Creativity and Innovation',
    weight: 15,
    maxScore: 100,
    description:
        'Unique and fresh interpretation of the theme through storytelling and visuals.',
  ),
  ActiveCriterion(
    id: 'fp_3',
    name: 'Originality of Choreography',
    weight: 15,
    maxScore: 100,
    description:
        'Creative dance routines that blend tradition with modern techniques.',
  ),
  ActiveCriterion(
    id: 'fp_4',
    name: 'Precision and Synchronization',
    weight: 10,
    maxScore: 100,
    description: 'Cohesive and well-coordinated movements.',
  ),
  ActiveCriterion(
    id: 'fp_5',
    name: 'Costume and Props Design',
    weight: 15,
    maxScore: 100,
    description:
        'Vibrant and artistic costumes and props that reflect their cultural traditions.',
  ),
  ActiveCriterion(
    id: 'fp_6',
    name: 'Stage Design and Presentation',
    weight: 10,
    maxScore: 100,
    description:
        'Effective use of space, props, and stage elements to enhance the performance.',
  ),
  ActiveCriterion(
    id: 'fp_7',
    name: 'Cultural Integrity & Overall Impact',
    weight: 10,
    maxScore: 100,
    description:
        'Authentic representation of traditions that captivate the audience and evoke emotions.',
  ),
  ActiveCriterion(
    id: 'fp_8',
    name: 'Musicality',
    weight: 10,
    maxScore: 100,
    description: 'Choice of music, editing, and climatic transitions.',
  ),
];

// ═══════════════════════════════════════════════════════════════════
// STATIC CRITERIA
// ═══════════════════════════════════════════════════════════════════

const List<ActiveCriterion> festivalQueenCriteria = [
  ActiveCriterion(
    id: 'fq_1',
    name: 'Stage Presence / Personality & Performance',
    weight: 30,
    maxScore: 100,
    description:
        'Confidence, poise, and ability to showcase the dance effectively.',
  ),
  ActiveCriterion(
    id: 'fq_2',
    name: 'Costume Creativity & Cultural Relevance',
    weight: 10,
    maxScore: 100,
    description:
        'Uniqueness of design, innovative use of materials, overall artistic merit, and accuracy in representing cultural heritage and tradition.',
  ),
  ActiveCriterion(
    id: 'fq_3',
    name: 'Overall Impact',
    weight: 10,
    maxScore: 100,
    description: 'Totality and overall performance/impression.',
  ),
];

const List<ActiveCriterion> staticCriteria = [
  ...streetDanceCriteria,
  ...focalPresentationCriteria,
  ...festivalQueenCriteria,
];

// ═══════════════════════════════════════════════════════════════════
// JUDGE SCORE SERVICE
//
// IMPORTANT CHANGE: Document ID is now:
//   "{judgeEmail}_{groupId}_{stationId}"
//
// This allows the same judge to score the same group at each of
// the 4 stations separately for Street Dance.
//
// For Focal Presentation there is only one station per push so
// the stationId naturally differentiates sessions.
// ═══════════════════════════════════════════════════════════════════

class JudgeScoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream the live-session document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> sessionStream() =>
      _db.collection('live_sessions').doc('current').snapshots();

  /// Stream all groups ordered by performanceOrder.
  Stream<List<PerformingGroup>> groupsStream() => _db
      .collection('dance_groups')
      .orderBy('performanceOrder')
      .snapshots()
      .map(
        (snap) => snap.docs.map((doc) {
          final d = doc.data();
          return PerformingGroup(
            id: doc.id,
            name: d['name'] as String? ?? '',
            barangay: d['community'] as String? ?? '',
            theme: d['theme'] as String? ?? '',
            performanceOrder: d['performanceOrder'] as int? ?? 0,
          );
        }).toList(),
      );

  /// Submit scores for a group at a specific station.
  /// Doc ID: "{judgeEmail}_{groupId}_{stationId}"
  Future<void> submitScores({
    required String judgeEmail,
    required String groupId,
    required String stationId,
    required Map<String, double> scores,
    required double weightedTotal,
  }) async {
    final docId = '${judgeEmail}_${groupId}_$stationId';
    await _db.collection('judge_scores').doc(docId).set({
      'judgeEmail': judgeEmail,
      'groupId': groupId,
      'stationId': stationId,
      'sessionId': 'current',
      'scores': scores,
      'weightedTotal': weightedTotal,
      'isSubmitted': true,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns a Set of "{groupId}_{stationId}" keys for which this
  /// judge has already submitted scores in the current session.
  ///
  /// Using composite keys allows the judge screens to check whether
  /// a specific group+station combo has been scored without ambiguity.
  Future<Set<String>> loadScoredGroupStationKeys(String judgeEmail) async {
    final snap = await _db
        .collection('judge_scores')
        .where('judgeEmail', isEqualTo: judgeEmail)
        .where('sessionId', isEqualTo: 'current')
        .where('isSubmitted', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) {
          final data = d.data();
          final gId = data['groupId'] as String? ?? '';
          final sId = data['stationId'] as String? ?? '';
          return '${gId}_$sId';
        })
        .where((key) => key != '_')
        .toSet();
  }

  FirebaseFirestore get db => _db;
}

// ═══════════════════════════════════════════════════════════════════
// RANKINGS HELPER
// ═══════════════════════════════════════════════════════════════════

List<RankingEntry> computeRankings(
  Map<String, List<JudgeScore>> judgeScores,
  List<PerformingGroup> groups,
  List<ActiveCriterion> criteria,
) {
  final List<RankingEntry> entries = [];

  judgeScores.forEach((groupId, scores) {
    final submitted = scores
        .where((j) => j.isSubmitted && j.scores.isNotEmpty)
        .toList();
    if (submitted.isEmpty) return;

    final avg =
        submitted.fold(0.0, (sum, j) => sum + j.totalWeighted(criteria)) /
        submitted.length;

    final group = groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => PerformingGroup(
        id: groupId,
        name: 'Unknown',
        barangay: '',
        theme: '',
        performanceOrder: 0,
      ),
    );

    entries.add(
      RankingEntry(
        groupId: groupId,
        groupName: group.name,
        barangay: group.barangay,
        averageScore: avg,
        rank: 0,
      ),
    );
  });

  entries.sort((a, b) => b.averageScore.compareTo(a.averageScore));

  return entries
      .asMap()
      .entries
      .map(
        (e) => RankingEntry(
          groupId: e.value.groupId,
          groupName: e.value.groupName,
          barangay: e.value.barangay,
          averageScore: e.value.averageScore,
          rank: e.key + 1,
        ),
      )
      .toList();
}

Map<String, List<JudgeScore>> get resolvedJudgeScores => {};
