// ============================================================
// app_models.dart — PandanFest 2026
// Shared data models for Admin and Judge screens.
// ============================================================

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
  final String description;

  const ActiveCriterion({
    required this.id,
    required this.name,
    required this.weight,
    required this.maxScore,
    this.description = '',
  });
}

class JudgeScore {
  final String judgeId;
  final String judgeName;
  final Map<String, double> scores;
  final bool isSubmitted;

  const JudgeScore({
    required this.judgeId,
    required this.judgeName,
    required this.scores,
    required this.isSubmitted,
  });

  double totalWeighted(List<ActiveCriterion> criteria) {
    return scores.entries.fold(0.0, (sum, e) {
      final criterion = criteria.firstWhere(
        (c) => c.id == e.key,
        orElse: () => const ActiveCriterion(id: '', name: '', weight: 0, maxScore: 100),
      );
      return sum + (e.value * criterion.weight / 100);
    });
  }
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
  final String stageId;

  const AppJudge({
    required this.id,
    required this.name,
    required this.position,
    required this.stageId,
  });
}

// ─────────────────────────────────────────────────────────────
// STAGE MODEL
// ─────────────────────────────────────────────────────────────

class CompetitionStage {
  final String id;
  final String name;
  final String description;
  final int order;

  const CompetitionStage({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
  });
}

// ─────────────────────────────────────────────────────────────
// OVERALL RANKING (sum of all 3 stage average scores)
// ─────────────────────────────────────────────────────────────

class OverallRankingEntry {
  final String groupId;
  final String groupName;
  final String barangay;
  final Map<String, double> stageScores; // stageId -> avg score
  final double totalScore;              // sum across stages
  final int rank;

  const OverallRankingEntry({
    required this.groupId,
    required this.groupName,
    required this.barangay,
    required this.stageScores,
    required this.totalScore,
    required this.rank,
  });
}

// ================= STATIC DATA =================

const List<CompetitionStage> staticStages = [
  CompetitionStage(id: 's1', name: 'Stage 1', description: 'Opening parade station — entrance and formation.', order: 1),
  CompetitionStage(id: 's2', name: 'Stage 2', description: 'Main performance area — full routine showcase.', order: 2),
  CompetitionStage(id: 's3', name: 'Stage 3', description: 'Final parade station — closing impression and exit.', order: 3),
];

const List<PerformingGroup> staticGroups = [
  PerformingGroup(id: 'g1', name: 'Sayaw Pandan',   barangay: 'Brgy. Pandan',        theme: 'Urban Fusion',      performanceOrder: 1),
  PerformingGroup(id: 'g2', name: 'Ritmo Barangay', barangay: 'Brgy. San Isidro',    theme: 'Cultural Heritage', performanceOrder: 2),
  PerformingGroup(id: 'g3', name: 'Kalye Kings',    barangay: 'Brgy. Malaya',        theme: 'Hip-Hop Street',    performanceOrder: 3),
  PerformingGroup(id: 'g4', name: 'Alon Dancers',   barangay: 'Brgy. Bagong Silang', theme: 'Contemporary Wave', performanceOrder: 4),
];

// ── Original / generic criteria (kept for backward compat) ──
const List<ActiveCriterion> staticCriteria = [
  ActiveCriterion(id: 'c1', name: 'Choreography',   weight: 25, maxScore: 100, description: 'Creativity, complexity, and execution of dance moves.'),
  ActiveCriterion(id: 'c2', name: 'Synchronization', weight: 20, maxScore: 100, description: 'Uniformity and timing precision among all members.'),
  ActiveCriterion(id: 'c3', name: 'Costume',         weight: 15, maxScore: 100, description: 'Visual appeal, thematic relevance, and overall presentation.'),
  ActiveCriterion(id: 'c4', name: 'Musicality',      weight: 20, maxScore: 100, description: 'Responsiveness and interpretation of the music.'),
  ActiveCriterion(id: 'c5', name: 'Overall Impact',  weight: 20, maxScore: 100, description: 'Audience engagement, energy, and stage presence.'),
];

