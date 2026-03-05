import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';

// ================= DATA MODELS =================

class ScoringCriteria {
  final String id;
  String name;
  String description;
  double weight; // percentage 0–100
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

// ================= SAMPLE DATA =================

final List<ScoringCriteria> _defaultCriteria = [
  ScoringCriteria(
    id: '1',
    name: 'Choreography',
    description: 'Creativity, complexity, and execution of dance moves.',
    weight: 25,
    minScore: 0,
    maxScore: 100,
    isActive: true,
  ),
  ScoringCriteria(
    id: '2',
    name: 'Synchronization',
    description: 'Uniformity and timing precision among all members.',
    weight: 20,
    minScore: 0,
    maxScore: 100,
    isActive: true,
  ),
  ScoringCriteria(
    id: '3',
    name: 'Costume',
    description: 'Visual appeal, thematic relevance, and overall presentation.',
    weight: 15,
    minScore: 0,
    maxScore: 100,
    isActive: true,
  ),
  ScoringCriteria(
    id: '4',
    name: 'Musicality',
    description: 'Responsiveness and interpretation of the music.',
    weight: 20,
    minScore: 0,
    maxScore: 100,
    isActive: true,
  ),
  ScoringCriteria(
    id: '5',
    name: 'Overall Impact',
    description: 'Audience engagement, energy, and stage presence.',
    weight: 20,
    minScore: 0,
    maxScore: 100,
    isActive: true,
  ),
];

// ================= MAIN SCREEN =================

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

  double get totalWeight => criteriaList
      .where((c) => c.isActive)
      .fold(0.0, (sum, c) => sum + c.weight);

