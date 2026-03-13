// ============================================================
// app_models.dart
// Shared data models used by both Admin and Judge screens.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

// ================= MODELS =================

class PerformingGroup {
  final String id;
  final String name;
  final String barangay;
  final String theme;
  final int performanceOrder;

  const PerformingGroup({
    required this.id,
    required this.name,
    required this.barangay,
    required this.theme,
    required this.performanceOrder,
  });
}

class ActiveCriterion {
  final String id;
  final String name;
  final double weight;
  final double maxScore;
  final double minScore;
  final String description;

  const ActiveCriterion({
    required this.id,
    required this.name,
    required this.weight,
    required this.maxScore,
    this.minScore = 0,
    this.description = '',
  });

  factory ActiveCriterion.fromMap(Map<String, dynamic> m) => ActiveCriterion(
    id: m['id'] as String,
    name: m['name'] as String,
    weight: (m['weight'] as num).toDouble(),
    maxScore: (m['maxScore'] as num?)?.toDouble() ?? 100,
    minScore: (m['minScore'] as num?)?.toDouble() ?? 0,
    description: m['description'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'weight': weight,
    'maxScore': maxScore,
    'minScore': minScore,
    'description': description,
  };
}

class JudgeScore {
  final String judgeId;
  final String judgeName;
  final Map<String, double> scores; // criterionId -> score
  final bool isSubmitted;
  final DateTime? submittedAt;

  const JudgeScore({
    required this.judgeId,
    required this.judgeName,
    required this.scores,
    required this.isSubmitted,
    this.submittedAt,
  });

  /// Computes the weighted total against the shared criteria list.
  double totalWeighted(List<ActiveCriterion> criteria) {
    return scores.entries.fold(0.0, (sum, e) {
      final criterion = criteria.firstWhere(
        (c) => c.id == e.key,
        orElse: () =>
            const ActiveCriterion(id: '', name: '', weight: 0, maxScore: 100),
      );
      return sum + (e.value * criterion.weight / 100);
    });
  }

