import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';

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
}

// ═══════════════════════════════════════════════════════════════
//  SAMPLE DATA
// ═══════════════════════════════════════════════════════════════

final List<ScoringCriteria> _defaultCriteria = [
  ScoringCriteria(
    id: '1',
    name: 'Choreography',
    description: 'Creativity, complexity, and execution of dance moves.',
    weight: 25,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: '2',
    name: 'Synchronization',
    description: 'Uniformity and timing precision among all members.',
    weight: 20,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: '3',
    name: 'Costume',
    description: 'Visual appeal, thematic relevance, and overall presentation.',
    weight: 15,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: '4',
    name: 'Musicality',
    description: 'Responsiveness and interpretation of the music.',
    weight: 20,
    minScore: 0,
    maxScore: 100,
  ),
  ScoringCriteria(
    id: '5',
    name: 'Overall Impact',
    description: 'Audience engagement, energy, and stage presence.',
    weight: 20,
    minScore: 0,
    maxScore: 100,
  ),
];

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
  List<ScoringCriteria> criteriaList = _defaultCriteria
      .map(
        (c) => ScoringCriteria(
          id: c.id,
          name: c.name,
          description: c.description,
          weight: c.weight,
          minScore: c.minScore,
          maxScore: c.maxScore,
          isActive: c.isActive,
        ),
      )
      .toList();

  bool autoTotalEnabled = true;

  double get totalWeight =>
      criteriaList.where((c) => c.isActive).fold(0.0, (s, c) => s + c.weight);

  bool get isWeightValid => (totalWeight - 100.0).abs() < 0.01;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildSummaryRow(),
        const SizedBox(height: 12),
        _buildAutoTotalBanner(),
        if (!isWeightValid) ...[
          const SizedBox(height: 10),
          _buildWeightWarning(),
        ],
        const SizedBox(height: 14),
        Expanded(
          child: criteriaList.isEmpty ? _buildEmptyState() : _buildList(),
        ),
      ],
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
                'Define what judges score and how much each criterion contributes to the final score',
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
        _WeightCard(total: totalWeight, isValid: isWeightValid),
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
            onChanged: (val) => setState(() => autoTotalEnabled = val),
            activeThumbColor: AppColors.accentGreen,
            activeTrackColor: AppColors.accentGreen.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  // ── Weight Warning ────────────────────────────────────────────
  Widget _buildWeightWarning() {
    final diff = 100.0 - totalWeight;
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
                  ? 'Total weight is ${diff.abs().toStringAsFixed(1)}% over 100%. '
                        'Please reduce some weights before saving.'
                  : 'Total weight is ${diff.toStringAsFixed(1)}% short of 100%. '
                        'Adjust the weights so they add up to exactly 100%.',
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
      itemCount: criteriaList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final c = criteriaList[i];
        return _CriteriaCard(
          criteria: c,
          autoTotal: autoTotalEnabled,
          onEdit: () => _showDialog(context, c),
          onDelete: () => _confirmDelete(context, c),
          onToggle: (val) => setState(() => c.isActive = val),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              'Add at least one criterion so judges know what to score. '
              'Each criterion should have a weight that adds up to 100%.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
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
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────
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
          'This criterion will be permanently removed and will no longer be included in scoring.',
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
//  SUMMARY CARDS
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
            Column(
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
          ],
        ),
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  final double total;
  final bool isValid;
  const _WeightCard({required this.total, required this.isValid});

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
            Column(
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
                      ? 'Total Weight ✓ (100%)'
                      : 'Total Weight (must equal 100%)',
                  style: GoogleFonts.poppins(fontSize: 11, color: color),
                ),
              ],
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _CriteriaCard({
    required this.criteria,
    required this.autoTotal,
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
            color: active
                ? AppColors.secondary.withOpacity(0.12)
                : AppColors.divider,
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
            // Top row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: AppColors.secondary,
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
                // Active toggle
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
                // Edit / delete
                Tooltip(
                  message: 'Edit criteria',
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: AppColors.secondary,
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
                      child: Icon(
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
            // Stats row
            Row(
              children: [
                _StatChip(
                  icon: Icons.percent_rounded,
                  label: 'Weight',
                  value: '${criteria.weight.toStringAsFixed(0)}%',
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Min Score',
                  value: criteria.minScore.toStringAsFixed(0),
                  color: AppColors.accentGreen,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Max Score',
                  value: criteria.maxScore.toStringAsFixed(0),
                  color: AppColors.primary,
                ),
                const Spacer(),
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
                      children: [
                        Icon(
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
            // Weight bar
            Tooltip(
              message: '${criteria.weight.toStringAsFixed(0)}% of total score',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (criteria.weight / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    active ? AppColors.secondary : AppColors.silverRank,
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
          ? 'Enter a number between 1 and 100 (e.g. 25 for 25%).'
          : null;
      final min = double.tryParse(_minCtrl.text);
      final max = double.tryParse(_maxCtrl.text);
      _rangeError = (min == null || max == null || min >= max)
          ? 'Max score must be greater than min score.'
          : null;
      if (_nameError != null || _weightError != null || _rangeError != null)
        ok = false;
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
              // Header
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
                  Column(
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
                'How much does this criterion count toward the total score? All active criteria weights must add up to 100%.',
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

              // Active toggle
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

              // Actions
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