  bool get isWeightValid => (totalWeight - 100.0).abs() < 0.01;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Criteria Setup",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showCriteriaDialog(context, null),
              icon: const Icon(Icons.add_rounded),
              label: Text("Add Criteria", style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Summary Cards Row ──
        Row(
          children: [
            _SummaryCard(
              label: "Total Criteria",
              value: "${criteriaList.length}",
              icon: Icons.rule_folder_rounded,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 16),
            _SummaryCard(
              label: "Active Criteria",
              value: "${criteriaList.where((c) => c.isActive).length}",
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.accentGreen,
            ),
            const SizedBox(width: 16),
            _WeightSummaryCard(totalWeight: totalWeight, isValid: isWeightValid),
          ],
        ),
        const SizedBox(height: 20),

        // ── Auto-Total Toggle Banner ──
        _AutoTotalBanner(
          enabled: autoTotalEnabled,
          onToggle: (val) => setState(() => autoTotalEnabled = val),
        ),
        const SizedBox(height: 16),

        // ── Weight Warning ──
        if (!isWeightValid)
          _WeightWarningBanner(totalWeight: totalWeight),

        // ── Criteria List ──
        Expanded(
          child: criteriaList.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  itemCount: criteriaList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final criteria = criteriaList[index];
                    return _CriteriaCard(
                      criteria: criteria,
                      autoTotalEnabled: autoTotalEnabled,
                      onEdit: () => _showCriteriaDialog(context, criteria),
                      onDelete: () => _confirmDelete(context, criteria),
                      onToggleActive: (val) {
                        setState(() => criteria.isActive = val);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rule_folder_rounded, size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text(
            "No criteria added yet",
            style: GoogleFonts.poppins(
              color: AppColors.silverRank,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Click \"Add Criteria\" to get started.",
            style: GoogleFonts.poppins(
              color: AppColors.silverRank,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ================= DIALOGS =================

  void _showCriteriaDialog(BuildContext context, ScoringCriteria? existing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CriteriaFormDialog(
        existing: existing,
        onSave: (criteria) {
          setState(() {
            if (existing == null) {
              criteriaList.add(criteria);
            } else {
              final idx =
                  criteriaList.indexWhere((c) => c.id == criteria.id);
              if (idx != -1) criteriaList[idx] = criteria;
            }
          });
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ScoringCriteria criteria) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Remove Criteria",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to remove \"${criteria.name}\"? This cannot be undone.",
          style:
              GoogleFonts.poppins(fontSize: 14, color: AppColors.silverRank),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: AppColors.silverRank),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(
                () => criteriaList.removeWhere((c) => c.id == criteria.id),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Remove",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= SUMMARY CARD =================

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
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
                    fontSize: 12,
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

// ================= WEIGHT SUMMARY CARD =================

class _WeightSummaryCard extends StatelessWidget {
  final double totalWeight;
  final bool isValid;

  const _WeightSummaryCard({
    required this.totalWeight,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    final color = isValid ? AppColors.accentGreen : AppColors.warning;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isValid
                ? AppColors.accentGreen.withOpacity(0.3)
                : AppColors.warning.withOpacity(0.5),
            width: 1.5,
          ),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isValid
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${totalWeight.toStringAsFixed(0)}%",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  isValid ? "Total Weight ✓" : "Total Weight (≠100%)",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: color,
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

// ================= AUTO-TOTAL BANNER =================

class _AutoTotalBanner extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const _AutoTotalBanner({required this.enabled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.accentGreen.withOpacity(0.07)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? AppColors.accentGreen.withOpacity(0.35)
              : AppColors.divider,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calculate_rounded,
            color: enabled ? AppColors.accentGreen : AppColors.silverRank,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Auto-Total Computation",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: enabled ? AppColors.accentGreen : AppColors.silverRank,
                  ),
                ),
                Text(
                  enabled
                      ? "Scores are automatically weighted and summed per judge submission."
                      : "Auto-total is disabled. Totals must be entered manually.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.silverRank,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeThumbColor: AppColors.accentGreen,
            activeTrackColor: AppColors.accentGreen.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

// ================= WEIGHT WARNING BANNER =================

class _WeightWarningBanner extends StatelessWidget {
  final double totalWeight;

  const _WeightWarningBanner({required this.totalWeight});

  @override
  Widget build(BuildContext context) {
    final diff = 100.0 - totalWeight;
    final isOver = diff < 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isOver
                  ? "Total weight exceeds 100% by ${diff.abs().toStringAsFixed(1)}%. Please reduce some weights."
                  : "Total weight is ${diff.toStringAsFixed(1)}% short of 100%. Adjust weights before saving.",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= CRITERIA CARD =================

class _CriteriaCard extends StatelessWidget {
  final ScoringCriteria criteria;
  final bool autoTotalEnabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const _CriteriaCard({
    required this.criteria,
    required this.autoTotalEnabled,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = criteria.isActive;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isActive ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.secondary.withOpacity(0.15)
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
            // ── Top Row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Name + Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        criteria.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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

                // Active Toggle
                Row(
                  children: [
                    Text(
                      isActive ? "Active" : "Inactive",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isActive
                            ? AppColors.accentGreen
                            : AppColors.silverRank,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: isActive,
                      onChanged: onToggleActive,
                      activeThumbColor: AppColors.accentGreen,
                      activeTrackColor: AppColors.accentGreen.withOpacity(0.3),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),

                // Edit / Delete
                const SizedBox(width: 4),
                _SmallActionButton(
                  icon: Icons.edit_rounded,
                  color: AppColors.secondary,
                  tooltip: "Edit",
                  onTap: onEdit,
                ),
                const SizedBox(width: 6),
                _SmallActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  tooltip: "Delete",
                  onTap: onDelete,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 14),

            // ── Stats Row ──
            Row(
              children: [
                _StatChip(
                  icon: Icons.percent_rounded,
                  label: "Weight",
                  value: "${criteria.weight.toStringAsFixed(0)}%",
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.arrow_downward_rounded,
                  label: "Min Score",
                  value: criteria.minScore.toStringAsFixed(0),
                  color: AppColors.accentGreen,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.arrow_upward_rounded,
                  label: "Max Score",
                  value: criteria.maxScore.toStringAsFixed(0),
                  color: AppColors.primary,
                ),
                const Spacer(),
                if (autoTotalEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate_rounded,
                          size: 14,
                          color: AppColors.accentGreen,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Auto-computed",
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

            // ── Weight Progress Bar ──
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (criteria.weight / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isActive ? AppColors.secondary : AppColors.silverRank,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= STAT CHIP =================

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
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

// ================= SMALL ACTION BUTTON =================

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _SmallActionButton({
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
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ================= CRITERIA FORM DIALOG =================

class _CriteriaFormDialog extends StatefulWidget {
  final ScoringCriteria? existing;
  final Function(ScoringCriteria) onSave;

  const _CriteriaFormDialog({this.existing, required this.onSave});

  @override
  State<_CriteriaFormDialog> createState() => _CriteriaFormDialogState();
}

class _CriteriaFormDialogState extends State<_CriteriaFormDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _maxCtrl;
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
    bool valid = true;
    setState(() {
      _nameError = null;
      _weightError = null;
      _rangeError = null;

      if (_nameCtrl.text.trim().isEmpty) {
        _nameError = "Criteria name is required.";
        valid = false;
      }

      final weight = double.tryParse(_weightCtrl.text);
      if (weight == null || weight <= 0 || weight > 100) {
        _weightError = "Enter a valid weight between 1 and 100.";
        valid = false;
      }

      final min = double.tryParse(_minCtrl.text);
      final max = double.tryParse(_maxCtrl.text);
      if (min == null || max == null || min >= max) {
        _rangeError = "Max score must be greater than Min score.";
        valid = false;
      }
    });
    return valid;
  }

  void _save() {
    if (!_validate()) return;
    final criteria = ScoringCriteria(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      weight: double.parse(_weightCtrl.text),
      minScore: double.parse(_minCtrl.text),
      maxScore: double.parse(_maxCtrl.text),
      isActive: _isActive,
    );
    widget.onSave(criteria);
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
              // ── Title ──
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
                  Text(
                    isEdit ? "Edit Criteria" : "Add Criteria",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Name ──
              _buildLabel("Criteria Name *"),
              _buildTextField(
                ctrl: _nameCtrl,
                hint: "e.g. Choreography",
                errorText: _nameError,
              ),
              const SizedBox(height: 14),

              // ── Description ──
              _buildLabel("Description"),
              _buildTextField(
                ctrl: _descCtrl,
                hint: "Brief description of this criteria...",
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              // ── Weight ──
              _buildLabel("Percentage Weight (%) *"),
              _buildTextField(
                ctrl: _weightCtrl,
                hint: "e.g. 25",
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                errorText: _weightError,
                suffix: Text(
                  "%",
                  style: GoogleFonts.poppins(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Min / Max Score ──
              _buildLabel("Score Range *"),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      ctrl: _minCtrl,
                      hint: "Min",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      prefix: Text(
                        "Min  ",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.silverRank,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "—",
                      style: GoogleFonts.poppins(
                        color: AppColors.silverRank,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildTextField(
                      ctrl: _maxCtrl,
                      hint: "Max",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      prefix: Text(
                        "Max  ",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.silverRank,
                        ),
                      ),
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

              // ── Active Toggle ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
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
                      child: Text(
                        "Active — include in scoring",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (val) => setState(() => _isActive = val),
                      activeThumbColor: AppColors.accentGreen,
                      activeTrackColor: AppColors.accentGreen.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Actions ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.poppins(color: AppColors.silverRank),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: Icon(
                      isEdit ? Icons.save_rounded : Icons.add_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isEdit ? "Save Changes" : "Add Criteria",
                      style: GoogleFonts.poppins(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController ctrl,
    required String hint,
    String? errorText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
    Widget? prefix,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(color: AppColors.silverRank, fontSize: 13),
        suffixText: null,
        suffix: suffix,
        prefix: prefix,
        errorText: errorText,
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
          borderSide: BorderSide(color: AppColors.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
    );
  }
}