// ── Street Dance criteria ──
const List<ActiveCriterion> streetDanceCriteria = [
  ActiveCriterion(id: 'sd1', name: 'Street Dance Technique',    weight: 25, maxScore: 100, description: 'Mastery of street dance styles (hip-hop, waacking, locking, popping, etc.).'),
  ActiveCriterion(id: 'sd2', name: 'Choreography & Creativity', weight: 25, maxScore: 100, description: 'Originality, creativity, and complexity of choreography.'),
  ActiveCriterion(id: 'sd3', name: 'Synchronization',           weight: 20, maxScore: 100, description: 'Uniformity and timing precision among all members.'),
  ActiveCriterion(id: 'sd4', name: 'Musicality & Rhythm',       weight: 15, maxScore: 100, description: 'Responsiveness and interpretation of the music and beat.'),
  ActiveCriterion(id: 'sd5', name: 'Costume & Presentation',    weight: 15, maxScore: 100, description: 'Visual appeal, street-themed costume, and overall stage presence.'),
];

// ── Focal Presentation criteria ──
const List<ActiveCriterion> focalPresentationCriteria = [
  ActiveCriterion(id: 'fp1', name: 'Focal Performance',         weight: 30, maxScore: 100, description: 'Standout execution by the designated focal performer(s).'),
  ActiveCriterion(id: 'fp2', name: 'Artistic Expression',       weight: 25, maxScore: 100, description: 'Emotional depth, storytelling, and artistic quality of the presentation.'),
  ActiveCriterion(id: 'fp3', name: 'Crowd Engagement',          weight: 20, maxScore: 100, description: 'Ability to captivate and engage the audience throughout the performance.'),
  ActiveCriterion(id: 'fp4', name: 'Costume & Props',           weight: 15, maxScore: 100, description: 'Appropriateness and visual impact of costumes and props used.'),
  ActiveCriterion(id: 'fp5', name: 'Overall Showmanship',       weight: 10, maxScore: 100, description: 'General stage presence, confidence, and entertainment value.'),
];

// Each judge is exclusive to ONE stage
const List<AppJudge> staticJudges = [
  AppJudge(id: 'j1', name: 'Judge Reyes',    position: 'Head Judge',      stageId: 's1'),
  AppJudge(id: 'j2', name: 'Judge Santos',   position: 'Associate Judge', stageId: 's1'),
  AppJudge(id: 'j3', name: 'Judge Cruz',     position: 'Head Judge',      stageId: 's2'),
  AppJudge(id: 'j4', name: 'Judge Bautista', position: 'Associate Judge', stageId: 's2'),
  AppJudge(id: 'j5', name: 'Judge Lim',      position: 'Head Judge',      stageId: 's3'),
  AppJudge(id: 'j6', name: 'Judge Mendoza',  position: 'Associate Judge', stageId: 's3'),
];

