import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandan_fest/constant/colors.dart';

// ═══════════════════════════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════════════════════════

class DanceGroup {
  final String id;
  String name;
  String barangay;
  String coach;
  String theme;
  int memberCount;
  List<String> members;
  String? profileImagePath;
  int performanceOrder;
  List<ScoreHistory> scoreHistory;

  DanceGroup({
    required this.id,
    required this.name,
    required this.barangay,
    required this.coach,
    required this.theme,
    required this.memberCount,
    required this.members,
    this.profileImagePath,
    required this.performanceOrder,
    this.scoreHistory = const [],
  });
}

class ScoreHistory {
  final String phase;
  final double score;
  final String date;
  final int rank;

  const ScoreHistory({
    required this.phase,
    required this.score,
    required this.date,
    required this.rank,
  });
}

// ═══════════════════════════════════════════════════════════════
//  SAMPLE DATA
// ═══════════════════════════════════════════════════════════════

final List<DanceGroup> _sampleGroups = [
  DanceGroup(
    id: '1',
    name: 'Sayaw Pandan',
    barangay: 'Brgy. Pandan',
    coach: 'Maria Santos',
    theme: 'Urban Fusion',
    memberCount: 15,
    members: ['Juan D.', 'Ana R.', 'Carlos M.', 'Lea P.', 'Rico T.'],
    performanceOrder: 1,
    scoreHistory: [
      ScoreHistory(
        phase: 'Preliminaries',
        score: 87.5,
        date: 'Feb 10, 2026',
        rank: 2,
      ),
      ScoreHistory(
        phase: 'Semi-Finals',
        score: 91.0,
        date: 'Feb 20, 2026',
        rank: 1,
      ),
    ],
  ),
  DanceGroup(
    id: '2',
    name: 'Ritmo Barangay',
    barangay: 'Brgy. San Isidro',
    coach: 'Jose Reyes',
    theme: 'Cultural Heritage',
    memberCount: 18,
    members: ['Pedro B.', 'Nina C.', 'Mark L.', 'Clara G.', 'Tony A.'],
    performanceOrder: 2,
    scoreHistory: [
      ScoreHistory(
        phase: 'Preliminaries',
        score: 83.0,
        date: 'Feb 10, 2026',
        rank: 4,
      ),
      ScoreHistory(
        phase: 'Semi-Finals',
        score: 88.5,
        date: 'Feb 20, 2026',
        rank: 3,
      ),
    ],
  ),
  DanceGroup(
    id: '3',
    name: 'Kalye Kings',
    barangay: 'Brgy. Malaya',
    coach: 'Rosa Dela Cruz',
    theme: 'Hip-Hop Street',
    memberCount: 12,
    members: ['Ben V.', 'Grace N.', 'Sonny E.', 'Myra F.', 'Dante O.'],
    performanceOrder: 3,
    scoreHistory: [
      ScoreHistory(
        phase: 'Preliminaries',
        score: 85.0,
        date: 'Feb 10, 2026',
        rank: 3,
      ),
      ScoreHistory(
        phase: 'Semi-Finals',
        score: 89.5,
        date: 'Feb 20, 2026',
        rank: 2,
      ),
    ],
  ),
  DanceGroup(
    id: '4',
    name: 'Alon Dancers',
    barangay: 'Brgy. Bagong Silang',
    coach: 'Edwin Lim',
    theme: 'Contemporary Wave',
    memberCount: 20,
    members: ['Lucy H.', 'Ralph J.', 'Vince K.', 'Pia S.', 'Jun T.'],
    performanceOrder: 4,
    scoreHistory: [
      ScoreHistory(
        phase: 'Preliminaries',
        score: 90.0,
        date: 'Feb 10, 2026',
        rank: 1,
      ),
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════

class DanceGroupManagement extends StatefulWidget {
  const DanceGroupManagement({super.key});

  @override
  State<DanceGroupManagement> createState() => _DanceGroupManagementState();
}

class _DanceGroupManagementState extends State<DanceGroupManagement> {
  List<DanceGroup> groups = List.from(_sampleGroups);
  String _searchQuery = '';

  List<DanceGroup> get _filtered => groups
      .where(
        (g) =>
            g.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            g.barangay.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            g.coach.toLowerCase().contains(_searchQuery.toLowerCase()),
      )
      .toList();

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildStatsRow(),
        const SizedBox(height: 16),
        _buildSearchBar(),
        const SizedBox(height: 6),
        _buildResultsHint(),
        const SizedBox(height: 10),
        Expanded(child: _buildGroupsList()),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dance Groups',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Manage all registered dance groups for PandanFest 2026',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showGroupDialog(context, null),
          icon: const Icon(Icons.add_rounded),
          label: Text('Add New Group', style: GoogleFonts.poppins()),
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

  // ── Stats Row ─────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatBadge(
          icon: Icons.groups_rounded,
          label: 'Total Groups',
          value: '${groups.length}',
          color: AppColors.secondary,
        ),
        const SizedBox(width: 12),
        _StatBadge(
          icon: Icons.person_rounded,
          label: 'Total Performers',
          value: '${groups.fold(0, (s, g) => s + g.memberCount)}',
          color: const Color(0xFF007AFF),
        ),
        const SizedBox(width: 12),
        _StatBadge(
          icon: Icons.history_rounded,
          label: 'With Score History',
          value: '${groups.where((g) => g.scoreHistory.isNotEmpty).length}',
          color: AppColors.accentGreen,
        ),
      ],
    );
  }

  // ── Search Bar ────────────────────────────────────────────
  Widget _buildSearchBar() {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        hintText: 'Search by group name, barangay, or coach…',
        hintStyle: GoogleFonts.poppins(
          color: AppColors.silverRank,
          fontSize: 13,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.silverRank,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.silverRank,
                  size: 18,
                ),
                onPressed: () => setState(() => _searchQuery = ''),
                tooltip: 'Clear search',
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.secondary, width: 1.5),
        ),
      ),
    );
  }

  // ── Results hint ──────────────────────────────────────────
  Widget _buildResultsHint() {
    if (_searchQuery.isEmpty) return const SizedBox.shrink();
    final count = _filtered.length;
    return Text(
      count == 0
          ? 'No groups match "$_searchQuery"'
          : '$count group${count != 1 ? 's' : ''} found for "$_searchQuery"',
      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
    );
  }

  // ── Groups List ───────────────────────────────────────────
  Widget _buildGroupsList() {
    final displayed = _filtered;

    if (displayed.isEmpty && groups.isEmpty) {
      return _EmptyState(
        icon: Icons.groups_rounded,
        title: 'No dance groups yet',
        subtitle:
            'Tap "Add New Group" to register the first dance group for the competition.',
        actionLabel: 'Add First Group',
        onAction: () => _showGroupDialog(context, null),
      );
    }

    if (displayed.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No groups found',
        subtitle: 'Try a different name, barangay, or coach name.',
        actionLabel: 'Clear Search',
        onAction: () => setState(() => _searchQuery = ''),
      );
    }

    return ListView.separated(
      itemCount: displayed.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = displayed[index];
        return _GroupCard(
          group: group,
          onEdit: () => _showGroupDialog(context, group),
          onDelete: () => _confirmDelete(context, group),
          onViewHistory: () => _showHistoryDialog(context, group),
        );
      },
    );
  }

  // ── Dialogs ───────────────────────────────────────────────
  void _showGroupDialog(BuildContext context, DanceGroup? existing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GroupFormDialog(
        existing: existing,
        onSave: (group) {
          setState(() {
            if (existing == null) {
              group.performanceOrder = groups.length + 1;
              groups.add(group);
            } else {
              final idx = groups.indexWhere((g) => g.id == group.id);
              if (idx != -1) groups[idx] = group;
            }
          });
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, DanceGroup group) {
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
          'Remove "${group.name}"?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'This will permanently remove the group and all their score history. This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.silverRank),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.silverRank,
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
              setState(() => groups.removeWhere((g) => g.id == group.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${group.name} has been removed.',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Yes, Remove',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, DanceGroup group) {
    showDialog(
      context: context,
      builder: (_) => _HistoryDialog(group: group),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GROUP CARD
// ═══════════════════════════════════════════════════════════════

class _GroupCard extends StatelessWidget {
  final DanceGroup group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewHistory;

  const _GroupCard({
    required this.group,
    required this.onEdit,
    required this.onDelete,
    required this.onViewHistory,
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
      child: Row(
        children: [
          // Order badge + avatar
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${group.performanceOrder}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: group.profileImagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          group.profileImagePath!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.groups_rounded,
                        color: AppColors.secondary,
                        size: 28,
                      ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (group.scoreHistory.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${group.scoreHistory.length} scores',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _InfoChip(Icons.location_on_outlined, group.barangay),
                    _InfoChip(
                      Icons.person_outline_rounded,
                      'Coach: ${group.coach}',
                    ),
                    _InfoChip(Icons.palette_outlined, group.theme),
                    _InfoChip(
                      Icons.people_outline_rounded,
                      '${group.memberCount} member${group.memberCount != 1 ? 's' : ''}',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons with labels
          Row(
            children: [
              _ActionButton(
                icon: Icons.history_rounded,
                label: 'History',
                tooltip: 'View score history',
                color: AppColors.accentGreen,
                onTap: onViewHistory,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.edit_rounded,
                label: 'Edit',
                tooltip: 'Edit group details',
                color: AppColors.secondary,
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Remove',
                tooltip: 'Remove this group',
                color: AppColors.danger,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _InfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.silverRank),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.silverRank),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.divider.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: AppColors.silverRank),
          ),
          const SizedBox(height: 18),
          Text(
            title,
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
              subtitle,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(actionLabel!, style: GoogleFonts.poppins()),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STAT BADGE
// ═══════════════════════════════════════════════════════════════

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: AppColors.shadow,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
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

// ═══════════════════════════════════════════════════════════════
//  GROUP FORM DIALOG
// ═══════════════════════════════════════════════════════════════

class _GroupFormDialog extends StatefulWidget {
  final DanceGroup? existing;
  final Function(DanceGroup) onSave;

  const _GroupFormDialog({this.existing, required this.onSave});

  @override
  State<_GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<_GroupFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _barangayCtrl;
  late final TextEditingController _coachCtrl;
  late final TextEditingController _themeCtrl;
  late final TextEditingController _memberCountCtrl;
  final TextEditingController _memberInputCtrl = TextEditingController();
  late List<String> _members;

  String? _nameError;
  String? _barangayError;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _barangayCtrl = TextEditingController(text: g?.barangay ?? '');
    _coachCtrl = TextEditingController(text: g?.coach ?? '');
    _themeCtrl = TextEditingController(text: g?.theme ?? '');
    _memberCountCtrl = TextEditingController(
      text: g?.memberCount.toString() ?? '',
    );
    _members = List.from(g?.members ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barangayCtrl.dispose();
    _coachCtrl.dispose();
    _themeCtrl.dispose();
    _memberCountCtrl.dispose();
    _memberInputCtrl.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberInputCtrl.text.trim();
    if (name.isNotEmpty) {
      setState(() => _members.add(name));
      _memberInputCtrl.clear();
    }
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty
          ? 'Group name is required.'
          : null;
      _barangayError = _barangayCtrl.text.trim().isEmpty
          ? 'Barangay is required.'
          : null;
      if (_nameError != null || _barangayError != null) ok = false;
    });
    return ok;
  }

  void _save() {
    if (!_validate()) return;
    final group = DanceGroup(
      id:
          widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      barangay: _barangayCtrl.text.trim(),
      coach: _coachCtrl.text.trim(),
      theme: _themeCtrl.text.trim(),
      memberCount: int.tryParse(_memberCountCtrl.text) ?? _members.length,
      members: _members,
      performanceOrder: widget.existing?.performanceOrder ?? 0,
      scoreHistory: widget.existing?.scoreHistory ?? [],
    );
    widget.onSave(group);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Dance Group' : 'Add New Dance Group',
                        style: GoogleFonts.poppins(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isEdit
                            ? 'Update the group\'s information below'
                            : 'Fill in the details to register a new group',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Photo upload
              Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.25),
                      ),
                    ),
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      color: AppColors.secondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group Profile Photo',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Optional — JPG or PNG, max 2 MB',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.upload_rounded, size: 15),
                        label: Text(
                          'Upload Photo',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: BorderSide(color: AppColors.secondary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Required fields
              _buildField(
                'Group Name *',
                _nameCtrl,
                'e.g. Sayaw Pandan',
                errorText: _nameError,
              ),
              _buildField(
                'Barangay *',
                _barangayCtrl,
                'e.g. Brgy. Pandan',
                errorText: _barangayError,
              ),
              _buildField('Coach / Trainer', _coachCtrl, 'e.g. Maria Santos'),
              _buildField(
                'Dance Theme / Style',
                _themeCtrl,
                'e.g. Urban Fusion, Hip-Hop',
              ),
              _buildField(
                'Total Number of Members',
                _memberCountCtrl,
                'e.g. 15',
                keyboardType: TextInputType.number,
              ),

              // Member list
              Text(
                'Members List',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add individual member names (optional)',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _memberInputCtrl,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type member name and press Add…',
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.silverRank,
                          fontSize: 13,
                        ),
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
                      ),
                      onSubmitted: (_) => _addMember(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _addMember,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('Add', style: GoogleFonts.poppins()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_members.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _members
                      .map(
                        (m) => Chip(
                          label: Text(
                            m,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _members.remove(m)),
                          backgroundColor: AppColors.secondary.withOpacity(0.1),
                          deleteIconColor: AppColors.danger,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: AppColors.secondary.withOpacity(0.2),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No members added yet. You can add them later.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

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
                      isEdit ? 'Save Changes' : 'Register Group',
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

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(fontSize: 14),
            onChanged: (_) {
              if (errorText != null) setState(() {});
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: AppColors.silverRank,
                fontSize: 13,
              ),
              errorText: errorText,
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
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HISTORY DIALOG
// ═══════════════════════════════════════════════════════════════

class _HistoryDialog extends StatelessWidget {
  final DanceGroup group;
  const _HistoryDialog({required this.group});

  Color _rankColor(int rank) {
    switch (rank) {
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
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: AppColors.accentGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Score History — ${group.barangay}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.silverRank,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.silverRank,
                    ),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (group.scoreHistory.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 40,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No score history yet',
                          style: GoogleFonts.poppins(
                            color: AppColors.silverRank,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Scores will appear here after each phase.',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: group.scoreHistory.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final h = group.scoreHistory[i];
                    final rc = _rankColor(h.rank);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: rc.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '#${h.rank}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: rc,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h.phase,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  h.date,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.silverRank,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${h.score.toStringAsFixed(1)} pts',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(color: AppColors.silverRank),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