  /// Build a JudgeScore from a Firestore document map.
  factory JudgeScore.fromFirestore(Map<String, dynamic> d) => JudgeScore(
    judgeId: d['judgeEmail'] as String? ?? '',
    judgeName: d['judgeEmail'] as String? ?? '',
    scores: Map<String, double>.from(
      (d['scores'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
    ),
    isSubmitted: d['isSubmitted'] as bool? ?? false,
    submittedAt: (d['submittedAt'] as Timestamp?)?.toDate(),
  );

  /// Serialize to Firestore document.
  /// Document ID should be "{judgeEmail}_{groupId}" to prevent duplicates.
  Map<String, dynamic> toFirestore({
    required String groupId,
    required String sessionId,
  }) => {
    'judgeEmail': judgeId,
    'groupId': groupId,
    'sessionId': sessionId,
    'scores': scores,
    'isSubmitted': isSubmitted,
    'submittedAt': isSubmitted ? FieldValue.serverTimestamp() : null,
  };
}

class RankingEntry {
  final String groupId;
  final String groupName;
  final String barangay;
  final double averageScore;
  final int rank;

  const RankingEntry({
    required this.groupId,
    required this.groupName,
    required this.barangay,
    required this.averageScore,
    required this.rank,
  });
}

class AppJudge {
  final String id;
  final String name;
  final String position;

  const AppJudge({
    required this.id,
    required this.name,
    required this.position,
  });
}

// ================= STATIC SAMPLE DATA =================
// TODO: Replace with Firebase Firestore streams when integrating.

const List<PerformingGroup> staticGroups = [
  PerformingGroup(
    id: 'g1',
    name: 'Sayaw Pandan',
    barangay: 'Brgy. Pandan',
    theme: 'Urban Fusion',
    performanceOrder: 1,
  ),
  PerformingGroup(
    id: 'g2',
    name: 'Ritmo Barangay',
    barangay: 'Brgy. San Isidro',
    theme: 'Cultural Heritage',
    performanceOrder: 2,
  ),
  PerformingGroup(
    id: 'g3',
    name: 'Kalye Kings',
    barangay: 'Brgy. Malaya',
    theme: 'Hip-Hop Street',
    performanceOrder: 3,
  ),
  PerformingGroup(
    id: 'g4',
    name: 'Alon Dancers',
    barangay: 'Brgy. Bagong Silang',
    theme: 'Contemporary Wave',
    performanceOrder: 4,
  ),
];

const List<ActiveCriterion> staticCriteria = [
  ActiveCriterion(
    id: 'c1',
    name: 'Choreography',
    weight: 25,
    maxScore: 100,
    description: 'Creativity, complexity, and execution of dance moves.',
  ),
  ActiveCriterion(
    id: 'c2',
    name: 'Synchronization',
    weight: 20,
    maxScore: 100,
    description: 'Uniformity and timing precision among all members.',
  ),
  ActiveCriterion(
    id: 'c3',
    name: 'Costume',
    weight: 15,
    maxScore: 100,
    description: 'Visual appeal, thematic relevance, and overall presentation.',
  ),
  ActiveCriterion(
    id: 'c4',
    name: 'Musicality',
    weight: 20,
    maxScore: 100,
    description: 'Responsiveness and interpretation of the music.',
  ),
  ActiveCriterion(
    id: 'c5',
    name: 'Overall Impact',
    weight: 20,
    maxScore: 100,
    description: 'Audience engagement, energy, and stage presence.',
  ),
];

const List<AppJudge> staticJudges = [
  AppJudge(id: 'j1', name: 'Judge Reyes', position: 'Head Judge'),
  AppJudge(id: 'j2', name: 'Judge Santos', position: 'Associate Judge'),
  AppJudge(id: 'j3', name: 'Judge Cruz', position: 'Associate Judge'),
];

// Simulated scores per group per judge
// TODO: Replace with Firestore collection listener.
final Map<String, List<JudgeScore>> staticJudgeScores = {
  'g1': [
    const JudgeScore(
      judgeId: 'j1',
      judgeName: 'Judge Reyes',
      scores: {'c1': 88, 'c2': 90, 'c3': 85, 'c4': 91, 'c5': 87},
      isSubmitted: true,
    ),
    const JudgeScore(
      judgeId: 'j2',
      judgeName: 'Judge Santos',
      scores: {'c1': 92, 'c2': 88, 'c3': 90, 'c4': 86, 'c5': 93},
      isSubmitted: true,
    ),
    const JudgeScore(
      judgeId: 'j3',
      judgeName: 'Judge Cruz',
      scores: {'c1': 85, 'c2': 84, 'c3': 88, 'c4': 89, 'c5': 86},
      isSubmitted: false,
    ),
  ],
  'g2': [
    const JudgeScore(
      judgeId: 'j1',
      judgeName: 'Judge Reyes',
      scores: {'c1': 80, 'c2': 82, 'c3': 79, 'c4': 83, 'c5': 81},
      isSubmitted: true,
    ),
    const JudgeScore(
      judgeId: 'j2',
      judgeName: 'Judge Santos',
      scores: {'c1': 84, 'c2': 80, 'c3': 83, 'c4': 78, 'c5': 82},
      isSubmitted: true,
    ),
    const JudgeScore(
      judgeId: 'j3',
      judgeName: 'Judge Cruz',
      scores: {'c1': 79, 'c2': 77, 'c3': 81, 'c4': 80, 'c5': 78},
      isSubmitted: true,
    ),
  ],
  'g3': [
    const JudgeScore(
      judgeId: 'j1',
      judgeName: 'Judge Reyes',
      scores: {'c1': 86, 'c2': 85, 'c3': 84, 'c4': 87, 'c5': 88},
      isSubmitted: true,
    ),
    const JudgeScore(
      judgeId: 'j2',
      judgeName: 'Judge Santos',
      scores: {'c1': 89, 'c2': 87, 'c3': 86, 'c4': 84, 'c5': 90},
      isSubmitted: false,
    ),
    const JudgeScore(
      judgeId: 'j3',
      judgeName: 'Judge Cruz',
      scores: {},
      isSubmitted: false,
    ),
  ],
  'g4': [
    const JudgeScore(
      judgeId: 'j1',
      judgeName: 'Judge Reyes',
      scores: {},
      isSubmitted: false,
    ),
    const JudgeScore(
      judgeId: 'j2',
      judgeName: 'Judge Santos',
      scores: {},
      isSubmitted: false,
    ),
    const JudgeScore(
      judgeId: 'j3',
      judgeName: 'Judge Cruz',
      scores: {},
      isSubmitted: false,
    ),
  ],
};

// ================= HELPERS =================

/// Computes live rankings from all submitted judge scores.
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

// ================= JUDGE NAME HELPER =================

/// Returns the display name for a judge by their id,
/// falling back to the raw judgeName field if not found.
String resolveJudgeName(String judgeId) {
  final match = staticJudges.firstWhere(
    (j) => j.id == judgeId,
    orElse: () => AppJudge(id: judgeId, name: judgeId, position: ''),
  );
  return match.name;
}

/// Returns the position for a judge by their id.
String resolveJudgePosition(String judgeId) {
  final match = staticJudges.firstWhere(
    (j) => j.id == judgeId,
    orElse: () => AppJudge(id: judgeId, name: judgeId, position: ''),
  );
  return match.position;
}

/// Returns the static resolved judge scores (used as fallback
/// before Firestore data loads in the Live Control Panel).
/// The Live Control Panel replaces this with live Firestore
/// data via its _liveJudgeScores listener.
Map<String, List<JudgeScore>> get resolvedJudgeScores {
  return staticJudgeScores.map((groupId, scores) {
    final resolved = scores
        .map(
          (s) => JudgeScore(
            judgeId: s.judgeId,
            judgeName: resolveJudgeName(s.judgeId),
            scores: s.scores,
            isSubmitted: s.isSubmitted,
          ),
        )
        .toList();
    return MapEntry(groupId, resolved);
  });
}
