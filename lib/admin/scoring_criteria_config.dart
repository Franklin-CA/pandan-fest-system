import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ═══════════════════════════════════════════════════════════════
//  FIRESTORE COLLECTION: scoring_configs
//  Document ID per category: "streetDance" | "focalPresentation" | "festivalQueen"
//  Schema:
//  {
//    "category": "streetDance",
//    "autoTotalEnabled": true,
//    "criteria": [
//      { "id": "sd_1", "name": "Choreography", "description": "...",
//        "weight": 20.0, "minScore": 0.0, "maxScore": 100.0, "isActive": true }
//    ],
//    "updatedAt": Timestamp,
//    "updatedBy": "admin@pandanfest.com"
//  }
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
//  MODEL
// ═══════════════════════════════════════════════════════════════

class ScoringCriteria {
  final String id;
  String name;
  String description;
  double weight;
  double minScore;
  double maxScore;
  bool isActive;

  ScoringCriteria({
    required this.id,
    required this.name,
    required this.description,
    required this.weight,
    required this.minScore,
    required this.maxScore,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'weight': weight,
    'minScore': minScore,
    'maxScore': maxScore,
    'isActive': isActive,
  };

  factory ScoringCriteria.fromMap(Map<String, dynamic> m) => ScoringCriteria(
    id: m['id'] as String,
    name: m['name'] as String,
    description: m['description'] as String? ?? '',
    weight: (m['weight'] as num).toDouble(),
    minScore: (m['minScore'] as num).toDouble(),
    maxScore: (m['maxScore'] as num).toDouble(),
    isActive: m['isActive'] as bool? ?? true,
  );
}

// ═══════════════════════════════════════════════════════════════
//  COMPETITION CATEGORY ENUM
// ═══════════════════════════════════════════════════════════════

enum CompetitionCategory { streetDance, focalPresentation, festivalQueen }

extension CompetitionCategoryExt on CompetitionCategory {
  String get label {
    switch (this) {
      case CompetitionCategory.streetDance:
        return 'Street Dance';
      case CompetitionCategory.focalPresentation:
        return 'Focal Presentation';
      case CompetitionCategory.festivalQueen:
        return 'Festival Queen';
    }
  }

  /// Firestore document ID for this category
  String get docId {
    switch (this) {
      case CompetitionCategory.streetDance:
        return 'streetDance';
      case CompetitionCategory.focalPresentation:
        return 'focalPresentation';
      case CompetitionCategory.festivalQueen:
        return 'festivalQueen';
    }
  }

  IconData get icon {
    switch (this) {
      case CompetitionCategory.streetDance:
        return Icons.music_note_rounded;
      case CompetitionCategory.focalPresentation:
        return Icons.theater_comedy_rounded;
      case CompetitionCategory.festivalQueen:
        return Icons.stars_rounded;
    }
  }