// stageId -> groupId -> [JudgeScore]
final Map<String, Map<String, List<JudgeScore>>> staticStageJudgeScores = {
  's1': {
    'g1': [
      const JudgeScore(judgeId: 'j1', judgeName: 'Judge Reyes',  scores: {'c1': 88, 'c2': 90, 'c3': 85, 'c4': 91, 'c5': 87}, isSubmitted: true),
      const JudgeScore(judgeId: 'j2', judgeName: 'Judge Santos', scores: {'c1': 92, 'c2': 88, 'c3': 90, 'c4': 86, 'c5': 93}, isSubmitted: true),
    ],
    'g2': [
      const JudgeScore(judgeId: 'j1', judgeName: 'Judge Reyes',  scores: {'c1': 80, 'c2': 82, 'c3': 79, 'c4': 83, 'c5': 81}, isSubmitted: true),
      const JudgeScore(judgeId: 'j2', judgeName: 'Judge Santos', scores: {'c1': 84, 'c2': 80, 'c3': 83, 'c4': 78, 'c5': 82}, isSubmitted: true),
    ],
    'g3': [
      const JudgeScore(judgeId: 'j1', judgeName: 'Judge Reyes',  scores: {'c1': 86, 'c2': 85, 'c3': 84, 'c4': 87, 'c5': 88}, isSubmitted: true),
      const JudgeScore(judgeId: 'j2', judgeName: 'Judge Santos', scores: {'c1': 89, 'c2': 87, 'c3': 86, 'c4': 84, 'c5': 90}, isSubmitted: true),
    ],
    'g4': [
      const JudgeScore(judgeId: 'j1', judgeName: 'Judge Reyes',  scores: {'c1': 91, 'c2': 89, 'c3': 90, 'c4': 92, 'c5': 88}, isSubmitted: true),
      const JudgeScore(judgeId: 'j2', judgeName: 'Judge Santos', scores: {'c1': 87, 'c2': 90, 'c3': 88, 'c4': 91, 'c5': 89}, isSubmitted: false),
    ],
  },
  's2': {
    'g1': [
      const JudgeScore(judgeId: 'j3', judgeName: 'Judge Cruz',     scores: {'c1': 91, 'c2': 89, 'c3': 88, 'c4': 93, 'c5': 90}, isSubmitted: true),
      const JudgeScore(judgeId: 'j4', judgeName: 'Judge Bautista', scores: {'c1': 90, 'c2': 91, 'c3': 87, 'c4': 89, 'c5': 92}, isSubmitted: true),
    ],
    'g2': [
      const JudgeScore(judgeId: 'j3', judgeName: 'Judge Cruz',     scores: {'c1': 83, 'c2': 84, 'c3': 82, 'c4': 85, 'c5': 83}, isSubmitted: true),
      const JudgeScore(judgeId: 'j4', judgeName: 'Judge Bautista', scores: {'c1': 85, 'c2': 83, 'c3': 84, 'c4': 82, 'c5': 86}, isSubmitted: true),
    ],
    'g3': [
      const JudgeScore(judgeId: 'j3', judgeName: 'Judge Cruz',     scores: {'c1': 88, 'c2': 87, 'c3': 85, 'c4': 89, 'c5': 88}, isSubmitted: true),
      const JudgeScore(judgeId: 'j4', judgeName: 'Judge Bautista', scores: {'c1': 86, 'c2': 88, 'c3': 87, 'c4': 86, 'c5': 87}, isSubmitted: false),
    ],
    'g4': [
      const JudgeScore(judgeId: 'j3', judgeName: 'Judge Cruz',     scores: {'c1': 93, 'c2': 91, 'c3': 92, 'c4': 94, 'c5': 91}, isSubmitted: true),
      const JudgeScore(judgeId: 'j4', judgeName: 'Judge Bautista', scores: {'c1': 90, 'c2': 92, 'c3': 89, 'c4': 93, 'c5': 90}, isSubmitted: true),
    ],
  },
  's3': {
    'g1': [
      const JudgeScore(judgeId: 'j5', judgeName: 'Judge Lim',     scores: {'c1': 89, 'c2': 91, 'c3': 87, 'c4': 90, 'c5': 88}, isSubmitted: true),
      const JudgeScore(judgeId: 'j6', judgeName: 'Judge Mendoza', scores: {'c1': 93, 'c2': 90, 'c3': 92, 'c4': 91, 'c5': 94}, isSubmitted: true),
    ],
    'g2': [
      const JudgeScore(judgeId: 'j5', judgeName: 'Judge Lim',     scores: {'c1': 82, 'c2': 83, 'c3': 80, 'c4': 84, 'c5': 82}, isSubmitted: true),
      const JudgeScore(judgeId: 'j6', judgeName: 'Judge Mendoza', scores: {'c1': 84, 'c2': 82, 'c3': 83, 'c4': 81, 'c5': 85}, isSubmitted: false),
    ],
    'g3': [
      const JudgeScore(judgeId: 'j5', judgeName: 'Judge Lim',     scores: {'c1': 87, 'c2': 88, 'c3': 86, 'c4': 89, 'c5': 87}, isSubmitted: true),
      const JudgeScore(judgeId: 'j6', judgeName: 'Judge Mendoza', scores: {'c1': 90, 'c2': 89, 'c3': 88, 'c4': 87, 'c5': 91}, isSubmitted: true),
    ],
    'g4': [
      const JudgeScore(judgeId: 'j5', judgeName: 'Judge Lim',     scores: {'c1': 92, 'c2': 93, 'c3': 91, 'c4': 94, 'c5': 92}, isSubmitted: true),
      const JudgeScore(judgeId: 'j6', judgeName: 'Judge Mendoza', scores: {'c1': 91, 'c2': 94, 'c3': 90, 'c4': 93, 'c5': 91}, isSubmitted: true),
    ],
  },
};

