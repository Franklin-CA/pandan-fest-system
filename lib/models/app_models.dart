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

// ═══════════════════════════════════════════════════════════════════
// COMPETITION STAGE
//
// Used by JudgeTopBar to display which stage/round is active.
// Defined here so both services.dart and judge screens can reference it.
// ═══════════════════════════════════════════════════════════════════

class CompetitionStage {
  final String id;
  final String name;
  final int order;

  const CompetitionStage({
    required this.id,
    required this.name,
    required this.order,
  });
}

// NOTE: staticGroups removed — groups are now loaded exclusively
// from the dance_groups Firestore collection via JudgeScoreService.groupsStream()
// and LiveControlPanel._listenGroups().