  Color get color {
    switch (this) {
      case CompetitionCategory.streetDance:
        return AppColors.primary;
      case CompetitionCategory.focalPresentation:
        return AppColors.secondary;
      case CompetitionCategory.festivalQueen:
        return AppColors.goldRank;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  PRESET CRITERIA DATA
// ═══════════════════════════════════════════════════════════════

List<ScoringCriteria> _buildStreetDanceCriteria() => [
  ScoringCriteria(
    id: 'sd_1',
    name: 'Choreography',
    description:
        'Creativity, synchronization, and difficulty of dance routines.',
    weight: 20,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'sd_2',
    name: 'Execution',
    description: 'Precision, timing, and overall coordination.',
    weight: 10,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'sd_3',
    name: 'Energy and Stage Presence',
    description: 'Enthusiasm and engagement with the audience.',
    weight: 10,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'sd_4',
    name: 'Relevance to the Theme',
    description:
        'Performers must wear and use distinct costumes and props inspired by their respective culture/festival.',
    weight: 10,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'sd_5',
    name: 'Creativity and Aesthetic',
    description: 'Design, color harmony, and artistic impact.',
    weight: 10,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'sd_6',
    name: 'Originality',
    description: 'Innovative and culturally relevant music.',
    weight: 10,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'sd_7',
    name: 'Synchronization with Movements',
    description: 'Music and steps in perfect harmony.',
    weight: 10,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'sd_8',
    name: 'Portrayal of Theme',
    description: 'Adherence to the festival\'s cultural identity and story.',
    weight: 10,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'sd_9',
    name: 'Impact and Emotional Appeal',
    description:
        'Effectiveness in delivering a message or cultural representation.',
    weight: 10,
    minScore: 0,
    maxScore: 100,
  ),
];

List<ScoringCriteria> _buildFocalPresentationCriteria() => [
  ScoringCriteria(
    id: 'fp_1',
    name: 'Relevance to the Festival Theme',
    description:
        'The presentation must highlight the essence of their festival, emphasizing culture, history, and local pride.',
    weight: 15,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'fp_2',
    name: 'Creativity and Innovation',
    description:
        'Unique and fresh interpretation of the theme through storytelling and visuals.',
    weight: 15,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'fp_3',
    name: 'Originality of Choreography',
    description:
        'Creative dance routines that blend tradition with modern techniques.',
    weight: 15,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'fp_4',
    name: 'Precision and Synchronization',
    description: 'Cohesive and well-coordinated movements.',
    weight: 10,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'fp_5',
    name: 'Costume and Props Design',
    description:
        'Vibrant and artistic costumes and props that reflect their cultural traditions.',
    weight: 15,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'fp_6',
    name: 'Stage Design and Presentation',
    description:
        'Effective use of space, props, and stage elements to enhance the performance.',
    weight: 10,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'fp_7',
    name: 'Cultural Integrity & Overall Impact',
    description:
        'Authentic representation of traditions that captivate the audience and evoke emotions.',
    weight: 10,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'fp_8',
    name: 'Musicality',
    description: 'Choice of music, editing, and climatic transitions.',
    weight: 10,
    minScore: 0,
    maxScore: 100,
  ),
];

List<ScoringCriteria> _buildFestivalQueenCriteria() => [
  ScoringCriteria(
    id: 'fq_1',
    name: 'Stage Presence / Personality & Performance',
    description:
        'Confidence, poise, and ability to showcase the dance effectively.',
    weight: 30,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'fq_2',
    name: 'Costume Creativity & Cultural Relevance',
    description:
        'Uniqueness of design, innovative use of materials, overall artistic merit, and accuracy in representing cultural heritage and tradition.',
    weight: 10,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: 'fq_3',
    name: 'Overall Impact',
    description: 'Totality and overall performance/impression.',
    weight: 10,
    minScore: 0,
    maxScore: 100,
  ),
];

// Grouped category descriptions for the UI
const Map<CompetitionCategory, List<_CategoryGroup>> _categoryGroups = {
  CompetitionCategory.streetDance: [
    _CategoryGroup('Street Dancing Performance', '40%', [
      'Choreography',
      'Execution',
      'Energy and Stage Presence',
    ]),
    _CategoryGroup('Costume and Props', '20%', [
      'Relevance to the Theme',
      'Creativity and Aesthetic',
    ]),
    _CategoryGroup('Music and Rhythm', '20%', [
      'Originality',
      'Synchronization with Movements',
    ]),
    _CategoryGroup('Cultural Relevance and Storytelling', '20%', [
      'Portrayal of Theme',
      'Impact and Emotional Appeal',
    ]),
  ],
  CompetitionCategory.focalPresentation: [
    _CategoryGroup('Theme and Concept', '30%', [
      'Relevance to the Festival Theme',
      'Creativity and Innovation',
    ]),
    _CategoryGroup('Choreography and Execution', '25%', [
      'Originality of Choreography',
      'Precision and Synchronization',
    ]),
    _CategoryGroup('Visual Impact', '25%', [
      'Costume and Props Design',
      'Stage Design and Presentation',
    ]),
    _CategoryGroup('Cultural and Emotional Appeal', '10%', [
      'Cultural Integrity & Overall Impact',
    ]),
    _CategoryGroup('Musicality', '10%', ['Musicality']),
  ],
  CompetitionCategory.festivalQueen: [
    _CategoryGroup('Judging Criteria', '50%', [
      'Stage Presence / Personality & Performance',
      'Costume Creativity & Cultural Relevance',
      'Overall Impact',
    ]),
  ],
};

class _CategoryGroup {
  final String name;
  final String weight;
  final List<String> criteria;
  const _CategoryGroup(this.name, this.weight, this.criteria);
}

// ═══════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════

class ScoringCriteriaConfiguration extends StatefulWidget {
  const ScoringCriteriaConfiguration({super.key});

  @override
  State<ScoringCriteriaConfiguration> createState() =>
      _ScoringCriteriaConfigurationState();
}

class _ScoringCriteriaConfigurationState
    extends State<ScoringCriteriaConfiguration> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CompetitionCategory _activeCategory = CompetitionCategory.streetDance;
  List<ScoringCriteria> criteriaList = [];
  bool autoTotalEnabled = true;

  // Loading / saving state
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  DateTime? _lastSaved;
  String? _lastSavedBy;

  double get totalWeight =>
      criteriaList.where((c) => c.isActive).fold(0.0, (s, c) => s + c.weight);

  double get _requiredWeight =>
      _activeCategory == CompetitionCategory.festivalQueen ? 50.0 : 100.0;

  bool get isWeightValid => (totalWeight - _requiredWeight).abs() < 0.01;

  @override
  void initState() {
    super.initState();
    _loadFromFirestore(_activeCategory);
  }

  // ── Firestore: Load ────────────────────────────────────────
  Future<void> _loadFromFirestore(CompetitionCategory category) async {
    setState(() => _isLoading = true);
    try {
      final doc = await _db
          .collection('scoring_configs')
          .doc(category.docId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final rawList = List<Map<String, dynamic>>.from(data['criteria'] ?? []);
        final loaded = rawList.map((m) => ScoringCriteria.fromMap(m)).toList();
        final ts = data['updatedAt'] as Timestamp?;
        setState(() {
          criteriaList = loaded;
          autoTotalEnabled = data['autoTotalEnabled'] as bool? ?? true;
          _lastSaved = ts?.toDate();
          _lastSavedBy = data['updatedBy'] as String?;
          _hasUnsavedChanges = false;
          _isLoading = false;
        });
      } else {
        // No document yet — load the preset as default
        final preset = _getPreset(category);
        setState(() {
          criteriaList = preset;
          autoTotalEnabled = true;
          _lastSaved = null;
          _lastSavedBy = null;
          _hasUnsavedChanges = true; // Encourage saving the defaults
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load criteria: $e');
    }
  }

  // ── Firestore: Save ────────────────────────────────────────
  Future<void> _saveToFirestore() async {
    if (!isWeightValid) {
      _showError('Total weight must equal 100% before saving.');
      return;
    }
    final user = _auth.currentUser;
    if (user == null) {
      _showError('You must be signed in to save criteria.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      // ── Fetch admin name from users collection ──
      String updatedBy = user.email ?? user.uid; // fallback
      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final fetchedName = userDoc.data()?['name'] as String?;
        if (fetchedName != null && fetchedName.trim().isNotEmpty) {
          updatedBy = fetchedName.trim();
        }
      }

      await _db.collection('scoring_configs').doc(_activeCategory.docId).set({
        'category': _activeCategory.docId,
        'autoTotalEnabled': autoTotalEnabled,
        'criteria': criteriaList.map((c) => c.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy, // ← now uses name instead of email
      });
      setState(() {
        _isSaving = false;
        _hasUnsavedChanges = false;
        _lastSaved = DateTime.now();
        _lastSavedBy = updatedBy; // ← also update local display
      });
      _showSuccess('Criteria saved and pushed to judges.');
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Failed to save: $e');
    }
  }

  List<ScoringCriteria> _getPreset(CompetitionCategory category) {
    switch (category) {
      case CompetitionCategory.streetDance:
        return _buildStreetDanceCriteria();
      case CompetitionCategory.focalPresentation:
        return _buildFocalPresentationCriteria();
      case CompetitionCategory.festivalQueen:
        return _buildFestivalQueenCriteria();
    }
  }

  void _loadPreset(CompetitionCategory category) {
    setState(() {
      _activeCategory = category;
      criteriaList = [];
      _isLoading = true;
      _hasUnsavedChanges = false;
    });
    _loadFromFirestore(category);
  }

  void _markDirty() => setState(() => _hasUnsavedChanges = true);

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildCategorySelector(),
        const SizedBox(height: 14),
        if (!_isLoading) _buildCategoryOverview(),
        if (!_isLoading) const SizedBox(height: 12),
        if (!_isLoading) _buildSummaryRow(),
        if (!_isLoading) const SizedBox(height: 12),
        if (!_isLoading) _buildAutoTotalBanner(),
        if (!_isLoading && !isWeightValid) ...[
          const SizedBox(height: 10),
          _buildWeightWarning(),
        ],
        if (!_isLoading) _buildSaveBar(),
        const SizedBox(height: 14),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
          )
        else if (criteriaList.isEmpty)
          _buildEmptyState()
        else
          _buildList(),
      ],
    );
  }

  // ── Save Bar ──────────────────────────────────────────────────
  Widget _buildSaveBar() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_isSaving) {
      statusText = 'Saving to Firestore…';
      statusColor = AppColors.secondary;
      statusIcon = Icons.cloud_upload_rounded;
    } else if (_hasUnsavedChanges) {
      statusText = 'You have unsaved changes';
      statusColor = AppColors.warning;
      statusIcon = Icons.edit_rounded;
    } else if (_lastSaved != null) {
      final time = _lastSaved!;
      final formatted =
          '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
      statusText =
          'Saved at $formatted${_lastSavedBy != null ? ' by $_lastSavedBy' : ''}';
      statusColor = AppColors.accentGreen;
      statusIcon = Icons.cloud_done_rounded;
    } else {
      statusText = 'Not yet saved to Firestore';
      statusColor = AppColors.silverRank;
      statusIcon = Icons.cloud_off_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                statusText,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_hasUnsavedChanges && !_isSaving)
              ElevatedButton.icon(
                onPressed: _saveToFirestore,
                icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                label: Text(
                  'Save & Publish',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isWeightValid
                      ? AppColors.secondary
                      : AppColors.divider,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            if (_isSaving)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scoring Criteria Setup',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Configure and publish criteria to Firestore. Judges will see changes in real-time.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showDialog(context, null),
          icon: const Icon(Icons.add_rounded),
          label: Text('Add Criteria', style: GoogleFonts.poppins()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // ── Category Selector ─────────────────────────────────────────
  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
                Icons.category_rounded,
                color: AppColors.secondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Competition Category',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 13,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Switching loads from Firestore',
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
          const SizedBox(height: 12),
          Row(
            children: CompetitionCategory.values.map((cat) {
              final isActive = _activeCategory == cat;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: cat != CompetitionCategory.values.last ? 10 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (!isActive) {
                        if (_hasUnsavedChanges) {
                          _confirmCategorySwitch(cat);
                        } else {
                          _loadPreset(cat);
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? cat.color.withOpacity(0.12)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? cat.color : AppColors.divider,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? cat.color.withOpacity(0.15)
                                  : AppColors.divider.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat.icon,
                              color: isActive
                                  ? cat.color
                                  : AppColors.silverRank,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.label,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isActive
                                  ? cat.color
                                  : AppColors.silverRank,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isActive) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 24,
                              height: 3,
                              decoration: BoxDecoration(
                                color: cat.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Category Overview ─────────────────────────────────────────
  Widget _buildCategoryOverview() {
    final groups = _categoryGroups[_activeCategory] ?? [];
    final color = _activeCategory.color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_activeCategory.icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_activeCategory.label} — Category Breakdown',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
              if (_activeCategory == CompetitionCategory.festivalQueen)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldRank.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total: 50%',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldRank,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: groups.map((g) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          g.name,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            g.weight,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...g.criteria.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_right_rounded,
                              size: 14,
                              color: AppColors.silverRank,
                            ),
                            Text(
                              c,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
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
            }).toList(),
          ),
          if (_activeCategory == CompetitionCategory.focalPresentation) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.gavel_rounded, size: 14, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Grounds for Disqualification: (1) Execution of dangerous/aerial stunts. (2) Unruliness/failure to observe sportsman-like conduct.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.danger,
                      ),
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

  // ── Summary Row ───────────────────────────────────────────────
  Widget _buildSummaryRow() {
    return Row(
      children: [
        _SummaryCard(
          label: 'Total Criteria',
          value: '${criteriaList.length}',
          icon: Icons.rule_folder_rounded,
          color: AppColors.secondary,
        ),
        const SizedBox(width: 14),
        _SummaryCard(
          label: 'Active (Used in Scoring)',
          value: '${criteriaList.where((c) => c.isActive).length}',
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.accentGreen,
        ),
        const SizedBox(width: 14),
        _WeightCard(
          total: totalWeight,
          isValid: isWeightValid,
          required: _requiredWeight,
        ),
      ],
    );
  }

  // ── Auto-Total Banner ─────────────────────────────────────────
  Widget _buildAutoTotalBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: autoTotalEnabled
            ? AppColors.accentGreen.withOpacity(0.06)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: autoTotalEnabled
              ? AppColors.accentGreen.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calculate_rounded,
            color: autoTotalEnabled
                ? AppColors.accentGreen
                : AppColors.silverRank,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-Compute Final Score',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: autoTotalEnabled
                        ? AppColors.accentGreen
                        : Colors.grey[600],
                  ),
                ),
                Text(
                  autoTotalEnabled
                      ? 'The system automatically multiplies each criterion score by its weight and sums them for the final result.'
                      : 'Auto-compute is OFF. Admins must manually enter final totals.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: autoTotalEnabled,
            onChanged: (val) {
              setState(() => autoTotalEnabled = val);
              _markDirty();
            },
            activeThumbColor: AppColors.accentGreen,
            activeTrackColor: AppColors.accentGreen.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  // ── Weight Warning ────────────────────────────────────────────
  Widget _buildWeightWarning() {
    final diff = _requiredWeight - totalWeight;
    final isOver = diff < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isOver
                  ? 'Total weight is ${diff.abs().toStringAsFixed(1)}% over 100%. Please reduce some weights before saving.'
                  : 'Total weight is ${diff.toStringAsFixed(1)}% short of 100%. Adjust the weights so they add up to exactly 100%.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────
  Widget _buildList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: criteriaList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final c = criteriaList[i];
        return _CriteriaCard(
          criteria: c,
          autoTotal: autoTotalEnabled,
          categoryColor: _activeCategory.color,
          onEdit: () => _showDialog(context, c),
          onDelete: () => _confirmDelete(context, c),
          onToggle: (val) {
            setState(() => c.isActive = val);
            _markDirty();
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.divider.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rule_folder_rounded,
                size: 36,
                color: AppColors.silverRank,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No scoring criteria yet',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 340,
              child: Text(
                'Select a category to load its preset, or add criteria manually.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showDialog(context, null),
              icon: const Icon(Icons.add_rounded),
              label: Text('Add First Criterion', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────
  void _confirmCategorySwitch(CompetitionCategory newCat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 28,
          ),
        ),
        title: Text(
          'Unsaved Changes',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'You have unsaved changes for ${_activeCategory.label}. Switch anyway and discard them?',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Stay', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadPreset(newCat);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Discard & Switch',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, ScoringCriteria? existing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CriteriaFormDialog(
        existing: existing,
        onSave: (c) {
          setState(() {
            if (existing == null) {
              criteriaList.add(c);
            } else {
              final idx = criteriaList.indexWhere((x) => x.id == c.id);
              if (idx != -1) criteriaList[idx] = c;
            }
          });
          _markDirty();
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ScoringCriteria c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.danger,
            size: 28,
          ),
        ),
        title: Text(
          'Remove "${c.name}"?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'This criterion will be removed and will no longer be included in scoring.',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => criteriaList.removeWhere((x) => x.id == c.id));
              _markDirty();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Yes, Remove',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SUMMARY CARDS (unchanged UI, kept intact)
// ═══════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: AppColors.shadow,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.silverRank,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  final double total;
  final bool isValid;
  final double required; // ← add this
  const _WeightCard({
    required this.total,
    required this.isValid,
    required this.required,
  });

  @override
  Widget build(BuildContext context) {
    final color = isValid ? AppColors.accentGreen : AppColors.warning;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: AppColors.shadow,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isValid
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${total.toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    isValid
                        ? 'Total Weight ✓ (${required.toStringAsFixed(0)}%)'
                        : 'Total Weight (must equal ${required.toStringAsFixed(0)}%)',
                    style: GoogleFonts.poppins(fontSize: 11, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CRITERIA CARD
// ═══════════════════════════════════════════════════════════════

class _CriteriaCard extends StatelessWidget {
  final ScoringCriteria criteria;
  final bool autoTotal;
  final Color categoryColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _CriteriaCard({
    required this.criteria,
    required this.autoTotal,
    required this.categoryColor,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final active = criteria.isActive;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: active ? 1.0 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? categoryColor.withOpacity(0.15) : AppColors.divider,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: AppColors.shadow,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: categoryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        criteria.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (criteria.description.isNotEmpty)
                        Text(
                          criteria.description,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.silverRank,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      active ? 'Active' : 'Inactive',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: active
                            ? AppColors.accentGreen
                            : AppColors.silverRank,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: active,
                      onChanged: onToggle,
                      activeThumbColor: AppColors.accentGreen,
                      activeTrackColor: AppColors.accentGreen.withOpacity(0.3),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                Tooltip(
                  message: 'Edit criteria',
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Remove criteria',
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StatChip(
                  icon: Icons.percent_rounded,
                  label: 'Weight',
                  value: '${criteria.weight.toStringAsFixed(0)}%',
                  color: categoryColor,
                ),
                _StatChip(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Min Score',
                  value: criteria.minScore.toStringAsFixed(0),
                  color: AppColors.accentGreen,
                ),
                _StatChip(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Max Score',
                  value: criteria.maxScore.toStringAsFixed(0),
                  color: AppColors.primary,
                ),
                if (autoTotal && active)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calculate_rounded,
                          size: 13,
                          color: AppColors.accentGreen,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Auto-computed',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Tooltip(
              message: '${criteria.weight.toStringAsFixed(0)}% of total score',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (criteria.weight / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    active ? categoryColor : AppColors.silverRank,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.silverRank,
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
//  FORM DIALOG
// ═══════════════════════════════════════════════════════════════

class _CriteriaFormDialog extends StatefulWidget {
  final ScoringCriteria? existing;
  final Function(ScoringCriteria) onSave;
  const _CriteriaFormDialog({this.existing, required this.onSave});

  @override
  State<_CriteriaFormDialog> createState() => _CriteriaFormDialogState();
}

class _CriteriaFormDialogState extends State<_CriteriaFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late bool _isActive;

  String? _nameError;
  String? _weightError;
  String? _rangeError;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _weightCtrl = TextEditingController(
      text: c != null ? c.weight.toStringAsFixed(0) : '',
    );
    _minCtrl = TextEditingController(
      text: c != null ? c.minScore.toStringAsFixed(0) : '0',
    );
    _maxCtrl = TextEditingController(
      text: c != null ? c.maxScore.toStringAsFixed(0) : '100',
    );
    _isActive = c?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _weightCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty
          ? 'Please enter a criteria name.'
          : null;
      final w = double.tryParse(_weightCtrl.text);
      _weightError = (w == null || w <= 0 || w > 100)
          ? 'Enter a number between 1 and 100.'
          : null;
      final min = double.tryParse(_minCtrl.text);
      final max = double.tryParse(_maxCtrl.text);
      _rangeError = (min == null || max == null || min >= max)
          ? 'Max score must be greater than min score.'
          : null;
      if (_nameError != null || _weightError != null || _rangeError != null) {
        ok = false;
      }
    });
    return ok;
  }

  void _save() {
    if (!_validate()) return;
    widget.onSave(
      ScoringCriteria(
        id:
            widget.existing?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        weight: double.parse(_weightCtrl.text),
        minScore: double.parse(_minCtrl.text),
        maxScore: double.parse(_maxCtrl.text),
        isActive: _isActive,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.rule_folder_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Criteria' : 'Add New Criteria',
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isEdit
                              ? 'Update the criteria details'
                              : 'Define a new scoring criterion',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _label('Criteria Name *'),
              _field(_nameCtrl, 'e.g. Choreography', error: _nameError),
              const SizedBox(height: 14),
              _label('Description'),
              _field(
                _descCtrl,
                'Briefly describe what judges should evaluate…',
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              _label('Percentage Weight (%) *'),
              Text(
                'How much does this criterion count toward the total score? All active criteria must add up to 100%.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 6),
              _field(
                _weightCtrl,
                'e.g. 25',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                error: _weightError,
                suffix: Text(
                  '%',
                  style: GoogleFonts.poppins(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _label('Score Range *'),
              Text(
                'The minimum and maximum score a judge can give for this criterion.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _minCtrl,
                      'Min (e.g. 0)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'to',
                      style: GoogleFonts.poppins(color: AppColors.silverRank),
                    ),
                  ),
                  Expanded(
                    child: _field(
                      _maxCtrl,
                      'Max (e.g. 100)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              if (_rangeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _rangeError!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.toggle_on_rounded,
                      color: _isActive
                          ? AppColors.accentGreen
                          : AppColors.silverRank,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Include in scoring',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'When inactive, judges won\'t see this criterion and it won\'t affect scores.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeThumbColor: AppColors.accentGreen,
                      activeTrackColor: AppColors.accentGreen.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.silverRank,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Cancel', style: GoogleFonts.poppins()),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: Icon(
                      isEdit ? Icons.save_rounded : Icons.add_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isEdit ? 'Save Changes' : 'Add Criteria',
                      style: GoogleFonts.poppins(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    String? error,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 14),
      onChanged: (_) {
        if (error != null) setState(() {});
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: AppColors.silverRank,
          fontSize: 13,
        ),
        suffix: suffix,
        errorText: error,
        errorStyle: GoogleFonts.poppins(fontSize: 11, color: AppColors.danger),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.secondary, width: 1.5),
        ),
      ),
    );
  }
}