// Backward-compat alias used by LiveControlPanel
final Map<String, List<JudgeScore>> staticJudgeScores =
    staticStageJudgeScores['s1']!;

// ================= HELPERS =================

List<RankingEntry> computeRankings(
  Map<String, List<JudgeScore>> judgeScores,
  List<PerformingGroup> groups,
  List<ActiveCriterion> criteria,
) {
  final List<RankingEntry> entries = [];
  judgeScores.forEach((groupId, scores) {
    final submitted = scores.where((j) => j.isSubmitted && j.scores.isNotEmpty).toList();
    if (submitted.isEmpty) return;
    final avg = submitted.fold(0.0, (s, j) => s + j.totalWeighted(criteria)) / submitted.length;
    final group = groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => PerformingGroup(id: groupId, name: 'Unknown', barangay: '', theme: '', performanceOrder: 0),
    );
    entries.add(RankingEntry(groupId: groupId, groupName: group.name, barangay: group.barangay, averageScore: avg, rank: 0));
  });
  entries.sort((a, b) => b.averageScore.compareTo(a.averageScore));
  return entries.asMap().entries.map((e) => RankingEntry(
    groupId: e.value.groupId, groupName: e.value.groupName,
    barangay: e.value.barangay, averageScore: e.value.averageScore, rank: e.key + 1,
  )).toList();
}

double computeStageScore(String groupId, String stageId, List<ActiveCriterion> criteria) {
  final stageData = staticStageJudgeScores[stageId] ?? {};
  final groupScores = stageData[groupId] ?? [];
  final submitted = groupScores.where((j) => j.isSubmitted && j.scores.isNotEmpty).toList();
  if (submitted.isEmpty) return 0.0;
  return submitted.fold(0.0, (s, j) => s + j.totalWeighted(criteria)) / submitted.length;
}

List<OverallRankingEntry> computeOverallRankings(
  List<PerformingGroup> groups,
  List<CompetitionStage> stages,
  List<ActiveCriterion> criteria,
) {
  final entries = groups.map((g) {
    final stageSc = <String, double>{};
    double total = 0.0;
    for (final stage in stages) {
      final s = computeStageScore(g.id, stage.id, criteria);
      stageSc[stage.id] = s;
      total += s;
    }
    return OverallRankingEntry(groupId: g.id, groupName: g.name, barangay: g.barangay, stageScores: stageSc, totalScore: total, rank: 0);
  }).toList();
  entries.sort((a, b) => b.totalScore.compareTo(a.totalScore));
  return entries.asMap().entries.map((e) => OverallRankingEntry(
    groupId: e.value.groupId, groupName: e.value.groupName, barangay: e.value.barangay,
    stageScores: e.value.stageScores, totalScore: e.value.totalScore, rank: e.key + 1,
  )).toList();
}

String resolveJudgeName(String judgeId) {
  final match = staticJudges.firstWhere(
    (j) => j.id == judgeId,
    orElse: () => AppJudge(id: judgeId, name: judgeId, position: '', stageId: ''),
  );
  return match.name;
}

String resolveJudgePosition(String judgeId) {
  final match = staticJudges.firstWhere(
    (j) => j.id == judgeId,
    orElse: () => AppJudge(id: judgeId, name: judgeId, position: '', stageId: ''),
  );
  return match.position;
}

List<AppJudge> judgesForStage(String stageId) =>
    staticJudges.where((j) => j.stageId == stageId).toList();

Map<String, List<JudgeScore>> get resolvedJudgeScores {
  return staticJudgeScores.map((groupId, scores) {
    final resolved = scores.map((s) => JudgeScore(
      judgeId: s.judgeId,
      judgeName: resolveJudgeName(s.judgeId),
      scores: s.scores,
      isSubmitted: s.isSubmitted,
    )).toList();
    return MapEntry(groupId, resolved);
  });
}

Map<String, List<JudgeScore>> resolvedStageJudgeScores(String stageId) {
  final stageData = staticStageJudgeScores[stageId] ?? {};
  return stageData.map((groupId, scores) {
    final resolved = scores.map((s) => JudgeScore(
      judgeId: s.judgeId,
      judgeName: resolveJudgeName(s.judgeId),
      scores: s.scores,
      isSubmitted: s.isSubmitted,
    )).toList();
    return MapEntry(groupId, resolved);
  });
}